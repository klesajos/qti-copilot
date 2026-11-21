> 🌍 Read this in: **English** | [Česky](03-hooks.cs.md)

# Example 3: Project-scoped hooks

## What is a hook?

A **hook** is a command that Copilot CLI runs **itself** when an event happens: a session
starts, a tool is about to run, a tool has finished, the agent is about to stop. The CLI
writes a JSON description of the event to the command's stdin and reads at most one JSON
object back from its stdout.

The difference from instructions and skills ([Example 1](01-custom-instructions.md),
[Example 2](02-skills.md)): those are *advice*. They are text in the context window and the
model may skip them. A hook is *enforcement*. It runs outside the model, every time, whatever
the model decided. Use hooks for what must not be skipped: blocking a destructive command,
keeping secrets out of the session, formatting, running tests.

When you generate code instead of writing it, you no longer read every tool call. Hooks are
the part of the setup that still does.

## What this example does

The repo ships one registration file and five scripts:

```
.github/hooks/
├── hooks.json                 ← WHEN: which event runs which script
└── scripts/
    ├── git-context.sh         ← sessionStart: tells the model the branch and uncommitted files
    ├── block-destructive.sh   ← preToolUse (shell): refuses rm -rf, reset --hard, force-push, ...
    ├── protect-secrets.sh     ← preToolUse (shell + view): keeps .env files out of the session
    ├── format.sh              ← postToolUse (file edits): Prettier on web/src
    └── run-tests.sh           ← agentStop: tests for the parts that changed, advisory
```

| Script | Event | What it returns | Can it stop anything? |
|--------|-------|-----------------|-----------------------|
| `git-context.sh` | `sessionStart` | `{"additionalContext": "..."}` | No. It adds context |
| `block-destructive.sh` | `preToolUse` | `{"permissionDecision": "deny", ...}` or nothing | Yes, the tool call |
| `protect-secrets.sh` | `preToolUse` | same | Yes, the tool call |
| `format.sh` | `postToolUse` | `{"additionalContext": "..."}` or nothing | No. The edit already happened |
| `run-tests.sh` | `agentStop` | exit code 2 plus a line on stderr | No. It warns. The gate variant below does |

Four of the five need `jq` (`run-tests.sh` does not). Without it they do nothing and let the
session continue.

## Lab step 1: look at the real payload

Do this before reading any script. The documentation disagrees with itself about the shape
of the payload (the tutorial says `toolArgs` is a JSON string, the reference types it as
`unknown`), and the shape depends on the model you run. So dump it.

Create `.github/hooks/payload-dump.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/sessionStart.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "preToolUse": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/preToolUse.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "postToolUse": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/postToolUse.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "agentStop": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/agentStop.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ]
  }
}
```

- **A second file, not an edit of `hooks.json`.** Every `*.json` in `.github/hooks/` is loaded
  and the entries are combined, so this file adds four hooks next to the five shipped ones.
  Delete it when you are done.
- **No `matcher`**, so the two tool hooks fire for every tool.
- **`(cat; echo) >>`**: the payload arrives as one line without a trailing newline. `echo`
  adds it, so each event is one line of JSONL.
- **`; exit 0`**: a `preToolUse` hook that exits non-zero **denies the tool call**. A dump
  hook that fails for a silly reason would block the whole session.
- **`.github/hooks/logs/`** is in `.gitignore`. The logs contain your prompts and tool
  output; do not share them without reading them.

Start a **new** session (hook files are read when the CLI starts) and give it three things
to do. As a one-shot:

```bash
copilot -p "Do exactly these three things, in order, then stop: (1) read the file README.md with the file view tool; (2) run the shell command 'git status --short'; (3) create a new file named .github/hooks/logs/note.txt containing the single word alpha. Do not do anything else." \
  --trust-folder --no-ask-user --allow-tool='write'
```

Then look at what the tools received:

```bash
jq -c '{toolName, toolArgs}' .github/hooks/logs/preToolUse.jsonl
```

This file and this kind of prompt were run on Copilot CLI 1.0.114 in a scratch repository
(the files there were called `note.txt` and `created.txt`). The model was a GPT-family one.
The output, with the path shortened to `<repo>`:

```json
{"toolName":"view","toolArgs":{"path":"<repo>/note.txt"}}
{"toolName":"bash","toolArgs":{"command":"git status --short","description":"Check git status"}}
{"toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Add File: <repo>/created.txt\n+alpha\n*** End Patch\n"}
```

The full payloads, one per event (ids shortened):

```json
// sessionStart
{"sessionId":"af3889b0-...","timestamp":1795259836973,"cwd":"<repo>","source":"new","initialPrompt":"Do exactly these three things, ..."}

// userPromptSubmitted
{"sessionId":"cf7325ea-...","timestamp":1795258198411,"cwd":"<repo>","prompt":"Do exactly these three things, ..."}

// preToolUse
{"sessionId":"af3889b0-...","timestamp":1795259842921,"cwd":"<repo>","toolCallId":"call_8028...","toolName":"bash","toolArgs":{"command":"git status --short","description":"Check git status"}}

// postToolUse = preToolUse + toolResult
{"sessionId":"af3889b0-...","timestamp":1795259844348,"cwd":"<repo>","toolCallId":"custom_call_4ef2...","toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Add File: <repo>/created.txt\n+alpha\n*** End Patch\n","toolResult":{"resultType":"success","textResultForLlm":"Added 1 file(s): <repo>/created.txt"}}

// agentStop
{"sessionId":"af3889b0-...","timestamp":1795259845225,"cwd":"<repo>","transcriptPath":"/Users/you/.copilot/session-state/af3889b0-.../events.jsonl","stopReason":"end_turn","stop_hook_active":false}

// sessionEnd
{"sessionId":"cf7325ea-...","timestamp":1795258207094,"cwd":"<repo>","reason":"complete"}
```

What to take from it:

- **There is no event name in the payload.** A script knows its event only from where it is
  registered.
- **`toolArgs` is an object for `bash` and `view`, and a raw patch string for `apply_patch`.**
  The patch string is not JSON. A script that does `jq '.toolArgs.path'` on it gets an error.
- **GPT-family models create and edit files with `apply_patch`**, not with `edit` / `create`.
  In another probe the same model wrote a file with `printf 'goodbye\n' > note.txt` in the
  shell. A matcher on the edit tools never sees that call.
- **Paths inside the patch arrived relative in one run and absolute in another.**
- **Hook processes start in the repository root.** They also get `COPILOT_PROJECT_DIR` (and
  the same value as `CLAUDE_PROJECT_DIR`), `COPILOT_HOOK_DIR`, `COPILOT_HOOK_DEPTH=1` and
  `COPILOT_CLI=1`. All five were seen live and are listed in `copilot help environment`, so
  the repo root is a documented variable. The scripts in this repo do not need it; they rely
  on the working directory.
- **The `edit` and `create` tools were not observed** here: the test account only had
  GPT-family models. GitHub's own samples read their file path from `toolArgs.path`. If your
  model list has a Claude-family model, this lab step is how you check that on your machine.

Clean up:

```bash
rm .github/hooks/payload-dump.json
rm -r .github/hooks/logs
```

## The files, line by line

### Part 1: the registration (`.github/hooks/hooks.json`)

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "./.github/hooks/scripts/git-context.sh",
        "cwd": ".",
        "timeoutSec": 10
      }
    ],
    "preToolUse": [
      {
        "type": "command",
        "matcher": "bash|powershell",
        "bash": "./.github/hooks/scripts/block-destructive.sh",
        "cwd": ".",
        "timeoutSec": 10
      },
      {
        "type": "command",
        "matcher": "bash|powershell|view",
        "bash": "./.github/hooks/scripts/protect-secrets.sh",
        "cwd": ".",
        "timeoutSec": 10
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "matcher": "edit|create|str_replace_editor|apply_patch",
        "bash": "./.github/hooks/scripts/format.sh",
        "cwd": ".",
        "timeoutSec": 60
      }
    ],
    "agentStop": [
      {
        "type": "command",
        "bash": "./.github/hooks/scripts/run-tests.sh",
        "cwd": ".",
        "timeoutSec": 300
      }
    ]
  }
}
```

- `"version": 1` and `"hooks"`: the fixed envelope. `hooks` maps an **event name** to a list
  of entries.
- `"sessionStart"`, `"preToolUse"`, ...: event names in **camelCase**. The CLI also accepts
  PascalCase aliases (`PreToolUse`, `Stop`); with those the payload switches to snake_case
  fields and Claude Code tool names (per the docs). This repo uses camelCase only.
- Each entry is **flat**: its own `matcher`, its own command. There is no nested
  `hooks: [...]` list as in Claude Code's `settings.json`.
- `"type": "command"`: run a shell command. It is the default; `http` and `prompt` also exist
  (see [Optional parameters](#optional-parameters)).
- `"bash"`: the command line. The path is relative to `cwd`.
- `"cwd": "."`: relative to the **repository root**, not to the directory you started
  `copilot` in. Start `copilot` from the repository root all the same: a `-p --trust-folder`
  run started in `web/` skipped the hooks with *"Skipped repository hooks (../.github/hooks)
  because --trust-folder trusts only .../web, not the repository root"* (tested). `-C <root>`
  is the documented way to point a run at the root from elsewhere.
- `"timeoutSec"`: the default is 30. The fast hooks get 10, the formatter 60, the test run
  300. When the limit hits, the hook is killed and the CLI carries on as if it had not run.
- `"matcher"`: a regex on the **tool name**, compiled as `^(?:PATTERN)$`. It has to match the
  whole name, so `bash|powershell` means exactly one of those two. `sessionStart` and
  `agentStop` are not about a tool, so they have no matcher.
- **Why four names for one formatter.** `edit` and `create` are the classic file tools,
  `str_replace_editor` is another edit tool, and `apply_patch` is what GPT-family models use.
  A matcher of `edit|create` would never fire on those models, and it would fail silently.
- **Two `preToolUse` entries match a shell call.** Both run. If any hook returns `deny`, the
  call is blocked.

### Part 2: `git-context.sh` (`sessionStart` → `additionalContext`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

command -v jq >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
```

- `set -euo pipefail` is safe here. A failing `sessionStart` hook is logged and skipped; it
  cannot block anything.
- `cat >/dev/null` reads the payload and throws it away. The script needs no field from it.
- The two guards make the hook a no-op without `jq` or outside a git checkout. Every
  "nothing to do" path ends in `exit 0`.

```bash
branch=$(git branch --show-current 2>/dev/null)
branch=${branch:-"(detached HEAD)"}
changes=$(git status --porcelain 2>/dev/null)

if [ -z "$changes" ]; then
    context="Git: on branch $branch, working tree clean."
else
    count=$(printf '%s\n' "$changes" | wc -l | tr -d ' ')
    # Cap the list so a huge diff cannot flood the context window.
    files=$(printf '%s\n' "$changes" | head -10 | awk '{print $NF}' | paste -sd ',' - | sed 's/,/, /g')
    context="Git: on branch $branch, $count uncommitted file(s): $files"
    if [ "$count" -gt 10 ]; then
        context="$context, ..."
    fi
fi

# jq escapes quotes and backslashes in file names.
jq -cn --arg context "$context" '{additionalContext: $context}'
```

- It builds one line, for example
  `Git: on branch main, 2 uncommitted file(s): README.cs.md, README.md`.
- `head -10` caps the list. This text is paid for in tokens in every session.
- `jq -cn --arg ...` prints one JSON object. `additionalContext` is the only field
  `sessionStart` consumes. Live on 1.0.114, the model answered "which branch, what is
  uncommitted" from this line without calling a tool.
- **It is a snapshot.** It is taken once, when the session starts, and not refreshed.
- **Why `sessionStart` and not every prompt.** For `userPromptSubmitted` the sources
  conflict: the hooks reference says the output of a config-file hook is dropped, the CLI
  changelog says `additionalContext` reaches the model. `sessionStart` is the event where the
  reference, the changelog and the live test agree. (The hooks *tutorial* still says
  `sessionStart` output is ignored. It is stale.)

### Part 3: `block-destructive.sh` (`preToolUse` → deny)

```bash
set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "block-destructive hook: jq is not installed, guard is inactive" >&2
    exit 0
fi
```

- **No `-e`.** A `preToolUse` hook that exits non-zero denies the tool call
  (`Denied by preToolUse hook (hook errored)`, per the docs). With `-e`, any failing `grep`
  would block every shell command. The script must never fail by accident.
- Without `jq` the guard is off, and it says so on stderr. The alternative would be a repo
  where no shell command runs until you install `jq`.

```bash
# toolArgs arrives as an object; older versions sent it as a JSON-encoded string.
command=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.command // "") else "" end' 2>/dev/null)
```

- Three shapes, one expression: an **object** is used as is, a **JSON-encoded string** is
  parsed with `fromjson`, and anything else (a patch string, `null`) becomes an empty
  command. The script works whichever shape your version sends.

```bash
deny() {
    jq -cn --arg reason "$1" '{permissionDecision: "deny", permissionDecisionReason: $reason}'
    exit 0
}
```

- **This is how a hook blocks:** exit code 0 and one JSON object with
  `permissionDecision: "deny"`. The reason goes **to the model**, which sees
  `Denied by preToolUse hook: <reason>`. Write the reason as an instruction: what to do
  instead.
- Live: the deny holds even when the session was started with `--allow-tool='shell'`.

```bash
# Wiping build output is routine; any other recursive force-delete is not.
# Flags are checked separately so `rm -rf`, `rm -fr` and `rm -r -f` all match.
if printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]' \
    && printf '%s' "$command" | grep -Eq '[[:space:]](-[[:alpha:]]*[rR]|--recursive)' \
    && printf '%s' "$command" | grep -Eq '[[:space:]](-[[:alpha:]]*f|--force)' \
    && ! printf '%s' "$command" | grep -Eq '^rm -rf (\./)?((engine/|api/)?build|web/dist)/?$'; then
    deny "block-destructive hook: recursive force-delete is blocked. Only build output (build, engine/build, api/build, web/dist) may be removed this way; delete specific files instead."
fi
```

- Three `grep`s: there is an `rm`, there is a recursive flag, there is a force flag.
- The fourth is the **exception**, and it is anchored at both ends. `rm -rf web/dist` passes.
  `cd web && rm -rf dist` is denied, because the whole command is not exactly the allowed form.

The other four rules follow the same pattern:

| Blocked | Regex idea | Allowed instead |
|---------|-----------|-----------------|
| `git reset --hard` | `git reset` followed by `--hard` anywhere | `git stash`, `git reset --soft` |
| `git push -f` / `--force` | bare `-f` or `--force` after `git push` | `git push --force-with-lease` |
| `git clean -f` | any flag group containing `f` | `git clean -n` first |
| `git checkout -- .` / `git restore .` | the path is exactly `.` | restoring individual files |

- **Silence means "no opinion".** No output and exit 0: the normal permission flow decides.
- **It matches text, so it has false positives.** Tested:
  `echo "never run git reset --hard" >> notes.md` is denied, because the words are in the
  command.
- **It is not a security boundary.** `bash -c "git re""set --hard"` passes (tested). A
  pattern hook stops accidents, not intent. The boundary is the sandbox
  ([Example 8](08-permissions-sandbox.md)).
- `permissionDecision` also accepts `allow` and `ask`, and a hook may return `modifiedArgs`
  to rewrite the call (per the docs; not used here). In autopilot, `ask` is denied because
  nobody can answer.

### Part 4: `protect-secrets.sh` (`preToolUse` → deny)

Registered with `"matcher": "bash|powershell|view"`: the two shells **and** the file-read tool.

```bash
# What the tool is about to touch: a path for the file tools, a command for the shell.
target=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.path // .command // "") else "" end' 2>/dev/null)

# Matches .env and .env.local, but not .envrc or environment.ts.
if printf '%s' "$target" | grep -Eq '(^|[^[:alnum:]_])\.env(\.[[:alnum:]_-]+)?([^[:alnum:]_.-]|$)'; then
    jq -cn '{permissionDecision: "deny", permissionDecisionReason: "protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need."}'
fi

exit 0
```

- `.path // .command`: `view` carries a `path`, the shell carries a `command`. One variable
  covers both.
- The regex in three parts: `.env` must start the string or follow a non-word character; an
  optional suffix such as `.local`; then the end or a character that cannot continue a file
  name. So `.env`, `config/.env` and `.env.local` match; `.envrc` and `environment.ts` do not.
- **Why this hook exists.** A `--deny-tool='read(.env)'` rule blocks the `view` tool only.
  `cat .env` in the shell still returned the content in a live test.
  [Example 8](08-permissions-sandbox.md) reproduces that.
- **Its limits, tested with fake stdin:** `cat .e*` and `grep -r SECRET .` pass, because the
  name is not in the command. `grep -n .env .gitignore` is denied, although it reads no
  secret. Guard rail, not boundary.
- **It does not guard writes.** The matcher has no edit tool. To add them, extend the matcher
  and read the path from the patch text the way `format.sh` does.

### Part 5: `format.sh` (`postToolUse` → `additionalContext`)

```bash
input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
[ -x web/node_modules/.bin/prettier ] || exit 0
```

- Before `cd web && npm ci` there is no Prettier, and the hook stays silent.

```bash
# The file tools pass an object with a `path`. apply_patch (used by some models
# instead of edit/create) passes the raw patch text, so the paths are read from
# its "*** Add File:" / "*** Update File:" headers.
paths=$(printf '%s' "$input" | jq -r '
    .toolArgs
    | if type == "object" then (.path // empty)
      elif type == "string" then (split("\n")[] | capture("^\\*\\*\\* (Add|Update) File: (?<path>.+)$")? | .path)
      else empty end' 2>/dev/null)
```

- **Two shapes, two branches.** This is the reason for lab step 1.
  - Object: `edit` and `create` pass `{"path": "...", ...}` (per GitHub's samples; `view` was
    seen live with this shape). Take `.path`.
  - String: `apply_patch` passes patch text. Split it into lines and keep the ones that look
    like `*** Add File: <path>` or `*** Update File: <path>`. One patch can touch several
    files, so the result is a list.
- A script that only handled the object would never format anything on a GPT-family model,
  and nothing would tell you.

```bash
formatted=""
while IFS= read -r path; do
    [ -n "$path" ] || continue
    # Paths arrive absolute or relative depending on the tool; compare from the repo root.
    relative=${path#"$PWD"/}
    case "$relative" in
        web/src/*.ts | web/src/*.tsx | web/src/*.css)
            if [ -f "$relative" ] && web/node_modules/.bin/prettier --write "$relative" >/dev/null 2>&1; then
                formatted="$formatted ${relative##*/}"
            fi
            ;;
    esac
done <<EOF
$paths
EOF
```

- `${path#"$PWD"/}` strips the repo root from an absolute path. The hook runs in the root, so
  `$PWD` is the root.
- The `case` keeps only web sources. In a `case` pattern `*` also matches `/`, so
  subdirectories of `web/src/` are included.
- `prettier --write` rewrites the file in place.

```bash
if [ -n "$formatted" ]; then
    jq -cn --arg files "$formatted" \
        '{additionalContext: ("format hook: Prettier reformatted" + $files + ". Re-read the file before editing it again.")}'
fi
```

- **Why tell the model.** After the formatter ran, the model's picture of the file is stale.
  Its next `edit` or patch may not apply. On `postToolUse`, `additionalContext` is appended to
  the tool result, so the model reads it in the same turn (per the docs; several hooks'
  contexts are joined and capped at 10 KB).
- The message is sent whenever Prettier ran without error, even if the file was already
  formatted. That costs one extra re-read at worst.
- **Why Kotlin is not formatted here.** Formatting Kotlin means a Gradle task, and this hook
  fires after every single edit. A Gradle start per edit is too slow, so the script leaves
  Kotlin alone. This build has no Kotlin formatter at all; Kotlin style is carried by the
  instructions file, which is advice. If you add a formatter, run it from `agentStop` or CI.
- **What it cannot see.** A file written through shell redirection is a `bash` call. This
  matcher does not fire.

### Part 6: `run-tests.sh` (`agentStop`, advisory)

```bash
# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# agentStop fires after every turn, including plain questions. Only test what changed.
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
failed=""

if printf '%s\n' "$changed" | grep -Eq '^(engine|api)/'; then
    ./gradlew test --quiet >/dev/null 2>&1 || failed="$failed gradle"
fi

if printf '%s\n' "$changed" | grep -Eq '^web/src/' && [ -d web/node_modules ]; then
    (cd web && npm test --silent >/dev/null 2>&1) || failed="$failed web"
fi

if [ -n "$failed" ]; then
    # Exit code 2 shows stderr to the user as a warning without blocking the turn.
    echo "run-tests hook: tests are failing in:$failed" >&2
    exit 2
fi

exit 0
```

- `agentStop` fires when the agent finishes a turn, **every** turn, also after a plain
  question. So the script first asks git what is uncommitted and tests only those parts:
  Gradle for `engine/` or `api/`, Vitest for `web/src/`.
- A clean tree means no test run and no delay. A dirty tree means a test run after every
  turn until you commit.
- Test output is thrown away. Only the list of failing parts is kept.
- **Exit code 2 plus stderr = a warning.** For `agentStop` it does not block. In a JSONL run
  it arrives as a `session.warning` event with `warningType: "hook"` (live).
- `timeoutSec` is 300. A test run that takes longer is killed, and the turn ends as if the
  hook had not run.
- **Advisory on purpose**: a live workshop session cannot get stuck in a fix-the-tests loop.
  [A second hook: gate on tests](#a-second-hook-gate-on-tests) shows the blocking variant.

## Test a hook with fake stdin

Do not debug a hook inside a session. A hook is a program that reads stdin, so feed it by
hand. Run these from the repo root. The output shown is real.

```bash
H=.github/hooks/scripts

echo '{"toolName":"bash","toolArgs":{"command":"git push --force origin main"}}' | $H/block-destructive.sh
# {"permissionDecision":"deny","permissionDecisionReason":"block-destructive hook: force-push is blocked. Use git push --force-with-lease, or ask the user."}

echo '{"toolName":"bash","toolArgs":{"command":"git status"}}' | $H/block-destructive.sh; echo "exit=$?"
# exit=0            (no output = no opinion)

echo '{"toolName":"bash","toolArgs":"{\"command\":\"git reset --hard HEAD~1\"}"}' | $H/block-destructive.sh
# {"permissionDecision":"deny","permissionDecisionReason":"block-destructive hook: git reset --hard discards uncommitted work. Use git stash, or git reset --soft."}
#                   (toolArgs as a JSON string works too)

echo '{"toolName":"view","toolArgs":{"path":"/repo/web/.env.local"}}' | $H/protect-secrets.sh
# {"permissionDecision":"deny","permissionDecisionReason":"protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need."}

echo '{"toolName":"bash","toolArgs":{"command":"cat .envrc"}}' | $H/protect-secrets.sh; echo "exit=$?"
# exit=0

$H/git-context.sh </dev/null
# {"additionalContext":"Git: on branch main, 2 uncommitted file(s): README.cs.md, README.md"}
#                   (your branch and file list will differ)
```

`format.sh` needs `web/node_modules` (`cd web && npm ci`). It runs Prettier for real, so point
it at a file that is already formatted:

```bash
echo "{\"toolName\":\"edit\",\"toolArgs\":{\"path\":\"$PWD/web/src/App.tsx\"}}" | $H/format.sh
# {"additionalContext":"format hook: Prettier reformatted App.tsx. Re-read the file before editing it again."}

printf '%s' '{"toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Update File: web/src/api.ts\n@@\n-x\n+y\n*** End Patch\n"}' | $H/format.sh
# {"additionalContext":"format hook: Prettier reformatted api.ts. Re-read the file before editing it again."}

echo '{"toolName":"edit","toolArgs":{"path":"engine/src/main/kotlin/Board.kt"}}' | $H/format.sh; echo "exit=$?"
# exit=0            (Kotlin is skipped)
```

`run-tests.sh` with a clean `engine/`, `api/` and `web/src/`:

```bash
echo '{}' | $H/run-tests.sh; echo "exit=$?"
# exit=0
```

Three things to check on every hook: the output is **one** JSON object or nothing, the exit
code is 0 on every "nothing to do" path, and it survives the payload shapes from lab step 1.

## Create your own hook, step by step

1. **Dump the payload** for the event you want (lab step 1). Write the script against what
   you saw.
2. **Write the script** in `.github/hooks/scripts/`. Skeleton: `input=$(cat)`, pull out what
   you need with `jq` in a way that tolerates an object and a string, act, print at most one
   JSON object, `exit 0`.
3. **Make it executable**: `chmod +x .github/hooks/scripts/my-hook.sh`.
4. **Register it** in `hooks.json`, or in a new `*.json` file next to it. Give it a `matcher`
   if it is a tool event and a `timeoutSec` that fits.
5. **Test it with fake stdin**, including one payload it should ignore.
6. **Start a new session** and run `/env`. It lists the hooks that were loaded.
7. **Commit** the JSON file and the script. From then on everybody who trusts the folder
   runs your hook.

## Try the demo

Start `copilot` in the repo root and confirm the folder-trust prompt. Repo hooks load only
after that.

1. **Context.** Change any file *before* you start the session, then ask:

   > *"Without running any tool: which branch am I on and what is uncommitted?"*

   The answer comes from the injected line (live).

2. **Destructive guard.**

   > *"Run exactly this command: git push --force nowhere main"*

   The hook denies it before git runs. The model quotes
   `Denied by preToolUse hook: block-destructive hook: force-push is blocked. ...` and offers
   `--force-with-lease`. The remote `nowhere` does not exist, so the command would be harmless
   even without the hook. (For this guide the script's answer to this command was tested with
   fake stdin; the live denial was tested with another blocked command.)

3. **Secrets guard.**

   ```bash
   echo "DUMMY_SECRET=not-real" > .env      # .env is gitignored
   ```

   > *"Run exactly this one shell command and quote any message you received: cat .env"*

   Live result: `Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and
   stay out of the session. ...`. Remove the file afterwards: `rm .env`.

4. **Formatter** (needs `cd web && npm ci`; not run live for this guide):

   > *"Add an exported function isWasdKey(key: string): boolean to web/src/keys.ts. Write it with double quotes and semicolons."*

   Then `git diff web/src/keys.ts`. The Prettier config has `semi: false` and
   `singleQuote: true`, so the file on disk has single quotes and no semicolons, whatever the
   model wrote. Undo with `git restore web/src/keys.ts`.

5. **Tests.** While `web/src/` has uncommitted changes, every turn ends with a Vitest run.
   Green means silence. A failure shows as a warning: `run-tests hook: tests are failing in: web`.

## A second hook: gate on tests

`run-tests.sh` warns. To make "tests must pass before you stop" a rule, the hook has to send
the agent back to work. Exercise 3 in [exercises.md](exercises.md) has you do it. The mechanism:

- **Only JSON on stdout blocks.** The script exits 0 and prints
  `{"decision": "block", "reason": "..."}`. The CLI then starts another agent turn, and
  `reason` arrives as the next user message (live). `decision` also accepts `"allow"`.
- **Exit codes cannot block `agentStop`.** Exit 2 is a warning (live). Any other non-zero
  exit is logged and skipped (per the docs). Only `preToolUse` and `permissionRequest` treat
  an exit code as a decision.
- **`stop_hook_active`** is `false` on a normal stop and `true` on the stop that follows a
  block (live). It lets the script see that it already sent the agent back.
- **The cap.** After 8 consecutive blocks the CLI overrides the hook and ends the turn (per
  the docs). Do not rely on it: eight Gradle runs and eight agent turns are slow and cost
  credits. Limit yourself with `stop_hook_active`.

Two changes to the script. At the top, keep the payload instead of draining it:

```bash
# Keep the payload this time: stop_hook_active says whether Copilot was already sent back.
input=$(cat)
```

And the new tail, replacing the `if [ -n "$failed" ]` block:

```bash
if [ -n "$failed" ]; then
    already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
    if [ "$already_blocked" != "false" ]; then
        # Copilot was sent back once and the tests still fail (or jq is missing):
        # warn the user and let the turn end instead of looping.
        echo "run-tests hook: tests are still failing in:$failed" >&2
        exit 2
    fi
    # Exit 0 plus one JSON object on stdout is the only form that blocks.
    jq -cn --arg failed "$failed" \
        '{decision: "block", reason: ("run-tests hook: tests are failing in:" + $failed + ". Run them, fix the cause, then finish.")}'
fi

exit 0
```

Tested with fake stdin against a stub `gradlew` that fails:

```bash
echo '{"stopReason":"end_turn","stop_hook_active":false}' | .github/hooks/scripts/run-tests.sh
# {"decision":"block","reason":"run-tests hook: tests are failing in: gradle. Run them, fix the cause, then finish."}

echo '{"stopReason":"end_turn","stop_hook_active":true}' | .github/hooks/scripts/run-tests.sh; echo "exit=$?"
# run-tests hook: tests are still failing in: gradle
# exit=2
```

What changes once it blocks:

- The agent gets **one** more turn to fix the tests. If they still fail, you get the warning
  and the turn ends. Drop the `stop_hook_active` branch if you want it to keep trying up to
  the cap.
- The `reason` is a prompt. "Tests are failing" makes the agent guess; name the part and say
  what to do.
- The script throws test output away, so the agent has to rerun the tests to see the failure.
  That is one tool call, and it keeps a wall of Gradle output out of the `reason`.
- A `-p` run waits for the blocked continuation before it exits (per the changelog).
- A stop that follows a plain question is gated too, if the tree is dirty and red.

## Events, matchers and failure modes

### The 14 events

Names are from the hooks reference. "Live" marks what was observed on 1.0.114; the rest is
per the docs. A dash means no output field for that event is covered by this guide; check the
[hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference) before you
rely on one.

| Event | Fires | Matcher on | What the hook can do (output honoured) |
|-------|-------|-----------|-----------------------------------------|
| `sessionStart` | A session starts. `source` is `startup`, `resume` or `new` | — | Add context: `additionalContext` (live). The only field consumed |
| `userPromptSubmitted` | You submit a prompt. Payload has `prompt` (live) | — | Conflicting: the reference says output is dropped, the changelog says `additionalContext` reaches the model. Use it for logging |
| `userPromptTransformed` | Before the prompt goes to the model | — | Replace what the model receives: `modifiedTransformedPrompt`. The timeline still shows your original |
| `preToolUse` | Before a tool runs (live) | tool name | Decide: `permissionDecision` `allow` / `deny` / `ask` with `permissionDecisionReason`; rewrite: `modifiedArgs`. Any `deny` wins (deny live) |
| `permissionRequest` | Before the permission rules engine. CLI only. Not for reads | tool name | `behavior` `allow` / `deny`, `message`, `interrupt` |
| `postToolUse` | After a **successful** tool call (live) | tool name | `additionalContext` appended to the tool result; `modifiedResult` |
| `postToolUseFailure` | After a failed tool call | — | — |
| `agentStop` | The agent finishes a turn (live) | — | `decision: "block"` + `reason` forces another turn (live) |
| `subagentStart` | A subagent starts | agent name | — |
| `subagentStop` | A subagent finishes | — | `decision` / `reason` like `agentStop`; `modifiedResponse` rewrites its answer |
| `preCompact` | Before the context is compacted | trigger | — |
| `notification` | The CLI raises a notification | notification type | — |
| `errorOccurred` | An error occurred | — | — |
| `sessionEnd` | The session ends. Payload has `reason` (live: `complete`) | — | — |

The built-in `general-purpose` agent does not emit `subagentStart` / `subagentStop`; the
other built-in agents and custom agents do (per the docs).

A fifteenth name, `preMcpToolCall`, appears in `copilot help environment` in a sentence about
HTTP hooks. It is named in the CLI help and not otherwise described.

### Exit codes

| Exit code | Meaning | Exception |
|-----------|---------|-----------|
| `0` | Stdout is parsed as the hook's JSON output. Empty or unparseable output means default behaviour | — |
| `2` | A warning; stderr is shown | A **deny** for `preToolUse` and `permissionRequest` |
| other non-zero | Logged and skipped | `preToolUse` **denies** the call: it fails closed |

- **Timeouts fail open, for every event.** A `preToolUse` hook that hangs is killed after
  `timeoutSec`, a warning is shown, and the tool call goes ahead. A guard that is slow is not
  a guard.
- **A crash on `preToolUse` fails closed.** A typo in a guard script blocks every matching
  tool call. That is the reason for `set -uo pipefail` without `-e` and for the `jq` check.
- **One JSON document on stdout.** Two objects concatenate into invalid JSON and are ignored.
  Do not `echo` debug text to stdout; use stderr. Lines of the form
  `{"type":"progress","message":"..."}` are the one exception and are stripped.

### Matcher and tool names

The matcher is a regex that must match the **whole** tool name. `bash` does not match
`bash_extra`, and `edit` does not match `str_replace_editor`. An invalid regex skips the
entry; the CLI prints `! Invalid hook configuration in FILE: REASON`.

| Tool name | What it is |
|-----------|-----------|
| `bash` | Shell on macOS and Linux |
| `powershell` | Shell on Windows |
| `view` | Read a file or directory |
| `create` | Create a file |
| `edit` | Edit a file by string replacement |
| `str_replace_editor` | Another edit tool; the CLI treats it as one |
| `apply_patch` | Patch-based create and edit, used by some models instead of `edit` / `create` |

Others you may want to match: `glob`, `grep` (seen live as `rg`), `task` (delegation to a
subagent), `web_fetch`, `ask_user`, `skill`. Lab step 1 shows the names your session uses.

## Where hooks can live

All sources are loaded and combined, in the order policy, user, project, plugins. If the same
event appears in several places, every entry runs (per the docs).

| Location | Scope | Notes |
|----------|-------|-------|
| `.github/hooks/*.json` | Repo, committed | This example. A bad entry is dropped; the rest of the file still loads |
| `hooks` key in `.github/copilot/settings.json` | Repo, committed | Inline. Stricter: one invalid entry rejects the whole `hooks` field |
| `hooks` key in `.github/copilot/settings.local.json` | Repo, yours | Same, normally gitignored |
| `~/.copilot/hooks/` | You, every repo | Personal hooks, for example a notification on `agentStop` |
| `hooks` key in `~/.copilot/settings.json` | You, every repo | Inline user-level hooks |
| A plugin's `hooks.json` or `hooks/hooks.json` | Whoever enables the plugin | See [Example 6](06-plugins.md). Plugin hooks also get `COPILOT_PLUGIN_ROOT` |
| `hooks:` in an agent's frontmatter | While that agent is selected | CLI only. See [Example 5](05-agents.md) |
| `.claude/settings.json`, `.claude/settings.local.json` | Repo | **Copilot CLI runs these too** |
| Managed (policy) hooks | Set by an admin | Cannot be disabled from the repo or by you |

**The `.claude/` row matters if a repo serves both tools.** Hooks written for Claude Code
under `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop` or `SessionStart` run on the
matching Copilot events. Their matchers (`Bash`, `Read`, `Edit`, `Write`) match Copilot's
tools, and their payload uses Claude Code's field names (`tool_name`, `tool_input`). A
Claude Code guard hook that fails under Copilot denies every matching tool call. This repo
has no `.claude/` directory, so nothing runs twice.

## Side effects worth knowing

- **The cloud agent loads the same files.** Per the docs, Copilot cloud agent reads
  `.github/hooks/*.json` from the repo it works on. There only `bash` / `command` entries are
  honoured, `ask` becomes a deny, `permissionRequest` and `notification` do not fire, and a
  block on `agentStop` counts against the job's time limit. A hook you commit for your
  terminal also runs in every cloud agent job on that repo.
- **Hooks run inside the sandbox when it is on.** Per the docs, repo, user and plugin command
  hooks then run under the same policy as the agent's shell commands (policy hooks stay on
  the host). A hook that runs `./gradlew test` or `npm test` can fail only there, for example
  on access to a build cache. `/sandbox policy <hook command>` shows what the policy gives
  that command. Not tested in this repo.
- **Shell redirection bypasses edit-tool matchers.** Seen live: the model wrote a file with
  `printf ... > note.txt`. That is a `bash` call. `format.sh` does not run for it, and a hook
  that protects files by matching `edit|create|apply_patch` does not see it. A file guard
  has to look at shell commands as well, which is what `protect-secrets.sh` does.
- **Parallel tool calls run their `preToolUse` hooks at the same time** (per the docs). A hook
  that writes a shared state or log file has to tolerate that.
- **`-p` runs load repo hooks only for a trusted folder.** Either the folder is already
  trusted, or you pass `--trust-folder` (live). The docs also name an environment variable,
  `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=true`; it is not in `copilot help environment`, so
  prefer the flag.
- **Committed hooks are code that runs on your colleagues' machines.** Review a change to
  `.github/hooks/` the way you review a change to CI.

## Optional parameters

Fields of one hook entry (per the hooks reference; this repo uses the first five):

| Field | What it does |
|-------|--------------|
| `type` | `command` (default), `http` or `prompt` |
| `bash` | Command line run with bash. On Windows that needs a bash on `PATH` (`COPILOT_BASH_PATH` overrides which one) |
| `cwd` | Working directory, relative to the repo root or absolute |
| `timeoutSec` | Seconds before the hook is killed. Default 30. `timeout` is an alias |
| `matcher` | Full-match regex. Tool name for `preToolUse`, `postToolUse`, `permissionRequest`; see the event table for the others |
| `powershell` | Command line for PowerShell. This repo's entries have none |
| `command` | Cross-platform fallback, copied to `bash` and `powershell` when those are absent |
| `exec` + `args` | Run a program directly, without a shell. CLI only |
| `env` | Extra environment variables for the hook process |

Other types:

| Type | What runs | Limits |
|------|-----------|--------|
| `http` | POSTs the payload to `url` | Must be `https://` for the hooks that decide; loopback is blocked unless `COPILOT_HOOK_ALLOW_LOCALHOST=1`. A `preToolUse` HTTP hook fails open |
| `prompt` | Submits a text or a slash command for you | `sessionStart` only, new interactive sessions only, never in `-p` |

Switches:

| Key | Where | Effect |
|-----|-------|--------|
| `"disableAllHooks": true` | Top level of one hooks file | Skips that file's hooks |
| `"disableAllHooks": true` | Repo `settings.json` | Skips every hook from every source in that repo, except policy hooks |
| `allowManagedHooksOnly`, `strictPluginOnlyCustomization` | Managed settings (admin) | Block repo and user hooks. If your hooks never load at 2N, ask whether one of these is set |

## Where it works: CLI, IntelliJ, cloud agent

| Platform | Works? | Notes |
|----------|--------|-------|
| **Copilot CLI** | ✅ Yes | Everything in this guide. Tested on 1.0.114 |
| **IntelliJ IDEA plugin** | ⚠️ Partly | Reads `.github/hooks/`. The only published event list is `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`. Nothing confirms `sessionStart` or `agentStop`, so expect `git-context.sh` and `run-tests.sh` to do nothing there. Not tested in this repo |
| **Copilot cloud agent** | ⚠️ Partly | Loads `.github/hooks/*.json` (per the docs). `bash` / `command` only, `ask` becomes deny, no `permissionRequest`, no `notification` |

More on IntelliJ, all from the docs and from user reports, none of it tested here:

- A deny from `preToolUse` is the one decision reported to work. One user report says the IDE
  ignores `modifiedArgs`.
- A user report says the IDE's own agent calls its terminal tool `run_in_terminal`. A matcher
  of `bash|powershell` would then not fire for it. Dump the payload in the IDE before you
  trust a guard there.
- The docs support matrix still lists hooks as unsupported in JetBrains IDEs, while the
  plugin release notes call them generally available since 1.10.0. Trust what you measure.
- See [Example 12](12-intellij.md).

## Troubleshooting

- **Hook never runs** → hook files are read when the CLI starts. Start a new session, then
  check `/env`.
- **Hook never runs, and `/env` does not list it** → the folder is not trusted. Repo hooks
  load only after the trust prompt; in `-p` add `--trust-folder`. Still nothing: a managed
  setting may block repo hooks.
- **`! Invalid hook configuration in FILE: REASON` at startup** → a bad entry, often an
  invalid `matcher` regex. In `.github/hooks/*.json` only that entry is dropped.
- **"Permission denied" from the hook** → the script is not executable. `chmod +x`.
- **Every shell command is suddenly denied with `Denied by preToolUse hook (hook errored)`** →
  a `preToolUse` script exits non-zero. Run it with fake stdin and look at the exit code.
  Check for `set -e`.
- **A guard works in the fake-stdin test but not in the session** → the matcher does not
  match the real tool name, or `toolArgs` has another shape. Repeat lab step 1.
- **The format hook does nothing** → `web/node_modules` is missing (`cd web && npm ci`), or
  the file is outside `web/src/`, or the model wrote it through the shell.
- **The hook's JSON is ignored** → something else was printed to stdout. One JSON object,
  nothing more.
- **`agentStop` hook exits 1 or 2 and the agent still stops** → by design. Block with
  `{"decision":"block","reason":"..."}` and exit 0.
- **Every turn takes a minute** → `run-tests.sh` runs Gradle while `engine/` or `api/` has
  uncommitted changes. Commit, or stash.
- **A guard blocks a harmless command** → it matches text. Rephrase the command, or put the
  text in a file.
- **Hooks behave differently under the sandbox** → they run inside it. See
  [Example 8](08-permissions-sandbox.md).

Next: [Example 4: MCP connections](04-mcp.md).

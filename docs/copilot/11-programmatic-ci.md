> 🌍 Read this in: **English** | [Česky](11-programmatic-ci.cs.md)

# Example 11: Programmatic mode and CI

## What is programmatic mode?

`copilot -p "<prompt>"` runs one prompt without the interactive UI and exits. Same agent, same
tools, same repo customizations; the difference is that **nobody is there to answer a
question**. That one fact explains every flag in this guide: permissions must be decided up
front, folder trust must be given on the command line, and the output must be something a
script can read.

Use it for scripted checks of your own customizations, for one-shot tasks in a shell pipeline,
and for CI.

Where each statement comes from:

- Unmarked: the CLI's own help on 1.0.114 (`copilot --help`, `copilot help <topic>`).
- **[T]** tested: run in this repository on 1.0.114.
- **[D]** per the docs; not tested in this repo.

## What this example does

It shows the three output modes, the event stream you can assert on, the permission rules that
work in this repo, and a smoke check that proves the `board-tests` skill loads. Nothing is
committed for this guide: the repo has no workflow file, because running Copilot in GitHub
Actions needs an organisation policy first (see [GitHub Actions](#github-actions)).

## The flags

| Flag | What it does |
|------|--------------|
| `-p "<prompt>"` | Run once and exit. A prompt can also be piped on stdin **[D]**. A slash invocation works: `copilot -p "/2048-dev:build-test ..."` **[T]** |
| `-s`, `--silent` | Print only the answer **[T]** |
| `--output-format json` | Print the event stream as JSONL, one object per line **[T]** |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Decide permissions up front. Deny wins over every allow |
| `--trust-folder` | Trust this folder's hooks, workspace MCP servers and repository plugin settings for this one run |
| `--agent <agent>` | Run the prompt as a custom agent |
| `--model <model-id>` | Pick the model; `auto` lets Copilot choose. `COPILOT_MODEL` does the same and loses to the flag |
| `--max-ai-credits <n>` | Soft cap for the run, minimum 30 |
| `--no-ask-user` | Remove the `ask_user` question form. It grants nothing and does not make the agent continue on its own **[D]** |
| `--share[=<path>]`, `--share-gist` | Save the transcript as Markdown, or as a secret gist, when the run ends |
| `--usage-output-file <file>` | Write final usage as JSON, also with `-s` |
| `--autopilot`, `--max-autopilot-continues <n>` | Let the agent take several turns; default 5 continuations |
| `--secret-env-vars=<names>` | Keep these environment variables out of shells and MCP servers |

## The three output modes

**Text** (default). The answer goes to stdout. A summary with usage and a
`copilot --resume=<id>` hint goes to stderr.

**Silent.** `-s` prints the answer and nothing else, which is what you want in `$(...)`:

```bash
copilot --agent kotlin-reviewer \
    -p "Review uncommitted changes under engine/ and api/ only. If there are none, answer: nothing to review." \
    -s --trust-folder --no-ask-user \
    --allow-tool='shell(git status)' --allow-tool='shell(git diff)'
```

On a tree with no changes under `engine/` or `api/` this printed the single line
`nothing to review` and exited with 0 **[T]**.

**JSON.** `--output-format json` prints one JSON object per line. Every record has the shape
`{type, data, id, parentId, timestamp}`, some with `ephemeral`. Three real lines from a run in
this repo, shortened **[T]**:

```json
{"type":"session.start","data":{"sessionId":"09175a2e-…","copilotVersion":"1.0.114","sessionLimits":{"maxAiCredits":30},"context":{"cwd":"/…/qti-ws-3","gitRoot":"/…/qti-ws-3","branch":"main"}},"id":"dedb8df6-…","timestamp":"2026-11-21T11:15:55.549Z","parentId":null}
{"type":"tool.execution_start","data":{"toolCallId":"call_72aa…","toolName":"skill","arguments":{"skill":"board-tests"},"turnId":"0","model":"<model-id>"},"id":"1102ab72-…","timestamp":"2026-11-21T11:16:04.490Z","parentId":"d34a8778-…"}
{"type":"result","timestamp":"2026-11-21T11:16:08.985Z","sessionId":"09175a2e-…","exitCode":0,"usage":{"premiumRequests":1,"totalApiDurationMs":6872,"sessionDurationMs":13483,"codeChanges":{"linesAdded":0,"linesRemoved":0,"filesModified":[]}}}
```

In every run recorded for this repo the last line was the `result` record. It has no `data`
wrapper.

| `type` | What to read |
|--------|--------------|
| `session.start` | `data.copilotVersion`, `data.context.cwd`, `gitRoot`, `branch` |
| `session.auto_mode_resolved` | `data.chosenModel`: which model `auto` picked |
| `session.skills_loaded` | `data.skills[]` with `name`, `commandName`, `source` (`project`, `plugin`, ...) |
| `session.custom_agents_updated` | `data.agents[]` with `id` and `source`; `data.warnings`, `data.errors` |
| `user.message`, `assistant.message` | `data.content` |
| `tool.execution_start` | `data.toolName`, `data.arguments` |
| `tool.execution_complete` | `data.success`, `data.result.content`, `data.error.message` |
| `subagent.started`, `subagent.completed`, `subagent.failed` | A delegated agent's life cycle |
| `session.warning` | Hook warnings, with `data.warningType: "hook"` |
| `session.usage_checkpoint` | `data.totalNanoAiu`; 10^9 nano AIU is one AI credit |
| `result` | `exitCode`, `usage.codeChanges.filesModified` |

Three things the stream does **not** have, which matter when you write assertions **[T]**:

- No `skill.invoked` record. A skill use is a `tool.execution_start` with `toolName: "skill"`.
- No separate delegation record to assert on by name. Delegation is `toolName: "task"` with
  `arguments.agent_type`, for example `"2048-dev:game-explorer"` or the built-in `"explore"`.
- No documented schema. The docs say "JSONL" and stop there **[D]**. Most lines are streaming
  deltas (`assistant.message_delta`). Pin the CLI version in anything that parses this.

### jq one-liners

```bash
# Which tools ran, and how often
jq -r 'select(.type == "tool.execution_start") | .data.toolName' events.jsonl | sort | uniq -c

# Was a skill used, and which one
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "skill") | .data.arguments.skill' events.jsonl

# Was a task delegated, and to which agent
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "task") | .data.arguments.agent_type' events.jsonl

# Tool calls that failed, with the reason
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | .data.error.message' events.jsonl

# The final result record
tail -n 1 events.jsonl | jq -c '{exitCode, usage}'

# The answer text
jq -rs '[.[] | select(.type == "assistant.message") | .data.content] | join("\n")' events.jsonl

# AI credits used
jq -s '[.[] | select(.type == "session.usage_checkpoint") | .data.totalNanoAiu] | last / 1e9' events.jsonl
```

Two billing units show up. Per `copilot help billing` the CLI reports AI credits or premium
requests, whichever the plan uses. On the test account the `result` record carried
`usage.premiumRequests`, while `session.usage_checkpoint` and `--usage-output-file` carried
`totalNanoAiu` (and `totalPremiumRequestCost` in the file) **[T]**. Read the one your plan is
billed in.

## Permissions when nobody can answer

In `-p` mode a tool request that would prompt is **denied**. The agent sees this **[T]**:

```
Permission denied because no interactive user response was available.
```

The run does not stop there. The agent reports that it could not do the work, or tries
something else, and the process still exits with 0 **[T]**. A green exit code is not proof that
the command ran; check for `tool.execution_complete` records with `success: false`.

Commands that Copilot recognises as read-only need no rule. Everything else needs one. What
was tested in this repo **[T]**:

| Rule | Command the agent ran | Result |
|------|-----------------------|--------|
| `--allow-tool='shell(./gradlew:*)'` | `./gradlew :engine:test` | ✅ allowed |
| `--allow-tool='shell(gradlew:*)'` | `./gradlew :engine:test` | ❌ denied; the rule must name the command as it is typed, with `./` |
| `--allow-tool='shell(./gradlew test)'` | `./gradlew :engine:test` | ❌ denied; a different subcommand |
| `--allow-tool='shell(npm test)'` | `cd web && npm test` | ✅ allowed |
| `--allow-tool='shell(npm:*)'` | `cd web && npm test` | ✅ allowed |
| `--deny-tool='read(.env)'` | the `view` tool on `.env` | ✅ blocked |
| `--deny-tool='read(.env)'` | `cat .env` in the shell | ❌ not blocked; a path rule does not apply to shell commands |
| none; `protect-secrets.sh` hook, with `--trust-folder` | `view` or `cat` on `.env` | ✅ blocked: `Denied by preToolUse hook: protect-secrets hook: ...` |

More from `copilot help permissions`:

- `--allow-tool='write'` approves all file edits. `write(<path>)` and `read(<path>)` take globs.
- A deny rule wins over every allow, including `--allow-all` and `--yolo`.
- `--assisted-approval` hands each request to a safety judge instead of denying it. It is
  probabilistic and not a security boundary.
- `--allow-all` and `--yolo` exist. An administrator can switch them off
  (`permissions.disableBypassPermissionsMode`), and nothing in this workshop needs them.

`scripts/copilot-ws.sh -p "..."` gives you the repo's standard rules in one go.

## `--trust-folder`

Interactive sessions ask once whether you trust a folder. A script cannot be asked.

| | |
|---|---|
| What it trusts | The working directory's hooks, workspace MCP servers and repository plugin settings **[D]** |
| For how long | One new `-p` (or piped) session. Nothing is saved |
| What it does not do | Grant any tool, path or URL permission. It cannot be combined with `--resume`, `--continue` or `--session-id` **[D]** |
| Without it | A `-p` run in an untrusted folder skips workspace MCP servers and repository hooks, and the repo's plugin settings **[D]** |
| Where to run | From the repository root. From a subdirectory the hooks at the root are not loaded, with a warning **[D]** |

With `--trust-folder` this repo's hooks fired, and the plugin from
`.github/copilot/settings.json` loaded with no install step **[T]**. Without the hooks you lose
`block-destructive.sh` and `protect-secrets.sh`, so a script that omits the flag runs with fewer
guard rails than your interactive session.

Setting `COPILOT_ALLOW_ALL` to exactly `true` also trusts the folder, and allows every tool.
Do not use it as a shortcut for trust.

## Agent, model and limits

- **`--agent`** takes the agent id: `kotlin-reviewer`, `board-test-writer`, or the plugin agent
  `2048-dev:game-explorer` **[T]**. A wrong name fails before anything runs: exit code 1, no
  JSONL on stdout, and on stderr
  `No such agent: no-such-agent, available: board-test-writer, kotlin-reviewer, 2048-dev:game-explorer` **[T]**.
- **`--model <model-id>`**. Which ids exist depends on the organisation's model list; `/model`
  in a session shows them. Do not put an id into a committed script; read it from a variable.
  With `auto`, the JSONL tells you what was chosen (`session.auto_mode_resolved`).
- **`--max-ai-credits <n>`**. Minimum 30. Per `copilot help limits` usage accumulates over the
  whole session, subagents included, and the cap is soft: one response can pass it, then the
  next model call is blocked. The docs disagree with each other on the scope **[D]**; trust the
  built-in help.
- **`--share=<path>`** wrote a Markdown transcript of the run **[T]**. The default is
  `./copilot-session-<id>.md`, inside the repo; give a path.
- **`--usage-output-file <file>`** wrote JSON with `totalNanoAiu`, `modelMetrics`,
  `agentMetrics` and `codeChanges` **[T]**.

For a task that needs several turns, add `--autopilot`. The documented form is
`copilot --autopilot --yolo --max-autopilot-continues 10 -p "YOUR PROMPT HERE"` **[D]**; replace
`--yolo` with explicit `--allow-tool` rules.

## Try the demo: a smoke check for the skill

The check asks a question the `board-tests` skill should answer and asserts that the `skill`
tool was called. It is read-only and cost about 0.4 AI credits and 13 seconds in a test run
**[T]**. Paste it into a terminal at the repository root:

```bash
events=$(mktemp)
copilot -p "What are this project's conventions for board tests? Answer in five bullets. Do not create or change any file." \
    --output-format json --trust-folder --no-ask-user --max-ai-credits 30 > "$events"

if jq -es '[.[] | select(.type == "tool.execution_start" and .data.toolName == "skill")
                | .data.arguments.skill] | index("board-tests") != null' "$events" >/dev/null; then
    echo "PASS board-tests skill was loaded"
else
    echo "FAIL board-tests skill was not loaded"
fi
tail -n 1 "$events" | jq -c '{exitCode, filesModified: .usage.codeChanges.filesModified}'
```

Expected:

```
PASS board-tests skill was loaded
{"exitCode":0,"filesModified":[]}
```

How it works: the prompt does not name the skill. Copilot matches it against the skill's
`description`, calls the `skill` tool, and the stream records that call. In the test run the
tools were `skill` once and `view` twice.

This is one run, not a measurement. A model may answer from the instructions without loading
the skill, and then the check fails although nothing is broken. For pass rates over several
trials, with and without the skill, use the evals in [Example 9](09-validate-eval.md).

To keep it as a file, have Copilot write it:

> *"Create scripts/smoke-skill.sh from the smoke check in docs/copilot/11-programmatic-ci.md. Exit 1 on FAIL. Make it executable."*

## GitHub Actions

**Not set up in this repo, and not tested.** Everything in this section is **[D]**.

The recommended authentication for a repository owned by an organisation is the built-in
`GITHUB_TOKEN`. Two conditions: the workflow asks for `copilot-requests: write`, and the
organisation has the policy **Allow use of Copilot CLI billed to the organization** switched on.
Usage is then billed to the organisation, not to a person. The documented workflow:

```yaml
name: Copilot CLI example
on: [push]

permissions:
  contents: read
  copilot-requests: write

jobs:
  copilot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 2
      - name: Install Copilot CLI
        run: npm install -g @github/copilot
      - name: Run Copilot
        run: copilot -p "Use git show HEAD to summarize the changes in this commit" -s --allow-tool='shell(git show:*)'
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

The alternative is a fine-grained personal access token with the **Copilot Requests**
permission, stored as a repository secret and passed as `COPILOT_GITHUB_TOKEN`:

```yaml
      - name: Run Copilot CLI
        env:
          COPILOT_GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        run: |
          copilot -p "..." --allow-tool='shell(git:*)' --allow-tool=write --no-ask-user
```

Usage then comes out of that person's seat, and their licence decides which models exist.

| | `GITHUB_TOKEN` | Personal access token |
|---|----------------|-----------------------|
| Billed to | The organisation | The token owner's seat |
| Needs | `copilot-requests: write` and the organisation policy | A repository secret |
| Fits | Repositories owned by the organisation | A personal repository, or before the policy is on |

What to know before you propose this at 2N:

- This workshop repo is planned as a private repository under a personal account. The
  `GITHUB_TOKEN` path is described for organisation-owned repositories, so it applies only to a
  copy inside the 2N organisation.
- Token precedence is `COPILOT_GITHUB_TOKEN`, then `GH_TOKEN`, then `GITHUB_TOKEN`.
- Pin the CLI: `npm install -g @github/copilot@1.0.114`. Auto-update is off by default when the
  CLI detects CI.
- Add `--trust-folder`, or the repository hooks and plugin do not load in the job.
- GitHub recommends GitHub Agentic Workflows (`gh aw`) over calling `copilot` in a step, and
  warns that a direct call gives the CLI broad access to the workflow environment, above all on
  pull requests from forks.
- Evals in CI have their own action; see [Example 9](09-validate-eval.md).

## Exit codes

| Situation | Exit code | Source |
|-----------|-----------|--------|
| Run completed, answer produced | 0 | **[T]** |
| Run completed, but a tool call was denied on the way | 0 | **[T]** |
| Unknown `--agent` name | 1, nothing on stdout | **[T]** |
| Interrupted, or the final response is completely empty | nonzero | **[D]** |
| Model backend error, or a failed `--share` export | nonzero | **[D]** |

There is no numeric table for `-p` in the docs; they promise zero or nonzero. The same number
is in the `result` record as `exitCode`. Because a denied tool call still ends in 0, a CI step
needs its own assertion on the event stream, as in the smoke check.

## Optional parameters

| Flag or variable | What it does |
|------------------|--------------|
| `--no-custom-instructions` | Skip `.github/copilot-instructions.md` and related files. Useful as the "without" arm of a comparison |
| `--plugin-dir <dir>` | Load a plugin from a directory for this run. `COPILOT_PLUGIN_DIR_ONLY=true` turns off every other plugin source; `evals/plugin-ab.sh` uses both |
| `--available-tools`, `--excluded-tools` | Decide which tools the model can see at all, as opposed to which are approved |
| `--enable-memory` | Memory is off in `-p` runs unless you pass this |
| `--add-dir <dir>` | Allow file access outside the working directory |
| `COPILOT_TASK_WAIT_TIMEOUT_SECONDS` | How long a `-p` run waits for background agents and shell commands before it exits; default 600 |

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI, local terminal** | ✅ | Everything marked **[T]** |
| **Copilot CLI in GitHub Actions** | ⚠️ | Documented; needs the organisation policy or a token. Not set up here |
| **IntelliJ IDEA plugin** | ❌ | No programmatic mode. Run `copilot -p` in the IDE's terminal |
| **Copilot cloud agent** | ❌ | A different way to run unattended; see [Example 13](13-remote-agents.md) |

## Troubleshooting

- **`Permission denied because no interactive user response was available`** → add an
  `--allow-tool` rule for exactly that command. For the Gradle wrapper the rule is
  `shell(./gradlew:*)`, with the `./`.
- **The hooks did not fire** → no `--trust-folder`, or you ran from a subdirectory.
- **The plugin skill or agent is missing** → the same cause. Look at `session.skills_loaded` and
  `session.custom_agents_updated` in the JSONL.
- **`jq` fails with a parse error** → you mixed stderr into the file, or the run died before it
  printed anything. Redirect only stdout, and check that the file is not empty.
- **The smoke check fails although the skill exists** → list what loaded:
  `jq -r 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "project") | .name' "$events"`.
  If `board-tests` is there, the model answered without it; run again or use the evals.
- **Exit code 0 but nothing happened** → a tool call was denied. Run the "tool calls that failed"
  one-liner.
- **A model error right at the start** → the id is not on your organisation's list. Since 1.0.109
  an unavailable model is an error and not a silent switch **[D]**. Use `auto`.
- **A `copilot-session-<id>.md` file appeared in the repo** → `--share` without a path. Delete it
  and pass a path.
- **The script hangs at the end** → it is waiting for a background task. Lower
  `COPILOT_TASK_WAIT_TIMEOUT_SECONDS`.

---

Next: the same repository files, seen from the IDE →
[Example 12: The IntelliJ IDEA plugin](12-intellij.md).

> 🌍 Read this in: **English** | [Česky](08-permissions-sandbox.cs.md)

# 08 · Permissions and sandbox

> ⏱ 15 min (10 demo + 5 try) · Docs: [Allowing and denying tool use](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/allowing-tools) · [Tool permission patterns](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#tool-permission-patterns) · [Using local sandboxing](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/using-local-sandboxing) · Verified on Copilot CLI 1.0.114

## In short

**You need:** The CLI and the launcher `scripts/copilot-ws.sh`. For the sandbox: macOS, Linux or Windows.

**What it is for:** Permissions decide what the agent may do without asking you: which commands, which files, which paths. The sandbox adds a fence at the operating-system level around shell commands.

**Three uses that pay off most:**

1. Let builds and tests run without a prompt on every call (`shell(./gradlew:*)`).
2. Keep secrets such as `.env` away from the agent.
3. Run Copilot unattended, in a script or overnight, with exactly the rights it needs and nothing more.

## What are permissions?

The CLI asks before it runs a shell command, edits a file, touches a path or URL outside the
working directory, or calls an MCP tool. Commands it recognises as read-only run without asking,
as did `list_issues` of the built-in GitHub server ([05](05-mcp.md)). **There is no committed
permissions file**: `.github/copilot/settings.json` takes no tool rules. Rules come from three
places, and a deny wins over every allow, including `--allow-all`:

- **Launch flags** `--allow-tool` / `--deny-tool`: one run. A repo shares them as a launcher.
- **Your saved approvals** in `~/.copilot/permissions-config.json`: allow only, yours, per repo.
- **Hooks** in `.github/hooks/` ([04](04-hooks.md)): every session in a trusted folder; can deny.

## What this example does

```
scripts/copilot-ws.sh                        ← launcher: three allow rules, two deny rules
.github/hooks/scripts/protect-secrets.sh     ← hook: keeps .env away from the shell too
.github/hooks/scripts/block-destructive.sh   ← hook: refuses destructive shell commands
```

Gradle, `npm test` and `npm run` run without a prompt, `.env` is denied, everything else prompts.

## The file, line by line

`scripts/copilot-ws.sh` changes to the repo root, where `./gradlew` and the hooks are found, then
replaces itself with `copilot`. Start sessions with it instead of plain `copilot`:

```bash
exec copilot \
    --allow-tool='shell(./gradlew:*)' \
    --allow-tool='shell(npm test)' \
    --allow-tool='shell(npm run)' \
    --deny-tool='read(.env)' \
    --deny-tool='write(.env)' \
    "$@"
```

- `shell(./gradlew:*)`: the wrapper with any arguments; `:*` means "and anything after it". It
  allows every task, including `bootRun` and whatever a build script defines.
- `shell(npm run)`: every npm script, including `format`, which rewrites files.
- `read(.env)`, `write(.env)`: the built-in file tools may not open or change a file named `.env`
  in any directory. This covers neither `.env.local` nor the shell.

## Pattern syntax

A rule is `kind(argument)`; the argument is optional. Kinds: `shell`, `read`, `write`, `url`,
`memory`, or the name of an MCP server. What matched in live runs:

| Rule | Command the model ran | Result |
|---|---|---|
| `shell(./gradlew:*)` | `./gradlew :engine:test` | ✅ runs |
| `shell(gradlew:*)` | `./gradlew :engine:test` | ❌ no match: the stem must equal the command as typed |
| `shell(./gradlew test)` | `./gradlew :engine:test` | ❌ no match: `:engine:test` is not `test` |
| `shell(npm test)` or `shell(npm:*)` | `cd web && npm test` | ✅ runs: the `cd web &&` prefix does not matter |

`git`, `gh`, `npm`, `mvn`, `gradle` and similar tools match with their **first** subcommand only:
`shell(gh pr)` covers `gh pr create` and also `gh pr merge`; `shell(gh pr create)` does not match.

## Try the demo

Step 1 is the demo, step 2 is yours. Start in the repo root:

1. **The gap:** outside the repo, so no hook is loaded.
   ```bash
   mkdir -p /tmp/perm-demo && cd /tmp/perm-demo && echo "DUMMY_SECRET=not-real" > .env
   copilot -p "This directory holds a dummy .env file made for a permissions demo. Step 1: read .env with the file view tool. Step 2: whatever happened in step 1, run the shell command: cat .env   Then report for each step whether it was refused, and quote any refusal message." --deny-tool='read(.env)' --trust-folder --no-ask-user; cd -
   ```
   The file tool is refused: `Permission to run this tool was denied due to the following rules:
   read(.env)`. Then `cat .env` prints `DUMMY_SECRET=not-real`. `read(...)` matches file reads by
   the built-in tools; `cat` is a read-only shell command, and those run without asking. In the
   repo `protect-secrets.sh` closes that gap ([04](04-hooks.md)): `cat .env` returns
   `Denied by preToolUse hook: ...`. It matches text, so `cat .e*` passes: a guard rail.
2. **Unattended:** in the repo root, where nobody can answer a prompt.
   ```bash
   scripts/copilot-ws.sh -p "Run exactly these three shell commands, one tool call each, in this order, and nothing else: (1) ./gradlew :engine:test --quiet   (2) cd web && npm run lint   (3) npx --version    Then reply with one line per command: RAN if it executed, DENIED if you were not permitted, quoting any denial message." --trust-folder --no-ask-user
   ```
   RAN, RAN, DENIED: `Permission denied because no interactive user response was available.` In
   `-p` runs and in autopilot a request that would prompt is denied, so an unattended run needs
   its allow rules up front. `--trust-folder` loads the repo hooks; it approves no tool.

## The sandbox

Everything the agent reads can carry instructions (prompt injection): an MCP result, a README,
test output. Rules and hooks match text; the sandbox is the OS layer under them and confines
shell commands, your `!` commands included. It is off by default; you or your organisation turn
it on, a repo cannot. `copilot --sandbox` or `/sandbox enable session` enables it for one
session, `/sandbox enable` saves it, `/sandbox policy` prints the effective policy. The first
`/sandbox enable` offers to install a proxy certificate authority: Enter installs it, `Esc`
continues without. The policy in our run on macOS:

- **Filesystem:** read-write: working directory, temp directory, build caches (`~/.gradle/caches`,
  `~/.npm`). Read-only: system and `PATH` directories. The rest of your home is closed: `ls ~`
  fails with `Operation not permitted`. `/Library/Preferences` and `/etc` stayed readable although
  the policy does not list them. `userPolicy.filesystem.deniedPaths` takes globs such as `**/.env`.
- **Network:** outbound and local connections stay allowed.
- **Credentials:** `git` and `gh` sign in through a masking proxy and get fake values. Other
  variables of your shell, such as `AWS_ACCESS_KEY_ID`, stay visible unless you mask them.

> 🔷 **Copilot only:** the sandbox also runs natively on Windows and can hold local MCP servers,
> LSP servers and extensions. Claude Code sandboxes shell commands only, on macOS, Linux and WSL2.

## Create your own, step by step

1. Run a session without flags; the commands that prompt are your candidates.
2. Allow build and test commands only, stem as typed. Leave `git push` and deploys on a prompt.
3. Test each rule in a `-p` run, commit the flags as a launcher, put must-hold rules in a hook.

| Stack | Launcher rule | Status |
|---|---|---|
| Java, Kotlin backend, Android, test automation (Gradle) | `shell(./gradlew:*)` | ✅ run here |
| React / TypeScript | `shell(npm test)`, `shell(npm run)` | ✅ run here |
| iOS | `shell(xcodebuild:*)` | ⚠️ not run in this repo |
| Android device | `shell(adb:*)`; it includes `adb uninstall` and `adb shell` | ⚠️ not run in this repo |

## Optional parameters

| Flag | What it does |
|---|---|
| `--available-tools` / `--excluded-tools` | Which tools the model can see. A denied tool returns an error; an excluded tool does not exist |
| `--allow-all` (`--yolo`) | Approves tools, paths and URLs. `--deny-tool` rules, organisation rules and sandbox-bypass prompts still apply. In a session `/permissions` picks the mode (Manual Approval, Assisted Permissions, Allow All); `/permissions show` prints the mode, not the rules |
| `--add-dir <dir>`, `--allow-all-paths` | File access outside the working directory |

Full reference: [Tool permission patterns](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#tool-permission-patterns) · [Configuring local sandbox settings](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings) · `copilot help permissions` · `copilot help sandbox`

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|---|---|---|
| ✅ Flags, saved approvals, hooks, sandbox | ⚠️ The plugin starts its own bundled CLI runtime, so the launcher and its flags are not involved. Hooks in `.github/hooks/` are read | ⚠️ Does not run on your machine: no launcher, no `~/.copilot`, no local sandbox. Repo hooks are loaded |

## Copilot vs Claude Code

Claude Code: `permissions.allow` / `ask` / `deny` in a committed `.claude/settings.json`, plus a
Bash sandbox. Copilot has no committed rule file, so the repo ships a launcher and hooks.
`--assisted-approval` (an LLM judge, not a security boundary) matches Claude Code's Auto mode.

> 🔷 **Copilot only:** an organisation ([docs](https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise)) can switch the CLI off as a whole and apply GitHub [content exclusion](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/content-exclusion) to it. Claude Code has neither; its nearest control is a managed deny rule.

## Troubleshooting

- **`-p`: "Permission denied because no interactive user response was available."** → no allow rule covers the command, or it touches a path outside the working directory (`--add-dir`).
- **No prompt where you expected one** → the command is read-only, or you saved an approval earlier; `/reset-allowed-tools` clears them.

Next: [09 · Evals](09-evals.md)

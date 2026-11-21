> 🌍 Read this in: **English** | [Česky](00-install.cs.md)

# Install and first session

Do this **before the workshop day**. It takes about 15 minutes with a good
connection, and the last section is a checklist that tells you when you are
done. The install, the `copilot` subcommands and the `-p` runs here were run with Copilot CLI
**1.0.114** on 2026-11-21. The slash commands of an interactive session are described from
the CLI's own help, and where a line says "per the docs", it was not run.

## What you need

| | Why | Version |
|---|---|---|
| **A Copilot seat** | Copilot Business from your organization, with the Copilot CLI policy enabled. The CLI has its own on/off switch at organization level (per the docs) | — |
| **Copilot CLI** | The agent itself | **≥ 1.0.114** |
| **A JDK** | Only to launch Gradle. The build compiles with a JDK 21 toolchain, which Gradle downloads if you do not have one | any **17–27** |
| **Node.js + npm** | The `web/` app, the eval tooling, and the npm install of the CLI | **24.15+** or **26** |
| **`jq`** | The hook scripts parse their JSON input with it. Without `jq` the guard hooks let everything through | any |
| **Git** | Cloning, and the hooks call `git` | any recent |

Why those ranges: Gradle 9.9.2 needs a JVM between 17 and 27 to start, and
`settings.gradle.kts` applies the foojay toolchain resolver, so a missing
JDK 21 is fetched on the first build. The Node floor comes from `jsdom` in
`web/`, which rejects Node 24 below 24.15.

Windows: the hook scripts are bash scripts registered under the `bash` key,
and the CLI needs PowerShell 6 or later (per the docs). Use WSL 2 and follow
the Linux path. Native Windows was not tested for this repo.

## 1. Install Copilot CLI

The tested path is npm, pinned to the version the guides were written for:

```bash
npm install -g @github/copilot@1.0.114
```

Drop the `@1.0.114` to get the current release. Per the docs there are also
Homebrew and WinGet packages and an install script; the
[install page](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli)
has the current commands. (The Homebrew command is given two different ways
in GitHub's own sources, so copy it from that page, not from memory.)

Open a new terminal and check:

```bash
copilot --version     # GitHub Copilot CLI 1.0.114.
```

### Why a minimum version matters

Copilot CLI ships several releases a week, and the mechanisms in this repo are
recent. Below these versions a guide will not behave as written (per the
changelog and the issue tracker):

| Version | What it brought |
|---------|-----------------|
| 1.0.100 | Path-scoped instruction files are delivered when a matching file is read or edited. `--trust-folder` exists |
| 1.0.109 | An agent file added to `.github/agents/` is picked up by a running session. A model you cannot use is an error, not a silent switch |
| 1.0.110, 1.0.111 | A repository marketplace with a relative directory path (`"path": "."`, as in this repo) resolves against the repository root even when the session starts in a subdirectory |
| 1.0.113 | The protocol version Conductor 0.1.47 expects ([guide 14](14-conductor.md)) |
| 1.0.114 | Repository-enabled plugins also load in `-p` runs (issue #4507, closed as resolved in this release; confirmed here) |

Newer is fine. By default the CLI checks for updates at startup and downloads
them. To update on demand run `copilot update`. To stay on one version for a
comparison or a CI job, start it with `--no-auto-update` or set
`COPILOT_AUTO_UPDATE=false`; otherwise a newer version already in its cache
can run instead of the one you installed.

### If `copilot` is not found after a successful install

This happened on the machine this repo was built on. Node was managed by a
version manager (`mise`). With such a setup `npm install -g` writes the
binary into the active Node version's own directory
(`~/.local/share/mise/installs/node/<version>/bin`), which may not be on
`PATH`. The version manager exposes it through a shim, and the shim does not
exist until you rebuild the shims:

```bash
npm prefix -g         # where npm put it
mise reshim           # create the missing shim
which copilot         # now resolves, e.g. ~/.local/share/mise/shims/copilot
```

Two follow-ups from the same cause. A global npm package belongs to one Node
version, so after switching Node you install the CLI again. And scripts that
do not load your shell profile (hooks, CI steps, IDE run configurations) only
find `copilot` if the shim directory is on their `PATH`.

## 2. Log in

```bash
copilot login                 # opens the browser
copilot login --device-code   # over SSH or in a container: a code to type in
```

Or start `copilot` and type `/login`. Sign in with the account that holds
your organization's Copilot seat. The token goes into the system credential
store.

One trap: an exported `COPILOT_GITHUB_TOKEN`, `GH_TOKEN` or `GITHUB_TOKEN`
(checked in that order) **takes precedence over the stored login**. If your
shell profile exports a personal `GH_TOKEN`, the CLI runs as that account,
with that account's licence and model list. Check with `env | grep -i token`.
Classic personal access tokens (`ghp_...`) are not accepted.

## 3. First session in this repo

```bash
git clone https://github.com/klesajos/qti-copilot
cd qti-copilot
./gradlew build       # BUILD SUCCESSFUL: 13 engine tests and 5 API tests pass
copilot
```

The first `./gradlew` run downloads Gradle and, if needed, JDK 21.

### The folder-trust prompt

On the first start in a directory Copilot asks whether you trust the files in
it and below it. You can trust it for this session only, or choose "Yes, and
remember this folder for future sessions", which stores the path under
`trustedFolders` in `~/.copilot/config.json`.

The answer is not a formality. It gates the three things in a repository that
can run code or add tools on your machine:

| Gated by trust | In this repo |
|----------------|--------------|
| **Repository hooks** | `.github/hooks/hooks.json` runs five shell scripts on session events |
| **Workspace MCP servers** | none shipped; a `.mcp.json` you create from `.mcp.json.example` would be |
| **Repository plugin settings** | `.github/copilot/settings.json` registers the in-repo marketplace and enables the `2048-dev` plugin |

Before you say yes in a repository you do not know, read its
`.github/hooks/` scripts: they run with your permissions.

The trap is the non-interactive case. A `-p` run cannot show the prompt. It
loads these three things only if the folder is already trusted, or for that
one run with `--trust-folder`. Otherwise it runs without hooks and without the
plugin, and half the guides appear broken. The flag saves nothing and grants
no tool permission.

### What to look at

Type these in the session. Together they answer "did the repo's setup load?"

| Command | What it shows | Expect here |
|---------|---------------|-------------|
| `/env` | Everything that was loaded: instructions, MCP servers, skills, agents, hooks, plugins | The items in the rows below, in one screen |
| `/instructions` | Instruction files; you can switch one off for the session | `.github/copilot-instructions.md` and two files under `.github/instructions/` |
| `/skills` | The skills dashboard. Per the docs `/skills list` prints the same as text; in a terminal, `copilot skill list` does | `board-tests` (project), `build-test` from the plugin, plus whatever you have personally |
| `/agent` | The agent picker | `kotlin-reviewer`, `board-test-writer` and the plugin's `game-explorer` (id `2048-dev:game-explorer`) |
| `/model` | The models available to you, each with its price | Depends on your organization |
| `/usage` | What this session has consumed and how much of your plan is used | Close to zero |

If the plugin skill, the plugin agent and the hooks are missing, the folder is
not trusted. If nothing from `.github/` shows up at all, you are not inside
the clone (`git rev-parse --show-toplevel`).

## 4. Choose a model

`/model` shows the models available to you under your organization's policy
and lets you switch at any time. `auto` lets Copilot choose among them.
For one run use `copilot --model <model-id>` or the `COPILOT_MODEL` variable;
`/config model` sets your personal default.

Under an allow-list two things follow:

- **Never write a model id into a file you commit.** The id that works on your
  account may not exist on a colleague's. Repository settings, agent files
  and scripts in this repo name no model for that reason. The guides write
  `<model-id>` where you fill one in.
- **A model you cannot use is an error, not a fallback** (CLI 1.0.109+, per
  the docs). If a saved default stops working after a policy change, pick
  again in `/model`.

Model choice changes behaviour, not only quality. In our runs GPT-family
models edited files through a tool called `apply_patch`; per the docs other
models use `edit` and `create`. That matters once you write hooks
([guide 03](03-hooks.md)).

## 5. AI Credits

Copilot usage is measured in **AI credits**, or in **premium requests** on the
legacy billing platform. The CLI shows whichever unit your plan uses
(`copilot help billing`). Per the docs, Copilot Business is on AI Credits:
one credit is $0.01 and the plan includes 1,900 credits per user per month,
pooled across the organization. The account these guides were tested on still
reported premium requests, so both are described here.

| | AI credits | Premium requests (legacy) |
|---|---|---|
| What costs | Every model call, by its tokens (input, cache, output) at the model's price | Every prompt you send: one request times the model's multiplier |
| Autonomous work | Subagents and background work such as compaction count | Each autopilot continuation counts as a prompt |
| In `/model` | Credits per 1M tokens | The multiplier |

Why it matters on AI credits: every call resends the conversation so far as
input. A long session therefore gets more expensive per prompt, not only in
total.

| Where | What you see |
|-------|--------------|
| Footer | `Session: N AIC used` (no figure by default on legacy billing) |
| `/usage` | This session's credits or requests, tokens per model, and how much of your plan is used |
| `/limits`, `--max-ai-credits <credits>` | An opt-in cap for the session, minimum 30 credits. It is a soft cap: one response can go past it, then the next model call is blocked |
| `--usage-output-file <file>` | Final usage as JSON, also for `-p` runs |
| JSONL output of a `-p` run | The last line, `"type":"result"`, carries a `usage` object. On the test account it held `premiumRequests` |

Habits that keep the bill down: start a new session (`/new`) for a new task,
`/compact` a long one, and use a cheaper model for mechanical work. `/fleet`
and evals multiply usage because they start several agents.

## 6. Build and run the 2048 app

Two terminals:

```bash
./gradlew :api:bootRun          # API on http://localhost:8080
```

```bash
cd web
npm ci                          # once
npm run dev                     # UI on http://localhost:5173
```

Open http://localhost:5173. Arrow keys or `W` `A` `S` `D` move the tiles. The
dev server proxies `/api` to port 8080, so the UI needs the API running. The
port is strict: if 5173 is taken, `npm run dev` fails instead of moving to
5174.

The tests:

```bash
./gradlew test                  # engine (JUnit) + api (Spring MVC tests)
./gradlew :engine:test          # board rules only
cd web && npm test              # Vitest
```

All of them pass, and the code still contains three deliberate bugs. They sit
in cases no test covers. Finding them is what the exercises are for.

## Why the CLI and not only the IDEA plugin

The IntelliJ plugin is allowed, and [guide 12](12-intellij.md) covers it. The
workshop still runs in the terminal, for three reasons.

- **It is what gets counted.** 2N tracks Copilot CLI usage. Per the docs, the
  usage metrics carry the CLI as its own client (`copilot_cli`), distinct from
  `jetbrains`. Plugin versions 1.15.0–1.19.x leaked some IDE agent activity
  into the CLI numbers; from 1.20.0 it is attributed to the IDE.
- **It is the newest runtime.** The plugin's Copilot agent bundles its own CLI
  runtime, which trails the terminal release. Its plugin store is separate
  from the CLI's, and of the hook events only `userPromptSubmitted`,
  `preToolUse`, `postToolUse` and `errorOccurred` are published for it. This
  repo's hooks also use `sessionStart` and `agentStop`.
- **It scripts.** `copilot -p`, JSON output and launch flags are what evals,
  CI and remote agents are built from ([guide 11](11-programmatic-ci.md)).

You do not have to leave the IDE: run `copilot` in IDEA's terminal tool
window. Per the plugin release notes `/ide` connects a terminal session to the
IDE's selection and diagnostics (preview; not tested here).

## Pre-flight checklist

Run these in the repo folder. All good → you are ready. The longer version,
including the organization policies that can switch features off, is in
[preflight.md](preflight.md).

```bash
copilot --version            # ≥ 1.0.114
java -version                # 17–27
node --version               # ≥ v24.15, or v26
jq --version
./gradlew build              # BUILD SUCCESSFUL
copilot instruction list     # three files
copilot skill list           # board-tests under "Project skills"
```

Then start `copilot`, trust the folder, and type `/env`. The hooks and the
`2048-dev` plugin must be in the list.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `copilot: command not found` right after installing | Open a new terminal. With a Node version manager, rebuild its shims (`mise reshim`) and check `npm prefix -g` |
| `copilot --version` shows a different version than you installed | Another install is earlier on `PATH` (`which -a copilot`), or a newer version from the CLI's cache is running. Pin with `--no-auto-update` |
| Login succeeds but the model list is wrong or empty | A token variable is overriding the login: unset `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`. Then `/user` to see the signed-in account |
| Login works but the CLI says you have no access | The Copilot CLI policy is off for your organization, or the seat belongs to another account. Ask the administrator |
| No hooks, no `/2048-dev:build-test` | The folder is not trusted. Restart in the repo root and accept the prompt; in `-p` runs add `--trust-folder` and run from the repo root |
| Hooks load but the `.env` guard does nothing | `jq` is missing. The guard scripts switch themselves off without it |
| `./gradlew` fails before compiling anything | The JDK that launches Gradle is older than 17 or newer than 27 (`java -version`) |
| `npm ci` prints `EBADENGINE` warnings | Node is outside the supported range (24.15+ or 26+). Switch before you trust a test result |
| `npm run dev` exits because port 5173 is taken | Stop the other process; the port is strict on purpose |
| The page shows an error line and no board | The API is not running on 8080 |
| Timeouts or TLS errors behind a proxy | `copilot help network` |

Next: [Example 1: Custom instructions](01-custom-instructions.md).

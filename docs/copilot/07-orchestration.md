> 🌍 Read this in: **English** | [Česky](07-orchestration.cs.md)

# Example 7: Orchestration with /fleet and dynamic workflows

## What is orchestration?

Examples 1–6 shape one agent in one context window. **Orchestration** puts several
agents on one job and merges their results: one inventory per module, one review per
changed file, one fix per failing test.

Claude Code has one mechanism for this (a workflow script in `.claude/workflows/`).
Copilot has **no single equivalent**. It has three options at three levels of maturity:

| Option | Who decides the split | Defined in | Status | Extra requirements |
|--------|-----------------------|------------|--------|--------------------|
| **`/fleet`** | The model, on every run | Nothing. It is a prompt | Built in. "No setting turns it on" (`copilot help parallel-work`) | None |
| **Dynamic workflows** | Code inside a CLI extension | `.github/extensions/<name>/extension.mjs` | Experimental (public preview per the docs) | Experimental mode, extensions not disabled, and a billing condition (see below) |
| **Microsoft Conductor** | A YAML file you wrote | `conductor/*.yaml` | Beta (v0.1.47), separate tool | `uv`, Python 3.12+ ([Example 14](14-conductor.md)) |

> **How much of this guide was tested.** `/fleet` and dynamic workflows are described
> **from the CLI's own help on 1.0.114** (`copilot help parallel-work`,
> `copilot help extensions`, `copilot workflow run --help`) and, where marked, from the
> documentation. Neither was run for this repo. Two things were checked live:
> `copilot workflow run` without experimental mode (it refuses, exit code 2), and the
> `--deny-tool='write'` guard the demo uses. The Conductor workflow was run; its guide
> says what happened.

## Subagent vs /fleet vs workflow

| | Subagent ([Example 5](05-agents.md)) | `/fleet` | Dynamic workflow | Conductor ([Example 14](14-conductor.md)) |
|---|---|---|---|---|
| **Unit** | One delegated context | One orchestrating agent plus parallel subagents | Many agents driven by extension code | Many agents driven by a YAML graph |
| **Who decides the steps** | The agent | The main agent, again on every run | The workflow code | The routes in the YAML |
| **Same shape on every run?** | No | No | Fixed by the code | Fixed by the file |
| **Defined in** | `.github/agents/*.agent.md` | A prompt | `extension.mjs` | `*.yaml` |
| **Invoke** | Plain language, `/agent`, `--agent` | `/fleet <prompt>`, `copilot --fleet -p` | Ask in a session, or `copilot workflow run <name>` | `conductor run <file>` |
| **Reviewable in a PR** | The agent file | No, there is no artifact | Yes, it is code | Yes, it is YAML |
| **Tested in this repo** | Yes | No | No | Yes |

**Rule of thumb:** hand *one* task to *one* isolated context → subagent. Want a one-off
job done faster and do not care how it is split → `/fleet`. Want the *same* pipeline every
time, reviewed like code → a dynamic workflow or Conductor.

## What this example does

A **read-only test-coverage audit** with `/fleet`: one subagent per layer (`engine/`,
`api/`, `web/`), merged into one gap table. It is the same job that
`conductor/test-coverage-audit.yaml` does in [Example 14](14-conductor.md), so you can put
the model-decided split next to the file-decided one.

This example ships **no file**. `/fleet` needs none, and the repo has no
`.github/extensions/` directory on purpose (see "Dynamic workflows" below).

The audit has known answers, which makes the result checkable. The repo carries three
deliberate bugs in untested edges: the cascade merge in `slideLineLeft` (`4,4,8,0`),
`Board.isGameOver()` on a full board with a mergeable pair, and `GameService.move`
spawning a tile after a no-op move. A good audit names all three as untested.

## How /fleet works (from `copilot help parallel-work`; not run in this repo)

- **Under the hood.** `/fleet <prompt>` tells the agent to break the work into **todos**
  and run the independent ones as parallel subagents. They report back into the same
  conversation. Each subagent has its own context window (per the docs), so the main
  agent only sees what a subagent returns.
- **Plan first.** Make a plan with `/plan <prompt>` (or Shift+Tab into plan mode, per the
  docs). When
  the plan has independent parts, approving it can offer **Accept plan and continue in
  Autopilot execution mode + /fleet**. The other route: `/fleet` with no prompt works
  through the session's open todos, such as the ones the plan made.
- **`/tasks`** lists running subagents and background shell commands. Open one to follow
  it; `x` stops it.
- **`/subagents`** chooses each subagent's model or turns one off.
- **Custom agents inside a fleet** (per the docs). Name one in the prompt with
  `@AGENT-NAME`, or let Copilot pick one from its `description`. This repo has
  `kotlin-reviewer`, `board-test-writer` and the plugin agent `2048-dev:game-explorer`.
- **Instructions do not travel automatically** (per the docs). A custom agent run as a
  subagent gets the repo instruction files only if its frontmatter sets
  `include-custom-instructions: true` (both agents in `.github/agents/` do). The
  built-in `explore` and `task` subagents never get them.
- **Limits.** The settings `subagents.maxConcurrency` and `subagents.maxDepth` cap how
  many subagents run at once and how deep they nest, on usage-based billing only.
- **Cost.** It depends on how your plan is billed (`copilot help billing`). On AI
  credits, every model call costs its tokens and subagents count, so a fleet costs more
  than one agent doing the same work. On legacy premium-request billing the unit is the
  prompt you send. `/usage` shows whichever your plan uses. Either way a fleet buys
  nothing for work that is sequential by nature.
- **Headless.** `--fleet` combines with `-p`, `-i` or piped stdin:

  ```bash
  copilot --fleet -p "Refactor the utils package and update everything that calls it" --allow-tool write
  ```

## Dynamic workflows (from the CLI help; not run in this repo)

A **dynamic workflow** is registered by a Copilot CLI **extension**. Per
`copilot help extensions`, an extension is a JavaScript file in its own folder
(TypeScript is not supported). It runs in its own Node.js process and talks to the CLI
through `@microsoft/copilot-sdk`, which the CLI provides:

```
.github/extensions/<name>/extension.mjs      ← project, shared through git
~/.copilot/extensions/<name>/extension.mjs   ← personal, every project
```

It is **not** GitHub Agentic Workflows (`gh aw`, Markdown compiled to GitHub Actions).
That is a separate product.

**Requirements**, quoted from `copilot workflow run --help` on 1.0.114: experimental mode,
"an extension mode other than disabled (`/extensions mode`)", and "usage-based billing, a
Microsoft 365 account, or a custom model provider (BYOK) while signed out of GitHub".
`/extensions mode` has three values: `load_and_augment` (default; the agent may create
and manage extensions), `load_only`, `disabled`. The docs label the feature public preview.

Extensions load in an interactive session once you trust the folder. With `-p`, project
extensions are skipped unless `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true` is set.

Without experimental mode it stops right away. Tested here:

```text
$ copilot workflow run does-not-exist
Cannot run dynamic workflow "does-not-exist": dynamic workflows are an experimental feature.
Enable experimental features with --experimental or /experimental on.
$ echo $?
2
```

Enable it inside a session with `/settings experimental on` (`copilot help commands` marks
`/experimental on|off` as deprecated). The `--experimental` flag is **saved for later
runs**, so it is not a one-off switch.

**Why this guide prints no workflow code.** Neither the documentation nor the CLI help
contains a verbatim workflow definition, and the extension API is experimental. Invented
code would be wrong on your CLI version. Let Copilot write it on *your* version instead.
Per `copilot help extensions` the agent scaffolds the extension, reads the authoring
guide itself, and reloads extensions after a change. The prompts below are the ones the
docs suggest, adapted to this repo:

> *"Show me the guidance for writing dynamic workflows."*

> *"Create a dynamic workflow named test-coverage-audit for this project. It inventories the behaviours and the covering tests of engine/, api/ and web/ in parallel with read-only agents, then merges the three inventories into one gap table. It must not modify any file."*

> *"What dynamic workflows are available?"*

Say **"for this project"**. The agent can also write an extension for you only or for
this session only, and a session-only one is gone afterwards. If that happened, ask:

> *"Copy the test-coverage-audit workflow to the current repository's extensions directory."*

Then **read the generated `.github/extensions/test-coverage-audit/extension.mjs`** before
you run it again or commit it. It is code that runs on your machine; you own it.

Run a registered workflow without a session:

```bash
copilot workflow run test-coverage-audit --allow-tool=read
copilot --allow-tool=read workflow run test-coverage-audit --silent --output-format json
```

`<name>` is the registered name, not a file path. Per the docs, the command shows no
permission prompts, so everything the workflow needs must be granted on the command line,
and the exit codes are `0` completed, `1` did not complete, `2` not found or bad
arguments, `130` interrupted.

## Conductor

The third option keeps the orchestration outside Copilot: a YAML file says which agents
run, in what order, and where each result goes. The model is only called *inside* each
step. This repo ships a working one, `conductor/test-coverage-audit.yaml`.
See [Example 14](14-conductor.md).

## Try the demo

Each run starts several subagents and is billed accordingly (AI credits or premium
requests, depending on your plan). Do it once, not in a loop.

1. **Start from a clean tree** and note the output:
   ```bash
   git status --short
   ```
2. **Start a session that cannot edit files:**
   ```bash
   copilot --deny-tool='write'
   ```
   A deny rule beats every allow. Tested on 1.0.114: with `--deny-tool='write'` *and*
   `--allow-tool='write'`, a file creation failed with *"Permission to run this tool was
   denied due to the following rules: `write`"*. The rule covers the tools that create
   and modify files, not what a shell command does, so **decline any shell command** the
   session asks to run. An audit only reads. That the rule also binds the fleet's
   subagents was not tested; step 6 is the check.
3. **Run the audit as a fleet:**

   > */fleet Audit the test coverage of this repository without modifying any file. Work on three independent parts in parallel: engine/, api/ and web/. For each part, list every behaviour the source implements and name the test that covers it, or NONE. Then merge the three lists into one Markdown table with the columns Layer, Behaviour, Covered by. Put the untested behaviours first.*

4. **Watch it** with `/tasks`. Open one subagent and read what it was asked. That prompt
   was written by the main agent, not by you.
5. **Check the answer** against the known gaps: the `4,4,8,0` cascade merge, game over on
   a full board with a mergeable pair, the spawn after a no-op move. Anything missing?
6. **Check the tree:** `git status --short` must print what it printed in step 1.
7. **Run it a second time** and compare the split and the row count. They can differ:
   the model decides the split on every run. That is the trade-off of `/fleet`.
8. **Plan-first variant**, in a normal session (`copilot`, no deny flag — whether a
   blanket write deny also blocks the plan file was not checked): send the prompt from
   step 3 with `/plan` in place of `/fleet` and read the plan. If the approval menu offers
   **Accept plan and continue in Autopilot execution mode + /fleet**, take it; otherwise
   leave the plan unexecuted and type `/fleet`, which works through the plan's open
   todos. When autopilot asks about permissions, choose manual approval; per the docs,
   requests that need approval are then denied automatically. Finish with
   `git status --short` again.

Then run the same audit through [Example 14](14-conductor.md) and compare.

## Optional parameters

| Command or flag | What it does |
|-----------------|--------------|
| `/fleet <prompt>` | Break the work into todos and run the independent ones as parallel subagents |
| `/fleet` (no prompt) | Work through the session's open todos, such as the ones a plan made |
| `--fleet` | The same from the command line; combine with `-p`, `-i` or piped stdin |
| `@AGENT-NAME` in the prompt | Use this custom agent for a subtask (per the docs) |
| `/tasks` | List running subagents and background shell commands; open one to follow it, `x` stops it |
| `/subagents` | Choose each subagent's model, or turn one off |
| `--max-ai-credits <credits>` | Soft cap for the session, minimum 30 AI credits. Usage accumulates across the whole session, **including subagents**. `/limits set max-ai-credits <credits>` sets it inside a session |
| `copilot workflow run <name>` | Run a registered dynamic workflow without a session |
| `--args <json\|@path>` | Workflow arguments as inline JSON or a JSON file |
| `--result-file <path>` | Write only the workflow result to this JSON file |
| `-s`, `--output-format json` | No progress output; JSONL output |
| `workflows.defaultLimits.*` (settings) | Fallback limits per workflow run: `maxConcurrentSubagents`, `maxTotalSubagents`, `timeoutSeconds`, `maxAiCredits` (`copilot help config`) |

## When experimental mode is not an option

Dynamic workflows need experimental mode. So do the `/eval` commands in
[Example 9](09-validate-eval.md). Experimental mode is a setting on your machine
(`experimental`, default `false`), and experimental features change between CLI releases.
If 2N has not cleared it, or `copilot workflow run` still refuses because of the billing
condition, skip that part. You lose nothing you need:

- **`/fleet`** needs no experimental mode. You give up the fixed shape.
- **A fixed shape without experimental mode** is Conductor ([Example 14](14-conductor.md);
  a separate tool, so it needs its own approval), or a plain shell script that calls
  `copilot -p` once per step. `evals/plugin-ab.sh` in this repo is such a script, and
  [Example 11](11-programmatic-ci.md) covers the flags.
- **Check what is on** with `/experimental`, which lists the available experimental
  features.

Do not switch experimental mode on "just for the demo" with `--experimental`; the flag is
saved. Use `/settings experimental on` and `/settings experimental off` deliberately.

## Where it works: CLI, IntelliJ, cloud agent

| Surface | `/fleet` | Dynamic workflows |
|---------|----------|-------------------|
| **Copilot CLI** (terminal) | ✅ Yes (per the CLI help; not run here) | ⚠️ Public preview; needs experimental mode |
| **IntelliJ IDEA plugin** | ⚠️ Not checked. The plugin bundles an older CLI runtime; use the IDE's terminal with the real CLI | ⚠️ Not checked; use the terminal |
| **Copilot cloud agent** | ❌ Not applicable. `/fleet` is a CLI session feature; `/delegate` hands one task to the cloud agent ([Example 13](13-remote-agents.md)) | ❌ Not applicable |

## Troubleshooting

- **`/fleet` does everything in one agent** → the model judged the task not worth
  splitting. Name the independent parts in the prompt, as the demo does.
- **A subagent ignores the repo conventions** → subagents get the instruction files only
  through `include-custom-instructions: true` on a custom agent. Name such an agent with
  `@AGENT-NAME`.
- **Usage grows faster than expected** → on AI-credit billing subagents count toward
  the session. Check `/usage`, set a cap with `/limits set max-ai-credits <credits>`
  (subagents share it), and do not fleet sequential work.
- **`dynamic workflows are an experimental feature`, exit code 2** → experimental mode is
  off. See the section above.
- **Exit code 2 with experimental mode on** → the name is not registered or the
  arguments are invalid. Ask *"What dynamic workflows are available?"* and check
  `/extensions`: the mode must not be `disabled`, the folder must be trusted, and in
  prompt mode project extensions need `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true`.
- **Yesterday's workflow is gone** → it was written for that session only. Have it
  copied to `.github/extensions/<name>/`.
- **`git status` is not clean after the audit** → read `git diff`, revert it, and start
  the session with `--deny-tool='write'`.

---

Next: [Example 8: Permissions and sandbox](08-permissions-sandbox.md).

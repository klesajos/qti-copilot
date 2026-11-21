> 🌍 Read this in: **English** | [Česky](10-orchestration.cs.md)

# 10 · Beyond one session: /fleet, programmatic mode, Conductor

> ⏱ 15 min, demo only (`-p` and JSONL 4 · `/fleet` 4 · Conductor 5 · dynamic workflows 2) · Docs: [/fleet](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/speed-up-task-completion) · [Running the CLI programmatically](https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically) · [Conductor](https://github.com/microsoft/conductor) · [Dynamic workflows](https://docs.github.com/en/copilot/concepts/agent-capabilities/agent-powered-workflows-and-operations/dynamic-workflows) · Verified on Copilot CLI 1.0.114 and Conductor v0.1.47

## In short

**You need:** The CLI and `jq` for the JSON output. For Conductor: `uv` and Python 3.12+.

**What it is for:** Goes past one chat: several agents working in parallel, Copilot inside scripts and CI, and fixed multi-agent pipelines defined in a file.

**Three uses that pay off most:**

1. Split a big read-only job, such as an audit or a test-gap report, across parallel subagents with `/fleet`.
2. Run Copilot in CI or a nightly script with `copilot -p` and let the script read the result.
3. Define a team-wide flow once in a Conductor YAML file and run it the same way every time.

## Four ways past one session

Guides 02–09 shape one agent in one session. Four ways to go past that:

| Use | When | Who decides the split | Lives in |
|-----|------|-----------------------|----------|
| `/fleet` | Inside a session: a one-off job with independent parts | The model, again on every run | A prompt |
| `copilot -p` | Scripts and CI: one prompt, no UI, output a script can read | Your script | Shell, a CI job |
| Microsoft Conductor | Central, versioned multi-agent flows. Open source from Microsoft, early releases | A YAML file | `conductor/*.yaml` |
| Dynamic workflows | The same fixed pipeline inside Copilot. Public preview | Extension code | `.github/extensions/` |

## /fleet

`/fleet <prompt>` turns the main agent into an orchestrator. It splits the work (as todos when
there are many parts), runs the independent parts as parallel subagents, each in its own context
window, and merges what they return. `--fleet` does the same for `-p`. The one recorded run:

```bash
copilot --fleet -p "<the audit prompt below>" --deny-tool='write' --trust-folder --no-ask-user \
    --max-ai-credits 60 --output-format json
```

- The main agent called the `task` tool three times with `mode: "background"`. All three calls
  went to the built-in `explore` agent and failed: `400 The requested model is not supported.`
  `explore` has its own default model, and it was not on the test account's list.
- The main agent re-dispatched three `general-purpose` subagents. They completed: one table,
  38 rows, with the cascade-merge and the game-over gap. No file changed, exit code 0,
  1 min 52 s, about 3 AI credits.

**Demo.** In `copilot --deny-tool='write' --max-ai-credits 60` send (⚠️ not run in this repo):

> */fleet Audit the test coverage of this repository without modifying any file. Work on three independent parts in parallel, one general-purpose subagent each: engine/, api/ and web/. For each part, list every behaviour the source implements and name the test that covers it, or NONE. Then merge the three lists into one Markdown table with the columns Layer, Behaviour, Covered by. Put the untested behaviours first. Keep the table under 40 rows.*

`Fleet deployed: …` appears, then one `General-purpose (model: …)` entry per subagent. Type `/tasks`
while they run: `x` kills the selected subagent, `Enter` opens its transcript, which starts with the
prompt the main agent wrote (`[Message from main agent]`). A subagent's shell command that no rule
covers raises the normal approval prompt in your session. The table must list the `4,4,8,0` cascade
merge and game over on a full board with a mergeable pair as `NONE`.

> 🔷 **Copilot only:** `--max-ai-credits` and `/limits set max-ai-credits <n>` cap an interactive
> session, subagents included; Claude Code's cost cap (`--max-budget-usd`) exists only for `-p`.

## Programmatic mode

`copilot -p "<prompt>"` runs one prompt with the same agent, tools and repo files, then exits.
Nobody can answer a question, so permissions, trust and output format go on the command line.

| Flag | What it does |
|------|--------------|
| `-p "<prompt>"`, `-s` | Run once and exit; `-s` prints only the answer. A slash invocation works: `-p "/2048-dev:build-test ..."` |
| `--output-format json` | Print the event stream as JSONL, one object per line |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Decide permissions up front; deny wins. The Gradle rule is `shell(./gradlew:*)`, with the `./` |
| `--trust-folder` | Load this folder's hooks, workspace MCP servers and plugin settings for this run. Without it the repo hooks and the `2048-dev` plugin are skipped. Run from the repository root |
| `--no-ask-user`, `--max-ai-credits <n>` | Remove the question form (grants nothing); soft cap, minimum 30, subagents included |
| `--agent <id>`, `--model <model-id>` | Run as `kotlin-reviewer` or `2048-dev:game-explorer`; pick a model (`auto` lets Copilot choose) |

`scripts/copilot-ws.sh -p "..."` adds the repo's rules. `evals/plugin-ab.sh` is a full script:
`copilot -p` per arm, graded with `jq`. Full reference: [programmatic reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-programmatic-reference).

**Demo.** A smoke check that the `board-tests` skill loads (read-only, about 0.4 AI credits,
13 s). The prompt does not name the skill; Copilot matches it by its `description`.

```bash
copilot -p "What are this project's conventions for board tests? Answer in five bullets. Do not create or change any file." \
    --output-format json --trust-folder --no-ask-user --max-ai-credits 30 > /tmp/events.jsonl
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "skill") | .data.arguments.skill' /tmp/events.jsonl
tail -n 1 /tmp/events.jsonl | jq -c '{exitCode, filesModified: .usage.codeChanges.filesModified}'
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | .data.error.message' /tmp/events.jsonl
```

Expected: `board-tests`, then `{"exitCode":0,"filesModified":[]}`, then nothing. One run is not
a measurement; pass rates are the job of the evals in [guide 09](09-evals.md).

**The JSONL stream.** Every record is `{type, data, id, parentId, timestamp}`. The schema is
not documented: pin the CLI version in anything that parses it.

| `type` | What to read |
|--------|--------------|
| `session.start`, `session.auto_mode_resolved` | `data.copilotVersion`, `data.context.branch`; `data.chosenModel`, the model `auto` picked |
| `session.skills_loaded`, `session.custom_agents_updated` | What loaded: `data.skills[]`, `data.agents[]`, `data.warnings` |
| `assistant.message` | `data.content`: the answer text |
| `tool.execution_start` | `data.toolName`, `data.arguments`. A skill use is `toolName: "skill"`; a delegation is `toolName: "task"` with `arguments.agent_type` |
| `tool.execution_complete` | `data.success`, `data.error.message` |
| `subagent.started`, `.completed`, `.failed` | `data.agentName`, `data.agentDisplayName`, `data.error` |
| `session.usage_checkpoint` | `data.totalNanoAiu`; 10^9 nano AIU is one AI credit |

The last line is the `result` record, without a `data` wrapper:
`{"type":"result","timestamp":"…","sessionId":"…","exitCode":0,"usage":{"premiumRequests":1,…,"codeChanges":{…,"filesModified":[]}}}`.

**Exit codes.** A tool request that would prompt is denied. The agent reads
`Permission denied because no interactive user response was available.`, carries on, and the
process still exits with 0: assert on the stream, as the last demo line does. An unknown
`--agent` name exits with 1 and prints nothing on stdout.

**GitHub Actions** (⚠️ not run in this repo). It needs the organisation policy **Allow use of
Copilot CLI billed to the organization**; in a personal repository, such as this one, usage is
billed to the owner's seat. From the [docs](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli-in-actions), step names left out:

```yaml
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
      - run: npm install -g @github/copilot
      - run: copilot -p "Use git show HEAD to summarize the changes in this commit" -s --allow-tool='shell(git show:*)'
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

> 🔷 **Copilot only:** the built-in `GITHUB_TOKEN` with `copilot-requests: write` meters the agent
> to the GitHub organisation; Claude Code in Actions needs an Anthropic credential, billed there.

## Microsoft Conductor

[Conductor](https://github.com/microsoft/conductor) is a separate command-line tool from
Microsoft (beta, MIT licence). A YAML file names the agents, their tools, their typed outputs
and the routes. No model decides the routing; a model is called only inside a step, through
your Copilot login. Install from the git URL only: `conductor-cli` on PyPI is another project.

```bash
uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"   # needs uv, Python 3.12+
conductor validate conductor/test-coverage-audit.yaml        # free
conductor run conductor/test-coverage-audit.yaml --dry-run   # free
conductor run conductor/test-coverage-audit.yaml             # four agent sessions on your plan
```

Run from the repository root. `validate` prints **Validation Successful**: 4 agents, 1 parallel
group. `--dry-run` prints the plan: `layer_inventories` with three parallel agents, `reporter`,
`$end`. The recorded run returned one gap table with 42 untested behaviours, among them the
cascade-merge and the game-over gap, and changed no file. The shape is fixed; the rows differ
between runs. Agents get the repo instructions only with `--workspace-instructions`.

`conductor/test-coverage-audit.yaml`, shortened (the comments are added here; full syntax:
[workflow-syntax.md](https://github.com/microsoft/conductor/blob/main/docs/workflow-syntax.md)):

```yaml
workflow:
  runtime:
    default_model: auto              # Copilot picks from the models your organisation allows
parallel:
  - name: layer_inventories          # the entry_point: three agents at the same time
    agents:
      - engine_inventory
      - api_inventory
      - web_inventory
    failure_mode: continue_on_error  # the reporter runs even if one inventory fails
    routes:
      - to: reporter
agents:
  - name: engine_inventory           # api_inventory and web_inventory: same shape, other paths
    tools: [view, grep, glob]        # read-only: it has no tool that can write
  - name: reporter
    tools: []                        # no tools; it works on its prompt only
    input:
      - layer_inventories.outputs    # the three agents' typed output: fields, not prose
```

- **Why `default_model: auto`.** Conductor's own default is a fixed model id. Without this line
  the run failed with `Model "gpt-4o" is not available.` Do not put a model id in the file.
- **The tool lists are the guard.** Conductor approves permission requests without asking. Each
  agent tool must also be in the top-level `tools:` list. With no lists at all, agents get the
  full default tool set and write files.

## Dynamic workflows

A dynamic workflow is "a program that defines how a task is carried out": automated steps and
agents, in sequence or in parallel. A CLI extension registers it
(`.github/extensions/<name>/extension.mjs`); run it by name in a session or with
`copilot workflow run <name>`. It needs experimental mode (`/settings experimental on`) and
usage-based billing; without that mode the command exits with 2. This repo ships none. Docs:
[Using dynamic workflows](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-dynamic-workflows).

> 🔷 **Copilot only:** a workflow run takes a time limit and an AI-credit ceiling
> (`workflows.defaultLimits.*`); Claude Code workflows have no documented time or cost limit per run.

## Where it works

| | CLI | IntelliJ plugin | Cloud agent |
|---|-----|-----------------|-------------|
| `/fleet` | ✅ | ⚠️ In the IDE's terminal | ❌ `/delegate` hands over one task ([guide 11](11-ide-remote.md)) |
| `copilot -p` | ✅ Also in GitHub Actions, under the organisation policy | ⚠️ In the IDE's terminal | ❌ |
| Conductor | ✅ Separate tool; reuses the Copilot login | ⚠️ In the IDE's terminal | ❌ |
| Dynamic workflows | ⚠️ Public preview, experimental mode | ⚠️ In the IDE's terminal | ❌ |

## Copilot vs Claude Code

- `/fleet` ↔ parallel subagents, `/batch`, workflows. A Claude Code workflow reports once, at the end.
- Dynamic workflows ↔ Claude Code workflows (`.claude/workflows/*.js`); extensions ↔ mods.
- Autopilot with a credit cap ↔ `/goal` in auto mode, with no cost cap in a session.
- `copilot -p` in Actions ↔ `anthropics/claude-code-action`, with its own credential.

## Troubleshooting

- **Fleet subagents fail with `400 The requested model is not supported`** → ask for general-purpose subagents, or pick models in `/subagents`.
- **Exit code 0 but nothing happened** → a tool call was denied. Add an exact `--allow-tool` rule.
- **Hooks or the plugin are missing in a `-p` run** → no `--trust-folder`, or not the repo root.
- **`references unknown tool '…'` from `conductor validate`** → add it to the top-level `tools:`.

Next: [11 · IntelliJ IDEA and remote agents](11-ide-remote.md)

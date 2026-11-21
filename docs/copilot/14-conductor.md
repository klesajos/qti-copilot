> 🌍 Read this in: **English** | [Česky](14-conductor.cs.md)

# Example 14: Microsoft Conductor

## What is Conductor?

**Conductor** is a command-line tool from Microsoft that runs multi-agent workflows
defined in a YAML file. The file names the agents, what each one may use, what each one
must return, and where the result goes next. It is not part of Copilot; it is a separate
MIT-licensed Python tool that *uses* Copilot as its model provider.

2N plans to use it for central agent flows. The property that fits that job:

- **Routing is plain YAML.** Which step runs next is decided by `routes` in the file,
  not by a model. There is **no LLM in the orchestration loop**; a model is called only
  *inside* a step.
- **The file is the contract.** It can be reviewed in a pull request, validated without
  running, and run the same way on a laptop and on a server.

Compare that with [`/fleet`](07-orchestration.md), where the model decides the split
again on every run.

**Status: v0.1.47, Beta, and it moves fast.** Five releases between 2026-10-29 and
2026-11-20, and its changelog carries several entries marked breaking. Treat everything
here as a snapshot of one version.

## What this example does

`conductor/test-coverage-audit.yaml` audits the test coverage of this repo:

```
layer_inventories (parallel group)
├── engine_inventory   ← Board.kt vs BoardTest.kt
├── api_inventory      ← api/src/main vs api/src/test
└── web_inventory      ← web/src and its *.test.ts(x) files
        │  all three finish
        ▼
reporter               ← merges the three inventories into one gap table
        ▼
$end → output: report, untested_total
```

The three inventory agents can only read. The reporter has no tools at all. The file was
validated and run for this guide; the result is in "Validate and run".

## Install

```bash
uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"
conductor --version        # Conductor v0.1.47
```

- It needs [`uv`](https://docs.astral.sh/uv/) and Python 3.12 or later.
- **Do not install `conductor-cli` from PyPI.** That name belongs to an unrelated project
  by another author. Install from the Microsoft git URL only, and pin the tag.
- Per its changelog, Conductor v0.1.47 is the first version that works with Copilot CLI
  1.0.113 and later. Older Conductor versions fail with "SDK protocol version mismatch".
- `conductor update` exists. Do not run it in the middle of a workshop.

Then check the environment:

```bash
conductor doctor
```

On the test machine it reported Conductor v0.1.47, Python 3.12, and for the `copilot`
provider: installed, tier `stable`, *"authenticates via GitHub/Copilot CLI login; env vars
are optional overrides"*. If Copilot CLI works for you, there is nothing else to configure.
The `openai` and `claude` providers need their own API keys and are not used here.

## The file, line by line

### `workflow`: identity and entry point

```yaml
workflow:
  name: test-coverage-audit
  description: Inventory behaviours per layer in parallel, then report which have no test
  version: "1.0.0"
  entry_point: layer_inventories
```

`entry_point` is where the run starts. It can name an agent, a parallel group or a
for-each group. Here it names the parallel group.

### `runtime`: provider and model

```yaml
  runtime:
    provider: copilot
    default_model: auto
```

`copilot` is the default provider and could be left out (per the README); it is written
so you can see it.

`default_model: auto` matters. Without it the run failed on the test account with
**`Model "gpt-4o" is not available.`** Conductor's built-in default is a fixed model id,
and that id is not on every organization's list. `auto` lets Copilot choose from the
models you are allowed to use. Do not put a model id in this file.

### `context` and `limits`

```yaml
  context:
    mode: explicit

  limits:
    max_iterations: 10
    timeout_seconds: 900
```

`mode: explicit` means an agent sees only what it lists under `input:`. The other modes
are `accumulate` (the default) and `last_only` (per the docs). Explicit mode keeps the
reporter's prompt down to the three inventories.

`limits` stop a run that loops or hangs. This workflow has two steps and no loop; the
limits start to matter when you add one.

### Top-level `tools`

```yaml
tools:
  - view
  - grep
  - glob
```

This is the workflow's tool registry. **Every tool an agent lists must also be listed
here.** Tested: with `glob` removed from this list, `conductor validate` fails with
*"Agent 'engine_inventory' references unknown tool 'glob'. Available tools: grep, view"*.
The names are Copilot's built-in tool names. Per the docs, an agent that omits `tools:`
inherits this whole list, and `tools: []` gives it none.

Why this is the safety mechanism: per its docs, Conductor approves ordinary permission
requests automatically. Nobody is asked. An agent is read-only because it has no tool
that can write, not because a prompt says so.

### The parallel group

```yaml
parallel:
  - name: layer_inventories
    description: One read-only inventory per layer, run at the same time
    agents:
      - engine_inventory
      - api_inventory
      - web_inventory
    failure_mode: continue_on_error
    routes:
      - to: reporter
```

The group runs its agents at the same time and waits for all of them. Per the docs, each
agent gets the same snapshot of the context; they cannot see each other's work.

`failure_mode: continue_on_error` lets the reporter run even if one inventory fails. The
default is `fail_fast`; the third value is `all_or_nothing`.

### Agents with typed outputs

```yaml
agents:
  - name: engine_inventory
    description: Behaviours of the board rules and the tests that cover them
    tools: [view, grep, glob]
    prompt: |
      You audit test coverage. Read only; never modify a file.

      Source: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      Tests:  engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
      …
    output:
      behaviours:
        type: array
        description: One entry per behaviour, as "behaviour — covering test name, or NONE"
      untested_count:
        type: number
        description: How many behaviours have no covering test
```

`api_inventory` and `web_inventory` are the same agent with different paths.

`output` declares the fields the agent must return, each with a type (`string`, `number`,
`boolean`, `array`, `object`). The next step reads fields, not prose. Per the docs, with
the Copilot provider this is done by instructing the model, not by a native JSON mode, so
keep the shapes simple.

The paths are relative to where you start `conductor`. Run it from the repository root.

### The reporter

```yaml
  - name: reporter
    description: Merges the three inventories into one gap report
    tools: []
    input:
      - layer_inventories.outputs
    prompt: |
      Three auditors inventoried the test coverage of a 2048 game, one layer each:

      {{ layer_inventories.outputs | json }}

      Write one Markdown table with the columns Layer, Behaviour, Covered by. …
    output:
      report:
        type: string
        description: The Markdown gap report
      untested_total:
        type: number
        description: Total number of untested behaviours across all layers
    routes:
      - to: $end
```

- `tools: []` gives it nothing. It reasons only over its prompt.
- `input:` is the explicit-mode declaration: this agent receives the group's outputs.
- `{{ … }}` is a Jinja2 template. `layer_inventories.outputs` holds one entry per agent
  of the group; `| json` renders it into the prompt.
- *"Use only what the auditors reported"* in the prompt keeps it from inventing rows.

### Routes and the final output

```yaml
output:
  report: "{{ reporter.output.report }}"
  untested_total: "{{ reporter.output.untested_total }}"
```

There are two routes in the file: the group goes to `reporter`, and `reporter` goes to
`$end`. The inventory agents have none; the group routes for them. A route can also carry
a `when:` condition on an agent's output, and the first matching route wins (per the
docs). That is how a loop or a branch is written. Either way the decision is an
expression in the file.

The top-level `output` maps the workflow's result from agent outputs.

## Validate and run

```bash
conductor validate conductor/test-coverage-audit.yaml       # free
conductor run conductor/test-coverage-audit.yaml --dry-run  # free: prints the plan
conductor run conductor/test-coverage-audit.yaml            # four agent sessions
```

`validate` checks YAML syntax, the schema, agent references and route targets. On this
file it prints **Validation Successful** with 4 agents, 1 parallel group, model `auto`.
`--dry-run` prints the plan: step 1 `layer_inventories` with three parallel agents, step
2 `reporter`, then `$end`.

The real run did what the file says: the three inventory agents ran in parallel on the
Copilot provider, then the reporter returned one gap table. It listed **42 untested
behaviours**, among them the cascade-merge gap and the game-over gap from this repo's
deliberate bugs. **No file changed** (`git status` was the same before and after).

The shape of the run is fixed. The content is not: every row is still written by a
model, so expect a different count next time.

For machine-readable output, `--silent` prints only the JSON result. It is a root option
and goes **before** `run`:

```bash
conductor --silent run conductor/test-coverage-audit.yaml
```

## How it compares

| | `/fleet` | Dynamic workflow | Conductor |
|---|---|---|---|
| **Who decides the split** | The model, every run | Extension code | The YAML file |
| **Defined in** | A prompt | `.github/extensions/<name>/extension.mjs` | `conductor/*.yaml` |
| **Extra requirements** | None | Experimental mode and a billing condition | A separate install (`uv`, Python 3.12+) |
| **Tools per agent** | Set by the session, not per step (not tested) | Not tested | Exactly the listed tools; no prompts |
| **Typed results between steps** | No | Not tested | Yes, `output:` |
| **Check without running** | No | Not tested | `conductor validate`, `--dry-run` |
| **Status** | Built in | Experimental | Beta |
| **Run in this repo** | No | No | Yes |

`conductor fleet` is unrelated to Copilot's `/fleet`: it monitors running Conductor
workflows.

## Extend it

Two extensions worth trying. The syntax is **taken from Conductor's own examples and
skill reference**. Both snippets pass `conductor validate` on v0.1.47 when added to a
copy of the file. **Neither was run here.**

**A human gate** after the report. Route `reporter` to the gate instead of `$end`:

```yaml
  - name: reporter
    # … unchanged …
    routes:
      - to: review_gate

  - name: review_gate
    type: human_gate
    prompt: |
      {{ reporter.output.untested_total }} untested behaviours found.

      {{ reporter.output.report }}
    options:
      - label: Accept the report
        value: accept
        route: $end
      - label: Run the inventories again
        value: redo
        route: layer_inventories
```

The second option creates a loop, which is what `max_iterations` is for. In automation
`conductor run --skip-gates` picks the first option. A gate cannot sit inside a parallel
group.

**A for-each group** that fans out over a list an agent produced. Give `reporter` one
more output field (`top_gaps`, `type: array`), route it to the group, and add:

```yaml
for_each:
  - name: gap_planners
    type: for_each
    description: One test proposal per top gap
    source: reporter.output.top_gaps
    as: gap
    max_concurrent: 3
    failure_mode: continue_on_error
    agent:
      name: gap_planner
      tools: [view]
      prompt: |
        Gap {{ _index + 1 }}: {{ gap }}

        Read the source file this gap is about. Propose one test for it: the test name
        and the assertion. Do not write any file.
      output:
        test_name:
          type: string
          description: Proposed test name
        assertion:
          type: string
          description: The assertion the test would make
    routes:
      - to: $end
```

Unlike the static group, the number of agents is decided at run time by the length of the
list. Read the results downstream as `{{ gap_planners.outputs | json }}`.

Conductor's `docs/workflow-syntax.md` shows a different human-gate form and a top-level
`input:` block; both disagree with its schema (per the research for this workshop).
When in doubt, trust `conductor validate`.

## Create your own workflow, step by step

1. **Copy** `conductor/test-coverage-audit.yaml` and cut it down to one agent that routes
   to `$end`. Set `entry_point` to that agent.
2. **Keep `default_model: auto`** and the top-level `tools:` list.
3. **Give the agent a typed `output`** and map it in the top-level `output:`.
4. **Validate, then dry-run.** Both are free.
5. **Run it once.** Then add the second agent, a route, and only then a parallel group.
6. **Keep agents read-only** until the flow is stable. A writing agent needs a write or
   shell tool in both lists, and nothing will ask you before it uses it.

## Optional parameters

| Flag | What it does |
|------|--------------|
| `--dry-run` | Show the execution plan without running |
| `-i, --input NAME=VALUE` | Workflow input; repeatable. Declared under `workflow.input` |
| `--skip-gates` | Auto-select the first option at human gates |
| `-l, --log-file <path\|auto>` | Write full debug output to a file |
| `--web` | Start a real-time web dashboard for the run |
| `--workspace-instructions` | Prepend `AGENTS.md`, `.github/copilot-instructions.md` and `applyTo: "**"` instruction files to every agent prompt. **Off by default** |
| `-p, --provider <name>` | Override the provider set in the file |
| `conductor --silent run …` | Only the JSON result on stdout |
| `conductor --quiet run …` | Agent lifecycle and routing only |

## 2N context

Conductor is **planned** at 2N for central agent flows. It is **not rolled out**. Until
2N publishes its own setup:

- Treat this guide as a preview. Do not build team processes on it yet.
- Pin the version and re-run `conductor validate` on every workflow after an upgrade.
- What carries over whatever the tool: cut a job into steps, give each step the fewest
  tools it needs, and make each step return typed fields.
- Conductor agents do **not** get this repo's Copilot instructions unless you pass
  `--workspace-instructions`. Whether the repo's hooks and skills load inside Conductor's
  agent sessions was not checked; do not rely on a hook as a guard there.

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Terminal**, next to Copilot CLI | ✅ Yes | A separate tool. It reuses the Copilot login, and its agents use your Copilot plan |
| **IntelliJ IDEA plugin** | ⚠️ Terminal only | No integration. Edit the YAML in the IDE, run `conductor` in its terminal |
| **Copilot cloud agent** | ❌ No | Conductor is not part of Copilot. It runs where you install it |

## Troubleshooting

- **`Model "gpt-4o" is not available.`** → set `runtime.default_model: auto`.
- **`references unknown tool '…'`** from `validate` → add the tool to the top-level
  `tools:` list.
- **"SDK protocol version mismatch"** → Conductor older than v0.1.47 with Copilot CLI
  1.0.113 or later (per its changelog). Install the pinned tag.
- **`No such option: --silent`** → root options go before the subcommand:
  `conductor --silent run …`.
- **An agent says it cannot find the files** → you started `conductor` outside the
  repository root. The prompts use paths relative to it.
- **The `copilot` provider is not ready in `conductor doctor`** → log in to Copilot CLI
  first (`copilot login`), then run `conductor doctor` again.
- **You installed `conductor-cli` with pip** → wrong package. Remove it and install from
  the git URL.
- **The report differs between runs** → expected. The routing is deterministic; the text
  inside each step is not. Tighten the `output` fields and the prompts.

---

Next: the [exercise catalog](exercises.md).

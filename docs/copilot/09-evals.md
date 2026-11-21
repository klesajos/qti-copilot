> 🌍 Read this in: **English** | [Česky](09-evals.cs.md)

# 09 · Evals: prove that a skill or plugin helps

> ⏱ 20 min (5 demo + 15 [exercise 8](exercises.md)) · Docs: [Vally](https://microsoft.github.io/vally/) · [Eval Spec Reference](https://microsoft.github.io/vally/reference/eval-spec/) · [GitHub Copilot Evals](https://github.github.io/evals/) · Verified on Copilot CLI 1.0.114, Vally CLI 0.21.0

## In short

**You need:** Node.js 24.15+ or 26 and `npm ci` in the repo root (it installs Vally). A real run spends Copilot credits.

**What it is for:** An eval proves that a skill or plugin really helps: the same task with and without it, scored automatically. Without one, "the skill helps" is an opinion.

**Three uses that pay off most:**

1. Prove a skill earns its place before you share it at a guild.
2. Catch a regression when you edit a skill or switch to another model.
3. Compare two versions of an instruction on numbers, not on one lucky run.

## What is an eval?

A skill, agent or plugin is a hypothesis: "with this, Copilot does the task better". It costs
tokens and time in every session that loads it. An **eval** tests it: a prompt (**stimulus**) plus
**graders** that score what the agent did, run **with** and **without** the customization. The
difference is the proof. Every trial is a real, billed Copilot session. Three tools do the job:

| Tool | What it is | In this repo |
|---|---|---|
| **Vally CLI** (`@microsoft/vally-cli`, MIT) | The engine: runs a stimulus through a Copilot SDK session and grades the result | Used. Pinned to `0.21.0` in `package.json` |
| **GitHub Copilot Evals** (`eval@github-copilot-evals`) | A plugin with `/eval` commands and skills in front of Vally. [Public preview](https://github.blog/changelog/2026-11-17-github-copilot-evals-is-now-in-public-preview/) since 2026-11-17 | Not vendored (source-available licence); install from [github/evals](https://github.com/github/evals). `/eval` needs experimental mode. It ships its own `copilot-evals` MCP server: expect it blocked at 2N until it is on the approved list |
| **Plain `copilot -p` script** (`evals/plugin-ab.sh`) | 73 lines of bash and `jq` | Used for what Vally does not cover: a whole plugin as one unit |

## What this example does

```
package.json, .vally.yaml                 ← Vally version; scripts eval:lint, eval, eval:ab; paths
evals/
├── board-tests/eval.yaml                 ← skill eval: a positive case and a negative control
├── game-explorer/eval.yaml               ← agent eval: was the agent delegated to?
├── experiments/board-tests-ab.experiment.yaml   ← that eval twice: without and with the skill
├── plugin-ab.sh                          ← whole-plugin A/B on plain copilot -p
└── results/                              ← gitignored: holds your prompts and tool output
```

## The file, line by line

Per trial, Vally copies what the spec lists into an empty workspace, runs one Copilot session on
the stimulus, then grades the event stream and the files. `evals/board-tests/eval.yaml`, abridged
(the comments were added for this guide and name what was cut):

```yaml
defaults:
  executor: copilot-sdk     # each trial is a real Copilot session, driven through the SDK
  runs: 2                   # trials per stimulus. No model key: Copilot picks the model
agent_environment:          # everything a trial workspace contains; paths relative to this file
  skills:
    - ../../.github/skills/board-tests        # the skill under test
  files:                                      # the fixture: one source file, and no .github/
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
stimuli:
  - name: game-over-edge-case                 # positive case: the prompt never names the skill
    prompt: >-
      Write a unit test for the 2048 board: … Follow this project's test conventions.
      This workspace has no build tool, so do not try to compile or run anything.
    graders:                                  # cut: completed, file-exists on the path below
      - type: file-matches                    # three of these, one per convention: the backtick
        config:                               # test name (shown), 'boardOf\(', 'assertFalse\('
          path: engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
          pattern: 'fun `[^`]+`\(\)'
  - name: unrelated-question                  # negative control (prompt cut): asks a question
    graders:                                  # cut: completed, output-matches, diff-empty
      - type: skill-invocation                # the skill must stay quiet
        config:
          disallowed: [board-tests]
scoring:
  threshold: 1                                # a trial passes only if every grader passes
```

Why no `.github/`: the executor also loads skills it finds in the workspace, so the baseline arm
would get the skill too. No grader needs a judge model. The experiment file reruns the spec once
per variant and changes one field; 2 variants × 2 stimuli × 2 runs = **8 sessions**:

```yaml
matrix:
  skills:
    path: /environment/skills            # the field of the spec this axis overrides
    values:
      - without: []                      # the skills list is replaced by an empty one
      - with: ["../../.github/skills/board-tests"]
baseline:
  skills: without                        # the arm every other arm is compared to
```

## Create your own, step by step

1. Write down one claim: "With this skill, Copilot names tests as sentences." No claim, no eval.
2. `mkdir evals/my-skill && cp evals/board-tests/eval.yaml evals/my-skill/`. Change `name`,
   `description` and `agent_environment`: your skill, the smallest fixture, never `.github/`.
3. Write one positive stimulus the way a user would ask, without naming the skill, and one
   negative control. Add one deterministic grader per convention the skill states.
4. `npm run eval:lint`, then one trial: `npm run eval -- -e evals/my-skill/eval.yaml --runs 1`.
   Read a failing trial's `workspace.patch` before you trust the grader: a grader can be wrong.
5. Copy the experiment file; point `evals` and the `with` value at yours. Dry-run your file with
   the command in the demo below. For the paid run put `EVALUATE_USE_HOST_COPILOT_HOME=1` in
   front as well and replace `--dry-run` with `--output-dir evals/results`.

## Try the demo

```console
$ npm run eval:lint
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid
$ VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
Baseline:   skills=without
Plans:      2
$ npm run eval:ab
```

Run `npm ci` once first (Node 24.15+ or 26+). Lint and dry run call no model; `eval:ab` is 8 real
sessions. Output abridged. The run ends with a table: stimuli passed, tokens and time per arm.
In `evals/results/<timestamp>/`, `report.md` has a row per variant and stimulus (`Skills` shows
which skill fired); each trial folder holds `events.jsonl` and `workspace.patch` (its changes).

## Read the result

| Recorded here: 2 runs of `eval:ab`, 4 trials per cell, model `auto` | Without the skill | With the skill |
|---|---|---|
| `game-over-edge-case` (positive) | **0 of 4** trials passed | **3 of 4** trials passed |
| `unrelated-question` (negative control) | 4 of 4 | 4 of 4 |
| Tokens / wall time | baseline | +26–32% / +51–67% |

- **The baseline missed conventions, not logic:** no `boardOf(` helper in 4 of 4 trials, a
  camelCase test name in 2 of 4. That is what the skill adds, at the price in the last row.
- The with-skill miss wrote its test outside its workspace. The negative control held in 8 of 8.
- **Limits:** four trials on one model are a signal, not a measurement. The fixture leaves out
  the existing `BoardTest.kt`, where `boardOf` is defined, so the eval overstates the gain here.

**Plugin A/B** (`RUNS=1 evals/plugin-ab.sh`: one `copilot -p` session per arm, `--plugin-dir` in
the `with` arm only): 3 of 3 outcome checks passed in both arms. Without the plugin the built-in
`explore` agent did the trace; with it, `2048-dev:game-explorer`. **The plugin changed who did
the work, not the outcome.** If its value lies elsewhere, write a check for that and measure it.

## Two traps, and the cost

- **Personal skills leak into trials.** The npm scripts set `EVALUATE_USE_HOST_COPILOT_HOME=1` to
  reuse your CLI login. That exposes your Copilot home: a personal `tdd` skill ran in the baseline
  arm. Check `copilot skill list --json`: rows with a `source` other than `project` or `builtin`.
- **Trials are not sandboxed.** One wrote outside its workspace. No destructive stimuli.
- **A run costs** one session per variant × stimulus × run, in AI credits or premium requests
  (`copilot help billing`). Vally has no usage cap; only the script has (`--max-ai-credits 30`).
- **A skill or plugin costs context** in every session: `/context` (per skill in experimental mode).

## Optional parameters

| Flag | On | What it does |
|---|---|---|
| `--runs <n>` | `vally eval` | Trials per stimulus; overrides `defaults.runs` |
| `--model <model-id>` | `vally eval` | Model for the agent under test |
| `--require-pass` | both | Exit non-zero on a failed verdict. Without it, exit code 0 does not mean "passed" |
| `--dry-run`, `--variant <name>` | `vally experiment run` | Print the plan without running; run one arm only |

Full reference: [CLI: eval](https://microsoft.github.io/vally/reference/cli/eval/) · [CLI: experiment](https://microsoft.github.io/vally/reference/cli/experiment/)

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|---|---|---|
| ✅ Vally and the script run beside the CLI and reuse its login | ⚠️ No eval UI; run the npm scripts in the IDE terminal | ❌ Nothing here evaluates the cloud agent |

## Copilot vs Claude Code

Claude Code: `claude plugin eval` ([Test plugins with evals](https://code.claude.com/docs/en/plugin-evals)).
Same idea: cases, graders, a run with and without the plugin. There it is built into the CLI and
generally available; here the engine is a separate package and the front end a preview plugin.

## Troubleshooting

- **Authentication error in a trial** → `vally` ran without `EVALUATE_USE_HOST_COPILOT_HOME=1`, or the CLI is logged out.
- **`file-exists` fails but the agent says it wrote the file** → it wrote outside the workspace; read `events.jsonl`.
- **The with-skill arm is no better** → the skill did not fire (`Skills` column in `report.md`) or the baseline is already good.

Next: [10 · Beyond one session](10-orchestration.md)

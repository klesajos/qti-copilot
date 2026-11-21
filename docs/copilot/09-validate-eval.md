> 🌍 Read this in: **English** | [Česky](09-validate-eval.cs.md)

# Example 9: Validating and evaluating your customizations

## What are validation and evals?

Examples 1–8 *build* customizations. This one *checks* them.

A skill or an agent is not free. A session that uses one spends more tokens and more time
(measured below: about a quarter to a third more tokens with the `board-tests` skill).
The question is whether it **changes the outcome**. "It felt better" is not an answer you
can take to a guild.

- **Validation** is static and free: do the files parse, do they match the schema?
- An **eval** is the unit test of a customization: a prompt (**stimulus**) plus
  **graders** that score what the agent did. Run it **with** and **without** the
  customization and compare. Every run is a real Copilot session and is billed like one:
  in AI credits or in premium requests, depending on your plan (`copilot help billing`).

## The landscape

Copilot CLI 1.0.114 has **no `copilot eval` command and no `copilot plugin validate`
command**. Evaluation lives in separate tools:

| Tool | What it is | Use it for | Status |
|------|------------|-----------|--------|
| **Vally CLI** (`@microsoft/vally-cli`, MIT) | The eval engine. Runs a stimulus through a Copilot SDK session and grades the result | Skills, agents, with/without experiments. **Used in this repo** | npm package, pinned to 0.21.0 here |
| **GitHub Copilot Evals** (`eval@github-copilot-evals`) | A plugin: `/eval` commands and skills in front of the same engine | Drafting evals in conversation. Optional demo below | Public preview since 2026-11-17 |
| **Plain `copilot -p` script** (`evals/plugin-ab.sh`) | About 70 lines of bash and `jq` | What Vally's docs do not cover: a plugin as a unit, hooks | Yours to change |

If you know `claude plugin eval` from Claude Code, map it like this:

| Claude Code | Here |
|-------------|------|
| `claude plugin validate` | No command. `jq`, an `ajv` schema check, `npm run eval:lint` |
| `claude plugin eval` (Δ for one skill) | `vally experiment run` with a matrix on `/environment/skills` |
| `claude plugin eval` (Δ for the plugin) | `evals/plugin-ab.sh` |
| `case.yaml` + `prompt.md` + `graders/*.md` | One `eval.yaml`: stimuli with their graders |
| `setup.sh` + `fixture/` | `agent_environment.files` |
| `arm: with-only` grader | A check kept out of the score (`used_plugin_agent` in the script) |
| `--max-cost-usd` | Nothing in Vally. `--max-ai-credits` only in the `copilot -p` script |
| Hermetic sandbox | **Not sandboxed** by default (see "Things that bite") |

## What this example does

```
package.json                         ← pins the engine; npm run eval:lint | eval | eval:ab
.vally.yaml                          ← where specs and results live
evals/
├── board-tests/eval.yaml            ← skill eval: positive case + negative control
├── game-explorer/eval.yaml          ← agent eval: was it delegated to?
├── experiments/
│   └── board-tests-ab.experiment.yaml   ← the same skill eval, with and without the skill
├── plugin-ab.sh                     ← whole-plugin A/B on plain copilot -p
└── results/                         ← gitignored
```

All four were run for real. The numbers are in "What the runs showed".

## Validate for free first

None of this calls a model. Run it before every eval and in every review.

```bash
# 1. The JSON parses (prints nothing when all is well)
jq empty marketplace.json plugins/2048-dev/plugin.json .github/copilot/settings.json .github/hooks/hooks.json

# 2. plugin.json matches the Agent Plugins 1.0 schema
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"

# 3. Eval specs and SKILL.md files are well-formed
npm ci                                   # once, at the repo root
npm run eval:lint
npx --no vally lint .github/skills

# 4. The experiment resolves to the plan you expect
npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
```

Output on this repo:

```text
plugins/2048-dev/plugin.json valid
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid
✅ board-tests (2/2 checks passed)
Experiment: board-tests-ab
Baseline:   skills=without
Plans:      2
```

Step 2 is the same check GitHub's plugin starter template runs. Keep the schema URL at
`1.0.0`; the `1.1.0` URL returned 404 when this guide was written.

What these checks do **not** catch: a customization that loads but does nothing useful.
To see what a session really loaded, use `/env` inside it, or `copilot skill list --json`
and `copilot instruction list --json` outside it.

## The files, line by line

### `evals/board-tests/eval.yaml`

```yaml
name: board-tests
description: Does the board-tests skill make Copilot write board tests the way this project does?
type: capability
defaults:
  executor: copilot-sdk
  runs: 2
  timeout: 5m
```

`description` states the claim under test. `copilot-sdk` is Vally's built-in executor: each trial is a real Copilot session driven
through the SDK. `runs` is trials per stimulus. There is **no `model:`** on purpose; the
dry run shows `Model: (unset)` and Copilot picks one. Pin it per run with
`--model <model-id>`.

```yaml
agent_environment:
  skills:
    - ../../.github/skills/board-tests
  files:
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
```

Every trial starts in a fresh workspace that holds only what is listed here. Paths are
relative to the eval file. `skills` is the skill under test; `files` is the fixture, one
source file.

**No `.github/` is staged, and that is the point.** Per the Vally docs, the `copilot-sdk`
executor also loads skill directories it finds *in the workspace*, so the declared list
is "a floor rather than the exact set". Stage `.github/` and the baseline arm has the
skill too.

```yaml
stimuli:
  - name: game-over-edge-case
    prompt: >-
      Write a unit test for the 2048 board: a full board that still contains two equal
      neighbours must not be reported as game over. Follow this project's test conventions.
      This workspace has no build tool, so do not try to compile or run anything.
    tags:
      control: positive
      suite: smoke
```

The **positive** stimulus. It never names the skill; the skill has to trigger on its own.
The tags are free-form labels; `--tag suite=smoke` selects by them.
It targets deliberate bug 2, so a correct test fails against the current code. The last
sentence stops the agent from burning its timeout on a missing Gradle wrapper.

| Grader | Why it exists |
|--------|---------------|
| `completed` | The session ended normally. Without it the other graders may be judging a crash |
| `file-exists` `…/BoardTest.kt` | The test landed where the project keeps board tests |
| `file-matches` ``fun `[^`]+`\(\)`` | The test name is a sentence in backticks |
| `file-matches` `boardOf\(` | The board is built with the project's deterministic helper |
| `file-matches` `assertFalse\(` | The correct assertion is kept, although the current code fails it |

```yaml
  - name: unrelated-question
    prompt: >-
      In two sentences, what does slideLineLeft return and what does it do to its argument?
      Answer in chat only; do not create or change any file.
    tags:
      control: negative
      suite: smoke
```

The **negative control**: same code, no test wanted.

| Grader | Why it exists |
|--------|---------------|
| `completed` | As above |
| `skill-invocation` `disallowed: [board-tests]` | A skill that fires on everything costs context for nothing |
| `output-matches` `(?i)score` | The question was answered (the function returns the score gained) |
| `diff-empty` | Nothing was written |

`scoring: threshold: 1` means a trial passes only when **all** its graders pass. Four of
five is a fail (score 0.8). Every grader here is deterministic; none needs a judge model.

### `evals/experiments/board-tests-ab.experiment.yaml`

The whole file, with comments added for this guide:

```yaml
name: board-tests-ab
evals:
  - ../board-tests/eval.yaml          # which specs to run
matrix:
  skills:                             # one axis, named "skills"
    path: /environment/skills         # the field of the eval it overrides
    values:
      - without: []                   # the array is replaced: no skill at all
      - with: ["../../.github/skills/board-tests"]
baseline:
  skills: without                     # the arm every other arm is compared to
```

One axis with two values gives two variants, `skills=without` and `skills=with`.
Everything else is identical. Cost: 2 variants × 2 stimuli × 2 runs = **8 sessions**.

### The npm scripts

| Script | Runs | Cost |
|--------|------|------|
| `npm run eval:lint` | `vally lint -e evals` | Free |
| `npm run eval -- -e <spec>` | `vally eval --output-dir evals/results` on one spec | One session per stimulus per run |
| `npm run eval:ab` | `vally experiment run evals/experiments/board-tests-ab.experiment.yaml` | 8 sessions |

Both paid scripts set `EVALUATE_USE_HOST_COPILOT_HOME=1` (reuse your Copilot CLI login)
and `VALLY_TELEMETRY_OPTOUT=1`. `package.json` pins the engine to exactly `0.21.0`.

Results land in `evals/results/<timestamp>/`:

```
report.md                              ← experiment summary (eval-results.md for a single eval)
skills=with/results.jsonl              ← one line per trial, with each grader's evidence
skills=with/board-tests/<stimulus>/default-model/<trial>/
├── events.jsonl                       ← the full session event stream
└── workspace.patch                    ← what the agent changed
```

### `evals/game-explorer/eval.yaml`

The agent ships inside the `2048-dev` plugin, but Vally's docs cover project agents, not
installed plugins. So the eval **stages the agent file as a project agent**:

```yaml
agent_environment:
  files:
    - src: ../../plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md
      dest: .github/agents/game-explorer.agent.md
    # … plus the six source files of the keypress chain
```

```yaml
      - type: tool-calls
        config:
          required:
            - name: "^task$"
              args:
                agent_type: "game-explorer"
```

Copilot delegates through a tool named `task`; the chosen agent is its `agent_type`
argument. The grader asserts exactly that call. Staged as a project agent, the id is
`game-explorer`, not `2048-dev:game-explorer`.

The prompt says *"Delegate to the game-explorer agent"*. This is **forced delegation**: it
tests whether the agent does its job when called, not whether the model would route to it.
Two `output-matches` graders (`keys\.ts`, `GameService`) check the trace, and `diff-empty`
checks the agent stayed read-only. Pick patterns only a *correct* answer contains:
`Board.move` is in the prompt, so an answer saying "I cannot find Board.move" would match it.

### `evals/plugin-ab.sh`

The question Vally does not answer: **does installing the plugin change the outcome?**

| Lines | What happens |
|-------|--------------|
| `prompt=` | A real task (trace Left arrow to `Board.move`). It asks to delegate "if a specialised code-exploration agent is available", without naming the plugin |
| `grade()` | Reads the `assistant.message` events and the final `result` line of the JSONL stream. Three checks: names `keys.ts`, names `GameService`, no file modified |
| `used_plugin_agent()` | Looks for a `task` tool call whose `agent_type` contains `game-explorer`. **Not scored**: the baseline cannot pass it by construction |
| `git archive HEAD engine api web` | Each run gets a fresh copy of the application source only. No `.github/`, so the repo's skills, agents and hooks cannot leak into either arm. It archives `HEAD`: uncommitted changes are not in the copy |
| `args=(…)` | `--output-format json`, `--no-ask-user`, `--no-auto-update`, `--disable-builtin-mcps`, `--max-ai-credits 30`. No `--allow-tool`: in `-p` mode a call that needs approval is denied, and the task only reads |
| `--plugin-dir "$plugin"` | Added in the `with` arm only. This is the one difference between the arms |
| `COPILOT_PLUGIN_DIR_ONLY=true` | Set in both arms. Per `copilot help environment` it turns off automatic plugin discovery, so only `--plugin-dir` plugins load. Your personal skills and agents in `~/.copilot` still load, in both arms alike |
| `\|\| true` | A crashed run is still graded, as a fail |

## What the runs showed

**Skill A/B** (`npm run eval:ab`, two runs, CLI 1.0.114, Vally 0.21.0):

| | Without the skill | With the skill |
|---|---|---|
| `game-over-edge-case` (positive) | **0 of 4** trials passed | **3 of 4** trials passed under the corrected grader (2 of 4 as graded at the time; see below) |
| `unrelated-question` (negative) | 4 of 4 | 4 of 4 |
| Tokens | baseline | about 26–32% more |
| Wall time | baseline | about 51–67% more |

Read it with these caveats:

- **Four trials per cell, one model** (whatever `auto` resolved to on the test account).
  This is a signal, not a measurement. 2N's model list differs; rerun it there.
- **What the baseline got wrong:** no `boardOf(` helper in 4 of 4 trials, a camelCase test
  name instead of a backtick sentence in 2 of 4. The assertion itself was fine.
- **The baseline is handicapped by the fixture.** Only `Board.kt` is staged, not the
  existing `BoardTest.kt` where `boardOf` is defined. In the real repo the agent can read
  that file and copy its conventions without any skill. The eval shows the skill
  *transfers* the conventions; it overstates what the skill adds in this repo.
- **The one with-skill miss** had nothing to do with conventions: the agent wrote the
  test to a path outside the trial workspace, so `file-exists` and every file grader failed.
- **One grader was wrong on the first run.** It was `assertFalse\([^)]*isGameOver\(\)`
  and failed a correct test that stored the result in a variable first
  (`val gameOver = board.isGameOver()` … `assertFalse(gameOver)`), exactly the
  Arrange-Act-Assert the skill asks for. The pattern was relaxed to `assertFalse\(`.
  The 3 of 4 counts that trial under the current pattern; the saved report of that run
  shows it as a fail, so the two saved reports add up to 2 of 4.
- **The skill is not free:** a quarter to a third more tokens, and half to two thirds
  more time.
- The negative control held in 8 of 8 trials: the skill did not fire on an unrelated question.

**Agent eval** (`npm run eval -- -e evals/game-explorer/eval.yaml`): 1 of 1 passed.

**Plugin A/B** (`RUNS=1 evals/plugin-ab.sh`, one run per arm):

| Arm | Outcome checks passed | Who did the trace |
|-----|-----------------------|-------------------|
| `without` | 3 of 3 | The built-in `explore` agent |
| `with` | 3 of 3 | `2048-dev:game-explorer` |

**The outcome was identical. The plugin changed who did the work, not the result.** That
is a useful finding, not a failed eval. It says the built-in agent already handles this
task, so "better traces" is not a claim this plugin can make. If its value is something
else (a strict read-only tool list, a fixed output format), write a check for *that* and
measure it. One run per arm is thin; the conclusion is "no difference seen", not "no
difference exists".

## Grader mapping

| Claude Code grader | Vally grader | Notes |
|--------------------|--------------|-------|
| `llm` | `prompt` | LLM judge. Needs a judge model |
| `tool_used` | `tool-calls`, `skill-invocation` | `required` / `disallowed`; `tool-calls` can match arguments |
| `regex` | `output-matches` | On the agent's final answer |
| `file_exists` | `file-exists` | |
| — | `file-matches` | Regex on a file in the workspace |
| — | `diff-empty` | The workspace was not changed |
| — | `completed` | The session ended normally |

An LLM judge is optional. The snippet below follows the Vally docs and passes
`vally lint`; it was **not run** here:

```yaml
  - name: game-over-edge-case
    prompt: …
    rubric:
      - The test builds a full board that contains at least one pair of equal neighbours
      - The test asserts that this board is not game over, and does not weaken the assertion
    graders:
      - type: prompt
        config:
          scoring: binary
          evidence: [trajectory, diff]
```

The judge is a model call, so its model must be on your organization's allow-list. Vally's
default judge model was **not available** on the test account, and `--compare` failed for
that reason. Pass `--judge-model <model-id>`, or leave judged graders and `--compare` out.
Mind the scope of the flag: on `vally eval` it sets the judge for `prompt` graders; on
`vally experiment run` it sets only the `--compare` judge.

## Things that bite

- **Your personal skills leak into the trials.** `EVALUATE_USE_HOST_COPILOT_HOME=1`
  exposes your whole Copilot home. In the real runs a personal `tdd` skill was invoked in
  the *baseline* arm. Check with `copilot skill list --json` (every row whose `source` is
  not `project`) and disable what could interfere with `copilot skill disable <name>`. The docs recommend token authentication for reproducible
  runs: a fine-grained PAT with the "Copilot Requests" permission in
  `COPILOT_GITHUB_TOKEN` (not tested here; the org must allow such tokens).
- **Trials are not sandboxed.** One trial wrote a file outside its workspace. Do not put
  destructive tasks in a stimulus. `vally eval --help` lists `--backend docker`; not tested.
- **Results contain your prompts and the tools' output**, including file contents.
  `evals/results/` is gitignored. Read a report before you paste it anywhere.
- **Telemetry is on by default** in Vally. The npm scripts set `VALLY_TELEMETRY_OPTOUT=1`;
  set it yourself when you call `npx vally` directly.
- **Vally has no usage cap.** Sessions = variants × stimuli × runs, and `vally eval`
  adds up to two retries per stimulus by default (`--max-retries`). Keep `runs` small
  while you iterate. Only the `copilot -p` script can cap a session
  (`--max-ai-credits 30`: the minimum, a soft cap, shared with subagents). To see what a
  script run cost, read the last line of its `events.jsonl`: on the test account the
  `result` record carried `usage.premiumRequests`. Whether you see AI credits or premium
  requests depends on your plan.
- **Exit code 0 does not mean "passed".** Per `--help`, failing verdicts exit non-zero
  only with `--require-pass`.

## Create your own eval, step by step

1. **Write down one claim.** "With this skill, Copilot names tests as sentences."
   No claim, no eval.
2. **Copy a spec:** `mkdir evals/my-skill && cp evals/board-tests/eval.yaml evals/my-skill/`.
3. **Stage the smallest fixture** under `agent_environment.files`. Application source
   only; never `.github/`.
4. **Write one positive stimulus** the way a user would ask. Do not name the skill.
5. **Write one negative control:** a nearby request where the skill must stay quiet.
6. **Add deterministic graders first.** One per convention you claim. Choose patterns
   only a correct result contains.
7. **Lint:** `npm run eval:lint`.
8. **Run one trial:** `npm run eval -- -e evals/my-skill/eval.yaml --runs 1`.
9. **Open a failing trial's `workspace.patch` and `events.jsonl`** before you believe the
   grader. The agent may be wrong, or the grader may be (see above).
10. **Copy the experiment file**, point it at your eval and skill, check it with
    `--dry-run`, then run it. Report the numbers together with the trial count.

## Try the demo

Needs: a logged-in Copilot CLI, Node 24.15+, `npm ci` at the repo root, `jq` for the script.

1. Run the free block from "Validate for free first".
2. `npm run eval -- -e evals/game-explorer/eval.yaml` (one session). Open
   `eval-results.md` in the newest `evals/results/<timestamp>/`.
3. `npm run eval:ab` (eight sessions). Open `report.md` and compare your numbers with the
   table above. Then run `copilot skill list --json` and ask which of your personal skills
   took part.
4. `RUNS=1 evals/plugin-ab.sh` (two sessions). Which agent did the trace in each arm?

## Optional parameters

| Flag | What it does |
|------|--------------|
| `-e, --eval-spec <path>` | Eval file to run (repeatable) |
| `--runs <n>` | Trials per stimulus; overrides `defaults.runs` |
| `--model <model-id>` | Model for the agent under test |
| `--tag <key=values>` | Run only matching stimuli, e.g. `--tag control=positive` |
| `--require-pass` | Exit non-zero when a verdict fails |
| `--max-retries <n>` | Retries per stimulus (default 2) |
| `--workers <n>` | Concurrent sessions (default 5) |
| `--judge-model <model-id>` | `vally eval`: model for `prompt` graders. `experiment run`: model for the `--compare` judge only |
| `--junit` | Also write a JUnit XML report |
| `experiment run --dry-run` | Print the resolved plan without running |
| `experiment run --variant <name>` | Run one arm only |
| `experiment run --compare` | Let an LLM judge compare each arm with the baseline. Spends tokens |

## GitHub Copilot Evals (optional demo)

The first-party front end. Everything in this section is **per its documentation; nothing
was installed or run for this repo**.

```bash
copilot plugin marketplace add github/evals
copilot plugin install eval@github-copilot-evals
```

- **Experimental mode.** `/eval setup|create|review|improve|run|compare` need it
  (`/settings experimental on`). Without it the plugin's six skills still work in plain
  language.
- **Its own MCP server.** The plugin ships a `copilot-evals` MCP server. Under an MCP
  allow-list every non-default server is blocked unless approved, and nothing documents
  an exemption for this one. At 2N expect it to be blocked until it is on the list. With
  the server blocked and experimental mode off, the plugin can draft eval files but not
  run them. The fallback is always `npm run eval` in the terminal.
- **Prerequisites:** Node.js 24, `@microsoft/vally-cli` 0.21.0, Copilot CLI 1.0.85 or
  later, Git 2.28 or later.
- **Licence.** GitHub Limited Use Source License: source-available, not open source.
  Internal use is allowed; being paid to operate it for a third party is not. That is why
  it is **never vendored in this repo** and you install it yourself. Vally CLI is MIT.
- **Side effects.** `/eval setup` writes `.vally.yaml`; check `git diff .vally.yaml`
  afterwards. Results go to `.copilot/evals/results` (gitignored here). Its telemetry is
  on by default; `COPILOT_EVALS_TELEMETRY=off` turns it off.
- **What it cannot do yet:** a verified with/without comparison (`/eval compare` is one
  skill, one case, one attempt per arm, with no comparison report); repeated trials or an
  LLM judge in its default profile; evaluating hooks, instruction files or an installed
  plugin as a unit. For those, use the files in this repo.

It releases several times a day and its pages disagree with each other. Treat
[github.com/github/evals](https://github.com/github/evals) as the source of truth and
re-read it on the day.

## Evals in CI (not set up in this repo)

Per the docs, `github/evals-action@v0` lints the specs, runs a named Vally suite and posts
one PR comment. It needs a suite in `.vally.yaml` (this repo defines none), the job
permission `copilot-requests: write`, an Actions policy that allows the action, and the
organization policy "Allow use of Copilot CLI billed to the organization". Usage is billed
to the organization, and it runs only on GitHub-hosted Linux x64 runners. That is an admin
decision at 2N, so this repo ships no workflow for it.

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** (terminal) | ✅ Yes | Vally and the script run next to the CLI and reuse its login |
| **IntelliJ IDEA plugin** | ⚠️ Terminal only | No eval UI. Run the npm scripts in the IDE terminal. Copilot Evals does not list JetBrains as a host (per its docs) |
| **Copilot cloud agent** | ❌ No | Nothing here evaluates the cloud agent. The CI path is `evals-action`, not set up |

## Troubleshooting

- **`vally: command not found`** → run `npm ci` at the repo root and use the npm scripts
  or `npx --no vally`.
- **Authentication error in a trial** → you called `vally` directly without
  `EVALUATE_USE_HOST_COPILOT_HOME=1`, or the Copilot CLI is not logged in.
- **`--compare` or a `prompt` grader fails on the model** → the default judge model is
  not on your allow-list. Pass `--judge-model <model-id>`.
- **The baseline arm uses a skill you never staged** → a personal skill leaked in. See
  "Things that bite".
- **`file-exists` fails but the agent says it wrote the file** → it wrote outside the
  workspace. Read that trial's `workspace.patch` and `events.jsonl`.
- **The with-skill arm is no better** → the skill did not fire (check the Skills column
  in `report.md`), or the baseline is already good. Both mean the skill is not earning
  its cost on this task.
- **Scores jump between runs** → model variance. Raise `runs` before you conclude anything.
- **`plugin-ab.sh` ignores your latest change** → it archives `HEAD`. Commit first.

---

Next: [Example 10: The level-5 workflow](10-level-5-workflow.md).

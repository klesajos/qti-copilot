> 🌍 Read this in: **English** | [Česky](10-level-5-workflow.cs.md)

# Example 10: Working at level 5 and above

2N does not want developers to type code. It expects work at **level 5 or higher** on the scale
from the VisiData post [Using AI to Contribute to Open Source](https://www.visidata.org/blog/2026/ai/).
Examples 1–9 built the tools. This one is the working method: how to ship a change in this repo
when every line is generated, and what you must hold in your hands before you merge it.

Where each statement comes from:

- Unmarked: the CLI's own help on 1.0.114 (`copilot --help`, `copilot help <topic>`).
- **[T]** tested: run in this repository on 1.0.114.
- **[D]** per the docs; not tested in this repo. Most slash commands here are interactive, so
  their finer behaviour is **[D]**.

## The scale

Level names as in the post; the short descriptions are paraphrased.

| Level | Name | In short |
|-------|------|----------|
| 0 | Human did not use AI at all | No AI anywhere |
| 1 | Human asked chatbot for ideas | Human typed every character |
| 2 | Human coded with minor assists | Small pasted snippets, a regex, boilerplate |
| 3 | Human coded, bots assisted non-trivially | Human wrote it; some non-trivial pasted code |
| 4 | Human coded, bots helped significantly | Human wrote most; bots edited files such as docs and tests |
| **5** | **Bots coded, human understands completely** | Bots wrote most of it; the human reviewed every line |
| **6** | **Bots coded, human understands mostly** | The human oversaw the work and deferred some code judgement to the bots |
| **7** | **Human specced, bots coded** | The human wrote the spec and watched tests and process; most code judgement is deferred |
| 8 | Bots planned, human approved | The bots worked mostly on their own; the human validated the result |
| 9 | Human fired-and-forgot | A human started it and never looked again |
| 10 | Rogue bots, zero human attention | Nobody asked for it |

At every level up to 8 a human still vouches for the change. Levels 9 and 10 are not a way of
working; they are what the guard rails in this guide exist to prevent.

## What changes between 5, 6 and 7

The code is generated at all three. What moves is **what you verify yourself and what you accept
on evidence**.

| | Level 5 | Level 6 | Level 7 |
|---|---------|---------|---------|
| You write | Prompts | Prompts | A spec: behaviour, constraints, how it is proven |
| You read | Every line of the diff | The risky hunks and the tests; the rest by sampling | The plan, the tests and the review findings; little or no code |
| You accept on evidence | Nothing | The parts you did not read | Almost everything |
| Evidence before merge | Diff read in full, tests green | Plus: a test that failed before the fix, a review run, a diff of sane size | Plus: tests you specified up front, an independent review, a session transcript |
| Typical failure | You run out of time and skim | The unread part hides the bug | The spec was vague and the tests prove the wrong thing |

The step from 5 to 6 is the risky one, because "understands mostly" has no visible edge. Decide
per change which files you will read in full (in this repo: anything in `engine/`, where the
rules live) and say so in the pull request.

## The loop for this repo

Everything below is driven by prompts and slash commands. You type no code.

| Step | Tool | What you get |
|------|------|--------------|
| 1. Isolate | `/new worktree`, or `copilot --worktree` **[D]** | A separate checkout, so a bad run cannot touch your working tree |
| 2. Specify and plan | `/plan <spec>` | A written plan; edits are blocked while it is being made **[D]** |
| 3. Execute | Standard mode, or autopilot | The change, with tests run by the agent |
| 4. Collect evidence | Tests, `agentStop` hook, `/diff`, `kotlin-reviewer`, `/review`, `/security-review` | Reasons to believe the change without reading all of it |
| 5. Roll back if needed | `/rewind` | The files as they were before a turn |
| 6. Make it reviewable | `/share` | A transcript a colleague can read |
| 7. Watch the cost | `/usage`, `/limits` | AI credits spent, and a cap |

Start the session with the repo's launcher. It pre-approves the build and test commands and
denies `.env`:

```bash
scripts/copilot-ws.sh
```

`--allow-tool='shell(./gradlew:*)'` covers `./gradlew :engine:test`, and `shell(npm test)` covers
`cd web && npm test` **[T]**. File edits still ask.

### Plan mode

| | |
|---|---|
| Enter | `/plan [prompt]`, or `Shift+Tab` (cycles standard → plan → autopilot **[D]**), or start with `copilot --plan` |
| What it blocks **[D]** | Edits, patches and shell commands that would change a file in the workspace. This is enforced by the CLI, not asked of the model. Subagents inherit it |
| What it lets through **[D]** | Writing the plan itself (kept outside the workspace, as `plan.md` in the session folder), shell commands whose effect cannot be determined, and external or MCP tool calls. It is not a sandbox |
| Approve **[D]** | A menu appears when the plan is ready. Documented choices: **Accept plan and continue in Autopilot execution mode**, the same **+ /fleet**, and **Exit to Interactive execution mode without running the plan** |
| Change the plan | Send another `/plan` prompt that says what is wrong. `COPILOT_EDITOR` (then `VISUAL`, `EDITOR`) names the editor the CLI uses when you edit the plan file yourself |
| Model for planning | `/model plan` sets a separate plan-mode model |

Approving a plan you have read is level 7. `copilot --plan --mode autopilot` **[D]** goes from
plan to implementation with no approval at all; that is level 8 or 9 depending on what you do
afterwards. Do not use it for work you must vouch for.

### Autopilot

Autopilot is about **continuation**: the agent keeps taking turns until the objective is done
instead of stopping after each answer. `/autopilot` toggles it; `/autopilot <objective>` sets a
goal and accepts `--max-ai-credits`.

What it is not:

- **It grants no permissions.** In autopilot a tool request that would prompt is denied. Give
  explicit allow rules at launch: `scripts/copilot-ws.sh --allow-tool='write'` adds file edits to
  the launcher's rules (an unscoped `write` rule is described in `copilot help permissions`).
  The launcher's `--deny-tool` rules still win.
- **It does not ask you.** When the agent would ask a question, Copilot answers that you are not
  available; the agent makes its best guess or stops with a summary of what is unclear.
- **It is not unlimited.** It pauses after 5 automatic continuations unless
  `--max-autopilot-continues` says otherwise.

On entering autopilot the CLI offers Allow All, Assisted permissions, Manual Approval or Cancel
**[D]**. Prefer launch-time allow rules plus Manual Approval over Allow All.

### Evidence instead of reading every line

| Evidence | How to get it | What it proves | What it does not |
|----------|---------------|----------------|------------------|
| Tests run by the agent | The instructions tell it to run the tests for the part it touched and report the result. Ask for the counts | The suite passes now | That the suite tests the change |
| A test that failed first | Ask for the test before the fix, and for the failing output | The test can detect this bug | That the fix is the smallest one |
| `agentStop` hook | Automatic: `.github/hooks/scripts/run-tests.sh` runs Gradle tests when `engine/` or `api/` has uncommitted changes, and web tests when `web/src/` has | A warning `run-tests hook: tests are failing in: ...` when the agent stops on red. Silence means green or nothing relevant changed | It is advisory. Exit code 2 from an `agentStop` hook warns and does not block **[T]** |
| `/diff` | Type it | The size and shape of the change | Correctness |
| `kotlin-reviewer` agent | Prompt below | Findings by severity, judged against this repo's instructions (`include-custom-instructions: true`). It has no edit tool | It has a shell for `git diff`, so "read-only" rests on its prompt and your permission rules |
| `/review` | Type it | A second opinion from the built-in `code-review` agent. It does not modify code **[D]** | It does not receive the repository instructions **[D]** |
| `/security-review` | Type it | Prioritised findings on the uncommitted changes, or on the branch diff when the tree is clean | It is not a full repository audit |
| Evals | [Example 9](09-validate-eval.md) | That a change to a skill or agent still makes Copilot behave as intended | Anything about application code |

> *"Use the kotlin-reviewer agent to review my uncommitted changes."*

Exercise 3 turns the advisory hook into a gate: an `agentStop` hook that prints
`{"decision":"block","reason":"..."}` sends the agent back to work, with `reason` as the next
user message **[T]**. The CLI stops honouring the block after 8 in a row **[D]**.

### Rollback

`/rewind` (alias `/undo`, or `Esc` twice on an empty prompt) restores an earlier turn.
Choose **Conversation only** or **Conversation + files**.

- Only files Copilot changed are restored; files you edited afterwards are skipped **[D]**.
- A rewind cannot be undone: the later turns are gone from the session. `/fork` first if you
  want to keep a copy of the conversation.
- Git stays the real safety net. Start from a clean tree or a worktree.

### Isolation with worktrees

| Command | Effect |
|---------|--------|
| `/new worktree` | Empty session in a new worktree |
| `/fork worktree` | Copy of the current conversation in a new worktree |
| `/worktree` | Move this session into a new worktree; uncommitted changes stay behind |
| `/move` | The same, and the uncommitted changes come along |
| `copilot --worktree[=NAME]` / `-w` **[D]** | Start inside a new or reused worktree. In the docs; not listed by `copilot --help` on 1.0.114 |

New worktrees go to a `<repo>.worktrees` folder beside the repository. Two things follow for
this repo: a fresh worktree has no `web/node_modules`, so the `agentStop` hook skips the web
tests there until you run `npm ci`; and with `/new worktree` or `/worktree` your uncommitted
files, a local `.env` included, stay in the original checkout.

Not verified: whether rules given as launch flags carry into a session started with
`/new worktree`. If the agent starts asking for `./gradlew`, run `scripts/copilot-ws.sh` from
inside the worktree folder instead.

### A session someone else can review

`/share file [path]` exports the transcript as Markdown, `/share html [path]` as HTML,
`/share link` makes a synced session visible to anyone who can read the repository, and
`/share gist` creates a secret gist (not available to Enterprise Managed Users **[D]**).
`/rename` gives the session a name before you export it.

The default file name is `copilot-session-<id>.md` in the current directory. Give a path
outside the repo, or delete the file before you commit. A transcript contains tool output; read
it before you attach it to a pull request.

### Cost

- `/usage` shows AI credits (premium requests on a plan with legacy billing), tokens per model
  and how much of the plan is used.
- `/limits set max-ai-credits <n>` caps the session (minimum 30); `/limits unset` removes the cap.
  It is a soft cap: one response can go past it, then the next model call is blocked.
- 1 AI credit is $0.01; Copilot Business includes 1,900 pooled credits per user per month **[D]**.
- For scale: a read-only question about this repo cost about 0.4 AI credits on `auto` **[T]**.
  A plan, a fix and two review runs cost a multiple of that, because every call resends the
  conversation.

## Worked example: the no-op move that spawns a tile

The bug: `GameService.move` stores the result of `board.move(direction)` in `changed`, ignores
it, and always calls `board.spawnRandom()`. Press a direction that moves nothing and a tile
appears anyway. The build is green because no test covers it.

1. **Start** the launcher, and isolate if you have other work in the tree:

   ```bash
   scripts/copilot-ws.sh
   ```

2. **Specify.** Paste this. It is the spec; the precision is the point.

   > */plan Bug: a move that changes nothing still spawns a tile. GameService.move ignores the
   > Boolean returned by board.move(direction) and always calls board.spawnRandom(). Expected:
   > when the move changes nothing, the returned game has exactly the same grid and score as
   > before, and no tile is added. When the move changes the board, exactly one tile is added,
   > as today. Constraints: write the failing test first; the test must not depend on random
   > tiles; do not change anything in engine/; keep the controller thin. If the test needs a way
   > to start a game from a known board, propose the smallest seam and wait for my approval.*

3. **Read the plan.** This is the review that matters most at level 7. Check four things:
   - The test comes before the fix.
   - The seam is small. `GameService` creates boards with `Board.newGame()`, which is random; a
     test needs a known board. A constructor parameter with a default is fine. A public setter or
     a test-only endpoint is not.
   - Files touched: `GameService.kt` and one test file under `api/`. Nothing in `engine/`.
   - The proof is a command: `./gradlew :api:test`.

   If something is off, send another `/plan` prompt with the correction. Then choose **Exit to
   Interactive execution mode without running the plan** **[D]**, so that you can stop between
   red and green.

4. **Red.**

   > *"Do the test step of the plan only. Run ./gradlew :api:test and show me the name of the
   > failing test and its assertion message. Do not change the body of GameService.move yet."*

   Evidence: one new test fails on an **assertion** about the grid. A compile error or a Spring
   context failure is not a red test.

5. **Green.**

   > *"Now make the smallest change in GameService.move that makes this test pass. Run
   > ./gradlew :api:test and report the pass and fail counts."*

6. **Prove the test guards the fix.**

   > *"Temporarily revert only the fix in GameService.move, run ./gradlew :api:test and confirm
   > the new test fails. Then restore the fix, run the tests again and show both results."*

7. **Review.** Run `/diff` and look at the size: a seam, a test, one condition. Then:

   > *"Use the kotlin-reviewer agent to review my uncommitted changes."*

   and `/review` for a second, independent reader. No warning from the `agentStop` hook means
   the Gradle tests passed when the agent stopped.

8. **Record.** `/usage`, then `/share file <path-outside-the-repo>`.

If you read every changed line in step 7, you worked at level 5. If you merged on steps 4–7
alone, that was level 7.

**The same in autopilot.** Start with `scripts/copilot-ws.sh --allow-tool='write'`, paste the
spec, and accept the plan with **Accept plan and continue in Autopilot execution mode**. You
lose the stop between red and green, so put it into the spec: "report the failing output
before you write the fix". Steps 6–8 stay yours.

## When the agent gets it wrong and you may not fix it yourself

The rule against typing code does not stop you from being precise. Move down this list.

| Situation | Move |
|-----------|------|
| The fix is wrong but the test passes | The test is weak. Add a case by prompt: *"Add a test: after a no-op move the number of non-zero tiles is unchanged."* Then ask for the fix again |
| It changed too much | `/rewind` to before the turn. Name the file and function, and forbid the rest: *"Change only GameService.move. Touch no other file."* |
| It edited the test to make it pass | `/rewind`. State that the test is the spec. For the next run add `--deny-tool='write(<TestFile>.kt)'`; a relative path in a rule matches by trailing path components |
| It keeps wandering into `engine/` | Add `--deny-tool='write(engine/**)'` (glob form per `copilot help permissions`; not tested here). A path rule does not cover shell commands, and GPT-family models sometimes write through shell redirection **[T]** |
| It loops on a failing test | Stop it, `/rewind`, switch to plan mode: *"Explain why the test still fails. Cite file and line. Change nothing."* Fix the spec, not the code |
| It does not understand the code path | Delegate the map first: *"Use the 2048-dev:game-explorer agent to trace a move from the controller to the board."* |
| It writes Spring Boot 3 idioms | That is an instruction gap. Have Copilot amend `.github/copilot-instructions.md`, then start a new session; instructions do not reload in a running one **[D]** |
| The conversation is polluted with failed attempts | `/new` with a fresh, shorter spec. `/rubber-duck` gives an independent critique of the current work |
| Same model, same mistake | `/model`, pick another one, and repeat the smallest failing step |
| Nothing helps | Dictate the change in words, at line level: *"In GameService.move, call board.spawnRandom() only when changed is true."* It is still generated, and you now know the spec was the problem |

## The risk at level 6 and above

Be honest about what you give up.

- **A green build proves little.** This repo is the demonstration: the build is green with three
  bugs in it. Tests written by the agent that wrote the code share its misunderstanding.
- **Review agents are probabilistic.** They miss things, and the built-in one does not know your
  conventions **[D]**.
- **You stop reading where it gets boring**, which is where bugs hide.
- **You are still the author of record.** The scale ends at "a human vouches".

What the repo's guard rails cover, and what they do not:

| Guard rail | Reduces | Does not cover |
|------------|---------|----------------|
| `block-destructive.sh` (`preToolUse`) | Destructive shell commands. A hook deny holds even with `--allow-tool='shell'` **[T]** | Commands it has no pattern for. Hook timeouts fail open **[D]** |
| `protect-secrets.sh` (`preToolUse`) | `.env` reaching the conversation through `view` or the shell **[T]** | A command that hides the file name. The script itself says it is not a security boundary |
| `format.sh` (`postToolUse`) | Style noise in the diff | Files written through shell redirection, which no edit matcher sees **[T]** |
| `run-tests.sh` (`agentStop`) | Stopping on red without noticing | Missing tests. It warns; it does not block |
| Launcher allow and deny rules | Approval fatigue, edits to `.env` | `--deny-tool='read(.env)'` blocks the `view` tool but not `cat .env` **[T]**; the hook closes that gap |
| `kotlin-reviewer` | Convention and logic slips, with repo context | Anything outside the diff |
| Plan approval | Work on the wrong problem | Bugs inside a correct plan |
| Worktree, `/rewind` | Damage to your working tree | Anything already pushed |
| Sandbox ([Example 8](08-permissions-sandbox.md)) | What a shell command can reach. Off by default **[D]** | Wrong code that is allowed to run |

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** | ✅ | Everything in this guide |
| **IntelliJ IDEA plugin** | ⚠️ | Has a Plan agent and custom agents, but `agentStop` is not among its published hook events, so the test hook is unconfirmed there. See [Example 12](12-intellij.md) |
| **Copilot cloud agent** | ⚠️ | Reached with `/delegate`. Review happens on the draft pull request instead of in the session. See [Example 13](13-remote-agents.md) |

## Troubleshooting

- **Autopilot stops with "permission denied" on every edit** → autopilot grants nothing. Launch
  with `scripts/copilot-ws.sh --allow-tool='write'`.
- **`/plan` produced code changes anyway** → plan mode lets through shell commands whose effect it
  cannot determine **[D]**. Check `/diff`, `/rewind` if needed, and report it to the facilitator.
- **The `agentStop` hook says tests fail but the agent said they pass** → believe the hook. Ask:
  *"Run ./gradlew test and paste the failing test names."*
- **No hook warning in a worktree although web tests are broken** → no `web/node_modules` there.
  Run `cd web && npm ci`.
- **`/rewind` did not restore a file** → you edited it after Copilot did, or the turn is outside
  what was captured **[D]**. Use `git restore`.
- **`/review` fails or returns nothing useful** → built-in agents carry their own default model
  **[D]**; with a restricted model list that model may not be available. Use `kotlin-reviewer`,
  and report it (see the [preflight checklist](preflight.md)).
- **Credits disappear quickly** → long sessions resend the whole conversation on every call.
  `/compact`, or `/new` with a fresh spec, and set `/limits set max-ai-credits <n>`.

---

Next: the same loop without a terminal session, from a script or a pipeline →
[Example 11: Programmatic mode and CI](11-programmatic-ci.md).

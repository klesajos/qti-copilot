> 🌍 Read this in: **English** | [Česky](exercises.cs.md)

# Exercises: one task per mechanism

> Verified on Copilot CLI 1.0.114 · every solution patch applies to a clean `main` and passes the
> build (`ex5-undo.patch` on top of `ex5.patch`) · most prompts were replayed once in `-p` mode on a
> test account, exercise 0 also in an interactive session; a step that was never run is marked ⚠️

## How to use this

1. Every exercise starts from a clean `main` and is independent of the others. Before each one:
   `git stash -u && git switch -c ex-N main` shelves the leftovers; `git status --short` is empty.
2. Start Copilot with `scripts/copilot-ws.sh` from the repository root.
3. You generate, you do not type code. Paste the prompt, read the plan, check the evidence
   (tests, `/diff`). The loop is in [01 · Getting started](01-getting-started.md).
4. Stop at the time box. Shelve your attempt (a patch fails on a half-done one), apply the solution:
   `git stash -u && git apply docs/copilot/solutions/exN.patch`. To list its files: `git apply --stat <patch>`.
5. Your model will not write the same code as the solution. "Done when" is the test, not the diff.

## At a glance

| # | Mechanism | Task | Layer | Time | When |
|---|---|---|---|---|---|
| [0](#0-on-ramp---fix-a-planted-bug-with-the-level-5-loop) | Level-5 loop | Fix the no-op spawn bug, failing test first | api | 7 min | block 01 |
| [1](#1-instructions---teach-the-web-conventions-then-colour-the-tiles) | Instructions | Add `web.instructions.md`, then colour the tiles | web | 10 min | block 02 |
| [2](#2-skill---capture-how-an-endpoint-is-added-then-add-one) | Skill | Write an `api-endpoint` skill, then add `DELETE /games/{id}` | api | 15 min | block 03 |
| [3](#3-hook---make-the-tests-un-skippable) | Hook | Turn the advisory test hook into a blocking gate | config | 15 min | block 04 |
| [4](#4-mcp---implement-a-feature-from-a-github-issue) | MCP | Best score, straight from a GitHub issue | api | 10 min | block 05, demo |
| [5](#5-agents---fix-two-planted-bugs-with-three-agents) | Agents | Explorer, test writer and reviewer fix two engine bugs | engine | 20 min | block 06 |
| [6](#6-plugin---add-a-skill-to-the-2048-dev-plugin) | Plugin | Add a `run-local` skill to `2048-dev` | config | 8 min | block 07 |
| [8](#8-eval---prove-a-skill-helps) | Eval | Add an eval case, lint, dry-run, read a with/without result | config | 15 min | block 09 |
| [7](#7-orchestration---an-auto-solver-chosen-by-a-judge) | Orchestration | Three solvers in parallel, a judge picks one | engine | 60 min | after |
| [B](#bonus-web---the-bug-nobody-planted) | Level-5 loop | Stale board after two fast key presses | web | 30 min | after |

The patches of exercises 0, 4 and `ex5-undo` all add `GameServiceTest.kt`: apply one per branch.

## 0. On-ramp 🟢 — fix a planted bug with the level-5 loop

**Time:** 7 min · **Guide:** [01 · Getting started](01-getting-started.md) · **Layer:** api · **Solution:** [`solutions/ex0.patch`](solutions/ex0.patch)

**Goal.** A no-op move spawns no tile, and a test in a new `GameServiceTest.kt` proves it.

**Why this mechanism.** Plan, failing test, fix, evidence is the loop every later exercise repeats.

### Steps

1. On a clean `main`, run `scripts/copilot-ws.sh` from the repository root. First time here: try the
   four commands of [First session](01-getting-started.md#first-session-3-min-before-exercise-0).
2. Plan. Paste the spec. After about half a minute a **Plan Ready for Review** box appears;
   `Ctrl+E` shows the full plan. Check it: test before fix, only two files under `api/` change.
   Choose option 1, **Exit to Interactive execution mode without running the plan**.
   > */plan Bug: `GameService.move` ignores the result of `board.move(direction)` and spawns a tile
   > even when nothing moved. Failing test first, in a new `GameServiceTest.kt`, without random
   > tiles: give `GameService` a constructor parameter `newBoard: () -> Board = { Board.newGame() }`.
   > Change nothing in `engine/` or `web/`. Proof: `./gradlew :api:test`.*
3. Red. Paste the first prompt and answer each edit prompt (`Update file`, `Create file`) with
   **1. Yes**; `./gradlew :api:test` runs without a prompt, folded to one timeline line:
   `✗ Shell … Failed with exit code 1` (`Ctrl+O` on an empty prompt expands every entry). The answer
   quotes the failed assertion; the turn ends with `run-tests hook: tests are failing in: gradle`.
   > *"Do the test step only: add the parameter and the test, run `./gradlew :api:test` and show
   > the failing test's name and its assertion message. Do not fix `GameService.move` yet."*
4. Green. Paste the second prompt and approve the one edit. The answer reports 6 passed, 0 failed (the solution has two tests: 7 passed).
   > *"Now fix `GameService.move`, rerun `./gradlew :api:test` and report the pass and fail counts."*
5. Type `/diff`: `Files (2)` on the left, the diff on the right. Read every line: one constructor
   parameter, one condition, one test file. `Esc` closes it.

### Done when

- `./gradlew :api:test` → `BUILD SUCCESSFUL`
- `git status --short` → ` M …/GameService.kt` and `?? …/GameServiceTest.kt`, nothing else
- Step 3 ended on a failed assertion, not on a compile error, and without the fix

### Key part of the solution

```diff
+class GameService(
+    private val newBoard: () -> Board = { Board.newGame() },
+) {
@@ fun move(id: UUID, direction: Direction): GameState
-            board.spawnRandom()
+            if (changed) {
+                board.spawnRandom()
+            }
```
Apply the whole solution: `git apply docs/copilot/solutions/ex0.patch`

### Go further

- Have Copilot remove only the `if (changed)`, rerun the tests, show the failure and restore it.

## 1. Instructions 🟢 — teach the web conventions, then colour the tiles

**Time:** 10 min · **Guide:** [02 · Custom instructions](02-custom-instructions.md) · **Layer:** web · **Solution:** [`solutions/ex1.patch`](solutions/ex1.patch)

**Goal.** `.github/instructions/web.instructions.md` holds the React conventions for `web/src`, and
the tiles are coloured by value in a way that follows the file.

**Why this mechanism.** A rule that must hold on every change under a path belongs in a scoped
instruction file, not in each prompt; `engine/` and `api/` have one, `web/` does not.

### Steps

1. On a clean `main` with `web/node_modules` installed (`cd web && npm ci`), run `scripts/copilot-ws.sh`.
2. Paste the starter prompt and approve the one new file.
   > *"Read every file in `web/src/`, `web/eslint.config.js` and `web/.prettierrc.json`. Write
   > `.github/instructions/web.instructions.md` with the front matter
   > `applyTo: "web/src/**/*.ts,web/src/**/*.tsx,web/src/**/*.css"`. State only conventions the code
   > already follows, each with what it forbids: exports, typing, what a component file may export,
   > where styles live, where HTTP calls live, where tests sit and how they query the DOM. At most
   > ten short imperative bullets, in the style of `.github/instructions/api.instructions.md`.
   > Change no other file."*
3. Read the file. It needs three rules the feature will exercise: styles are plain classes in
   `web/src/index.css` with no inline `style`; a component file exports components only, helpers
   get their own module; tests query by role or visible text. Tell Copilot to add what is missing.
4. Check that the CLI loads the file. In a second terminal, from the repository root:

   ```bash
   copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
   ```

   It prints `["web/src/**/*.ts","web/src/**/*.tsx","web/src/**/*.css"]`. One comma-separated
   `applyTo` string becomes three globs.
5. Instructions load when a session starts. Type `/exit`, run `scripts/copilot-ws.sh` again and paste
   the follow-up. The CLI delivers the file the first time Copilot opens a file matching `applyTo`:
   the timeline then shows `● Discovered web.instructions.md from .github/instructions/`.
   > *"Colour the tiles by value. Web only: do not touch `api/` or `engine/`. Add tests."*
6. Type `/diff`. You see a helper module next to `Board.tsx`, new `.tile-…` classes in `index.css`
   and a test that finds the tile by role or text. No `style=` attribute anywhere.

### Done when

- The command from step 4 → the three `web/src` globs
- `cd web && npm test && npm run lint && npm run build` → 0 tests failed (the solution ends at `Tests  11 passed (11)`), no ESLint findings, `✓ built in …`
- `grep -rn 'style=' web/src` → prints nothing
- `git status --short` → `.github/instructions/web.instructions.md` and paths under `web/src/` only

### Key part of the solution

```markdown
---
applyTo: "web/src/**/*.ts,web/src/**/*.tsx,web/src/**/*.css"
---

# Web rules

- Named exports only. No default exports, not even for components.
- Strict TypeScript: no `any`, no non-null `!`. Import types with `import type`.
- Function components with hooks. Props get an interface named `<Component>Props` in the same file.
- A component file exports components only. Pure helpers go in their own module (like `keys.ts`)
  so they can be tested without rendering.
- Styling lives in `web/src/index.css` as plain classes. No inline `style`, no CSS modules, no
  CSS-in-JS.
- HTTP goes through `web/src/api.ts`. Components never call `fetch` themselves.
- Tests sit next to the source as `<name>.test.ts(x)` and use Vitest with Testing Library. Query by
  role or visible text (`getByRole('gridcell')`), never by class name or test id.
- One behaviour per `it`, named as a sentence, Arrange-Act-Assert separated by blank lines.
- Run `npm test` and `npm run lint` in `web/` after the change and report the pass and fail counts.
```
Apply the whole solution: `git apply docs/copilot/solutions/ex1.patch`

### Go further

- Add a `moves: N` counter to the header the same way: it counts the moves the API accepted and
  returns to 0 on **New game**. The new `App.test.tsx` has to mock `./api`; add that rule first.
- Audit by prompt: *"Go through `web.instructions.md` rule by rule and fix where your diff breaks it."*

## 2. Skill 🟢–🟡 — capture how an endpoint is added, then add one

**Time:** 15 min · **Guide:** [03 · Skills](03-skills.md) · **Layer:** api · **Solution:** [`solutions/ex2.patch`](solutions/ex2.patch)

**Goal.** A project skill `.github/skills/api-endpoint/SKILL.md` that holds the procedure for adding an
endpoint, and `DELETE /api/v1/games/{id}` built with it: 204, a structured 404, `MockMvcTester` tests.

**Why this mechanism.** A skill holds a procedure and its shapes to copy, and loads only on demand.

### Steps

1. On a clean `main`, start `scripts/copilot-ws.sh` and paste:
   > *"Read `GameController.kt`, `GameService.kt`, `ApiExceptionHandler.kt` and `GameControllerTest.kt`
   > in `api/`, and `.github/instructions/api.instructions.md`. Write a project skill at
   > `.github/skills/api-endpoint/SKILL.md`, modelled on `.github/skills/board-tests/SKILL.md`, that
   > captures how an endpoint is added in this API. Sections: the order of work (rule in `engine`
   > first, service method, own exception, its handler, thin controller, `@WebMvcTest` test, run
   > `./gradlew :api:test`); the contract (URLs, the `ApiResponse` and `ErrorResponse` envelopes,
   > status codes, 204 with no body for a delete); shapes to copy (short real snippets from the
   > code); the Spring Boot 4 test idioms. State the path where controller tests live and that test
   > names are plain-English sentences in backticks. Write the `description` so that it says when
   > to use the skill; put no colon in it. Change no Kotlin file."*

   Approve the file write. Copilot reads the files the prompt names and creates one file. No Kotlin file changes.
2. Open `.github/skills/api-endpoint/SKILL.md` and compare it with the reference:
   ```markdown
   ---
   name: api-endpoint
   description: Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
   ---
   ## Order of work       rule in engine, service method, own exception, handler, controller, test, run
   ## Contract            /api/v1, { "data": ... }, { "error": { "code", "message" } }, 201 200 400 404, 204
   ## Shapes to copy      one real exception, handler, controller function and MockMvcTester test
   ## Boot 4, not Boot 3  WebMvcTest package, MockMvcTester, @MockitoBean, tools.jackson.*
   ```
   Check three lines that a rewrite loses easily, and tell Copilot to add what is missing: a delete
   answers 204 with no body; controller tests live in `api/src/test/kotlin/com/quanti/g2048/api/`;
   test names are sentences in backticks. A `: ` in an unquoted `description` is invalid YAML.
3. Leave the session with `/exit`. Run `copilot skill list --json | grep -A2 '"name": "api-endpoint"'`:
   it prints the name, your description and `"source": "project"`.
4. Start `scripts/copilot-ws.sh` again and paste the task. Do not name the skill:
   > *"Add an endpoint that deletes a game, with its tests."*

   Before the first edit Copilot calls the tool `skill` with `{"skill":"api-endpoint"}`; the TUI
   may not give that call a line. Then it edits `GameService.kt`, `GameController.kt`,
   `GameControllerTest.kt` and runs the API tests. Skill not used? Repeat the prompt with
   `/api-endpoint` in front, then sharpen the `description`.

### Done when

- `copilot skill list --json | grep -c '"name": "api-endpoint"'` → `1`
- `grep -cE 'NO_CONTENT|noContent\(\)' api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` → `1`
- `./gradlew :api:test` → `BUILD SUCCESSFUL`
- `grep -o 'tests="[0-9]*"' api/build/test-results/test/*.xml` → more than `tests="5"` (reference: 8)

### Key part of the solution

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+    fun delete(id: UUID) {
+        boards.remove(id) ?: throw GameNotFoundException(id)
+    }
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
+    @DeleteMapping("/{id}")
+    @ResponseStatus(HttpStatus.NO_CONTENT)
+    fun delete(@PathVariable id: UUID) {
+        games.delete(id)
+    }
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+    @Test
+    fun `deleting a game returns 204 with no body`() {
+        val id = createGameId()
+
+        val result = mvc.delete().uri("/api/v1/games/$id")
+
+        assertThat(result).hasStatus(HttpStatus.NO_CONTENT).hasBodyTextEqualTo("")
+    }
```
Apply the whole solution: `git apply docs/copilot/solutions/ex2.patch`

### Go further

- Two layers with the same skill: *"Make the win value configurable. `Board` owns the rule for legal
  values; `POST /api/v1/games` takes an optional `{"winValue": 1024}`; an illegal value answers 400."*
- Measure the skill with a with/without experiment: [09 · Evals](09-evals.md).

## 3. Hook 🟡 — make the tests un-skippable

**Time:** 15 min · **Guide:** [04 · Hooks](04-hooks.md) · **Layer:** config · **Solution:** [`solutions/ex3.patch`](solutions/ex3.patch)

**Goal.** `.github/hooks/scripts/run-tests.sh` sends Copilot back to work once when the tests for
the changed part of the tree fail, and only warns when they still fail on the next stop.

**Why this mechanism.** "Run the tests" in an instruction file is a request the model can skip; an
`agentStop` hook runs on every stop, whatever the model decided.

### Steps

1. On a clean `main` with `web/node_modules` in place (`cd web && npm ci`), run
   `scripts/copilot-ws.sh` from the repository root.
2. Paste the starter prompt and approve the edit. Today the script exits 2 on red: a warning only.
   > *"Rewrite `.github/hooks/scripts/run-tests.sh` so that the `agentStop` hook blocks when tests
   > fail. Keep what it tests now: Gradle when `engine/` or `api/` has uncommitted changes, Vitest
   > when `web/src/` has. On failure print exactly one JSON object
   > `{"decision":"block","reason":"..."}` on stdout and exit 0. Put the failing suites, the command
   > to rerun them and the last 30 lines of the test output into `reason`. Read `stop_hook_active`
   > from the JSON on stdin: when it is true, do not block again; write one line to stderr and
   > exit 2. Do the same when `jq` is missing. Do not change `hooks.json`."*
3. Test the script without Copilot: a hook reads JSON on stdin and answers on stdout. In a second
   terminal, from the repository root, run three cases: nothing to test, red, red after a block.
   ```bash
   payload() { printf '{"cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }
   hook=./.github/hooks/scripts/run-tests.sh
   payload false | $hook; echo "exit=$?"
   perl -pi -e "s/toBe\('UP'\)/toBe('DOWN')/" web/src/keys.test.ts
   payload false | $hook | jq -r '.decision'
   payload true  | $hook; echo "exit=$?"
   git restore web/src/keys.test.ts
   ```
   You see four lines; the wording of the third is your script's own. With `.reason` instead of
   `.decision` the second command prints what Copilot will receive.
   ```text
   exit=0
   block
   run-tests hook: tests are failing in: web (cd web && npm test). Not sent back: this turn was …
   exit=2
   ```
4. Back in the session, paste the follow-up. The session already uses the new script: the CLI
   starts it from disk on every stop.
   > *"In `web/src/keys.ts`, make `toDirection` case-sensitive: an upper-case `W` must no longer
   > count as a move. Do not run the tests."*

   Copilot edits `keys.ts` and ends its turn. The hook runs Vitest, then a turn starts that you did
   not type. Its prompt is the hook's `reason`: `run-tests hook: tests are failing in: web …` and
   the Vitest output with `× ignores the case of a WASD key`. Copilot changes the code again, runs
   `cd web && npm test` and stops on green; on that stop the hook prints nothing.
5. Type `/diff`. The gate proves that the tests pass, not that the change is right: Copilot can
   add upper-case `S`, `A`, `D` to the key map and leave `W` out. Then run `git restore web/src`.

### Done when

- No change under `engine/`, `api/`, `web/src/`: `payload false | $hook; echo "exit=$?"` → `exit=0`
- Red test: `payload false | $hook | jq -r '.decision'` → `block`
- Red test: `payload true | $hook; echo "exit=$?"` → one warning line, then `exit=2`
- In the session, a turn you did not type starts with `run-tests hook: tests are failing in: web`

### Key part of the solution

```diff
-cat >/dev/null
+input=$(cat)
@@ the Gradle branch, without --quiet; the Vitest branch changes the same way
+    if ! result=$(./gradlew test 2>&1); then
+        failed="$failed gradle (./gradlew test)"
+        output="$output$result"$'\n'
+    fi
@@ the ending
+[ -n "$failed" ] || exit 0
+already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
+if [ "$already_blocked" != "false" ]; then
+    echo "run-tests hook: tests are failing in:$failed. Not sent back: …" >&2
     exit 2
 fi
+reason="run-tests hook: tests are failing in:$failed. Find the cause, fix it, …"
+reason="$reason"$'\n'"$(printf '%s' "$output" | tail -n 30)"
+jq -cn --arg reason "$reason" '{decision: "block", reason: $reason}'
 exit 0
```
Apply the whole solution: `git apply docs/copilot/solutions/ex3.patch`

### Go further

- Build a feature behind the gate: a server-side move counter (`moves` in the game state, counted
  only when the board changed, shown in the web header). The hook then runs Gradle and Vitest.
- Make the gate strict: delete the `stop_hook_active` branch. The CLI ends the turn after 8 blocks.

## 4. MCP 🟡 — implement a feature from a GitHub issue

**Time:** 10 min in full; in the workshop the facilitator shows steps 1 to 3 (5 min) · **Guide:** [05 · MCP under an allow-list](05-mcp.md) · **Layer:** api · **Solution:** [`solutions/ex4.patch`](solutions/ex4.patch)

**Goal.** Copilot reads the issue "Show the best score" through the built-in GitHub MCP server and
implements it: every game state the API returns carries `bestScore`. A pull request references it.

**Why this mechanism.** MCP lets the agent fetch the spec from the system that owns it.

### Steps

1. On a clean `main`, file the issue and note its number `<N>`. ⚠️ not run in this repo
   ```bash
   gh issue create --title "Show the best score" --body-file docs/copilot/solutions/ex4-issue.md
   ```
2. Start the session with the two issue tools. With `gh` on `PATH` the built-in server exposes
   6 tools and none reads issues; `--add-github-mcp-tool` replaces that subset with the tools named.
   ```bash
   scripts/copilot-ws.sh --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
   ```
3. Paste the starter prompt. The timeline shows a call to `github-mcp-server-issue_read`; Copilot
   repeats the acceptance criteria and changes no file. ⚠️ not run in this repo
   If Copilot runs `gh issue view` or has no issue tool, the flags are missing: repeat step 2. No
   `github-mcp-server` in `/mcp list`: start with *"Read docs/copilot/solutions/ex4-issue.md."*
   > *"Read issue #<N> of this repository with the issue_read tool of the GitHub MCP server. Repeat
   > its acceptance criteria as a numbered list and name the files you will change for each one.
   > Do not edit anything yet."*
4. Paste the follow-up and approve the edits to `GameService.kt` and the two test files.
   > *"Implement the issue in `api` only. The best score is shared by all games: test it in a new
   > `GameServiceTest` with a fresh `GameService()` per test and give the service an `internal` way
   > to start a game on a board the test supplies. The controller tests share one service: add one
   > test there that only checks the `bestScore` field is present. Run `./gradlew build`."*
5. Type `/diff` and read it against the criteria. Then type
   `!git switch -c best-score && git add api && git commit -m "Show the best score (#<N>)"` and
   `/pr create`; check that the description references `#<N>`. ⚠️ not run in this repo

### Done when

- `/mcp get github-mcp-server` → `tools (2)`: `list_issues` and `issue_read`; `q` closes the screen
- `./gradlew build` → `BUILD SUCCESSFUL`
- `./gradlew :api:bootRun`; `curl -s -X POST localhost:8080/api/v1/games | jq .data.bestScore` → `0`
- `/pr view` → the pull request of branch `best-score`

### Key part of the solution

```diff
@@ data class GameState(
+    val bestScore: Int,
@@ class GameService {
+    // Atomic because games move in parallel; the lock in move() guards one board only.
+    private val bestScore = AtomicInteger(0)
+    fun create(): GameState = start(Board.newGame())
+    /** Starts a game on the given board. Tests use it to begin from a known position. */
+    internal fun start(board: Board): GameState {
@@ fun move(id: UUID, direction: Direction): GameState {
+            bestScore.updateAndGet { best -> maxOf(best, board.score) }
@@ private fun stateOf(id: UUID, board: Board): GameState {
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, bestScore.get())
```
Apply the whole solution: `git apply docs/copilot/solutions/ex4.patch`

### Go further

- **Web layer.** File a second issue, "Show `best: N` in the header", and repeat steps 2 to 5:
  `bestScore: number` in `web/src/api.ts`, one `<p>` in `App.tsx`, a test with a mocked `./api`.
- **Jira variant** (⚠️ not run in this repo). `cp .mcp.json.example .mcp.json`, put the URL of 2N's
  approved Jira MCP server in place of the placeholder and restart the session. `/mcp list` shows
  `jira` as connected; run `/mcp auth jira` if it asks you to sign in. Use the same two prompts
  with *"Read Jira issue <KEY> with the jira server"* in place of the GitHub issue.

## 5. Agents 🟡 — fix two planted bugs with three agents

**Time:** 20 min · **Guide:** [06 · Custom agents](06-agents.md) · **Layer:** engine · **Solution:** [`solutions/ex5.patch`](solutions/ex5.patch)

**Goal.** `slideLineLeft` turns `4, 4, 8, 0` into `8, 8, 0, 0` for 8 points, and `isGameOver()` is
false for a full board with a mergeable pair. Each fix has a test that failed first.

**Why this mechanism.** Each agent has its own context and its own tool list: exploration and test
output stay out of the main context, and the explorer and the reviewer cannot edit a file.

### Steps

1. On a clean `main` (`git status --short` prints nothing), run `scripts/copilot-ws.sh` from the
   repository root. It pre-approves `./gradlew`, which the test writer needs.
2. Paste the starter prompt. Naming an agent makes the main agent call the `task` tool with
   `agent_type` set to that agent.
   > *"Two engine rules are suspected to be wrong. Sliding the line 4, 4, 8, 0 must give 8, 8, 0, 0
   > and score 8. A full board that still has two equal neighbours must not be game over. First use
   > the 2048-dev:game-explorer agent to find the function and the lines that decide each rule.
   > Then use the board-test-writer agent to add one test per rule to BoardTest.kt. Do not change
   > Board.kt. Report which tests fail and why."*

   You see two delegations in this order. `2048-dev:game-explorer` (plugin agent, tools `read`
   and `search`) returns a `file:function:line` trace that ends in `slideLineLeft` and
   `Board.isGameOver`. `board-test-writer` (project agent, also `edit` and `execute`) changes
   `BoardTest.kt` and runs `./gradlew :engine:test`; approve the edit. The turn ends with 2 of
   15 tests failing and the warning `run-tests hook: tests are failing in: gradle`. Red is the
   expected state here.
3. In a second terminal, check that the tests assert the rule and not the current behaviour:
   ```bash
   git status --short        # only BoardTest.kt is modified
   git diff engine/src/test | grep -E '^\+.*(8, 8, 0, 0|assertFalse)'
   ```
   The `grep` prints two added lines. An assertion on `16, 0, 0, 0` means the agent bent the test
   to get a green run: tell it to restore the correct expectation before you go on.
4. Paste the follow-up. The main agent fixes; the reviewer has no edit tool.
   > *"Fix both bugs in Board.kt so that the two new tests pass. Do not change any test. Run
   > ./gradlew :engine:test and report the counts. Then use the kotlin-reviewer agent to review the
   > uncommitted changes and show me its findings."*

   You see an edit to `Board.kt` (approve it), a test run with 15 passed, then a delegation to
   `kotlin-reviewer`. It reads the change with `git status` and `git diff` and reports findings as
   Blocker, Should-fix and Nit. The main agent may shorten that report to one line.
5. Read the fix yourself with `git diff engine/src/main`. After a merge the scan must move past
   the merged tile, and `isGameOver()` must compare every cell with its right and lower neighbour.

### Done when

- `./gradlew :engine:test` → `BUILD SUCCESSFUL`
- `grep -o 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' engine/build/test-results/test/TEST-*.xml` → `tests="15" skipped="0" failures="0"`
- `git status --short` → two modified files, `Board.kt` and `BoardTest.kt`
- The `kotlin-reviewer` report contains no Blocker

### Key part of the solution

```diff
@@ fun slideLineLeft(line: IntArray): Int
             out[count - 1] = 0
             count--
-            // NOTE: index `i` is intentionally not advanced here.
-        } else {
-            i++
         }
+        // A tile merges at most once per move, so step past it even when it has just merged.
+        i++
     }
@@ fun isGameOver(): Boolean
         for (row in 0 until SIZE) {
             for (col in 0 until SIZE) {
-                if (cells[row][col] == 0) {
+                val value = cells[row][col]
+                if (value == 0) {
+                    return false
+                }
+                // Looking right and down covers every neighbouring pair exactly once.
+                if (col + 1 < SIZE && cells[row][col + 1] == value) {
+                    return false
+                }
+                if (row + 1 < SIZE && cells[row + 1][col] == value) {
                     return false
                 }
```
Apply the whole solution: `git apply docs/copilot/solutions/ex5.patch`

### Go further

- Build **undo** in all three layers with the same team: `Board.undo()` tests first, then
  `POST /api/v1/games/{id}/undo`, the `u` key and an Undo button. Reference, from a clean `main`
  (it also guards the spawn after a no-op move):
  `git apply docs/copilot/solutions/ex5.patch && git apply docs/copilot/solutions/ex5-undo.patch`
- Test a tool boundary instead of trusting the agent's prompt:
  `copilot --agent 2048-dev:game-explorer -p "Create a file named probe.txt" --trust-folder --no-ask-user`,
  then `git status --short` shows no new file.

## 6. Plugin 🟡 — add a skill to the 2048-dev plugin

**Time:** 8 min · **Guide:** [07 · Plugins](07-plugins.md) · **Layer:** config · **Solution:** [`solutions/ex6.patch`](solutions/ex6.patch)

**Goal.** The `2048-dev` plugin ships a second skill, `run-local` (start the API and the web UI,
smoke-test them), at version 1.1.0, and a session offers it as `/2048-dev:run-local`.

**Why this mechanism.** A plugin is what you hand to a guild: one versioned unit carries the skill.

### Steps

1. On a clean `main`, run `scripts/copilot-ws.sh` from the repository root and paste:
   > *"Add a skill to the 2048-dev plugin at `plugins/2048-dev/skills/run-local/SKILL.md`, modelled
   > on `plugins/2048-dev/skills/build-test/SKILL.md`: how to run the app on this machine. Take the
   > facts from `web/vite.config.ts` and `GameController.kt`: the two start commands, the ports, the
   > `/api` proxy, the strict web port, and one `curl` smoke test that creates a game through the
   > proxy, with the expected status and body. At most 30 lines. Frontmatter: `name: run-local` and
   > a `description` that says when to use it. Then raise the version from 1.0.0 to 1.1.0 in
   > `plugins/2048-dev/plugin.json` and in the plugin's entry in `marketplace.json` (not
   > `metadata.version`), and name the new skill in both descriptions. Do not start any server."*

   Copilot creates one file and edits two. Nothing registers the skill: the CLI finds it by its
   path, `skills/<name>/SKILL.md`, and prefixes its command with the plugin's `name`.
2. Read the new `SKILL.md` against `web/vite.config.ts` and `GameController.kt`: ports 8080 and
   5173, `strictPort`, `POST /api/v1/games` → 201. No tool checks a skill against the code.
3. In a second terminal, check the plugin without a model call:
   ```bash
   copilot --plugin-dir ./plugins/2048-dev plugin list | tail -1
   copilot --plugin-dir ./plugins/2048-dev skill list --json | jq -r '.[] | select(.source == "plugin") | .name'
   ```
4. Type `/exit` and start a new session: it reads the plugin from the working tree. Type `/2048`:
   the suggestion list offers `/2048-dev:run-local` next to `/2048-dev:build-test`. Clear the line with `Ctrl+U` and paste:
   > */2048-dev:run-local Do not start anything. In two lines: which two commands start the app,
   > and on which ports?*

   The timeline shows your command and no line for the skill. Copilot answers
   `./gradlew :api:bootRun` on 8080 and `cd web && npm run dev` on 5173.

### Done when

- `jq -r .version plugins/2048-dev/plugin.json` → `1.1.0`
- `jq -r '.plugins[0].version, .metadata.version' marketplace.json` → `1.1.0`, then `1.0.0`
- The two commands of step 3 → `• 2048-dev (v1.1.0)`, then `build-test` and `run-local`
- Step 4 answers with both commands and both ports

### Key part of the solution

```diff
+++ b/plugins/2048-dev/plugin.json
-  "version": "1.0.0",
+  "version": "1.1.0",
+++ b/plugins/2048-dev/skills/run-local/SKILL.md
+---
+name: run-local
+description: Start the 2048 app on this machine (Spring Boot API on port 8080, Vite dev server on port 5173) and smoke-test it with curl. Use when asked to run or start the app, to try a change in the browser, or to check that the API answers.
+---
```
Apply the whole solution: `git apply docs/copilot/solutions/ex6.patch`

### Go further

- Package knowledge that spans three layers: apply `solutions/ex5.patch`, then
  `solutions/ex5-undo.patch`, then add `skills/undo/SKILL.md` with where undo lives in each layer
  and the rules a change must keep.

## 7. Orchestration 🔴 — an auto-solver chosen by a judge

**Time:** after the workshop, about 60 min · **Guide:** [10 · Beyond one session](10-orchestration.md) · **Layer:** engine · **Solution:** [`solutions/ex7.patch`](solutions/ex7.patch)

**Goal.** An engine-only auto-solver: a `Solver` contract, three heuristics written by three parallel
subagents, and a seeded benchmark whose table, not a model, decides which heuristic wins.

**Why this mechanism.** `/fleet` pays off when the work splits into parts that own disjoint files.

### Steps

1. Start `scripts/copilot-ws.sh` on a clean `main`. One agent writes the shared pieces first:
   > *"In the engine module create the package `com.quanti.g2048.engine.solver`. `Solver.kt`: interface
   > `Solver` (`val name: String`; `fun chooseMove(board: Board): Direction?`, null when no direction
   > changes the board, never modifies it), class `Outcome(direction, grid, gained)` and
   > `legalOutcomes(board)`: every direction tried on a copy `Board(board.grid, board.score)`, only
   > those that change the board, in enum order. `Benchmark.kt`: `playGame(solver, random)` plays
   > `Board.newGame(random)` until the solver returns null, without `isGameOver()`;
   > `benchmark(solver, games, seed)` seeds game n with `Random(seed + n)` and returns solver name,
   > games, average score, best tile. No printing in main code. Tests: `SolverTest.kt`,
   > `BenchmarkTest.kt` (uses `GreedySolver()`). `BenchmarkRunner.kt` in the test source set prints
   > one row per solver for `CornerSolver()`, `GreedySolver()`, `MonotonicSolver()`; a `JavaExec` task
   > `benchmark` in `engine/build.gradle.kts` runs it with `-Pgames` (default 1000) and `-Pseed`
   > (default 2048). The three solvers come in the next step: do not create them, and verify with
   > `./gradlew :engine:compileKotlin` only."*
2. Expect `BUILD SUCCESSFUL` plus a `run-tests hook` warning (no solvers yet). Fan out, watch
   `/tasks`. The subagents' approval prompts appear in your session: answer them or they wait.
   > */fleet Build three 2048 solvers in parallel, one subagent each, in the engine package
   > `com.quanti.g2048.engine.solver`. Use general-purpose subagents. Each subagent reads `Solver.kt`
   > first, creates only its solver and its test file, and does not run Gradle (all three write into
   > one source set). (1) `CornerSolver`, name "corner": the outcome with the most tile value near
   > the top-left corner, weights falling along a snake. (2) `GreedySolver`, name "greedy": the
   > highest `gained`, the first one wins a tie. (3) `MonotonicSolver`, name "monotonic": the most
   > neighbouring pairs whose value does not grow from left to right or from top to bottom. Each
   > returns null when no outcome is legal. When all three are done, run `./gradlew :engine:test`
   > yourself, fix what fails, then run `./gradlew -q :engine:benchmark` and name the winner by
   > average score from the printed numbers alone.*
3. Conductor variant: the same split from a YAML file. It approves the agents' file writes itself.
   `rm engine/src/*/kotlin/com/quanti/g2048/engine/solver/{Corner,Greedy,Monotonic}*.kt`, then
   `git apply --include='conductor/*' docs/copilot/solutions/ex7.patch`, then
   `conductor validate conductor/solver-tournament.yaml` → `Validation Successful`, then
   `conductor --silent run conductor/solver-tournament.yaml` → JSON with `winner`, `ranking`, `reason`.

### Done when

- `./gradlew build` → `BUILD SUCCESSFUL`; `git status --short` → only `engine/` paths before step 3
- `./gradlew -q :engine:benchmark`, twice → the same three rows; reference: `monotonic` wins, 3047.5

### Key part of the solution

```diff
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/solver/GreedySolver.kt
+    override fun chooseMove(board: Board): Direction? =
+        legalOutcomes(board).maxByOrNull { it.gained }?.direction
```
Apply the whole solution: `git apply docs/copilot/solutions/ex7.patch`

### Go further

- On top of `ex5.patch`, `greedy` (3000.0) nearly ties `monotonic` (3037.4): give the judge a tie rule.
- On `main` no heuristic gets past the 512 tile: add a solver that searches deeper, same interface.

## 8. Eval 🟡 — prove a skill helps

**Time:** 15 min · **Guide:** [09 · Evals](09-evals.md) · **Layer:** config · **Solution:** [`solutions/ex8.patch`](solutions/ex8.patch)

**Goal.** `evals/board-tests/eval.yaml` has a second positive case, `cascade-merge-line`, that
lints and dry-runs, and you can say what the recorded with/without result proves.

**Why this mechanism.** A skill costs tokens in every session; an A/B run shows what it buys.

### Steps

1. Run `npm ci` once at the repository root (installs Vally). Start `scripts/copilot-ws.sh`, paste:
   > *"Add a second positive stimulus named `cascade-merge-line` to `evals/board-tests/eval.yaml`,
   > between `game-over-edge-case` and `unrelated-question`, modelled on `game-over-edge-case`. Its
   > prompt asks for a unit test of the merge rule: moving the row 4, 4, 8, 0 to the left must give
   > 8, 8, 0, 0 and add 8 to the score. The prompt must not name the skill or the function
   > `slideLineLeft`, and it keeps the sentence about the missing build tool. Read
   > `.github/skills/board-tests/SKILL.md` and add one `file-matches` grader per convention the
   > skill states for this case, plus `completed` and `file-exists`. Change nothing else. Run
   > `npm run eval:lint` and show its output. Do not run the eval."*

   Copilot edits one file and shows two `✔ … is valid` lines.
2. Review the graders. Each one checks a sentence of the skill (test name in backticks,
   `slideLineLeft` for merge rules, expected value first) and passes every correct test. A
   pattern that pins a variable name or a blank line, such as `val gained = slideLineLeft\(line\)`,
   fails a correct test that names things differently. If you find one, paste:
   > *"Loosen every grader pattern of `cascade-merge-line` that pins a variable name, whitespace or
   > a line break, so that any correct test that follows the skill passes. Keep one grader per
   > convention. Run `npm run eval:lint` again."*
3. Lint and dry-run. Neither calls a model:
   ```bash
   npm run eval:lint
   VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
   ```
   The dry run prints two plans, `skills=without (baseline)` and `skills=with`. They share one
   `Eval hash` and differ in `Config hash`: the arms differ in the environment and in nothing
   else. On a clean `main` the eval hash is `ef971c7643e7f213`; yours is a new value.
4. Read the result recorded for the two older cases under
   [Read the result](09-evals.md#read-the-result) in guide 09: the positive case passed in 0 of 4
   trials without the skill and in 3 of 4 with it, for 26–32% more tokens.
5. Optional, paid: `npm run eval:ab`. With your case it is 12 real Copilot sessions (2 variants ×
   3 stimuli × 2 runs); the recorded 8-session runs took under a minute each. Compare the
   `cascade-merge-line` rows in `evals/results/<timestamp>/report.md`. ⚠️ not run in this repo

### Done when

- `grep -c '^  - name:' evals/board-tests/eval.yaml` → `3`
- `npm run eval:lint` → `✔ evals/board-tests/eval.yaml is valid`, `✔ evals/game-explorer/eval.yaml is valid`
- The dry run → `Baseline:   skills=without`, `Plans:      2`, the same `Eval hash` in both plans
- `git status --short` → ` M evals/board-tests/eval.yaml` and nothing else

### Key part of the solution

```yaml
  - name: cascade-merge-line
    prompt: >-
      Write a unit test for the 2048 merge rule: moving the row 4, 4, 8, 0 to the left must
      give 8, 8, 0, 0 and add 8 to the score, because a tile merges at most once per move.
      Follow this project's test conventions. This workspace has no build tool, so do not
      try to compile or run anything.
    graders:  # completed, file-exists and the backtick test name as in the first case, then:
      # Merge rules are tested through the top-level function, not through Board.move.
      - type: file-matches
        config:
          path: engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
          pattern: 'slideLineLeft\('
      # Two more of the same shape: 'assertEquals\(\s*8\s*,' (score gained, expected value first)
      # and '8,\s*8,\s*0,\s*0' (the correct line is kept; the current code returns 16, 0, 0, 0)
```
Apply the whole solution: `git apply docs/copilot/solutions/ex8.patch`

### Go further

- Evaluate a skill of your own, for example `api-endpoint` from exercise 2: copy the spec to
  `evals/api-endpoint/`, copy only application source into the trial workspace, add an experiment file, lint, dry-run.

## Bonus (web) 🟡 — the bug nobody planted

**Time:** after the workshop, about 30 min · **Guide:** [01 · Getting started](01-getting-started.md) · **Layer:** web · **Solution:** [`solutions/bonus.patch`](solutions/bonus.patch)

**Goal.** A test that reproduces the stale board after two fast key presses, then the fix in `App.tsx`.

**Why this mechanism.** No new mechanism: the level-5 loop on a bug without a prepared answer.

### Steps

1. Run `cd web && npm ci`, start `scripts/copilot-ws.sh` on a clean `main` and paste:
   > *"Two arrow keys pressed almost together can leave the board stale: the server applied both
   > moves, but the screen shows whichever response arrived last. Find the cause in `web/src`.
   > Intended behaviour: one move in flight at a time; a key press while a move is pending is
   > ignored. Do not fix anything yet. Write a test in `web/src/App.test.tsx`, mocking `./api`,
   > that fails because of this, run `npm test` in `web/` and show me the failure."*
2. Copilot names the cause (one request per key press) and shows the new test failing. Then paste:
   > *"Now fix it in `App.tsx`: ignore direction keys until the pending move returns, on success and
   > on failure, but keep `preventDefault`. In the test, render inside `await act(async () => ...)`
   > so the key listener is registered before the first key. Run the web tests, lint and build."*

### Done when

- after step 1: `cd web && npm test` → `1 failed`, `expected "vi.fn()" to be called 1 times, but got 2 times`
- after step 2: `cd web && npm test && npm run lint && npm run build` → `Tests  8 passed (8)`, `✓ built in`

### Key part of the solution

```diff
+      if (isMoveInFlight.current) {
+        return
+      }
+      isMoveInFlight.current = true
       move(game.id, direction)
```
Apply the whole solution: `git apply docs/copilot/solutions/bonus.patch`

### Go further

- Add a test that the next key press is accepted once the pending move has resolved or failed.

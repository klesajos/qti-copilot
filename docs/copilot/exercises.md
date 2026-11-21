> 🌍 Read this in: **English** | [Česky](exercises.cs.md)

# Exercise catalog: one feature per mechanism

The guides explain the mechanisms one by one: [Instructions](01-custom-instructions.md),
[Skills](02-skills.md), [Hooks](03-hooks.md), [MCP](04-mcp.md), [Agents](05-agents.md),
[Plugins](06-plugins.md), [Orchestration](07-orchestration.md), [Evals](09-validate-eval.md).
This catalog turns them into practice. **Each exercise builds one game feature and uses it as
the vehicle for one mechanism.** The feature is small on purpose; the mechanism is the point.

Each exercise is self-contained. It gives you a paste-ready **starter prompt**, the **files**
involved, the relevant code explained inline, a **walkthrough with the full reference
solution**, and a **done check**. The linked guide is optional depth.

## How to use this catalog

You generate the code through Copilot. At 2N you are not allowed to write it by hand, so the
exercises are built the same way: your tools are prompts, approvals and review. You are still
expected to understand every line that lands (level 5 on the
[scale](https://www.visidata.org/blog/2026/ai/)).

1. **Start from a clean `main`.** Every exercise assumes the repository as it was cloned.
   Two exceptions say so themselves: exercise 6 branches from your exercise 5 branch, and
   exercise 8 copies the skill from your exercise 2 branch.

   ```bash
   git switch main && git status --short     # must print nothing
   git switch -c ex1-instructions            # one branch per exercise
   ```

2. **Start Copilot from the repository root** with `scripts/copilot-ws.sh`. The launcher
   pre-approves `./gradlew`, `npm test` and `npm run`, and denies reads and writes of `.env`.
   Extra flags are passed through; exercise 4 needs two.
3. **Paste the starter prompt** as it is. Read what Copilot proposes before you approve it.
4. **Steer with follow-up prompts, not with the editor.** Each walkthrough lists the two or
   three prompts that lead from the starter prompt to the solution, and names the mechanism
   that does the work at each step.
5. **Compare with the walkthrough.** It is the reference solution, built and tested for this
   catalog. It is there to compare against, not to type in. Your result may use other names
   and still be right; the done check decides. `/diff` shows what Copilot changed.
6. **Run the done check.** Every exercise lists the exact commands and what you should see.
7. **Commit on the exercise branch** (ask Copilot to do it) and switch back to `main`. The
   next exercise starts clean again.

Every exercise is tagged with the layers it touches: **engine** (Kotlin rules), **api**
(Spring Boot) and **web** (React). The done check always includes the baseline for those layers:

```bash
./gradlew build                                        # engine + api: BUILD SUCCESSFUL
cd web && npm test && npm run lint && npm run build    # web (run npm ci once before)
```

Gradle prints no test counts on success. This prints them from the reports:

```bash
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
```

A clean `main` has 13 engine tests, 5 API tests and 7 web tests.

**Leave the three planted bugs alone in exercises 1–4.** `slideLineLeft` merges a tile twice
(`4,4,8,0` gives `16,0,0,0`), `Board.isGameOver()` only looks for an empty cell, and
`GameService.move` spawns a tile after a move that changed nothing. Exercise 5 fixes two of
them. If Copilot offers to fix one in passing, say no; the reference solutions below keep them.

There is a fourth bug, in the web layer, that nobody planted: it turned up when the app was
tested in a browser. It is kept for the [bonus exercise](#bonus-web---a-bug-nobody-planted)
at the end. Leave it alone in exercises 1–8 as well.

Difficulty: 🟢 Easy · 🟡 Medium · 🔴 Hard.

## At a glance

| # | Mechanism | Feature exercise | Difficulty | Layers |
|---|---|---|---|---|
| 1 | [**Instructions**](01-custom-instructions.md) | Write `web.instructions.md`, then colour the tiles by value and add a `moves: N` counter | 🟢 | web |
| 2 | [**Skill**](02-skills.md) | Write an `api-endpoint` skill, then make the win value configurable (`{"winValue": 1024}`, 400 on an invalid value) | 🟢–🟡 | engine · api |
| 3 | [**Hook**](03-hooks.md) | Turn `run-tests.sh` into a gate that blocks on red, then add a server-side move counter behind it | 🟡 | api · web |
| 4 | [**MCP**](04-mcp.md) | Implement the issue "Show the best score" read through the built-in GitHub MCP server, then `/pr create` | 🟡 | api · web |
| 5 | [**Custom agents**](05-agents.md) | Fix the game-over and no-op-spawn bugs, then build undo across the explorer, test-writer and reviewer agents | 🟡 | engine · api · web |
| 6 | [**Plugin**](06-plugins.md) | Package an undo workflow skill into the `2048-dev` plugin and bump its version | 🟡 | none (config) |
| 7 | [**Orchestration**](07-orchestration.md) | An auto-solver chosen by a judge: heuristics built in parallel with `/fleet`; Conductor variant optional | 🔴 | engine |
| 8 | [**Eval**](09-validate-eval.md) | Prove a skill helps: write an eval case, run it with and without the skill, read the delta | 🟡 | none (config) |
| + | Bonus | Find and fix a stale-board race in the UI, with the failing test first | 🟡 | web |

---

## 1. Instructions 🟢 — teach the web conventions, then use them

**Layers:** web

**Goal.** Write `.github/instructions/web.instructions.md`, a path-scoped instruction file for
the React client. Then, with the file in place, have Copilot **colour the tiles by value** and
add a **`moves: N` counter** to the header, and check that the result follows the file.

**Mechanism it teaches.** [Path-scoped instructions](01-custom-instructions.md): rules that
apply to every session, but only for files matching `applyTo`. The repository already has such
files for `engine/` and `api/`; `web/` has none. Instructions state rules that always hold.
A procedure you only need sometimes belongs in a skill (exercise 2).

**Files.** `.github/instructions/web.instructions.md` (new), `web/src/tiles.ts` and
`web/src/tiles.test.ts` (new), `web/src/App.test.tsx` (new), `web/src/Board.tsx`,
`web/src/Board.test.tsx`, `web/src/App.tsx`, `web/src/index.css`.

**Inline context.**
- `web/src/Board.tsx:11` renders every cell as `<div className="tile" role="gridcell">`. All
  tiles share one background, `.tile` in `web/src/index.css:42`.
- The header is in `web/src/App.tsx:57–63` and shows `score:` only. The move request is sent
  in the key handler at `App.tsx:46–48`.
- `web/eslint.config.js` enables `react-refresh`, so a component file that also exports a
  helper fails lint (`react-refresh/only-export-components`). A helper needs its own module,
  the way `keys.ts` sits next to `App.tsx`.
- There is no test for `App` yet. `Board.test.tsx` and `keys.test.ts` show the style: Testing
  Library queries by role, one behaviour per `it`.
- This counter lives in the client and counts every move the API accepted. The client cannot
  tell whether a move changed the board. Exercise 3 builds a counter on the server instead,
  starting again from a clean `main`.

**Starter prompt.**
> *"Read every file in `web/src/` and `web/eslint.config.js`, `web/.prettierrc.json` and
> `web/tsconfig.app.json`. Write `.github/instructions/web.instructions.md` with an `applyTo`
> that covers the `.ts`, `.tsx` and `.css` files under `web/src`. State only conventions the
> code already follows: exports, typing, components, where styles live, where HTTP calls live,
> where tests sit and how they query the DOM. Short imperative bullets, in the style of
> `.github/instructions/api.instructions.md`. Change no other file."*

**Walkthrough (full solution).**

1. **The starter prompt writes the instruction file.** *Mechanism: none yet. Copilot reads the
   code with the repository-wide `copilot-instructions.md` in context and writes a Markdown
   file.* The reference version:

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
- `web` only renders. It does not decide game rules; if the UI needs a new fact, the API returns it.
- Tests sit next to the source as `<name>.test.ts(x)` and use Vitest with Testing Library. Query by
  role or visible text (`getByRole('gridcell')`), never by class name or test id. Mock `./api`,
  not `fetch`.
- One behaviour per `it`, named as a sentence, Arrange-Act-Assert separated by blank lines.
- Prettier decides formatting: no semicolons, single quotes.
- Run `npm test` and `npm run lint` in `web/` after the change and report the pass and fail counts.
```

   Everything in it is visible in the code today, with one addition: "mock `./api`, not
   `fetch`". No test needed that rule so far; the `App` test below does.

2. **Check that the CLI sees the file.** In a shell, from the repository root:

```bash
copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
```

```text
["web/src/**/*.ts","web/src/**/*.tsx","web/src/**/*.css"]
```

   One comma-separated `applyTo` string becomes three globs. A running session does not pick
   up a new instruction file (per the docs): start a new one with `/new`, then `/instructions`
   lists the file and lets you toggle it.

3. **Follow-up prompt: build the feature.**
   > *"Colour the tiles by value and show a `moves: N` counter in the header. The counter
   > counts the moves the API accepted and goes back to 0 on New game. Web only: do not touch
   > `api/` or `engine/`. Add tests."*

   *Mechanism: the scoped instructions. Per the docs, the CLI delivers `web.instructions.md`
   when the agent reads or edits a file that matches `applyTo`, so the rules arrive exactly
   when Copilot opens `Board.tsx`. The `format.sh` hook runs Prettier on each web file Copilot
   edits, and the `run-tests.sh` hook runs Vitest when the turn ends.*

   The class name is derived in a helper module, `web/src/tiles.ts`:

```ts
const HIGHEST_STYLED_VALUE = 2048

/**
 * CSS classes for one cell. An empty cell keeps the base look; every value up to 2048 has
 * its own class in index.css, and anything above shares `tile-super`.
 */
export function tileClassName(value: number): string {
  if (value === 0) {
    return 'tile'
  }
  return value > HIGHEST_STYLED_VALUE ? 'tile tile-super' : `tile tile-${value}`
}
```

   `web/src/tiles.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { tileClassName } from './tiles'

describe('tileClassName', () => {
  it('gives an empty cell the base class only', () => {
    expect(tileClassName(0)).toBe('tile')
  })

  it('adds a class named after the tile value', () => {
    expect(tileClassName(64)).toBe('tile tile-64')
  })

  it('uses the shared class for a value above 2048', () => {
    expect(tileClassName(4096)).toBe('tile tile-super')
  })
})
```

   `web/src/Board.tsx` uses it:

```diff
--- a/web/src/Board.tsx
+++ b/web/src/Board.tsx
@@ -1,3 +1,5 @@
+import { tileClassName } from './tiles'
+
 interface BoardProps {
   grid: number[][]
 }
@@ -8,7 +10,11 @@ export function Board({ grid }: BoardProps) {
       {grid.map((row, rowIndex) => (
         <div className="board-row" role="row" key={rowIndex}>
           {row.map((value, colIndex) => (
-            <div className="tile" role="gridcell" key={colIndex}>
+            <div
+              className={tileClassName(value)}
+              role="gridcell"
+              key={colIndex}
+            >
               {value === 0 ? '' : value}
             </div>
           ))}
```

   One more case in `web/src/Board.test.tsx`. It finds the cell by role and only then looks
   at the class:

```diff
--- a/web/src/Board.test.tsx
+++ b/web/src/Board.test.tsx
@@ -27,4 +27,10 @@ describe('Board', () => {
 
     expect(screen.getAllByRole('gridcell')[1]).toBeEmptyDOMElement()
   })
+
+  it('colours a tile by its value', () => {
+    render(<Board grid={GRID} />)
+
+    expect(screen.getAllByRole('gridcell')[0]).toHaveClass('tile-2')
+  })
 })
```

   The colours are plain classes appended to `web/src/index.css`, after `.tile`:

```css
.tile-2 {
  background: #eee4da;
}

.tile-4 {
  background: #ede0c8;
}

.tile-8 {
  color: #f9f6f2;
  background: #f2b179;
}

.tile-16 {
  color: #f9f6f2;
  background: #f59563;
}

.tile-32 {
  color: #f9f6f2;
  background: #f67c5f;
}

.tile-64 {
  color: #f9f6f2;
  background: #f65e3b;
}

.tile-128 {
  color: #f9f6f2;
  background: #edcf72;
}

.tile-256 {
  color: #f9f6f2;
  background: #edcc61;
}

.tile-512 {
  color: #f9f6f2;
  background: #edc850;
}

.tile-1024 {
  color: #f9f6f2;
  background: #edc53f;
  font-size: 1.25rem;
}

.tile-2048 {
  color: #f9f6f2;
  background: #edc22e;
  font-size: 1.25rem;
}

.tile-super {
  color: #f9f6f2;
  background: #3c3a32;
  font-size: 1.25rem;
}
```

   The counter is one more piece of state in `web/src/App.tsx`:

```diff
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -17,11 +17,13 @@ function messageOf(error: unknown): string {
 export function App() {
   const [game, setGame] = useState<Game | null>(null)
   const [error, setError] = useState<string | null>(null)
+  const [moves, setMoves] = useState(0)
 
   const startGame = useCallback(() => {
     createGame()
       .then((created) => {
         setGame(created)
+        setMoves(0)
         setError(null)
       })
       .catch((cause: unknown) => setError(messageOf(cause)))
@@ -44,7 +46,10 @@ export function App() {
       // Arrow keys would otherwise scroll the page.
       event.preventDefault()
       move(game.id, direction)
-        .then(setGame)
+        .then((moved) => {
+          setGame(moved)
+          setMoves((count) => count + 1)
+        })
         .catch((cause: unknown) => setError(messageOf(cause)))
     }
 
@@ -57,6 +62,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="moves">moves: {moves}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` mocks the API module, as the instruction file asks:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App move counter', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4 })
  })

  it('starts at zero', async () => {
    render(<App />)

    await screen.findByRole('grid')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })

  it('counts a move the server accepted', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('moves: 1')).toBeInTheDocument()
  })

  it('does not count a move the server rejected', async () => {
    vi.mocked(move).mockRejectedValue(new Error('Game does not exist'))
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')
    await screen.findByRole('alert')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })

  it('goes back to zero when a new game starts', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')
    await user.keyboard('{ArrowLeft}')
    await screen.findByText('moves: 1')

    await user.click(screen.getByRole('button', { name: 'New game' }))

    expect(await screen.findByText('moves: 0')).toBeInTheDocument()
  })
})
```

4. **Follow-up prompt: hold the result against the rules.**
   > *"Go through `web.instructions.md` rule by rule and show me where your diff follows it.
   > Fix anything that does not."*

   What to look for in your own result: colours as an inline `style`, a class-name helper
   exported from `Board.tsx` (lint fails), a test that finds a tile with `querySelector`. If
   you find one of these although the file forbids it, check with `/instructions` that the
   file is loaded and enabled in this session.

5. **Follow-up prompt, only if the checks are not green yet.**
   > *"Run `npm test`, `npm run lint` and `npm run build` in `web/` and fix what fails. Report
   > the pass and fail counts."*

**Done check.**

```bash
copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
cd web && npm test && npm run lint && npm run build
```

- The first command prints the three `web/src` globs.
- Vitest: 0 failed. The reference solution ends at `Test Files  4 passed (4)` and
  `Tests  15 passed (15)` (7 existing + 8 new).
- ESLint prints no findings; the build ends with `✓ built in …`.
- By eye: start `./gradlew :api:bootRun` and, in a second terminal, `cd web && npm run dev`.
  At http://localhost:5173 a 2 and a 4 have different colours, and the header shows
  `moves: 0`, counts up with each arrow key and returns to 0 on **New game**.

## 2. Skill 🟢–🟡 — capture how an endpoint is added, then add one

**Layers:** engine · api

**Goal.** Write a project skill, `.github/skills/api-endpoint/SKILL.md`, that captures how an
endpoint is added in this API. Then use it to make the **win value configurable**: `Board`
takes a win value (default 2048), a game can be created with `{"winValue": 1024}`, and an
invalid value answers 400.

**Mechanism it teaches.** Authoring a [skill](02-skills.md): a `description` that triggers on
the right requests and a body that holds a procedure. `api.instructions.md` already holds the
API's rules and arrives with every `api/**/*.kt` file. The skill holds the *order of work* and
the shapes to copy, and loads only when a task calls for it. Compare with the existing
`board-tests` skill: same shape, different domain.

**Files.** `.github/skills/api-endpoint/SKILL.md` (new),
`engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`, `engine/.../BoardTest.kt`,
`api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`, `GameController.kt`,
`ApiExceptionHandler.kt`, `api/.../GameControllerTest.kt`, and one line in
`.github/skills/board-tests/SKILL.md`.

**Inline context.**
- The target tile is a constant: `const val WIN_VALUE = 2048` at `Board.kt:177`, read by
  `hasWon()` at `Board.kt:174`.
- `GameController.create()` (`GameController.kt:22–24`) takes no body.
- Which values are legal is a game rule, so it belongs to `engine`. The API only translates
  a refusal into an HTTP error (`.github/copilot-instructions.md`: "Game rules live in `engine`
  only").
- `ApiExceptionHandler.unreadableBody()` (`ApiExceptionHandler.kt:23–28`) answers every
  unparseable body with a message about `direction`. Once a second endpoint takes a body, that
  message is wrong for it.
- The web client never sends a win value, so `web/` stays untouched.

**Starter prompt.**
> *"Read `GameController.kt`, `GameService.kt`, `ApiExceptionHandler.kt` and
> `GameControllerTest.kt` in `api/`, and `.github/instructions/api.instructions.md`. Write a
> project skill at `.github/skills/api-endpoint/SKILL.md` that captures how an endpoint is
> added in this API: the order of work (rule in `engine` first, then the service method, an
> own exception, its handler, a thin controller, a `@WebMvcTest` test), the `ApiResponse` and
> `ErrorResponse` envelopes, the status codes and the Spring Boot 4 test idioms. Copy short
> real snippets from the code as shapes to follow. Write the `description` so that it says
> when to use the skill. Model the file on `.github/skills/board-tests/SKILL.md`. Change no
> Kotlin file."*

**Walkthrough (full solution).**

1. **The starter prompt writes the skill.** *Mechanism: none yet; Copilot documents what it
   reads.* The reference version of `.github/skills/api-endpoint/SKILL.md`:

````markdown
---
name: api-endpoint
description: Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
---

# Adding or changing an API endpoint

The API lives in `api/src/main/kotlin/com/quanti/g2048/api/`. It is Spring Boot 4 (Spring MVC,
Jackson 3). Work in this order; each step has one home.

## Order of work

1. **Rule first.** If the change needs a new game rule (which values are legal, what a move
   does), add it to `Board` in `engine/` with a deterministic test. The API asks the engine;
   it never decides a rule itself.
2. **Service method.** Add or extend a method on `GameService`. It takes plain values (`UUID`,
   an enum, an `Int`), never a request class, and returns `GameState`. Anything that changes a
   board runs inside `synchronized(board)`.
3. **Failure cases.** Each new way to fail gets its own exception class next to
   `GameNotFoundException` in `GameService.kt`. The service throws it; the controller does not
   validate.
4. **Handler.** One `@ExceptionHandler` per exception in `ApiExceptionHandler`, with
   `@ResponseStatus` and a stable `UPPER_SNAKE` code. Write the message by hand. Never pass
   `exception.message` of a framework exception to the client.
5. **Controller.** One function in `GameController` that maps HTTP to the service call and wraps
   the result: `ApiResponse(games.someMethod(...))`. A request body is a data class next to
   `MoveRequest`. An optional field is nullable with a `null` default; an optional body is
   `@RequestBody(required = false)`.
6. **Test.** Add cases to `GameControllerTest` (`@WebMvcTest(GameController::class)`,
   `@Import(GameService::class)`, `MockMvcTester`). One test for the success path and one per
   failure case. Assert on the status and on a JSON path, not on Kotlin objects.
   Tests live in `api/src/test/kotlin/com/quanti/g2048/api/<Controller>Test.kt`; create it if missing.
   Name each test as a plain-English sentence in backticks, one behaviour per test.
7. **Run** `./gradlew :api:test` (and `./gradlew :engine:test` if step 1 applied) and report the
   pass and fail counts.

## Contract

- URLs: resources under `/api/v1`, plural nouns, no verbs (`/games/{id}/moves`).
- Success body: `{ "data": ... }`. Error body: `{ "error": { "code": "...", "message": "..." } }`.
- Status: 201 for a create, 200 for a read or a move, 400 for input that cannot be parsed or is
  not allowed, 404 for an unknown game. Never 200 with an error inside, never 500 for bad input.
- A delete answers 204 with no body: `@ResponseStatus(HttpStatus.NO_CONTENT)`, no return value.
- A new field on `GameState` is additive. If the web client should show it, add it to the `Game`
  interface in `web/src/api.ts` in the same change.

## Shapes to copy

```kotlin
// GameService.kt
class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")

// ApiExceptionHandler.kt
@ExceptionHandler(GameNotFoundException::class)
@ResponseStatus(HttpStatus.NOT_FOUND)
fun gameNotFound(exception: GameNotFoundException): ErrorResponse =
    ErrorResponse(ErrorBody("GAME_NOT_FOUND", exception.message ?: "Game does not exist"))

// GameController.kt
@PostMapping("/{id}/moves")
fun move(
    @PathVariable id: UUID,
    @RequestBody request: MoveRequest,
): ApiResponse<GameState> = ApiResponse(games.move(id, request.direction))

// GameControllerTest.kt
@Test
fun `moving in an unknown game returns a structured 404`() {
    val result = mvc.post().uri("/api/v1/games/${UUID.randomUUID()}/moves")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""{"direction":"LEFT"}""")

    assertThat(result)
        .hasStatus(HttpStatus.NOT_FOUND)
        .bodyJson()
        .extractingPath("$.error.code")
        .isEqualTo("GAME_NOT_FOUND")
}
```

## Boot 4, not Boot 3

Use `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`, `MockMvcTester`,
`@MockitoBean` and `tools.jackson.*`. Do not write `@MockBean`, `com.fasterxml.jackson.*`
imports or `TestRestTemplate`.
````

   A `: ` (colon and space) inside an unquoted `description` is invalid YAML. Avoid it, as
   the reference does with ` - `, or quote the whole value.

2. **Check that the skill is loaded.** In a shell:

```bash
copilot skill list | grep '^  api-endpoint'
```

```text
  api-endpoint - Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
```

   The line appears under `Project skills:`. In a session that was already running when the
   file was written, run `/skills reload` first (per the docs).

3. **Follow-up prompt: build the feature without naming the skill.**
   > *"Make the win value configurable. `Board` takes a win value (default 2048) and owns the
   > rule for which values are legal. `POST /api/v1/games` accepts an optional body
   > `{"winValue": 1024}`; without a body the game plays to 2048. An illegal value answers 400
   > with a structured error. The game state reports the win value."*

   *Mechanism: the skill. The model matches the request against the `description` and loads
   the body through a tool call named `skill` with the argument `{"skill":"api-endpoint"}`;
   watch for it in the timeline. If it does not appear, repeat the prompt with `/api-endpoint`
   in it (per the docs) and then sharpen the `description`. The scoped instruction files for
   `engine/` and `api/` arrive on their own as Copilot opens the Kotlin files (per the docs).*

   Step 1 of the skill puts the rule into `Board.kt`:

```diff
--- a/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
@@ -52,11 +52,14 @@ fun slideLineLeft(line: IntArray): Int {
  *
  * Builds a board from an explicit grid, so the state is fully deterministic.
  * Use [Board.newGame] for a board seeded with two random tiles.
+ *
+ * [winValue] is the tile that wins the game. It must pass [Board.isValidWinValue].
  */
 class Board(
     grid: List<List<Int>>,
     score: Int = 0,
     private val random: Random = Random.Default,
+    val winValue: Int = DEFAULT_WIN_VALUE,
 ) {
     private val cells: Array<IntArray>
 
@@ -67,6 +70,9 @@ class Board(
         require(grid.size == SIZE && grid.all { it.size == SIZE }) {
             "Grid must be $SIZE x $SIZE"
         }
+        require(isValidWinValue(winValue)) {
+            "Win value must be a power of two between $MIN_WIN_VALUE and $MAX_WIN_VALUE"
+        }
         cells = Array(SIZE) { row -> IntArray(SIZE) { col -> grid[row][col] } }
     }
 
@@ -170,15 +176,25 @@ class Board(
         return true
     }
 
-    /** True once any tile reaches [WIN_VALUE]. */
-    fun hasWon(): Boolean = cells.any { row -> row.any { it >= WIN_VALUE } }
+    /** True once any tile reaches [winValue]. */
+    fun hasWon(): Boolean = cells.any { row -> row.any { it >= winValue } }
 
     companion object {
-        const val WIN_VALUE = 2048
+        const val DEFAULT_WIN_VALUE = 2048
+
+        /** Spawned tiles are 2 or 4, so anything lower would win the game on the first tile. */
+        const val MIN_WIN_VALUE = 8
+
+        /** The largest tile a 4 x 4 board can hold. */
+        const val MAX_WIN_VALUE = 131072
+
+        /** A win value is a tile the game can produce: a power of two within the bounds. */
+        fun isValidWinValue(value: Int): Boolean =
+            value in MIN_WIN_VALUE..MAX_WIN_VALUE && value.countOneBits() == 1
 
         /** Starts an empty board and seeds it with two random tiles. */
-        fun newGame(random: Random = Random.Default): Board {
-            val board = Board(List(SIZE) { List(SIZE) { 0 } }, random = random)
+        fun newGame(random: Random = Random.Default, winValue: Int = DEFAULT_WIN_VALUE): Board {
+            val board = Board(List(SIZE) { List(SIZE) { 0 } }, random = random, winValue = winValue)
             board.spawnRandom()
             board.spawnRandom()
             return board
```

   The lower bound is 8 because a spawned tile is 2 or 4. The upper bound is the largest tile
   a 4 × 4 board can hold. `WIN_VALUE` became `DEFAULT_WIN_VALUE`, so the one mention of it in
   `.github/skills/board-tests/SKILL.md` changes too:

````diff
--- a/.github/skills/board-tests/SKILL.md
+++ b/.github/skills/board-tests/SKILL.md
@@ -30,7 +30,7 @@ fun slideLineLeft(line: IntArray): Int          // mutates the line, returns sco
 Board(grid: List<List<Int>>, score: Int = 0)    // deterministic, for tests
 fun Board.move(direction: Direction): Boolean   // true if the board changed
 fun Board.isGameOver(): Boolean
-fun Board.hasWon(): Boolean                     // any tile >= Board.WIN_VALUE
+fun Board.hasWon(): Boolean                     // any tile >= board.winValue
 ```
 
 ## Running the tests
````

   Deterministic tests in `BoardTest.kt`:

```diff
--- a/engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
+++ b/engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
@@ -4,6 +4,7 @@ import org.junit.jupiter.api.Assertions.assertEquals
 import org.junit.jupiter.api.Assertions.assertFalse
 import org.junit.jupiter.api.Assertions.assertTrue
 import org.junit.jupiter.api.Test
+import org.junit.jupiter.api.assertThrows
 
 class BoardTest {
 
@@ -156,6 +157,63 @@ class BoardTest {
         assertTrue(board.hasWon())
     }
 
+    @Test
+    fun `hasWon triggers at a custom win value`() {
+        val board = Board(
+            listOf(
+                listOf(1024, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+            ),
+            winValue = 1024,
+        )
+
+        assertTrue(board.hasWon())
+    }
+
+    @Test
+    fun `a tile below a custom win value has not won`() {
+        val board = Board(
+            listOf(
+                listOf(2048, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+            ),
+            winValue = 4096,
+        )
+
+        assertFalse(board.hasWon())
+    }
+
+    @Test
+    fun `a power of two within the bounds is a valid win value`() {
+        assertTrue(Board.isValidWinValue(1024))
+    }
+
+    @Test
+    fun `a win value that is not a power of two is invalid`() {
+        assertFalse(Board.isValidWinValue(1000))
+    }
+
+    @Test
+    fun `a win value a spawned tile already reaches is invalid`() {
+        assertFalse(Board.isValidWinValue(4))
+    }
+
+    @Test
+    fun `a win value above the largest possible tile is invalid`() {
+        assertFalse(Board.isValidWinValue(262144))
+    }
+
+    @Test
+    fun `a board refuses an invalid win value`() {
+        val emptyGrid = List(SIZE) { List(SIZE) { 0 } }
+
+        assertThrows<IllegalArgumentException> { Board(emptyGrid, winValue = 1000) }
+    }
+
     @Test
     fun `a board with an empty cell is not game over`() {
         val board = boardOf(
```

   Steps 2 and 3: the service method and its own exception in `GameService.kt`. The service
   asks the engine; it does not repeat the rule:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
@@ -13,10 +13,13 @@ data class GameState(
     val grid: List<List<Int>>,
     val score: Int,
     val status: GameStatus,
+    val winValue: Int,
 )
 
 class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")
 
+class InvalidWinValueException(winValue: Int) : RuntimeException("Win value $winValue is not allowed")
+
 /**
  * Owns the running games. The rules themselves live in the engine module;
  * this class only decides what happens around a move.
@@ -26,9 +29,13 @@ class GameService {
     // Demo storage: games live in memory only and are lost on restart.
     private val boards = ConcurrentHashMap<UUID, Board>()
 
-    fun create(): GameState {
+    fun create(winValue: Int = Board.DEFAULT_WIN_VALUE): GameState {
+        // The engine owns the rule; the service only turns a refusal into an API error.
+        if (!Board.isValidWinValue(winValue)) {
+            throw InvalidWinValueException(winValue)
+        }
         val id = UUID.randomUUID()
-        val board = Board.newGame()
+        val board = Board.newGame(winValue = winValue)
         boards[id] = board
         return stateOf(id, board)
     }
@@ -56,6 +63,6 @@ class GameService {
             board.hasWon() -> GameStatus.WON
             else -> GameStatus.IN_PROGRESS
         }
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, board.winValue)
     }
 }
```

   Step 5: the controller stays a mapping, `GameController.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
@@ -1,5 +1,6 @@
 package com.quanti.g2048.api
 
+import com.quanti.g2048.engine.Board
 import com.quanti.g2048.engine.Direction
 import java.util.UUID
 import org.springframework.http.HttpStatus
@@ -15,13 +16,16 @@ data class ApiResponse<T>(val data: T)
 
 data class MoveRequest(val direction: Direction)
 
+data class CreateGameRequest(val winValue: Int? = null)
+
 @RestController
 @RequestMapping("/api/v1/games")
 class GameController(private val games: GameService) {
 
     @PostMapping
     @ResponseStatus(HttpStatus.CREATED)
-    fun create(): ApiResponse<GameState> = ApiResponse(games.create())
+    fun create(@RequestBody(required = false) request: CreateGameRequest?): ApiResponse<GameState> =
+        ApiResponse(games.create(request?.winValue ?: Board.DEFAULT_WIN_VALUE))
 
     @GetMapping("/{id}")
     fun find(@PathVariable id: UUID): ApiResponse<GameState> = ApiResponse(games.find(id))
```

4. **Follow-up prompt: the error path.**
   > *"Send `{"winValue": "high"}` to `POST /api/v1/games` in a test. Which error does the
   > client get? The message must be true for both endpoints that take a body. And an illegal
   > number needs its own error code."*

   *Mechanism: the skill again (step 4, one handler per exception, message written by hand)
   together with the rule from `api.instructions.md` that unparseable input answers 400.*
   `ApiExceptionHandler.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
@@ -1,5 +1,6 @@
 package com.quanti.g2048.api
 
+import com.quanti.g2048.engine.Board
 import org.springframework.http.HttpStatus
 import org.springframework.http.converter.HttpMessageNotReadableException
 import org.springframework.web.bind.annotation.ExceptionHandler
@@ -19,12 +20,26 @@ class ApiExceptionHandler {
     fun gameNotFound(exception: GameNotFoundException): ErrorResponse =
         ErrorResponse(ErrorBody("GAME_NOT_FOUND", exception.message ?: "Game does not exist"))
 
+    @ExceptionHandler(InvalidWinValueException::class)
+    @ResponseStatus(HttpStatus.BAD_REQUEST)
+    fun invalidWinValue(): ErrorResponse =
+        ErrorResponse(
+            ErrorBody(
+                "INVALID_WIN_VALUE",
+                "winValue must be a power of two between ${Board.MIN_WIN_VALUE} and ${Board.MAX_WIN_VALUE}",
+            ),
+        )
+
     // Fixed messages on purpose: the framework's own text leaks class names and parser details.
     @ExceptionHandler(HttpMessageNotReadableException::class)
     @ResponseStatus(HttpStatus.BAD_REQUEST)
     fun unreadableBody(): ErrorResponse =
         ErrorResponse(
-            ErrorBody("INVALID_REQUEST", "Body must be JSON with a direction of UP, DOWN, LEFT or RIGHT"),
+            ErrorBody(
+                "INVALID_REQUEST",
+                "Body must be valid JSON: a direction of UP, DOWN, LEFT or RIGHT for a move, " +
+                    "an integer winValue for a new game",
+            ),
         )
 
     @ExceptionHandler(MethodArgumentTypeMismatchException::class)
```

   Step 6: one test for the success path and one per failure, `GameControllerTest.kt`:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,62 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a game created without a body plays to 2048`() {
+        assertThat(mvc.post().uri("/api/v1/games"))
+            .bodyJson()
+            .extractingPath("$.data.winValue")
+            .isEqualTo(2048)
+    }
+
+    @Test
+    fun `a game created with a body that has no win value plays to 2048`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("{}")
+
+        assertThat(result).bodyJson().extractingPath("$.data.winValue").isEqualTo(2048)
+    }
+
+    @Test
+    fun `a game can be created with a win value of 1024`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":1024}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.CREATED)
+            .bodyJson()
+            .extractingPath("$.data.winValue")
+            .isEqualTo(1024)
+    }
+
+    @Test
+    fun `a win value that is not a power of two returns a structured 400`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":1000}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.BAD_REQUEST)
+            .bodyJson()
+            .extractingPath("$.error.code")
+            .isEqualTo("INVALID_WIN_VALUE")
+    }
+
+    @Test
+    fun `a win value that is not a number returns a structured 400`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":"high"}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.BAD_REQUEST)
+            .bodyJson()
+            .extractingPath("$.error.code")
+            .isEqualTo("INVALID_REQUEST")
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

5. **Follow-up prompt: review against the skill.**
   > *"Check your diff against the seven steps of the `api-endpoint` skill. Name the file and
   > line for each step, and list the tests you added with what each one proves."*

   If the skill was missing a step you needed (for example how to take an optional body),
   have Copilot add it to `SKILL.md` now. A skill is maintained like code.

**Done check.**

```bash
copilot skill list | grep -c '^  api-endpoint'     # 1
./gradlew build                                    # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
```

The reference solution reports `BoardTest` with `tests="20"` and `GameControllerTest` with
`tests="10"`, both `failures="0"`. Then against the running API (`./gradlew :api:bootRun` in a
second terminal):

```bash
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":1024}'
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":1000}'
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":"high"}'
curl -s -X POST localhost:8080/api/v1/games
```

```text
{"data":{"id":"ff27d284-a7e7-4bde-8955-eb9ee1f512c2","grid":[[0,0,0,0],[0,0,0,0],[0,2,0,0],[0,0,2,0]],"score":0,"status":"IN_PROGRESS","winValue":1024}}
{"error":{"code":"INVALID_WIN_VALUE","message":"winValue must be a power of two between 8 and 131072"}}
{"error":{"code":"INVALID_REQUEST","message":"Body must be valid JSON: a direction of UP, DOWN, LEFT or RIGHT for a move, an integer winValue for a new game"}}
{"data":{"id":"08254dd1-7d97-42f7-a47d-5f12d7e5ebb5","grid":[[0,0,0,0],[0,2,2,0],[0,0,0,0],[0,0,0,0]],"score":0,"status":"IN_PROGRESS","winValue":2048}}
```

Ids and grids differ on every run. The first and last answer with 201, the two in the middle
with 400. One edge the reference solution leaves open: Jackson reads `{"winValue": 1024.5}` as
1024 and the game is created. Closing it is a good extra prompt.

## 3. Hook 🟡 — make tests un-skippable, then add a gated feature

**Layers:** api · web

**Goal.** Change `.github/hooks/scripts/run-tests.sh` so that failing tests **stop the agent
from finishing**. Then build a small feature behind that gate: a **move counter kept by the
server**. `moves` is part of the game state, counts only moves that changed the board, and is
shown in the header.

**Mechanism it teaches.** A [hook](03-hooks.md) that enforces something on every turn, with no
model discretion. An instruction that says "run the tests" is a request; the hook is a fact.

**Files.** `.github/hooks/scripts/run-tests.sh` (changed; `hooks.json` stays as it is),
`api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`,
`api/.../GameServiceTest.kt` (new), `api/.../GameControllerTest.kt`, `web/src/api.ts`,
`web/src/App.tsx`, `web/src/App.test.tsx` (new).

**Inline context.**
- `.github/hooks/hooks.json:37–44` already registers `run-tests.sh` under `agentStop` with
  `timeoutSec: 300`. The script is *advisory*: on red it writes one line to stderr and exits
  with 2, which the CLI shows as a warning. The turn still ends.
- An `agentStop` hook cannot block with an exit code. It blocks by printing exactly one JSON
  object on stdout, `{"decision":"block","reason":"..."}`, and exiting 0. The agent goes back
  to work and receives `reason` as its next user message.
- The payload on stdin has `sessionId`, `timestamp`, `cwd`, `transcriptPath`, `stopReason` and
  `stop_hook_active`. The last one is `false` on a normal stop and `true` on the stop that
  follows a block. A gate that ignores it can loop; per the docs the CLI ends the turn anyway
  after 8 consecutive blocks.
- Hook processes start in the repository root, so the script can call `./gradlew` and
  `cd web` directly.
- `GameService.move` computes `val changed = board.move(direction)` at `GameService.kt:42` and
  never uses it. The service stores bare boards (`GameService.kt:27`), so there is no place
  for a per-game counter yet.
- `GameService.create()` starts from a random board. A test for "a move that changes nothing"
  needs a board it controls.

**Starter prompt.**
> *"Rewrite `.github/hooks/scripts/run-tests.sh` so that the `agentStop` hook blocks when tests
> fail. Keep what it tests now: Gradle when `engine/` or `api/` has uncommitted changes, Vitest
> when `web/src/` has. On failure print exactly one JSON object
> `{"decision":"block","reason":"..."}` on stdout and exit 0. Put the failing suites, the
> command to rerun them and the last 30 lines of the test output into `reason`. Read
> `stop_hook_active` from the JSON on stdin: when it is true, do not block again; write one
> line to stderr and exit 2. Do the same when `jq` is missing. Do not change `hooks.json`."*

**Walkthrough (full solution).**

1. **The starter prompt rewrites the script.** *Mechanism: none yet; this step builds it.*
   The reference `.github/hooks/scripts/run-tests.sh`:

```bash
#!/usr/bin/env bash
# agentStop hook: when Copilot finishes a turn, run the tests for the parts of
# the tree that have uncommitted changes. If they fail, send Copilot back to
# work once. If they still fail after that, let the turn end with a warning.
#
# An agentStop hook cannot block with an exit code: exit 2 is only a warning.
# It blocks by printing one JSON object, {"decision":"block","reason":"..."},
# and exiting 0. Copilot receives `reason` as its next prompt.
set -uo pipefail

input=$(cat)

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# agentStop fires after every turn, including plain questions. Only test what changed.
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
failed=""
output=""

if printf '%s\n' "$changed" | grep -Eq '^(engine|api)/'; then
    # Not --quiet: that would drop the line that names the failing test.
    if ! result=$(./gradlew test 2>&1); then
        failed="$failed gradle (./gradlew test)"
        output="$output$result"$'\n'
    fi
fi

if printf '%s\n' "$changed" | grep -Eq '^web/src/' && [ -d web/node_modules ]; then
    if ! result=$(cd web && npm test --silent 2>&1); then
        failed="$failed web (cd web && npm test)"
        output="$output$result"$'\n'
    fi
fi

[ -n "$failed" ] || exit 0

# stop_hook_active is true when a block already forced this turn to continue.
# Blocking again could loop until the CLI's own cap, so the second failure only
# warns. Without jq the payload cannot be read and the hook stays advisory.
already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$already_blocked" != "false" ]; then
    echo "run-tests hook: tests are failing in:$failed. Not sent back: this turn was already sent back once, or jq is missing." >&2
    exit 2
fi

# The end of the test output is where both runners name the failing test.
jq -cn --arg suites "$failed" --arg tail "$(printf '%s' "$output" | tail -n 30)" \
    '{decision: "block", reason: ("run-tests hook: tests are failing in:" + $suites + ". Find the cause, fix it, run the suite yourself and finish only when it passes. Do not weaken or delete a test to get there. End of the test output:\n" + $tail)}'
exit 0
```

   What changed against the advisory version: stdin is kept instead of drained, the test
   output is captured, Gradle runs without `--quiet` (with it the line naming the failed test
   is gone), and the ending is a decision instead of a fixed exit code. The gate blocks once
   per turn. That is deliberate: one forced round is enough for the agent to run the suite
   itself as often as it needs, and a workshop session cannot get stuck. For a stricter gate,
   delete the `stop_hook_active` branch and rely on the CLI's cap.

2. **Test the script without Copilot.** A hook is a program that reads JSON and prints JSON,
   so feed it by hand. From the repository root, with only the script changed:

```bash
payload() { printf '{"sessionId":"demo","cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }

# Nothing under engine/, api/ or web/src/ changed: no tests run, the turn may end.
payload false | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"
```

```text
exit=0
```

   Now make the tree red. This flips one expectation in a test (a throwaway edit, restored below):

```bash
perl -pi -e "s/toBe\('UP'\)/toBe('DOWN')/" web/src/keys.test.ts

# Red, first stop: the hook blocks.
payload false | ./.github/hooks/scripts/run-tests.sh | jq -r '.decision, .reason' | head -n 14
```

```text
block
run-tests hook: tests are failing in: web (cd web && npm test). Find the cause, fix it, run the suite yourself and finish only when it passes. Do not weaken or delete a test to get there. End of the test output:

 RUN  v5.1.1 /path/to/qti-copilot/web

 ❯ src/keys.test.ts (4 tests | 1 failed) 4ms
   ❯ toDirection (4)
     × maps a WASD key to its direction 2ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/keys.test.ts > toDirection > maps a WASD key to its direction
AssertionError: expected 'UP' to be 'DOWN' // Object.is equality

```

```bash
# Red, the stop after a block: no second block, a warning instead.
payload true | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"

git restore web/src/keys.test.ts
```

```text
run-tests hook: tests are failing in: web (cd web && npm test). Not sent back: this turn was already sent back once, or jq is missing.
exit=2
```

   This is real output from the reference script; only the repository path is shortened. With
   a failing Kotlin test the first line reads `tests are failing in: gradle (./gradlew test)`
   and the tail contains Gradle's `GameServiceTest > … FAILED` line.

3. **Watch the gate in a session.** `hooks.json` did not change and the CLI starts the script
   anew on every stop, so the running session already uses the new version. `/env` lists the
   loaded hooks. Give Copilot a task that breaks a test:
   > *"In `web/src/keys.ts`, make `toDirection` case-sensitive: an upper-case `W` must no
   > longer count as a move. Do not run the tests."*

   *Mechanism: the `agentStop` hook.* What you should observe:
   1. Copilot edits `keys.ts` and writes its closing answer.
   2. The prompt does not come back. The hook is running Vitest; that takes a few seconds.
   3. A new turn starts that you did not type. Its user message is the hook's `reason`:
      `run-tests hook: tests are failing in: web (cd web && npm test). …` followed by the
      tail of the test output, with `ignores the case of a WASD key` as the failing test.
   4. Copilot works on it. The request and the test contradict each other, and the `reason`
      forbids weakening the test, so it should either restore the old behaviour and tell you
      about the conflict, or ask you which of the two is right.
   5. When it stops again, the hook runs with `stop_hook_active: true`. Green: nothing is
      printed and the turn ends. Still red: you get the warning line from step 2 and the turn
      ends anyway.

   The sequence block → `reason` as the next user message → `stop_hook_active: true` was
   verified on CLI 1.0.114. The reference script itself was verified with the payloads in
   step 2, not inside a live session, so the wording Copilot uses will differ from this list.
   Before you continue: *"Put `keys.ts` back exactly as it was."*

4. **Follow-up prompt: the feature, behind the gate.**
   > *"The server should count moves. Add `moves` to the game state: 0 for a new game, plus one
   > for every move that changed the board; a move that changes nothing is not counted. Show it
   > in the web header as `moves: N`. I need a test that proves a no-op move is not counted.
   > `GameService.create()` starts from a random board, so give the service a way to start a
   > game on a board the test supplies, without exposing it over HTTP. Leave the tile spawn
   > as it is."*

   *Mechanism: the gate, silently. Every time Copilot believes it is done, the hook runs
   Gradle and Vitest for what changed. If Copilot stops while a test no longer compiles, it
   is sent back with the Kotlin compiler's `e: …GameServiceTest.kt:36:25 Unresolved reference`
   line in `reason` (checked with a deliberately broken test).*

   `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`, complete:

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import org.springframework.stereotype.Service

enum class GameStatus { IN_PROGRESS, WON, OVER }

data class GameState(
    val id: UUID,
    val grid: List<List<Int>>,
    val score: Int,
    val status: GameStatus,
    val moves: Int,
)

class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")

/** A running game: the board plus what the API tracks around it. */
private class Game(val board: Board) {
    var moves: Int = 0
}

/**
 * Owns the running games. The rules themselves live in the engine module;
 * this class only decides what happens around a move.
 */
@Service
class GameService {
    // Demo storage: games live in memory only and are lost on restart.
    private val games = ConcurrentHashMap<UUID, Game>()

    fun create(): GameState = start(Board.newGame())

    /** Starts a game on the given board. Tests use it to begin from a known position. */
    internal fun start(board: Board): GameState {
        val id = UUID.randomUUID()
        val game = Game(board)
        games[id] = game
        return stateOf(id, game)
    }

    fun find(id: UUID): GameState = stateOf(id, gameFor(id))

    fun move(id: UUID, direction: Direction): GameState {
        val game = gameFor(id)
        // Board is not thread-safe; two requests for the same game must not interleave.
        synchronized(game) {
            val changed = game.board.move(direction)
            if (changed) {
                game.moves++
            }

            // Place a new tile.
            game.board.spawnRandom()

            return stateOf(id, game)
        }
    }

    private fun gameFor(id: UUID): Game = games[id] ?: throw GameNotFoundException(id)

    private fun stateOf(id: UUID, game: Game): GameState {
        val board = game.board
        val status = when {
            board.isGameOver() -> GameStatus.OVER
            board.hasWon() -> GameStatus.WON
            else -> GameStatus.IN_PROGRESS
        }
        return GameState(id, board.grid, board.score, status, game.moves)
    }
}
```

   The service now stores a `Game` (board plus counter) instead of a bare board, and uses the
   `changed` flag for the first time. `start(board)` is the seam for tests: `internal`, so it
   is visible to the tests of this module and to nothing else. Exercise 5 solves the same
   problem differently, with a constructor parameter that supplies the board; both are
   valid, and since each exercise starts from a clean `main` they never meet. The spawn after
   a no-op move is still there; it belongs to exercise 5. If Copilot guards it with `if (changed)` anyway, the
   tests below still pass.

   `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (new, plain JUnit, no Spring):

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    private val games = GameService()

    /** One pair to merge: a move to the left changes this board. */
    private fun mergeableBoard(): Board = Board(
        listOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        ),
    )

    /** Full and without equal neighbours: no move changes this board. */
    private fun lockedBoard(): Board = Board(
        listOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        ),
    )

    @Test
    fun `a new game has made no moves`() {
        val game = games.create()

        assertThat(game.moves).isEqualTo(0)
    }

    @Test
    fun `a move that changes the board is counted`() {
        val game = games.start(mergeableBoard())

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.moves).isEqualTo(1)
    }

    @Test
    fun `a move that changes nothing is not counted`() {
        val game = games.start(lockedBoard())

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.moves).isEqualTo(0)
    }

    @Test
    fun `each game keeps its own count`() {
        val played = games.start(mergeableBoard())
        val untouched = games.start(mergeableBoard())

        games.move(played.id, Direction.LEFT)

        assertThat(games.find(untouched.id).moves).isEqualTo(0)
    }
}
```

   One case in `GameControllerTest.kt` pins the JSON field:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,14 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a new game reports zero moves`() {
+        assertThat(mvc.post().uri("/api/v1/games"))
+            .bodyJson()
+            .extractingPath("$.data.moves")
+            .isEqualTo(0)
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

5. **Follow-up prompt: the client.**
   > *"Show the counter in the header. The number comes from the server; the client does not
   > count. Test `App` with the API module mocked."*

   `web/src/api.ts` and `web/src/App.tsx`:

```diff
--- a/web/src/api.ts
+++ b/web/src/api.ts
@@ -7,6 +7,7 @@ export interface Game {
   grid: number[][]
   score: number
   status: GameStatus
+  moves: number
 }
 
 interface ApiResponse<T> {
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -57,6 +57,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="moves">moves: {game?.moves ?? 0}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` (new). The third case is the one that tells a server count from a
   client count:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
  moves: 0,
}

describe('App move counter', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
  })

  it('shows zero moves for a new game', async () => {
    render(<App />)

    expect(await screen.findByText('moves: 0')).toBeInTheDocument()
  })

  it('shows the move count the server reports', async () => {
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4, moves: 1 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('moves: 1')).toBeInTheDocument()
  })

  it('does not count a key press the server did not count', async () => {
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4, moves: 0 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')
    await screen.findByText('score: 4')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })
})
```

**Done check.**

```bash
# The gate, on your finished tree (green): prints nothing.
payload() { printf '{"sessionId":"demo","cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }
payload false | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"     # exit=0

./gradlew build                                                          # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

- The red and the already-blocked payloads from walkthrough step 2 give `block` and `exit=2`.
- The reference solution reports `BoardTest` 13, `GameControllerTest` 6 and `GameServiceTest`
  4 tests with `failures="0"`, and Vitest ends at `Tests  10 passed (10)`.
- Against the running API, `moves` counts up and a new game starts at 0 again. A real run of
  the reference solution (create, then eight moves that all changed the board, then a new
  game), filtered with `jq -c '.data | {score, moves}'`:

```text
{"score":0,"moves":1}
{"score":4,"moves":2}
{"score":4,"moves":3}
{"score":8,"moves":4}
{"score":8,"moves":5}
{"score":8,"moves":6}
{"score":20,"moves":7}
{"score":20,"moves":8}
{"score":0,"moves":0}
```

- In a session, a task that breaks a test is sent back once (walkthrough step 3).
- The gate works in the CLI. Per the docs, `agentStop` is not among the hook events the
  IntelliJ plugin publishes, so do not expect it there.

## 4. MCP 🟡 — implement a feature straight from a GitHub issue

**Layers:** api · web

**Goal.** The facilitator files an issue, "Show the best score", in the workshop repository.
You have Copilot **read the issue through the built-in GitHub MCP server** and implement it:
the server keeps the best score seen across games (in memory) and returns it, and the header
shows `best: N`. Then open a pull request with `/pr create`.

**Mechanism it teaches.** [MCP](04-mcp.md) as the way an agent reaches a system outside the
working tree. Nothing is installed and no `.mcp.json` is written: the CLI starts its own
GitHub server, `github-mcp-server`, when you are signed in. You only choose which of its tools
the model gets. At 2N that server and the approved Jira server are the realistic sources of a
specification, so this is the workflow to practise: the issue is the spec, the agent reads it
itself, you review the result against it.

**Prerequisites.**
- The organisation's Copilot policy "MCP servers in Copilot" is on. Per the docs, since CLI
  1.0.112 the built-in server does not start when that policy disables MCP. It is exempt from
  MCP allow-lists, so no registry entry is needed.
- You are signed in to Copilot with an account that has **read access** to the workshop
  repository (and has authorised SSO for the organisation, if it enforces it), and your clone
  has its GitHub remote.
- **Start the session with the issue tools named.** Which tools the built-in server exposes
  depends on whether `gh` is on your `PATH`. Tested on CLI 1.0.114: with `gh` installed, which
  is the case on most developer machines, it exposes 6 tools and none of them reads issues;
  without `gh` it exposes 24, including `list_issues` and `issue_read`. So name the two tools
  yourself. `--add-github-mcp-tool` replaces the default subset with exactly what you list:

  ```bash
  scripts/copilot-ws.sh --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
  ```

  The launcher hands these flags to `copilot` unchanged. In the session,
  `/mcp get github-mcp-server` shows the two tools. Both only read. The tool lists per setup
  and the other ways to widen the set are in
  [the MCP guide](04-mcp.md#the-built-in-github-mcp-server).
- `/pr create` needs **push access** and a branch. If you only have read access, stop after
  the commit and let the facilitator show the pull request.

Tested for the MCP guide on CLI 1.0.114: the tool counts, the flag, and a `list_issues` call
in `-p` mode against a public repository, which ran with no allow rule. Reading *this*
repository's issues was not tested, because it had no GitHub remote when the catalog was
written.

**Fallback when the built-in server is unavailable** (policy off, `github-mcp-server` missing
from `/mcp list`, no access to the repository): paste the issue text below into the prompt in
place of the issue number. Everything after the first step is the same. Say so in the pull
request.

**The issue (facilitator: file this once in the workshop repository).**

Title: `Show the best score`

```markdown
As a player I want to see the best score reached so far, so that I have something to beat.

## Acceptance criteria

- [ ] The API remembers the highest score any game has reached since the server started.
      In memory is enough; it is lost on restart, like the games.
- [ ] Every game state the API returns (create, find, move) carries it as `bestScore`.
- [ ] A new game reports the best score of earlier games, not 0.
- [ ] A later game with a lower score does not lower it.
- [ ] The web header shows `best: N` next to the score.
- [ ] Tests cover each point above.

## Out of scope

Persistence across restarts. Per-player scores.
```

**Files.** `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`,
`api/.../GameServiceTest.kt` (new), `api/.../GameControllerTest.kt`, `web/src/api.ts`,
`web/src/App.tsx`, `web/src/App.test.tsx` (new). No MCP configuration file.

**Inline context.**
- `GameService` is a singleton that holds all games in a map (`GameService.kt:27`). A value
  shared by all games fits next to that map.
- `GameControllerTest` runs all its tests against one Spring context, so against one
  `GameService`. A best score is shared state: asserting an exact value there would make the
  tests depend on their order. Exact values are tested on a fresh `GameService()` per test.
- `GameService.create()` starts from a random board, so a test that needs a known score needs
  a board it controls (the same seam as in exercise 3).
- `.github/copilot-instructions.md` says `web` only renders. The client shows the number the
  server sends; it does not compute a maximum itself.

**Starter prompt.** Start the session with the two flags from the prerequisites. Replace
`<N>` with the issue number the facilitator announces.
> *"Read issue #<N> of this repository with the issue_read tool of the GitHub MCP server.
> Repeat its acceptance criteria as a numbered list, then name the files you would change for
> each one. Do not edit anything yet."*

**Walkthrough (full solution).**

1. **The starter prompt reads the issue.** *Mechanism: the built-in GitHub MCP server. The
   timeline shows a call to `github-mcp-server-issue_read` (the model sees every MCP tool with
   the server name as prefix), followed by local file reads.* If Copilot answers that it has
   no tool for issues, or reaches for `gh issue view` in the shell, the session was started
   without the two flags: exit and start it again. Check that the list Copilot repeats
   matches the issue. It is the spec for everything that follows.

2. **Follow-up prompt: implement it.**
   > *"Implement the issue. Keep the best score in `GameService`, in memory. Test it on the
   > service directly with a fresh `GameService()` per test, because the best score is shared
   > by all games; give the service a way to start a game on a board the test supplies. Add
   > one controller test for the JSON field. Then the web client, with `App` tested against a
   > mocked API module."*

   *Mechanism: ordinary agent work under the repository's instructions and hooks. MCP
   delivered the specification; it plays no part in the edit.*

   `GameService.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
@@ -4,6 +4,7 @@ import com.quanti.g2048.engine.Board
 import com.quanti.g2048.engine.Direction
 import java.util.UUID
 import java.util.concurrent.ConcurrentHashMap
+import java.util.concurrent.atomic.AtomicInteger
 import org.springframework.stereotype.Service
 
 enum class GameStatus { IN_PROGRESS, WON, OVER }
@@ -13,6 +14,7 @@ data class GameState(
     val grid: List<List<Int>>,
     val score: Int,
     val status: GameStatus,
+    val bestScore: Int,
 )
 
 class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")
@@ -26,9 +28,14 @@ class GameService {
     // Demo storage: games live in memory only and are lost on restart.
     private val boards = ConcurrentHashMap<UUID, Board>()
 
-    fun create(): GameState {
+    // Highest score any game has reached since the server started. Lost on restart, like the games.
+    private val bestScore = AtomicInteger(0)
+
+    fun create(): GameState = start(Board.newGame())
+
+    /** Starts a game on the given board. Tests use it to begin from a known position. */
+    internal fun start(board: Board): GameState {
         val id = UUID.randomUUID()
-        val board = Board.newGame()
         boards[id] = board
         return stateOf(id, board)
     }
@@ -44,6 +51,7 @@ class GameService {
             // Place a new tile.
             board.spawnRandom()
 
+            bestScore.updateAndGet { best -> maxOf(best, board.score) }
             return stateOf(id, board)
         }
     }
@@ -56,6 +64,6 @@ class GameService {
             board.hasWon() -> GameStatus.WON
             else -> GameStatus.IN_PROGRESS
         }
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, bestScore.get())
     }
 }
```

   `AtomicInteger` because two games can move at the same time; the `synchronized` block only
   guards one board. `start(board)` is `internal`: visible to this module's tests, not to
   HTTP.

   `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (new, plain JUnit). JUnit
   creates a new instance of the class for every test, so each one gets its own service:

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    // A fresh service per test: the best score is shared by every game of one service.
    private val games = GameService()

    /** A board whose only move to the left merges one pair and scores twice the tile value. */
    private fun boardWithPairOf(tile: Int): Board = Board(
        listOf(
            listOf(tile, tile, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        ),
    )

    @Test
    fun `the best score starts at zero`() {
        val game = games.create()

        assertThat(game.bestScore).isEqualTo(0)
    }

    @Test
    fun `a move that beats the best score raises it`() {
        val game = games.start(boardWithPairOf(2))

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.bestScore).isEqualTo(4)
    }

    @Test
    fun `a new game reports the best score of an earlier game`() {
        val earlier = games.start(boardWithPairOf(2))
        games.move(earlier.id, Direction.LEFT)

        val later = games.create()

        assertThat(later.bestScore).isEqualTo(4)
    }

    @Test
    fun `a lower score in a later game does not lower the best score`() {
        val earlier = games.start(boardWithPairOf(4))
        games.move(earlier.id, Direction.LEFT)
        val later = games.start(boardWithPairOf(2))

        val moved = games.move(later.id, Direction.LEFT)

        assertThat(moved.bestScore).isEqualTo(8)
    }
}
```

   `GameControllerTest.kt` only pins that the field is in the JSON:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,11 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a game state carries the best score`() {
+        assertThat(mvc.post().uri("/api/v1/games")).bodyJson().hasPath("$.data.bestScore")
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

   `web/src/api.ts` and `web/src/App.tsx`:

```diff
--- a/web/src/api.ts
+++ b/web/src/api.ts
@@ -7,6 +7,7 @@ export interface Game {
   grid: number[][]
   score: number
   status: GameStatus
+  bestScore: number
 }
 
 interface ApiResponse<T> {
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -57,6 +57,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="best">best: {game?.bestScore ?? 0}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` (new):

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
  bestScore: 128,
}

describe('App best score', () => {
  it('shows the best score a new game reports', async () => {
    vi.mocked(createGame).mockResolvedValue(GAME)

    render(<App />)

    expect(await screen.findByText('best: 128')).toBeInTheDocument()
  })

  it('shows the new best score after a move that beats it', async () => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 256, bestScore: 256 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('best: 256')).toBeInTheDocument()
  })
})
```

3. **Follow-up prompt: review against the issue.**
   > *"Read issue #<N> again. Go through its acceptance criteria one by one and name the test
   > that proves each. If one has no test, write it."*

   *Mechanism: MCP again, as the reviewer's source of truth.* In the reference solution:
   criteria 1–4 are the four cases of `GameServiceTest`, the JSON field is
   `a game state carries the best score`, and the header is the two cases of `App.test.tsx`.

4. **Follow-up prompts: commit and open the pull request.**
   > *"Commit this on the current branch. Reference issue #<N> in the message."*

   Then type `/pr create`. *Mechanism: the CLI's own pull request command, not an MCP write
   tool; the two read tools are enough. Per the docs it works on the current branch of a
   repository hosted on GitHub and opens the pull request with you as author; per the
   changelog, plan mode blocks it. Not tested in this repo.* Read the description Copilot
   wrote before you approve it, and make sure it says `Closes #<N>`.

**Done check.**

```bash
./gradlew build                                        # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

- The reference solution reports `BoardTest` 13, `GameControllerTest` 6 and `GameServiceTest`
  4 tests with `failures="0"`; Vitest ends at `Tests  9 passed (9)`; ESLint prints no findings.
- Against the running API the best score survives a new game. A real run of the reference
  solution (create, eight moves, then a new game), filtered with
  `jq -c '.data | {score, bestScore}'`:

```text
{"score":0,"bestScore":0}
{"score":0,"bestScore":0}
{"score":4,"bestScore":4}
{"score":12,"bestScore":12}
{"score":12,"bestScore":12}
{"score":20,"bestScore":20}
{"score":20,"bestScore":20}
{"score":24,"bestScore":24}
{"score":0,"bestScore":24}
```

- The session timeline contains the `github-mcp-server-issue_read` call that fetched the
  issue, or the pull request says that the issue text was pasted (fallback).
- `/pr view` shows a pull request for your branch that references the issue (per the docs).

## 5. Custom agents 🟡 — delegate an undo feature across the three agents

**Layers:** engine · api · web

**Goal.** Build **undo** in all three layers and hand each part of the job to the agent
that fits it ([Example 5](05-agents.md), [Example 6](06-plugins.md)):

- `2048-dev:game-explorer` (plugin agent, read and search only) traces where the change goes.
- `board-test-writer` (project agent, edits and runs Gradle) writes the engine tests first.
- The **main session** implements.
- `kotlin-reviewer` (project agent, no edit tool) reviews the diff.

The contract: `Board.undo()` takes back the last move that changed the board and restores
the grid and the score. On a fresh game it changes nothing and returns `false`. The API gets
`POST /api/v1/games/{id}/undo`. The web UI undoes on the `u` key and has an **Undo** button.

As a warm-up, fix two of the three deliberate bugs, each with a test written before the fix.
Undo depends on both: a move that changes nothing must not count as a turn, and "game over"
must mean that no move is left.

**Mechanism it teaches.** [Custom agents](05-agents.md) as a team. When you name an agent in
a prompt, the main agent calls the `task` tool with `agent_type` set to that agent. The agent
works in its own context with its own tool list and reports back when it is done. Two things
follow. The file reads of the exploration and the output of the test run stay out of the
main session's context. And the tool list, not the prompt, decides what an agent can do: the
explorer and the reviewer cannot edit a file, the test writer can.

**Files.**

- `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt` — `isGameOver()` fix, history, `undo()`
- `engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` — 9 new tests
- `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt` — board factory, spawn guard, `undo()`
- `api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` — the endpoint
- `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (new), `GameControllerTest.kt`
- `web/src/api.ts`, `web/src/keys.ts`, `web/src/App.tsx`
- `web/src/keys.test.ts`, `web/src/App.test.tsx` (new)

**Inline context.**

- **Bug A, `Board.isGameOver()`** (`Board.kt`, lines 160–171) returns `true` as soon as it
  finds no empty cell. It never compares neighbours, so a full board that still has a
  mergeable pair is reported as over. The missing test is the TODO at the end of
  `BoardTest.kt` (lines 183–185).
- **Bug B, `GameService.move`** (`GameService.kt`, lines 38–49) assigns
  `val changed = board.move(direction)` on line 42 and calls `board.spawnRandom()` on line 45
  regardless. A move that slides nothing still spawns a tile. There is no `GameServiceTest`,
  and `create()` starts every game with `Board.newGame()` (line 31), which places two random
  tiles. A test for this bug needs a known board, and today the service cannot be given one.
- **The path undo has to follow** is the move path:
  `App.onKeyDown → toDirection() → api.move() → GameController.move() → GameService.move() → Board.move() → Board.spawnRandom()`.
  `Board.move` already copies the grid into `before` (line 83) to compute its return value.
  That copy is the snapshot undo needs.
- **A trap in the web layer:** `App.tsx` does not attach its key listener at all when
  `game.status === 'OVER'` (line 35). That is exactly when undo is most useful.

Start the session with `scripts/copilot-ws.sh`. It pre-approves `./gradlew`, `npm test` and
`npm run`, which the test writer and the done check need. `kotlin-reviewer` reads the change
with `git status` and `git diff`; approve those when it asks.

**Starter prompt — bug A (`isGameOver`).**
> *"Use the board-test-writer agent: turn the TODO at the end of
> `engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` into a test for a full board
> that still contains two equal neighbours, and assert that `isGameOver()` returns false.
> Run the engine tests and report the result. Do not change `Board.kt`."*

**Starter prompt — bug B (the ignored `changed` flag).**
> *"`GameService.move` in `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt` computes
> `changed` and ignores it, so a move that slides nothing still spawns a tile. Write the
> failing test first, in a new `GameServiceTest.kt`: a move that changes nothing leaves the
> grid unchanged. The test must not depend on random tiles. Give `GameService` a constructor
> parameter `newBoard: () -> Board` that defaults to `{ Board.newGame() }`, and start the
> test game from a board that cannot move left. Run `./gradlew :api:test` and show me the
> failure before you fix anything."*

**Starter prompt — undo.**
> *"Use the 2048-dev:game-explorer agent: we want an undo feature. The engine keeps a history
> so the last move can be taken back (grid and score), the API gets
> `POST /api/v1/games/{id}/undo`, and the web UI undoes on the `u` key and with an Undo
> button. Trace how a move travels from the key press to `Board.move` and back to the screen,
> then name every function that has to change or be added for undo, layer by layer. Do not
> modify any file."*

**Walkthrough (full solution).**

> **What was run for this catalog.** The code below was built and tested in a clean worktree
> of this repository. Two of the delegation steps were also run against Copilot CLI 1.0.114
> and are quoted: the `2048-dev:game-explorer` trace (step 1) and the `kotlin-reviewer` review
> of the finished diff (step 6). The prompts for `board-test-writer` and for the
> implementation were not replayed; treat them as a script, not as a recording.

*Warm-up A — `isGameOver()`. Mechanism: `board-test-writer`, then the main session.*

The starter prompt asks the agent for the test only. This is the test (`BoardTest.kt`,
replacing the TODO):

```kotlin
    @Test
    fun `a full board with a mergeable pair is not game over`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 2, 4),
        )

        assertFalse(board.isGameOver())
    }
```

The last row has two 2s side by side. `./gradlew :engine:test` fails, which is the point:

```text
BoardTest > a full board with a mergeable pair is not game over() FAILED
    org.opentest4j.AssertionFailedError at BoardTest.kt:192
14 tests completed, 1 failed
```

`board-test-writer` is instructed to keep a correct assertion and report the bug instead of
bending the test. Now let the main session fix the rule:

> *"The new test fails because `Board.isGameOver()` only looks for an empty cell. Fix it in
> `Board.kt`: a full board with two equal neighbours, side by side or one above the other, is
> not game over. Run `./gradlew :engine:test` and report the counts."*

```kotlin
    /** True when no move is possible: the board is full and no two neighbours are equal. */
    fun isGameOver(): Boolean {
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                val value = cells[row][col]
                if (value == 0) {
                    return false
                }
                // Looking right and down covers every neighbouring pair exactly once.
                if (col + 1 < SIZE && cells[row][col + 1] == value) {
                    return false
                }
                if (row + 1 < SIZE && cells[row + 1][col] == value) {
                    return false
                }
            }
        }
        return true
    }
```

One pass is enough. Each cell is compared with its right and its lower neighbour, so every
pair is seen once. An empty neighbour never equals a non-zero value, and the loop returns
`false` when it reaches the empty cell itself.

*Warm-up B — the `changed` flag. Mechanism: the main session.*

This one is service logic, so `board-test-writer` is the wrong agent: its instructions keep
it on `Board`. The difficulty is the test, not the fix. `GameService.create()` builds a random
board, and a test that hopes for a no-op move on random tiles is not a test.

The way out is a seam: the service receives the function that creates a board. Production
keeps the default. A test passes a function that returns a board it chose
(`GameService.kt`):

```kotlin
@Service
class GameService(
    // Tests pass a factory that returns a known board. Spring finds no bean of this type and,
    // because the parameter has a default, falls back to a random new game.
    private val newBoard: () -> Board = { Board.newGame() },
) {
    // Demo storage: games live in memory only and are lost on restart.
    private val boards = ConcurrentHashMap<UUID, Board>()

    fun create(): GameState {
        val id = UUID.randomUUID()
        val board = newBoard()
        boards[id] = board
        return stateOf(id, board)
    }
```

Spring still constructs the service without help. It looks for a bean of type
`() -> Board`, finds none, and because the Kotlin parameter has a default value it uses the
default. Verified here two ways: the existing `@WebMvcTest` with `@Import(GameService::class)`
still passes, and `./gradlew :api:bootRun` starts and serves games.

Now the test. The board is chosen so that the outcome does not depend on chance in either
direction (`GameServiceTest.kt`, new file; three more tests are added to it in step 4):

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    /** A service whose every new game starts from the given rows instead of two random tiles. */
    private fun serviceStartingWith(vararg rows: List<Int>): GameService = GameService { Board(rows.toList()) }

    @Test
    fun `a move that changes nothing leaves the grid unchanged`() {
        // Both rows are packed to the left with no equal neighbours, so LEFT cannot move a tile.
        val games = serviceStartingWith(
            listOf(2, 4, 0, 0),
            listOf(4, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val moved = games.move(created.id, Direction.LEFT)

        assertThat(moved.grid).isEqualTo(created.grid)
    }

    @Test
    fun `a move that changes the board spawns one tile`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val moved = games.move(created.id, Direction.LEFT)

        // The merged 4 plus the spawned tile; where the new tile lands is random, its existence is not.
        assertThat(moved.grid.flatten().count { it != 0 }).isEqualTo(2)
    }
```

Close the class with `}`; step 4 adds three more tests before it.

Why this is deterministic: both non-empty rows are already packed to the left and hold no
equal neighbours, so `LEFT` cannot move anything. With the bug, `spawnRandom()` runs, the
board has 12 empty cells, so a tile always appears and the grids always differ. With the fix,
nothing runs and the grids are always equal. Where the tile would land is random; whether the
test passes is not. The second test guards the other side of the fix: a real move must still
spawn exactly one tile.

Before the fix, `./gradlew :api:test` reports:

```text
GameServiceTest > a move that changes nothing leaves the grid unchanged() FAILED
    org.opentest4j.AssertionFailedError at GameServiceTest.kt:26
7 tests completed, 1 failed
```

> *"Now fix `GameService.move`: spawn a tile only when the move changed the board. Run
> `./gradlew :api:test` and report the counts."*

```kotlin
    fun move(id: UUID, direction: Direction): GameState {
        val board = boardFor(id)
        // Board is not thread-safe; two requests for the same game must not interleave.
        synchronized(board) {
            val changed = board.move(direction)

            // A move that slides nothing is not a turn, so it earns no new tile.
            if (changed) {
                board.spawnRandom()
            }

            return stateOf(id, board)
        }
    }
```

*Now the undo feature.*

1. **Trace it.** *Mechanism: `2048-dev:game-explorer`.* Paste the undo starter prompt. Run
   for this catalog (as `copilot --agent 2048-dev:game-explorer -p "..."`), the agent used
   only `glob`, `rg` and `view`, returned a 14-step trace from `main.tsx:11` to `Board.tsx`,
   and then a list per layer. The parts that matter:

   - Engine: add private history to `Board`; in `Board.move()` snapshot grid and score before
     the move and push the snapshot only when the move changes the board; add
     `Board.undo(): Boolean`. `slideLineLeft()` needs no change.
   - API: add `GameService.undo(id)` inside the same `synchronized(board)` as `move`, and
     `@PostMapping("/{id}/undo")` in `GameController`.
   - Web: add `undo(gameId)` to `api.ts`, recognise `u` in `onKeyDown`, add the button, and
     keep undo usable after `OVER`.

   It also proposed two things the contract does not ask for: a `canUndo` field on the game
   state, and a 409 with a `NO_UNDO_HISTORY` code when there is nothing to undo. The explorer
   maps; you decide. This solution leaves `canUndo` out and answers 200 with the unchanged
   game, because "nothing to undo" is a no-op in the contract, the client gets the current
   state either way, and the UI then needs no special case.

2. **Tests first.** *Mechanism: `board-test-writer`.*

   > *"Use the board-test-writer agent: write the tests for a new `Board.undo(): Boolean`
   > in `BoardTest.kt`, before the function exists. Behaviours: undo restores the grid from
   > before the last move; it restores the score; it returns true when it reverted a move;
   > on a fresh board it returns false and leaves the grid unchanged; a move that changes
   > nothing cannot be undone; undo also removes a tile spawned after the move; each undo
   > reverts exactly one move. One behaviour per test. Do not touch `Board.kt` and do not add
   > a stub: report the compile error instead."*

   In Kotlin, "red" for a missing function is a compile error, not a failing assertion:
   `Unresolved reference 'undo' on receiver of type 'Board'`. Until step 3 is done, the
   repo's `agentStop` hook also reports `run-tests hook: tests are failing in: gradle` after
   each turn. The hook is advisory, and that is the expected state.

   The tests, appended to `BoardTest.kt`:

```kotlin
    // -----------------------------------------------------------------------
    // Undo.
    // -----------------------------------------------------------------------

    @Test
    fun `undo restores the grid from before the last move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)

        board.undo()

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `undo restores the score from before the last move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT) // +4

        board.undo()

        assertEquals(0, board.score)
    }

    @Test
    fun `undo reports true when it reverted a move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)

        assertTrue(board.undo())
    }

    @Test
    fun `undo on a fresh board reports false`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        assertFalse(board.undo())
    }

    @Test
    fun `undo on a fresh board leaves the grid unchanged`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        board.undo()

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `a move that changes nothing cannot be undone`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )
        board.move(Direction.LEFT)

        assertFalse(board.undo())
    }

    @Test
    fun `undo also removes the tile spawned after the move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)
        board.spawnRandom()

        board.undo()

        // Wherever the tile landed, the grid from before the move has no trace of it.
        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `each undo reverts exactly one move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)
        board.move(Direction.DOWN)

        board.undo()

        assertEquals(
            listOf(
                listOf(4, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }
```

   Read the test with `spawnRandom()` closely. It calls a random function and is still
   deterministic: wherever the tile lands, the snapshot from before the move does not
   contain it.

3. **Implement the engine.** *Mechanism: the main session.*

   > *"Make the undo tests in `BoardTest.kt` pass. In `Board.kt`, keep a private history of
   > snapshots (grid and score). `move()` records the state from before the move, and only
   > when the move changed the board. `undo()` restores the latest snapshot and returns
   > false when there is none. No I/O, no new use of `Random`. Run `./gradlew :engine:test`
   > and report the counts."*

   The change to `Board.kt`, on top of warm-up A:

```diff
--- a/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
@@ -61,4 +61,7 @@
     private val cells: Array<IntArray>
 
+    // One entry per move that changed the board: the grid and score from just before it.
+    private val history = ArrayDeque<Snapshot>()
+
     var score: Int = score
         private set
@@ -82,4 +85,5 @@
     fun move(direction: Direction): Boolean {
         val before = grid
+        val scoreBefore = score
         var gained = 0
 
@@ -133,5 +137,25 @@
 
         score += gained
-        return grid != before
+        val changed = grid != before
+        if (changed) {
+            history.addLast(Snapshot(before, scoreBefore))
+        }
+        return changed
+    }
+
+    /**
+     * Takes back the last move that changed the board: the grid and the score return to
+     * what they were just before it, so a tile spawned after that move disappears too.
+     * Returns false, and changes nothing, when there is no move to take back.
+     */
+    fun undo(): Boolean {
+        val previous = history.removeLastOrNull() ?: return false
+        for (row in 0 until SIZE) {
+            for (col in 0 until SIZE) {
+                cells[row][col] = previous.grid[row][col]
+            }
+        }
+        score = previous.score
+        return true
     }
 
@@ -181,4 +205,6 @@
     fun hasWon(): Boolean = cells.any { row -> row.any { it >= WIN_VALUE } }
 
+    private class Snapshot(val grid: List<List<Int>>, val score: Int)
+
     companion object {
         const val WIN_VALUE = 2048
```

   Why it has this shape. The snapshot is taken **before** the move, so it also predates the
   `spawnRandom()` that `GameService` calls afterwards; one undo removes the merge and the
   spawned tile together. A move that changes nothing pushes nothing, so undo never "takes
   back" a move that did not happen. The history is a stack: every undo pops one move, and
   the stack is unbounded, which is fine for a demo that already keeps every game in memory
   (a cap is an easy extension, see exercise 6).

4. **The API.** *Mechanism: the main session.*

   > *"Add undo to the API, tests first. In `GameServiceTest.kt`: undo restores the grid and
   > the score from before the last move, and undo on a fresh game returns the game
   > unchanged. In `GameControllerTest.kt`: `POST /api/v1/games/{id}/undo` answers 200 with
   > the usual envelope, and an unknown game answers the structured 404. Then add
   > `GameService.undo(id)` and the controller method. Nothing to undo is not an error. Run
   > `./gradlew :api:test`."*

   Service behaviour, appended to `GameServiceTest.kt`:

```kotlin
    @Test
    fun `undo restores the grid from before the last move`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()
        games.move(created.id, Direction.LEFT)

        val undone = games.undo(created.id)

        assertThat(undone.grid).isEqualTo(created.grid)
    }

    @Test
    fun `undo restores the score from before the last move`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()
        games.move(created.id, Direction.LEFT) // +4

        val undone = games.undo(created.id)

        assertThat(undone.score).isEqualTo(0)
    }

    @Test
    fun `undo on a fresh game returns the game unchanged`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val undone = games.undo(created.id)

        assertThat(undone).isEqualTo(created)
    }
```

   HTTP mapping, appended to `GameControllerTest.kt`:

```kotlin
    @Test
    fun `undo on a fresh game returns the game with its four rows`() {
        val id = createGameId()

        val result = mvc.post().uri("/api/v1/games/$id/undo")

        assertThat(result).hasStatusOk().bodyJson().extractingPath("$.data.grid.length()").isEqualTo(4)
    }

    @Test
    fun `undo in an unknown game returns a structured 404`() {
        val result = mvc.post().uri("/api/v1/games/${UUID.randomUUID()}/undo")

        assertThat(result)
            .hasStatus(HttpStatus.NOT_FOUND)
            .bodyJson()
            .extractingPath("$.error.code")
            .isEqualTo("GAME_NOT_FOUND")
    }
```

   The split is deliberate. The controller test still runs on random boards, so it asserts
   only what holds for every board: status, envelope, error code. Everything that depends on
   the tiles is tested through the seam from warm-up B.

   `GameService.kt`:

```kotlin
    fun undo(id: UUID): GameState {
        val board = boardFor(id)
        synchronized(board) {
            // Nothing to undo is not an error: the caller gets the unchanged game back.
            board.undo()
            return stateOf(id, board)
        }
    }
```

   `GameController.kt`:

```kotlin
    @PostMapping("/{id}/undo")
    fun undo(@PathVariable id: UUID): ApiResponse<GameState> = ApiResponse(games.undo(id))
```

   The controller stays one expression. Status needs no code either: `stateOf()` recomputes
   it, so undoing the move that ended the game puts it back to `IN_PROGRESS`.

5. **The web UI.** *Mechanism: the main session.*

   > *"Add undo to the web UI, tests first. `undo(gameId)` in `api.ts` posts to the new
   > endpoint. `isUndoKey(key)` in `keys.ts` is true for `u` in either case. In `App.tsx` the
   > `u` key and a new Undo button both undo, and undo keeps working after the game is over
   > while moves stay blocked. Test the key mapping in `keys.test.ts` and the behaviour in a
   > new `App.test.tsx` that mocks `./api`. No `any`, named exports. Run `npm test`,
   > `npm run lint` and `npm run build` in `web/`."*

   `web/src/api.ts`, appended:

```ts
export function undo(gameId: string): Promise<Game> {
  return request<Game>(`/games/${encodeURIComponent(gameId)}/undo`, {
    method: 'POST',
  })
}
```

   `web/src/keys.ts`, appended:

```ts
/** True for the key that takes back the last move: `u`, in either case. */
export function isUndoKey(key: string): boolean {
  return key.toLowerCase() === 'u'
}
```

   `web/src/keys.test.ts`: the import becomes
   `import { isUndoKey, toDirection } from './keys'`, and this block is appended:

```ts
describe('isUndoKey', () => {
  it('recognises u as the undo key', () => {
    expect(isUndoKey('u')).toBe(true)
  })

  it('ignores the case of the undo key', () => {
    expect(isUndoKey('U')).toBe(true)
  })

  it('rejects a key that is not the undo key', () => {
    expect(isUndoKey('ArrowUp')).toBe(false)
  })
})
```

   `web/src/App.tsx`: the imports become `import { createGame, move, undo } from './api'`
   and `import { isUndoKey, toDirection } from './keys'`. The callback and the key effect:

```tsx
  const undoLastMove = useCallback(() => {
    if (game === null) {
      return
    }
    undo(game.id)
      .then(setGame)
      .catch((cause: unknown) => setError(messageOf(cause)))
  }, [game])

  useEffect(() => {
    if (game === null) {
      return
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (isUndoKey(event.key)) {
        undoLastMove()
        return
      }
      const direction = toDirection(event.key)
      // A finished game takes no more moves, but its last move can still be undone.
      if (direction === null || game.status === 'OVER') {
        return
      }
      // Arrow keys would otherwise scroll the page.
      event.preventDefault()
      move(game.id, direction)
        .then(setGame)
        .catch((cause: unknown) => setError(messageOf(cause)))
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [game, undoLastMove])
```

   and the button, placed before **New game** in the header:

```tsx
        <button type="button" onClick={undoLastMove} disabled={game === null}>
          Undo
        </button>
```

   The listener used to be skipped for a finished game. Now it is always attached, the undo
   check comes first, and the `OVER` test moved down to where only moves are affected.

   `web/src/App.test.tsx` (new file):

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move, undo } from './api'
import type { Game } from './api'
import { App } from './App'

// api.ts is this app's own wrapper around fetch, so the tests replace the wrapper, not fetch.
vi.mock('./api')

const CURRENT: Game = {
  id: 'game-1',
  grid: [
    [8, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 8,
  status: 'IN_PROGRESS',
}

const PREVIOUS: Game = {
  id: 'game-1',
  grid: [
    [4, 4, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App', () => {
  beforeEach(() => {
    vi.resetAllMocks()
    vi.mocked(createGame).mockResolvedValue(CURRENT)
    vi.mocked(undo).mockResolvedValue(PREVIOUS)
  })

  it('shows the previous board when Undo is clicked', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('8')

    await user.click(screen.getByRole('button', { name: 'Undo' }))

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('shows the previous board when u is pressed', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('8')

    await user.keyboard('u')

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('still undoes with u after the game is over', async () => {
    vi.mocked(createGame).mockResolvedValue({ ...CURRENT, status: 'OVER' })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('Game over.')

    await user.keyboard('u')

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('sends no move after the game is over', async () => {
    vi.mocked(createGame).mockResolvedValue({ ...CURRENT, status: 'OVER' })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('Game over.')

    await user.keyboard('{ArrowLeft}')

    expect(move).not.toHaveBeenCalled()
  })
})
```

   `api.ts` is the app's own wrapper around `fetch`, so the test replaces the wrapper and
   leaves `fetch` alone. The last test is a regression guard for the restructured listener:
   it proves that moving the `OVER` check did not unblock moves.

6. **Review.** *Mechanism: `kotlin-reviewer`.*

   > *"Use the kotlin-reviewer agent to review my uncommitted changes."*

   Run for this catalog on the diff above (as
   `copilot --agent kotlin-reviewer -p "..." --allow-tool='shell(git:*)'`; in `-p` mode an
   unapproved shell call is denied, in a session you are asked). The agent ran `git status`,
   `git diff` per layer and `git diff --check`, read the two `.instructions.md` files, and
   answered:

   ```text
   **Blocker**
   - No blocking issues found.

   **Should-fix**
   - No should-fix issues found.

   **Nit**
   - No nit issues found.

   > No files modified — review only.
   ```

   A clean review is one data point from one model, not a proof. You are still the one who
   has to understand the diff. Things worth checking yourself in whatever Copilot generates
   for you: the snapshot is taken before the move and not after the spawn; `undo()` restores
   the score; every `Board` access in `GameService` is inside `synchronized(board)`; the
   controller holds no logic; no test asserts on where a random tile landed.

**Done check.**

```bash
./gradlew build
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

Expected: `BUILD SUCCESSFUL`; the `grep` reports `BoardTest` with `tests="22"`,
`GameServiceTest` with `tests="5"` and `GameControllerTest` with `tests="7"`, all
`failures="0"`; Vitest prints `Test Files  3 passed (3)` and `Tests  14 passed (14)`; ESLint
prints nothing; the build ends with `✓ built in …`.

Then against the running API (`./gradlew :api:bootRun` in another terminal):

```bash
ID=$(curl -s -X POST localhost:8080/api/v1/games | jq -r .data.id)
curl -s -X POST localhost:8080/api/v1/games/$ID/undo | jq -c .data          # fresh game: unchanged, HTTP 200
curl -s -X POST -H 'Content-Type: application/json' -d '{"direction":"LEFT"}' \
  localhost:8080/api/v1/games/$ID/moves | jq -c .data
curl -s -X POST localhost:8080/api/v1/games/$ID/undo | jq -c .data          # the grid and score from before the move
curl -s -X POST localhost:8080/api/v1/games/00000000-0000-0000-0000-000000000000/undo
```

The last call answers 404 with
`{"error":{"code":"GAME_NOT_FOUND","message":"Game 00000000-0000-0000-0000-000000000000 does not exist"}}`.
`kotlin-reviewer` reports no blocker.

## 6. Plugin 🟡 — package the undo workflow as a bundled skill

**Layers:** none (config)

**Goal.** Put what exercise 5 taught you about undo into the `2048-dev` plugin as a skill,
`plugins/2048-dev/skills/undo/SKILL.md`: where undo lives in each layer, the rules a change
must keep, how to extend it. A colleague who enables the plugin then gets that knowledge
without reading your diff. Raise the plugin version from 1.0.0 to 1.1.0, validate the
manifest, and confirm that the skill loads as `2048-dev:undo`.

**Mechanism it teaches.** Growing a [plugin](06-plugins.md). A skill is discovered by its
location, `skills/<name>/SKILL.md`; in the Agent Plugins 1.0 format the manifest lists no
components, and the schema rejects a `skills` field. The version is what a colleague with
an installed copy sees in `copilot plugin list`; `copilot plugin update` is how they pick
the change up (per the docs). Validation is a JSON Schema check, because Copilot CLI has no
`plugin validate` command (per the docs).

**Files.**

- `plugins/2048-dev/skills/undo/SKILL.md` (new)
- `plugins/2048-dev/plugin.json` — `version`, `description`
- `marketplace.json` — the plugin entry's `version`, `description`

**Inline context.**

- The plugin bundles one skill, `plugins/2048-dev/skills/build-test/SKILL.md`, which loads
  with the command name `2048-dev:build-test`. The prefix is the plugin's `name`.
- The version is written twice: `plugins/2048-dev/plugin.json` line 5 and the plugin entry
  in `marketplace.json` line 14. `metadata.version` on line 8 of `marketplace.json` is the
  marketplace's own version. Leave it.
- This repo enables the plugin through `.github/copilot/settings.json` with a directory
  marketplace, so it loads from the working tree. Per the docs an edit takes effect on
  `/restart` or in a new session; nobody has to reinstall anything here.
- **This exercise builds on exercise 5.** The skill describes code that exists only on your
  exercise 5 branch, so branch from it instead of from `main`:
  `git switch -c ex6-plugin <your-exercise-5-branch>`. Without that branch, take the
  `SKILL.md` from the walkthrough as it is. The plugin mechanics are the same, and the skill
  then serves as the build plan for undo.
- **Names.** Per the docs a project skill silently wins over a plugin skill with the same
  `name`. The project skills here are `board-tests` and, if you did exercise 2,
  `api-endpoint`. `undo` is free. The built-in `/undo` slash command is unrelated: the
  skill's command carries the plugin prefix, `/2048-dev:undo`.

**Starter prompt.**
> *"Add a skill to the 2048-dev plugin at `plugins/2048-dev/skills/undo/SKILL.md`, modelled
> on `plugins/2048-dev/skills/build-test/SKILL.md`. It documents the undo feature as it is
> implemented now, so read `Board.kt`, `GameService.kt`, `GameController.kt`, `web/src/api.ts`,
> `web/src/keys.ts` and `web/src/App.tsx` first. Sections: where undo lives in each layer,
> the rules a change must keep, how to extend it (redo, a history limit, showing whether
> undo is possible), which tests come first, how to verify. Frontmatter: `name: undo` and a
> `description` that says when to use it. Then raise the plugin version from 1.0.0 to 1.1.0
> in `plugins/2048-dev/plugin.json` and in the plugin's entry in `marketplace.json`, and
> mention the new skill in both descriptions. Add no other field to `plugin.json`."*

**Walkthrough (full solution).**

> **What was run for this catalog.** Steps 3 to 5, in a worktree that held the plugin change
> but not the code of exercise 5. The skill text describes the solution of exercise 5.
> No tool checks a skill against the code it describes; that part is your review.

1. **Write the skill.** *Mechanism: the main session.* `plugins/2048-dev/skills/undo/SKILL.md`:

````markdown
---
name: undo
description: Use when changing or extending the undo feature of the 2048 project (move history, the undo endpoint, the U key, the Undo button), or when adding a neighbouring feature such as redo or a history limit. Explains where undo lives in each layer and the rules a change must keep.
---

# Undo in the 2048 project

Undo takes back the last move that changed the board. It is one feature spread over three
layers, and each layer does exactly one thing.

## Where it lives

| Layer  | File                                                        | What it does                                                                                           |
| ------ | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| engine | `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`   | `move()` pushes a `Snapshot(grid, score)` onto `history` when the board changed; `undo()` pops it       |
| api    | `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`   | `undo(id)` calls `board.undo()` inside `synchronized(board)` and returns the game state                 |
| api    | `api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` | `POST /api/v1/games/{id}/undo` answers `{ "data": GameState }`                                         |
| web    | `web/src/api.ts`                                            | `undo(gameId)` posts to the endpoint                                                                   |
| web    | `web/src/keys.ts`                                           | `isUndoKey(key)` is true for `u` in either case                                                        |
| web    | `web/src/App.tsx`                                           | `undoLastMove()` is called by the key listener and by the Undo button                                  |

If `Board.undo()` does not exist yet, build the feature in this order: engine, api, web.

## Rules a change must keep

1. History is game state, so it lives in `Board`. `GameService` never stores a grid.
2. The snapshot is taken **before** the move and kept only when the move changed the board.
   A move that slides nothing cannot be undone.
3. Because the snapshot predates `spawnRandom()`, one undo also removes the tile spawned
   after the move. Never snapshot after the spawn.
4. The score is restored together with the grid.
5. Nothing to undo is not an error. `Board.undo()` returns `false` and changes nothing; the
   API answers 200 with the unchanged game. An unknown game is still 404 `GAME_NOT_FOUND`.
6. Undo stays available after the game is over. The key listener in `App.tsx` must keep
   listening when the status is `OVER`; only moves are ignored then.
7. `GameService` touches a `Board` only inside `synchronized(board)`.

## Extending it

- **Redo.** Add a second deque to `Board`. `undo()` pushes the state it replaces onto it,
  `redo()` pops from it, and a `move()` that changes the board clears it. Then add
  `POST /api/v1/games/{id}/redo`, `redo(gameId)` in `api.ts` and a key in `keys.ts`.
- **History limit.** Add a constant next to `WIN_VALUE` and drop the oldest snapshot with
  `history.removeFirst()` when `move()` exceeds it.
- **Showing whether undo is possible.** Expose it from `Board`, add the field to `GameState`
  and to the `Game` type in `api.ts`, and disable the button with it.

## Tests come first

- Engine rules go in `BoardTest.kt`, built with `boardOf(...)`, one behaviour per test.
- What happens around a move goes in `GameServiceTest.kt`. `GameService { Board(rows) }`
  starts every game from a known grid, so the test does not depend on random tiles.
- The HTTP mapping (status, envelope, 404) goes in `GameControllerTest.kt`.
- Web: key mapping in `keys.test.ts`, the button and the key in `App.test.tsx`, which
  replaces `./api` with `vi.mock`.

## Verify

```bash
./gradlew build
cd web && npm test && npm run lint && npm run build
```

Report the pass and fail counts per suite.
````

   What makes this worth shipping is the middle section. The file table can be rebuilt with
   a search. The rules cannot: each one is a decision from exercise 5 that the code only
   shows if you already know to look for it. If Copilot's draft has only the table, ask for
   the rules:

   > *"Add a section 'Rules a change must keep'. For each rule, tell me which test in
   > `BoardTest.kt`, `GameServiceTest.kt` or `App.test.tsx` would fail if it were broken, or
   > that none would. Do not put the test names into the skill."*

   Two of the seven rules have no test: where the history lives, and the locking. Those are
   the ones a reviewer has to carry in the head, which is the best reason to write them down.

2. **Raise the version in both files.**

```diff
--- a/marketplace.json
+++ b/marketplace.json
@@ -12,4 +12,4 @@
       "name": "2048-dev",
-      "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
-      "version": "1.0.0",
+      "description": "Dev workflow skills (build-test, undo) and the game-explorer agent for the 2048 workshop project",
+      "version": "1.1.0",
       "source": "./plugins/2048-dev"
--- a/plugins/2048-dev/plugin.json
+++ b/plugins/2048-dev/plugin.json
@@ -3,4 +3,4 @@
   "name": "2048-dev",
-  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
-  "version": "1.0.0",
+  "description": "Dev workflow skills (build-test, undo) and the game-explorer agent for the 2048 workshop project",
+  "version": "1.1.0",
   "author": {
```

3. **Validate the manifest.** Free, no model call:

```bash
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

   Run here, the command needs no extra flag and prints:

```text
plugins/2048-dev/plugin.json valid
```

   The schema fixes `$schema` to the 1.0.0 URL, requires `name`, and sets
   `additionalProperties: false`. `version` is any string, so the schema does not catch a
   forgotten bump; the `jq` line in the done check does. To see the check fail, add
   `"skills": "./skills"` to `plugin.json` and run it again:

```text
plugins/2048-dev/plugin.json invalid
[
  {
    instancePath: '',
    schemaPath: '#/additionalProperties',
    keyword: 'additionalProperties',
    params: { additionalProperty: 'skills' },
    message: 'must NOT have additional properties'
  }
]
```

   Remove the field again. The skill is found by its folder, not by the manifest.

4. **Check that it loads.** *Mechanism: the plugin loader.* One model call:

```bash
copilot -p "Reply with the single word ok. Do not call any tool." --trust-folder --no-ask-user --output-format json \
  | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | {name, commandName}' \
  | sort -u
```

   Run here:

```text
{"name":"build-test","commandName":"2048-dev:build-test"}
{"name":"undo","commandName":"2048-dev:undo"}
```

5. **Use it.** *Mechanism: the plugin skill.*

   > */2048-dev:undo I want to add redo. In at most six lines: where does the undo history
   > live, and which rules must redo not break? Do not modify any file.*

   Run here with `copilot -p`, the session made one tool call, `skill` with
   `{"skill":"undo"}`, and answered from the skill: the history lives in `Board`, redo is a
   second deque there and never in `GameService`, a move that changes the board clears it,
   grid and score are restored together, and both stay available after `OVER`.

**Done check.**

```bash
jq -r '"\(.name) \(.version)"' plugins/2048-dev/plugin.json
jq -r '.plugins[] | "\(.name) \(.version)"' marketplace.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

Expected: `2048-dev 1.1.0` twice, then `plugins/2048-dev/plugin.json valid`. The command
from step 4 lists `"commandName":"2048-dev:undo"`. No application code changed, so
`./gradlew build` and the web checks are as green as exercise 5 left them.

## 7. Orchestration 🔴 — an auto-solver chosen by a judge

**Layers:** engine

**Goal.** Add an engine-only auto-solver: a `Solver` abstraction, three heuristics
(corner-biased, greedy by score, monotonicity), and a seeded benchmark that plays N games
per heuristic and reports the average score and the best tile. Build the three heuristics
with three subagents in parallel using `/fleet`, then let a judge pick the winner from the
benchmark numbers and from nothing else.

**Mechanism it teaches.** [Orchestration](07-orchestration.md): fan out, join, judge. The
shape that makes it work is the same in every tool. First a **contract** written by one
agent, so the parallel workers cannot drift apart. Then **workers that own disjoint files**.
Then a **deterministic measurement** that no model produces. Last a **judge that sees only
the measurement**. `/fleet` lets the model decide the split on every run. The optional
[Conductor](14-conductor.md) variant fixes the split in a YAML file.

**Files.**

- `engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt` — the contract
- `…/solver/CornerSolver.kt`, `GreedySolver.kt`, `MonotonicSolver.kt` — one per subagent
- `…/solver/Benchmark.kt` — `playGame`, `benchmark`
- `engine/src/test/kotlin/com/quanti/g2048/engine/solver/` — `SolverTest.kt`,
  `CornerSolverTest.kt`, `GreedySolverTest.kt`, `MonotonicSolverTest.kt`,
  `BenchmarkTest.kt`, `BenchmarkRunner.kt`
- `engine/build.gradle.kts` — the `benchmark` task
- `conductor/solver-tournament.yaml` (optional)

**Inline context.**

- **Determinism is already there.** `Board`'s constructor takes a `Random`, and
  `Board.newGame(random)` passes it on. A game started from `Random(seed)` is the same game
  every time.
- **A solver must try a move without making it.** `Board.move()` mutates, and `Board` has no
  copy function. Its public constructor does the job: `Board(board.grid, board.score)`.
  `grid` already returns a copy, so the two boards share nothing. The copy gets the default
  `Random`, which is harmless here because a trial never spawns a tile: the lookahead draws
  nothing, neither from the copy's generator nor from the game's seeded one. That is what
  keeps the benchmark reproducible.
- **Do not end the game loop on `isGameOver()`.** At `HEAD` it is the bug from exercise 5
  and reports a full but playable board as over. End the game when no direction changes the
  board. The solver needs that list of legal moves anyway.
- **Engine main code performs no I/O** (`.github/copilot-instructions.md`: "pure game rules
  … No I/O, no Spring"). The benchmark logic returns numbers and lives in `main`; the
  `println` lives in a runner in the test source set, and a Gradle task runs it.
- **Parallel workers share one working tree.** Kotlin compiles a source set as a whole, so
  one subagent's half-written file fails another subagent's build. The workers must not run
  Gradle; the orchestrator builds once after the join.

**Starter prompt.** The contract comes first and is not parallel work:
> *"Create the package `com.quanti.g2048.engine.solver` in the engine module with one file,
> `Solver.kt`: an interface `Solver` with `val name: String` and
> `fun chooseMove(board: Board): Direction?`, which returns null when no direction changes
> the board and never modifies it; a class `Outcome(direction, grid, gained)`; and a
> top-level function `legalOutcomes(board): List<Outcome>` that tries every direction on a
> copy made with `Board(board.grid, board.score)` and returns the ones that change the
> board, in enum order. Add `SolverTest.kt` with one behaviour per test. No I/O, no
> `Random`. Run `./gradlew :engine:test`."*

Then fan out:
> */fleet Build three 2048 solvers in parallel, one subagent each, in
> `engine/src/main/kotlin/com/quanti/g2048/engine/solver/`. Every subagent reads `Solver.kt`
> first, creates exactly two files (its solver and its test) and touches nothing else.
> (1) `CornerSolver`, name "corner": picks the outcome whose grid has the most tile value on
> the cells nearest the top-left corner, with weights falling along a snake.
> (2) `GreedySolver`, name "greedy": picks the outcome with the highest `gained`; the first
> one wins a tie. (3) `MonotonicSolver`, name "monotonic": picks the outcome whose grid has
> the most neighbouring pairs in order, a pair being in order when the value does not grow
> from left to right or from top to bottom. Each returns null when there is no legal
> outcome. Tests: JUnit Jupiter, backtick sentence names, Arrange-Act-Assert, boards built
> with `Board(listOf(...))`. The subagents must not run Gradle, because all three write into
> the same source set at the same time. When all three are done, run `./gradlew :engine:test`
> once yourself and fix what fails.*

**Walkthrough (full solution).**

> **What was run for this catalog.** The code was built and tested in a clean worktree, and
> every number below was printed by it. `/fleet` itself was **not** driven here; what this
> exercise says about it is per the docs and `copilot help`. The Conductor variant at the end
> **was** run once, end to end.

1. **The contract.** *Mechanism: the main session.* `Solver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction

/** A strategy that plays 2048 by picking the next move for a board. */
interface Solver {
    /** Short label used in benchmark output. */
    val name: String

    /** The move to play on [board], or null when no direction changes it. Never modifies [board]. */
    fun chooseMove(board: Board): Direction?
}

/** What one direction would do to a board: the grid it leads to and the score it gains. */
class Outcome(val direction: Direction, val grid: List<List<Int>>, val gained: Int)

/**
 * Tries every direction on a copy of [board] and returns the ones that change it, in the
 * order UP, DOWN, LEFT, RIGHT. The board passed in is never modified.
 */
fun legalOutcomes(board: Board): List<Outcome> =
    Direction.entries.mapNotNull { direction ->
        // Board has no copy function; its public constructor rebuilds one from grid and score.
        // The copy never spawns a tile, so the trial draws nothing from the game's Random.
        val copy = Board(board.grid, board.score)
        if (copy.move(direction)) {
            Outcome(direction, copy.grid, copy.score - board.score)
        } else {
            null
        }
    }
```

   `legalOutcomes` is the piece all three heuristics share. With it, a heuristic is one
   expression, and three subagents have very little room to disagree. `SolverTest.kt` pins it
   down:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class SolverTest {

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `trying the moves leaves the board untouched`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        legalOutcomes(board)

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `a direction that changes nothing is not a legal outcome`() {
        // The tiles already sit on the top edge, so UP is the one direction that moves nothing.
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val directions = legalOutcomes(board).map { it.direction }

        assertEquals(listOf(Direction.DOWN, Direction.LEFT, Direction.RIGHT), directions)
    }

    @Test
    fun `an outcome reports the score its move gains`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val left = legalOutcomes(board).first { it.direction == Direction.LEFT }

        assertEquals(4, left.gained)
    }

    @Test
    fun `an outcome carries the grid its move leads to`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val left = legalOutcomes(board).first { it.direction == Direction.LEFT }

        assertEquals(
            listOf(
                listOf(4, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            left.grid,
        )
    }

    @Test
    fun `a locked board has no legal outcome`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertTrue(legalOutcomes(board).isEmpty())
    }
}
```

2. **Fan out.** *Mechanism: `/fleet`.* Paste the `/fleet` prompt. Per the docs the main agent
   becomes the orchestrator, splits the work into todos and runs the independent ones as
   parallel subagents, each with its own context; `/tasks` shows them. The prompt does the
   three things that make a fan-out safe: it names the file each worker owns, it points all
   of them at the contract, and it keeps the build for after the join. Per the docs a custom
   agent can be named in a `/fleet` prompt as `@agent-name`. Expect to spend more AI credits
   than one session would: each subagent calls the model on its own.

   `GreedySolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction

/**
 * Greedy by score: plays the move that gains the most points right now. When several
 * moves gain the same, the first one in the order UP, DOWN, LEFT, RIGHT wins.
 */
class GreedySolver : Solver {
    override val name = "greedy"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { it.gained }?.direction
}
```

   `CornerSolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import com.quanti.g2048.engine.SIZE

/**
 * Corner-biased: plays the move that leaves the most tile value on the cells closest to
 * the top-left corner. The weights follow a snake from that corner, so the next-largest
 * tiles line up behind the largest one instead of scattering.
 */
class CornerSolver : Solver {
    override val name = "corner"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { cornerScore(it.grid) }?.direction

    private fun cornerScore(grid: List<List<Int>>): Int {
        var total = 0
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                total += grid[row][col] * WEIGHTS[row][col]
            }
        }
        return total
    }

    private companion object {
        val WEIGHTS = listOf(
            listOf(15, 14, 13, 12),
            listOf(8, 9, 10, 11),
            listOf(7, 6, 5, 4),
            listOf(0, 1, 2, 3),
        )
    }
}
```

   `MonotonicSolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import com.quanti.g2048.engine.SIZE

/**
 * Monotonicity: plays the move that leaves the most neighbouring pairs in order, counting
 * a pair as ordered when the value does not grow from left to right or from top to bottom.
 * Ordered lines keep equal tiles next to each other, which is what makes them mergeable.
 */
class MonotonicSolver : Solver {
    override val name = "monotonic"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { orderedPairs(it.grid) }?.direction

    private fun orderedPairs(grid: List<List<Int>>): Int {
        var ordered = 0
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                if (col + 1 < SIZE && grid[row][col] >= grid[row][col + 1]) {
                    ordered++
                }
                if (row + 1 < SIZE && grid[row][col] >= grid[row + 1][col]) {
                    ordered++
                }
            }
        }
        return ordered
    }
}
```

   `maxByOrNull` returns the first maximum and `legalOutcomes` has a fixed order, so every
   tie is broken the same way on every run. Without that the benchmark would not be
   reproducible.

   The three test files. Each board is chosen so that exactly one answer is right, and the
   comment says why:

   `GreedySolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class GreedySolverTest {

    private val solver = GreedySolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `takes the move that gains the most points`() {
        // LEFT and RIGHT merge the 8s (+16); UP and DOWN merge only the 2s (+4).
        val board = boardOf(
            listOf(8, 8, 0, 2),
            listOf(0, 0, 0, 2),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `breaks a tie with the first direction in enum order`() {
        // UP and LEFT change nothing; DOWN and RIGHT both gain 0, and DOWN comes first.
        val board = boardOf(
            listOf(2, 4, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.DOWN, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

   `CornerSolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class CornerSolverTest {

    private val solver = CornerSolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `moves the largest tile into the top-left corner`() {
        // UP puts the 64 on the corner cell (weight 15); DOWN and RIGHT land on weights 0 and 4.
        val board = boardOf(
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(64, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.UP, move)
    }

    @Test
    fun `does not pull the largest tile out of the corner`() {
        // UP changes nothing; DOWN and RIGHT move the 64 away; LEFT keeps it and packs the 2.
        val board = boardOf(
            listOf(64, 0, 2, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

   `MonotonicSolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class MonotonicSolverTest {

    private val solver = MonotonicSolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `prefers the move that leaves every line in order`() {
        // LEFT gives 4, 2, 0, 0: no pair grows. DOWN and RIGHT each leave a pair that grows.
        val board = boardOf(
            listOf(0, 4, 0, 2),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

3. **The benchmark.** *Mechanism: the main session.*

   > *"Add `Benchmark.kt` to the solver package. `playGame(solver, random): Board` starts
   > `Board.newGame(random)` and plays until the solver returns null; it must not use
   > `isGameOver()`. `benchmark(solver, games, seed): BenchmarkResult` seeds game n with
   > `Random(seed + n)` and returns the solver name, the number of games, the average score
   > and the best tile. No printing in main code. Add `BenchmarkTest.kt`. Put a `main` that
   > prints one row per solver into `BenchmarkRunner.kt` in the same package of the test
   > source set, and register a `JavaExec` task `benchmark` in `engine/build.gradle.kts` that
   > runs it on the test runtime classpath, with `-Pgames` (default 1000) and `-Pseed`
   > (default 2048)."*

   `Benchmark.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import kotlin.random.Random

data class BenchmarkResult(
    val solver: String,
    val games: Int,
    val averageScore: Double,
    val bestTile: Int,
)

/**
 * Plays one game to the end and returns the final board. The game ends when the solver
 * finds no move that changes the board, so the loop does not depend on Board.isGameOver().
 */
fun playGame(solver: Solver, random: Random): Board {
    val board = Board.newGame(random)
    while (true) {
        val direction = solver.chooseMove(board) ?: return board
        board.move(direction)
        board.spawnRandom()
    }
}

/**
 * Plays [games] games with [solver] and summarises them. Game number n is seeded with
 * `seed + n`, so every solver starts game n from the same two tiles and a run with the
 * same arguments always returns the same numbers.
 */
fun benchmark(solver: Solver, games: Int, seed: Long): BenchmarkResult {
    require(games > 0) { "games must be positive" }

    var totalScore = 0L
    var bestTile = 0
    for (game in 0 until games) {
        val board = playGame(solver, Random(seed + game))
        totalScore += board.score
        bestTile = maxOf(bestTile, board.grid.flatten().max())
    }
    return BenchmarkResult(solver.name, games, totalScore.toDouble() / games, bestTile)
}
```

   One seed per game, not one generator for the whole run: every solver then starts game n
   from the same two tiles, and a slow solver's extra draws cannot shift the games after it.

   `BenchmarkTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import kotlin.random.Random
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class BenchmarkTest {

    @Test
    fun `a game is played until no move changes the board`() {
        val board = playGame(GreedySolver(), Random(1))

        assertTrue(legalOutcomes(board).isEmpty())
    }

    @Test
    fun `the same seed gives the same result`() {
        val first = benchmark(GreedySolver(), games = 3, seed = 42)

        val second = benchmark(GreedySolver(), games = 3, seed = 42)

        assertEquals(first, second)
    }

    @Test
    fun `a different seed gives a different result`() {
        val first = benchmark(GreedySolver(), games = 3, seed = 42)

        val second = benchmark(GreedySolver(), games = 3, seed = 43)

        assertNotEquals(first.averageScore, second.averageScore)
    }

    @Test
    fun `the result names the solver it measured`() {
        val result = benchmark(CornerSolver(), games = 1, seed = 42)

        assertEquals("corner", result.solver)
    }

    @Test
    fun `zero games are rejected`() {
        assertThrows(IllegalArgumentException::class.java) {
            benchmark(GreedySolver(), games = 0, seed = 42)
        }
    }
}
```

   `BenchmarkRunner.kt` (test source set):

```kotlin
package com.quanti.g2048.engine.solver

import java.util.Locale

/**
 * Prints the benchmark table: `./gradlew -q :engine:benchmark [-Pgames=50] [-Pseed=7]`.
 * It lives in the test source set because engine main code performs no I/O.
 */
fun main(args: Array<String>) {
    val games = args.getOrNull(0)?.toInt() ?: 1000
    val seed = args.getOrNull(1)?.toLong() ?: 2048L
    val solvers = listOf(CornerSolver(), GreedySolver(), MonotonicSolver())

    println("solver      games  avg score  best tile   (seed $seed)")
    for (solver in solvers) {
        val result = benchmark(solver, games, seed)
        // Locale.ROOT keeps the decimal point a point on every machine.
        println(
            String.format(
                Locale.ROOT,
                "%-10s %6d %10.1f %10d",
                result.solver,
                result.games,
                result.averageScore,
                result.bestTile,
            ),
        )
    }
}
```

   `engine/build.gradle.kts`, appended:

```kotlin
// Prints one line per solver: ./gradlew -q :engine:benchmark [-Pgames=50] [-Pseed=7]
tasks.register<JavaExec>("benchmark") {
    group = "verification"
    description = "Plays seeded games with every solver and prints average score and best tile."
    classpath = sourceSets["test"].runtimeClasspath
    mainClass = "com.quanti.g2048.engine.solver.BenchmarkRunnerKt"
    args(
        providers.gradleProperty("games").getOrElse("1000"),
        providers.gradleProperty("seed").getOrElse("2048"),
    )
}
```

4. **Judge.** *Mechanism: the main session as judge, on numbers a command printed.*

   > *"Run `./gradlew -q :engine:benchmark`. Act as the judge: rank the solvers by average
   > score, break a tie with the best tile, name the winner and give one sentence of
   > justification. Use only the numbers the command printed. Do not change any file."*

   The command, run here on `HEAD` (three times 1000 games in under two seconds, the same
   output on every run):

```text
solver      games  avg score  best tile   (seed 2048)
corner       1000     2243.8        512
greedy       1000     2394.8        512
monotonic    1000     3047.5        512
```

   The winner is `monotonic`. The judge has nothing to be creative about, and you can check
   its verdict by eye. That is the design: the model orchestrates and explains, the benchmark
   decides.

   Two things the numbers teach, both measured here:

   | Run | corner | greedy | monotonic |
   |---|---|---|---|
   | `-Pgames=50` | 2515.6 | 2170.0 | 2920.2 |
   | default (1000 games) | 2243.8 | 2394.8 | 3047.5 |
   | 1000 games, cascade-merge bug fixed | 2262.3 | 3000.0 | 3037.4 |
   | 50 games, cascade-merge bug fixed | 2340.1 | 3113.3 | 3091.2 |

   - **Sample size.** With 50 games `corner` beats `greedy`; with 1000 it is the other way
     round. A judge given the 50-game table ranks them wrongly and is not to blame.
   - **The verdict depends on the rules.** If you have fixed the cascade-merge bug
     (`4, 4, 8, 0` must give `8, 8, 0, 0`), `greedy` stops profiting from double
     merges that should not exist, and it lands within about 1 % of `monotonic`; at 50 games
     it even wins. Rerun the benchmark after every rule change, and tell the judge what to do
     with a near tie.

   No heuristic gets past 512 on `HEAD`. Looking one move ahead is a weak player. A solver
   that searches deeper fits behind the same interface and into the same benchmark.

5. **Optional: the same flow as a Conductor workflow.** `/fleet` decides the split anew on
   every run. [Conductor](14-conductor.md) writes it down. The file below is modelled on
   `conductor/test-coverage-audit.yaml`: a parallel group, then a join. The new element is a
   `type: script` step, which runs the benchmark itself and hands stdout to the judge, so no
   agent stands between the command and the verdict. Save it as
   `conductor/solver-tournament.yaml`:

```yaml
# Solver tournament as a Conductor workflow.
#
# Three agents write one solver each at the same time, a script step runs the
# seeded benchmark, and a judge with no tools ranks the numbers. The benchmark is
# a plain command, so the table the judge reads was not produced by a model.
#
#   conductor validate conductor/solver-tournament.yaml
#   conductor run conductor/solver-tournament.yaml
#
# Run from the repository root, after the shared pieces exist: Solver.kt,
# Benchmark.kt, BenchmarkRunner.kt and the `benchmark` Gradle task.

workflow:
  name: solver-tournament
  description: Build three 2048 solvers in parallel, benchmark them, let a judge pick the winner
  version: "1.0.0"
  entry_point: solver_builders

  runtime:
    provider: copilot
    # Let Copilot pick from the models your organization allows.
    default_model: auto

  context:
    mode: explicit

  limits:
    max_iterations: 10
    timeout_seconds: 1800

# There is no top-level `tools:` list on purpose. Without one, an agent that names
# no tools gets the provider's default set, which is what lets the builders create
# files. The judge opts out of all tools with `tools: []`.

parallel:
  - name: solver_builders
    description: One solver and its test file per agent, written at the same time
    agents:
      - corner_builder
      - greedy_builder
      - monotonic_builder
    # A missing solver would break the benchmark's compile step, so stop early.
    failure_mode: fail_fast
    routes:
      - to: benchmark

agents:
  - name: corner_builder
    description: Writes the corner-biased solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/CornerSolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/CornerSolverTest.kt

      `class CornerSolver : Solver`, with `name = "corner"`. From `legalOutcomes(board)` it
      picks the outcome whose grid has the most tile value on the cells nearest the top-left
      corner (weight each cell, largest weight in the corner, weights falling along a snake).
      It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  - name: greedy_builder
    description: Writes the greedy-by-score solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/GreedySolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/GreedySolverTest.kt

      `class GreedySolver : Solver`, with `name = "greedy"`. From `legalOutcomes(board)` it
      picks the outcome with the highest `gained`; on a tie the first outcome in the list
      wins. It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  - name: monotonic_builder
    description: Writes the monotonicity solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/MonotonicSolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/MonotonicSolverTest.kt

      `class MonotonicSolver : Solver`, with `name = "monotonic"`. From `legalOutcomes(board)`
      it picks the outcome whose grid has the most neighbouring pairs in order, a pair being
      in order when the value does not grow from left to right or from top to bottom.
      It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  # Not an agent: Conductor runs the command itself and stores stdout, stderr and
  # exit_code as this step's output. Compiling here is also the first build of the
  # three new solvers together.
  - name: benchmark
    type: script
    description: Compiles the engine and prints the seeded benchmark table
    command: ./gradlew
    args: ["-q", ":engine:benchmark"]
    timeout: 600
    routes:
      - to: judge

  - name: judge
    description: Ranks the solvers from the benchmark table alone
    tools: []
    input:
      - benchmark.output
    prompt: |
      A seeded benchmark played the same games with each 2048 solver. Its output
      (exit code {{ benchmark.output.exit_code }}) is:

      {{ benchmark.output.stdout }}

      Rank the solvers by average score, highest first. Break a tie with the best tile.
      Use only the numbers above. If the text is not a table with one row per solver,
      set winner to "none" and quote the first error line as the reason.
    output:
      winner:
        type: string
        description: Name of the best solver, or "none"
      ranking:
        type: string
        description: Markdown table - rank, solver, average score, best tile
      reason:
        type: string
        description: One sentence on why the winner won
    routes:
      - to: $end

output:
  winner: "{{ judge.output.winner }}"
  ranking: "{{ judge.output.ranking }}"
  reason: "{{ judge.output.reason }}"
```

```bash
export PATH="$HOME/.local/bin:$PATH"
conductor validate conductor/solver-tournament.yaml
conductor --silent run conductor/solver-tournament.yaml
```

   **Validated and run** for this catalog (Conductor v0.1.47, Copilot provider), once, in a
   worktree that held steps 1 and 3 but none of the three solver files. `validate` printed
   `Validation Successful` with 5 agents and 1 parallel group. `run` wrote the six files,
   ran the benchmark and returned:

```json
{
  "winner": "monotonic",
  "ranking": "| Rank | Solver | Average score | Best tile |\n|---:|---|---:|---:|\n| 1 | monotonic | 3047.5 | 512 |\n| 2 | greedy | 2394.8 | 512 |\n| 3 | corner | 2243.8 | 512 |",
  "reason": "monotonic won with the highest average score of 3047.5."
}
```

   Afterwards `./gradlew build` was green in that worktree with 38 tests; the three agents
   had written 10 solver tests where the reference solution has 8. The numbers equal the
   reference ones although the generated `CornerSolver` uses weights 16 down to 1 instead of
   15 down to 0: a move never changes the sum of the tiles, so adding a constant to every
   weight cannot change which move wins. One run proves that the file works, not that it
   works every time. Run it in a worktree or on a branch: Conductor approves the agents'
   file writes for you.

**Done check.**

```bash
./gradlew build
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
./gradlew -q :engine:benchmark
./gradlew -q :engine:benchmark -Pgames=50 -Pseed=7
```

Expected: `BUILD SUCCESSFUL`; next to `BoardTest` and `GameControllerTest` the `grep` reports
five new suites, all `failures="0"`: `SolverTest` with `tests="5"`, `GreedySolverTest` 3,
`CornerSolverTest` 3, `MonotonicSolverTest` 2 and `BenchmarkTest` 5; the benchmark prints one
row per solver, and running it twice prints the same numbers. On a clean `HEAD`, and equally
on top of the solution of exercise 5, the default run is the table in step 4. Your averages differ if you fixed a rule bug or wrote the
heuristics differently; they must not differ between two runs of yours. The judge names the
solver with the highest average.

## 8. Eval 🟡 — prove a skill helps

**Layers:** none (config)

**Goal.** Write an eval for a skill you created, here the `api-endpoint` skill from
exercise 2 (the reference version printed there): a spec with a positive and a negative
stimulus and deterministic graders, and an experiment that runs the same spec with and
without the skill. Lint it, dry-run it, run it, and read the report without reading more
into it than it holds.

**Mechanism it teaches.** [Evals](09-validate-eval.md) with Vally. A trial is a real Copilot
session in a throwaway workspace that contains the files you stage and, in the variant that
has one, the skill. Graders then inspect the workspace and the event stream. An experiment
reruns the spec once per variant and changes exactly one thing, here `/environment/skills`.
Everything else stays equal, so a difference between the variants can be pinned on the
skill.

**Files.**

- `evals/api-endpoint/eval.yaml` (new)
- `evals/experiments/api-endpoint-ab.experiment.yaml` (new)
- `.github/skills/api-endpoint/SKILL.md` — from exercise 2, unchanged

**Inline context.**

- `evals/board-tests/eval.yaml` and `evals/experiments/board-tests-ab.experiment.yaml` are
  known to work. Copy their shape: `agent_environment` with `skills` and `files`, stimuli
  with `graders`, `scoring.threshold: 1`, and a `matrix` on `/environment/skills` with a
  declared `baseline`.
- **Stage application source only.** No `.github/`: the repository instructions already say
  "Spring Boot 4, use `MockMvcTester`", and with them in the workspace the baseline would
  know what the skill is supposed to teach. Leaving out the existing `GameControllerTest.kt`
  has the same reason. The skill must be the only place the conventions can come from.
- **Get the skill onto a clean branch.** It lives on your exercise 2 branch. Start from
  `main` and copy only the skill folder:
  `git checkout <your-exercise-2-branch> -- .github/skills/api-endpoint`. Do not run the
  eval on the exercise 2 branch itself: the spec stages `GameController.kt` and
  `GameService.kt` from the working tree, and there they already contain the win-value
  feature. No exercise 2 branch? Create the file from the reference block in exercise 2.
- **A grader can only check what the skill says.** Go through the `SKILL.md` and write one
  grader per convention. Every grader of the spec below has a line in the reference skill:

  | Grader checks | Where the reference skill says it |
  |---|---|
  | `@DeleteMapping("/{id}")` in `GameController.kt` | Contract: resources under `/api/v1`, plural nouns, no verbs |
  | `NO_CONTENT` or `noContent()` | Contract: "A delete answers 204 with no body" |
  | `boards.remove(` in `GameService.kt` | Steps 2 and 5: the service method does the work, the controller maps HTTP to it |
  | `GameControllerTest.kt` exists | Step 6: tests live in `api/src/test/kotlin/com/quanti/g2048/api/<Controller>Test.kt` |
  | `MockMvcTester` in that file | Step 6 and "Boot 4, not Boot 3" |
  | a backtick test name | Step 6: "a plain-English sentence in backticks" |
  | `GAME_NOT_FOUND` in that file | Step 6: one test per failure case; the shape to copy |

  A grader for something the skill never mentions measures the model, not the skill. If
  your own skill leaves one of these out, as an earlier draft of the reference did with the
  204, the test path and the test names, extend the skill or drop the grader.
- `package.json` pins `@microsoft/vally-cli`; `npm ci` at the repository root installs it.
  `EVALUATE_USE_HOST_COPILOT_HOME=1` reuses your Copilot login, `VALLY_TELEMETRY_OPTOUT=1`
  turns Vally's telemetry off.

**Starter prompt.**
> *"Write a Vally eval for the `api-endpoint` skill in `.github/skills/api-endpoint/`,
> modelled on `evals/board-tests/eval.yaml`. Read the skill first and write one
> deterministic grader per convention it states. Stage only application source: the three
> files in `api/src/main/kotlin/com/quanti/g2048/api/`, `api/build.gradle.kts` and
> `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`. No `.github/` and no existing
> test. Positive stimulus: 'Add a REST endpoint that deletes a game, with its tests',
> without naming the skill, and say that the workspace has no build tool. Negative stimulus:
> a short question about `Board.spawnRandom` that must not invoke the skill and must leave
> the diff empty. Use `runs: 1` and `scoring.threshold: 1`. Then write `evals/experiments/api-endpoint-ab.experiment.yaml`,
> modelled on `board-tests-ab.experiment.yaml`, with the variants `without` and `with` and
> `without` as the baseline. Run `npm run eval:lint` and report its output. Do not run the
> eval."*

**Walkthrough (full solution).**

> **What was run for this catalog.** Everything below: lint, dry run, and one real run of
> the experiment with `runs: 1` (four sessions), in a clean worktree that held the reference
> skill exactly as exercise 2 prints it and the two files of this exercise. With a
> differently worded skill your numbers will differ.

1. **Check the skill against the table.** *Mechanism: you.* Open
   `.github/skills/api-endpoint/SKILL.md` next to the table in the inline context and find
   the sentence behind each grader. Three of them are single lines that are easy to lose
   when Copilot rewrites the skill: the 204 for a delete, the path of the test file, and
   the backtick test names. If one is gone, put it back before you measure anything.

2. **Write the spec.** *Mechanism: the main session.* `evals/api-endpoint/eval.yaml`:

```yaml
name: api-endpoint
description: Does the api-endpoint skill make Copilot add an endpoint the way this project does?
type: capability
defaults:
  executor: copilot-sdk
  # One trial per stimulus keeps a first run cheap. Raise it to 3 or more before
  # you read anything into a difference between the variants.
  runs: 1
  timeout: 5m
# Only application source is staged. No .github/ and no existing controller test,
# so the skill under test is the only place the conventions can come from.
agent_environment:
  skills:
    - ../../.github/skills/api-endpoint
  files:
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
    - src: ../../api/build.gradle.kts
      dest: api/build.gradle.kts
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
stimuli:
  - name: delete-game-endpoint
    prompt: >-
      Add a REST endpoint that deletes a game, with its tests. Follow this project's API
      conventions. This workspace has no build tool, so do not try to compile or run anything.
    tags:
      control: positive
      suite: smoke
    graders:
      - type: completed
      # The route follows the resource: DELETE on the game itself.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
          pattern: '@DeleteMapping\("/\{id\}"\)'
      # A delete answers 204.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
          pattern: 'NO_CONTENT|noContent\(\)'
      # The controller stays thin: the service owns the storage.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
          pattern: 'boards\.remove\('
      # The endpoint ships with a controller test, where the project keeps them.
      - type: file-exists
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
      # Spring Boot 4 test stack.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'MockMvcTester'
      # Test name is a plain-English sentence in backticks.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'fun `[^`]+`\(\)'
      # The unknown-game case is tested against the structured error code.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'GAME_NOT_FOUND'
  - name: unrelated-question
    prompt: >-
      In two sentences, what does Board.spawnRandom return and when does it return false?
      Answer in chat only; do not create or change any file.
    tags:
      control: negative
      suite: smoke
    graders:
      - type: completed
      # A skill that fires on everything costs context for nothing.
      - type: skill-invocation
        config:
          disallowed: [api-endpoint]
      - type: output-matches
        config:
          pattern: '(?i)full|empty'
      - type: diff-empty
scoring:
  threshold: 1
```

   Reading it as a reviewer:

   - The positive prompt says what a user would say. It does not name the skill and does
     not list the conventions; "follow this project's API conventions" is all the help the
     baseline gets.
   - "No build tool" is there because nothing but source is staged. Without that sentence
     the agent spends its turns looking for a Gradle wrapper.
   - The patterns are loose where two correct answers exist (`NO_CONTENT|noContent\(\)`)
     and strict where the convention is the point (`MockMvcTester`).
   - The negative control guards the description. A skill that loads for every question
     about the code passes the positive case and still costs context on each turn.
   - `threshold: 1` means every grader must pass. One missed convention fails the trial.

3. **Write the experiment.** `evals/experiments/api-endpoint-ab.experiment.yaml`:

```yaml
name: api-endpoint-ab
evals:
  - ../api-endpoint/eval.yaml
matrix:
  skills:
    path: /environment/skills
    values:
      - without: []
      - with: ["../../.github/skills/api-endpoint"]
baseline:
  skills: without
```

   Paths in `values` are relative to the experiment file. `without: []` replaces the
   `skills` list of the spec with an empty one; `with` puts the skill back.

4. **Lint and dry-run.** *Mechanism: Vally, no model call.*

```bash
npm ci                                   # once, at the repository root
npm run eval:lint
npx --no vally lint .github/skills/api-endpoint
VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml \
  --output-dir evals/results --dry-run
```

   Run here:

```text
✔ evals/api-endpoint/eval.yaml is valid
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid

✅ api-endpoint (2/2 checks passed)
1 skill(s) linted, 1 passed

Experiment: api-endpoint-ab
Baseline:   skills=without
Plans:      2

── skills=without (baseline) ──
  Eval:        api-endpoint
  File:        ../api-endpoint/eval.yaml
  Model:       (unset)
  Config hash: 37dca6240065c336
  Eval hash:   76334ef3a03ae1a5

── skills=with ──
  Eval:        api-endpoint
  File:        ../api-endpoint/eval.yaml
  Model:       (unset)
  Config hash: 422626e8c5067705
  Eval hash:   76334ef3a03ae1a5
```

   Two plans, the same eval hash, different config hashes: the variants differ in the
   environment and in nothing else. Do not expect these exact hash values on your machine.

5. **Run it.** *Mechanism: Vally, four real sessions (2 variants × 2 stimuli × `runs: 1`).*

```bash
VALLY_TELEMETRY_OPTOUT=1 EVALUATE_USE_HOST_COPILOT_HOME=1 \
  npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml --output-dir evals/results
```

   Run here, once (Copilot CLI 1.0.114, Vally 0.21.0, model chosen by `auto`; console
   output abridged):

```text
skills=without
  FAIL  delete-game-endpoint · 7/8 graders · 47.3s
   ✘ file-matches api/src/test/… /MockMvcTester/  Pattern /MockMvcTester/ not found in any file
   · score 87.5% < threshold 100.0% · trial 1

  → skills=with beat baseline — 2/2 vs 1/2 stimuli.
    skills=with used +1% tokens, +17% trial time.

  eval          skills=without (baseline)   skills=with                Δ
  api-endpoint  ✘ 1/2 (score 93.8% < 100%)  ✓ 2/2 (score 100% ≥ 100%)  +1
  stimuli       1/2                         2/2                        +1
  tokens        168.8k                      170.9k                     +1%
  trial time    1m07s                       1m18s                      +17%
```

   Per trial, from `report.md`:

   | Stimulus | `skills=without` (baseline) | `skills=with` |
   |---|---|---|
   | `delete-game-endpoint` | ✘ 7/8 graders · 47.3s · 117,321 tokens · 13 tool calls | ✓ 8/8 graders · 1m 01s · 119,197 tokens · 14 tool calls |
   | `unrelated-question` | ✓ 4/4 graders · 18.7s · 51,450 tokens · 2 tool calls | ✓ 4/4 graders · 15.9s · 51,667 tokens · 3 tool calls |

6. **Read the report.** *Mechanism: you.* `evals/results/<timestamp>/report.md` has one table
   per variant. Each trial folder holds `events.jsonl` (what the agent did) and
   `workspace.patch` (what it wrote). What this run says, and what it does not:

   - **Positive case.** With the skill all 8 graders passed. Without it 7 of 8 passed. The
     baseline did write a controller test at the right path with backtick names and a
     `GAME_NOT_FOUND` case, and it answered the delete with 204; its `workspace.patch` shows
     the classic `MockMvc` with `MockMvcBuilders` instead of `MockMvcTester`. So on this
     trial the skill bought one thing, the Boot 4 test stack. The other six conventions the
     model inferred from the staged source, including the three the skill spells out for
     this eval.
   - **Negative control.** Passed in both variants: 4 of 4 graders, no skill invocation, no
     file touched.
   - **It is one trial per cell.** "1 of 1 against 0 of 1" is an anecdote. The token and time
     differences come from a single pair of sessions and mean nothing yet: an earlier run of
     this spec with a differently worded skill showed −13 % tokens and −16 % time for the
     skill, this one +1 % and +17 %. Set `runs: 3` or more and rerun before you tell anyone
     that the skill helps, and before you say anything about its cost.
   - **How the skill reached the model.** In the passing trial `events.jsonl` contains no
     `skill` tool call. Vally copied the skill folder into the trial workspace and the model
     read `api-endpoint/SKILL.md` with `view` while exploring. The run therefore shows that
     the skill's *content* helps, not that its *description* triggers. To test the trigger,
     the Vally docs give the `skill-invocation` grader a `required` list next to
     `disallowed` (not run here; on this trial `required: [api-endpoint]` would have failed).
   - **Nothing escaped.** Trials are not sandboxed, so check. Here every write of all four
     trials went to its own `vally-eval-*` folder in the system temp directory, which Vally
     removed afterwards; `git status --short` showed the same files before and after, and
     only `evals/results/` (gitignored) was new. With `EVALUATE_USE_HOST_COPILOT_HOME=1`
     your personal skills are visible to the trials too; none was invoked in this run.

   When a trial fails, open its `workspace.patch` before you touch the skill. The agent may
   be wrong, or the grader may be: a correct answer that your pattern did not foresee is a
   grader bug.

**Done check.**

```bash
npm run eval:lint
VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml \
  --output-dir evals/results --dry-run
VALLY_TELEMETRY_OPTOUT=1 EVALUATE_USE_HOST_COPILOT_HOME=1 \
  npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml --output-dir evals/results
git status --short
```

Expected: `✔ evals/api-endpoint/eval.yaml is valid` among the lint lines; the dry run prints
`Plans:      2` with `skills=without (baseline)` and `skills=with`; the real run (four
sessions) ends with the comparison table and leaves `evals/results/<timestamp>/report.md`;
`git status --short` lists only the files you created for this exercise. A run in which
the baseline also passes everything is a valid result: it tells you the skill is not earning
its place for that task, or that your graders check what the model does anyway.

---

## Bonus (web) 🟡 — a bug nobody planted

**Layers:** web

**Goal.** Reproduce a real race condition in the UI with a failing test, then fix it. Press
two direction keys in quick succession and the board can end up showing an older state than
the server holds.

**Mechanism it teaches.** None in particular; this is the level 5 loop from
[guide 10](10-level-5-workflow.md) on a bug with no prepared answer in the instructions:
describe the symptom, make Copilot prove it with a test, then fix.

**Files.** `web/src/App.tsx` (changed), `web/src/App.test.tsx` (new).

**Inline context.**

- `App.tsx` sends one request per key press and calls `setGame` with whatever comes back.
  Two requests in flight can answer in either order. The server applied both moves, but the
  response that arrives last wins on screen, and that can be the older one.
- It was found by driving the app with an automated browser that pressed two keys about a
  millisecond apart. At human speed it is rare, which is why no test had caught it.
- The server is right; do not touch `api/`. The fix belongs in the client.
- The cheapest correct fix is to allow one move in flight at a time and ignore key presses
  until it returns. Applying responses "latest request wins" is not correct here: the later
  request is not necessarily the one the server processed last.

**Starter prompt.**

> *"Pressing two arrow keys almost at the same time can leave the board showing a stale
> state: the server has applied both moves, the screen shows only the first. Find the cause
> in `web/src`. Do not fix anything yet. Write a test in `web/src/App.test.tsx` that fails
> because of it, mocking `./api`, and run it to show me the failure."*

**Walkthrough (full solution).**

1. **The failing test first.** *Mechanism: none; the prompt asks for evidence before a fix.*
   The test mocks the API client, leaves the first move unanswered, presses a second key and
   asserts that only one request went out.

```tsx
import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    // Never resolves: the first move stays in flight for the whole test.
    vi.mocked(move).mockReturnValue(new Promise<Game>(() => {}))
  })

  it('ignores a key press while the previous move is still in flight', async () => {
    render(<App />)
    await screen.findByRole('grid')

    fireEvent.keyDown(window, { key: 'ArrowLeft' })
    fireEvent.keyDown(window, { key: 'ArrowDown' })

    expect(move).toHaveBeenCalledTimes(1)
  })
})
```

   On a clean `main` it fails with `expected "vi.fn()" to be called 1 times, but got 2 times`.

2. **The fix.**

   > *"Now fix it in `App.tsx`: only one move may be in flight at a time; ignore direction
   > keys until it returns, on success and on failure. Keep `preventDefault` for direction
   > keys even while a move is in flight, so the page does not scroll. Run the web tests, lint
   > and build."*

```diff
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -1,4 +1,4 @@
-import { useCallback, useEffect, useState } from 'react'
+import { useCallback, useEffect, useRef, useState } from 'react'
 import { createGame, move } from './api'
 import type { Game } from './api'
 import { Board } from './Board'
@@ -17,6 +17,8 @@ function messageOf(error: unknown): string {
 export function App() {
   const [game, setGame] = useState<Game | null>(null)
   const [error, setError] = useState<string | null>(null)
+  // Responses can arrive out of order, so only one move is in flight at a time.
+  const isMoveInFlight = useRef(false)
 
   const startGame = useCallback(() => {
     createGame()
@@ -43,9 +45,16 @@ export function App() {
       }
       // Arrow keys would otherwise scroll the page.
       event.preventDefault()
+      if (isMoveInFlight.current) {
+        return
+      }
+      isMoveInFlight.current = true
       move(game.id, direction)
         .then(setGame)
         .catch((cause: unknown) => setError(messageOf(cause)))
+        .finally(() => {
+          isMoveInFlight.current = false
+        })
     }
 
     window.addEventListener('keydown', onKeyDown)
```

   A ref and not state: the flag must not trigger a render, and the key handler has to read
   its current value, not the one captured when the effect ran.

3. **Review.** Ask the `kotlin-reviewer` agent to review the uncommitted change; despite its
   name it also reviews TypeScript (its checklist includes effects without cleanup).

**Done check.**

```bash
cd web && npm test && npm run lint && npm run build
```

Expected: `Tests  8 passed (8)` in 3 files (7 existing + 1 new), lint prints nothing, the
build ends with `✓ built in`. The reference solution was built and tested for this catalog;
the prompts were not replayed through Copilot.

---

Pick an exercise, paste its starter prompt, and build it. Each one leaves you with a working
feature and a mechanism you have driven yourself.

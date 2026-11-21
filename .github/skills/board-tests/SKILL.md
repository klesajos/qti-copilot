---
name: board-tests
description: Use when writing or extending JUnit tests for the 2048 board logic (slideLineLeft, Board.move, win and game-over detection). Covers the project's test conventions and how to run the suite.
---

# Writing board tests

All game rules live in `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt` and are free
of I/O, which is what makes them unit-testable. Tests go in
`engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` (JUnit Jupiter).

## Conventions

- One `@Test` per behaviour, named in backticks with a plain-English sentence describing the
  scenario, e.g. `` fun `two separate pairs merge into two tiles`() ``.
- Arrange-Act-Assert, separated by blank lines: build the state, perform one action, then assert.
- Prefer testing the top-level function `slideLineLeft()` for merge rules. It is the heart of
  the game and takes a plain `IntArray`.
- For whole-board behaviour use the `boardOf(...)` helper, which calls the deterministic
  constructor `Board(grid, score)`. It spawns no random tiles.
- Never test rules through `GameService`, the controller or the web UI; rules belong to `Board`.
- Reuse the `slid()` helper when the score gained is irrelevant; call `slideLineLeft()` directly
  when asserting the score.
- Use `assertEquals(expected, actual)` with the expected value first.

## Key API

```kotlin
fun slideLineLeft(line: IntArray): Int          // mutates the line, returns score gained
Board(grid: List<List<Int>>, score: Int = 0)    // deterministic, for tests
fun Board.move(direction: Direction): Boolean   // true if the board changed
fun Board.isGameOver(): Boolean
fun Board.hasWon(): Boolean                     // any tile >= Board.WIN_VALUE
```

## Running the tests

```bash
./gradlew :engine:test
```

After adding a test, always run the suite before declaring it done. If a correct test fails
because the production code is wrong, keep the assertion and report the bug.

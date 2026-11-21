---
applyTo: "engine/**/*.kt"
---

# Engine rules

- `Board` stays free of I/O: no printing, no file or network access, no Spring imports.
- Randomness enters only through the `Random` passed to `Board`; never call `Random.Default` inside a rule.
- Keep `slideLineLeft()` a top-level function. It is the unit the merge rules are tested through.
- Every change to a rule needs a deterministic test built with `Board(grid, score)`, which spawns no tiles.
- A tile may merge at most once per move.
- Run `./gradlew :engine:test` after the change and report the pass and fail counts.

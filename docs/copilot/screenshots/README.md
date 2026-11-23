# Workshop dry run, 2026-11-23

One participant run of the workshop from a fresh clone at `~/qti-copilot` on macOS (Apple
silicon, Node 26.13, Homebrew OpenJDK 27) with Copilot CLI 1.0.114, model "Copilot Fusion" (it
picked MAI Code 2 Flash and GPT-5.6 Luna). Every exercise started from a clean `main` with
`scripts/copilot-ws.sh`, the prompts were pasted from [exercises.md](../exercises.md) and every
approval prompt was answered with **1. Yes**. Exercise 7 and `npm run eval:ab` were not run. In
exercise 4 no issue and no pull request were created; the spec came from `solutions/ex4-issue.md`.
The whole run used roughly 10–13 AI credits (0.2–2.3 per session).

## Results

| Exercise | Result | Screenshots |
|---|---|---|
| Setup check | without a JDK on `PATH`: `MISS java`; after the guide 01 fix: everything `ok` | [JDK missing](setup-01-java-missing.png) · [all ok](setup-02-all-ok.png) |
| 0 · level-5 loop | passes: red on an assertion, then 6 passed | [folder trust](ex0-01-folder-trust.png) · [plan](ex0-02-plan-ready.png) · [edit prompt](ex0-03-update-file.png) · [red](ex0-04-red.png) · [green](ex0-05-green.png) · [/diff](ex0-06-diff.png) |
| 1 · instructions | passes: `web.instructions.md` discovered, 8 web tests, lint and build clean, no `style=` | [tile colours](ex1-01-tile-colours.png) |
| 2 · skill | passes: `skill(api-endpoint)` loaded unasked, 7 API tests | [delete endpoint](ex2-01-delete-endpoint.png) |
| 3 · hook | passes: script checks `exit=0` / `block` / warning / `exit=2`; the live gate sent the Vitest failure back | [gate](ex3-01-gate-sent-back.png) · [/diff](ex3-02-diff.png) |
| 4 · MCP | passes: `tools (2)`, `list_issues` works, `bestScore` is `0` | [MCP tools](ex4-01-mcp-tools.png) · [criteria](ex4-02-criteria.png) · [implemented](ex4-03-implemented.png) |
| 5 · agents | passes: both agents in order, 2 of 15 red, then 15 of 15; full reviewer report, no Blocker | [agents, red](ex5-01-agents-red.png) · [fix and review](ex5-02-fix-and-review.png) |
| 6 · plugin | passes: v1.1.0, `/2048-dev:run-local` answers both commands and ports | [suggestions](ex6-01-slash-suggestions.png) · [answer](ex6-02-run-local-answer.png) |
| 8 · eval | passes: lint, dry run with one eval hash in both plans | [lint](ex8-01-eval-lint.png) · [loosened](ex8-02-loosened.png) |
| Bonus | passes: red on "called 2 times", then 8 passed, lint and build | [red](bonus-01-red.png) · [green](bonus-02-green.png) |

## Fixed after the first run (2026-11-22), confirmed here

- `check-setup.sh` no longer reports the macOS `java` stub as ok.
- Guide 01 and [prep.md](../prep.md) put a JDK on `PATH` on macOS; Copilot no longer searches
  outside the repository for one.
- Exercise 3: "Do not change any test." in the prompt; the gate now fires.
- Exercise 5: "show me its report word for word"; the Blocker, Should-fix and Nit sections arrive.
- `block-destructive.sh` lets a `/tmp/<name>` path or a `mktemp` variable of the same command go;
  no cleanup was denied in this run.

## Fixed after this run

- **Exercise 0:** the plan menu now lists **Accept plan and continue** first; *Exit to Interactive
  execution mode* is option 3. The guide named it option 1, which would have run the whole plan
  without stopping at red. The step now names it by its label.
- **Exercise 3:** the hook Copilot wrote checked `stop_hook_active` before the tests, so it warned
  on a green stop too. The prompt now says "when it is true and the tests still fail".
- **Exercise 8:** the loosen prompt relaxed whitespace but kept `intArrayOf(8, 8, 0, 0)`, which
  the skill does not prescribe; a correct `listOf` test would fail. The prompt now also names calls
  the skill does not prescribe.

## Still open

1. **Exercise 1:** Copilot ran `npm test`, `npm run lint` and `npm run build` at the repository
   root first (no such scripts there), then retried in `web/`. Same in both runs.
2. **Exercise 1:** no helper module next to `Board.tsx`; the class name is built inline
   (`tile-${value}`), which the rules allow. Same in both runs.
3. **Exercise 0:** besides the edits, Copilot asked to run two `grep | sed | awk` commands that
   count test results. The guide mentions only the edit prompts.
4. **npm 12 on Node 26** holds back install scripts for `koffi` and `@vscode/deviceid` (Vally) and
   `fsevents`. Lint and dry run work; `eval:ab` is untested.

All 11 solution patches apply to a clean `main` and reproduce the documented test counts; the
exercise 7 benchmark reproduces `monotonic` 3047.5 (checked in the first run).

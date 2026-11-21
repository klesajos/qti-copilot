> 🌍 Read this in: **English** | [Česky](01-custom-instructions.cs.md)

# Example 1: Custom instructions

## What are custom instructions?

**Custom instructions** are Markdown files Copilot reads as standing orders
for a repository. There are three kinds, and they differ in *when* they reach
the model:

- `.github/copilot-instructions.md` is **repo-wide**. It is part of every
  session from the first prompt. Keep it short: stack, layout, conventions,
  commands.
- `.github/instructions/**/*.instructions.md` with an `applyTo:` glob is
  **path-scoped**. Its body is not in the session until Copilot reads or edits
  a file that matches the glob. Then it is delivered.
- `AGENTS.md` is the **cross-tool** file other coding agents read too. Per
  the docs Copilot CLI looks for it in the repository root, the working
  directory, the directories between them, and the directories on the path of
  a file it is working on. A nested `web/AGENTS.md` is therefore picked up for
  work under `web/`. This repo has no `AGENTS.md`.

All of them are **merged**. Per the docs the CLI defines no precedence between
instruction files and only drops identical duplicates, so `AGENTS.md` does not
replace `copilot-instructions.md`; it is added to it. Two files that disagree
both reach the model. Do not write conflicting rules and expect the "nearer"
one to win. (That rule is documented for GitHub.com, not for the CLI.)

Your personal instructions live in `~/.copilot/copilot-instructions.md` and
are merged in as well.

## What this example does

The repo ships one repo-wide file and two path-scoped ones. The repo-wide file
says what is true for every task. The two scoped files carry the rules that
matter only when someone touches the game rules or the REST layer. A
participant working in `web/` never pays the context cost of the engine rules.

Tested on 1.0.114: in a fresh session Copilot could quote the "Conventions"
section of the repo-wide file and said the "Engine rules" section was not in
its context. After it opened `Board.kt` with the `view` tool, it quoted the
first engine rule word for word.

## The files, line by line

```
.github/
├── copilot-instructions.md        ← repo-wide; in every session
└── instructions/                  ← path-scoped files, searched recursively
    ├── engine.instructions.md     ← applyTo: "engine/**/*.kt"
    └── api.instructions.md        ← applyTo: "api/**/*.kt"
```

The file name of a scoped file is free. The `.instructions.md` suffix and the
`.github/instructions/` location are what make it one.

### `.github/copilot-instructions.md`

It has no frontmatter; it is plain Markdown, 49 lines. Section by section:

- **`# 2048` and one sentence.** What the repository is. Without it the model
  infers the purpose from file names.
- **`## Stack`.** One line per module with *versions*: Kotlin 2.4 and JUnit 6
  in `engine/`, Spring Boot 4.2 with Jackson 3 in `api/`, React 19 with
  TypeScript 6 on Vite 8 in `web/`. The line for `engine/` ends with "No I/O,
  no Spring", which is a rule disguised as a description.
- **The Spring Boot 4 paragraph.** A positive list and a negative list:

  ```markdown
  This is Spring Boot **4**, not 3. Use `spring-boot-starter-webmvc`, Jackson 3 packages
  (`tools.jackson.*`), `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`,
  `MockMvcTester` and `@MockitoBean`. Do not generate Boot 3 idioms (`@MockBean`,
  `com.fasterxml.jackson.*` imports, `TestRestTemplate`).
  ```

  The next section explains why this paragraph exists.
- **`## Directory structure`.** Four lines, one per place where code lives.
  It saves the search Copilot would otherwise run at the start of each task.
- **`## Conventions`.** Six bullets. The first is the architecture in one
  line: rules in `engine`, orchestration in `api`, rendering in `web`. The
  REST bullet fixes the response envelope (`{ "data": ... }` and
  `{ "error": { "code", "message" } }`), so every generated endpoint looks
  the same.
- **`## Commands`.** The exact build, run and test commands. Copilot runs what
  is written here instead of guessing between `./gradlew test` and
  `gradle test`.
- **The last line.** "After changing code, run the tests for the part you
  touched and report the result." One sentence of process, placed last.

### `.github/instructions/engine.instructions.md`

```markdown
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
```

- `---` opens and closes the frontmatter. It must be the first line.
- `applyTo:` is a glob relative to the repository root. `engine/**/*.kt`
  matches the production file and the test file, so the rules arrive for
  both.
- The heading is for you and for the model: it is how you ask "is the section
  *Engine rules* in your context?" when you debug loading.
- Bullets 1–3 protect the design that makes the engine testable.
- Bullet 4 names the constructor to test with. It is the same convention the
  `board-tests` skill teaches ([Example 2](02-skills.md)); the instruction
  states the rule, the skill explains how.
- Bullet 5, "a tile may merge at most once per move", is the specification
  the current code violates (deliberate bug 1). An instruction file states
  the intended behaviour. It is what lets Copilot call a failing test a bug
  instead of "fixing" the test.
- Bullet 6 is the scoped version of the repo-wide last line: the exact
  command for this module.

### `.github/instructions/api.instructions.md`

```markdown
---
applyTo: "api/**/*.kt"
---

# API rules

- Controllers stay thin: parse the request, call `GameService`, wrap the result in `ApiResponse`.
- New failure cases get their own exception and a handler in `ApiExceptionHandler` that returns
  `ErrorResponse` with a stable `code`. Write the message yourself; do not pass exception text through.
- Validate input at the boundary. Path and body values that cannot be parsed answer 400, not 500.
- Do not put game rules here. If a move needs a new rule, it belongs in `engine`.
- Controller tests use `@WebMvcTest` with `MockMvcTester` and assert on the JSON body, not on Kotlin objects.
- Run `./gradlew :api:test` after the change and report the pass and fail counts.
```

Same shape. Note what it names: real classes in this codebase
(`GameService`, `ApiResponse`, `ApiExceptionHandler`, `ErrorResponse`). A rule
that points at an existing symbol gets followed; "handle errors properly"
does not.

## Why this repo names Spring Boot 4, Jackson 3 and JUnit 6

A model tends to write what it has seen most. For Spring that is Boot 3, and
most of the differences are ones the compiler rejects:

| The model's habit | What this build needs |
|-------------------|-----------------------|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` |
| `import com.fasterxml.jackson...` | `tools.jackson.*` (Jackson 3 is Boot 4's default) |
| `@MockBean` | `@MockitoBean` from Spring Framework |
| `@WebMvcTest` from the old package | `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` |
| `TestRestTemplate` | `MockMvcTester` here; Boot 4.2 deprecates `TestRestTemplate` support |
| JUnit 5 | JUnit Jupiter 6.1.3, which Boot 4.2 manages. `engine/` has no Boot BOM and pins `junit-bom:6.1.3` itself |

Without the paragraph Copilot can still get there: it generates the Boot 3
form, the build fails, it reads the error and corrects itself. That loop costs
a turn and usage each time, and one paragraph in the repo-wide file is meant
to remove it. (The reasoning behind the paragraph; the difference was not
measured in this repo.)

The rule of thumb for your own projects: **write down every place where your
stack differs from what was mainstream two years ago**, with the version
number and a "do not generate" list. Everything the model would get right
anyway does not need a line.

## When `applyTo` files are delivered

The body of a path-scoped file is not part of the system prompt. Per the docs
it is delivered when the agent reads or edits a matching file, and that is
what the test showed. In a `-p` run with `--output-format json` the moment is
visible as an event (wrapped and shortened here):

```json
{"type":"system.notification","data":{"content":"Discovered instruction: .github/instructions/engine.instructions.md",
  "kind":{"type":"instruction_discovered","sourcePath":".github/instructions/engine.instructions.md",
          "triggerFile":".../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt","triggerTool":"view"}}}
```

Two consequences:

- **A scoped rule cannot influence what happens before the first matching
  file is touched.** If Copilot drafts a plan from your prompt alone, the
  engine rules are not in it yet. Anything that must shape the plan belongs
  in the repo-wide file.
- **It costs nothing until then.** That is the reason to split: the repo-wide
  file is in the context of every model call of every session.

Syntax, per the docs: `applyTo` takes a glob string; several patterns go in
one string separated by commas (`"**/*.ts,**/*.tsx"`).

## See what loaded

Outside a session, without spending anything:

```bash
copilot instruction list --json
```

It lists `.github/copilot-instructions.md` and both scoped files. Each entry
has `id`, `label`, `location`, `type`, `sourcePath`, `defaultDisabled` and,
for a scoped file, `applyTo` (here `["engine/**/*.kt"]` and
`["api/**/*.kt"]`). If a scoped file shows no `applyTo` array, its frontmatter
has no usable `applyTo`.

Inside a session:

| Command | Use it for |
|---------|-----------|
| `/instructions` | The list of instruction files. You can switch one off for the session |
| `/env` | Everything loaded, instructions included, on one screen |
| `/context` | How many tokens the custom instructions take in the context window |

`copilot instruction list` shows what *would* load. To know whether a scoped
file *was* delivered, ask the model or look for `instruction_discovered` in
the JSON output.

## `/init`

`copilot init`, or `/init` inside a session, analyses the codebase with
read-only tools and writes or updates `.github/copilot-instructions.md`. Text
after `/init` steers what it writes. Use it to get a first draft for a repo
that has none, then cut the draft down. A generated file describes what the
code *is*. The valuable lines are the ones about what the code *must stay*,
and those you write yourself.

## Reload rules

Per the docs, edits to instruction files do **not** reach a running session.
Exit and resume it (`copilot --continue`), or start a new one (`/new`). Skills
and agents are more forgiving ([Example 2](02-skills.md)); instructions are
not.

## Create your own instruction file, step by step

A tests-only rule. (Exercise 1 has you write one for `web/`, so this one
covers the Kotlin tests.)

1. **Create the file** `.github/instructions/tests.instructions.md`:
   ```markdown
   ---
   applyTo: "engine/src/test/**/*.kt,api/src/test/**/*.kt"
   ---

   # Test rules

   - Never weaken or delete an assertion to make a test pass. If a correct test
     fails, keep it and report the failure as a bug in the code under test.
   - Do not add `@Disabled`. A test that cannot pass yet is a finding, not noise.
   - One behaviour per test. The test name says what the behaviour is.
   ```

2. **Check that it is discovered:**
   ```bash
   copilot instruction list --json
   ```
   The new entry must show both globs under `applyTo`.

3. **Start a new session.** A running one will not see the file.

4. **Check that it loads only when it should.** First ask:

   > *"Do not read any file. Is a section titled 'Test rules' in your context?"*

   The answer is no. Then:

   > *"Read engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt. Is a section titled 'Test rules' in your context now? Quote its first bullet."*

   Now it quotes the bullet. The same read also delivers the engine rules,
   because `BoardTest.kt` matches `engine/**/*.kt` too. Both apply; neither
   overrides the other.

5. **Commit it:**
   ```bash
   git add .github/instructions/tests.instructions.md
   git commit -m "Add path-scoped test rules"
   ```

The single-glob form is what this repo's two files use and what was tested
for delivery. The comma-separated form in step 1 is from the docs; on 1.0.114
`copilot instruction list --json` splits it into one glob per pattern (tested),
and step 2 is how you confirm that on your version. Delivery of a
comma-separated file was not tested.

## `applyTo` for your own stack

The mechanism is the same on every project; only the globs and the rules
change. Starting points, not tested here. Replace the bullets with what your
team actually enforces.

**Swift (iOS)**

```markdown
---
applyTo: "**/*.swift"
---

- New asynchronous code uses `async`/`await`. Do not add completion-handler APIs.
- UI state is updated on the main actor only.
- No force unwraps outside tests.
```

**Kotlin (Android)**

```markdown
---
applyTo: "app/src/main/**/*.kt"
---

- UI is Jetpack Compose. Do not create XML layouts or Fragments.
- Composables receive state and callbacks; they do not reach into repositories.
- Coroutines are launched from a ViewModel scope, never `GlobalScope`.
```

**Java (backend)**

```markdown
---
applyTo: "**/src/main/java/**/*.java"
---

- Constructor injection only. No field injection.
- DTOs are records. Entities never leave the service layer.
- Name the exact framework and JDK version here if it is not the one a model assumes.
```

One trap in a repository that holds a Kotlin backend and an Android app:
`**/*.kt` matches both. Scope by directory, as this repo does with `engine/`
and `api/`, not by file extension.

## Try the demo

Start a fresh session and ask:

> *"Read engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt. Is a section titled 'Engine rules' in your context? Quote its first bullet."*

Copilot quotes the I/O bullet. Start another fresh session and ask the same
question with "Do not read any file" in front. Now the answer is no, while the
"Conventions" section of the repo-wide file is still there.

## The Claude-file double-loading trap

Copilot CLI does not only read its own files. In a project it also loads
`CLAUDE.md`, `.claude/CLAUDE.md`, `GEMINI.md` and every file under
`.claude/rules/`, and it treats a `.claude/rules` file with a `paths:` key
like an `.instructions.md` file with `applyTo:`.

In a repository that serves both tools this means:

- `CLAUDE.md` and `.github/copilot-instructions.md` usually say the same thing
  in different words. They are not identical, so nothing is deduplicated.
  Copilot gets both, you pay for both, and where they differ the model picks.
- Rules written for Claude Code ("use the Edit tool", "delegate with the Task
  tool") arrive in Copilot's context, where they are noise or wrong.

This repo avoids the problem by having **no `CLAUDE.md` and no `.claude/`
directory**. In a repo that needs both tools:

1. Run `copilot instruction list` and read the list. It is the only reliable
   answer to "what does Copilot load here?"
2. Keep one source of truth and check the result with step 1. Per the docs
   `@path` imports work in `AGENTS.md`, `CLAUDE.md` and
   `copilot-instructions.md` (not inside `*.instructions.md`), so a
   tool-specific file can pull in a shared one. Whether the imported text is
   then counted once or twice is something to check on your version, not to
   assume.
3. For one session, switch a file off in `/instructions`, or start with
   `--no-custom-instructions` to see how Copilot behaves with none.

Your personal `~/.claude/` directory is not read. Personal instructions for
Copilot go in `~/.copilot/copilot-instructions.md`.

## Optional parameters

| Setting / key | Where | What it does |
|---------------|-------|--------------|
| `applyTo` | scoped file frontmatter | Glob, or several separated by commas. Makes the file path-scoped |
| `excludeAgent` | scoped file frontmatter | `"code-review"` or `"cloud-agent"`: hides the file from that surface. It does not affect the CLI (per the docs) |
| `@path/to/file` | inside `copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md` | Imports another file. Not expanded in `*.instructions.md` (per the docs) |
| `--no-custom-instructions` | launch flag | Loads no instruction files at all. Useful as the "without" arm of a comparison |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | environment | Extra directories to search, comma-separated |
| `include-custom-instructions: true` | custom agent frontmatter | A custom agent run as a subagent gets no repository instructions unless it sets this (per the docs). Both agents in `.github/agents/` set it |
| `/init [guidance]` | session | Generates or updates `.github/copilot-instructions.md` |

Length: the only published guidance is a best practice of about 1,000 lines
per file, from the code review docs. That is a ceiling, not a target. The
repo-wide file here has 49.

Reference: [Adding custom instructions for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions).

## Where it works: CLI, IntelliJ, cloud agent

| Platform | Works? | Notes |
|----------|--------|-------|
| **Copilot CLI** | ✅ Yes | Tested on 1.0.114: all three files load, scoped files are delivered on read |
| **IntelliJ plugin** | ✅ Yes | Per the plugin release notes: `copilot-instructions.md` since 1.5.42, `.instructions.md` since 1.5.53, `AGENTS.md` since 1.6.1. Nested `AGENTS.md` is a setting under Settings > GitHub Copilot > Customizations. Not tested here |
| **Cloud agent** | ✅ Yes | Per the docs it reads the repo-wide file, the scoped files and `AGENTS.md` from the repository. `excludeAgent: "cloud-agent"` keeps a file away from it |

Copilot code review on GitHub.com reads the same files, from the pull
request's head branch (per the docs). A change to an instruction file can
therefore be tried out in the pull request that introduces it.

## Troubleshooting

- **A scoped rule is ignored** → it is delivered only after Copilot reads or
  edits a matching file. Check the glob against the real path with
  `copilot instruction list --json`, then ask the model whether the section
  is in its context.
- **You edited a file and nothing changed** → instructions are read when the
  session starts. Use `/new`, or exit and run `copilot --continue`.
- **The file is missing from `copilot instruction list`** → the name must end
  in `.instructions.md` and the file must be under `.github/instructions/`.
- **Instructions seem to apply twice, or contradict each other** → a
  `CLAUDE.md`, `AGENTS.md` or `.claude/rules/` file is loading as well. The
  list shows every source.
- **A custom agent ignores the conventions** → it ran as a subagent without
  `include-custom-instructions: true`.
- **Copilot still writes `@MockBean`** → check that the repo-wide file loaded
  (`/instructions`) and that nobody started the session with
  `--no-custom-instructions`.

Next: [Example 2: Project-scoped skill](02-skills.md).

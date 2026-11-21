> 🌍 Read this in: **English** | [Česky](02-custom-instructions.cs.md)

# 02 · Custom instructions

> ⏱ 15 min (5 demo + 10 exercise 1) · Docs: [Adding custom instructions for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) · [Support per surface](https://docs.github.com/en/copilot/reference/custom-instructions-support) · Verified on Copilot CLI 1.0.114

## In short

**You need:** The CLI from [01](01-getting-started.md) and a text editor. For checking many repos at once: `jq`.

**What it is for:** Copilot starts every session knowing nothing about your project. Instruction files are the standing briefing it gets every time: the stack, the conventions, the commands, what not to do.

**Three uses that pay off most:**

1. Stop repeated mistakes once and for all: "Spring Boot 4, not 3", "use `MockMvcTester`", "no wildcard imports".
2. Give each part of the repo its own rules with `applyTo`, so Android rules load only when Copilot touches Android files.
3. Check what an existing repo with `CLAUDE.md`, `AGENTS.md` or Cursor rules really sends to Copilot (`scripts/instruction-audit.sh`).

## What are custom instructions?

Markdown files Copilot loads as standing orders. They differ in *when* they reach the model:

- `.github/copilot-instructions.md` is **repo-wide**: sent with every model call of every session.
- `.github/instructions/**/*.instructions.md` with an `applyTo:` glob is **path-scoped**: its body
  is injected only after Copilot reads or edits a matching file.
- `AGENTS.md` is the **cross-tool** file ([agents.md](https://agents.md/)). This repo has none.
- `~/.copilot/copilot-instructions.md` is **personal**. All loaded files are merged, none wins.

## What this example does

```
.github/
├── copilot-instructions.md        ← repo-wide, 49 lines: stack, layout, conventions, commands
└── instructions/                  ← searched recursively; the .instructions.md suffix is what counts
    ├── engine.instructions.md     ← applyTo: "engine/**/*.kt"
    └── api.instructions.md        ← applyTo: "api/**/*.kt"
```

The repo-wide file holds what is true for every task. The scoped files hold rules for the game
logic and the REST layer only, so a session working in `web/` never pays for them.

## The files, line by line

`.github/copilot-instructions.md` is plain Markdown without frontmatter. Two parts carry the weight:
- **The Spring Boot 4 paragraph** lists what to use (`tools.jackson.*`, `MockMvcTester`,
  `@MockitoBean`) and what not to generate (`@MockBean`, `com.fasterxml.jackson.*`). A model writes
  what it has seen most, which is Boot 3. Write down every place where your stack differs from the
  mainstream of two years ago: the version and a "do not generate" list. Skip the rest.
- **`## Commands`** has the exact build and test commands, so Copilot does not guess between them.

`.github/instructions/engine.instructions.md` is a frontmatter block plus six bullets:
- `applyTo: "engine/**/*.kt"` is a glob relative to the repository root. It matches the production
  file and the test file. Several patterns go in one string, separated by commas.
- "A tile may merge at most once per move" states the specification that the current code violates.
  That is what lets Copilot report a failing test as a bug instead of "fixing" the test.
- `api.instructions.md` names real symbols (`GameService`, `ApiExceptionHandler`). A rule that
  points at an existing symbol is followed; "handle errors properly" is not.
- A scoped body is not in the system prompt, so a plan drafted before the first matching file is
  touched does not know the rule. What must shape the plan belongs in the repo-wide file.

## Create your own, step by step

1. Create `.github/instructions/tests.instructions.md` (exercise 1 does the one for `web/`):
   ```markdown
   ---
   applyTo: "engine/src/test/**/*.kt,api/src/test/**/*.kt"
   ---
   # Test rules
   - Never weaken or delete an assertion to make a test pass. Report the failing test as a bug.
   ```
2. Check discovery, free and outside a session: `copilot instruction list --json` shows both globs.
3. Check delivery. The output names each injected file: `engine.instructions.md` and yours.
   ```bash
   copilot -p "Read engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt. Change no file." \
     --trust-folder --no-ask-user --output-format json \
     | jq -r 'select(.data.kind.type? == "instruction_discovered") | .data.kind.sourcePath'
   ```

> 🔷 **Copilot only:** `copilot instruction list --json` and the per-file switch in `/instructions`.
> Claude Code documents no JSON listing of loaded sources and no interactive per-file toggle.

## Try the demo

Start a fresh session with `scripts/copilot-ws.sh` and ask:

> *"Read engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt. Is a section titled 'Engine rules' in your context? Quote its first bullet. Change no file."*

Copilot answers yes and quotes "`Board` stays free of I/O: no printing, no file or network access,
no Spring imports." The timeline shows `● Discovered engine.instructions.md from .github/instructions/`.
A fresh session told "Do not read any file." first answers no.

**What it costs:** there is no static audit command. `copilot instruction list --json` shows what
loads, `/context` has the row `Custom Instructions` (760 tokens in this repo, before and after a scoped file was injected), and [`/chronicle improve`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle)
suggests edits to `.github/copilot-instructions.md` from this repo's sessions ⚠️ not run in this repo

## A repo that already has AI instructions

Most real repos already have some. First list what Copilot loads there, outside a session:

```bash
copilot instruction list --json | jq -r '.[] | [.location, .sourcePath, ((.applyTo // ["every session"]) | join(","))] | @tsv'
```

| File in the repo | Loaded by Copilot CLI 1.0.114 |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` in the root; nested ones when you start Copilot there | ✅ every session |
| `.claude/rules/*.md` | ✅ every session; with `paths:` scoped like `applyTo` |
| `.claude/skills/`, `.agents/skills/`, `.claude/agents/`, `.claude/commands/`, hooks in `.claude/settings.json` | ✅ the hooks run: read them first |
| `.claude/CLAUDE.md` (named in `copilot help config`), `.cursorrules`, `.cursor/rules/*.mdc`, `.windsurfrules`, personal `~/.claude/` | ❌ |

1. Everything loaded is merged and nothing wins. Near-duplicates are both sent, on every model call.
2. Keep one always-on file per repo. `AGENTS.md` is the cross-tool choice; move Cursor rules there.
3. Read the diff after `/init`: it writes `.github/copilot-instructions.md` next to what is there.
4. A/B the result: one session as it is, one started with `--no-custom-instructions`.
5. Many repos: `scripts/instruction-audit.sh <repo-dir>...` prints file, scope and bytes per repo.

> 🔷 **Copilot only:** Copilot CLI reads other tools' files live (`CLAUDE.md`, `GEMINI.md`, `.claude/`).
> Claude Code reads `AGENTS.md` and otherwise imports other tools' config once, with `/init` or `/import`.

## applyTo for your stack

| Stack | `applyTo` | Rules worth a line (starting points) |
|---|---|---|
| Java backend | `"**/src/main/java/**/*.java"` | constructor injection only; DTOs are records; exact framework and JDK version |
| Kotlin backend | `"api/**/*.kt"`: scope by directory, `**/*.kt` also matches Android and test modules | thin controllers; own exception per failure case (this repo) |
| React / TypeScript | `"web/src/**/*.ts,web/src/**/*.tsx"` | no `any`; named exports; how a component is tested (exercise 1) |
| Kotlin Android | `"app/src/main/**/*.kt"` | Compose only, no XML layouts; coroutines from a ViewModel scope |
| Swift iOS | `"**/*.swift"` | `async`/`await`, no completion handlers; UI state on the main actor; no force unwraps |
| Kotlin test automation | the test module, e.g. `"e2e/**/*.kt"` | wait on a condition, never sleep; selectors live in page objects; each test creates its own data |

## Optional parameters

| Setting | Where | What it does |
|---|---|---|
| `excludeAgent` | scoped file frontmatter | `"code-review"` or `"cloud-agent"`: hides the file from that surface, not from the CLI |
| `@path/to/file` | `copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md` | Includes another file of the repo. Not expanded in `*.instructions.md` or `GEMINI.md` |
| `/init [guidance]`, `copilot init` | session, terminal | Generates or updates `.github/copilot-instructions.md` |
| `--no-custom-instructions` | launch flag | Loads no instruction file: the "without" arm of a comparison |
| `include-custom-instructions: true` | custom agent frontmatter | A subagent gets the repo instructions only with this. `kotlin-reviewer` and `board-test-writer` set it |

Full reference: [Custom instructions locations](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-instructions-locations)

## Where it works

| File | CLI | IntelliJ plugin | Cloud agent |
|---|---|---|---|
| `.github/copilot-instructions.md`, `*.instructions.md` | ✅ | ✅ since 1.5.42; `applyTo` needs 1.5.62 | ✅ |
| `AGENTS.md`, `CLAUDE.md` | ✅ | ⚠️ since 1.6.1; nested files are a setting | ✅ |

## Copilot vs Claude Code

Claude Code: `CLAUDE.md`, `.claude/rules/*.md` with `paths:`, `/init`. Delivery on read or edit is
the same. Copilot merges every file it finds, Claude Code's included, so a repo that serves both
tools needs one source of truth. `excludeAgent` has no Claude Code counterpart.

## Troubleshooting

- **A scoped rule is ignored** → it arrives only after Copilot reads or edits a matching file.
- **You edited a file and nothing changed** → files load at session start: `/new` or `copilot --continue`.
- **The file is not in `copilot instruction list`** → name it `.github/instructions/<name>.instructions.md`.

Next: [03 · Skills](03-skills.md) · Exercise 1: [exercises.md](exercises.md)

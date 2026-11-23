> 🌍 Read this in: **English** | [Česky](README.cs.md)

# GitHub Copilot CLI workshop

> Verified on Copilot CLI 1.0.114 · Docs: [Customizing Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/overview) · [Comparing customization features](https://docs.github.com/en/copilot/concepts/customizations/comparing-customizations)

A hands-on workshop for Java, Kotlin, React/TypeScript, Android, iOS and test-automation developers
on a 2048 game: `engine/` (Kotlin rules), `api/` (Spring Boot), `web/` (React). The tool is Copilot CLI. You
generate code, you do not write it: level 5+ on the [VisiData scale](https://www.visidata.org/blog/2026/ai/),
where Copilot codes and you understand all of it. Sibling of the Claude Code workshop (`dxc-ws`).

## Agenda (4 h)

| Block | Min | Guide | How |
|-------|----:|-------|-----|
| Opening: level 5+, what is counted, the constraints | 5 | this page | talk |
| How LLMs and agents work; models, effort, credits, context | 20 | [00 · LLM basics](00-llm-basics.md) | talk, try `/model`, `/context`, `/usage` |
| Setup, first session, the level-5 loop | 20 | [01 · Getting started](01-getting-started.md) | setup check, exercise 0 |
| Custom instructions | 15 | [02 · Custom instructions](02-custom-instructions.md) | demo, exercise 1 |
| Skills | 20 | [03 · Skills](03-skills.md) | demo, exercise 2 |
| Hooks | 25 | [04 · Hooks](04-hooks.md) | demo, exercise 3 |
| **Break** | 10 | | |
| MCP under an allow-list | 10 | [05 · MCP](05-mcp.md) | demo (exercise 4) |
| Custom agents | 25 | [06 · Agents](06-agents.md) | demo, exercise 5 |
| Plugins and sharing across teams | 15 | [07 · Plugins](07-plugins.md) | demo, exercise 6 |
| Permissions and sandbox | 15 | [08 · Permissions and sandbox](08-permissions-sandbox.md) | demo, try |
| **Break** | 10 | | |
| Evals | 20 | [09 · Evals](09-evals.md) | demo, exercise 8 |
| Beyond one session: `/fleet`, `-p` and CI, Conductor | 15 | [10 · Orchestration](10-orchestration.md) | demo |
| IntelliJ IDEA, `/delegate`, `/remote`, Coder | 5 | [11 · IDE and remote](11-ide-remote.md) | talk |
| What only Copilot has; wrap-up | 10 | [12 · Copilot vs Claude Code](12-copilot-vs-claude.md) | talk |
| **Total** | **240** | | 220 content + 20 breaks |

If you run late, cut in this order: exercise 6 becomes a demo (−8), guide 11 becomes reading
(−5), guide 10 drops Conductor (−5), exercise 1 becomes a demo (−10).

All tasks are in [exercises.md](exercises.md). Each one starts from a clean `main` and none
depends on another.

## What you need

- **Nothing prepared in advance.** Setup is the first 10 minutes of block 01
  ([01 · Getting started](01-getting-started.md)): install Copilot CLI 1.0.114 or later, log in
  with your Copilot Business or Enterprise seat, clone, build. Windows: WSL 2, the hooks are bash.
  Five optional minutes the day before: [prep.md](prep.md) (`scripts/check-system.sh` checks the versions).
- **`scripts/check-setup.sh`** then shows in 20 seconds what works on your account. Organisation
  settings can switch off skills, hooks, plugins or MCP without an error; skip what is blocked.
- **No image input needed.** Some organisations disable it, so no guide or exercise uses a screenshot. Give the agent
  text instead: the failing test output, the DOM text from a test, the browser console log.
- **No third-party MCP server needed.** The workshop uses the built-in GitHub server and shows the
  pattern for a Jira server (`.mcp.json.example`), so it also works under an MCP allow-list.

## Five-minute demo

One terminal, repo root. Optional and not an agenda block: run it in place of the opening talk. Answer every approval prompt (`Update file`, a shell command, `Allow path access`) with **1. Yes**.
Afterwards restore the tree with `git restore engine/src/test`; `git status --short` must be empty.

1. **Instructions:** `copilot instruction list` prints the three instruction files the repo ships.
2. **Skill:** start `scripts/copilot-ws.sh`, trust the folder, ask *"Add a test for sliding the line 4, 4, 8, 0"*. The `skill` tool loads `board-tests` before any edit. The test expects `8, 8, 0, 0` and fails: the planted cascade-merge bug that exercise 5 fixes.
3. **Hook:** ask *"Run exactly this one shell command and report in one sentence what happened, quoting any message you received: cat .env"*. The call is refused with `Denied by preToolUse hook: protect-secrets hook: ...`. No `.env` file is needed: the hook judges the command text.
4. **MCP:** `/mcp list` shows `github-mcp-server` as connected. It is built in; the repo ships no MCP config.
5. **Agent:** ask *"Use the kotlin-reviewer agent to review my uncommitted changes."* You get a report grouped by severity (Blocker, Should-fix, Nit) on the test from step 2, sometimes with nothing in any group, and `git diff` stays the same: the agent has no edit tool.
6. **Plugin:** `/2048-dev:build-test` runs the build and the test suites and reports without fixing: here `./gradlew build` stops at the failing test from step 2; on a clean tree the report is `Tests: engine 13 passed/0 failed; API 5 passed/0 failed; web 7 passed/0 failed`. Nobody installed the plugin: `.github/copilot/settings.json` enabled it when you trusted the folder.

Not in the five minutes: orchestration (`/fleet` takes about two minutes, demo in [10](10-orchestration.md)),
permissions ([08](08-permissions-sandbox.md)) and evals ([09](09-evals.md)).

## Which mechanism when

- **Instructions:** what is true for every task in the repo (stack, layout, commands). Loaded
  into every session, so keep them short. Path-scoped files cost nothing until a matching file
  is read or edited.
- **Skill:** Copilot should know how to do something your way. The model decides when to load it.
- **Hook:** something must happen every time, whatever the model thinks: block, format, test.
- **MCP:** Copilot needs a capability it does not have, such as reading a Jira issue. Under an
  allow-list only approved servers.
- **Agent:** one self-contained task in its own context with its own tools, such as a reviewer
  that cannot edit.
- **Plugin:** a skill or agent should be shared across repos as one versioned package. This is
  how you share a tool with other teams.
- **Permissions:** pre-approve a repo's routine commands for one run and deny what must never
  run. The sandbox is the real boundary; rules and hooks are guard rails.
- **Eval:** you need evidence that a skill, agent or plugin changes the outcome before you ask a
  team to adopt it.
- **Orchestration:** the work splits into independent parts (`/fleet`), runs with nobody at the
  keyboard (`copilot -p`), or must run the same way every time (Conductor).

## Where it works

| Mechanism | CLI | IntelliJ plugin | Cloud agent |
|-----------|-----|-----------------|-------------|
| Instructions | ✅ | ✅ | ✅ |
| Skills | ✅ | ⚠️ agent mode, since plugin 1.10.0; which project folders it scans is not documented | ✅ |
| Hooks | ✅ | ⚠️ only `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred` are published; this repo also uses `sessionStart` and `agentStop` | ⚠️ same files; an `ask` decision becomes a deny |
| MCP (`.mcp.json`) | ✅ after folder trust, inside the organisation's policy | ⚠️ root `.mcp.json` since plugin 1.19.0 | ⚠️ configured per repository on GitHub.com |
| Custom agents | ✅ | ⚠️ reads `.github/agents/`; which frontmatter keys it honours is not documented | ✅ |
| Plugin enabled by repo settings | ✅ | ⚠️ separate plugin store; install it in the IDE | ✅ reads both keys from the committed settings |
| Permissions and sandbox | ✅ | ⚠️ launch flags belong to the terminal; the repo hooks are read | ⚠️ runs on GitHub: no launcher, no local sandbox; the repo hooks load |
| Evals | ✅ | ⚠️ no eval UI; run the npm scripts in the IDE terminal | ❌ |
| Orchestration | ✅ | ⚠️ in the IDE's terminal | ❌ `/delegate` hands over one task |

✅ works · ⚠️ works with limits · ❌ not available. The CLI column was run in this repo; the
other two come from GitHub's documentation and the [JetBrains plugin release notes](https://plugins.jetbrains.com/plugin/17718-github-copilot/versions) (plugin
1.21.1). The plugin bundles its own, older CLI runtime, and from plugin 1.20.0 its chat is not
counted as CLI usage.

## Take it to your stack

| Mechanism | Java backend | Kotlin backend | React / TypeScript | Android | iOS | Test automation |
|-----------|--------------|----------------|--------------------|---------|-----|-----------------|
| Scoped instructions (`applyTo`) | `**/src/main/java/**/*.java` | `api/**/*.kt` | `web/src/**/*.ts,web/src/**/*.tsx` | `app/src/main/**/*.kt` | `**/*.swift` | the test module, e.g. `e2e/**/*.kt` |
| First skill to write | add an endpoint | add an endpoint (exercise 2) | add a component with its test | add a screen: ViewModel, composable, unit test | add a view with its XCTest | add a scenario: page object, test data, tags |
| Launcher allow rule | `shell(./mvnw:*)` ⚠️ | `shell(./gradlew:*)` | `shell(npm test)`, `shell(npm run)` | `shell(./gradlew:*)` | `shell(xcodebuild:*)`, `shell(swift:*)` ⚠️ | `shell(./gradlew:*)` |
| `agentStop` test gate | unit tests of the changed module | unit tests of the changed module | `npm test` | JVM unit tests only, no emulator tests | `swift test`; a full `xcodebuild test` is too slow for every turn | one smoke tag; the full suite needs an environment |
| Read-only reviewer agent | copy `kotlin-reviewer.agent.md`, change the checklist | as shipped | same | same | same | same; checklist: flakiness, waits, test data |
| `/delegate` (cloud agent) | works | works | works | needs the Android SDK in `copilot-setup-steps.yml` | no macOS runners, so no `xcodebuild`; use a local session | the system under test must be reachable from the runner |

⚠️ not run in this repo; the rule follows the `shell(command:*)` syntax of
`copilot help permissions`. The cloud agent runs on Linux or Windows runners only:
[Customizing the agent environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment).
Most real repos already carry AI instructions: run `copilot instruction list` in yours
first and see what loads ([02](02-custom-instructions.md)).

## After the workshop

- [exercises.md](exercises.md), exercise 7: an auto-solver tournament with `/fleet`, with a
  Conductor variant. Bonus: the UI bug nobody planted.
- [cheatsheet.md](cheatsheet.md): flags, slash commands, models and effort, file locations,
  hook events and permission patterns on one page.
- [12 · Copilot vs Claude Code](12-copilot-vs-claude.md): what only Copilot has and what is only
  named differently, for everyone who did the Claude Code workshop.

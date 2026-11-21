> 🌍 Read this in: **English** | [Česky](03-skills.cs.md)

# 03 · Skills

> ⏱ 20 min (5 demo + 15 exercise 2) · Docs: [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) · [Agent skills](https://docs.github.com/en/copilot/concepts/customizations/agent-skills) · [Agent Skills specification](https://agentskills.io/specification) · Verified on Copilot CLI 1.0.114

## What is a skill?

A folder with a `SKILL.md`: instructions that are loaded **only when the task needs them**. The
instruction files of [guide 02](02-custom-instructions.md) are triggered by a session or a path. A
skill is triggered by the task: your request matches its description, or you type `/skill-name`.

Under the hood: at session start the model gets the name and description of every enabled skill,
nothing more. Loading is a tool call. The model calls the tool `skill` with the skill's name and
the CLI injects the body of `SKILL.md` into the conversation.

## What this example does

```
.github/skills/           ← project skills, committed with the repo
└── board-tests/          ← one folder per skill; scripts it uses go next to SKILL.md
    └── SKILL.md          ← must be named exactly SKILL.md
```

`board-tests` teaches Copilot how this project writes board tests: where they live, how they are
named, which helper builds a board, how to run the suite, what to do when a correct test fails.
Measured with and without it ([guide 09](09-evals.md)): the same test-writing task passed its
checks in 0 of 4 trials without the skill and in 3 of 4 with it, for 26–32 % more tokens and
51–67 % more time.

## The file, line by line

```yaml
---
name: board-tests
description: Use when writing or extending JUnit tests for the 2048 board logic (slideLineLeft, Board.move, win and game-over detection). Covers the project's test conventions and how to run the suite.
---
```

- `name` is what you type after the slash and what the model passes to the `skill` tool. At most
  64 characters; use lowercase with hyphens.
- `description` is the only part the model sees before it decides. This one is a trigger ("Use
  when ...") built from the words a developer types: `slideLineLeft`, `Board.move`, "game-over".
  At most 1,024 characters; a longer one stops the skill from loading.
- The body is a briefing: `## Conventions` (seven bullets, among them backtick test names and the
  `boardOf(...)` helper that spawns no random tiles), `## Key API` (five signatures, cheaper than
  letting Copilot open `Board.kt`) and `## Running the tests` (`./gradlew :engine:test`).
- The last sentence matters most: "If a correct test fails because the production code is wrong,
  keep the assertion and report the bug." Without it the cheapest way to a green run is to change
  the assertion. A correct test for the line `4, 4, 8, 0` fails today: that is the planted cascade-merge bug.

## Create your own, step by step

1. Create the folder, one per skill: `mkdir -p .github/skills/my-skill`
2. Create `.github/skills/my-skill/SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: Use when <the situation that should trigger it>. Covers <what it contains>.
   ---
   <A briefing for a new colleague: what to do, which files and APIs to use, how to verify the
   result, what to do when it fails.>
   ```
3. Load it with `/skills reload` in an open session. `copilot skill list` shows it under "Project skills".
4. Trigger it by hand: `/my-skill <your request>`. The timeline shows your command and then the
   tool calls. No line says that a skill was loaded.
5. Trigger it by description. Phrase the request as a colleague would, without the skill's name:
   ```bash
   copilot -p "<a read-only request that should trigger it>" --trust-folder --no-ask-user \
     --output-format json \
     | jq -c 'select(.type=="tool.execution_start" and .data.toolName=="skill") | .data.arguments'
   ```
   It prints `{"skill":"my-skill"}`. No output means the description did not match. Keep the
   request read-only: in `-p` mode a tool call that needs approval is denied.

Write the description around the user's situation, not the content: "Use when writing unit tests
for ..." triggers, "Information about tests" does not. Exercise 2 writes an `api-endpoint` skill.

Skills also load from `.agents/skills/` and `.claude/skills/` (project), `~/.copilot/skills/` and
`~/.agents/skills/` (personal) and plugins (`/2048-dev:build-test`, [guide 07](07-plugins.md)). On a
name clash the first location wins, `.github/skills/` before all of these. `~/.claude/skills/` is not read.

> 🔷 **Copilot only:** project skills load from `.github/skills/`, `.agents/skills/` and
> `.claude/skills/`, and `copilot skill add <file|URL|directory>` installs one. Claude Code's project
> location is `.claude/skills/` only, and it has no command that installs a skill from a file or URL.

## Try the demo

Start a fresh session with `scripts/copilot-ws.sh` and ask, without naming the skill:

> *"What are this project's conventions for board tests? Answer in five bullets. Do not create or change any file."*

The first tool call is `skill` with `board-tests`. The answer then lists what the skill says:
backtick test names, Arrange-Act-Assert, `slideLineLeft()` for merge rules, `boardOf(...)` for
whole boards.

**What it costs:** until the `skill` call, only its description. The descriptions of all enabled
skills are in every session; `/context` shows context use by category, per skill in experimental
mode. Count what competes with yours:
`copilot skill list --json | jq -r '[.[] | select(.enabled) | .description | length] | "\(length) skills, \(add) characters"'`

## Optional parameters

| Field or command | What it does |
|---|---|
| `allowed-tools` | Tools that run **without a prompt** while the skill is active. Pre-approval, not a whitelist: unlisted tools still work and still prompt. In a skill you did not write, `allowed-tools: shell` means any shell command unasked |
| `argument-hint` | Text shown in the skill picker, e.g. `"[test-name]"`. A hint only: write the request as prose after `/name` |
| `user-invocable: false` | Removes the `/name` command. Only the model can load the skill |
| `disable-model-invocation: true` | The model no longer loads the skill on its own. You start it with `/name` |
| `copilot skill add [--project] <file, URL or directory>` | Installs a skill. `--project` copies a file or URL into `.github/skills/` |
| `copilot skill disable <name>`, `enable <name>` | Switches one skill off or on |
| `/skills`, `/skills list`, `/skills info <name>`, `/skills reload` | The same inside a session. Bare `/skills` opens a manager: Enter on a row offers `Details` and `Disable`, the tab `Problems` lists load errors |
| `--dynamic-retrieval skills=on` | Launch flag: embeddings-based retrieval of skills. The choice is persisted; `skills=off` reverts it |

Full reference: [Skills reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference)

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|---|---|---|
| ✅ by description and by `/board-tests`, also in `-p` runs | ⚠️ agent mode, since plugin 1.10.0. Which project folders it scans is not documented | ✅ Copilot code review uses skills too |

## Copilot vs Claude Code

Claude Code: skills, in the same `SKILL.md` format (the open Agent Skills standard), kept in
`.claude/skills/`, which Copilot reads too. The Claude Code keys `model`, `context: fork` and
`paths` are not in the Copilot reference. Claude Code substitutes `$ARGUMENTS`; Copilot passes the
text after `/name` to the model as prose. Prompt files (`.github/prompts/*.prompt.md`) work in the
IDEs but not in Copilot CLI: there a skill takes their place.

## Troubleshooting

- **`/my-skill` is not found** → the path must be exactly `.github/skills/<name>/SKILL.md`. Then `/skills reload`.
- **Start-up prints `Failed to load 1 skill. Run /skills for more details.`** → `/skills`, tab `Problems`, or
  `copilot skill list`: `Skill description must be at most 1024 characters`. Shorten the description.
- **Listed but never triggers** → the description is vague, or too many skills compete. Call it with
  `/name`, run `copilot skill disable <name>` for what you do not need, keep descriptions short.
- **Copilot still asks before running Gradle** → a skill grants no permission. Use `scripts/copilot-ws.sh`.

Next: [04 · Hooks](04-hooks.md) · Exercise 2: [exercises.md](exercises.md)

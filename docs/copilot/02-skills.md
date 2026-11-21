> 🌍 Read this in: **English** | [Česky](02-skills.cs.md)

# Example 2: Project-scoped skill

## What is a skill?

A **skill** is a Markdown file with instructions for Copilot that is loaded
**only when the task needs it**. Compare it to the instruction files from
[Example 1](01-custom-instructions.md):

- `.github/copilot-instructions.md` is in **every** session. Keep it short.
- A skill is loaded **on demand**: when your request matches its description,
  or when you call it by name with `/skill-name`.

Under the hood: at session start the model gets a list of skill names and
descriptions, nothing more. Loading one is a tool call. The
model calls a tool named `skill` with the skill's name, and the CLI injects
the body of `SKILL.md` into the conversation. Until that call the body costs
nothing.

## What this example does

The skill `board-tests` teaches Copilot *how this project writes board tests*:
where they live, how they are named, which helper builds a board, how to run
the suite, and what to do when a correct test fails.

Whether that changes anything was measured ([Example 9](09-validate-eval.md)).
In a with/without comparison, the same test-writing task passed its checks in
0 of 4 trials without the skill and in 3 of 4 with it. Without the skill the
tests never used the `boardOf(` helper (4 of 4) and half of them had a
camelCase name instead of a sentence in backticks. The price: about 26–32 %
more tokens and 51–67 % more time with the skill loaded.

## The file, line by line

The skill lives at `.github/skills/board-tests/SKILL.md`. The path matters:

```
.github/              ← project-scoped Copilot config (committed to git)
└── skills/           ← all project skills live here
    └── board-tests/  ← one folder per skill
        └── SKILL.md  ← must be named exactly SKILL.md
```

The file starts with **frontmatter**, a YAML block between `---` lines:

```yaml
---
name: board-tests
description: Use when writing or extending JUnit tests for the 2048 board logic (slideLineLeft, Board.move, win and game-over detection). Covers the project's test conventions and how to run the suite.
---
```

- `name: board-tests` is the identifier: what you type after the slash and
  what the model passes to the `skill` tool. Per the docs it is required, at
  most 64 characters; lowercase with hyphens is the form every docs page
  accepts.
- `description:` is **the most important line**. It is the only part of the
  skill the model sees before deciding. This one is written as a trigger
  ("Use when writing or extending JUnit tests...") and contains the words a
  developer would type: `slideLineLeft`, `Board.move`, "game-over". Required,
  at most 1,024 characters (per the docs).

Everything below the frontmatter is the body, 39 lines here:

- **The opening paragraph** names the two files: where the rules are and where
  the tests go. Copilot does not have to search.
- **`## Conventions`**, seven bullets. One `@Test` per behaviour with a
  backtick sentence as the name. Arrange-Act-Assert separated by blank lines.
  Prefer `slideLineLeft()` for merge rules. Use `boardOf(...)` for
  whole-board behaviour, because it calls the constructor that spawns no
  random tiles. Never test rules through the service, the controller or the
  UI. When to use the `slid()` helper. Expected value first in `assertEquals`.
- **`## Key API`**, five signatures in a code block. This is cheaper than
  letting Copilot open `Board.kt` to find them, and it marks which constructor
  is the one for tests.
- **`## Running the tests`**: the one command, `./gradlew :engine:test`.
- **The last two sentences** are the ones that matter in the demo: "always
  run the suite before declaring it done", and "If a correct test fails
  because the production code is wrong, keep the assertion and report the
  bug." Without the second one, the cheapest way to a green run is to change
  the assertion.

A skill folder can hold more than `SKILL.md`. Per the docs, scripts and other
files in it are made available when the skill is invoked; refer to them from
the body.

## How a skill is triggered

**By the model.** Your request matches the description and the model calls
the tool. Tested: a prompt about writing a board test, which did not name the
skill, produced this in the JSON output of a `-p` run:

```json
{"type":"tool.execution_start","data":{"toolName":"skill","arguments":{"skill":"board-tests"}}}
```

There is no separate "skill invoked" event. A skill use is that tool call,
which is also what evals and scripts look for.

**By you.** Type `/board-tests`, alone or in front of a request. This works
in `-p` mode as well. Tested:

```bash
copilot -p "/board-tests Which helper builds a whole board without random tiles? Change no file." \
  --trust-folder --no-ask-user
```

The stream shows the same `skill` tool call and the answer names `boardOf(...)`.
Per the docs the slash name can also sit inside a sentence ("Use the
/board-tests skill to ...").

**Plugin skills** carry the plugin name in front, with a colon:
`/2048-dev:build-test` ([Example 6](06-plugins.md)).

On arguments: text after the slash name reached the model in the test above.
How `--option value` style arguments are passed is not documented, and an open
issue (github/copilot-cli#4548) reports them being dropped. `argument-hint`
only changes what the picker shows. Write the request as prose.

## `allowed-tools` is pre-approval, not a restriction

The name suggests a whitelist. It is not one. Per the docs, tools listed in
`allowed-tools` run **without a confirmation prompt** while the skill is
active; tools that are not listed still work and prompt as usual. The
documented example is `allowed-tools: shell`.

What follows from that:

- It cannot make a skill read-only. To limit what can be done, use a custom
  agent with a `tools` list ([Example 5](05-agents.md)) or a deny rule
  ([Example 8](08-permissions-sandbox.md)).
- `allowed-tools: shell` in a skill you did not write means "any shell command
  without asking" for as long as that skill is active. Read a skill before you
  install it.
- Whether a scoped rule such as `shell(./gradlew:*)` is accepted inside
  `SKILL.md` is not documented. Test it before you rely on it.

`board-tests` does not set the field. The Gradle run is approved by you, or in
advance by the launch flags in `scripts/copilot-ws.sh`
(`--allow-tool='shell(./gradlew:*)'`, tested).

## Create your own skill, step by step

1. **Create the folder.** In the repo root:
   ```bash
   mkdir -p .github/skills/my-skill
   ```
   Each skill needs its own folder. A `SKILL.md` placed directly in
   `.github/skills/` is not a skill (per the changelog it produces a warning).

2. **Create** `.github/skills/my-skill/SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: Use when <the situation that should trigger this skill>. Covers <what it contains>.
   ---

   # My skill

   <Instructions. Write them like a briefing for a new colleague: what to do,
   which files and APIs to use, how to verify the result, what to do when it
   fails.>
   ```

3. **Load it.** Per the docs `/skills reload` picks up a skill added during a
   session; a new session does it in any case.

4. **Check that it is there.** In a terminal:
   ```bash
   copilot skill list
   ```
   It must appear under "Project skills".

5. **Test the manual trigger:** type `/my-skill` followed by a request.

6. **Test the automatic trigger.** Phrase a request the way a colleague would,
   without the skill's name, and look for the tool call:
   ```bash
   copilot -p "<a request that should trigger it>" --trust-folder --no-ask-user \
     --output-format json \
     | jq -c 'select(.type=="tool.execution_start" and .data.toolName=="skill") | .data.arguments'
   ```
   An empty result means the description did not match. In `-p` mode a tool
   call that needs approval is denied, so keep the request read-only or add an
   `--allow-tool` rule.

7. **Commit it:**
   ```bash
   git add .github/skills/my-skill
   git commit -m "Add my-skill"
   ```
   Everyone who clones the repo now has it. Personal skills you do not want to
   share go in `~/.copilot/skills/` or `~/.agents/skills/`.

Writing the description is most of the work. Describe the *user's situation*,
not the content: "Use when writing unit tests for ..." triggers; "Information
about tests" does not. Put in the nouns people type. Keep it short, for the
reason given under Pitfalls.

## Try the demo

Ask Copilot:

> *"Add a test for sliding the line 4, 4, 8, 0"*

`BoardTest.kt` has a `TODO (participants)` for exactly this line. What to
watch (the middle steps vary with the model; the first and the last are the
point):

1. The `skill` tool is called with `board-tests` before any file is written.
2. Copilot opens `BoardTest.kt`. That read also delivers the engine rules from
   Example 1, including "A tile may merge at most once per move".
3. It writes one test with a backtick name that calls `slideLineLeft()` and
   expects `8, 8, 0, 0` with a score of 8.
4. It runs `./gradlew :engine:test`. You are asked to approve, unless you
   started the session with `scripts/copilot-ws.sh`.
5. **The test fails.** The code returns `16, 0, 0, 0` and a score of 24.

That is deliberate bug 1. `slideLineLeft()` does not advance its index after
a merge, so the freshly merged `8` merges again with the `8` next to it. The
skill told Copilot what to do now: keep the assertion and report the bug. If
it rewrites the expectation to `16, 0, 0, 0` instead, you have seen the
failure mode the skill's last sentence exists to prevent; say so and ask
again.

After the turn the `agentStop` hook reruns the tests and shows a warning that
they fail ([Example 3](03-hooks.md)). It is advisory; nothing loops.

Leave the failing test in place if you go on to the exercises. To undo it, run
`git restore engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` in
your own terminal.

## Skill directories

Per the docs, skills are loaded from these places, and for two skills with the
same name **the first one found wins**:

| Order | Location | Scope |
|-------|----------|-------|
| 1 | `.github/skills/` | project |
| 2 | `.agents/skills/` | project |
| 3 | `.claude/skills/` | project (Claude Code's location; read by Copilot too) |
| 4 | `.github/skills/` in parent directories | project |
| 5 | `~/.copilot/skills/`, `~/.agents/skills/` | personal |
| 6 | installed plugins | plugin |
| 7 | `COPILOT_SKILLS_DIRS`, `--add-dir` roots | custom |
| 8 | built-in, then organization or enterprise | remote |

So a project skill silently beats a plugin skill of the same name. That is why
the project skill here is `board-tests` and the plugin's is `build-test`. Your
personal `~/.claude/skills/` is not read.

## Pitfalls

**Many skills hide each other.** The list of skills the model sees has a
character budget, and open issues (github/copilot-cli#5488, #2314) report that
it is cut off without any prioritization. `copilot skill list` showing a skill
does not prove the model can see it. On the machine this repo was built on, a
session loaded 166 skills: this project's one, the plugin's one, three
built-in ones and 161 personal ones from `~/.agents/skills/`, with
descriptions adding up to about 47,000 characters. `board-tests` still
triggered there, which is one data point and no guarantee. If your skill does
not trigger and you have many personal ones:

- call it explicitly with `/board-tests`;
- switch off what you do not need: `copilot skill disable <name>`;
- keep every description short, yours included.

The 1.0.114 help also lists `--dynamic-retrieval skills=on|off`
(embeddings-based retrieval of skills). Not tested here.

**`disable-model-invocation: true` breaks more than it says.** The field is
meant for skills only you may start. An open issue (github/copilot-cli#4438)
reports that such a skill answers "Skill not found" from the `skill` tool in
`-p` mode, when it is named in prose, and when another skill calls it. Only a
`/name` typed in an interactive session works. A "manual-only" skill will
therefore fail in scripts, CI and evals. Not tested here; test before you
build on it.

**Personal skills leak into measurements.** In the eval runs a personal `tdd`
skill was invoked in the arm that was supposed to have no skill. What you have
installed privately changes how a shared skill behaves on your machine.

**A skill does not grant permissions.** Without `allowed-tools`, every command
in the body still prompts.

## Optional frontmatter parameters

`board-tests` uses only `name` and `description`. The full list, per the docs:

| Field | What it does |
|-------|--------------|
| `name` | Required. Identifier and slash name, max 64 characters |
| `description` | Required. The trigger text, max 1,024 characters |
| `argument-hint` | Free text shown in the skill picker, e.g. `"[test-name]"`. A hint only |
| `allowed-tools` | Tools that run without a prompt while the skill is active. String or YAML list; `"*"` means all |
| `user-invocable` | Default `true`. `false` removes the `/name` command; only the model can load it |
| `disable-model-invocation` | Default `false`. `true` stops the model loading it on its own. See Pitfalls |
| `license` | Optional licence note |

Claude Code keys such as `model`, `context: fork` and `paths` are not in the
Copilot reference. Do not rely on them.

Managing skills. The terminal commands are in the 1.0.114 help; the slash
subcommands are per the docs (the help describes `/skills` only as "Manage
skills"):

| Command | What it does |
|---------|--------------|
| `copilot skill list [--json]` | Skills grouped by source |
| `copilot skill add <file, URL or directory>` | Adds a skill; per the docs `--project` installs into `.github/skills/` |
| `copilot skill enable <name>` / `disable <name>` | Switches one on or off |
| `copilot skill remove <name>` | Removes a skill or a custom skill directory |
| `/skills` | The same management inside a session. Per the docs: `/skills list`, `/skills info NAME` (the changelog calls it `get`), `/skills reload` |

Reference: [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills).

## Where it works: CLI, IntelliJ, cloud agent

| Platform | Works? | Notes |
|----------|--------|-------|
| **Copilot CLI** | ✅ Yes | Tested on 1.0.114: loads as a project skill, triggers by description and by `/board-tests`, also in `-p` runs |
| **IntelliJ plugin** | ✅ Yes | Per the plugin release notes agent skills are generally available since 1.10.0. Which project folders the plugin scans is not stated in a JetBrains-specific source. Not tested here |
| **Cloud agent** | ✅ Yes | Per the docs. Copilot code review also uses relevant skills from the pull request's head branch |

## Troubleshooting

- **`/board-tests` is not found** → the file must be exactly
  `.github/skills/<name>/SKILL.md` (uppercase `SKILL.md`, its own folder).
  Check `copilot skill list`, then reload or start a new session.
- **The skill is listed but never triggers** → the description is too vague,
  or the list is crowded (see Pitfalls). Rewrite it around the user's
  situation and test with the `jq` one-liner above.
- **The skill triggers on unrelated questions** → the description is too
  broad. The eval in `evals/board-tests/` has a negative case for exactly
  this.
- **"Skill not found" in a `-p` run** → the skill sets
  `disable-model-invocation: true`.
- **Copilot still asks before running Gradle** → skills grant nothing. Start
  with `scripts/copilot-ws.sh`, or add `allowed-tools`.
- **No project skill loads at all, on any prompt** → a managed setting can
  block standalone repository skills (`strictPluginOnlyCustomization`), and
  `disabledSkills` can switch single ones off. See [preflight.md](preflight.md).
- **Two skills with one name** → the first location in the table above wins.
  Rename one.

Next: [Example 3: Hooks](03-hooks.md).

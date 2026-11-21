> 🌍 Read this in: **English** | [Česky](05-agents.cs.md)

# Example 5: Custom agents and delegation

## What is a custom agent?

A **custom agent** is a Markdown file with a frontmatter block and a prompt. It gives you
three things the main session does not have:

- **Its own context.** Run as a subagent, it works in a separate conversation and returns
  only its conclusion. The file reads, diffs and dead ends stay out of your main context.
- **Its own tools.** The `tools` list decides what it can call. A reviewer without an edit
  tool cannot call one, whatever the prompt says.
- **Its own prompt.** The body of the file is its system prompt: role, scope, output format.

A skill ([Example 2](02-skills.md)) loads instructions *into* the current conversation. An
agent is *who* a task is handed to. The main agent hands tasks over with a tool named `task`.

## What this example does

The repo ships three agents that cover the range:

| Agent | File | `tools` | Why it is here |
|-------|------|---------|----------------|
| `board-test-writer` | `.github/agents/board-test-writer.agent.md` | `read`, `search`, `edit`, `execute` | Write-capable. Adds tests, runs Gradle, reports bugs instead of hiding them |
| `kotlin-reviewer` | `.github/agents/kotlin-reviewer.agent.md` | `read`, `search`, `execute` | No edit tool, but a shell for `git diff`. Shows what a tool list does and does not guarantee |
| `game-explorer` | `plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md` | `read`, `search` | Plugin-bundled (Example 6). Read and search only. Addressed as `2048-dev:game-explorer` |

All three load with no warnings on CLI 1.0.114.

## The files, line by line

```
.github/agents/                       ← project agents, committed
├── board-test-writer.agent.md
└── kotlin-reviewer.agent.md
plugins/2048-dev/com.github.copilot/agents/
└── game-explorer.agent.md            ← ships inside the plugin
```

The agent ID comes from the file name: `kotlin-reviewer.agent.md` → `kotlin-reviewer`.

### `kotlin-reviewer`: no edit tool, but a shell

```yaml
---
name: kotlin-reviewer
description: Use to review uncommitted Kotlin or TypeScript changes in this repo for correctness and project conventions before a commit. Reads the diff and the surrounding code and reports severity-tagged findings. It has no edit tool; it reviews and never modifies.
tools: ["read", "search", "execute"]
strict-tools-list: true
include-custom-instructions: true
---
```

- `name` — what you type after `--agent` and what shows in `/agent`.
- `description` — the main agent reads this to decide when to delegate. Write it as a
  trigger ("Use to review uncommitted ... changes"), then say what comes back.
- `tools` — the allow-list, written with aliases: `read`, `search`, `edit`, `execute`
  (shell), `agent`, `web`, `todo`. Omit the key and the agent gets every tool.
- `strict-tools-list: true` — per the docs, keeps the agent to the listed groups "without
  adding the usual default tools". On 1.0.114 we saw no difference with or without it for a
  top-level agent; the files keep it because it is the documented way to state the intent.
- `include-custom-instructions: true` — see the section below.

**What the tool list guarantees.** Started with `--agent kotlin-reviewer`, the agent got
`view`, `rg`, `glob`, `bash` (plus `read_bash`, `stop_bash`, `list_bash`), `skill` and `sql`.
No `apply_patch`, no `edit`, no `create`, no `task`. It cannot call an edit tool and it
cannot delegate further.

**What it does not guarantee.** It has `bash`, and a shell can write: a redirect, `sed -i`,
`git checkout`. The restriction to `git status`, `git diff` and `git log` is in the prompt
body, so it is a request and not a boundary. In our test run the reviewer also ran one
`find`, outside its stated scope. It changed nothing, but nothing in the file would have
stopped it. The enforced layers are elsewhere:

- **Session permissions.** Per the docs, subagents inherit the parent session's permissions
  and cannot escalate them. Shell commands the CLI does not recognise as read-only still
  need your approval or an `--allow-tool` rule ([guide 08](08-permissions-sandbox.md)).
- **Hooks.** A `preToolUse` hook can deny a call whatever the allow rules say
  ([Example 3](03-hooks.md)).

**Where the result becomes visible.** The body ends with a fixed output format: findings
grouped as Blocker, Should-fix and Nit, each with `path/File.kt:line`, and a last line
`> No files modified — review only.` The footer is a statement by the model. Your proof is
an unchanged `git status`.

### `board-test-writer`: write-capable

Same keys, one more tool: `tools: ["read", "search", "edit", "execute"]`. On a GPT-family
model the `edit` alias resolved to `apply_patch`; everything else matched the reviewer's list.

The body does three things worth copying:

1. It tells the agent to use the `board-tests` skill (Example 2) instead of repeating the
   conventions. The agent has the `skill` tool, so it can load it.
2. It makes running `./gradlew :engine:test` a condition of being done.
3. It names the three known traps (cascade merge, `isGameOver()`, the ignored `changed`
   flag) and says: **keep the correct assertion and report the bug**. Without that
   paragraph, an agent asked for a green run can get one by weakening the test.

### `game-explorer`: read and search only

`tools: ["read", "search"]` and no `include-custom-instructions`. As a subagent it does not
receive the repo's instruction files, so its body carries its own map of the architecture.
Because it ships in the `2048-dev` plugin, its ID is `2048-dev:game-explorer`.
In our run it used only `rg` and `view`.

## Frontmatter keys: exact spelling

Agent-file keys are **kebab-case**. These loaded without warnings on 1.0.114:

| Key | Notes |
|-----|-------|
| `name` | Display name |
| `description` | Required per the docs. Drives automatic delegation |
| `tools` | Array of aliases or raw tool names. Default `["*"]`; `[]` means no tools; a `*` anywhere in the list grants everything |
| `strict-tools-list` | See above |
| `include-custom-instructions` | See below |
| `model-policy` | `preferred` (default) or `required` (per the docs) |
| `reasoning-effort` | Effort level for this agent |

Write them in camelCase and the agent still loads, but the keys do nothing. The live warning:

```
unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList
```

The docs reference table itself prints `modelPolicy` and `reasoningEffort`. Do not copy
that: camelCase is the spelling of the per-user override in `~/.copilot/settings.json`, not
of the agent file.

## The read-only test

What an agent actually gets for a given `tools` list (CLI 1.0.114, GPT-family model):

| `tools` in the file | Tools the agent got |
|---------------------|---------------------|
| `["read", "search"]` | `view`, `rg`, `glob`, `sql`, `skill` |
| `["read", "search", "execute"]` | the above plus `bash`, `read_bash`, `stop_bash`, `list_bash` |
| `["read", "search", "edit", "execute"]` | the above plus `apply_patch` |

The first row is the read-only case. That agent could not create a file and could not run a
shell command, with or without `strict-tools-list: true`. Note what "read-only" means here:
no edit tool and no shell. `sql` and `skill` come along regardless. For comparison, the
default session agent listed 27 tools in the same test, including `task`, `apply_patch`, web
tools and the GitHub MCP tools.

## `include-custom-instructions`

Per the docs, a custom agent that runs as a **subagent** does not receive the repository
instruction files (`copilot-instructions.md`, `AGENTS.md`) unless its frontmatter sets
`include-custom-instructions: true`. The same agent selected as the **session** agent
(`--agent`, `/agent`) does receive them.

`kotlin-reviewer` and `board-test-writer` set it, because both judge code against the repo's
conventions. `game-explorer` does not need conventions to draw a map, and stays cheaper
without them. `--no-custom-instructions` switches instructions off for the whole session,
including agents that opt in.

## Do not name an agent after a built-in

The CLI has built-in agents (per the docs): `explore`, `task`, `general-purpose`,
`code-review`, `security-review`, `research` and `rubber-duck`. They do not appear in the
`/agent` picker. A custom agent with one of these names is shadowed: delegating to that name
always runs the built-in. The agents in this repo use other names: `kotlin-reviewer`, not
`code-review`; `game-explorer`, not `explore`.

Per the docs, `explore`, `task` and `code-review` never receive repository instructions;
`general-purpose` does. That is one reason to write your own reviewer.

## How to invoke an agent

| Way | Example | What happens |
|-----|---------|--------------|
| Picker | `/agent`, or `/agent kotlin-reviewer` | It becomes the session agent |
| Flag | `copilot --agent kotlin-reviewer` | Same, from the start. Plugin agents need the full ID: `--agent 2048-dev:game-explorer` |
| By name in a prompt | *"Use the kotlin-reviewer agent to review my uncommitted changes."* | The main agent calls `task` with `agent_type: "kotlin-reviewer"`; the agent runs as a subagent |
| Automatic | *"Trace how a keypress becomes a board move."* | The main agent picks an agent from the descriptions, or does the work itself |

All four are tested except the picker. On automatic delegation: in our plugin A/B run the
prompt asked for "a specialised code-exploration agent" without naming one. With the plugin
loaded, the task went to `2048-dev:game-explorer`. Without it, it went to the built-in
`explore`. That was one run per arm, so name the agent when it matters.

Delegation is not free. Our review of two small untracked files took the subagent 19 tool
calls and about 66,000 tokens. With `--output-format json` you can see it: a
`tool.execution_start` event with `toolName: "task"`, then `subagent.started` and
`subagent.completed`.

## `/fleet`: several subagents at once

`/fleet <prompt>` tells the main agent to split the work into todos and run the independent
ones as parallel subagents that report back into the same conversation. Per the docs, you
point it at a custom agent by writing `@kotlin-reviewer` in the fleet prompt. `/tasks` lists
what is running. Details are in [guide 07](07-orchestration.md); exercise 7 in
[exercises.md](exercises.md) uses it.

## `/delegate`: hand the session to the cloud agent

`/delegate` sends the session to Copilot on GitHub, which works there and opens a pull
request; `--base` picks the target branch. Per the docs it needs both the Copilot CLI policy
and the Copilot cloud agent policy enabled in the organisation. See
[guide 13](13-remote-agents.md).

## Why no `model:` is hard-coded

None of the three files has a `model` key. Reasons:

- **The allowed models differ per organisation.** A model ID that works on the author's
  account may not exist under the 2N policy.
- **A wrong ID fails quietly or loudly, never usefully.** Per the docs, a `model` you cannot
  access falls back to the session model, so the key silently does nothing. With
  `model-policy: required` the dispatch is refused instead.
- **Inheritance already works.** In our run the subagent's model came from the session
  (`modelSelectionSource: "session_inheritance"`).

To give one agent a different model, do it per user with `/subagents`, which stores the
choice in `~/.copilot/settings.json`. Per the docs the order is: per-call value, `/subagents`
setting, agent file, parent session. If you do put it in a file, the key is
`model: <model-id>`.

## Create your own agent, step by step

1. **Create the file** `.github/agents/my-agent.agent.md`:
   ```markdown
   ---
   name: my-agent
   description: Use when <the situation that should trigger delegation>. <What it returns.>
   tools: ["read", "search"]
   strict-tools-list: true
   ---

   # My agent

   <Who the agent is, what it does, how it reports back.>
   ```
2. **Decide its tools.** Start from `["read", "search"]`. Add `execute` only if it must run
   something, and `edit` only if it must write. Add `include-custom-instructions: true` if it
   judges or writes code.
3. **Check that it loads without warnings:**
   ```bash
   copilot --agent my-agent -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.custom_agents_updated") | .data | {warnings, errors}'
   ```
   You want `{"warnings":[],"errors":[]}`. A misspelled key shows up here.
4. **Test the boundary, not the promise.** Ask it for something it should not be able to do:
   ```bash
   copilot --agent my-agent -p "Create a file named probe.txt containing the word test" \
     --trust-folder --no-ask-user
   git status --short
   ```
5. **Use it in a session.** Per the changelog, a new file in `.github/agents/` is picked up
   by a running session since CLI 1.0.109. After editing an existing agent, start a new session.
6. **Commit it.** Personal agents go in `~/.copilot/agents/`. Per the docs, a personal agent
   with the same ID wins over the project one.

## Try the demo

Start with `scripts/copilot-ws.sh` in the repo root. It pre-approves `./gradlew`, which the
second step needs.

1. **Review uncommitted changes (`kotlin-reviewer`).** Make a small edit in any `.kt` file, then:
   > *"Use the kotlin-reviewer agent to review my uncommitted changes."*

   Approve any command it asks about. You get severity-tagged findings. Then run
   `git status`: nothing new. (Tested: delegation through `task`, the footer in the agent's
   report, no file modified. The main agent summarises the report, so the footer may only be
   visible in the subagent's transcript under `/tasks`.)
2. **Add the 4, 4, 8, 0 test (`board-test-writer`).**
   > *"Use the board-test-writer agent to add a test for sliding the line 4, 4, 8, 0."*

   The correct expectation is `8, 8, 0, 0` with a score of 8. The current code returns
   `16, 0, 0, 0` with 24, so a correct test fails. Watch what the agent does with a red run:
   its prompt tells it to keep the assertion and report the cascade-merge bug. Check with
   `git diff` that the assertion says `8, 8, 0, 0`. If the agent weakened it instead, that is
   the finding, and [guide 09](09-validate-eval.md) shows how to measure such behaviour.
   (This step was not run while writing the guide.)
3. **Trace with `game-explorer`.**
   ```bash
   copilot --agent 2048-dev:game-explorer -p "Trace how a keypress becomes a board move" --trust-folder
   ```
   You get a numbered `file:function:line` trace and no edits (tested).

## Optional parameters

Further frontmatter keys, all per the docs and not tested in this repo:

| Key | What it does |
|-----|--------------|
| `model` | Model for this agent. Falls back to the session model if you cannot access it |
| `models` | Array of models in priority order; overrides `model` |
| `mcp-servers` | MCP servers defined for this agent only |
| `disable-model-invocation`, `user-invocable` | Control automatic delegation and manual selection. They replace the retired `infer` key |
| `hooks` | Agent-scoped hooks (Copilot CLI only) |

In `tools`, MCP tools are written `server/tool` or `server/*`. The prompt body is limited to
30,000 characters.

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** | ✅ | `.github/agents/*.agent.md` for project agents; plugin agents after folder trust. Tested |
| **IntelliJ plugin** | ⚠️ | Custom agents in `.github/agents` are supported per the plugin release notes. Which frontmatter keys it honours is not documented ("Supported profile properties depend on the surface"). The plugin-bundled `game-explorer` needs the plugin installed in the IDE's own plugin store. Not tested here; see [guide 12](12-intellij.md) |
| **Copilot cloud agent** | ✅ | Custom agents are supported per the docs, with the same caveat about supported properties. Reached with `/delegate` |

## Troubleshooting

- **`unknown fields ignored: ...`** → a camelCase or misspelled key. Use the kebab-case
  spelling from the table.
- **The agent is never picked automatically** → sharpen `description`, or name the agent in
  the prompt. A built-in such as `explore` may be taking the task.
- **Delegation runs a different agent than yours** → your agent shares a name with a
  built-in. Rename it.
- **A "read-only" agent changed a file** → it has `execute`, or the file has no `tools` key
  at all. Remove `execute`, or enforce the limit with permissions or a hook.
- **The agent ignores the repo's conventions as a subagent** → add
  `include-custom-instructions: true`, and check you did not start with
  `--no-custom-instructions`.
- **`model` is set but another model ran** → you cannot access that model (silent fallback),
  or a `/subagents` setting overrides the file.
- **Plugin agent not found** → use the full ID `2048-dev:game-explorer`, and check the folder
  is trusted (Example 6).
- **In `-p` mode: "Permission denied because no interactive user response was available."**
  → the agent needed a tool nobody approved. Pass `--allow-tool`, for example
  `--allow-tool='shell(git:*)'` for the reviewer.
- **Your edit to an agent file has no effect** → start a new session. Also check
  `~/.copilot/agents/` for a personal agent with the same ID.

---

Next: `game-explorer` came from a plugin. How that plugin is built, listed and switched on →
[Example 6: Plugins and an in-repo marketplace](06-plugins.md).

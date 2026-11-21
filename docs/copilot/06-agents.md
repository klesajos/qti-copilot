> 🌍 Read this in: **English** | [Česky](06-agents.cs.md)

# 06 · Custom agents

> ⏱ 25 min (5 demo + 20 exercise 5) · Docs: [Custom agents](https://docs.github.com/en/copilot/concepts/customizations/custom-agents) · [Creating and using custom agents for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli) · Verified on Copilot CLI 1.0.114

## In short

**You need:** The CLI. One Markdown file per agent.

**What it is for:** A custom agent is a specialist with its own instructions, its own list of tools and its own context window. Your session hands it a task and gets back only the result, not the noise.

**Three uses that pay off most:**

1. A read-only reviewer that checks your diff and cannot change a single file.
2. An explorer that finds where a feature lives without filling your session with file contents.
3. A test writer that only writes tests, so the fix stays a separate step you can check.

## What is a custom agent?

A custom agent is a Markdown file: frontmatter plus a prompt. It has three things of its own:

- **Context.** As a subagent it works in a separate conversation and returns only its conclusion.
- **Tools.** The `tools` list decides what it can call. No edit tool, no edits.
- **Prompt.** The body of the file is its system prompt: role, scope, report format.

Use one when the work is noisy (exploration, review), needs fewer tools than your session, or must
report in a fixed format. A skill ([03](03-skills.md)) adds instructions; an agent takes the task.

## What this example does

```
.github/agents/{board-test-writer,kotlin-reviewer,workshop-tutor}.agent.md   ← agent ID = file name
plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md            ← plugin agent (07)
```

| Agent | `tools` in the file | Tools it gets | Job |
|-------|---------------------|---------------|-----|
| `board-test-writer` | `read`, `search`, `edit`, `execute` | the reviewer's set plus `apply_patch` | Adds board tests, runs `./gradlew :engine:test`, keeps a correct failing assertion and reports the bug |
| `kotlin-reviewer` | `read`, `search`, `execute` | `view`, `rg`, `glob`, `bash`, `skill`, `sql` | Reviews uncommitted changes. No edit tool |
| `2048-dev:game-explorer` | `read`, `search` | `view`, `rg`, `glob`, `skill`, `sql` | Traces a feature as `file:function:line`. No shell, no edit tool |

## The file, line by line

The frontmatter of `.github/agents/kotlin-reviewer.agent.md`:

```yaml
name: kotlin-reviewer
description: Use to review uncommitted Kotlin or TypeScript changes in this repo for correctness and project conventions before a commit. Reads the diff and the surrounding code and reports severity-tagged findings. It has no edit tool; it reviews and never modifies.
tools: ["read", "search", "execute"]
strict-tools-list: true
include-custom-instructions: true
```

- `name` — what you pass to `--agent` and see in `/agent`. Defaults to the agent ID.
- `description` — required. The main agent reads it to decide when to delegate. Write the trigger
  first ("Use to review uncommitted ... changes"), then what comes back.
- `tools` — allow-list of aliases: `read`, `search`, `edit`, `execute` (shell), `agent`, `web`.
  Omit the key and the agent gets every tool. `[]` gives it none.
- `strict-tools-list: true` — only the listed groups, without the usual default tools. On 1.0.114
  the tool set was the same with and without it.
- `include-custom-instructions: true` — a subagent receives `copilot-instructions.md` and
  `AGENTS.md` only if this is set; a session agent always does. The two agents that judge code,
  `board-test-writer` and `kotlin-reviewer`, set it; `game-explorer` and `workshop-tutor` do not.

**Keys are kebab-case.** The docs table prints camelCase keys such as `modelPolicy`. That spelling
does nothing: `unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList`.

**What the tool list guarantees.** The reviewer cannot call an edit tool. It does have `bash`, and
a shell can write. The rule to use the shell only for `git status`, `git diff` and `git log` is in
the body, so it is a request to the model. The enforced layers are session permissions, which subagents
inherit and cannot widen ([08](08-permissions-sandbox.md)), and `preToolUse` hooks ([04](04-hooks.md)).

## How delegation works and how to call an agent

The main agent delegates with a tool named `task`; its `agent_type` argument names the agent. With
`--output-format json` you see `tool.execution_start` with `toolName: "task"`, then
`subagent.started` and `subagent.completed`. In a session, `/tasks` lists the subagents; `Enter` opens a transcript.

| Way | Example | What happens |
|-----|---------|--------------|
| Session agent | `/agent kotlin-reviewer` or `copilot --agent kotlin-reviewer` | It replaces the default agent for the session. Bare `/agent` opens a picker: `Default`, `board-test-writer · project`, `game-explorer · plugin`, `kotlin-reviewer · project`, `workshop-tutor · project` |
| By name in a prompt | *"Use the kotlin-reviewer agent to review my uncommitted changes."* | The main agent calls `task` with `agent_type: "kotlin-reviewer"` |
| Automatic | *"Trace how a keypress becomes a board move."* | The main agent picks an agent by `description`, picks a built-in, or does the work itself |

Plugin agents need the full ID: `2048-dev:game-explorer`. Built-in agents are `explore`, `task`,
`general-purpose`, `code-review`, `security-review`, `research` and `rubber-duck` ([list](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-agents)).
They are not in `/agent`. A custom agent with one of these names never runs: the built-in does.

## Create your own, step by step

1. Create `.github/agents/my-agent.agent.md`:
   ```markdown
   ---
   name: my-agent
   description: Use when <the situation that should trigger delegation>. <What it returns.>
   tools: ["read", "search"]
   strict-tools-list: true
   ---
   <Who the agent is, what it does, how it reports back.>
   ```
2. Add `execute` only to run something, `edit` only to write, and
   `include-custom-instructions: true` if it judges or writes code.
3. Check that it loads. Expect `{"warnings":[],"errors":[]}`:
   ```bash
   copilot --agent my-agent -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.custom_agents_updated") | .data | {warnings, errors}'
   ```
4. Test the boundary; afterwards `git status --short` shows no `probe.txt`:
   `copilot --agent my-agent -p "Create a file named probe.txt" --trust-folder --no-ask-user`
5. A running session picks up a new file in `.github/agents/`; an edited one needs a new session.
   A personal agent in `~/.copilot/agents/` wins over a project agent with the same ID.

## An agent as an output style

Copilot CLI has no output-style feature. A session agent whose body only fixes the answer shape
does the same job. `.github/agents/workshop-tutor.agent.md` has no `tools` key, so it keeps every
tool, and `disable-model-invocation: true`, so it is never picked as a subagent. Its body shapes
every answer as **What I did** / **Why it works** / **Try it**.

```bash
copilot --agent workshop-tutor -p "What does Board.hasWon() return? Don't edit anything." \
  --trust-folder --no-ask-user
```

The answer names `Board.kt:174` (one run said `:177`), gives the reason and ends with `./gradlew :engine:test` to try.
The model may rename the first heading (`What I found`) or fold the reason into it. In a session, `/agent workshop-tutor` selects it
(footer: `workshop-tutor · <model>`); `/agent`, then Enter on `Default (deselect current agent)`, leaves it. `/agent default` fails. Limits:

- One session agent at a time: no combining with `--agent kotlin-reviewer`. Subagent reports are
  not shaped. The shape is a request: before the body said "always", one run gave no command.
- The always-on alternative is a "Response format" section in `.github/copilot-instructions.md`.
  It costs context in every session, for everyone.

## Try the demo

1. Start `scripts/copilot-ws.sh` in the repo root and trust the folder.
2. Prompt:
   > *"Use the 2048-dev:game-explorer agent to trace how a keypress becomes a board move. Do not modify any file."*
3. Copilot delegates to `game-explorer`; `/tasks` lists it and `Enter` opens its transcript (`f` shows or hides finished ones).
   The answer is the path `App.tsx` → `keys.ts` → `api.ts` → `GameController.kt` → `GameService.kt`
   → `Board.kt`. `git status` shows no change. Our run: 20 tool calls, about 42,000 tokens.

## Optional parameters

| Key | What it does |
|-----|--------------|
| `model`, `models` | Model, or models in priority order. No agent here sets it: allowed models differ per organisation (2N: all except Fable) and a subagent inherits the session model. Ignored when the session model is Auto. Per-user override: `/subagents` |
| `model-policy` | `preferred` (default), or `required`: refuse the dispatch instead of using another model |
| `reasoning-effort` | Effort level for this agent |
| `mcp-servers` | MCP servers for this agent only. In `tools`, MCP tools are `server/tool` or `server/*` |
| `disable-model-invocation`, `user-invocable` | Switch off automatic delegation, or manual selection |
| `skills` | Skill names whose text is loaded into the agent's context when it starts. A name that is not found gives a `skill_load` warning |

> 🔷 **Copilot only:** `model-policy: required` locks one agent to the models its file names. Claude Code has no per-agent lock; `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` applies to every subagent.

The body is limited to 30,000 characters. Full reference: [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration) · [frontmatter fields in the CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-agent-frontmatter-fields)

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|-----|-----------------|-------------|
| ✅ `.github/agents/`, `~/.copilot/agents/`, plugin agents after folder trust | ⚠️ Reads `.github/agents/` (generally available since plugin 1.6.1); which keys it honours is not documented. Plugin agents need the plugin in the IDE's own plugin store ([11](11-ide-remote.md)) | ✅ Reads `.github/agents/`; reached with `/delegate` ([11](11-ide-remote.md)) |

## Copilot vs Claude Code

Claude Code calls this **subagents**: `.claude/agents/*.md`, the same own context, tools and prompt.

- Claude Code lists tool names (`Read`, `Grep`, `Bash`). Both preload skills with a `skills:`
  list in the frontmatter; `board-test-writer` names `board-tests` in its body instead.
- Copilot CLI also reads a project's `.claude/agents/` and accepts the Claude tool names as
  aliases. `~/.claude/agents` is not read; move personal agents to `~/.copilot/agents/`.
- Output styles exist only in Claude Code. Here a session agent stands in, with the limits above.

## Troubleshooting

- **`unknown fields ignored: ...`** → a camelCase or misspelled key: use the kebab-case spelling. `sidekick`, from the docs reference, is also ignored on 1.0.114.
- **Another agent ran, or none** → name the agent in the prompt; use the full ID for a plugin agent.
- **A "read-only" agent changed a file** → it has `execute` or no `tools` key. Remove `execute`.
- **A `-p` run ends with "Permission denied ..."** → pre-approve the tool: `--allow-tool='shell(git:*)'`.

Next: [07 · Plugins and guild sharing](07-plugins.md)

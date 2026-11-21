> 🌍 Read this in: **English** | [Česky](cheatsheet.cs.md)

# Copilot CLI cheat sheet

> Verified on Copilot CLI 1.0.114 · Docs: [CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) · [Customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)

Every flag and slash command here is in `copilot --help` or `copilot help <topic>` on 1.0.114. The CLI
ships almost daily: when a row does not match, the help wins. Guides: [index](README.md).

## Launch flags

| Flag | What it does |
|------|--------------|
| `copilot`, `-i "<prompt>"` | Interactive session; `-i` runs the prompt first |
| `-p "<prompt>"` | Run one prompt and exit ([programmatic mode](#programmatic-mode)) |
| `--model <model-id>`, `--reasoning-effort <level>` | Model and effort for the session. `auto` lets Copilot pick; effort with `auto` fails: `Model "auto" does not support reasoning effort configuration` |
| `--agent <agent>` | Run the session as a custom agent; a plugin agent is `<plugin>:<agent>` |
| `--mode <mode>`, `--plan`, `--autopilot` | Start in `interactive`, `plan` or `autopilot` mode. `--max-autopilot-continues <n>` (default 5) |
| `--fleet` | Run the prompt with parallel subagents; combine with `-i`, `-p` or piped stdin |
| `--max-ai-credits <n>` | Credit cap for the session (minimum 30, soft) |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Pre-approve or block matching tool calls for this run; deny wins |
| `--allow-all-tools`, `--allow-all` (`--yolo`) | No tool prompts; `--allow-all` also drops the path and URL checks |
| `--trust-folder` | Trust the folder's configuration for one `-p` run; saves nothing |
| `--continue`, `--resume [value]`, `-n <name>` | Resume the latest session; resume by ID or name; name a new session |
| `--add-github-mcp-tool <tool>`, `--disable-mcp-server <name>`, `--additional-mcp-config <json>` | For this run: expose exactly the named tools of the built-in GitHub MCP server, replacing its default subset (`--add-github-mcp-toolset <toolset>` adds to it); switch a server off; add servers |
| `--plugin-dir <dir>`, `--experimental`, `--no-custom-instructions` | Load a plugin from a local directory; turn on experimental features; skip every instruction file |

In a shell, without a session: `copilot instruction list`, `copilot skill list`, `copilot mcp list`,
`copilot plugin list`, `copilot config [key] [value]` (`--repo`, `--local`), `copilot help [topic]`.

## Slash commands

| Group | Command | What it does |
|-------|---------|--------------|
| **Loaded** | `/env` | What loaded: instructions, MCP servers, skills, agents, hooks, plugins |
| | `/instructions`, `/skills`, `/plugin`, `/init` | Toggle instruction files; manage skills; manage plugins; write the instructions file |
| | `/agent [name]`, `/subagents` | Select an agent (back: `/agent`, then `Default`); set each subagent's model or turn it off |
| | `/mcp` | `list`, `get <server>`, `reload`, `enable` / `disable <server>` |
| **Model, cost** | `/model` | Model, effort and context tier; `/model plan` for plan mode; `--repo` sets the repo default |
| | `/usage`, `/limits` | Credits, tokens per model and the `Plan` budget bar; `/limits set max-ai-credits <n>`, `/limits unset` |
| | `/context`, `/compact [focus]` | Context window use by category; summarise history to free it |
| **Work** | `/plan`, `/autopilot` | Plan before coding; toggle autopilot, or set an objective with `--max-ai-credits` |
| | `/fleet [prompt]`, `/tasks` | Split the work into parallel subagents; list what runs: `Enter` opens a transcript, `x` kills the selected one |
| | `/delegate` | Send the session to the cloud agent, which opens a PR; `--base` picks the branch |
| **Code** | `/diff`, `/review`, `/security-review`, `/rubber-duck` | Show the changes (`Esc` closes it); review agent; security scan of uncommitted changes; independent critique |
| **Permissions** | `/permissions` | Switch mode: `manual`, `assisted`, `allow-all`; `show` prints the mode, not the allow and deny rules |
| | `/allow-all`, `/reset-allowed-tools` | Allow everything; clear session and saved approvals for this location |
| | `/sandbox`, `/add-dir` | `status`, `policy`, `enable [session]`, `disable`; allow another directory |
| **Session** | `/new`, `/clear` | New session, the current one keeps running; abandon this session |
| | `/resume [value]`, `/fork [name]`, `/rewind` | Switch session; copy this one; restore an earlier turn ([Rewind](#rewind)) |
| | `/share`, `/remote`, `/keep-alive` | Export `file`, `html`, `gist`, `link`; steer from GitHub web or mobile; prevent sleep |
| **Other** | `/ide`, `/pr`, `/ask`, `/settings`, `/diagnose` | IDE link; the branch's PR; side question; one setting; why a request needed approval |

Input: `/name` runs a skill (`/board-tests`, `/2048-dev:build-test`), `!cmd` runs a shell command
directly, `@file` mentions a file. Keys: `Enter` steers a running turn, `Ctrl+Q` queues a new one,
`Ctrl+C` stops the turn, `Esc` rejects a permission prompt, `Shift+Tab` cycles Interactive, Plan and
Autopilot, `Ctrl+O` expands the timeline entries, `?` on an empty prompt lists all keys.

## Models and effort

| Topic | How |
|-------|-----|
| Pick a model | `/model`, `--model <model-id>`, `COPILOT_MODEL`, or the `model` setting. At 2N every model except the Claude Fable family can be selected; one you cannot use is still listed in `/model` and says why when highlighted. Each model lists its credits per 1M tokens |
| Effort | Levels `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`; which exist depends on the model; unset is the model's default, `medium` for most. Set it with left / right arrows in `/model`, `--reasoning-effort <level>`, the `effortLevel` setting, `reasoning-effort:` in an `.agent.md`, or `/subagents` |
| Plan mode | Own model and effort: `/model plan`, `planModel`, `planEffortLevel`. The session effort is not inherited |
| Auto | `auto` is shown as Copilot Fusion and picks a model per prompt. `--auto-tier` / `autoTier`: `efficiency`, `balance`, `intelligence`. `fusionTier`: `standard`, `high`, `max`. In `/model`, left / right on the `Copilot Fusion` row step its `Tier` (`Standard`, `High`, `Max`) |
| Context tier | `--context default` or `long_context`, the `contextTier` setting, or the tier picker in `/model` |
| Reasoning, cost | `Ctrl+T` shows or hides reasoning summaries. `/usage`: `↑ input (N cached, N written) • ↓ output (N reasoning)`; reasoning tokens are billed as output |

Never commit a model id: 2N's list differs from yours. `effortLevel` is the safe one to commit.

> 🔷 **Copilot only:** one subscription and one picker for models from several vendors (Anthropic, OpenAI, Google, xAI, Microsoft, Moonshot AI). Claude Code runs Claude models only.

## Context economics

| Fact | What to do with it |
|------|--------------------|
| Every model call resends the whole conversation as input | Long sessions cost more per turn. The prompt cache serves the repeated part at a fraction of the price; `/usage` shows it as cached |
| On the test machine a one-word prompt in an empty directory sent 20,387 input tokens, 10,668 of them tool definitions | The fixed overhead is paid on every call, and every instruction file and MCP tool adds to it. `/context` shows what fills the window |
| `/compact [focus]` replaces the history with a summary; it starts by itself at 80 % of the window | Detail is lost, it cannot be reversed, and it costs credits. For a new task use `/new` or `/clear` |
| A subagent has its own window | Only its report comes back: delegate the reading |
| 1 credit = $0.01; Copilot Business has 1,900 per user per month, pooled | Cap a session: `--max-ai-credits <n>` or `/limits set max-ai-credits <n>`. Soft cap: one response can pass it, then the next call is blocked. Subagents and compaction count |

> 🔷 **Copilot only:** a cost cap you set on one interactive session. Claude Code's `--max-budget-usd` applies to `-p` runs only.

## Several sessions at once

| Do this | To get |
|---------|--------|
| `/new` | A second session; the current one keeps running in the background |
| `Left` on an empty prompt | The Sessions sidebar: list them and switch |
| `/fork [name]` | A copy of this conversation to try something else |
| `/new worktree`, `/fork worktree` | The same in a new git worktree, so two sessions do not edit the same files |
| `copilot --continue`, `--resume [value]`, `/resume` | Back into a saved session |
| `/delegate` | The session continues on GitHub and ends in a pull request |

A background session is still interactive: switch back and answer its prompts.

## Rewind

`/rewind`, `/undo`, or `Esc Esc` on an empty prompt: pick a turn, then "Conversation only" or
"Conversation + files". Only files Copilot changed are restored; that turn's prompt returns to the
input line. A rewind is final: `/fork` first. Compaction saves a checkpoint: `/session checkpoints [n]`.

## Where files live

| What | In the repository | For you (`~/.copilot/`) |
|------|-------------------|-------------------------|
| Instructions | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md` (`applyTo`), `AGENTS.md` | `copilot-instructions.md`, `instructions/*.instructions.md` |
| Skills | `.github/skills/<name>/SKILL.md` | `skills/` |
| Hooks | `.github/hooks/*.json` | `hooks/` |
| MCP | `.mcp.json` or `.github/mcp.json`, top-level key `mcpServers` | `mcp-config.json` |
| Agents | `.github/agents/<name>.agent.md` | `agents/` |
| Plugins | `marketplace.json`, `plugins/<name>/plugin.json`; enabled by `extraKnownMarketplaces` and `enabledPlugins` in `.github/copilot/settings.json` | `installed-plugins/` |
| Settings | `.github/copilot/settings.json`, `settings.local.json` (git-ignored here) | `settings.json` |
| Permissions | no committed file: launch flags in `scripts/copilot-ws.sh`, or a hook | `permissions-config.json` ("don't ask again") |

- Also read: `CLAUDE.md`, `GEMINI.md`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/`,
  `.claude/commands/`, `.agents/skills/`, hooks in `.claude/settings.json`. This repo has none.
- Not read: `.cursorrules`, `.cursor/rules/*.mdc`, `.windsurfrules`, `.vscode/mcp.json`, `~/.claude/`.
- Hooks, workspace MCP servers and repo plugins load only in a trusted folder; `/env` shows them.

## Hook events

`{"version": 1, "hooks": {"<event>": [{"type": "command", "bash": "./script.sh", "cwd": ".", "timeoutSec": 30, "matcher": "..."}]}}`

| Event | Fires | Payload adds | Answer: JSON on stdout, exit 0 |
|-------|-------|--------------|--------------------------------|
| `sessionStart` | Session begins | `source`, `initialPrompt` | `{"additionalContext": "..."}` goes into the model's context |
| `userPromptSubmitted` | You submit a prompt | `prompt` | Use it to log |
| `preToolUse` | Before a tool call | `toolName`, `toolArgs` | `{"permissionDecision": "deny", "permissionDecisionReason": "..."}` blocks the call, even with `--allow-tool`. The model sees `Denied by preToolUse hook: <reason>` |
| `postToolUse` | After a successful tool call | plus `toolResult` | `{"additionalContext": "..."}` |
| `agentStop` | The agent ends its turn | `stopReason`, `stop_hook_active` | `{"decision": "block", "reason": "..."}` sends it back to work; `reason` arrives as the next user message |
| `sessionEnd` | Session ends | `reason` | Nothing |

- Every payload has `sessionId`, `timestamp`, `cwd`. Hooks run in the repo root with
  `COPILOT_PROJECT_DIR`, `COPILOT_HOOK_DIR` and `COPILOT_CLI=1` set.
- `matcher` is a regex on the whole tool name, e.g. `bash|powershell`. `toolArgs` is an object for
  `bash` (`.command`) and a raw patch string for `apply_patch`.
- Exit code 2 shows stderr as a warning. On `agentStop` it does not block; on `preToolUse` any
  non-zero exit denies the call. All events:
  [hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference).

## Permission patterns

| Pattern | Matches |
|---------|---------|
| `shell`, `shell(command)` | Every shell command; one command. `git`, `gh`, `npm`, `gradle` and similar match with their first subcommand: `shell(git push)` |
| `shell(command:*)` | That command and anything after it: `shell(git:*)` matches `git push`, not `gitea` |
| `write`, `write(path)` | File creation and edits. A relative path matches by trailing components: `write(.env)` is any `.env`. Globs `*`, `?`, `**` |
| `read`, `read(path)` | File reads by built-in tools, same path matching. Not shell commands |
| `<mcp-server>`, `<mcp-server>(tool)` | All tools of an MCP server; one tool |
| `url(domain-or-url)` | URL access by shell and web-fetch tools: `url(https://*.github.com)` |

- ✅ `shell(./gradlew:*)` allows `./gradlew :engine:test`. ❌ `shell(gradlew:*)` and
  `shell(./gradlew test)` do not. ✅ `shell(npm test)` and `shell(npm:*)` allow `cd web && npm test`.
- ⚠️ `--deny-tool='read(.env)'` blocks the `view` tool; `cat .env` still prints the file. The
  `protect-secrets.sh` hook closes that gap.
- Deny wins over every allow, also over `--allow-all`. Flag rules last for the run. Read-only
  commands run without asking. In autopilot and `-p` runs a request that would prompt is denied.
- Sandbox, off by default: `/sandbox enable` saves it; `/sandbox enable session` or `--sandbox`: one session.

## Programmatic mode

```bash
copilot -p "<prompt>" --trust-folder --no-ask-user --allow-tool='shell(./gradlew:*)' --output-format json > events.jsonl
```

| Flag | Why a script needs it |
|------|-----------------------|
| `--allow-tool='<rule>'` | Nobody can answer a prompt: an unapproved call fails with `Permission denied because no interactive user response was available.` |
| `--trust-folder`, `--no-ask-user` | Load the repo's hooks and workspace MCP servers; the agent cannot open the question form |
| `-s`, `--output-format json` | Only the final answer; or JSONL, one `{type, data, id, parentId, timestamp}` per line |
| `--usage-output-file <file>`, `--share [path]` | Credits (`totalNanoAiu`, 10^9 = 1 credit) and tokens per model and agent; session as Markdown |

- `tool.execution_start`: `data.toolName`, `data.arguments`. A skill use is `toolName: "skill"`,
  a delegation is `toolName: "task"` with `arguments.agent_type`.
- `tool.execution_complete`: `data.success`, `data.error.message`. The answer is in
  `assistant.message` (`data.content`). The last line is `{"type": "result", "exitCode": 0, ...}`.

## Evals

| Command (repo root, after `npm ci`) | What it does |
|-------------------------------------|--------------|
| `npm run eval:lint` | Validate both eval specs. Free |
| `VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run` | Print the with / without plan. Free |
| `npm run eval -- -e evals/game-explorer/eval.yaml` | Run one eval. Spends credits |
| `npm run eval:ab` | `board-tests` skill, with and without. Spends credits |
| `evals/plugin-ab.sh`, `RUNS=3 MODEL=<model-id> evals/plugin-ab.sh` | Plugin A/B on plain `copilot -p`; needs only `copilot` and `jq`. Spends credits |

Results: `evals/results/<timestamp>/report.md`. Details: [09 · Evals](09-evals.md).

## Not in 1.0.114

| You may look for | Use instead |
|------------------|-------------|
| `/yolo` | `--yolo` or `--allow-all` at launch, `/allow-all` in a session |
| `/goal` | `/autopilot` with an objective and `--max-ai-credits` |
| `/workflows` | `copilot workflow run <name>`, with `--experimental` |
| `/agents`, `/output-style` | `/agent [name]`; `/subagents` for per-subagent settings. Output style: a session agent, `copilot --agent workshop-tutor` ([06](06-agents.md)) |

> 🌍 Read this in: **English** | [Česky](cheatsheet.cs.md)

# Copilot CLI cheat-sheet

> ✅ Checked against Copilot CLI 1.0.114 (2026-11-21). The CLI ships almost daily; run `copilot help` when something here does not match.

The numbered guides explain how to **extend** Copilot CLI ([instructions](01-custom-instructions.md),
[skills](02-skills.md), [hooks](03-hooks.md), [MCP](04-mcp.md), [agents](05-agents.md),
[plugins](06-plugins.md), [orchestration](07-orchestration.md),
[permissions](08-permissions-sandbox.md), [evals](09-validate-eval.md)). This page is for
**operating** it: flags, slash commands, keys, file locations, hook events and permission rules.

Unmarked rows come from the CLI's own help on 1.0.114 (`copilot --help`, `copilot help <topic>`,
`copilot <command> --help`). **[T]** = run in this repository. **[D]** = per the docs; not tested in this repo.

## Launch flags (`copilot ...`)

| Group | Flag | What it does |
|-------|------|--------------|
| **Prompt and output** | `copilot` | Interactive session in the current folder |
| | `-i "<prompt>"` / `--interactive` | Interactive session that runs this prompt first |
| | `-p "<prompt>"` / `--prompt` | Non-interactive: run the prompt, exit when done |
| | `-s` / `--silent` | Print only the agent's answer, no stats |
| | `--output-format json` | JSONL, one object per line (default `text`) |
| | `--share [path]`, `--share-gist` | After a `-p` run, export the session to Markdown (default `./copilot-session-<id>.md`) or a secret gist |
| | `--usage-output-file <file>` | Final usage as JSON: credits, premium requests, tokens per model and per agent |
| | `-C <directory>` | Change working directory before anything else |
| **Permissions** | `--allow-tool='<rule>'` | Run matching tools without asking. Lasts for this run |
| | `--deny-tool='<rule>'` | Block matching tools. Wins over every allow, also `--allow-all` and `--yolo` |
| | `--allow-all-tools` | No tool confirmations. Env `COPILOT_ALLOW_ALL`; the exact value `true` also trusts the working directory |
| | `--add-dir <dir>`, `--allow-all-paths`, `--disallow-temp-dir` | Add a directory (also loads its `.github/skills` and `.github/agents`) / drop the path check / drop the temp directory |
| | `--allow-url`, `--deny-url`, `--allow-all-urls` | URL and domain access. Deny wins. Rules default to `https://` |
| | `--allow-all` / `--yolo` | `--allow-all-tools --allow-all-paths --allow-all-urls` |
| | `--available-tools`, `--excluded-tools` | Which tools the model can see at all (not an approval rule) |
| | `--assisted-approval` | A safety judge reviews permission requests. Probabilistic, not a security boundary |
| | `--trust-folder` | Trust the working directory's configuration for one new `-p` session. Saves nothing, approves nothing |
| | `--sandbox` | Sandbox shell commands for this session (see `copilot help sandbox`; not listed in `copilot --help`) |
| | `--secret-env-vars=A,B` | Remove these variables from shell and MCP server environments; mask their values in some output |
| **Agents and models** | `--agent <agent>` | Run the session as a custom agent. A plugin agent is `<plugin>:<agent>` **[T]** |
| | `--model <model-id>` | Pick the model. `auto` lets Copilot choose |
| | `--reasoning-effort <level>` | `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`; depends on the model |
| | `--mode interactive` / `plan` / `autopilot` | Initial agent mode; shorthands `--plan`, `--autopilot`. `--max-autopilot-continues <n>` (default 5) |
| | `--fleet` | Run the prompt with parallel subagents; combine with `-i`, `-p` or piped stdin |
| | `--max-ai-credits <n>` | Session credit cap (minimum 30, soft) |
| | `--no-custom-instructions` | Skip `AGENTS.md` and related instruction files |
| **Sessions** | `--continue` | Resume the most recent session, preferring this branch, repository or directory |
| | `-r` / `--resume [value]` | Resume by session ID, ID prefix (7+ hex chars), task ID or exact name. No value opens the picker |
| | `--session-id <id>` | Resume by ID, or set the UUID of a new session |
| | `-n` / `--name <name>` | Name the new session |
| **MCP and plugins** | `--additional-mcp-config <json>` / `@file` | Extra MCP servers for this session; repeatable |
| | `--disable-mcp-server <name>`, `--enable-mcp-server <name>` | Turn one server off / on for this run |
| | `--disable-builtin-mcps` | Turn off the built-in servers. `copilot --help` names `github-mcp-server` and `githubiq`; `copilot mcp list` on the test machine printed `computer-use` and `github-mcp-server` |
| | `--add-github-mcp-toolset`, `--add-github-mcp-tool`, `--enable-all-github-mcp-tools` | Widen the built-in GitHub server. Any of them makes it read-write |
| | `--plugin-dir <dir>` | Load a plugin from a local directory; repeatable |
| **Misc** | `--experimental` / `--no-experimental` | Experimental features (extensions, dynamic workflows) |
| | `--log-level <level>`, `--log-dir <dir>` | Logging; default directory `~/.copilot/logs/` |
| | `--no-auto-update` | Do not download CLI updates |
| | `--acp` | Start as an Agent Client Protocol server (Zed, JetBrains) |

| Subcommand (shell, no session) | What it does |
|--------------------------------|--------------|
| `copilot help [topic]` | Topics: `acp`, `billing`, `commands`, `config`, `environment`, `extensions`, `input`, `limits`, `logging`, `lsp`, `mcp`, `monitoring`, `network`, `parallel-work`, `permissions`, `providers`, `providers-env`, `providers-local`, `sandbox`, `sessions`, `timeline` |
| `copilot init` | Analyse the repo and write `.github/copilot-instructions.md` |
| `copilot login` | Sign in. A token in `COPILOT_GITHUB_TOKEN`, `GH_TOKEN` or `GITHUB_TOKEN` (in that order) takes precedence over stored credentials |
| `copilot config [key] [value]` | Read or set a setting. `--list`, `--json`, `--rm`, `--repo`, `--local` |
| `copilot instruction list [--json]` | Instruction sources this process would load |
| `copilot skill list` / `add` / `remove` / `enable` / `disable` | Skills. `add --project` writes to `.github/skills` |
| `copilot plugin install` / `uninstall` / `update` / `list` / `enable` / `disable` | Plugins. Source: `plugin@marketplace`, `owner/repo`, `owner/repo:path`, git URL |
| `copilot plugin marketplace add` / `remove` / `list` / `browse` / `update` | Marketplaces. `awesome-copilot` is built in |
| `copilot mcp list` / `get` / `add` / `remove` / `enable` / `disable` | MCP servers. `add` writes to `~/.copilot/mcp-config.json`; `list` and `get` show configuration, not live status |
| `copilot workflow run <name>` | Run a registered dynamic workflow; needs experimental mode |
| `copilot lsp list`, `copilot sandbox ca <cmd>`, `copilot update`, `copilot completion` | Language servers, sandbox proxy certificate authority, update, shell completion script |

## Programmatic mode (`copilot -p`)

See [Example 11](11-programmatic-ci.md).

| Flag | Why it matters in a script |
|------|----------------------------|
| `-p "<prompt>"` | Runs once and exits. A slash invocation works: `copilot -p "/2048-dev:build-test ..."` **[T]** |
| `--allow-tool='<rule>'` / `--allow-all-tools` | Nobody can answer a prompt. An unapproved call fails with `Permission denied because no interactive user response was available.` **[T]** |
| `--trust-folder` | Without it, a `-p` run in an untrusted folder skips workspace MCP servers and repository hooks. With it the repo hooks load **[T]** |
| `--no-ask-user` | The agent cannot open the question form |
| `-s` | Only the final answer on stdout **[T]** |
| `--output-format json` | JSONL event stream on stdout |
| `--max-ai-credits <n>`, `--usage-output-file <file>` | Credit cap for the run; usage as JSON, also with `-s` |

- The exit summary goes to stderr. It is not printed with `--silent` or `--output-format json`.
- Memory is off in `-p` runs (`--enable-memory` turns it on). Project extensions are skipped unless `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true`.
- A `-p` run waits up to 600 s for background agents and shell commands (`COPILOT_TASK_WAIT_TIMEOUT_SECONDS`).

**JSONL records** **[T]**. Each line is `{type, data, id, parentId, timestamp, ephemeral?}`.

| `type` | Useful fields |
|--------|---------------|
| `session.start` | `data.copilotVersion`, `data.context.cwd`, `gitRoot`, `branch` |
| `session.model_change`, `session.auto_mode_resolved` | `data.newModel`; `data.chosenModel` when the model is `auto` |
| `session.skills_loaded`, `session.custom_agents_updated` | `data.skills`; `data.agents`, `data.warnings`, `data.errors` |
| `user.message`, `assistant.message` | `data.content` |
| `tool.execution_start` | `data.toolName`, `data.arguments` |
| `tool.execution_complete` | `data.success`, `data.result.content`, `data.error.message` |
| `subagent.started` / `completed` / `failed` | `data.agentName` |
| `session.warning` | Hook warnings arrive here with `warningType: "hook"` |
| `session.usage_checkpoint` | `data.totalNanoAiu` |
| `result` (last line) | `exitCode`, `usage.premiumRequests`, `usage.totalApiDurationMs`, `usage.sessionDurationMs`, `usage.codeChanges.{linesAdded, linesRemoved, filesModified}` |

- There is no `skill.invoked` record. A skill use is `tool.execution_start` with `toolName: "skill"` and `arguments: {"skill": "board-tests"}`.
- Delegation to an agent is `toolName: "task"` with `arguments.agent_type` (`"2048-dev:game-explorer"`, built-in `"explore"`).
- Final answer only: `jq -rs '[.[] | select(.type == "assistant.message") | .data.content] | join("\n")' events.jsonl`

## Slash commands

Grouped as in `copilot help commands`. `/help` in a session shows the live list.

| Group | Command | What it does |
|-------|---------|--------------|
| **Agent environment** | `/init` | Create or update instructions; text after `/init` guides what is written |
| | `/agent [name]` | Browse and select agents |
| | `/skills` | Manage skills. `/skills reload` rereads the skill directories **[D]** |
| | `/mcp` | `list`, `get <server>`, `reload`, `enable` / `disable <server>`, `auth <server>` |
| | `/plugin` | Manage plugins and marketplaces |
| **Agents, subagents** | `/model` | Model for this session. `--repo` / `--local` set the repo default, `plan` the plan-mode model |
| | `/delegate` | Send the session to GitHub; Copilot opens a PR. `--base` picks the target branch |
| | `/fleet [prompt]` | Split the work into todos and run independent ones as parallel subagents. No prompt: work through the open todos |
| | `/autopilot` | Toggle autopilot, or set an objective with `--max-ai-credits` |
| | `/tasks` | Running subagents and background shell commands; `x` stops the selected one |
| **Code** | `/diff` | Review the changes made in the current directory |
| | `/review` | Run the code review agent on the changes |
| | `/security-review` | Scan uncommitted changes, or the branch diff when the tree is clean |
| | `/rubber-duck` | Independent critique of the current work |
| | `/pr`, `/ide` | Operate on the branch's pull request; connect to an IDE workspace |
| | `/lsp` | `list`, `test <name>`, `logs`, `reload` |
| **Permissions** | `/permissions` | Switch permission mode: `manual`, `assisted`, `allow-all` |
| | `/allow-all` | Enable all permissions (tools, paths, URLs) |
| | `/sandbox` | Status and policy dialog. `enable`, `disable`, `policy`, `ca create` / `trust` / `rotate` / `remove` |
| | `/add-dir`, `/list-dirs`, `/cwd` | Add an allowed directory / list them / show or change the working directory |
| | `/reset-allowed-tools` | Clear session approvals, turn off allow-all, clear saved approvals for this location |
| **Session** | `/new`, `/clear` | `/new` starts a session and keeps the current one in the background; `/clear` abandons it. `/new worktree` starts in a new git worktree |
| | `/resume [value]` | Switch session by ID, task ID or name. Alias `/continue` |
| | `/fork [name]` | Copy the session and switch to the copy. `/fork worktree` does it in a new worktree |
| | `/worktree`, `/move` | Move the session into a new worktree, leaving / taking the uncommitted changes |
| | `/rewind` | Restore an earlier turn: conversation only, or conversation and files. Cannot be undone. Also `/undo`, or `Esc Esc` on an empty prompt |
| | `/context` | Context window usage by category |
| | `/compact [focus]` | Summarise history to free context |
| | `/usage` | Session usage: changes, credits, tokens per model, plan and rate-limit bars |
| | `/session` | `id`, `info`, `plan`, `checkpoints [n]`, `cleanup`, `prune --older-than <days>`, `delete <id> --yes` |
| | `/share` | `file [path]`, `html [path]`, `gist`, `research`, `link` |
| | `/remote` | `on`, `off`, `show`: steer the session from GitHub web or mobile |
| | `/rename`, `/copy` | Rename the session; copy the last response to the clipboard |
| **Help** | `/help`, `/version`, `/update`, `/changelog` | Help, version, update, changelog (`summarize` for an AI summary) |
| | `/instructions` | View and toggle custom instruction files |
| | `/diagnose` | Analyse session logs, including why a permission request needed approval |
| | `/memory` | Memory status; `on` / `off` |
| **Other** | `/plan` | Create an implementation plan before coding |
| | `/env` | What is loaded: instructions, MCP servers, skills, agents, hooks, plugins, LSPs, extensions |
| | `/limits` | Session limits. `set max-ai-credits <n>`, `unset` |
| | `/settings`, `/config` | Settings UI, or show / set / `unset` one key. `--repo` / `--local` target repo settings |
| | `/subagents` | Per-subagent model and settings; turn a subagent on or off |
| | `/ask` | Side question that is not added to history |
| | `/research`, `/refine` | Deep research with GitHub search and web sources; rewrite a rough prompt into a clear one |
| | `/keep-alive` | Prevent sleep: `on`, `off`, `busy`, or a duration such as `30m` |
| | `/login`, `/logout`, `/user`, `/restart`, `/exit` | Accounts; restart; exit (`/exit print` prints the session) |

Also listed: `/statusline` (`/footer`), `/theme`, `/terminal-setup`, `/experimental`, `/feedback`, `/app`, `/vim`, `/voice`, `/ahp`, `/chronicle`, `/collect-debug-logs`, `/computer`, `/environments`, `/index`, `/search`. `/extensions` is described in `copilot help extensions` (experimental).

## Keyboard shortcuts and input prefixes

| Key | What it does |
|-----|--------------|
| `Enter` while the agent works | Steer: the message joins the running turn |
| `Ctrl+Q` (`Ctrl+Enter` with the kitty protocol) | Queue the message as a new turn |
| `Ctrl+C` | Stop the turn and drop the queue. On an empty idle prompt it warns; a second one quits |
| `Esc Esc` (within 0.5 s) | Cancel or interrupt; on an empty idle prompt, open `/rewind` |
| `Esc` in a permission prompt | Reject and stop the turn |
| `Ctrl+D` on an empty prompt | Quit at once |
| `Shift+Enter`, `Alt+Enter`, `Ctrl+J` | Newline. `Ctrl+J` works in every terminal; `/terminal-setup` fixes `Shift+Enter` |
| `Ctrl+G` | Open the prompt in `$COPILOT_EDITOR`, `$VISUAL` or `$EDITOR` |
| `Up` / `Down`, `Ctrl+R` | Prompt history; reverse search |
| `Ctrl+S` | Stash the draft; again on an empty prompt restores it |
| `Ctrl+O` on an empty prompt | Expand or collapse every timeline entry |
| `Ctrl+T` | Show or hide reasoning summaries |
| `Left` on an empty prompt | Open the Sessions sidebar |
| `?` on an empty prompt | List the shortcuts |

Shortcuts cannot be rebound; there is no key binding setting.

| Prefix | What it does |
|--------|--------------|
| `/` | Slash command or skill: `/board-tests`, `/2048-dev:build-test` **[T]** |
| `!` | Run a shell command yourself. Command and output are added to the conversation |
| `@file` | File mention. The picker hides gitignored files unless `respectGitignore` is `false` |
| lone `$` then `Enter` | Open your interactive shell in the session directory; `exit` returns |

## Where files live

User paths are relative to `~/.copilot` (`$COPILOT_HOME` moves it).

| What | Repository | User |
|------|------------|------|
| Instructions | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `AGENTS.md` | `copilot-instructions.md`, `instructions/*.instructions.md` |
| Skills | `.github/skills/<name>/SKILL.md`, `.agents/skills/` | `skills/`, `~/.agents/skills/`, `skillDirectories` setting |
| Agents | `.github/agents/<name>.agent.md` | `agents/` |
| Hooks | `.github/hooks/*.json`, or `hooks` in repo `settings.json` | `hooks/`, or `hooks` in `settings.json` |
| MCP | `.mcp.json` or `.github/mcp.json` (top-level key `mcpServers`) | `mcp-config.json` |
| Plugins | `extraKnownMarketplaces` + `enabledPlugins` in `.github/copilot/settings.json`; `marketplace.json` | `installed-plugins/` |
| Settings | `.github/copilot/settings.json`, `.github/copilot/settings.local.json` | `settings.json`; `config.json` is CLI state (`trustedFolders`) |
| LSP, extensions | `.github/lsp.json`, `.github/extensions/<name>/extension.mjs` | `lsp-config.json`, `extensions/<name>/extension.mjs` |
| Saved approvals | none | `permissions-config.json` |
| Sessions, logs | none | `session-state/<id>/` (`events.jsonl`, `plan.md`, `session.db`), `logs/` |

- The CLI also reads `CLAUDE.md`, `GEMINI.md`, `.claude/rules/**/*.md`, `.claude/skills/`, `.claude/agents/`, `.claude/commands/` and hooks in `.claude/settings.json`. This repo has no `.claude/` and no `CLAUDE.md`, so nothing loads twice. Personal `~/.claude` is not read.
- `.vscode/mcp.json` is not read. Copy it to `.mcp.json` and rename `servers` to `mcpServers`.
- Workspace MCP servers, repo plugins and project extensions load only after you trust the folder.
- Plugin layout in this repo: `plugins/2048-dev/plugin.json`, `skills/<name>/SKILL.md`, `com.github.copilot/agents/*.agent.md`. With the repo settings above and a trusted folder the plugin loads with no install step **[T]**. `copilot plugin list --json` outside a session does not show it **[T]**.
- Reload: instructions need a new session **[D]**; skills `/skills reload` **[D]**; agents added to `.github/agents/` are picked up in a running session since 1.0.109 **[D]**; MCP `/mcp reload`; LSP `/lsp reload`.

## Frontmatter keys

Agent keys are kebab-case. camelCase is ignored with a warning: `unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList` **[T]**.

| File | Key | Meaning |
|------|-----|---------|
| `*.instructions.md` | `applyTo` | Glob, e.g. `"engine/**/*.kt"`. Listed by `copilot instruction list --json` **[T]**. The body is delivered when the agent reads a matching file (**[T]**, seen on a `view`) or edits one **[D]** |
| | `excludeAgent` | `"code-review"` or `"cloud-agent"` **[D]** |
| `SKILL.md` | `name`, `description` | Required; max 64 and 1024 characters **[D]**. A prompt that fits the description triggers the skill without naming it **[T]** |
| | `argument-hint` | Hint shown in the skill picker **[D]** |
| | `allowed-tools` | Tools pre-approved while the skill is active; not a restriction **[D]** |
| | `user-invocable` | `/name` available to the user; default `true` **[D]** |
| | `disable-model-invocation` | Stop automatic use; default `false` **[D]** |
| `*.agent.md` | `name`, `description` | Load without warnings **[T]** |
| | `tools` | Aliases `read`, `search`, `edit`, `execute`, `agent`, `web`, `todo` **[D]**. `["read", "search"]` gave exactly `view`, `rg`, `glob`, `sql`, `skill` **[T]** |
| | `strict-tools-list` | Only the listed tool groups **[D]**. No observable difference with `--agent` on 1.0.114 **[T]** |
| | `include-custom-instructions` | A subagent also gets the repository instructions **[D]** |
| | `model`, `model-policy` | Preferred model; `model-policy: required` refuses a substitute **[D]**. `model-policy` loads without warnings **[T]** |
| | `reasoning-effort` | Effort for this agent **[D]**. Loads without warnings **[T]** |
| | `mcp-servers`, `hooks` | Agent-scoped MCP servers and hooks **[D]** |

A plugin skill is `<plugin>:<skill>` and a plugin agent is `<plugin>:<agent>` **[T]**.

## Hook events

File shape: `{"version": 1, "hooks": {"<event>": [{"type": "command", "bash": "...", "cwd": ".", "timeoutSec": 30, "matcher": "..."}]}}`.
Event names are camelCase. Every payload has `sessionId`, `timestamp`, `cwd` **[T]**. See [Example 3](03-hooks.md).

| Event | When, and what the payload adds | What its output can do |
|-------|----------------------------------|------------------------|
| `sessionStart` | Session begins. `source`, `initialPrompt` **[T]** | `{"additionalContext": "..."}` reaches the model **[T]** |
| `userPromptSubmitted` | You submit a prompt. `prompt` **[T]** | Use it to log. Docs and changelog disagree on whether its output is used; not tested here |
| `userPromptTransformed` | Carries `prompt` and `transformedPrompt` **[D]** | `{"modifiedTransformedPrompt": "..."}` replaces what the model receives **[D]** |
| `preToolUse` | Before a tool runs. `toolCallId`, `toolName`, `toolArgs` **[T]**. Matcher on tool name | `{"permissionDecision": "deny", "permissionDecisionReason": "..."}` blocks the call, even with `--allow-tool='shell'` **[T]**. Also `allow`, `ask`, `modifiedArgs` **[D]** |
| `permissionRequest` | Before the permission rules engine; not for reads **[D]** | `{"behavior": "allow"}` or `"deny"`, plus `message`, `interrupt` **[D]** |
| `postToolUse` | After a successful tool call. Adds `toolResult: {resultType, textResultForLlm}` **[T]** | `additionalContext`, `modifiedResult` **[D]** |
| `agentStop` | The agent finishes its turn. `transcriptPath`, `stopReason`, `stop_hook_active` **[T]** | `{"decision": "block", "reason": "..."}` sends the agent back; `reason` arrives as the next user message **[T]**. Ends anyway after 8 blocks in a row **[D]** |
| `subagentStart`, `subagentStop` | A subagent starts or finishes. Matcher on agent name **[D]** | `subagentStop`: `decision` + `reason`, `modifiedResponse` **[D]** |
| `sessionEnd` | Session ends. `reason` **[T]** | Nothing verified |
| `postToolUseFailure`, `preCompact`, `errorOccurred`, `notification` | Listed in the hooks reference **[D]** | Nothing verified; see the reference |

| Exit code | Effect |
|-----------|--------|
| `0` | stdout is parsed as one JSON document. Empty or invalid JSON means default behaviour **[D]** |
| `2` | Warning with stderr shown; a deny for `preToolUse` and `permissionRequest` **[D]**. On `agentStop` it does not block: it shows up as `session.warning` **[T]** |
| other non-zero | Logged and skipped. Exception: `preToolUse` denies (fail-closed) **[D]** |
| timeout | The hook is killed and the run continues as if it had not run, for every event **[D]** |

- `matcher` is a regex that must match the whole value, for example `bash|powershell` **[D]**. This repo matches edits with `edit|create|str_replace_editor|apply_patch`.
- `toolArgs` is a JSON object for `bash` (`{"command": "...", "description": "..."}`) and a raw patch string for `apply_patch` **[T]**. GPT-family models use `apply_patch`, and sometimes write files through shell redirection, which no edit matcher sees **[T]**.
- Hook processes run in the repository root **[T]**. The CLI sets `COPILOT_PROJECT_DIR` (also `CLAUDE_PROJECT_DIR`), `COPILOT_HOOK_DIR`, `COPILOT_HOOK_DEPTH` and `COPILOT_CLI=1`.
- Hooks under Claude Code event names (`PreToolUse`, `Stop`, ...) also run, and get `session_id`, `tool_name`, `tool_input` instead.
- Off switch: `disableAllHooks` in settings. Managed `allowManagedHooksOnly` or `strictPluginOnlyCustomization` can block repository hooks **[D]**.

## Permission rules

A rule is `kind(argument)`; the argument is optional. Full text: `copilot help permissions`. See [Example 8](08-permissions-sandbox.md).

| Pattern | Matches |
|---------|---------|
| `shell` / `shell(command)` | Every shell command / one command. Tools such as `git`, `gh`, `npm`, `gradle` match with their first subcommand: `shell(git push)`, `shell(gh pr)` |
| `shell(command:*)` | That command and anything after it: `shell(git:*)` matches `git push`, not `gitea` |
| `write` / `write(path)` | File creation and edits. A relative path matches by trailing components: `write(.env)` is any `.env`. Globs `*`, `?`, `**`; no `!` negation |
| `read` / `read(path)` | File reads by built-in tools; same path matching |
| `<mcp-server>` / `<mcp-server>(tool)` | All tools of an MCP server / one tool |
| `url(domain-or-url)` | URL access by shell and web-fetch tools, e.g. `url(https://*.github.com)` |
| `memory` | Requests to store a memory |

| Tested in this repo **[T]** | Result |
|-----------------------------|--------|
| `--allow-tool='shell(./gradlew:*)'` | ✅ allows `./gradlew :engine:test` |
| `--allow-tool='shell(gradlew:*)'` | ❌ does not match `./gradlew ...` |
| `--allow-tool='shell(./gradlew test)'` | ❌ does not cover `./gradlew :engine:test` |
| `--allow-tool='shell(npm test)'`, `'shell(npm:*)'` | ✅ both allow `cd web && npm test` |
| `--deny-tool='read(.env)'` | ⚠️ blocks the `view` tool, but `cat .env` in the shell still returned the content. The `protect-secrets.sh` hook closes that gap |

- Deny wins over every allow. Flag rules last for the run. "Yes, and don't ask again" is saved per repository or directory in `~/.copilot/permissions-config.json`.
- Commands recognised as read-only run without asking. In autopilot and `-p` runs, a request that would prompt is denied.
- Allow-all still stops at: `--deny-tool` rules, a command asking to leave the sandbox, organisation rules, and `permissions.disableBypassPermissionsMode: "disable"`.
- File access is limited to the working directory and the system temp directory unless you add paths.

| Permission mode | Behaviour |
|-----------------|-----------|
| `manual` (default) | Writes and commands prompt; read-only requests are approved |
| `assisted` | An LLM review approves what it judges safe and asks otherwise. Not a security boundary |
| `allow-all` | Approves everything, like `--allow-all`. Ignored when policy disables it |

Set the mode with `/permissions` or the `defaultPermissionMode` setting. Agent modes are a separate axis: `interactive`, `plan`, `autopilot`.

**Sandbox:** off by default. `/sandbox enable` / `disable`, or `--sandbox` for one session. It confines shell commands (macOS Seatbelt, Linux bubblewrap); built-in file edits follow the policy best-effort. Settings sit under `sandbox` in `settings.json`, user-level only **[D]**.

## Models, credits and limits

| Topic | What to know |
|-------|--------------|
| Pick a model | `/model` in a session, `--model <model-id>` at launch, `COPILOT_MODEL`, or the `model` setting. `auto` lets Copilot choose |
| What you may use | `/model` lists it. The organisation can limit the list; at 2N every model except Fable is allowed. Do not hard-code a model id in a file |
| Effort, plan mode | `--reasoning-effort`, `effortLevel` setting, or left / right arrows in `/model`. Plan mode: `planModel` setting or `/model plan` |
| Billing unit | AI credits. Each model call costs its tokens at the model's per-token price; subagents and compaction count. `/model` shows credits per 1M tokens |
| Budget | 1 credit = $0.01. Copilot Business includes 1,900 credits per user per month, pooled **[D]** |
| See usage | `/usage`; footer `Session: N AIC used`; `--usage-output-file` (`totalNanoAiu`, 10^9 nano AIU = 1 credit) |
| Session cap | `--max-ai-credits <n>` or `/limits set max-ai-credits <n>` (minimum 30); `/limits unset`. Soft cap: one response can go past it, then the next model call is blocked. Subagents share it |
| Rate limits | Session and Weekly bars in `/usage`; warnings at 50, 75, 90 and 95 %. When hit: wait, `/model`, or switch to Auto (`continueOnAutoMode` does it without asking) |
| Autopilot | Pauses after 5 automatic continuations (`--max-autopilot-continues`) |
| Subagents | `/subagents` sets a model per agent. `subagents.maxConcurrency` and `subagents.maxDepth` apply on usage-based billing only |
| Context | `/context` shows usage, `/compact` summarises. Background compaction starts at 80 % of the window by default |

## This repo's commands

| Task | Command |
|------|---------|
| Build and test engine + api | `./gradlew build` |
| Engine tests only | `./gradlew :engine:test` |
| Run the API (port 8080) | `./gradlew :api:bootRun` |
| Run the UI (port 5173, proxies `/api`) | `cd web && npm ci && npm run dev` |
| Web tests, lint, build | `cd web && npm test`, `npm run lint`, `npm run build` |
| Launcher with the workshop rules | `scripts/copilot-ws.sh`, or `scripts/copilot-ws.sh -p "..."`. Allows `shell(./gradlew:*)`, `shell(npm test)`, `shell(npm run)`; denies `read(.env)`, `write(.env)` |
| What did Copilot load? | `copilot instruction list --json`, `copilot skill list --json`, `/env` in a session |
| Plugin agent, headless | `copilot --agent 2048-dev:game-explorer -p "..."` **[T]** |
| Validate eval specs | `npm run eval:lint` |
| Run one eval | `npm run eval -- -e evals/game-explorer/eval.yaml` |
| Skill A/B (spends credits) | `npm run eval:ab`. Plan only, free: `npx vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run` |
| Plugin A/B (spends credits) | `evals/plugin-ab.sh`, or `RUNS=3 MODEL=<model-id> evals/plugin-ab.sh` |
| Conductor | `conductor validate conductor/test-coverage-audit.yaml`, then `conductor run conductor/test-coverage-audit.yaml` (`conductor --silent run ...` for JSON only; `--silent` is a root option and goes before `run`). `conductor doctor` shows provider status |

Eval results land in `evals/results/<timestamp>/`. See [Example 9](09-validate-eval.md) and [Example 14](14-conductor.md).

## Not available in Copilot CLI

For people coming from Claude Code.

| Claude Code has | Copilot CLI 1.0.114 |
|-----------------|---------------------|
| A committed permission file (`permissions.allow` / `deny` in `.claude/settings.json`) | None. Repository settings accept no tool allow or deny key **[D]**. Share rules with launch flags (`scripts/copilot-ws.sh`) or hooks. Declarative allow / ask / deny rules come only from organisation policy |
| Output styles | No equivalent in the help or the settings |
| Prompt files (`.prompt.md`) | Not supported by the CLI **[D]**. Use a skill |
| `plugin validate` | No such subcommand. `copilot plugin` has `install`, `uninstall`, `update`, `list`, `enable`, `disable`, `marketplace`. Check the result with `copilot plugin list --json` and `/env` |
| A built-in eval command | None in the CLI. This repo uses Vally (`npm run eval`). GitHub Copilot Evals is a separate plugin in public preview **[D]** |
| Rebindable keys | Shortcuts cannot be rebound |

---

Reference, not a tutorial. For how and why each mechanism works, see the numbered guides in the [index](README.md).

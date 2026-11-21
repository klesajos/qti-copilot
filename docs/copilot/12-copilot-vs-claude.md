> 🌍 Read this in: **English** | [Česky](12-copilot-vs-claude.cs.md)

# 12 · Copilot vs Claude Code: what is only here

> ⏱ 10 min (talk + questions: talk through the Models and GitHub platform rows and the wrap-up; the rest is reference) · Docs: [Copilot customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet) · [Claude Code docs index](https://code.claude.com/docs/llms.txt) · Verified on Copilot CLI 1.0.114 · Compared on 2026-11-21 with the Claude Code docs of that day; both tools change monthly, so re-check a row before you decide on it

## In short

**You need:** Nothing to install: this is a talk. It helps if you did the Claude Code workshop.

**What it is for:** Shows what Copilot has and Claude Code does not, what is the same idea under another name, and how one repo can serve both tools without trouble.

**Three uses that pay off most:**

1. Know which Copilot-only features are worth using in a team: the choice of models, the GitHub integration, the metrics.
2. Carry your Claude Code habits over with the name-mapping table.
3. Stop a repo that both tools read from sending the same instructions twice.

## Only in Copilot

Ordered by how much a developer feels the difference. Where Claude Code has a partial
substitute, the middle column names only what is still missing. "—" = not part of the workshop.

| Feature | What exactly Claude Code lacks | In this workshop |
|---|---|---|
| **Models** | | |
| [Models from several vendors](https://docs.github.com/en/copilot/reference/ai-models/supported-models) in one picker (`/model`, `--model <model-id>`) | It runs Claude models only. [No gateway may route it to another vendor's model](https://code.claude.com/docs/en/llm-gateway) | [00](00-llm-basics.md) |
| [Your own and local models](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-llm-models): OpenAI-compatible, Azure, Ollama, offline mode | Any OpenAI-compatible or Ollama endpoint, and an offline mode | [00](00-llm-basics.md) |
| `--model auto` ([Copilot Fusion](https://docs.github.com/en/copilot/concepts/models/copilot-fusion)) | A router that picks the model for each prompt and switches when a model is rate-limited. Nearest: `opusplan`, the advisor, `--fallback-model` (overload only) ([docs](https://code.claude.com/docs/en/model-config)) | [00](00-llm-basics.md) |
| [`/rubber-duck`](https://docs.github.com/en/copilot/concepts/agent-capabilities/choosing-and-delegating-agent-work/getting-a-second-opinion): critique of your plan or diff on another model family | A second opinion from a different vendor. Its [advisor](https://code.claude.com/docs/en/advisor) is always another Claude model | [cheat sheet](cheatsheet.md) |
| Plan mode with its own effort: `planEffortLevel`, `/model plan` | A separate effort setting for plan mode. `opusplan` gives plan mode its own model only ([docs](https://code.claude.com/docs/en/model-config)) | [00](00-llm-basics.md) |
| **GitHub platform** | | |
| [Built-in GitHub MCP server](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-mcp-servers): starts at sign-in, read-only by default | A GitHub server without setup: you add one with a token or install a plugin ([docs](https://code.claude.com/docs/en/mcp)) | [05](05-mcp.md) |
| [`/pr`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/manage-pull-requests): create, fix review comments, conflicts and CI, merge; Issues and Pull requests tabs | One command that also resolves conflicts and merges, the tabs, a CI status footer. `/autofix-pr` covers CI failures and review comments ([docs](https://code.claude.com/docs/en/claude-code-on-the-web)) | — |
| [`/delegate`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/delegate-tasks-to-cca): send the running session to the cloud agent, which opens a draft PR | Sending the running session from the CLI (`claude --cloud` starts a new one; the Desktop app can), a draft PR on handoff, `--base` | [11](11-ide-remote.md) |
| [Assign an issue to Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/kick-off-a-task); start the cloud agent from [Jira, Teams, Linear, Azure Boards](https://docs.github.com/en/copilot/concepts/agent-capabilities/choosing-and-delegating-agent-work/about-copilot-integrations) | An assignee identity: you build it as an [Actions workflow](https://code.claude.com/docs/en/github-actions). An entry point from those four tools (Slack only) | [11](11-ide-remote.md) |
| CLI in GitHub Actions on the built-in [`GITHUB_TOKEN`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli-in-actions) | Auth by `GITHUB_TOKEN` and metering to the GitHub organization: its Action needs an Anthropic credential | [10](10-orchestration.md) |
| [Copilot Memory](https://docs.github.com/en/copilot/concepts/prompting-and-context/copilot-memory): repository facts kept on GitHub (preview) | Facts shared with the team, the cloud agent and code review without a commit. Its auto memory is machine-local ([docs](https://code.claude.com/docs/en/memory)) | — |
| [Copilot Spaces](https://docs.github.com/en/copilot/concepts/prompting-and-context/spaces) through the built-in MCP tools `list_copilot_spaces`, `get_copilot_space` | A shared, curated context store. It has connectors and a committed `CLAUDE.md` | [05](05-mcp.md) |
| **Governance, billing and metrics** | | |
| [Per-user CLI metrics](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics) for admins: `used_cli`, sessions, requests, tokens | A per-user daily "used the CLI" field, and a per-user metrics API on plans below Enterprise ([docs](https://code.claude.com/docs/en/analytics)) | [01](01-getting-started.md) |
| Org policy that [switches the CLI on or off](https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise) and applies [content exclusion](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/content-exclusion) to it | A switch for the whole tool (it has per-feature disables) and a content-exclusion policy (you write deny rules yourself) ([docs](https://code.claude.com/docs/en/managed-settings)) | [08](08-permissions-sandbox.md) |
| AI-credit cap for an interactive session or one autopilot objective: [`--max-ai-credits`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/set-session-limit) | A cost cap in an interactive session. `--max-budget-usd` works with `-p` only; [`/goal`](https://code.claude.com/docs/en/goal) shows spend and does not stop on it | [00](00-llm-basics.md), [10](10-orchestration.md) |
| [Dynamic workflow](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-dynamic-workflows) limits per run: `workflows.defaultLimits.timeoutSeconds`, `.maxAiCredits` | A documented time limit or cost ceiling for one workflow run | [10](10-orchestration.md) |
| **Customization and tooling** | | |
| Live read of other tools' files: `CLAUDE.md`, `GEMINI.md`, `.claude/rules`, `.claude/skills`, Claude plugins | It reads `AGENTS.md` and nothing else of another tool. The rest is a one-time copy with `/init` or `/import` ([docs](https://code.claude.com/docs/en/memory)) | [02](02-custom-instructions.md) |
| [`copilot instruction list --json`](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions), the per-file switch `/instructions`, `excludeAgent` | A JSON list of the loaded instruction files, an interactive per-file switch, a way to hide a file from code review or the cloud agent | [02](02-custom-instructions.md) |
| [Sandbox](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/about-cloud-and-local-sandboxes) on native Windows, and around MCP servers, language servers and extensions | Both. Its [sandbox](https://code.claude.com/docs/en/sandboxing) covers shell commands only and needs WSL2 on Windows | [08](08-permissions-sandbox.md) |
| Project skills in [`.github/skills/` and `.agents/skills/`](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills); `copilot skill add <file, URL or directory>` | A project skill folder other than `.claude/skills/`, and a command that installs a skill from a file or URL | [03](03-skills.md) |
| Hook event [`userPromptTransformed`](https://docs.github.com/en/copilot/reference/hooks-reference#hook-events); a `"type": "prompt"` hook at `sessionStart` | An event that rewrites the prompt text (`UserPromptSubmit` only blocks or adds context); a hook that submits a prompt when an interactive session starts (`SessionStart` does it in `-p` runs only) | [04](04-hooks.md) |
| Agent key [`model-policy: required`](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-agent-frontmatter-fields) | A model lock for one agent (`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` applies to every subagent) | [06](06-agents.md) |
| [Agent Plugins](https://agent-plugins.org/specification) manifest; `enabledPlugins` installs a missing plugin from a GitHub marketplace (an open CLI issue can leave it inactive); `copilot plugin install --from-github` | The vendor-neutral manifest; install on folder trust (each contributor runs `claude plugin install` once, unless managed settings install it); a one-step digest-verified install | [07](07-plugins.md) |
| [`copilot --acp`](https://docs.github.com/en/copilot/reference/copilot-cli-reference/acp-server): the CLI as an ACP agent for Zed or a JetBrains IDE (preview) | A built-in ACP mode. ACP editors reach it through a third-party adapter; Zed ships one | [11](11-ide-remote.md) |

Also only in Copilot, not part of this workshop: [`/research`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/research-with-copilot-cli), one flow over local code, org repos
and the web; [`/chronicle`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle), standup text, tips and skill proposals from session history; local
sessions synced to GitHub, `/share link` and `/share gist`; [code review](https://docs.github.com/en/copilot/concepts/agent-capabilities/agent-powered-workflows-and-operations/code-review) started by a ruleset, open
to members without a licence; [third-party agents](https://docs.github.com/en/copilot/concepts/agent-capabilities/about-agents/about-third-party-coding-agents) (Claude, Codex) assigned an issue, billed to the
Copilot plan; language servers in a user or project file (`.github/lsp.json`), with rename;
OpenTelemetry export to a file; [`/computer`](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-mcp-servers) in the CLI on Windows.

## Same idea, different name

| Mechanism | Copilot CLI | Claude Code | What trips you when you switch |
|---|---|---|---|
| [Repository instructions](02-custom-instructions.md) | `.github/copilot-instructions.md` | `CLAUDE.md` | Copilot merges it with `AGENTS.md` and `CLAUDE.md`, no precedence. Claude Code reads `AGENTS.md` only when there is no `CLAUDE.md` |
| [Path-scoped instructions](02-custom-instructions.md) | `.github/instructions/*.instructions.md`, key `applyTo:` | `.claude/rules/*.md`, key `paths:` | Different key, same delivery: when a matching file is read or edited |
| [Skills](03-skills.md) | `.github/skills/<name>/SKILL.md` | `.claude/skills/<name>/SKILL.md` | Same open format. `model`, `context: fork` and `paths` are Claude Code keys, not Copilot keys |
| [Hooks](04-hooks.md) | `.github/hooks/*.json`; `preToolUse`, `agentStop`; payload `toolName`, `toolArgs` | `hooks` in `.claude/settings.json`; `PreToolUse`, `Stop`; payload `tool_name`, `tool_input` | A PascalCase event name in Copilot switches the payload to snake_case and Claude tool names. A stop hook that exits 2 blocks in Claude Code; in Copilot print `{"decision":"block","reason":"..."}` |
| [Custom agents](06-agents.md) | `.github/agents/*.agent.md`; `tools: ["read", "search", "execute"]` | `.claude/agents/*.md` (subagents); `tools: Read, Grep, Bash` | Copilot keys are kebab-case and a camelCase key gives a warning. Claude Code ignores an unknown key silently |
| [Plugins and marketplaces](07-plugins.md) | `plugin.json` + root `marketplace.json`; enabled in `.github/copilot/settings.json` | `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`; enabled in `.claude/settings.json` | Same keys `extraKnownMarketplaces`, `enabledPlugins`. Copilot installs a Claude plugin unchanged; Claude Code does not read the Agent Plugins manifest |
| [Permissions](08-permissions-sandbox.md) | Launch flags `--allow-tool='shell(./gradlew:*)'`, `--deny-tool='read(.env)'`, plus a `preToolUse` hook | `permissions.allow` / `ask` / `deny` in `.claude/settings.json` | Copilot has no committed rule file in the repository. LLM approval judge: `--assisted-approval` here, auto mode there |
| [Sandbox](08-permissions-sandbox.md) | `/sandbox` on macOS, Linux, Windows | `/sandbox` on macOS, Linux, WSL2 | In Claude Code hooks and MCP servers run outside the sandbox |
| [Evals](09-evals.md) | Vally: `npm run eval`, `npm run eval:ab` | `claude plugin eval` | Copilot CLI has no built-in eval command. GitHub Copilot Evals (`/eval`) is a preview plugin |
| [`/fleet` and workflows](10-orchestration.md) | `/fleet`, `copilot --fleet -p`; `copilot workflow run` | Parallel subagents; `.claude/workflows/*.js` run as `/<name>` | `/fleet` reports into the conversation as it goes; a Claude workflow takes no input mid-run and returns one result. Copilot workflows are experimental and registered by an extension |
| [Cloud delegation](11-ide-remote.md) | `/delegate` | `claude --cloud "<task>"`, back with `--teleport` | `/delegate` sends the session you are in; `--cloud` starts a new one from the pushed branch |
| [Remote control](11-ide-remote.md) | `/remote on`, then GitHub.com or GitHub Mobile | `/remote-control`, then claude.ai/code or the Claude app | An admin has to allow it in both. The session keeps running on your machine |

## Only in Claude Code

| Claude Code feature | Nearest in Copilot CLI |
|---|---|
| [Output styles](https://code.claude.com/docs/en/output-styles): a file in `.claude/output-styles/` sets role, tone and answer format | A session agent that only sets the answer format: `copilot --agent workshop-tutor` ([06](06-agents.md)). One at a time; it does not shape subagents |
| [Permission rules committed in the repository](https://code.claude.com/docs/en/permissions) | `scripts/copilot-ws.sh` and the `protect-secrets.sh` hook ([08](08-permissions-sandbox.md)). `.github/copilot/settings.json` ignores permission keys |
| [Hooks judged by a model](https://code.claude.com/docs/en/hooks): `type: "prompt"` and `type: "agent"` | A `command` hook with a script. Copilot's `prompt` hook only submits text at `sessionStart` ([04](04-hooks.md)) |
| [`/doctor prompt-audit`](https://code.claude.com/docs/en/memory): finds outdated and contradicting instruction files | `copilot instruction list --json` shows what loads; nothing checks the content ([02](02-custom-instructions.md)) |
| [`claude plugin validate` and `claude plugin details`](https://code.claude.com/docs/en/plugins/cli-reference): manifest check and context cost | Check `plugin.json` against the [Agent Plugins schema](https://agent-plugins.org/schemas/1.0.0/plugin.schema.json), `npm run eval:lint`, `/context` ([09](09-evals.md)) |

## One repo, both tools

Copilot CLI reads Claude Code's project files. Claude Code reads almost nothing of Copilot's.

- **What Copilot loads from other tools, and what it skips:** the table in
  [02](02-custom-instructions.md#a-repo-that-already-has-ai-instructions).
- **Claude Code loads** nothing under `.github/`. `/init` copies the relevant parts of
  `.github/copilot-instructions.md` into `CLAUDE.md` once.
- **The trap:** a repo with `CLAUDE.md` and `.github/copilot-instructions.md` sends both to Copilot
  on every model call: only identical copies are dropped, no file wins, and Claude hooks run too.
  Keep one always-on file, `AGENTS.md` (Copilot merges it; Claude Code reads it when there is no
  `CLAUDE.md`), and check with `copilot instruction list --json`. This repo has no `.claude/`.

## Wrap-up: Monday in your own repo

- **Audit the instructions.** Run `copilot instruction list --json` in one of your repos and
  remove what is loaded twice ([02](02-custom-instructions.md)).
- **Write one skill** for the change you make most often, for example "add an endpoint"
  ([03](03-skills.md)).
- **Add one hook:** a `preToolUse` deny for secrets or an `agentStop` test gate ([04](04-hooks.md)).
- **Copy the launcher** `scripts/copilot-ws.sh` and put in your own build and test commands
  ([08](08-permissions-sandbox.md)).
- **Write one eval** before you share a skill with other teams: same prompt, with and without the skill
  ([09](09-evals.md)).

Back to the [README](README.md) · [exercises](exercises.md)

> 🌍 Read this in: **English** | [Česky](12-intellij.cs.md)

# Example 12: The IntelliJ IDEA plugin

> ⚠️ **Nothing in this guide was tested in IntelliJ IDEA for this repo.** It is assembled from
> the plugin's release notes, GitHub's docs and changelog, and the plugin's issue tracker, as of
> plugin 1.21.1 (2026-11-16). Several items exist only in release notes. Use the
> [checklist](#verify-on-your-own-plugin-version) before you rely on any of them.

## Why this guide exists

IntelliJ IDEA is allowed at 2N, and most of you live in it. Two facts shape how to use it:

1. **2N's metrics look for Copilot CLI usage.** Work done through the plugin is reported as IDE
   usage, not CLI usage.
2. **The plugin reads many of the same repository files as the CLI, but not all, and not in the
   same way.** The guard rails this repo ships as hooks are the main gap.

## What the plugin supports

Minimum plugin versions, from the release notes. "GA" is the version where the notes call the
feature generally available.

| Feature | First version | GA / current state |
|---------|---------------|--------------------|
| `.github/copilot-instructions.md` | 1.5.42 | Supported |
| `.github/instructions/*.instructions.md` | 1.5.53 | `applyTo` fixed in 1.5.62 |
| `AGENTS.md`, `CLAUDE.md` | 1.6.1 | Nested files behind a setting under Settings → GitHub Copilot → Customizations |
| Agent mode | 1.5.45 (preview) | Treated as a normal feature since; no explicit GA line found |
| Custom agents (`.agent.md` in `.github/agents`), sub-agents, Plan agent | 1.5.60 | GA in 1.6.1 |
| Agent skills | 1.5.64 (preview) | GA in 1.10.0; organisation and enterprise skills in 1.18.0 |
| Hooks (`.github/hooks/`) | 1.6.1 (preview) | GA in 1.10.0; editable in Agent Customizations from 1.12.1; workspace trust enforced from 1.13.0 |
| Prompt files (`.github/prompts/*.prompt.md`) | 1.5.55 | GA in 1.10.0 |
| Plugins and marketplaces | 1.13.0 (preview) | GA in 1.16.0 |
| Root `.mcp.json` for the Copilot agent | 1.19.0 | Supported, with open bugs (below) |
| "MCP servers in Copilot" policy | 1.5.53 | Registry allow-list from 1.5.62; managed `allowedMcpServers` / `deniedMcpServers` from 1.15.0 |
| Copilot CLI agent inside the IDE | 1.9.0 (preview) | Renamed to "Copilot" in 1.15.0; harness GA in 1.16.0; **default agent for everyone in 1.20.0** |
| `/ide` from a terminal CLI session | 1.17.0 | Preview |
| Next edit suggestions | 1.5.55 (preview) | GA announced 2026-10-28 |
| Code review | 1.5.57 | Inline review in 1.5.58; `/review` in agent mode from 1.16.0; Copilot agent review engine from 1.21.0 |
| Correct attribution of agent sessions in metrics | 1.20.0 | See [metrics](#how-usage-is-attributed-in-metrics) |

IDE versions: the plugin needs IntelliJ 2025.2 or later (support for 2025.1 ended in 1.19.0),
and 1.21.0 announces that 2025.2 will be dropped in favour of 2025.3 or later.

The docs.github.com pages lag behind: the JetBrains feature matrix stops at plugin 1.5.66, and
the customization cheat sheet still marks hooks as unsupported in JetBrains IDEs. Go by the
release notes.

## What this repo's files do in IDEA

| File in this repo | In IDEA | Caveat |
|-------------------|---------|--------|
| `.github/copilot-instructions.md` | ✅ Read | |
| `.github/instructions/engine.instructions.md`, `api.instructions.md` | ✅ Read, with `applyTo` | Needs 1.5.62 or later for `applyTo` |
| `AGENTS.md`, `CLAUDE.md` | n/a | The repo ships neither, on purpose |
| `.github/agents/kotlin-reviewer.agent.md`, `board-test-writer.agent.md` | ✅ Custom agents | Which frontmatter keys the plugin honours depends on the surface. `strict-tools-list` and `include-custom-instructions` are documented for the CLI only |
| `.github/skills/board-tests/SKILL.md` | ⚠️ Skills are GA | `.github/skills` is documented generically; no JetBrains source confirms which project folders the plugin reads |
| `.github/hooks/hooks.json` | ⚠️ Partly | See the next section. This is the important one |
| `.github/copilot/settings.json` (enables the `2048-dev` plugin) | ❓ Undocumented | The plugin has its own plugin store. Assume the repo setting does nothing here |
| `plugins/2048-dev/`, `marketplace.json` | ⚠️ Manual | Add the marketplace and install the plugin in the IDE's Customizations panel |
| `.mcp.json` (the repo ships only `.mcp.json.example`) | ✅ Root `.mcp.json` with `mcpServers` | The one MCP file both clients read. See the bugs below |
| `scripts/copilot-ws.sh` | ❌ | Launch flags are a CLI concept. The IDE has its own approval settings |
| `evals/`, `conductor/` | ❌ | Terminal tools. Run them in the IDE's terminal |

### Hooks: four published events

The only hook events GitHub has published for JetBrains are `userPromptSubmitted`,
`preToolUse`, `postToolUse` and `errorOccurred`. This repo's `hooks.json` uses five entries on
four events:

| Entry in `hooks.json` | Event | In IDEA |
|-----------------------|-------|---------|
| `git-context.sh` | `sessionStart` | ❓ Not a published event |
| `block-destructive.sh` | `preToolUse`, matcher `bash\|powershell` | ⚠️ Event exists; the matcher may not match |
| `protect-secrets.sh` | `preToolUse`, matcher `bash\|powershell\|view` | ⚠️ Same |
| `format.sh` | `postToolUse`, matcher `edit\|create\|str_replace_editor\|apply_patch` | ⚠️ Same |
| `run-tests.sh` | `agentStop` | ❓ Not a published event |

Why the matchers are in doubt: they are regular expressions on the CLI's tool names. A user
report in the plugin's tracker says the IDE's terminal tool is called `run_in_terminal`, that
only camelCase event names are read, and that only a `deny` decision is honoured. None of that
is confirmed by a maintainer.

The consequence is simple: **do not assume that the repo's guard rails are active in the IDE's
agent.** In the terminal CLI they were tested. In the IDE they were not.

## What differs or is missing

- **A separate plugin store.** The IDE keeps installed plugins in its own location, not in
  `~/.copilot/`. A plugin installed or enabled for the CLI does not appear in the IDE. Open bugs
  at the time of writing: plugin skills disappear after an IDE restart, a marketplace is never
  refreshed, and Update ignores a new ref.
- **An older CLI runtime inside.** The Copilot agent in the IDE bundles its own runtime:
  plugin 1.20.0 shipped CLI runtime 1.0.96, plugin 1.21.0 shipped 1.0.103. The terminal CLI in
  this workshop is 1.0.114. Anything that changed in between may behave differently, for
  example: environment values for MCP servers passed literally unless written `${NAME}`
  (1.0.108), agents added to `.github/agents/` picked up in a running session (1.0.109), an
  error instead of a silent switch for an unavailable model (1.0.109), and the built-in GitHub
  MCP server following the organisation's MCP policy (1.0.112).
- **Hook events**, as above.
- **Prompt files exist only here.** `.github/prompts/*.prompt.md`, invoked as `/name`, work in
  the IDE and not in the CLI. The repo ships none; the CLI equivalent is a skill. A prompt file
  you write for yourself in IDEA is invisible to colleagues on the CLI.
- **MCP configuration differs.** The IDE's global file is a single `mcp.json` with the top-level
  key `servers`. `.github/mcp.json` uses `servers` in the IDE and `mcpServers` in the CLI, so
  it cannot serve both. A root `.mcp.json` with `mcpServers` is the only shared form. Known
  bugs with it in the IDE: environment references in headers and `env` are sent literally, and
  stdio servers start in the IDE's working directory instead of the project root. Avoid
  `${VAR}` and relative paths in a server the IDE must start.
- **Content exclusion.** An open issue (plugin 1.21.0) reports that agent mode reads files that
  the organisation's content exclusion blocks in the CLI. A fix is announced for the next
  release.
- **Policies.** The organisation's "Editor preview features" policy gates the plugin's preview
  features. The Copilot agent in the IDE stays available even where the Copilot CLI policy is
  off (plugin 1.13.0 and later).

## The Copilot CLI agent inside the IDE, and `/ide`

Two bridges exist between the tools. They go in opposite directions.

**IDE → CLI runtime.** Since 1.20.0 the default agent in the plugin's chat is the "Copilot"
agent, which runs on the bundled CLI runtime (the "harness"). It has Agent, Ask, Plan and custom
agent modes, and its hooks and MCP servers are managed in Agent Customizations. It feels like
the CLI. It is an older runtime, and it is **not counted as CLI usage** on a current plugin.

**CLI → IDE context.** In a terminal session, `/ide` connects the CLI to an IDE workspace. For
JetBrains this is a preview since plugin 1.17.0 and shares selections, diagnostics and file
references with the terminal session. GitHub's `/ide` documentation covers VS Code only, and no
minimum CLI version is stated for JetBrains.

## How usage is attributed in metrics

What the Copilot usage metrics API reports, per the docs:

| Where | What is in it |
|-------|---------------|
| `totals_by_cli` | CLI only: `session_count`, `request_count`, `prompt_count`, `token_usage.*`. Also `daily_active_cli_users` and `used_cli` |
| `totals_by_ide[]` | IDE only, with `last_known_ide_version` and `last_known_plugin_version`. **CLI activity is not here** |
| `totals_by_feature` | CLI activity appears as `feature: copilot_cli` (since 2026-04-10). The top-level totals are IDE and CLI combined |
| `totals_by_client[].client` | `copilot_cli`, `jetbrains`, `copilot_sdk` and others. Derived from the integration ID each client sends; documented as best effort |
| `totals_by_skill`, `totals_by_custom_agent`, `totals_by_mcp`, `totals_by_slash_cmd`, `totals_by_plugin` | Customization usage, API only. Prompt mode needs CLI 1.0.97 or later |

The usage dashboard's charts exclude the CLI. The impact dashboard shows Copilot CLI as a
feature, counting a user who used it on at least two days in 28.

**The 1.15.0–1.19.x misattribution.** Those plugin versions ran agent sessions through the
Copilot SDK without identifying the IDE. That activity is missing from the IDE metrics, and some
of it was counted as Copilot CLI activity, which inflates the CLI numbers. It is fixed from
1.20.0, it is not backfilled, and billing is not affected.

What this means for you:

- **To be counted as a CLI user, run `copilot` in a terminal.** The IDE's terminal tool window
  is a terminal; the binary is the same one. That is an inference from how clients identify
  themselves, not a documented statement. What an active `/ide` connection does to attribution
  is not documented either.
- **The Copilot agent in the plugin's chat does not count as CLI** on plugin 1.20.0 or later. On
  1.15.0–1.19.x some of it did, by mistake. Do not rely on that.
- **Upgrade to 1.20.0 or later**, 1.21.0 or later if 2N also looks at customization usage. On an
  older plugin your IDE agent work is partly invisible and partly miscounted.
- **We do not know which field 2N reads.** The facilitator asks before the workshop; see the
  [preflight checklist](preflight.md). If the number that matters to you looks wrong, ask the
  2N Copilot admin which field and which period it comes from.

## A recommended way of working

| Task | Tool | Why |
|------|------|-----|
| Agent work: plan, implement, test, review ([Example 10](10-level-5-workflow.md)) | `copilot` in the IDE's terminal tool window, started with `scripts/copilot-ws.sh` | Tested hooks and permission rules, the current runtime, counted as CLI |
| Give the agent your selection or the current diagnostics | `/ide` from that terminal session (preview) | The editor's context without leaving the CLI |
| Completions and next edit suggestions while you read or adjust | The plugin | The CLI has no equivalent. They are not billed in AI credits |
| Reading the diff, navigating, running a single test, debugging | IDEA itself | It is what the IDE is best at |
| Review before a commit | `kotlin-reviewer` or `/review` in the CLI first; the plugin's inline review as a second view | The CLI agent gets the repo instructions; the IDE shows findings in place |
| Sharing a workflow with the team | A skill or an agent in `.github/` | Both clients read them. A prompt file reaches IDE users only |

One working tree, two agents: do not let the IDE's agent and a CLI session edit the same files
at once. Use a worktree for the CLI session if you want both.

## Verify on your own plugin version

Ten minutes, once per plugin upgrade. Every item here is known from release notes or issue
reports only.

1. Settings → Plugins: GitHub Copilot is **1.20.0 or later**. Note the exact version.
2. In the plugin's chat, check which agent is selected by default. It should be "Copilot".
3. Ask: *"Which instruction files were you given for this repository? List their paths."*
   Expect `.github/copilot-instructions.md`.
4. Open `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt` and ask the same question.
   `engine.instructions.md` should now be in the list (in the CLI a scoped file arrives when
   the agent reads or edits a matching file; how the IDE decides is not documented).
5. Open the agent picker. `kotlin-reviewer` and `board-test-writer` should be listed.
6. Ask: *"What are this project's conventions for board tests?"* The answer should match
   `.github/skills/board-tests/SKILL.md` (backtick test names, `boardOf(...)`).
7. Hooks, the important one: ask the agent to read `.env`. In the CLI the answer is
   `Denied by preToolUse hook: protect-secrets hook: ...`. Write down what the IDE does. Do this
   on a checkout without a real `.env`.
8. Ask it to make a small edit, then stop. Does a formatter run (`postToolUse`)? Does the test
   hook report anything (`agentStop`)? Expect "no" for the second.
9. Agent Customizations: are the repo's hooks listed? Is the `2048-dev` plugin there? Expect
   the plugin to be missing until you install it in the IDE.
10. In a terminal `copilot` session, run `/ide` and check that the IDE is offered.

Tell the facilitator what you found. The results decide what goes into the next version of this
guide.

## Where it works

| Surface | Reads this repo's customizations? | Counted as CLI usage? |
|---------|-----------------------------------|-----------------------|
| **Copilot CLI in any terminal**, the IDE's included | ✅ All of them | ✅ |
| **Plugin chat, "Copilot" agent** | ⚠️ Instructions, agents and skills; hooks partly; the repo plugin not automatically | ❌ on 1.20.0 or later |
| **Plugin completions and next edit suggestions** | n/a | ❌ |
| **Copilot cloud agent** | See [Example 13](13-remote-agents.md) | ❌ |

## Troubleshooting

- **The agent ignores the repo's conventions** → check the plugin version (instructions need
  1.5.42, `applyTo` 1.5.62), then ask it which instruction files it was given.
- **A hook that works in the CLI does nothing in the IDE** → expected for `sessionStart` and
  `agentStop`. For `preToolUse` and `postToolUse` the matcher probably does not match the IDE's
  tool names. Do the work in the terminal CLI.
- **The `2048-dev` skill or the `game-explorer` agent is missing** → the IDE has its own plugin
  store. Add the marketplace and install the plugin in Customizations.
- **Plugin skills vanished after restarting the IDE** → a known open bug. Reinstall, or use the
  CLI.
- **An MCP server from `.mcp.json` fails only in the IDE** → environment references are sent
  literally and stdio servers start in the wrong directory. Use absolute commands and no
  `${VAR}` for that server.
- **The IDE's agent behaves differently from the terminal CLI on the same prompt** → the bundled
  runtime is older than your terminal CLI. Compare the versions before you report a bug.
- **`/ide` shows nothing** → preview since plugin 1.17.0; update the plugin and keep the project
  open in the IDE.
- **Your CLI numbers look too high or too low** → plugin 1.15.0–1.19.x miscounted agent
  sessions. Upgrade, and remember the old data is not corrected.

---

Next: letting an agent work while you are away →
[Example 13: Remote and overnight agents](13-remote-agents.md).

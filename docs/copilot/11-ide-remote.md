> 🌍 Read this in: **English** | [Česky](11-ide-remote.cs.md)

# 11 · IntelliJ IDEA and remote agents

> ⏱ 5 min (talk: the first three tables; the numbered lists, the Coder section and the comparison table are reading for after the workshop) · Docs: [Copilot in IDEs](https://docs.github.com/en/copilot/concepts/copilot-surfaces/copilot-in-ides) · [Usage metrics fields](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics) · [/delegate](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/delegate-tasks-to-cca) · [Remote control](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/steer-remotely) · [Coder](https://github.com/coder/coder) · Nothing here was run for this repo: not in IntelliJ IDEA, not `/delegate`, not `/remote`, not on Coder. Sources: [plugin release notes](https://plugins.jetbrains.com/plugin/17718-github-copilot/versions) up to 1.21.1, the CLI 1.0.114 help, the GitHub and Coder docs

## IntelliJ IDEA plugin

IntelliJ IDEA is allowed at 2N. The plugin's chat agent reads most of this repo's files, but not
all of them in the same way, and it is not what 2N's metrics count. Android Studio and Xcode
users: this section covers IntelliJ IDEA only; the terminal CLI is the tool all six stacks share.

| File in this repo | In the plugin | Note |
|-------------------|---------------|------|
| `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | ✅ | `applyTo` needs plugin 1.5.62 or later |
| `.github/agents/*.agent.md` | ⚠️ | `strict-tools-list` and `include-custom-instructions` are documented for the CLI only |
| `.github/skills/board-tests/` | ⚠️ | Skills are supported; no JetBrains source names the project folders the plugin reads |
| `.github/hooks/hooks.json` | ⚠️ | Published events: `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`. `sessionStart` and `agentStop` are not among them, and the matchers are written for the CLI's tool names. Do not assume the guard rails are active |
| `.github/copilot/settings.json`, `plugins/2048-dev/` | ⚠️ | Assume the repo setting does nothing: the IDE has its own plugin store. Add the marketplace and install `2048-dev` in Customizations |
| Root `.mcp.json` (the repo ships `.mcp.json.example`) | ⚠️ | The one MCP file both clients read. In the IDE `${VAR}` is sent literally and stdio servers start in the IDE's directory |
| `scripts/copilot-ws.sh`, `evals/`, `conductor/` | ❌ | Terminal tools. Run them in the IDE's terminal |
| `.github/prompts/*.prompt.md` (none in this repo) | ✅ | IDE only; the CLI ignores prompt files. To share a workflow, write a skill |

**The CLI agent inside the IDE.** Since plugin 1.20.0 the default chat agent is "Copilot". It
runs on a CLI runtime bundled with the plugin, older than your terminal CLI: plugin 1.21.0 ships
1.0.103, this workshop uses 1.0.114. `/ide` in a terminal session goes the other way: it gives
the CLI the IDE's selection, diagnostics and file references (preview since plugin 1.17.0). An
IDE can also start the CLI as its agent with [`copilot --acp`](https://docs.github.com/en/copilot/reference/copilot-cli-reference/acp-server) (public preview).
Do agent work with `scripts/copilot-ws.sh` in the IDE's terminal: tested hooks and rules, the
current runtime, counted as CLI. Keep the plugin for completions and next edit suggestions.

> 🔷 **Copilot only:** `copilot --acp` is a built-in ACP server mode; Claude Code has none and
> reaches ACP editors only through a third-party adapter.

**How usage is attributed in 2N's metrics.** The CLI has its own counters: `totals_by_cli`
(sessions, requests, prompts, tokens) and a daily `used_cli` flag per user.¹

| What you run | Reported as |
|--------------|-------------|
| `copilot` in a terminal, the IDE's terminal included | ✅ CLI |
| The plugin's chat agent, completions, next edit suggestions | ❌ JetBrains (plugin 1.20.0 or later) |
| Vally evals and Conductor (Copilot SDK), `/delegate` (cloud agent) | ⚠️ Assume not CLI until 2N confirms |

Plugin 1.15.0–1.19.x counted some IDE agent sessions as CLI activity
([fixed in 1.20.0, not backfilled](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/usage-metrics-coverage)):
upgrade the plugin. Which field 2N reads is a question in [preflight.md](preflight.md).

¹ The docs page contradicts itself on `totals_by_feature`: one section says CLI usage is not
reflected there, the feature table lists `copilot_cli`. Ask which field a number comes from.

**Verify on your plugin version** (once per plugin upgrade):

1. Settings → Plugins: GitHub Copilot is 1.20.0 or later, and the default chat agent is "Copilot".
2. Ask *"Which instruction files were you given for this repository? List their paths."* Expect
   `.github/copilot-instructions.md`, and `engine.instructions.md` once `Board.kt` is open.
3. The agent picker lists `kotlin-reviewer`, `board-test-writer` and `workshop-tutor`. Ask *"What
   are this project's conventions for board tests?"*: the answer names backtick test names and
   `boardOf(...)`.
4. Ask the agent to read `.env`, on a checkout without a real one. If the hook runs in the IDE,
   you get the CLI's answer `Denied by preToolUse hook: protect-secrets hook: ...`; if the agent
   attempts the read, note that the guard rails are not active in the plugin.
5. In a terminal `copilot` session run `/ide`. If it works, the IDE is offered and the CLI gets its
   selection and diagnostics; if not, tell the facilitator your plugin version (preview since 1.17.0).

## Remote and overnight work

When you leave, nobody answers prompts (a request that would ask is denied) or notices a loop
(set a credit and a turn limit), and review moves to the end: level 8, or 9 if you skip it.

| Way | The agent runs | Needs | Use it when |
|-----|----------------|-------|-------------|
| `/delegate` | On GitHub, as the Copilot cloud agent | The Copilot CLI and cloud agent policies; the repo on GitHub | The task is well specified and the laptop may close |
| `/remote on` | On your machine | The policy "Store local sessions in the Cloud" set to "View and control"; the machine on and online | The task needs your local setup or unpushed files |
| Coder Workspaces | On 2N's infrastructure | A Coder template with Copilot CLI and a GitHub login in the workspace | The job outlives a night. Planned at 2N |

**`/delegate` to the cloud agent.** Type `/delegate <prompt>`, or start a prompt with `&`.
Copilot offers to commit your unstaged changes as a checkpoint on a new branch. The cloud agent
opens a draft pull request, works in the background and requests your review. The pull request
targets your current branch; `/delegate --base <branch>` changes that.
[Assigning an issue to Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/overview) on GitHub starts the same agent.

> */delegate Fix the no-op move bug: GameService.move must not spawn a tile when board.move returns false. Write the failing test first, without relying on random tiles. Do not change engine/. Run ./gradlew :api:test and report the counts in the pull request description.*

The committed files apply in the job: instructions, skills, agents, plugin settings and
`hooks.json` (only `bash` and `command` entries run, `ask` becomes a deny, an `agentStop` block
counts against the job's time limit). The flags of `scripts/copilot-ws.sh` do not. Runners are
Ubuntu x64 or Windows 64-bit: no `xcodebuild`, so iOS work stays local. Preinstall what the build
needs (`jq` for the hooks, the Android SDK) in [`copilot-setup-steps.yml`](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment).

> 🔷 **Copilot only:** `/delegate` opens the draft pull request itself and takes `--base`, and an
> issue can be assigned to Copilot like to a person; Claude Code's cloud sessions create the pull
> request from claude.ai/code, and assign-to-agent has to be built as an Actions workflow.

**`/remote`: steer a local session from another device.** `/remote on` shows a link for
GitHub.com and GitHub Mobile. There you answer permission requests and questions, approve plans
and send prompts; slash commands are not available. The session keeps running on your machine
with your hooks and launch rules. Interactive sessions only, not `-p` runs.

1. `scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)'`, then `/new worktree`.
2. `/plan <spec>`, read the plan (`Ctrl+E` shows all of it), choose **Accept plan and continue in
   Autopilot execution mode**. Autopilot grants nothing: what the launch rules do not allow is
   denied, and it pauses after 5 continuations.
3. `/limits set max-ai-credits <n>`, `/keep-alive busy` (no sleep while it works), `/remote on`.
4. Back: read why it stopped, `git diff --stat`, run the tests yourself, read the diff of every
   test file that already existed, and have `kotlin-reviewer` review the branch.

**Coder Workspaces.** [Coder](https://github.com/coder/coder) is a self-hosted platform for remote development
environments: an administrator writes a Terraform template, each developer gets a
[workspace](https://coder.com/docs/user-guides/workspace-access) built from it, and the agent runs there, not on your laptop.

- **Run Copilot CLI in the workspace**, not [Coder Agents](https://coder.com/docs/ai-coder/agents):
  that is Coder's own agent, and its docs do not mention Copilot. `copilot` in a workspace is the
  same binary with the same repo files. Overview: [AI coding agents in Coder](https://coder.com/docs/ai-coder).
- **The registry module** [`registry.coder.com/coder-labs/copilot/coder`](https://github.com/coder/registry/blob/main/registry/coder-labs/modules/copilot/README.md)
  is a community module (`verified: false`). It installs and configures the CLI; you start
  `copilot` yourself. The README pins `1.0.1`, the registry serves `1.0.0`.
- **The overnight run** is the `-p` mode from [guide 10](10-orchestration.md) in a workspace terminal:

```bash
scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)' \
    --autopilot --max-autopilot-continues 20 --max-ai-credits 300 \
    --trust-folder --no-ask-user --share="$HOME/overnight-session.md" -p "<spec>"
```

Open for the pilot: a JDK, Node and `jq` in the workspace image; how the GitHub login reaches
the workspace; whether these runs count as CLI usage; who looks when a run stops at 2 a.m.

## Copilot vs Claude Code

| Copilot | Claude Code | What differs |
|---------|-------------|--------------|
| `/delegate` | `claude --cloud "<task>"` | Claude Code: no automatic draft pull request, no `--base` |
| Assign an issue to Copilot | Claude Code GitHub Action on issue events | Claude cannot be an assignee; you build the trigger |
| `/remote on` | Remote Control (`/remote-control`) | Equivalent |
| Cloud sandbox session (`/environments`, `--connect`) | Cloud sessions, `--teleport` | Equivalent |
| `/ide`, JetBrains plugin | `/ide`, JetBrains plugin | Claude's plugin runs the `claude` CLI in the IDE terminal; Copilot's has its own chat agent |
| `copilot --acp` | None built in | Zed ships an adapter for Claude Code |
| `used_cli`, `totals_by_cli` | Analytics dashboard, Enterprise Analytics API | No per-user daily CLI flag |

Next: [12 · Copilot vs Claude Code](12-copilot-vs-claude.md)

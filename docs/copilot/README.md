> 🌍 Read this in: **English** | [Česky](README.cs.md)

# GitHub Copilot extension examples

This repo doubles as a showcase of the **project-scoped** ways to extend
GitHub Copilot CLI. "Project-scoped" means the configuration lives **inside the
repository**: when you `git clone` the project, you get the instructions, the
skill, the agents, the hooks and the plugin with it. Nothing is installed into
your home directory. The one thing a clone does not give you is consent: the
hooks and the plugin load only after you answer the folder-trust prompt
([guide 00](00-install.md)).

Guides 01–09 each cover one mechanism and are independent and minimal. Guides
10–14 are about how to work with them. Go in order; they run from simplest to
most advanced:

| # | Example | What it teaches | Where it lives |
|---|---------|-----------------|----------------|
| 0 | [Install and first session](00-install.md) | Installing Copilot CLI, login, folder trust, choosing a model, AI Credits, running the 2048 app | your machine |
| 1 | [Custom instructions](01-custom-instructions.md) | Standing orders for the repo: one file for every session, path-scoped files that load only when matching files are touched, `AGENTS.md` | `.github/copilot-instructions.md` + `.github/instructions/` |
| 2 | [Skills](02-skills.md) | Project knowledge Copilot loads only when the task needs it | `.github/skills/board-tests/SKILL.md` |
| 3 | [Hooks](03-hooks.md) | Shell scripts that run on session events: inject git context, block destructive commands, guard `.env`, format, run tests | `.github/hooks/hooks.json` + `.github/hooks/scripts/` |
| 4 | [MCP](04-mcp.md) | Connecting Copilot to external tools when the organization allows only an approved list | `.mcp.json.example` |
| 5 | [Custom agents](05-agents.md) | Handing one task to an isolated context with its own tools: a reviewer that cannot edit, a test writer | `.github/agents/` |
| 6 | [Plugins](06-plugins.md) | Packaging skills and agents for other repos; an in-repo marketplace enabled by repository settings | `plugins/2048-dev/` + `marketplace.json` + `.github/copilot/settings.json` |
| 7 | [Orchestration](07-orchestration.md) | Several agents on one task: `/fleet`, plan and autopilot modes, dynamic workflows | built into the CLI; uses the agents in `.github/agents/` |
| 8 | [Permissions & sandbox](08-permissions-sandbox.md) | Allow and deny rules as launch flags, a hook as the committed guard, the local sandbox | `scripts/copilot-ws.sh` + `.github/hooks/scripts/protect-secrets.sh` |
| 9 | [Validate & eval](09-validate-eval.md) | Measuring whether a skill, agent or plugin changes anything: with/without runs scored by graders | `evals/` + `package.json` |
| 10 | [Level 5 workflow](10-level-5-workflow.md) | The working loop where Copilot writes the code and you still understand all of it | the whole repo |
| 11 | [Programmatic mode & CI](11-programmatic-ci.md) | `copilot -p`, JSONL output, permissions when nobody can answer a prompt | `evals/plugin-ab.sh` as a worked example |
| 12 | [IntelliJ IDEA](12-intellij.md) | What the JetBrains plugin reads from this repo and where it behaves differently from the CLI | the same `.github/` files |
| 13 | [Remote agents](13-remote-agents.md) | Handing work to an agent that runs somewhere else: the cloud agent, Coder workspaces | nothing in the repo |
| 14 | [Conductor](14-conductor.md) | A multi-agent flow defined in YAML and run on the Copilot provider | `conductor/test-coverage-audit.yaml` |

Every guide exists in two languages: `xx-name.md` is English, `xx-name.cs.md`
is Czech. They have the same content. Three more files sit next to the guides:

- [exercises.md](exercises.md): the hands-on tasks, one or more per mechanism.
- [cheatsheet.md](cheatsheet.md): flags, slash commands and file locations on
  one page.
- [preflight.md](preflight.md): checks to run on your own machine, on the
  client network, before the workshop day. Organization-managed settings can
  switch off skills, hooks, plugins or MCP without telling you; this is where
  you find out.

## Before you start

You need:

1. **Copilot CLI 1.0.114 or later, logged in** with the account that holds
   your Copilot Business seat. See [guide 00](00-install.md).
2. **This repo cloned:** `git clone https://github.com/klesajos/qti-copilot`
3. **A terminal opened in the repo root** (the folder containing
   `settings.gradle.kts`). All examples assume that working directory.
4. **A JDK 17–27, Node.js 24.15+ or 26, `jq` and `git`.** The hook scripts
   need `jq`; without it the guards switch themselves off.
5. **The folder trusted** when Copilot asks. Read
   `.github/hooks/hooks.json` first if you want to know what you are
   agreeing to run.

No guide or exercise uses a screenshot or an image. Image input is disabled
for the audience this workshop was written for, so everything is text.

**How to read "tested".** The CLI behaviour described in these guides was run
on Copilot CLI 1.0.114 on 2026-11-21 in this repository. Where a guide says
"per the docs", the claim comes from GitHub's documentation or a changelog and
was not run here.

## Quick demo script (5 minutes)

For a facilitator, live. Every step uses something that is in this repo and
was run on 1.0.114.

1. **Instructions.** Before starting a session, run
   `copilot instruction list`. It prints the three instruction files the repo
   ships; add `--json` to see the `applyTo` globs of the two path-scoped ones.
2. **Hook that adds context.** Start `copilot` in the repo root and trust the
   folder. Ask:

   > *"Which branch am I on and which files are uncommitted? Answer from what you already know; do not run a command."*

   Copilot answers without a tool call. The `sessionStart` hook
   (`git-context.sh`) put that into its context before your first prompt.
3. **Skill.** Ask:

   > *"Add a test for sliding the line 4, 4, 8, 0"*

   Copilot calls the `skill` tool with `board-tests` before it writes
   anything. A correct test expects `8, 8, 0, 0` and fails, because the
   current code returns `16, 0, 0, 0`. That is deliberate bug 1.
4. **Hook that blocks.** In another terminal create a throwaway file,
   `echo 'DEMO_KEY=not-a-secret' > .env` (it is git-ignored). Then ask:

   > *"Print the contents of .env"*

   The call is refused with `Denied by preToolUse hook: protect-secrets hook: ...`.
   The hook inspects shell commands as well as the `view` tool. A
   `--deny-tool='read(.env)'` rule on its own stops `view`, but `cat .env`
   still gets through. Delete the file afterwards.
5. **Plugin skill.** Type `/2048-dev:build-test`. The plugin was never
   installed by hand; `.github/copilot/settings.json` enabled it when you
   trusted the folder. The skill tells Copilot to build, run every suite and
   report the result without fixing anything.
6. **Plugin agent.** In a second terminal:

   ```bash
   copilot --agent 2048-dev:game-explorer --trust-folder \
     -p "Trace how a keypress becomes a board move."
   ```

   The agent declares `tools: ["read", "search"]`. In the test run it used
   only `rg` and `view`.
7. **Eval, free of charge.** `npm ci` in the repo root, then
   `npm run eval:lint`. Both eval specs validate; it is a static check of the
   YAML. The paid run behind them (`npm run eval:ab`) is the reason the skill
   in step 3 is worth having: without the skill the positive case passed 0 of
   4 trials, with it 3 of 4 ([guide 09](09-validate-eval.md)).

## Where each mechanism works

Copilot reads this repository in three places, and **not everything works in
all of them**. Each guide has its own "Where it works" section; the summary:

| Project-scoped mechanism | CLI (terminal) | IntelliJ plugin | Cloud agent |
|--------------------------|:--------------:|:---------------:|:-----------:|
| Custom instructions (`.github/copilot-instructions.md`, `.github/instructions/`) | ✅ | ✅ | ✅ |
| Skills (`.github/skills/`) | ✅ | ✅ | ✅ |
| Hooks (`.github/hooks/`) | ✅ | ⚠️ only `userPromptSubmitted`, `preToolUse`, `postToolUse` and `errorOccurred` are published; nothing confirms `sessionStart` or `agentStop` | ⚠️ loads the same files; an `ask` decision becomes a deny, and an `agentStop` block counts against the job timeout |
| MCP (`.mcp.json`) | ✅ after folder trust, within the organization's MCP policy | ⚠️ root `.mcp.json` is read since plugin 1.19.0; open bugs with environment references and the working directory | ⚠️ not covered by this workshop; do not assume it reads your local file |
| Custom agents (`.github/agents/`) | ✅ | ✅ supported frontmatter keys depend on the surface | ✅ |
| Plugin enabled by repository settings | ✅ | ⚠️ the IDE keeps its own plugin store; install the plugin inside the IDE | ⚠️ reads `enabledPlugins` and `extraKnownMarketplaces` from `.github/copilot/settings.json`, so the commit affects cloud runs too |
| Orchestration (`/fleet`, plan, autopilot) | ✅ | ⚠️ has its own sub-agents and Plan agent; `/fleet` is not confirmed there | it is where `/delegate` sends the work |
| Permissions & sandbox (`scripts/copilot-ws.sh`) | ✅ | ❌ launch flags belong to the terminal command; the guard hooks are the shared part | ❌ runs on GitHub, not on your machine |
| Evals (`evals/`) | ✅ a terminal tool that starts its own Copilot sessions | ❌ run them from a terminal | ❌ |

✅ works · ⚠️ works with limits, or not confirmed · ❌ not available.

The CLI column was tested in this repo. The other two columns come from
GitHub's documentation and the JetBrains plugin release notes (plugin 1.21.1);
none of it was run here.

Why the columns differ: the terminal CLI is the reference implementation. The
IntelliJ plugin has used the Copilot CLI agent as its default agent since
plugin 1.20.0, but it bundles its own, older CLI runtime, so a feature that
arrived in a recent CLI release may not be there yet. The cloud agent runs on
GitHub against the pushed repository, not on your machine, so your local trust
decisions, launch flags and `~/.copilot` settings play no part. Details are in
[guide 12](12-intellij.md) and [guide 13](13-remote-agents.md).

## Which mechanism should I use when?

- **Custom instructions:** what is true for every task in the repo (stack,
  layout, conventions, commands). Loaded into every session, so keep it short.
- **Path-scoped instructions:** rules that matter only in one part of the
  tree. They cost nothing until a matching file is read or edited.
- **Skill:** when you want Copilot to *know how* to do something (write tests
  this project's way, run a release). The model decides when to load it.
- **Hook:** when something must happen *every time*, whatever the model
  thinks (formatting, blocking a command, running tests). The model has no say.
- **MCP:** when Copilot needs a *capability* it does not have (read a Jira
  issue). Under a restricted policy, only servers on the approved list.
- **Custom agent:** when *one* self-contained task should run in its own
  context with its own tools (a reviewer that cannot edit, a codebase mapper).
- **Plugin:** when a skill or agent should be *shared* across repos as one
  versioned package. Good material for a guild.
- **`/fleet`:** when the work splits into parts that do not depend on each
  other. Each subagent calls the model on its own, so it costs more.
- **Launch flags:** to pre-approve the routine commands of a repo for one run,
  and to deny what must never run.
- **Eval:** when you need evidence that a skill, agent or plugin changes the
  outcome, before you ask a whole team to adopt it.
- **Conductor:** when the same multi-agent flow has to run the same way every
  time, outside anybody's interactive session.

## How this differs from the Claude Code workshop

For people who attended the workshop built on `dxc-ws`. The ideas carry over;
the file names and a few rules do not.

| Claude Code (`dxc-ws`) | Copilot CLI (this repo) | What changes |
|------------------------|-------------------------|--------------|
| `CLAUDE.md` | `.github/copilot-instructions.md` | Same role. `AGENTS.md` is read too, and merged, not used as a fallback |
| `.claude/rules/*.md` with `paths:` | `.github/instructions/*.instructions.md` with `applyTo:` | Same idea: delivered when a matching file is read or edited |
| `.claude/skills/` | `.github/skills/` | Same `SKILL.md` format, shorter frontmatter list |
| Hooks in `.claude/settings.json` | `.github/hooks/*.json` | camelCase event names; a blocking stop hook answers with JSON, not with an exit code |
| `.claude/agents/*.md` | `.github/agents/*.agent.md` | kebab-case frontmatter keys; `tools` uses aliases such as `read`, `search`, `execute` |
| `permissions` in `.claude/settings.json` | launch flags (`--allow-tool`, `--deny-tool`) + a `preToolUse` hook | There is no committed allow/deny file at repository level |
| `.claude-plugin/marketplace.json` | `marketplace.json` + `plugins/2048-dev/plugin.json`, enabled in `.github/copilot/settings.json` | Plugin skills are called `/plugin:skill` here as well |
| `.claude/workflows/` | `/fleet`, dynamic workflows, Conductor | No single equivalent. Dynamic workflows are a public preview behind experimental mode (per the docs) |
| Output styles | no equivalent | Put tone and format rules into the instructions |
| `claude plugin eval` | Vally (`@microsoft/vally-cli`), GitHub Copilot Evals | The CLI has no built-in eval command. Copilot Evals is a public preview and is not vendored here |
| `.mcp.json` | `.mcp.json` | Same file name and `mcpServers` key. This repo ships only `.mcp.json.example` |

**Warning: Copilot CLI also reads Claude Code's files.** In a project it
loads `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/`, `.claude/skills/`,
`.claude/agents/`, `.claude/commands/` and the hooks in
`.claude/settings.json`, next to everything under `.github/`. A repository
that carries both sets gets its instructions twice, in two slightly different
wordings, and its Claude hooks run under Copilot. That is why this repo has
**no `.claude/` directory and no `CLAUDE.md`**. Your personal `~/.claude/` is
not read. If you add Copilot to a repo that already serves Claude Code, run
`copilot instruction list` and `/env` first and look at what actually loads
([guide 01](01-custom-instructions.md)).

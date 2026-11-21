> 🌍 Read this in: **English** | [Česky](07-plugins.cs.md)

# 07 · Plugins and sharing across teams

> ⏱ 15 min (7 demo + 8 exercise 6) · Docs: [Plugins for GitHub Copilot](https://docs.github.com/en/copilot/concepts/customizations/plugins) · [Creating a plugin](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating) · [Finding and installing plugins](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing) · Verified on Copilot CLI 1.0.114

## In short

**You need:** The CLI. To share a tool with other teams: a git repository that hosts the marketplace.

**What it is for:** A plugin packs skills, agents, hooks and MCP servers into one bundle with a name and a version. It is how a tool you built in one repo reaches all the other repos of your company.

**Three uses that pay off most:**

1. Share a team tool: colleagues install it by name instead of copying files.
2. Switch a team toolset on for a whole repo with two settings keys; everyone gets it after trusting the folder.
3. Version a tool, so a change can be rolled out and rolled back.

## What is a plugin?

A **plugin** is a directory with a manifest, `plugin.json`, that bundles skills, agents, hooks, MCP
servers and LSP servers under one name and version. A **marketplace** is a catalog file,
`marketplace.json`, that lists plugins and says where to fetch each one.

Guides 02 to 06 put everything into one repo's `.github/`. A company has dozens of repos, several stacks and
teams that share tools. A plugin in a marketplace repo is how a shared tool reaches the other
repos: versioned, installed by name, or switched on per repo with two settings keys.

## What this example does

```
marketplace.json                          ← catalog "qti-copilot": the repo is its own marketplace
plugins/2048-dev/                         ← the plugin
├── plugin.json                           ← manifest, Agent Plugins 1.0
├── skills/build-test/SKILL.md            ← portable part: a skill → /2048-dev:build-test
└── com.github.copilot/agents/
    └── game-explorer.agent.md            ← Copilot part: an agent → 2048-dev:game-explorer
.github/copilot/settings.json             ← enables the plugin after folder trust: no install step
```

## The files, line by line

**`plugins/2048-dev/plugin.json`**
```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "2048-dev",
  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
  "version": "1.0.0",
  "author": { "name": "Josef Klesa", "url": "https://github.com/klesajos" }
}
```
- `$schema` — this exact value selects the [Agent Plugins 1.0](https://agent-plugins.org/specification)
  format. Without it the plugin loads as a legacy plugin, which keeps agents in `agents/`.
- `name` — the prefix of every component: `/2048-dev:build-test`, `2048-dev:game-explorer`;
  `/skills`, `/env` and the `/agent` picker list the bare names. A project skill or agent with
  the same name wins; the plugin's copy is silently ignored.
- `version` — shown in `/env` as `2048-dev (1.0.0)`. Raise it with every change.
- No field points at components; locations are fixed. `skills/<name>/SKILL.md` and `mcp.json` sit
  at the plugin root. Agents, hooks, commands, rules and `lsp.json` go under `com.github.copilot/`.

> 🔷 **Copilot only:** the manifest follows the vendor-neutral Agent Plugins spec, with the Copilot-specific parts under `com.github.copilot/`. Claude Code plugins use Claude's own manifest, `.claude-plugin/plugin.json`, not this spec.

**`marketplace.json`** (repo root; shortened)
```json
{ "name": "qti-copilot", "owner": { "name": "Josef Klesa" },
  "plugins": [ { "name": "2048-dev", "version": "1.0.0", "source": "./plugins/2048-dev" } ] }
```
- `name` — the marketplace ID, the part after `@` in `2048-dev@qti-copilot`. `owner` is required.
- `plugins[].source` — a path relative to the repo root: the plugin ships in this repo. A plugin
  in another repo uses `{"source": "github", "repo": "owner/repo", "path": "plugins/x", "sha": "<commit>"}`.

**`.github/copilot/settings.json`**
```json
{ "extraKnownMarketplaces": { "qti-copilot": { "source": { "source": "directory", "path": "." } } },
  "enabledPlugins": { "2048-dev@qti-copilot": true } }
```
- `extraKnownMarketplaces` — the marketplace `qti-copilot` is the directory `.`, the checkout
  itself. Nothing is fetched; the plugin loads live from the working tree.
- `enabledPlugins` — key `<plugin>@<marketplace>`. On in this repository only, and only after
  folder trust (`copilot -p` needs `--trust-folder`). Your opt-out: the same key set to `false`
  in `.github/copilot/settings.local.json` (git-ignored here).

> 🔷 **Copilot only:** with a marketplace on GitHub, `enabledPlugins` also installs a missing plugin after folder trust (an open CLI issue can leave it inactive: see Troubleshooting). In Claude Code the same two keys enable it, but each contributor still runs `claude plugin install` once unless managed settings install it.

## Create your own, step by step

1. Add `plugins/2048-dev/skills/<skill>/SKILL.md` with `name` and `description`. Raise `version`
   in `plugin.json` and in the plugin's entry in `marketplace.json`.
2. Validate it (no `copilot plugin validate` exists). Expect `plugins/2048-dev/plugin.json valid`:
   ```bash
   curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
   npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
   ```
3. Check that a new session loads it. Expect `"2048-dev:build-test"` and your new skill:
   ```bash
   copilot -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | .commandName' | sort -u
   ```
4. Mount a plugin that no settings file enables yet (a new one, a shared marketplace repo). Nothing is installed:
   ```bash
   copilot --plugin-dir ./plugins/2048-dev               # then /2048-dev:build-test
   copilot --plugin-dir ./plugins/2048-dev plugin list   # no model call; lists "2048-dev (v1.0.0)"
   ```

## Share a tool across teams

One marketplace repo that every team member can read (the names are examples):

```
team-copilot-plugins/
├── marketplace.json                      ← "name": "team-tools", one entry per plugin
└── plugins/kotlin-review/
    ├── plugin.json
    └── skills/review-pr/SKILL.md
```

1. Create the repo. Copy `marketplace.json` and `plugin.json` from this repo and change both
   `name` values, or start from [github/plugin-marketplace-starter](https://github.com/github/plugin-marketplace-starter).
2. Move a tool that has proved itself in one repo's `.github/` into `plugins/<plugin>/`: skills
   to `skills/<skill>/SKILL.md`, agents and hooks under `com.github.copilot/`. An MCP server in
   a plugin must still pass your organisation's MCP allow-list.
3. List the plugin in `marketplace.json` with `"source": "./plugins/<plugin>"`.
4. Mount it with `--plugin-dir`, try it, and validate the manifest (steps 2 and 4 above).
5. Push. Give the teams read access to the repo; organisation membership alone is not enough.
6. Each colleague runs, once (⚠️ not run in this repo):
   `copilot plugin marketplace add <owner>/<repo>`, then `copilot plugin install <plugin>@<marketplace>`.
7. Or a project enables it for its whole team: commit the two settings keys with the marketplace
   source `{"source": "github", "repo": "<owner>/<repo>"}` (⚠️ not run in this repo).
8. To release a change, raise `version` in both files. Colleagues run
   `copilot plugin update <plugin>@<marketplace>` (⚠️ not run in this repo).

## Try the demo

1. Start `scripts/copilot-ws.sh` in the repo root, trust the folder, run `/2048-dev:build-test`.
2. Answer the one or two prompts with **1. Yes**. Copilot builds, tests and fixes nothing; ours
   ended `Tests: engine 13 passed/0 failed; API 5 passed/0 failed; web 7 passed/0 failed`.
3. `copilot plugin list` outside the session lists installed and built-in plugins, not `2048-dev`.

## Optional parameters

| Where | Field | What it does |
|-------|-------|--------------|
| `marketplace.json` entry | `source` object with `ref`, `sha` | Pins a remote plugin to a branch, tag or commit |
| Environment | `COPILOT_PLUGIN_DIR_ONLY=true` | Loads only `--plugin-dir` plugins. `evals/plugin-ab.sh` uses it to compare runs with and without the plugin |
| `copilot plugin install` | `owner/repo`, `owner/repo:path`, a git URL | Direct installs. They print a deprecation warning; install by `<plugin>@<marketplace>`. There is no local-path source: use `--plugin-dir` |

> 🔷 **Copilot only:** `copilot plugin install --from-github <resource@revision>` with the digests copied from github.com verifies the exact files and asks you to confirm before it installs. Claude Code pins a plugin by commit SHA or sha256 in the marketplace entry and has no one-step verified install.

Full reference: [GitHub Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|-----|-----------------|-------------|
| ✅ Committed settings plus folder trust | ⚠️ Has its own plugin store; a CLI install does not appear there. Whether it reads the plugin keys in `.github/copilot/settings.json` is not documented ([11](11-ide-remote.md)) | ✅ Reads both keys from the committed settings; there is no local opt-out |

## Copilot vs Claude Code

Claude Code has the same mechanism under the same names: plugin, marketplace, and the same two
keys in `.claude/settings.json`. Its manifest is `.claude-plugin/plugin.json`; Copilot CLI also
installs plugins in that format and reads the two keys from `.claude/settings.json`. Claude Code
has `claude plugin validate`; Copilot CLI has no validate command, hence the schema check.

## Troubleshooting

- **`/2048-dev:build-test` is unknown** → `settings.local.json` opts you out, or a `-p` run has no `--trust-folder`. A policy that blocks plugins shows up in `scripts/check-setup.sh` ([01](01-getting-started.md)).
- **The skill loads but the agent is missing** → `$schema` is not the exact 1.0.0 value (legacy plugin).
- **A plugin skill never runs** → a project skill with the same name shadows it. Rename one.
- **Enabled from a remote marketplace but never active** → an [open CLI issue](https://github.com/github/copilot-cli/issues/4837). Install it by name.

Next: [08 · Permissions and sandbox](08-permissions-sandbox.md)

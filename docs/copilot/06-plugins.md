> 🌍 Read this in: **English** | [Česky](06-plugins.cs.md)

# Example 6: Plugins and an in-repo marketplace

## What is a plugin?

A **plugin** is a directory with a manifest that bundles Copilot CLI extensions: skills,
agents, hooks, MCP servers, LSP servers. A **marketplace** is a catalog file,
`marketplace.json`, that lists plugins and says where to fetch each one.

In Examples 2 to 5 the skill, hooks and agents sit directly in `.github/`. That works for one
repo. A plugin is the same content packaged so it can move to other repos and other people,
with a name and a version.

This example is the smallest complete setup: the repo is **its own marketplace**
(`qti-copilot`) offering **one plugin** (`2048-dev`) that bundles **one skill** and **one
agent**. A committed settings file switches it on, so nobody runs an install command.

## The moving parts

```
marketplace.json                              ← the marketplace catalog (repo root)
plugins/2048-dev/                             ← the plugin
├── plugin.json                               ← manifest, Agent Plugins 1.0
├── skills/build-test/SKILL.md                ← portable component: a skill
└── com.github.copilot/agents/
    └── game-explorer.agent.md                ← Copilot-specific component: an agent
.github/copilot/settings.json                 ← registers the marketplace, enables the plugin
```

Four layers, from the inside out: a **skill and an agent** live in a **plugin**, which is
listed in a **marketplace**, which the repo's **settings** point to.

## Layer 1: the skill and the agent

**The skill** is `plugins/2048-dev/skills/build-test/SKILL.md`:

```markdown
---
name: build-test
description: Build the 2048 project and run every test suite (Gradle and Vitest), then summarize the results without fixing anything. Use when asked to build, to run all tests, or to check whether the tree is green.
---

# Build and test

Build the project and run the tests:

1. Backend: `./gradlew build`
2. Frontend: `cd web && npm test && npm run lint && npm run build`
...
- Do not fix anything. This skill only reports status.
```

- Same format as a project skill (Example 2): `name`, `description`, then the work order.
- Per the docs, a skill must sit in its own subdirectory directly under `skills/`. In this
  plugin format there is no fallback to a `SKILL.md` at the plugin root.
- There is no `disable-model-invocation: true`, so the model may also load the skill on its
  own. That also avoids a known problem: per an open issue, a manual-only skill answers
  "Skill not found" in `-p` runs.

**The agent** is `com.github.copilot/agents/game-explorer.agent.md`, a read-and-search agent
described in [Example 5](05-agents.md). Note where it lives: not next to `skills/`, but
under `com.github.copilot/`. Layer 2 explains why.

## Layer 2: the manifest (`plugins/2048-dev/plugin.json`)

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "2048-dev",
  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
  "version": "1.0.0",
  "author": {
    "name": "Josef Klesa",
    "url": "https://github.com/klesajos"
  }
}
```

- `$schema` — this exact string opts the plugin into the **Agent Plugins 1.0** format. Per
  the docs, a manifest without one of the recognised values is loaded as a *legacy* plugin,
  and one that declares a version the CLI does not support is rejected outright. Pin 1.0.0:
  the 1.1.0 spec was still a working draft when this guide was written.
- `name` — the plugin's identifier. It becomes the prefix of its skills and agents
  (`2048-dev:...`) and the part before `@` in `2048-dev@qti-copilot`. Lowercase letters,
  digits, hyphens and periods; at most 64 characters.
- `version` — shown in `copilot plugin list` (`2048-dev (v1.0.0)`). Raise it when the
  plugin changes.
- `description`, `author` — metadata.

**What belongs at the root, and what under `com.github.copilot/`.** In Agent Plugins 1.0 the
manifest describes the plugin and nothing else. It has no fields that point at components;
the locations are fixed (per the docs):

| Location in the plugin | Holds | Scope |
|------------------------|-------|-------|
| `plugin.json` | Manifest. Allowed fields: `$schema`, `name`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `extensions` | Portable |
| `skills/<name>/SKILL.md` | Skills | Portable |
| `mcp.json` | MCP servers. Needs its own `$schema` line | Portable |
| `com.github.copilot/agents/` | Custom agents (`*.agent.md`) | Copilot only |
| `com.github.copilot/commands/`, `rules/` | Slash commands, rules | Copilot only |
| `com.github.copilot/hooks/hooks.json` | Hooks | Copilot only |
| `com.github.copilot/lsp.json` | LSP servers | Copilot only |

The root holds what the plugin spec defines for any tool that implements it. Everything that
only Copilot understands goes into Copilot's own namespace directory. An unknown top-level
field in `plugin.json` is reported and ignored.

**The legacy format, for contrast** (per the docs):

```json
{
  "name": "my-dev-tools",
  "description": "React development utilities",
  "agents": "agents/",
  "skills": ["skills/", "extra-skills/"],
  "hooks": "hooks.json",
  "mcpServers": ".mcp.json"
}
```

No `$schema`, component paths configurable in the manifest, and agents in `agents/` at the
plugin root. GitHub recommends Agent Plugins 1.0 for new plugins. The CLI also loads Claude
Code plugin layouts (`.claude-plugin/plugin.json`) as legacy plugins.

## Layer 3: the marketplace (`marketplace.json` at the repo root)

```json
{
  "name": "qti-copilot",
  "owner": {
    "name": "Josef Klesa"
  },
  "metadata": {
    "description": "Plugins for the qti-copilot GitHub Copilot workshop",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "2048-dev",
      "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
      "version": "1.0.0",
      "source": "./plugins/2048-dev"
    }
  ]
}
```

- `name` — the marketplace's identifier and the part after `@`. Per the docs it is the
  registration key and cannot be overridden locally; the repository name plays no role.
- `owner` — required; who maintains the catalog.
- `plugins[].source` — a path relative to the repo root: the plugin ships with the repo. A
  catalog can also point elsewhere with an object such as
  `{"source": "github", "repo": "owner/repo", "path": "plugins/my-plugin"}`. That is how one
  central marketplace lists plugins from many repos.
- Location — per the docs the CLI looks for `marketplace.json`, `.plugin/marketplace.json`,
  `.github/plugin/marketplace.json`, then `.claude-plugin/marketplace.json`. This repo uses
  the root, like GitHub's own starter template.

## Layer 4: auto-enable (`.github/copilot/settings.json`)

```json
{
  "extraKnownMarketplaces": {
    "qti-copilot": {
      "source": {
        "source": "directory",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "2048-dev@qti-copilot": true
  }
}
```

- `extraKnownMarketplaces` — "this repo uses a marketplace called `qti-copilot`, and it is
  the directory `.`", which is the checkout itself. Nothing is fetched from the network. For
  a marketplace in another repo the source is `{"source": "github", "repo": "OWNER/REPOSITORY"}`.
- `enabledPlugins` — "from that marketplace, switch on `2048-dev`". The key is
  `<plugin-name>@<marketplace-name>`.

**It takes effect after folder trust.** Repository plugin settings are part of what you
approve at the folder-trust prompt. Once the folder is trusted, the plugin is switched on in
this repository only, not in your other projects. Tested on 1.0.114: in a trusted folder the
plugin loads with no install step. A `copilot -p` run needs `--trust-folder` for the same
result.

## How plugin skills and agents are named

Tested on 1.0.114:

| Component | Name in the file | Name you use |
|-----------|------------------|--------------|
| Skill | `build-test` | `/2048-dev:build-test` |
| Agent | `game-explorer` | `2048-dev:game-explorer`, for example `--agent 2048-dev:game-explorer` |

The separator is a **colon**. One page of the docs shows a slash form (`/my-plugin/search`);
that is not what 1.0.114 does. The slash command also works in `-p` mode (tested). There it
needs its tools approved up front:

```bash
copilot -p "/2048-dev:build-test" --trust-folder \
  --allow-tool='shell(./gradlew:*)' --allow-tool='shell(npm:*)'
```

**Project names shadow plugin names.** Per the docs, if a project-level skill or agent has
the same name or ID as one in a plugin, the plugin's copy is silently ignored. A plugin can
never override what a repo defines for itself. So keep names distinct: this repo has the
project skill `board-tests` and the plugin skill `build-test`.

## The dev loop: `--plugin-dir`

While you are writing a plugin, do not install it. Mount it:

```bash
copilot --plugin-dir ./plugins/2048-dev
```

Per the docs the directory is mounted read-only for that session, nothing is installed, and
your edits take effect on `/restart` or in a new session. To check the mount without spending
a model call (tested):

```
$ copilot --plugin-dir ./plugins/2048-dev plugin list
...
External Plugins (via --plugin-dir):
  • 2048-dev (v1.0.0)
```

`COPILOT_PLUGIN_DIR_ONLY=true` turns off automatic plugin discovery, so only the mounted
plugins are loaded. `evals/plugin-ab.sh` uses it to compare runs with and without the plugin.

## Manual marketplace commands

For using this marketplace from **another** repo, or for any marketplace that no settings
file registers for you (syntax from `copilot plugin --help`; not run here, because they
change your user profile):

```bash
copilot plugin marketplace add klesajos/qti-copilot    # owner/repo, a git URL, or a local path
copilot plugin marketplace browse qti-copilot          # what it offers
copilot plugin install 2048-dev@qti-copilot
copilot plugin list
copilot plugin update 2048-dev@qti-copilot
copilot plugin uninstall 2048-dev@qti-copilot
copilot plugin marketplace remove qti-copilot
```

Inside a session, `/plugin` opens the same management. For a private marketplace repo you
need read access to it; per the docs, organisation membership alone does not grant that.

**Install by `name@marketplace` only.** `copilot plugin install --help` on 1.0.114 lists
`plugin@marketplace`, `owner/repo`, `owner/repo:path` and a git URL as sources, and no local
path. Per an open issue, the direct forms already print a deprecation warning:

```
⚠️ Warning: Direct plugin installs (repos, URLs, local paths) are deprecated. Only plugin@marketplace installs will be supported in a future release.
```

For local work use `--plugin-dir`. For sharing use a marketplace.

## Personal opt-out

To switch a repo-enabled plugin off for yourself, create
`.github/copilot/settings.local.json` (per the docs; this repo's `.gitignore` already
excludes the file):

```json
{
  "enabledPlugins": {
    "2048-dev@qti-copilot": false
  }
}
```

`copilot plugin disable` is not the tool for this: per the docs it is rejected for a plugin
whose state the repository's settings decide.

## Validate before you commit

There is **no `copilot plugin validate`**. `copilot plugin --help` lists install, uninstall,
update, list, enable, disable and marketplace. Do what GitHub's starter template does and
check the manifest against the published schema:

```bash
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

Run in this repo it prints `plugins/2048-dev/plugin.json valid`. That proves the manifest is
well-formed, not that the components load. For that, ask a session what it loaded (one model
call; tested):

```bash
copilot -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
  | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | {commandName, source}'
```

Expected: `{"commandName":"2048-dev:build-test","source":"plugin"}`. In an interactive
session, `/env` lists the loaded plugins, skills and agents.

## What else the committed settings affect

**Cloud agent runs.** Per the docs, the Copilot cloud agent also reads `enabledPlugins` and
`extraKnownMarketplaces` from `.github/copilot/settings.json`, and there is no local
override there. What you commit in this file also applies when a task for this repo runs in
the cloud, for example after `/delegate`.

**Controls an administrator may have set.** Managed settings always beat repository defaults
(per the docs; none of this was tested here):

| Managed setting | Effect on this example |
|-----------------|------------------------|
| `strictKnownMarketplaces` | Allow-list of marketplace sources. A marketplace that is not on it cannot be used; expect that to include an in-repo one |
| `enabledPlugins` | `true` forces a plugin on, `false` blocks it. The repo cannot enable a blocked plugin |
| `strictPluginOnlyCustomization` | Blocks *standalone* repo and user skills, agents, hooks and MCP servers. Only plugin-delivered ones still load |
| MCP allow-list | MCP servers shipped inside a plugin must pass it too (Example 4) |

Organisation owners and team maintainers can also set plugins as team defaults; per the
GitHub changelog the CLI shows them as "Team plugin assignments" in `/plugin list`. If the
plugin loads on a private machine but not on a 2N one, ask the administrator before you
debug the files.

## Sharing a tool with colleagues

A plugin is how you ship a self-made tool to other people, which is what the 2N guilds are
for. The usual path:

1. A skill, agent or hook starts in one repo's `.github/` and proves useful.
2. Move it into `plugins/<name>/` with a `plugin.json`. Give it a version.
3. List it in a marketplace repo that your colleagues can read.
4. Colleagues run `copilot plugin marketplace add <owner>/<repo>` once and install what they
   want, or a project enables it for the whole team with the two settings keys from Layer 4.
5. Raise `version` when you change it. Colleagues pick the change up with
   `copilot plugin update <name>@<marketplace>`.

The docs ask plugin authors to add evaluations for the behaviour a plugin is meant to
provide; [guide 09](09-validate-eval.md) shows how.

## Build your own plugin, step by step

1. **Create the skeleton:**
   ```bash
   mkdir -p plugins/my-plugin/skills/hello
   ```
2. **Write `plugins/my-plugin/plugin.json`.** Copy the Layer 2 file, keep `$schema` exactly
   as it is, change `name` and `description`.
3. **Add a skill** in `plugins/my-plugin/skills/hello/SKILL.md` with `name`, `description`
   and a body. An agent would go in `plugins/my-plugin/com.github.copilot/agents/`.
4. **Try it mounted:** `copilot --plugin-dir ./plugins/my-plugin`, then `/my-plugin:hello`
   (the naming tested for `2048-dev`).
5. **Validate** the manifest with the `ajv` command above.
6. **List it** in `marketplace.json`: a new entry in `plugins` with `name` and
   `"source": "./plugins/my-plugin"`.
7. **Enable it for everyone:** add `"my-plugin@qti-copilot": true` to `enabledPlugins` in
   `.github/copilot/settings.json`.
8. **Start a new session,** check it with `/env`, and commit.

## Plugin vs standalone skill or hook: which to choose?

| | Standalone in `.github/` | Plugin |
|---|--------------------------|--------|
| Scope | One repo | Any repo that enables or installs it |
| Setup | None | Manifest, marketplace entry, settings |
| Versioned | With the repo | Own `version` |
| On a name clash | Wins | Silently ignored |
| Under `strictPluginOnlyCustomization` | Blocked | Still loads |

Start standalone. Move to a plugin when a second repo or a second team wants the same thing.

## Try the demo

1. Start `scripts/copilot-ws.sh` in the repo root and trust the folder. The launcher
   pre-approves `./gradlew`, `npm test` and `npm run`. Approve anything else it asks for.
2. Run `/2048-dev:build-test`. Copilot should build, run the three test suites and report
   counts, and fix nothing, because the skill file says so.
3. In a second terminal run `copilot plugin list`. `2048-dev` is **not** there. That is
   expected; see Troubleshooting.
4. Run the tracer agent from Example 5:
   ```bash
   copilot --agent 2048-dev:game-explorer -p "Trace how a keypress becomes a board move" --trust-folder
   ```
5. Optional: create the opt-out file from "Personal opt-out", start a new session, and check
   that `/2048-dev:build-test` is gone. Delete the file afterwards.

## Optional parameters

Per the docs:

| Where | Field | What it does |
|-------|-------|--------------|
| `plugin.json` | `homepage`, `repository`, `license`, `keywords` | Metadata |
| `marketplace.json` | `metadata.pluginRoot` | Part of the optional `metadata` object, next to `description` and `version` |
| `marketplace.json` plugin entry | `category`, `tags`, `author`, `homepage`, `license` | Listing metadata |
| `marketplace.json` plugin entry | `source` as an object with `ref`, `sha` | Pin a remote plugin to a branch, tag or full commit SHA |

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** | ✅ | Repo settings plus folder trust. Tested on 1.0.114 |
| **IntelliJ plugin** | ⚠️ | The JetBrains plugin has **its own plugin store**; a CLI install does not appear there. Plugins and marketplaces are managed in the IDE's Customizations panel. Whether it reads the plugin keys in `.github/copilot/settings.json` or loads `com.github.copilot/` components is not documented. Not tested here; see [guide 12](12-intellij.md) |
| **Copilot cloud agent** | ✅ | Reads `enabledPlugins` and `extraKnownMarketplaces` from the committed settings (per the docs; not tested) |

## Troubleshooting

- **`copilot plugin list` does not show `2048-dev`** → expected. Tested: outside a session
  the command lists user-installed and built-in plugins only, not plugins a repository
  enables. `copilot plugin marketplace browse qti-copilot` answers `Marketplace
  "qti-copilot" not found` for the same reason. Check inside a session with `/env`, or with
  the `jq` command from the validation section.
- **`/2048-dev:build-test` is unknown** → the folder is not trusted, a
  `settings.local.json` sets the plugin to `false`, `COPILOT_PLUGIN_DIR_ONLY` is set in your
  shell, or a managed policy blocks the marketplace.
- **The skill loads but the agent is missing** → check `$schema` in `plugin.json`. Per the
  docs, without the exact value the plugin is treated as legacy, and legacy plugins keep
  agents in `agents/`, not in `com.github.copilot/agents/`.
- **You edited the skill and nothing changed** → `/restart` or a new session.
- **A plugin skill never runs although the plugin is loaded** → a project skill with the
  same name shadows it. Rename one of them.
- **`copilot plugin disable` is rejected** → the repo's settings control the plugin. Use
  `settings.local.json`.
- **A deprecation warning on install** → you installed from a repo, URL or path. Add the
  marketplace and install `name@marketplace`.
- **Enabled from a remote marketplace, installed, but never active** → an open issue
  describes plugins that `enabledPlugins` installs but records as disabled. All reports use
  a remote `github` source. The directory source in this repo worked in our tests.

---

Next: one agent, one task at a time is the simple case. Plans, autopilot and parallel
subagents → [guide 07: Orchestration](07-orchestration.md).

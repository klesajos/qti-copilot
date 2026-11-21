> 🌍 Read this in: **English** | [Česky](04-mcp.cs.md)

# Example 4: MCP connections

## What is MCP?

**MCP (Model Context Protocol)** is how Copilot CLI gets tools it does not ship with. An
**MCP server** is either a local process the CLI starts (`stdio`) or a remote endpoint it
calls (`http`, `sse`). Each server adds tool definitions to the model's context, and every
call to one of those tools goes through the same permission system as a shell command.

At 2N, MCP is limited to a short approved list. That shapes this whole example:

- This repo **ships no third-party MCP server**. A committed `.mcp.json` pointing at some
  public server would be blocked by the allow-list on your machine, and you would spend the
  exercise debugging a policy.
- The primary example is the **built-in GitHub MCP server**, which every signed-in CLI has.
- The approved 2N Jira MCP is shown as a **pattern** in `.mcp.json.example`. You get the real
  URL from 2N.

## What this example does

| Piece | Where | What you learn |
|-------|-------|----------------|
| Built-in GitHub MCP server | inside the CLI, nothing to configure | What it exposes by default, how to list and widen its tools |
| `.mcp.json.example` | repo root | The workspace file format, using the approved Jira MCP as the pattern |
| Policy messages | this guide | How to tell a policy block from a config error |

## The built-in GitHub MCP server

When you are signed in, the CLI starts a server named `github-mcp-server` on its own. Check
from a shell (output from CLI 1.0.114):

```
$ copilot mcp list
Builtin servers:
  computer-use (local)
  github-mcp-server (http)
```

**What it can do by default.** It is read-only and exposes a subset of the full GitHub MCP
server. The subset depends on whether `gh` is on your `PATH`: tools that `gh` can replace are
left out to save context. Tested on 1.0.114:

| Your machine | Tools exposed |
|--------------|---------------|
| `gh` on `PATH` | 6: `get_file_contents`, `search_code`, `search_users`, `get_copilot_space`, `list_copilot_spaces`, `web_search` |
| no `gh` | 24: the six above plus `search_repositories`, `list_branches`, `list_commits`, `get_commit`, `issue_read`, `list_issues`, `search_issues`, `pull_request_read`, `list_pull_requests`, `search_pull_requests`, `actions_list`, `actions_get`, `get_job_logs`, `list_workflow_runs`, `get_workflow_run`, `list_workflows`, `get_workflow_run_logs`, `get_workflow` |

So with `gh` installed the agent has **no MCP tool for issues or pull requests** and is
expected to use `gh` in the shell instead. Neither set contains a write tool. The model sees
each tool with the server name as prefix, for example `github-mcp-server-search_code`.

**List its tools.** In a session:

```
/mcp list                       ← every server with its live status
/mcp get github-mcp-server      ← details and the tools it provides
```

(`copilot help mcp` on 1.0.114 names the verb `get`; the online docs still call it `/mcp show`.)
From a shell, `copilot mcp list` and `copilot mcp get github-mcp-server` show the
configuration, not the live status.

**Widen the toolset.** Three launch flags. The first two were tested on 1.0.114; the third
is described from `copilot --help`:

| Flag | Effect |
|------|--------|
| `--add-github-mcp-toolset <toolset>` | Adds a whole toolset **on top of** the default subset (repeatable). `all` enables every toolset. Tested with `issues`. |
| `--add-github-mcp-tool <tool>` | **Replaces** the default subset with exactly the tools you name (repeatable). `*` means all tools. |
| `--enable-all-github-mcp-tools` | Everything. Overrides the two flags above. |

To make a choice permanent, set `githubMcpToolsets`, `githubMcpTools` or
`enableAllGithubMcpTools` in `~/.copilot/settings.json` (per `copilot help mcp`; not tested in
this repo). Any of these takes the server off its read-only endpoint: `copilot mcp get
github-mcp-server` shows a URL ending in `/mcp/readonly` by default and `/mcp` once widened.
A whole toolset can bring write tools with it. Naming single read tools does not.

**Policy.** Per the docs, the built-in server is exempt from MCP allow-lists and deny-lists.
It is not exempt from the master switch: since CLI 1.0.112, when the organisation's "MCP
servers in Copilot" policy disables MCP, the built-in GitHub server does not start. If
`github-mcp-server` is missing for everybody, that is the cause. Nothing on your machine fixes it.

## The file, line by line

Workspace servers live in **`.mcp.json` in the repo root**. This repo ships only the pattern,
`.mcp.json.example`:

```json
{
  "mcpServers": {
    "jira": {
      "type": "http",
      "url": "https://REPLACE-WITH-THE-APPROVED-JIRA-MCP-URL/mcp",
      "tools": ["*"]
    }
  }
}
```

- `"mcpServers"` — the top-level key. VS Code's `servers` key does not work here: with
  `servers` the CLI loads none of the entries. The file must be strict JSON, with no comments
  and no trailing commas.
- `"jira"` — the server name. It shows up in `/mcp`, as the prefix of the tool names, and in
  permission rules (`jira(tool_name)`). Name-based allow-lists match on it, so use the exact
  name 2N gives you and do not rename it.
- `"type": "http"` — a remote server. Nothing runs on your machine. `sse` is the other remote
  type. A local server uses `"type": "local"` (or `"stdio"`) with `command` and `args`.
- `"url"` — a placeholder. The real address comes from 2N. Write it literally (see the
  secrets section).
- `"tools": ["*"]` — expose every tool the server offers. List tool names instead to keep
  unused definitions out of the context. The docs reference marks `tools` as required;
  `copilot help mcp` on 1.0.114 says it defaults to `["*"]`. Writing it out satisfies both.

There is no `headers` entry, so the file holds no secret. If the server uses OAuth, the CLI
opens a browser or tells you to run `/mcp auth jira`, and keeps the tokens in the OS keychain
(per `copilot help mcp`). How the 2N Jira MCP authenticates is a question for 2N.

## Why root `.mcp.json` and not `.github/mcp.json`

The CLI reads both. The JetBrains plugin reads both too, but not in the same way:

| File | Copilot CLI | IntelliJ plugin (Copilot agent, 1.19.0+) |
|------|-------------|------------------------------------------|
| `.mcp.json` (repo root) | `mcpServers`, or a bare map of server names | `mcpServers`, or a bare map of server names |
| `.github/mcp.json` | `mcpServers` or a bare map; **ignored** when the same directory has a `.mcp.json` | definitions go under `servers` |
| `.vscode/mcp.json` | not read | — |

Root `.mcp.json` with `mcpServers` is the one location both clients read the same way (the
JetBrains column comes from a maintainer reply, not from the docs; not tested here). The
GitHub docs suggest `.github/mcp.json` for committed configuration; we deviate from that for
this reason only. When the
same server name is defined in several places, the later source wins: user config
(`~/.copilot/mcp-config.json`), workspace files, plugins, then `--additional-mcp-config`.

## Secrets, and why to avoid `${VAR}` in `url` and `command`

Never write a token into a file that can be committed. The usual answer, a `${VAR}`
reference, has two problems in this environment:

- **Allow-lists.** Per the docs, a managed allow-list blocks any server whose URL or command
  contains an unresolved variable, "because the client cannot verify the server". A
  `${JIRA_HOST}` in `url` that is unset on one machine turns into a policy block there.
- **IntelliJ.** An open bug (user-reported on plugin 1.19.2 and 1.20.0) sends `${VAR}`
  references in `headers` and `env` literally instead of resolving them.

So keep `url`, `command` and `args` literal, and handle secrets like this:

1. **OAuth** if the server supports it. Nothing secret is in the file at all.
2. **A static token outside the repo.** Add the server to your user config instead:
   ```bash
   copilot mcp add --transport http --header "Authorization: Bearer <token>" jira <url>
   ```
   This writes to `~/.copilot/mcp-config.json`. Do not also define `jira` in `.mcp.json`:
   the workspace entry would win.
3. **`${NAME}` in `headers`** works in the CLI (per the docs) but is the case the IntelliJ
   bug breaks.

`copilot mcp get <name>` masks header and env values unless you pass `--show-secrets`.

## The trust prompt

Workspace MCP servers load only after you trust the folder. On first start in a folder the
CLI asks:

```
Yes                                                  Trust it for this session.
Yes, and remember this folder for future sessions    Add it to `trustedFolders` in config.json.
No                                                   Exit.
```

The same answer also covers the repo's hooks and plugin settings. A `stdio` entry is a
process that a file from the repo starts on your machine, so read `.mcp.json` before you
answer. A `copilot -p` run in an untrusted folder skips workspace servers; `--trust-folder`
trusts the folder for that one run.

Trust is not permission. Each MCP tool call still goes through the permission rules, where a
server is addressed as `jira` (all its tools) or `jira(tool_name)` (one tool), for example
`--deny-tool='jira(tool_name)'`.

## What a policy block looks like

Learn these messages. When you see one, stop editing JSON: the config is fine and only an
administrator can change the outcome.

Enterprise allow-list (documented wording):

```
MCP server "SERVER-NAME" was blocked by your enterprise "ENTERPRISE-NAME".
Contact your enterprise administrator to add this server to the allowlist.
```

Registry or organisation policy (wording from `copilot help mcp` on 1.0.114):

```
N MCP servers were blocked by policy: 'name' (reason)
```

with a reason such as `Not found in registry <url>`. Third-party MCP switched off for the
organisation (wording from a user report on CLI 1.0.101; it may differ on your version):

```
Third-party MCP servers are disabled by your organization's Copilot policy. Only built-in servers are available.
```

Two more facts from the same help text: if the policy cannot be fetched, every server except
the built-in ones is blocked, so a network or proxy problem can look like a policy block. And
`copilot mcp list` shows configuration only. Live status (`connected`, `failed: <reason>`,
`disabled`) is in `/mcp list` inside a session.

## Add an approved server, step by step

1. **Get three things from 2N:** the server name, the URL, and how it authenticates.
2. **Create the file:** `cp .mcp.json.example .mcp.json`, then replace the URL (and the name,
   if 2N uses a different one).
3. **Check the JSON:** `jq . .mcp.json`.
4. **Load it.** Start `copilot` and trust the folder, or run `/mcp reload` in a session that
   is already open.
5. **Verify:** `/mcp list` shows `jira` as connected and `/mcp get jira` lists its tools. Run
   `/mcp auth jira` if the CLI asks you to sign in.
6. **Use it** (not tested in this repo; there is no Jira server to test against):
   > *"List my open Jira issues."*
7. **Do not commit `.mcp.json` in this workshop repo.** The URL belongs to 2N. In a real 2N
   project, committing it is what gives every teammate the server after one trust prompt.

**Frontend developers:** if 2N has approved a Figma MCP, it is added the same way. Image
input is disabled, so work from text specs.

## Try the demo

The demo uses only the built-in server and this repo's own GitHub issues. No write tool is
needed. Your clone needs its GitHub remote. If the repo has no issues yet, open one in the
web UI first.

1. Start `copilot` in the repo root and run `/mcp list`. `github-mcp-server` is connected.
2. Run `/mcp get github-mcp-server` and count the tools. With `gh` installed there are six
   and none of them reads issues.
3. Exit and start again with two read tools:
   ```bash
   copilot --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
   ```
   `/mcp get github-mcp-server` now shows exactly these two.
4. Ask:
   > *"List the open issues in this repository with the list_issues tool. For each one, name the file and function in this codebase it most likely concerns."*

   The timeline shows a call to `github-mcp-server-list_issues`, followed by local file reads.
5. **Create a pull request with `/pr create`, not with an MCP write tool.** Put a change on a
   branch (the demo in [Example 5](05-agents.md) gives you one), then run `/pr create`. Per
   the docs, Copilot opens the pull request on your behalf with you as author, and `/pr`
   needs a repository hosted on GitHub. Per the changelog, plan mode blocks pull request
   creation. Not tested in this repo.

What was tested: the tool counts, both flags, and a `list_issues` call in `-p` mode against a
public repository, which ran without any allow rule. This repo's own issues were not tested,
because it had no GitHub remote when this guide was written.

## Optional parameters

Fields per server entry (per the docs):

| Field | Applies to | What it does |
|-------|-----------|--------------|
| `type` | both | `local` or `stdio` for a process; `http` or `sse` for a remote server |
| `command`, `args` | local | Program and arguments to start |
| `env` | local | Environment for the process. Supports `$VAR`, `${VAR}`, `${VAR:-default}`. Only `PATH` and a few platform variables are inherited automatically |
| `cwd` | local | Working directory of the process |
| `url` | remote | Server address |
| `headers` | remote | HTTP headers, typically `Authorization` |
| `tools` | both | `["*"]` or a list of tool names to expose |
| `timeout` | both | Per-server timeout in milliseconds |

Launch flags (from `copilot --help`):

| Flag | What it does |
|------|--------------|
| `--disable-mcp-server <name>` | Turn one server off for this run |
| `--disable-builtin-mcps` | Turn the built-in servers off for this run |
| `--additional-mcp-config <json>` | Add servers for one session: a JSON string, or `@file` |

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** | ✅ | Root `.mcp.json` after folder trust. `-p` runs need a trusted folder or `--trust-folder` |
| **IntelliJ plugin** | ⚠️ | Per a maintainer reply, the Copilot agent reads root `.mcp.json` with `mcpServers` since plugin 1.19.0. Known open bugs: `${VAR}` in `headers` and `env` is sent literally, and `stdio` servers start in the IDE's working directory, not the project root. The plugin bundles an older CLI runtime, so do not assume identical behaviour. Organisation MCP policies apply there too. Not tested here; see [guide 12](12-intellij.md) |
| **Copilot cloud agent** | ⚠️ | Not verified. We found no documentation that the cloud agent reads a workspace `.mcp.json`; do not rely on it |

## Troubleshooting

- **Server missing from `/mcp list`** → the folder is not trusted, the JSON is invalid
  (`jq . .mcp.json`), or the top-level key is `servers` instead of `mcpServers`.
- **"blocked by policy" or "blocked by your enterprise"** → not a config error. Send the
  server name and URL to the 2N administrator.
- **Every server blocked at once, including ones that worked yesterday** → the policy
  probably could not be fetched. Check VPN and proxy, then restart the CLI.
- **`github-mcp-server` is gone** → the organisation disabled the MCP policy (CLI 1.0.112+),
  or you started with `--disable-builtin-mcps`, or ran `/mcp disable github-mcp-server`.
- **The agent uses `gh issue list` instead of an MCP tool** → expected when `gh` is on
  `PATH`. Add the tool with `--add-github-mcp-tool`.
- **Edited `.mcp.json`, nothing changed** → `/mcp reload`.
- **Server works in the terminal but not in IntelliJ** → look for `${VAR}` in `headers` or
  `env`, or a relative path in `command`.
- **`/pr create` refuses** → you are in plan mode, or the repo has no GitHub remote.
- **Only web search is offered by the built-in server** → per `copilot help mcp`, that is the
  behaviour in a repository whose only remote is Azure DevOps.

---

Next: MCP gives the agent more tools. Custom agents decide who gets which tools →
[Example 5: Custom agents and delegation](05-agents.md).

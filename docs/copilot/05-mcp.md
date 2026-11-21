> 🌍 Read this in: **English** | [Česky](05-mcp.cs.md)

# 05 · MCP under an allow-list

> ⏱ 10 min (5 talk + 5 facilitator demo: exercise 4, steps 1 to 3) · Docs: [Adding MCP servers for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers) · [Built-in MCP servers](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-mcp-servers) · [MCP server usage in your company](https://docs.github.com/en/copilot/concepts/enterprise/mcp-management) · Verified on Copilot CLI 1.0.114

## In short

**You need:** The CLI, logged in: the GitHub server is built in. `gh` is optional. For any other server: a place on 2N's approved list, such as the Jira MCP and its URL.

**What it is for:** MCP plugs outside systems into the agent as tools: GitHub, Jira, a database. Copilot then reads the issue or ticket itself instead of you pasting it in.

**Three uses that pay off most:**

1. Implement a feature straight from a GitHub issue or a Jira ticket.
2. Search code across the organisation's repositories without leaving the session.
3. Bring in facts the model cannot know: a ticket's acceptance criteria, a shared Copilot Space.

## What is MCP?

MCP (Model Context Protocol) gives the agent tools the CLI does not ship with. A server is a
local process (`local`) or a remote endpoint (`http`, `sse`). At session start it adds its tool
definitions to the model's context. In permission rules it is `name` or `name(tool)`.

## What this example does

```
(inside the CLI)      ← github-mcp-server: built in, starts at sign-in, nothing to configure
.mcp.json.example     ← the file format, with the approved 2N Jira MCP as the pattern
.mcp.json             ← your copy with the real URL; gitignored
```

2N allows MCP servers from an approved list only and runs its own Jira MCP. The repo therefore
ships no live third-party server, on purpose: it would be blocked on your machine.

## The built-in GitHub MCP server

`copilot mcp list` prints `github-mcp-server (http)` under `Builtin servers:`. It is read-only by
default, and its tool subset depends on whether `gh` is on your `PATH`:

- **With `gh`:** 6 tools: `get_file_contents`, `search_code`, `search_users`, `get_copilot_space`,
  `list_copilot_spaces`, `web_search`. Nothing for issues or pull requests; the agent runs `gh`.
- **Without `gh`:** 24 tools: the six plus read tools for commits, issues, pull requests, Actions.

The model sees each tool as `github-mcp-server-<tool>`. Two flags widen the subset for one run:

- `--add-github-mcp-tool <tool>`: replaces the subset with exactly the tools you name.
- `--add-github-mcp-toolset <toolset>`: adds a toolset on top. A toolset can bring write tools.

The server is exempt from MCP allow-lists and deny-lists. It is off when the organisation
disables the "MCP servers in Copilot" policy (since CLI 1.0.112).

> 🔷 **Copilot only:** the GitHub MCP server is built in and starts when you sign in. Claude Code
> has no built-in GitHub server: you add one with `claude mcp add` and a PAT, or enable a plugin.

> 🔷 **Copilot only:** `list_copilot_spaces` and `get_copilot_space` read [Copilot Spaces](https://docs.github.com/en/copilot/concepts/prompting-and-context/spaces),
> shared curated context. Claude Code has connectors but no shared context store of this kind.

## The file, line by line

The CLI reads `.mcp.json` from the repo root once the folder is trusted. `.mcp.json.example`:

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

- `mcpServers`: the top-level key. With VS Code's `servers` key the CLI loads nothing.
- `jira`: the server name. It prefixes the tool names, appears in permission rules
  (`jira(tool)`), and a name-based allow-list matches on it. Use the exact name 2N gives you.
- `type`, `url`: `http` is a remote server; a local one uses `"type": "local"` with `command` and
  `args`. Write the URL literally: an allow-list blocks a server with an unresolved `${VAR}`.
- `"tools": ["*"]`: expose every tool; list names to keep unused definitions out of the context.
  No `headers` entry, so the file holds no secret; a static token goes in your user config (below).

## Create your own, step by step

1. `cp .mcp.json.example .mcp.json`, put in the name and URL from 2N, run `jq . .mcp.json`.
2. Start `copilot` and trust the folder, or run `/mcp reload` in an open session. `/mcp list`
   shows `jira` as `connected`; `/mcp auth jira` signs in. ⚠️ not run in this repo

## Try the demo

1. Start `copilot --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read`.
   `/mcp get github-mcp-server` opens its details: `tools` lists exactly these two; `q` closes.
2. Prompt:
   > *"List the three most recently updated open issues of the public repository github/copilot-cli with the list_issues tool. Reply with number and title only. Do not use the shell."*
3. The timeline shows one call to `github-mcp-server-list_issues`, with no approval prompt, then
   three lines of number and title. Self-study demo: the workshop shows [exercise 4](exercises.md).

## What a policy block looks like

- `N MCP servers were blocked by policy: 'name' (reason)`, e.g. `Not found in registry <url>`.
- `MCP server "SERVER-NAME" was blocked by your enterprise "ENTERPRISE-NAME".`

The config is fine: send the server name and URL to the 2N administrator. If the policy cannot
be fetched, every server except the built-in ones is blocked, so check VPN and proxy first.

## Optional parameters

| Field / flag / command | What it does |
|---|---|
| `command`, `args`, `env`, `cwd`; `headers` | Local server: program, arguments, environment, working directory. Remote server: HTTP headers |
| `copilot mcp add --transport http --header "Authorization: Bearer <token>" <name> <url>` | Adds a server to your user config `~/.copilot/mcp-config.json`, outside the repo. The place for a static token: never write one into a `.mcp.json` that can be committed |
| `--additional-mcp-config <json or @file>` | Servers for one session |

Full reference: [MCP server configuration](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#mcp-server-configuration) · `copilot help mcp`

## Where it works

| CLI | IntelliJ plugin | Cloud agent |
|---|---|---|
| ✅ Root `.mcp.json` after folder trust. A `-p` run needs `--trust-folder` | ⚠️ Reads root `.mcp.json` with `mcpServers` since plugin 1.19.0. `${VAR}` in `headers` and `env` is sent literally ([open bug](https://github.com/microsoft/copilot-intellij-feedback/issues/2125)) | ⚠️ Servers are configured per repository on GitHub.com; the GitHub and Playwright servers are on by default |

## Copilot vs Claude Code

Same mechanism and file: Claude Code also reads a committed root `.mcp.json` with `mcpServers`
and adds user servers with `claude mcp add`. The differences are the two callouts above.

## Troubleshooting

- **Server missing from `/mcp list`** → invalid JSON (`jq . .mcp.json`), `servers` instead of `mcpServers`, or in a `-p` run no `--trust-folder`.
- **`github-mcp-server` is gone** → the organisation disabled MCP, or you ran `/mcp disable github-mcp-server`.

Next: [06 · Custom agents](06-agents.md)

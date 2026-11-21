> 🌍 Read this in: **English** | [Česky](preflight.cs.md)

# Preflight checklist for the facilitator

> ⏱ 1 hour, before the day · Docs: [Enterprise managed settings](https://docs.github.com/en/copilot/reference/enterprise-administrators/enterprise-managed-settings) · [Administering Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise) · [Policies per surface](https://docs.github.com/en/copilot/reference/supported-surfaces-for-policies) · Part B verified on Copilot CLI 1.0.114, on an account no organisation manages

Run part A with your Copilot admin and part B on one participant machine, on the company network,
with a participant's account. A blocked customization gives no error: it does not load. The
guides do not explain these cases; this page does. Each item names the setting, what it breaks
and how to check. ⚠️ marks a check that was not run in this repo.

## A. With your Copilot admin

### Access

- [ ] **Copilot CLI policy** on for every participant. **Breaks:** everything. **Check:** part B prints a `cli` line.
- [ ] **Access to the private repo `klesajos/qti-copilot`.** Enterprise Managed Users generally cannot be collaborators outside their enterprise. **Breaks:** cloning; exercise 4. **Check:** `git ls-remote https://github.com/klesajos/qti-copilot` with a participant's account ⚠️. **If blocked:** mirror the repo into your organisation.
- [ ] **An issue for exercise 4** in the repo (or the mirror) that participants can read. **Breaks:** the MCP demo. **Check:** open the issue list in the browser as a participant. Text: [solutions/ex4-issue.md](solutions/ex4-issue.md).
- [ ] **[Model list](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-default-models).** Which models are enabled, and is `auto` available? The Claude Fable family is off by default. **Breaks:** a model that is not allowed is an error; built-in agents (`explore`, the `code-review` agent behind `/review`) use their own default model; `explore` failed with `400 The requested model is not supported` when its model was not enabled. **Check:** `/model` in a session (a model you cannot use is still listed and says why when highlighted); the `model` line in part B. **If restricted:** review with the `kotlin-reviewer` agent; add "Use general-purpose subagents" to `/fleet` prompts.
- [ ] **[Budget](https://docs.github.com/en/copilot/concepts/billing-and-usage/organizations-and-enterprises/billing).** How many AI credits does a participant have left, and is additional paid usage enabled? **Breaks:** at 100 % every model call fails until the reset; evals and `/fleet` spend fastest. **Check:** `/usage`, row Plan.
- [ ] **Image input** may be disabled. **Breaks:** nothing: no guide or exercise uses an image. **Check:** confirm it, and tell participants not to paste screenshots.
- [ ] **Windows machines.** The hooks are bash scripts (the `bash` key in `.github/hooks/hooks.json`) and need `jq`. **Breaks:** guide 04, exercise 3, the `.env` guard. **Check:** run part B inside WSL 2; native Windows ⚠️.
- [ ] **Proxy or private certificate authority.** **Breaks:** TLS errors and timeouts; under a registry policy an unreachable MCP registry blocks every MCP server except the built-in ones. **Check:** part B on the company network; `copilot help network` lists the settings.

### Organisation policies

- [ ] **["MCP servers in Copilot"](https://docs.github.com/en/copilot/concepts/enterprise/mcp-management).** Off until an admin enables it. **Breaks:** no MCP server starts, and since CLI 1.0.112 that includes the built-in GitHub server: guide 05 and exercise 4. **Check:** the `mcp` line in part B.
- [ ] **MCP [registry](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-mcp-usage/restrict-based-on-registry) or [allow-list](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-mcp-usage/configure-enterprise-allowlist)** (`allowManagedMcpServersOnly`, `allowedMcpServers`, `deniedMcpServers`). **Breaks:** any server a participant adds to `.mcp.json`. **Check:** ask for the list, and for the exact URL of the approved Jira server to put into a copy of `.mcp.json.example`.
- [ ] **Experimental mode and preview features** (`--experimental`, `/settings experimental on`). **Breaks:** dynamic workflows (`copilot workflow run`) in guide 10, the `/eval` commands of GitHub Copilot Evals in guide 09, the per-skill breakdown in `/context`. **Check:** start `copilot --experimental` and run `/experimental` ⚠️. **If blocked:** those parts are reading only.
- [ ] **Copilot cloud agent** and **[remote control](https://docs.github.com/en/copilot/concepts/agent-capabilities/agent-powered-workflows-and-operations/about-remote-control).** **Breaks:** `/delegate` and `/remote on` in guide 11. **Check:** `/remote show` ⚠️.
- [ ] **[Copilot Memory](https://docs.github.com/en/copilot/concepts/prompting-and-context/copilot-memory).** **Breaks:** nothing, but an earlier session can colour a later one, which distorts exercise 8. **Check:** `/memory` ⚠️; switch it off with `/memory off`.
- [ ] **[Content exclusion](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/content-exclusion).** **Breaks:** any exercise on a path a rule matches. **Check:** ask whether a rule matches `engine/`, `api/` or `web/`.

### Managed settings

A `managed-settings.json` comes from the enterprise's `.github-private` repository, from MDM or
as a local file. Ask for it. On a Mac, `ls "/Library/Application Support/GitHubCopilot/managed-settings.json"`
shows a local one; server-delivered settings leave no file ([locations](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference)).

- [ ] **`strictPluginOnlyCustomization`** (`true`, or a list of `skills`, `agents`, `hooks`, `mcp`). **Breaks:** `.github/skills/`, `.github/agents/`, `.github/hooks/` and `.mcp.json` do not load: guides 03 to 06. **Check:** the `skill project` and `agent project` lines in part B. **If set:** move the skill and the agents into the `2048-dev` plugin, or demo on your own machine.
- [ ] **`allowManagedHooksOnly`.** **Breaks:** repository hooks do not run: guide 04, exercise 3, the `.env` guard. **Check:** the `denied` line in part B. **If set:** rely on `--deny-tool` rules and say that `cat .env` is then not blocked.
- [ ] **`strictKnownMarketplaces`**, managed **`enabledPlugins`.** **Breaks:** the in-repo marketplace `qti-copilot` is not on the list, so `2048-dev` does not load: guide 07, exercise 6. **Check:** the two `plugin` lines in part B. **If set:** ask the admin to add the marketplace.
- [ ] **`permissions.deny`, `.ask`, `.allow`**, **`permissions.disableBypassPermissionsMode`.** **Breaks:** a managed "ask" is a deny in `-p` and autopilot runs (guides 08, 10), so `./gradlew` and `npm` must be on the managed allow list. `--allow-all` stops working; the guides use explicit rules. **Check:** read the file.
- [ ] **Managed sandbox.** **Breaks:** hooks run inside the sandbox; a hook that starts Gradle or npm may need extra paths. **Check:** `/sandbox status` shows on or off, `/sandbox policy` the effective policy; bare `/sandbox` opens the settings dialog.

### Outside Copilot

- [ ] **Vally install** (`@microsoft/vally-cli` 0.21.0 from npm, pinned in `package.json`). **Breaks:** guide 09, exercise 8. **Check:** `npm ci && npm run eval:lint` prints two `is valid` lines. **If blocked:** `evals/plugin-ab.sh` needs only `copilot` and `jq`.
- [ ] **Conductor install** (`uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"`). **Breaks:** the Conductor part of guide 10 and of exercise 7. **Check:** `conductor validate conductor/test-coverage-audit.yaml` prints `Validation Successful`.
- [ ] **[Metrics field](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics).** Which field does your organisation read as CLI usage: `totals_by_cli`, or `totals_by_client` with `copilot_cli`? Do Vally and Conductor runs (Copilot SDK) and `/delegate` jobs count? **Breaks:** what guides 01 and 11 tell participants. **Check:** ask. IntelliJ plugin 1.15.0 to 1.19.x counted some IDE sessions as CLI; 1.20.0 fixes it.

## B. On one participant machine

```bash
copilot --version; node --version; java -version; jq --version   # 1.0.114+, Node 24.15+ or 26, JDK 17-27
./gradlew build && (cd web && npm ci && npm test)                 # exit 0, "Tests  7 passed (7)"
```

One run, about 0.07 AI credits, from the repo root. It proves login, model access, folder trust,
the skill, the agents, the plugin, the hooks and the built-in MCP server.

```bash
events=$(mktemp)
copilot -p "Use the view tool to read the file .env in the repository root and print its first line. If the read is refused, quote the refusal message and stop." \
    --output-format json --trust-folder --no-ask-user > "$events"
jq -r 'if .type == "session.start" then "cli\t\(.data.copilotVersion)"
  elif .type == "session.auto_mode_resolved" then "model\t\(.data.chosenModel)"
  elif .type == "session.mcp_server_tools_loaded" then "mcp\t\(.data.serverName)\t\(.data.toolCount)"
  elif .type == "session.skills_loaded" then (.data.skills[] | select(.source == "project" or .source == "plugin") | "skill\t\(.source)\t\(.commandName)")
  elif .type == "session.custom_agents_updated" then (.data.agents[] | "agent\t\(.source)\t\(.id)")
  elif .type == "tool.execution_complete" and .data.success == false then "denied\t\(.data.error.message)"
  elif .type == "result" then "exit\t\(.exitCode)" else empty end' "$events" | sort -u
```

```
agent	plugin	2048-dev:game-explorer
agent	project	board-test-writer
agent	project	kotlin-reviewer
agent	project	workshop-tutor
cli	1.0.114
denied	Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need.
exit	0
mcp	github-mcp-server	6
model	<model-id>
skill	plugin	2048-dev:build-test
skill	project	board-tests
```

| Line missing | Likely cause |
|--------------|--------------|
| All of them | Not signed in, the CLI policy is off, or no model is available. Run it without `> "$events"` and read the error |
| `skill project`, `agent project` | `strictPluginOnlyCustomization`, or you are not in the repo root |
| Both `plugin` lines | `strictKnownMarketplaces`, a managed `enabledPlugins`, or `--trust-folder` was left out |
| `denied` | The hooks did not load: `allowManagedHooksOnly`, `strictPluginOnlyCustomization`, or `jq` is missing |
| `mcp` | The "MCP servers in Copilot" policy is off, or the network blocks it |

The `mcp` count is 6 with `gh` installed and 24 without. The 6 include no issue tools: guide 05
starts with `--add-github-mcp-tool list_issues --add-github-mcp-tool issue_read`, which replaces
the 6 with these two. The `model` line is what `auto` resolves to in your organisation: write it down. [Index](README.md).

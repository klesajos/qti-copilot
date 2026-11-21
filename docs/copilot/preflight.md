> 🌍 Read this in: **English** | [Česky](preflight.cs.md)

# Preflight checklist for the facilitator

Run this before the workshop: part A with the 2N Copilot administrator, part B on **one
participant machine, on the 2N network, with a participant's account**. Several organisation
settings disable an exercise without any error message; the customization simply does not load.
An hour here saves the session.

Where each statement comes from:

- **[T]** tested: run in this repository on Copilot CLI 1.0.114, on a personal test account
  that is **not** managed by 2N. The expected outputs in part B come from that machine.
- **[D]** per the docs; not tested. All of part A is **[D]**: no 2N policy was available to
  test against.

## Part A: questions for the administrator

Ask about organisation and enterprise **policies** and, separately, about **managed settings**:
a `managed-settings.json` delivered from the enterprise's `.github-private` repository, by MDM,
or as a local file. They are different mechanisms, and the second one is easy to forget.

### Access and accounts

| Question | If the answer is unfavourable | Affected |
|----------|-------------------------------|----------|
| Is the **Copilot CLI** policy enabled for every participant? | Nothing works | Everything |
| Are the participants' GitHub accounts **Enterprise Managed Users**? | A managed account generally cannot be made a collaborator on a repository outside its enterprise. The private `klesajos/qti-copilot` repo is then out of reach, and the workshop needs a **mirror inside the 2N organisation**. Gists are not available to managed users either | Cloning the repo; exercise 4; `/share gist` in [10](10-level-5-workflow.md) |
| Where will the **GitHub issues for exercise 4** live? | They must be in a repository every participant can read with the account the CLI is signed in to. With a mirror, create them in the mirror | Exercise 4 |
| Which **models** are on the allow-list? Is `auto` available? | A model id that is not allowed is an error since CLI 1.0.109. The repo hard-codes none, and Conductor uses `default_model: auto`. Built-in agents carry their own default models (`code-review`, `explore`, `task`, ...) | `/model` everywhere; `/review` in [10](10-level-5-workflow.md); `--judge-model` in [09](09-validate-eval.md); [14](14-conductor.md) |
| Is 2N billed in **AI credits** or still in premium requests (the CLI shows whichever the plan uses)? How much does a participant have left this month, and is additional paid usage enabled? | Evals and fleet runs burn budget fast. At 100 % model calls fail until the reset | [07](07-orchestration.md), [09](09-validate-eval.md), [14](14-conductor.md) |
| Is there a **corporate proxy or a private certificate authority**? | An open CLI issue reports the MCP registry as unreachable on macOS with a private CA, which then blocks every MCP server | [00](00-install.md), [04](04-mcp.md) |

### Organisation policies

| Policy | What breaks if it is off or restrictive | Affected |
|--------|------------------------------------------|----------|
| **MCP servers in Copilot** | Third-party MCP servers do not start. Since CLI 1.0.112 the built-in GitHub MCP server does not start either. The policy is off until an administrator enables it | [04](04-mcp.md); exercise 4, which reads issues through the built-in server |
| **Restrict MCP access to registry servers** ("Registry only") | Only servers in the registry run. Matching is by server name or ID. The check fails closed: if the registry cannot be reached, everything is blocked | [04](04-mcp.md); the `copilot-evals` MCP server of GitHub Copilot Evals in [09](09-validate-eval.md) |
| **Copilot cloud agent** | `/delegate` needs this policy **and** the CLI policy. The repository must also be available to the cloud agent | [13](13-remote-agents.md) |
| **Remote control** of CLI sessions | `/remote on` reports that an administrator has to allow it | [13](13-remote-agents.md) |
| **Copilot Memory** | User-level preferences are off until the administrator enables them; repository-level facts are on for all repositories by default. With memory on, an earlier session can colour a later one. `/memory off` for the workshop | Reproducibility of the exercises and of [09](09-validate-eval.md) |
| **Allow use of Copilot CLI billed to the organization** | `copilot` in GitHub Actions with the built-in `GITHUB_TOKEN` fails. The alternative is a personal access token | [11](11-programmatic-ci.md); `github/evals-action` in [09](09-validate-eval.md) |
| **Experimental mode and preview features** (`--experimental`, `/settings experimental on`; in the IDE the "Editor preview features" policy) | No dynamic workflows (`copilot workflow run` exits with 2), no `/eval` commands of GitHub Copilot Evals. In IntelliJ, preview features are hidden | [07](07-orchestration.md), [09](09-validate-eval.md), [12](12-intellij.md) |
| **Content exclusion** | Excluded files are not used as context. Check that no rule matches paths of this repo | Any exercise on a matching path |

### Managed settings

Ask for the file itself if one is deployed. Each of these keys switches off part of the repo.

| Key | What breaks if it is set | Affected |
|-----|--------------------------|----------|
| `strictPluginOnlyCustomization` (`true`, or an array of `skills`, `agents`, `hooks`, `mcp`, `extensions`) | Standalone repository and user customizations in those categories do not load: `.github/skills/`, `.github/agents/`, `.github/hooks/`, `.mcp.json`. Only plugin-delivered ones work. A user report shows the text `blocked by enterprise customization lockdown` | [02](02-skills.md), [03](03-hooks.md), [04](04-mcp.md), [05](05-agents.md), and everything in [10](10-level-5-workflow.md) that leans on hooks and `kotlin-reviewer` |
| `allowManagedHooksOnly` | Repository hooks do not run: no `block-destructive`, `protect-secrets`, `format`, `run-tests` | [03](03-hooks.md), [08](08-permissions-sandbox.md), [10](10-level-5-workflow.md); exercise 3 |
| `strictKnownMarketplaces` | The in-repo marketplace `qti-copilot` is not on the list, so `2048-dev` does not load. The key also disables the built-in marketplaces; `[]` is a full lockdown. `github/evals` is blocked the same way | [06](06-plugins.md), the plugin parts of [05](05-agents.md) and [09](09-validate-eval.md) |
| `enabledPlugins` (managed) | `false` for a plugin blocks it; repository defaults cannot override that | [06](06-plugins.md) |
| `allowManagedMcpServersOnly`, `allowedMcpServers`, `deniedMcpServers` | A server a participant configures is blocked. With an allow-list, a server whose URL or command contains an unresolved `${VAR}` is blocked too. Give the administrator the exact `command` and `args`, or the URL, of the approved Jira server | [04](04-mcp.md) |
| `permissions.disableBypassPermissionsMode: "disable"` | `--allow-all`, `--yolo`, `--allow-all-tools` and `/allow-all` stop working. The guides use explicit `--allow-tool` rules, so little breaks; documented examples that use `--yolo` do | [08](08-permissions-sandbox.md), [11](11-programmatic-ci.md), [13](13-remote-agents.md) |
| `permissions.deny`, `permissions.ask`, `permissions.allow` | They apply even in allow-all mode. Once any list is set, an operation that matches none defaults to "ask", and an "ask" is a **deny** in `-p` and autopilot runs. `./gradlew` and `npm` must then be on the managed allow list | [08](08-permissions-sandbox.md), [10](10-level-5-workflow.md), [11](11-programmatic-ci.md), [13](13-remote-agents.md) |
| `permissions.disableAssistedPermissionsMode` | No assisted approval mode, no `--assisted-approval` | [08](08-permissions-sandbox.md), [11](11-programmatic-ci.md) |
| Managed sandbox settings | The organisation can require sandboxing. Hooks then run inside the sandbox, and a hook that runs Gradle or npm may need extra paths | [03](03-hooks.md), [08](08-permissions-sandbox.md) |

### Tools outside Copilot

| Question | Why it matters | Affected |
|----------|----------------|----------|
| May participants install **`@microsoft/vally-cli`** (npm, pinned to 0.21.0 in `package.json`)? | It is the eval engine. The repo's npm scripts switch its telemetry off. It reuses the Copilot login and spends AI credits | [09](09-validate-eval.md) |
| May participants install **Microsoft Conductor** (`uv tool install` from the `microsoft/conductor` Git repository, v0.1.47, MIT, beta)? | It is fetched from github.com with dependencies from pypi.org. The PyPI package named `conductor-cli` is an unrelated tool; do not install that one | [14](14-conductor.md) |
| Is the plugin **GitHub Copilot Evals** acceptable (public preview, GitHub Limited Use Source License, own MCP server)? | The repo does not vendor it; the guide only describes it | [09](09-validate-eval.md) |
| Which **IntelliJ plugin version** is rolled out, and which **metrics field** does 2N read for "CLI usage"? | Plugin 1.15.0–1.19.x miscounts agent sessions, some of them as CLI. Attribution is correct from 1.20.0 | [12](12-intellij.md) |
| Is **Coder** available for a pilot, and with which template? | Nothing in the Coder section was tested | [13](13-remote-agents.md) |
| Which **Jira MCP server** is approved, and what is its exact URL or command? | The repo ships only `.mcp.json.example` with a placeholder | [04](04-mcp.md) |

## Part B: machine check

Run from the repository root. Each step lists what the test machine printed **[T]**. A
different result on the 2N machine points at the setting named in the last column.

| # | Command | Expected | If not |
|---|---------|----------|--------|
| 1 | `copilot --version` | `GitHub Copilot CLI 1.0.114.` or later | [00-install](00-install.md) |
| 2 | `node --version`; `java -version`; `jq --version`; `git --version` | Node 24.15 or later, or 26. Any JDK 17–27. `jq` and `git` present | The hooks need `jq`; without it `protect-secrets` is inactive |
| 3 | `ls -l "/Library/Application Support/GitHubCopilot/managed-settings.json"` | `No such file or directory` on an unmanaged Mac | If the file exists, read it against the managed-settings table. Windows: `%ProgramFiles%\GitHubCopilot\managed-settings.json`; Linux: `/etc/github-copilot/managed-settings.json` **[D]**. Server-delivered settings leave no file here |
| 4 | `./gradlew build` | Exit code 0 | JDK or network (Gradle downloads JDK 21 and dependencies) |
| 5 | `cd web && npm ci && npm test` | `Tests  7 passed (7)` | Node version, npm registry access |
| 6 | Instruction files (below) | Three lines | Wrong directory, or a customization lockdown |
| 7 | `copilot mcp list` | `Builtin servers:` with `github-mcp-server (http)` | A policy warning here means the MCP policy; see part A |
| 8 | The trusted `-p` run (below) | Nine lines | See the table under it |
| 9 | `npm ci && npm run eval:lint` | `✔ evals/board-tests/eval.yaml is valid` and `✔ evals/game-explorer/eval.yaml is valid` | Vally not installable |
| 10 | `conductor --version`; `conductor validate conductor/test-coverage-audit.yaml` | `Conductor v0.1.47`; a box titled `Validation Successful` | Conductor not installable |
| 11 | `conductor doctor` | The `copilot` provider row shows it as installed, with credentials found | Copilot login, or Conductor older than v0.1.47 against CLI 1.0.113 or later **[D]** |
| 12 | The GitHub MCP run (below) | Three lines | The MCP policy, or the network |

**Step 6**: which instruction files a session would load.

```bash
copilot instruction list --json | jq -r '.[] | "\(.sourcePath)\t\(.applyTo // [] | join(","))"'
```

```
.github/copilot-instructions.md
.github/instructions/api.instructions.md	api/**/*.kt
.github/instructions/engine.instructions.md	engine/**/*.kt
```

**Step 8**: one cheap run that proves login, model access, folder trust, the project skill,
both agents, the plugin and the hooks. It asks Copilot to read `.env`, which the
`protect-secrets` hook must refuse. The file does not need to exist. It cost about 0.07 AI
credits **[T]**.

```bash
events=$(mktemp)
copilot -p "Use the view tool to read the file .env in the repository root and print its first line. If the read is refused, quote the refusal message and stop." \
    --output-format json --trust-folder --no-ask-user > "$events"

jq -r 'select(.type == "session.start") | "cli\t\(.data.copilotVersion)"' "$events"
jq -r 'select(.type == "session.auto_mode_resolved") | "model\t\(.data.chosenModel)"' "$events"
jq -r 'select(.type == "session.skills_loaded") | .data.skills[]
       | select(.source == "project" or .source == "plugin") | "skill\t\(.source)\t\(.commandName)"' "$events" | sort -u
jq -r 'select(.type == "session.custom_agents_updated") | .data.agents[] | "agent\t\(.source)\t\(.id)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | "denied\t\(.data.error.message)"' "$events"
tail -n 1 "$events" | jq -r '"exit\t\(.exitCode)"'
```

```
cli	1.0.114
model	<model-id>
skill	plugin	2048-dev:build-test
skill	project	board-tests
agent	plugin	2048-dev:game-explorer
agent	project	board-test-writer
agent	project	kotlin-reviewer
denied	Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need.
exit	0
```

The `model` line shows what `auto` resolved to; write it down for 2N. Read the rest like this:

| Line missing or different | Likely cause |
|---------------------------|--------------|
| No output at all, the file is empty | Not signed in (`copilot login`), the CLI policy is off, or no model is available. Run the command again without `> "$events"` and read the error |
| `skill project board-tests` missing | `strictPluginOnlyCustomization` covers skills, or you are not in the repo root |
| `agent project ...` lines missing | The same key for agents. Look at `data.warnings` and `data.errors` of `session.custom_agents_updated` |
| The two `plugin` lines missing | `strictKnownMarketplaces` or a managed `enabledPlugins`, or `--trust-folder` was left out |
| No `denied` line, and the answer says the file does not exist | The hooks did not load: `allowManagedHooksOnly`, `strictPluginOnlyCustomization` for hooks, no `--trust-folder`, or `jq` is missing |
| `denied` with a different message | Another rule got there first. Fine, as long as `.env` stays unread |
| Personal skills in the unfiltered list | Normal. Skills from `~/.copilot/skills` and `~/.agents/skills` load too. They also leak into eval trials; see [09](09-validate-eval.md) |

`copilot plugin list --json` is **not** a substitute for this step: outside a session it shows
only user-installed and built-in plugins, not the one this repo enables **[T]**.

**Step 12**: the built-in GitHub MCP server, which the MCP demo in [04](04-mcp.md) and
exercise 4 use to read issues. Its default tool set depends on whether `gh` is installed
**[T]**: with `gh` on `PATH` it exposes 6 tools and none for issues or pull requests; without
`gh` it exposes 24, including `list_issues`, `issue_read` and `pull_request_read`. Exercise 4
therefore starts Copilot with two explicit tools, and so does this check. It reads a public
repository, needs no allow rule, and cost about 0.2 AI credits **[T]**.

```bash
events=$(mktemp)
copilot -p "Use the GitHub MCP server tool list_issues to list the 3 most recently updated open issues in the public repository github/copilot-cli. Reply with number and title only. Do not use the shell." \
    --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read \
    --output-format json --trust-folder --no-ask-user > "$events"

jq -r 'select(.type == "session.mcp_server_tools_loaded") | "mcp\t\(.data.serverName)\t\(.data.toolCount)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_start") | "tool\t\(.data.toolName)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_complete") | "success\t\(.data.success)"' "$events" | sort -u
```

```
mcp	github-mcp-server	2
tool	github-mcp-server-list_issues
success	true
```

No `mcp` line means the built-in server did not start; with CLI 1.0.112 or later that is what
a disabled "MCP servers in Copilot" policy looks like **[D]**. A `tool` line with `bash` instead
means the agent fell back to the shell.

This check proves the server and the flags, not the workshop repo. Before the MCP demo and
exercise 4 can work, **the workshop repo must exist on GitHub, each clone needs its GitHub
remote, and the repo needs at least one issue**. With a mirror in the 2N organisation, that
means the mirror.

**Optional, interactive, two minutes.** Start `scripts/copilot-ws.sh`, answer the folder trust
question with "Yes, and remember this folder", and run:

- `/env`: instructions, skills, agents, hooks and plugins that loaded.
- `/model`: the list a participant may choose from.
- `/review` on any small uncommitted change. Built-in agents use their own default models. On
  the test account a built-in `task` subagent failed once with
  `400 The requested model is not supported.` when its default model was not available (seen
  in a recorded run, not reproduced for this checklist). If `/review` fails at 2N, the model
  list is the first suspect.
- `/remote show`, if [13](13-remote-agents.md) is on the agenda.

Then run the smoke check from [Example 11](11-programmatic-ci.md) once. It should print
`PASS board-tests skill was loaded`.

## What to cut if something is blocked

| Blocked | Cut | Keep, or do instead |
|---------|-----|---------------------|
| Standalone customizations (`strictPluginOnlyCustomization`) | The hands-on parts of [02](02-skills.md), [03](03-hooks.md), [05](05-agents.md) as written | Show them as a demo on the facilitator's machine. Move the skill and the agents into the `2048-dev` plugin beforehand if marketplaces are allowed |
| Repository hooks (`allowManagedHooksOnly`) | [03](03-hooks.md) hands-on; exercise 3 | Explain the mechanism from the files. In [08](08-permissions-sandbox.md) and [10](10-level-5-workflow.md) rely on `--deny-tool` rules and say clearly that `cat .env` is then not blocked |
| The in-repo marketplace (`strictKnownMarketplaces`) | [06](06-plugins.md) hands-on; the plugin parts of [05](05-agents.md) and [09](09-validate-eval.md) | Ask the administrator to add the workshop marketplace to the list, or demo only |
| MCP | [04](04-mcp.md) hands-on; the MCP route of exercise 4 | Walk through `.mcp.json.example`. For exercise 4, read the issues with the `gh` CLI if it is installed and allowed |
| The GitHub MCP server shows no issue tools | Nothing | Expected when `gh` is on `PATH`. Start with `--add-github-mcp-tool list_issues --add-github-mcp-tool issue_read` |
| The repo is not on GitHub yet, or has no issues | The MCP demo in [04](04-mcp.md); exercise 4 | Push the repo (or the mirror) and open at least one issue before the session. Until then, demo `list_issues` against a public repository, as in step 12 |
| Allow-all | Nothing | The guides use explicit rules |
| Managed `ask` rules on shell commands | Autopilot and `-p` parts of [10](10-level-5-workflow.md), [11](11-programmatic-ci.md), [13](13-remote-agents.md) | Interactive mode, where a prompt can be answered |
| Experimental mode | Dynamic workflows in [07](07-orchestration.md); `/eval` in [09](09-validate-eval.md) | `/fleet` and custom agents; Vally through `npm run eval` |
| Vally | The eval runs in [09](09-validate-eval.md) | `evals/plugin-ab.sh`, which needs only `copilot` and `jq`; or show the recorded results |
| Conductor | [14](14-conductor.md) hands-on | Read the workflow file and show a recorded run |
| Cloud agent, remote control | `/delegate` and `/remote` in [13](13-remote-agents.md) | A local autopilot session with a credit limit |
| Copilot CLI in Actions | The Actions section of [11](11-programmatic-ci.md) stays a reading exercise | The local smoke check |
| Collaborator access (managed users) | Nothing, if the mirror exists in time | Mirror the repo into the 2N organisation and recreate the exercise 4 issues there |
| A restricted model list | Built-in `/review` if its model is missing | The `kotlin-reviewer` agent, which runs on the session's model |
| Low credit budget | `npm run eval:ab`, `/fleet`, `conductor run` for everyone | Run them once on the facilitator's machine. `vally experiment run <file> --dry-run` prints the plan and spends nothing |

---

Back to the [index](README.md). The guides start at [00-install](00-install.md).

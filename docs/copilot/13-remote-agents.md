> 🌍 Read this in: **English** | [Česky](13-remote-agents.cs.md)

# Example 13: Remote and overnight agents

> ⚠️ **Nothing in this guide was run for this repo.** Command names and their one-line
> descriptions come from the CLI's own help on 1.0.114. Everything else is **[D]**: per the
> docs of GitHub and Coder, not tested here. Treat it as a map for a pilot, not as a recipe.

## What is an unattended agent?

So far you sat in front of the session. An unattended agent works while you are in a meeting or
asleep, and you review the result afterwards. On the scale from
[Example 10](10-level-5-workflow.md) that is level 8, and it slides to level 9 the moment
nobody reviews.

Three things change when you leave:

1. **Nobody answers prompts.** A permission request that would ask is denied; a question gets
   "the user is not available". Permissions have to be decided before you go.
2. **Nobody notices a loop.** Cost and time need a hard stop.
3. **Review moves to the end**, where it is most tempting to skip.

There are three ways to do it, with very different maturity.

| Way | Where the agent runs | Prerequisites | Maturity |
|-----|----------------------|---------------|----------|
| **`/delegate`** to the Copilot cloud agent | On GitHub | Copilot CLI policy **and** Copilot cloud agent policy enabled; repository on GitHub and available to the cloud agent | A documented product feature **[D]** |
| **A local session you keep alive and steer remotely** (`/remote`, `/keep-alive`) | On your machine | Remote control allowed by the organisation; the machine stays on and online | In the CLI help; depends on an organisation setting |
| **A Coder workspace** | On 2N's infrastructure | Coder deployed, a template with Copilot CLI, GitHub authentication in the workspace | 2N is preparing it. The Copilot module is a community module. Self-assembled and untested |

## Way 1: `/delegate` to the Copilot cloud agent

`/delegate` sends the session to GitHub, where Copilot works on it and opens a pull request.
`--base` chooses the target branch.

What happens, step by step **[D]**:

1. You type `/delegate <prompt>`, or start a prompt with `&`.
2. Copilot offers to commit your unstaged changes as a checkpoint on a **new branch** that it
   creates. If you accept, they are the starting point of the job.
3. The cloud agent opens a **draft pull request**, works in the background and requests your
   review when it is done. The pull request targets your current branch unless you pass
   `--base`.
4. The CLI prints a link to the pull request and to the agent session. `/resume` can switch to
   a session by its cloud history ID.

> */delegate Fix the no-op move bug: GameService.move must not spawn a tile when board.move returns false. Write the failing test first, without relying on random tiles. Do not change engine/. Run ./gradlew :api:test and report the counts in the pull request description.*

Prerequisites **[D]**:

- Both the Copilot CLI policy and the Copilot cloud agent policy must be enabled. On Copilot
  Business the administrator controls this. Check your own state at
  `github.com/settings/copilot/features`.
- The repository must be one the cloud agent may work on. Organisation administrators manage
  that for organisation repositories, and it is not available for repositories owned by managed
  user accounts.

**This repo's committed files also apply in the cloud** **[D]**. That is easy to forget:

| File | In a cloud agent job |
|------|----------------------|
| `.github/copilot-instructions.md`, `.github/instructions/` | Read |
| `.github/skills/`, `.github/agents/` | Supported |
| `.github/hooks/hooks.json` | Loaded. Only `bash` and `command` entries are honoured, an `ask` decision becomes a deny, and an `agentStop` block counts against the job's time limit |
| `.github/copilot/settings.json` (`extraKnownMarketplaces`, `enabledPlugins`) | Read, with no local override |
| `scripts/copilot-ws.sh` | Not involved. Its allow and deny flags belong to a local launch |

Consequences for this repo: `block-destructive.sh`, `protect-secrets.sh`, `format.sh` and
`run-tests.sh` run in the job too. The first three need `jq`; `protect-secrets.sh` deliberately lets the
call through and reports that the guard is inactive when `jq` is missing. If you turn
`run-tests.sh` into a blocking gate (exercise 3) and commit it, the gate applies to cloud jobs
as well, and the time it takes counts against the job's time limit.

## Way 2: keep a local session alive and steer it

The session runs on your machine with your tools, your hooks and your launch rules. Two
commands make it survive your absence:

| Command | What it does |
|---------|--------------|
| `/remote on` | Lets you steer the session from GitHub on the web or on mobile. `/remote off` disconnects, `/remote show` reports the status |
| `/keep-alive on` | Prevents the machine from sleeping. Also `off`, `busy` (only while the agent works), or a duration such as `30m`, `2h`, `1d`. Without arguments it shows the status |
| `copilot --connect [<session-id>]` | Connects the CLI directly to a remote session, optionally by session or task ID |

If remote control is not enabled, an organisation administrator has to allow it. The machine
has to stay online **[D]**, and `/rewind` is not available for remote-backed sessions **[D]**.

A sequence for a long task:

1. Start with explicit rules, in a worktree:
   `scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)'`
2. `/new worktree`, or work on a dedicated branch.
3. `/plan <spec>`, read the plan, accept it into autopilot.
4. `/limits set max-ai-credits <n>`.
5. `/keep-alive busy`, then `/remote on`.
6. Leave. Look in from the phone if you want to.

What autopilot does while you are away, per `copilot help permissions` and `copilot help limits`:

- A tool request that would prompt is denied.
- A question to you is answered with "not available"; the agent guesses or stops with a summary.
- It pauses after 5 automatic continuations unless `--max-autopilot-continues` is higher.
- On a rate limit nothing asks, so the model only switches to Auto when the
  `continueOnAutoMode` setting is on.

The scripted variant is a `-p` run from [Example 11](11-programmatic-ci.md) in a terminal
multiplexer. The flags all exist; this combination was not tried:

```bash
scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)' \
    --autopilot --max-autopilot-continues 20 --max-ai-credits 300 \
    --trust-folder --no-ask-user --share="$HOME/overnight-session.md" \
    -p "<spec>"
```

## Way 3: Coder Workspaces

**What Coder is.** A self-hosted platform for remote development environments. An
administrator writes a template in Terraform; each developer gets a workspace built from it.
The agent then runs in a workspace in 2N's network instead of on your laptop, so it can keep
running when the laptop is closed.

**What 2N is preparing.** Coder Workspaces for remote, overnight agents. No details were
available when this guide was written. Ask before you plan around it.

**Current names.** Coder has renamed several of its AI features, and older articles use the
old names **[D]**:

| Old name | Current | What to know |
|----------|---------|--------------|
| Coder Tasks | **Coder Agents** | Tasks was deprecated in v2.34 and removed, API included. Coder Agents runs its own agent loop in the Coder control plane |
| AI Bridge | **AI Gateway** (and AI Gateway Proxy) | Part of AI Governance; needs a Premium licence |
| Agent Boundaries | **Agent Firewall** | Premium; being phased out in favour of sandboxed workspace templates |
| — | **Agent Relay** | Beta, Premium. Documented clients are Claude Code and Cursor, not Copilot |

Two different things hide behind "an agent in Coder":

- **Coder Agents** is Coder's own agent. Its documented model providers do not include GitHub
  Copilot, so it would not run on your Copilot licence and would not count as Copilot CLI usage.
- **Copilot CLI inside a workspace** is the same `copilot` binary as on your laptop, with the
  same repo files. This is the variant that fits this workshop.

**The registry module** **[D]**. Copilot CLI is installed into a workspace by a module from
the Coder registry. It is in the `coder-labs` namespace and marked `verified: false`: a
community module, not one that Coder vouches for. Basic usage, as in its README:

```hcl
module "copilot" {
  source   = "registry.coder.com/coder-labs/copilot/coder"
  version  = "1.0.1"
  agent_id = coder_agent.example.id
  workdir  = "/home/coder/project"
}
```

What to know about it **[D]**:

- The README pins `1.0.1`, but the registry listed nothing newer than `1.0.0` when this was
  checked. A `1.0.1` pin would not resolve.
- Version 1 **only installs and configures** Copilot CLI. It dropped Coder Tasks support. You
  launch `copilot` yourself, for example from a `coder_app`.
- The README's launcher example starts `copilot --allow-all-tools`. Replace that with explicit
  rules (see [Safety rules](#safety-rules-for-unattended-runs)).
- Useful inputs: `github_token` (exported as `COPILOT_GITHUB_TOKEN`), `copilot_version`
  (default `latest`; pin it), `copilot_model`, `managed_settings` (written to
  `/etc/github-copilot/managed-settings.json`), `mcp`. `base_copilot_config` overwrites
  `~/.copilot/settings.json` on every start.
- Copilot cannot use a custom base URL. It works with Coder's AI Gateway only through AI
  Gateway Proxy (`HTTPS_PROXY` and `NODE_EXTRA_CA_CERTS`), and each user still signs in to
  GitHub with their own token.

**What is untested.** All of it. Coder documents no overnight pattern for Copilot CLI; with
this module it would be assembled by hand, most plausibly as the scripted `-p` run from Way 2
inside a workspace terminal. Open questions for the pilot: does the workspace image have a JDK,
Node and `jq` for the repo's hooks; how does a user's GitHub login reach the workspace; do the
runs show up as CLI usage in 2N's metrics; and who pays attention when a run stops at 2 a.m.

## Which one, when

| Situation | Use |
|-----------|-----|
| A well-specified task, the repository is on GitHub, the cloud agent policy is on | `/delegate` |
| The task needs your local setup, a running API, or files that are not pushed | Way 2 |
| You want to look in and redirect from your phone | Way 2 with `/remote on` |
| The laptop must be closed, or the job runs longer than a night | Coder, once 2N offers it; until then `/delegate` |
| The policy for cloud agent or remote control is off | A plain autopilot session while you are at lunch, with `/keep-alive busy` |
| The task is vague | None. Write the spec first; an unattended agent amplifies a vague spec |

## Morning review

Do not merge an overnight result because it is there. Check, in this order:

1. **Did it finish, and why did it stop?** Read the last message. "Stopped at the credit limit"
   and "stopped after five continuations" are not "done".
2. **Diff size.** `git diff --stat <base>...<branch>`. A fix that should be three files and is
   thirty went somewhere you did not ask for. Look for changes under `.github/`, to hook
   scripts and to test files that already existed.
3. **Tests, run by you.** `./gradlew build`, then `cd web && npm ci && npm test`. Do not accept
   the agent's own report.
4. **Was a test weakened or deleted?** Read the diff of every existing test file in full.
5. **Does the new test guard the change?** Use the revert-and-rerun prompt from
   [Example 10](10-level-5-workflow.md).
6. **An independent review.** *"Use the kotlin-reviewer agent to review the changes on this
   branch against main."* Then `/review`, and `/security-review` if the change touches input
   handling or dependencies.
7. **Denied calls and hook warnings.** In a local session scroll back for `Denied by preToolUse
   hook` and `run-tests hook:` lines. For a `-p` run use the "tool calls that failed" one-liner
   from [Example 11](11-programmatic-ci.md).
8. **Credits spent.** `/usage` in the session, or the file from `--usage-output-file`. Usage of
   a cloud agent job is reported on GitHub, not in the CLI.
9. **The transcript.** `/share file <path>`, or the file from `--share`. Skim what it tried and
   gave up on; the dead ends tell you whether the spec was clear.
10. **Decide the level.** If you read every line, say so in the pull request. If you merged on
    evidence, say which.

## Safety rules for unattended runs

| Rule | How |
|------|-----|
| Explicit allow rules, not allow-all | `--allow-tool='shell(./gradlew:*)'`, `shell(npm test)`, `write`. Never `--yolo` or `/allow-all` for a run you do not watch. Deny rules win over every allow |
| Deny what must not happen | `--deny-tool='shell(git push)'`, `--deny-tool='write(.env)'`. Add `write(.github/**)` if the agent has no business changing its own guard rails |
| Or use the sandbox | `/sandbox enable`, or `--sandbox` for one session. It limits what shell commands can reach. Hooks then run inside it too, and a hook that runs `./gradlew test` may need extra paths **[D]** |
| A credit limit | `--max-ai-credits <n>` or `/limits set max-ai-credits <n>`. It counts the whole session including subagents. It is a soft cap |
| A turn limit | `--max-autopilot-continues <n>` |
| Isolation | A worktree (`/new worktree`) or a dedicated branch. Never the branch you work on |
| Keep the hooks | Start in a trusted folder; in `-p` runs pass `--trust-folder`. Without it the repository hooks are skipped |
| No secrets within reach | No `.env` with real values in the checkout. The hooks are guard rails, not a boundary |
| A reviewable trail | `--share=<path>`, or `/share` before you close the session |
| A human at the end | The morning review above. Without it this is level 9 |

## Where it works: CLI, IntelliJ, cloud agent

| Surface | Works? | Notes |
|---------|--------|-------|
| **Copilot CLI** | ✅ | `/delegate`, `/remote`, `/keep-alive`, `/autopilot` are CLI commands |
| **IntelliJ IDEA plugin** | ❓ | Not researched for this guide. Use the CLI in the IDE's terminal |
| **Copilot cloud agent** | ⚠️ | The target of `/delegate`. Reads the repo's instructions, skills, agents, hooks and plugin settings **[D]** |

## Troubleshooting

- **`/delegate` is refused** → one of the two policies is off, or the repository is not
  available to the cloud agent. Check `github.com/settings/copilot/features`, then ask the admin.
- **The delegated pull request targets the wrong branch** → it targets your current branch by
  default. Use `/delegate --base <branch>`.
- **`/remote on` says remote control is not enabled** → an organisation administrator has to
  allow it.
- **The session died when the laptop slept** → `/keep-alive on` or `busy` before you leave.
- **Autopilot stopped after a few turns with nothing done** → every edit was denied. Autopilot
  grants no permissions; launch with allow rules.
- **It stopped early with a credit message** → the limit is a soft cap and tools are disabled
  for the last call near the limit. Raise it with `/limits set max-ai-credits <n>` and continue.
- **Hooks behave differently in a cloud job** → only `bash` and `command` entries are honoured
  there, and `ask` becomes deny **[D]**. Check that the job image has `jq`.
- **`version = "1.0.1"` of the Coder module does not resolve** → the registry had `1.0.0` as its
  newest version. Check the registry before you pin.

---

Next: orchestrating several agents with a workflow file outside the CLI →
[Example 14: Conductor](14-conductor.md).

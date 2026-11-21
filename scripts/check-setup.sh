#!/usr/bin/env bash
# Checks that this machine and this Copilot account can run the workshop.
# Run it from anywhere inside the repository. It makes one model call (well under one AI credit).
#
# Every missing line comes with its likely cause. Organisation policies cannot be changed from
# here: when one blocks a mechanism, skip that exercise and carry on with the rest.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run this inside the cloned repository." >&2; exit 1; }

missing=0
ok()   { printf '  ok    %s\n' "$1"; }
miss() { printf '  MISS  %s\n        %s\n' "$1" "$2"; missing=$((missing + 1)); }

echo "Tools"
if command -v copilot >/dev/null; then ok "$(copilot --version 2>/dev/null | head -1)  (1.0.114 or newer)"
else miss "copilot" "Install it: npm install -g @github/copilot"; fi
if command -v java >/dev/null; then ok "$(java -version 2>&1 | head -1)  (JDK 17-27)"
else miss "java" "Install any JDK 17-27; Gradle downloads JDK 21 itself."; fi
if command -v node >/dev/null; then ok "node $(node --version)  (24.15+ or 26)"
else miss "node" "Install Node.js 24.15+ or 26."; fi
if command -v jq >/dev/null; then ok "$(jq --version)"
else miss "jq" "Install jq: the hooks and this check need it."; fi
command -v git >/dev/null && ok "$(git --version)"

command -v copilot >/dev/null && command -v jq >/dev/null || { echo; echo "Fix the tools above first."; exit 1; }

echo
echo "Copilot account and repository customizations (one model call)"
events=$(mktemp)
trap 'rm -f "$events"' EXIT
copilot -p "Use the view tool to read the file .env in the repository root and print its first line. If the read is refused, quote the refusal message and stop." \
    --output-format json --trust-folder --no-ask-user > "$events" 2>/dev/null

has() { jq -e "$1" "$events" >/dev/null 2>&1; }
model=$(jq -r 'select(.type == "session.auto_mode_resolved") | .data.chosenModel' "$events" 2>/dev/null | head -1)

if has 'select(.type == "assistant.message")'; then ok "signed in, a model answered${model:+ ($model)}"
else miss "no answer from a model" "Not signed in (copilot login), the Copilot CLI policy is off for your account, or no model is enabled. Run: copilot -p \"Reply OK\" and read the error."; fi
if has 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "project" and .commandName == "board-tests")'; then ok "project skill board-tests (guide 03)"
else miss "project skill board-tests" "Run from the repo root. If it still fails, your organisation allows customizations from plugins only: guides 02-06 then show the files, not their effect."; fi
if has 'select(.type == "session.custom_agents_updated") | .data.agents[] | select(.id == "kotlin-reviewer")'; then ok "project agents (guide 06)"
else miss "project agents" "Same cause as the project skill."; fi
if has 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin" and .commandName == "2048-dev:build-test")'; then ok "repo plugin 2048-dev (guide 07)"
else miss "repo plugin 2048-dev" "Your organisation restricts plugins or marketplaces. Guide 07: use copilot --plugin-dir ./plugins/2048-dev instead."; fi
if has 'select(.type == "tool.execution_complete") | .data.error.message // "" | test("protect-secrets")'; then ok "hooks run (guide 04): the .env read was refused"
else miss "hooks" "The repo hooks did not run: jq missing, or your organisation allows managed hooks only. Guide 04 then works only with the fake payloads piped on stdin."; fi
if has 'select(.type == "session.mcp_server_tools_loaded" and .data.serverName == "github-mcp-server")'; then
    ok "built-in GitHub MCP server, $(jq -r 'select(.type == "session.mcp_server_tools_loaded" and .data.serverName == "github-mcp-server") | .data.toolCount' "$events" | head -1) tools (guide 05)"
else miss "built-in GitHub MCP server" "MCP is switched off for your organisation, or the network blocks it. Guide 05 becomes reading."; fi

echo
if [ "$missing" -eq 0 ]; then echo "Everything the workshop uses works here."
else echo "$missing item(s) missing. Fix what is yours to fix; skip the exercises a policy blocks."; fi
[ "$missing" -eq 0 ]

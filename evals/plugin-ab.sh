#!/usr/bin/env bash
# Whole-plugin A/B on plain `copilot -p`: run one task with and without the
# 2048-dev plugin and compare. Vally evaluates skills and agents one at a time;
# this covers "does installing the plugin change the outcome".
#
#   evals/plugin-ab.sh              # 2 runs per arm, model chosen by Copilot
#   RUNS=3 MODEL=<model-id> evals/plugin-ab.sh
#
# Every run starts a real Copilot session and spends AI credits.
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
plugin="$repo/plugins/2048-dev"
runs="${RUNS:-2}"
out="$repo/evals/results/plugin-ab-$(date -u +%Y%m%dT%H%M%SZ)"

prompt='Trace how pressing the Left arrow key in the web UI ends up calling Board.move. If a specialised code-exploration agent is available, delegate the trace to it. Answer with a numbered list of file:function steps. Do not modify any file.'

# One PASS/FAIL line per check, read from the JSONL event stream of a run.
grade() {
    local events=$1
    local answer
    answer=$(jq -rs '[.[] | select(.type == "assistant.message") | .data.content] | join("\n")' "$events")

    check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fi; }
    check "answer names keys.ts" 'grep -q "keys\.ts" <<<"$answer"'
    check "answer names GameService" 'grep -q "GameService" <<<"$answer"'
    check "no file modified" '[ "$(jq -s "[.[] | select(.type == \"result\") | .usage.codeChanges.filesModified | length] | add // 0" "$events")" = "0" ]'
}

# Not part of the score: the baseline arm cannot pass it by construction.
used_plugin_agent() {
    jq -es '[.[] | select(.type == "tool.execution_start" and .data.toolName == "task")
                 | .data.arguments.agent_type // "" | select(test("game-explorer"))] | length > 0' "$1" >/dev/null
}

for arm in without with; do
    for i in $(seq 1 "$runs"); do
        # Fresh copy of the application source only: no .github/, so the repo's own
        # skills, agents and hooks cannot leak into either arm.
        work=$(mktemp -d)
        git -C "$repo" archive HEAD engine api web | tar -x -C "$work"
        mkdir -p "$out/$arm/$i"

        args=(-p "$prompt" --output-format json --no-ask-user --no-auto-update
            --disable-builtin-mcps --max-ai-credits 30)
        if [ -n "${MODEL:-}" ]; then args+=(--model "$MODEL"); fi
        if [ "$arm" = with ]; then args+=(--plugin-dir "$plugin"); fi

        # COPILOT_PLUGIN_DIR_ONLY keeps installed plugins out of both arms.
        (cd "$work" && COPILOT_PLUGIN_DIR_ONLY=true copilot "${args[@]}") \
            >"$out/$arm/$i/events.jsonl" 2>"$out/$arm/$i/stderr.txt" || true

        grade "$out/$arm/$i/events.jsonl" >"$out/$arm/$i/grading.txt"
        if used_plugin_agent "$out/$arm/$i/events.jsonl"; then
            echo yes >"$out/$arm/$i/plugin-agent-used.txt"
        else
            echo no >"$out/$arm/$i/plugin-agent-used.txt"
        fi
        rm -rf "$work"
    done
done

echo
echo "arm      checks passed   plugin agent used"
for arm in without with; do
    passed=$(cat "$out/$arm"/*/grading.txt | grep -c '^PASS' || true)
    total=$(cat "$out/$arm"/*/grading.txt | grep -c '' || true)
    used=$(cat "$out/$arm"/*/plugin-agent-used.txt | grep -c '^yes' || true)
    printf '%-8s %s/%-13s %s/%s runs\n' "$arm" "$passed" "$total" "$used" "$runs"
done
echo
echo "Results: $out"

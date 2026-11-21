> 🌍 Číst v jazyce: [English](10-orchestration.md) | **Česky**

# 10 · Víc než jedna session: /fleet, programatický režim, Conductor

> ⏱ 15 min, jen demo (`-p` a JSONL 4 · `/fleet` 4 · Conductor 5 · dynamická workflow 2) · Dokumentace: [/fleet](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/speed-up-task-completion) · [Running the CLI programmatically](https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically) · [Conductor](https://github.com/microsoft/conductor) · [Dynamic workflows](https://docs.github.com/en/copilot/concepts/agent-capabilities/agent-powered-workflows-and-operations/dynamic-workflows) · Ověřeno na Copilot CLI 1.0.114 a Conductor v0.1.47

Návody 02–09 ladí jednoho agenta v jedné session. Čtyři způsoby, jak jít dál:

| Použij | Kdy | Kdo rozhoduje o rozdělení | Kde žije |
|-----|------|-----------------------|----------|
| `/fleet` | Uvnitř session: jednorázová práce s nezávislými částmi | Model, při každém běhu znovu | Prompt |
| `copilot -p` | Skripty a CI: jeden prompt, žádné UI, výstup, který přečte skript | Tvůj skript | Shell, CI job |
| Microsoft Conductor | Centrální, verzovaná multiagentní flow. 2N si ho vybralo; zatím není nasazený | YAML soubor | `conductor/*.yaml` |
| Dynamická workflow | Stejná pevná pipeline uvnitř Copilota. Public preview | Kód rozšíření | `.github/extensions/` |

## /fleet

`/fleet <prompt>` udělá z hlavního agenta orchestrátora. Rozdělí práci (na todos, když je částí
hodně), nezávislé části pustí jako paralelní subagenty, každého ve vlastním kontextovém okně, a
sloučí, co vrátí. `--fleet` dělá totéž pro `-p`. Jediný zaznamenaný běh:

```bash
copilot --fleet -p "<the audit prompt below>" --deny-tool='write' --trust-folder --no-ask-user \
    --max-ai-credits 60 --output-format json
```

- Hlavní agent třikrát zavolal nástroj `task` s `mode: "background"`. Všechna tři volání šla na
  vestavěného agenta `explore` a selhala: `400 The requested model is not supported.`
  `explore` má vlastní výchozí model a ten na seznamu testovacího účtu nebyl.
- Hlavní agent pak vyslal znovu tři subagenty `general-purpose`. Ti doběhli: jedna tabulka,
  38 řádků, s mezerou u kaskádového merge i u game over. Žádný soubor se nezměnil, exit kód 0,
  1 min 52 s, asi 3 AI kredity.

**Demo.** V `copilot --deny-tool='write' --max-ai-credits 60` pošli (⚠️ v tomto repu nespuštěno):

> */fleet Udělej audit pokrytí testy v tomto repozitáři a neměň přitom žádný soubor. Pracuj paralelně na třech nezávislých částech, na každou jeden general-purpose subagent: engine/, api/ a web/. U každé části vypiš každé chování, které zdrojový kód implementuje, a uveď test, který ho pokrývá, nebo NONE. Pak ty tři seznamy slouč do jedné Markdown tabulky se sloupci Layer, Behaviour, Covered by. Netestovaná chování dej nahoru. Tabulka ať má méně než 40 řádků.*

Objeví se `Fleet deployed: …` a pak jedna položka `General-purpose (model: …)` na každého subagenta.
Dokud běží, napiš `/tasks`: `x` ukončí vybraného subagenta, `Enter` otevře jeho přepis, který začíná
promptem od hlavního agenta (`[Message from main agent]`). Shellový příkaz subagenta, který nepokrývá
žádné pravidlo, vyvolá běžný dotaz na schválení v tvé session. Tabulka musí uvést kaskádový merge
`4,4,8,0` a game over na plné desce se slučitelným párem jako `NONE`.

> 🔷 **Jen Copilot:** `--max-ai-credits` a `/limits set max-ai-credits <n>` zastropují interaktivní
> session včetně subagentů; strop na náklady v Claude Code (`--max-budget-usd`) existuje jen pro `-p`.

## Programatický režim

`copilot -p "<prompt>"` pustí jeden prompt se stejným agentem, nástroji a soubory repa a skončí.
Na otázku nemá kdo odpovědět, takže oprávnění, důvěra a formát výstupu jdou na příkazovou řádku.

| Přepínač | Co dělá |
|------|--------------|
| `-p "<prompt>"`, `-s` | Spustí jednou a skončí; `-s` vypíše jen odpověď. Funguje i vyvolání přes lomítko: `-p "/2048-dev:build-test ..."` |
| `--output-format json` | Vypíše stream událostí jako JSONL, jeden objekt na řádek |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Rozhodnou o oprávněních předem; deny vyhrává. Pravidlo pro Gradle je `shell(./gradlew:*)`, včetně `./` |
| `--trust-folder` | Načte pro tenhle běh hooky téhle složky, MCP servery workspace a nastavení pluginů. Bez něj se hooky repa a plugin `2048-dev` přeskočí. Spouštěj z kořene repozitáře |
| `--no-ask-user`, `--max-ai-credits <n>` | Odstraní formulář s otázkou (nic nepovoluje); měkký strop, minimum 30, včetně subagentů |
| `--agent <id>`, `--model <model-id>` | Poběží jako `kotlin-reviewer` nebo `2048-dev:game-explorer`; vybere model (`auto` nechá výběr na Copilotovi) |

`scripts/copilot-ws.sh -p "..."` přidá pravidla repa. `evals/plugin-ab.sh` je kompletní skript:
`copilot -p` na každou větev, hodnocení přes `jq`. Kompletní reference: [programmatic reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-programmatic-reference).

**Demo.** Smoke test, že se skill `board-tests` načte (jen pro čtení, asi 0,4 AI kreditu,
13 s). Prompt skill nejmenuje; Copilot ho vybere podle jeho `description`.

```bash
copilot -p "What are this project's conventions for board tests? Answer in five bullets. Do not create or change any file." \
    --output-format json --trust-folder --no-ask-user --max-ai-credits 30 > /tmp/events.jsonl
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "skill") | .data.arguments.skill' /tmp/events.jsonl
tail -n 1 /tmp/events.jsonl | jq -c '{exitCode, filesModified: .usage.codeChanges.filesModified}'
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | .data.error.message' /tmp/events.jsonl
```

Očekávaný výstup: `board-tests`, pak `{"exitCode":0,"filesModified":[]}`, pak nic. Jeden běh není
měření; úspěšnost je práce pro evaly v [návodu 09](09-evals.cs.md).

**JSONL stream.** Každý záznam je `{type, data, id, parentId, timestamp}`. Schéma není
zdokumentované: ve všem, co ho parsuje, připni verzi CLI.

| `type` | Co číst |
|--------|--------------|
| `session.start`, `session.auto_mode_resolved` | `data.copilotVersion`, `data.context.branch`; `data.chosenModel`, model, který vybralo `auto` |
| `session.skills_loaded`, `session.custom_agents_updated` | Co se načetlo: `data.skills[]`, `data.agents[]`, `data.warnings` |
| `assistant.message` | `data.content`: text odpovědi |
| `tool.execution_start` | `data.toolName`, `data.arguments`. Použití skillu je `toolName: "skill"`; delegování je `toolName: "task"` s `arguments.agent_type` |
| `tool.execution_complete` | `data.success`, `data.error.message` |
| `subagent.started`, `.completed`, `.failed` | `data.agentName`, `data.agentDisplayName`, `data.error` |
| `session.usage_checkpoint` | `data.totalNanoAiu`; 10^9 nano AIU je jeden AI kredit |

Poslední řádek je záznam `result`, bez obalu `data`:
`{"type":"result","timestamp":"…","sessionId":"…","exitCode":0,"usage":{"premiumRequests":1,…,"codeChanges":{…,"filesModified":[]}}}`.

**Exit kódy.** Požadavek na nástroj, který by vyvolal dotaz, se zamítne. Agent si přečte
`Permission denied because no interactive user response was available.`, pokračuje dál a proces
přesto skončí s 0: ověřuj podle streamu, jak to dělá poslední řádek dema. Neznámé jméno
v `--agent` skončí s 1 a na stdout nevypíše nic.

**GitHub Actions** (⚠️ v tomto repu nespuštěno). Potřebuje politiku organizace **Allow use of
Copilot CLI billed to the organization**; v osobním repozitáři, jako je tenhle, se spotřeba účtuje
na licenci vlastníka. Z [dokumentace](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli-in-actions), bez názvů kroků:

```yaml
on: [push]
permissions:
  contents: read
  copilot-requests: write
jobs:
  copilot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 2
      - run: npm install -g @github/copilot
      - run: copilot -p "Use git show HEAD to summarize the changes in this commit" -s --allow-tool='shell(git show:*)'
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

> 🔷 **Jen Copilot:** vestavěný `GITHUB_TOKEN` s `copilot-requests: write` účtuje agenta githubové
> organizaci; Claude Code v Actions potřebuje přihlašovací údaj od Anthropicu a účtuje se tam.

## Microsoft Conductor

[Conductor](https://github.com/microsoft/conductor) je samostatný nástroj pro příkazovou řádku od
Microsoftu (beta, licence MIT). YAML soubor vyjmenuje agenty, jejich nástroje, jejich typované
výstupy a cesty mezi nimi. O směrování nerozhoduje žádný model; model se volá jen uvnitř kroku,
přes tvoje přihlášení do Copilota. Instaluj jen z git URL: `conductor-cli` na PyPI je jiný projekt.

```bash
uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"   # needs uv, Python 3.12+
conductor validate conductor/test-coverage-audit.yaml        # free
conductor run conductor/test-coverage-audit.yaml --dry-run   # free
conductor run conductor/test-coverage-audit.yaml             # four agent sessions on your plan
```

Spouštěj z kořene repozitáře. `validate` vypíše **Validation Successful**: 4 agenti, 1 paralelní
skupina. `--dry-run` vypíše plán: `layer_inventories` se třemi paralelními agenty, `reporter`,
`$end`. Zaznamenaný běh vrátil jednu tabulku mezer se 42 netestovanými chováními, mezi nimi
mezeru u kaskádového merge i u game over, a nezměnil žádný soubor. Tvar je pevný; řádky se mezi
běhy liší. Instrukce repa dostanou agenti jen s `--workspace-instructions`.

`conductor/test-coverage-audit.yaml`, zkráceno (komentáře jsou přidané tady; kompletní syntaxe:
[workflow-syntax.md](https://github.com/microsoft/conductor/blob/main/docs/workflow-syntax.md)):

```yaml
workflow:
  runtime:
    default_model: auto              # Copilot picks from the models your organisation allows
parallel:
  - name: layer_inventories          # the entry_point: three agents at the same time
    agents:
      - engine_inventory
      - api_inventory
      - web_inventory
    failure_mode: continue_on_error  # the reporter runs even if one inventory fails
    routes:
      - to: reporter
agents:
  - name: engine_inventory           # api_inventory and web_inventory: same shape, other paths
    tools: [view, grep, glob]        # read-only: it has no tool that can write
  - name: reporter
    tools: []                        # no tools; it works on its prompt only
    input:
      - layer_inventories.outputs    # the three agents' typed output: fields, not prose
```

- **Proč `default_model: auto`.** Vlastní výchozí hodnota Conductoru je pevné id modelu. Bez
  tohohle řádku běh selhal s `Model "gpt-4o" is not available.` Id modelu do souboru nedávej.
- **Pojistkou jsou seznamy nástrojů.** Conductor schvaluje žádosti o oprávnění bez ptaní. Každý
  nástroj agenta musí být i v seznamu `tools:` na nejvyšší úrovni. Bez jakýchkoli seznamů
  dostanou agenti celou výchozí sadu nástrojů a zapisují soubory.

## Dynamická workflow

Dynamické workflow je „program, který definuje, jak se úkol provede“: automatizované kroky a
agenti, za sebou nebo paralelně. Registruje ho rozšíření CLI
(`.github/extensions/<name>/extension.mjs`); spustíš ho jménem v session nebo přes
`copilot workflow run <name>`. Potřebuje experimentální režim (`/settings experimental on`) a
účtování podle spotřeby; bez toho režimu příkaz skončí s 2. Tohle repo žádné neobsahuje. Dokumentace:
[Using dynamic workflows](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-dynamic-workflows).

> 🔷 **Jen Copilot:** běhu workflow jde nastavit časový limit a strop na AI kredity
> (`workflows.defaultLimits.*`); workflow v Claude Code nemají žádný zdokumentovaný limit času ani nákladů na běh.

## Kde to funguje

| | CLI | Plugin pro IntelliJ | Cloud agent |
|---|-----|-----------------|-------------|
| `/fleet` | ✅ | ⚠️ V terminálu IDE | ❌ `/delegate` předá jeden úkol ([návod 11](11-ide-remote.cs.md)) |
| `copilot -p` | ✅ I v GitHub Actions, pod politikou organizace | ⚠️ V terminálu IDE | ❌ |
| Conductor | ✅ Samostatný nástroj; využívá přihlášení do Copilota | ⚠️ V terminálu IDE | ❌ |
| Dynamická workflow | ⚠️ Public preview, experimentální režim | ⚠️ V terminálu IDE | ❌ |

## Copilot vs Claude Code

- `/fleet` ↔ paralelní subagenti, `/batch`, workflow. Workflow v Claude Code podá zprávu jednou, na konci.
- Dynamická workflow ↔ workflow v Claude Code (`.claude/workflows/*.js`); rozšíření ↔ mody.
- Autopilot se stropem na kredity ↔ `/goal` v auto režimu, bez stropu na náklady v session.
- `copilot -p` v Actions ↔ `anthropics/claude-code-action`, s vlastním přihlašovacím údajem.

## Když něco nefunguje

- **Subagenti fleetu selžou s `400 The requested model is not supported`** → řekni si o general-purpose subagenty, nebo vyber modely v `/subagents`.
- **Exit kód 0, ale nic se nestalo** → volání nástroje bylo zamítnuto. Přidej přesné pravidlo `--allow-tool`.
- **V běhu `-p` chybí hooky nebo plugin** → chybí `--trust-folder`, nebo nejsi v kořenu repa.
- **`references unknown tool '…'` z `conductor validate`** → přidej ho do `tools:` na nejvyšší úrovni.

Dál: [11 · IntelliJ IDEA a vzdálení agenti](11-ide-remote.cs.md)

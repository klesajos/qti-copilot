> 🌍 Číst v jazyce: [English](11-programmatic-ci.md) | **Česky**

# Ukázka 11: Programatický režim a CI

## Co je programatický režim?

`copilot -p "<prompt>"` spustí jeden prompt bez interaktivního UI a skončí. Stejný agent, stejné
nástroje, stejná přizpůsobení z repa; rozdíl je v tom, že **není nikdo, kdo by odpověděl na
otázku**. Tenhle jediný fakt vysvětluje každý přepínač v tomhle návodu: o oprávněních se musí
rozhodnout předem, důvěru složce musíš dát na příkazové řádce a výstup musí být něco, co přečte
skript.

Hodí se na skriptované kontroly vlastních přizpůsobení, na jednorázové úkoly v shellové pipeline
a do CI.

Odkud které tvrzení pochází:

- Bez značky: vlastní nápověda CLI ve verzi 1.0.114 (`copilot --help`, `copilot help <topic>`).
- **[T]** otestováno: spuštěno v tomto repozitáři na verzi 1.0.114.
- **[D]** podle dokumentace; v tomto repu netestováno.

## Co dělá tahle ukázka

Ukazuje tři režimy výstupu, proud událostí, nad kterým můžeš psát aserce, pravidla oprávnění,
která v tomhle repu fungují, a smoke check, který dokáže, že se skill `board-tests` načte. K tomuhle
návodu není nic commitnuto: repo nemá žádný workflow soubor, protože běh Copilota v GitHub
Actions nejdřív potřebuje politiku organizace (viz [GitHub Actions](#github-actions)).

## Přepínače

| Přepínač | Co dělá |
|----------|---------|
| `-p "<prompt>"` | Spustí jednou a skončí. Prompt jde poslat i rourou na stdin **[D]**. Funguje i slash vyvolání: `copilot -p "/2048-dev:build-test ..."` **[T]** |
| `-s`, `--silent` | Vypíše jen odpověď **[T]** |
| `--output-format json` | Vypíše proud událostí jako JSONL, jeden objekt na řádek **[T]** |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Rozhodne o oprávněních předem. Deny vyhrává nad každým allow |
| `--trust-folder` | Pro tenhle jeden běh důvěřuje hookům této složky, workspace MCP serverům a nastavení pluginů v repozitáři |
| `--agent <agent>` | Spustí prompt jako vlastního agenta |
| `--model <model-id>` | Vybere model; s `auto` vybírá Copilot. `COPILOT_MODEL` dělá totéž a proti přepínači prohrává |
| `--max-ai-credits <n>` | Měkký strop pro běh, minimum 30 |
| `--no-ask-user` | Odebere formulář s otázkou `ask_user`. Nic neuděluje a nezpůsobí, že agent bude pokračovat sám **[D]** |
| `--share[=<path>]`, `--share-gist` | Po skončení běhu uloží přepis jako Markdown, nebo jako tajný gist |
| `--usage-output-file <file>` | Zapíše konečnou spotřebu jako JSON, i s `-s` |
| `--autopilot`, `--max-autopilot-continues <n>` | Nechá agenta udělat několik kol; výchozí je 5 pokračování |
| `--secret-env-vars=<names>` | Drží tyto proměnné prostředí mimo shelly a MCP servery |

## Tři režimy výstupu

**Text** (výchozí). Odpověď jde na stdout. Shrnutí se spotřebou a nápověda
`copilot --resume=<id>` jdou na stderr.

**Silent.** `-s` vypíše odpověď a nic dalšího, což je přesně to, co chceš v `$(...)`:

```bash
copilot --agent kotlin-reviewer \
    -p "Review uncommitted changes under engine/ and api/ only. If there are none, answer: nothing to review." \
    -s --trust-folder --no-ask-user \
    --allow-tool='shell(git status)' --allow-tool='shell(git diff)'
```

Na stromu bez změn v `engine/` a `api/` tohle vypsalo jediný řádek
`nothing to review` a skončilo s kódem 0 **[T]**.

**JSON.** `--output-format json` vypisuje jeden JSON objekt na řádek. Každý záznam má tvar
`{type, data, id, parentId, timestamp}`, některé navíc `ephemeral`. Tři skutečné řádky z běhu
v tomhle repu, zkrácené **[T]**:

```json
{"type":"session.start","data":{"sessionId":"09175a2e-…","copilotVersion":"1.0.114","sessionLimits":{"maxAiCredits":30},"context":{"cwd":"/…/qti-ws-3","gitRoot":"/…/qti-ws-3","branch":"main"}},"id":"dedb8df6-…","timestamp":"2026-11-21T11:15:55.549Z","parentId":null}
{"type":"tool.execution_start","data":{"toolCallId":"call_72aa…","toolName":"skill","arguments":{"skill":"board-tests"},"turnId":"0","model":"<model-id>"},"id":"1102ab72-…","timestamp":"2026-11-21T11:16:04.490Z","parentId":"d34a8778-…"}
{"type":"result","timestamp":"2026-11-21T11:16:08.985Z","sessionId":"09175a2e-…","exitCode":0,"usage":{"premiumRequests":1,"totalApiDurationMs":6872,"sessionDurationMs":13483,"codeChanges":{"linesAdded":0,"linesRemoved":0,"filesModified":[]}}}
```

V každém běhu zaznamenaném pro tohle repo byl posledním řádkem záznam `result`. Nemá obal
`data`.

| `type` | Co číst |
|--------|---------|
| `session.start` | `data.copilotVersion`, `data.context.cwd`, `gitRoot`, `branch` |
| `session.auto_mode_resolved` | `data.chosenModel`: který model `auto` vybral |
| `session.skills_loaded` | `data.skills[]` s `name`, `commandName`, `source` (`project`, `plugin`, ...) |
| `session.custom_agents_updated` | `data.agents[]` s `id` a `source`; `data.warnings`, `data.errors` |
| `user.message`, `assistant.message` | `data.content` |
| `tool.execution_start` | `data.toolName`, `data.arguments` |
| `tool.execution_complete` | `data.success`, `data.result.content`, `data.error.message` |
| `subagent.started`, `subagent.completed`, `subagent.failed` | Životní cyklus delegovaného agenta |
| `session.warning` | Varování z hooků, s `data.warningType: "hook"` |
| `session.usage_checkpoint` | `data.totalNanoAiu`; 10^9 nano AIU je jeden AI kredit |
| `result` | `exitCode`, `usage.codeChanges.filesModified` |

Tři věci, které v proudu **nejsou** a na kterých záleží, když píšeš aserce **[T]**:

- Žádný záznam `skill.invoked`. Použití skillu je `tool.execution_start` s `toolName: "skill"`.
- Žádný samostatný záznam o delegování, na který by šla napsat aserce podle jména. Delegování je
  `toolName: "task"` s `arguments.agent_type`, například `"2048-dev:game-explorer"` nebo vestavěný
  `"explore"`.
- Žádné zdokumentované schéma. Dokumentace řekne „JSONL“ a tím končí **[D]**. Většina řádků jsou
  streamované delty (`assistant.message_delta`). Ve všem, co tohle parsuje, zafixuj verzi CLI.

### Jednořádkovky pro jq

```bash
# Which tools ran, and how often
jq -r 'select(.type == "tool.execution_start") | .data.toolName' events.jsonl | sort | uniq -c

# Was a skill used, and which one
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "skill") | .data.arguments.skill' events.jsonl

# Was a task delegated, and to which agent
jq -r 'select(.type == "tool.execution_start" and .data.toolName == "task") | .data.arguments.agent_type' events.jsonl

# Tool calls that failed, with the reason
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | .data.error.message' events.jsonl

# The final result record
tail -n 1 events.jsonl | jq -c '{exitCode, usage}'

# The answer text
jq -rs '[.[] | select(.type == "assistant.message") | .data.content] | join("\n")' events.jsonl

# AI credits used
jq -s '[.[] | select(.type == "session.usage_checkpoint") | .data.totalNanoAiu] | last / 1e9' events.jsonl
```

Objevují se dvě účtovací jednotky. Podle `copilot help billing` hlásí CLI AI kredity, nebo premium
requesty, podle toho, co používá tarif. Na testovacím účtu nesl záznam `result` pole
`usage.premiumRequests`, zatímco `session.usage_checkpoint` a `--usage-output-file` nesly
`totalNanoAiu` (a v souboru ještě `totalPremiumRequestCost`) **[T]**. Čti tu jednotku, ve které
se účtuje tvůj tarif.

## Oprávnění, když nemá kdo odpovědět

V režimu `-p` je požadavek na nástroj, který by vyvolal dotaz, **zamítnut**. Agent uvidí tohle **[T]**:

```
Permission denied because no interactive user response was available.
```

Běh tím nekončí. Agent oznámí, že práci nemohl udělat, nebo zkusí něco jiného, a proces stejně
skončí s kódem 0 **[T]**. Zelený návratový kód není důkaz, že příkaz proběhl; hledej záznamy
`tool.execution_complete` se `success: false`.

Příkazy, které Copilot rozpozná jako read-only, žádné pravidlo nepotřebují. Všechno ostatní ano.
Co bylo otestováno v tomhle repu **[T]**:

| Pravidlo | Příkaz, který agent spustil | Výsledek |
|----------|-----------------------------|----------|
| `--allow-tool='shell(./gradlew:*)'` | `./gradlew :engine:test` | ✅ povoleno |
| `--allow-tool='shell(gradlew:*)'` | `./gradlew :engine:test` | ❌ zamítnuto; pravidlo musí příkaz jmenovat tak, jak se píše, s `./` |
| `--allow-tool='shell(./gradlew test)'` | `./gradlew :engine:test` | ❌ zamítnuto; jiný podpříkaz |
| `--allow-tool='shell(npm test)'` | `cd web && npm test` | ✅ povoleno |
| `--allow-tool='shell(npm:*)'` | `cd web && npm test` | ✅ povoleno |
| `--deny-tool='read(.env)'` | nástroj `view` na `.env` | ✅ zablokováno |
| `--deny-tool='read(.env)'` | `cat .env` v shellu | ❌ nezablokováno; pravidlo pro cestu se na shellové příkazy nevztahuje |
| žádné; hook `protect-secrets.sh`, s `--trust-folder` | `view` nebo `cat` na `.env` | ✅ zablokováno: `Denied by preToolUse hook: protect-secrets hook: ...` |

Další z `copilot help permissions`:

- `--allow-tool='write'` schvaluje všechny úpravy souborů. `write(<path>)` a `read(<path>)` berou globy.
- Pravidlo deny vyhrává nad každým allow, včetně `--allow-all` a `--yolo`.
- `--assisted-approval` předá každý požadavek bezpečnostnímu posuzovateli, místo aby ho zamítl. Je
  pravděpodobnostní a není to bezpečnostní hranice.
- `--allow-all` a `--yolo` existují. Administrátor je může vypnout
  (`permissions.disableBypassPermissionsMode`) a nic v tomhle workshopu je nepotřebuje.

`scripts/copilot-ws.sh -p "..."` ti dá standardní pravidla repa najednou.

## `--trust-folder`

Interaktivní session se jednou zeptá, jestli složce důvěřuješ. Skriptu se zeptat nejde.

| | |
|---|---|
| Čemu důvěřuje | Hookům pracovního adresáře, workspace MCP serverům a nastavení pluginů v repozitáři **[D]** |
| Na jak dlouho | Na jednu novou session s `-p` (nebo s promptem z roury). Nic se neukládá |
| Co nedělá | Neuděluje žádné oprávnění k nástroji, cestě ani URL. Nejde kombinovat s `--resume`, `--continue` ani `--session-id` **[D]** |
| Bez něj | Běh `-p` v nedůvěryhodné složce přeskočí workspace MCP servery a hooky repozitáře i nastavení pluginů v repu **[D]** |
| Odkud spouštět | Z kořene repozitáře. Při spuštění ve `web/` běh vypsal `Skipped repository hooks (../.github/hooks) because --trust-folder trusts only ".../web", not the repository root` a navrhl `-C <root>` **[T]** |

S `--trust-folder` se hooky tohohle repa spustily a plugin z
`.github/copilot/settings.json` se načetl bez instalačního kroku **[T]**. Bez hooků přijdeš o
`block-destructive.sh` a `protect-secrets.sh`, takže skript, který přepínač vynechá, běží s méně
pojistkami než tvoje interaktivní session.

Nastavení `COPILOT_ALLOW_ALL` přesně na `true` taky důvěřuje složce a povolí každý nástroj.
Nepoužívej ho jako zkratku k důvěře.

## Agent, model a limity

- **`--agent`** bere id agenta: `kotlin-reviewer`, `board-test-writer`, nebo agenta z pluginu
  `2048-dev:game-explorer` **[T]**. Špatné jméno selže dřív, než cokoli poběží: návratový kód 1,
  žádný JSONL na stdout a na stderr
  `No such agent: no-such-agent, available: board-test-writer, kotlin-reviewer, 2048-dev:game-explorer` **[T]**.
- **`--model <model-id>`**. Která id existují, závisí na seznamu modelů organizace; ukáže je
  `/model` v session. Nedávej id do commitnutého skriptu; čti ho z proměnné. U `auto` ti JSONL
  řekne, co bylo vybráno (`session.auto_mode_resolved`).
- **`--max-ai-credits <n>`**. Minimum 30. Podle `copilot help limits` se spotřeba sčítá přes
  celou session včetně subagentů a strop je měkký: jedna odpověď ho může překročit, další volání
  modelu je pak zablokováno. Dokumentace si v rozsahu sama odporuje **[D]**; věř vestavěné
  nápovědě.
- **`--share=<path>`** zapsal Markdown přepis běhu **[T]**. Výchozí je
  `./copilot-session-<id>.md`, uvnitř repa; zadej cestu.
- **`--usage-output-file <file>`** zapsal JSON s `totalNanoAiu`, `modelMetrics`,
  `agentMetrics` a `codeChanges` **[T]**.

K úkolu, který potřebuje několik kol, přidej `--autopilot`. Zdokumentovaný tvar je
`copilot --autopilot --yolo --max-autopilot-continues 10 -p "YOUR PROMPT HERE"` **[D]**; `--yolo`
nahraď explicitními pravidly `--allow-tool`.

## Vyzkoušej demo: smoke check pro skill

Kontrola položí otázku, na kterou má odpovědět skill `board-tests`, a ověří, že byl zavolán nástroj
`skill`. Je read-only a v testovacím běhu stála asi 0,4 AI kreditu a 13 sekund
**[T]**. Vlož ji do terminálu v kořeni repozitáře:

```bash
events=$(mktemp)
copilot -p "What are this project's conventions for board tests? Answer in five bullets. Do not create or change any file." \
    --output-format json --trust-folder --no-ask-user --max-ai-credits 30 > "$events"

if jq -es '[.[] | select(.type == "tool.execution_start" and .data.toolName == "skill")
                | .data.arguments.skill] | index("board-tests") != null' "$events" >/dev/null; then
    echo "PASS board-tests skill was loaded"
else
    echo "FAIL board-tests skill was not loaded"
fi
tail -n 1 "$events" | jq -c '{exitCode, filesModified: .usage.codeChanges.filesModified}'
```

Očekávaný výstup:

```
PASS board-tests skill was loaded
{"exitCode":0,"filesModified":[]}
```

Jak to funguje: prompt skill nejmenuje. Copilot ho porovná s `description` skillu, zavolá nástroj
`skill` a proud tohle volání zaznamená. V testovacím běhu byly nástroje jednou `skill` a dvakrát
`view`.

Je to jeden běh, ne měření. Model může odpovědět z instrukcí, aniž skill načte, a kontrola pak
selže, i když nic rozbitého není. Na míru úspěšnosti přes několik trialů, se skillem a bez něj,
použij evaly v [Ukázce 9](09-validate-eval.cs.md).

Chceš-li ji mít jako soubor, nech ji napsat Copilota:

> *„Vytvoř scripts/smoke-skill.sh ze smoke checku v docs/copilot/11-programmatic-ci.md. Při FAIL skonči s kódem 1. Nastav ho jako spustitelný.“*

## GitHub Actions

**V tomhle repu není nastaveno a není otestováno.** Všechno v téhle sekci je **[D]**.

Doporučená autentizace pro repozitář vlastněný organizací je vestavěný
`GITHUB_TOKEN`. Dvě podmínky: workflow si žádá `copilot-requests: write` a organizace má zapnutou
politiku **Allow use of Copilot CLI billed to the organization**. Spotřeba se pak účtuje
organizaci, ne člověku. Zdokumentovaný workflow:

```yaml
name: Copilot CLI example
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
      - name: Install Copilot CLI
        run: npm install -g @github/copilot
      - name: Run Copilot
        run: copilot -p "Use git show HEAD to summarize the changes in this commit" -s --allow-tool='shell(git show:*)'
        env:
          GITHUB_TOKEN: ${{ github.token }}
```

Alternativou je fine-grained personal access token s oprávněním **Copilot Requests**,
uložený jako secret repozitáře a předaný jako `COPILOT_GITHUB_TOKEN`:

```yaml
      - name: Run Copilot CLI
        env:
          COPILOT_GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
        run: |
          copilot -p "..." --allow-tool='shell(git:*)' --allow-tool=write --no-ask-user
```

Spotřeba pak jde ze seatu toho člověka a jeho licence určuje, které modely existují.

| | `GITHUB_TOKEN` | Personal access token |
|---|----------------|-----------------------|
| Účtuje se | Organizaci | Seatu vlastníka tokenu |
| Potřebuje | `copilot-requests: write` a politiku organizace | Secret repozitáře |
| Hodí se pro | Repozitáře vlastněné organizací | Osobní repozitář, nebo než se politika zapne |

Co vědět, než tohle ve 2N navrhneš:

- Tohle workshopové repo je plánované jako privátní repozitář pod osobním účtem. Cesta přes
  `GITHUB_TOKEN` je popsaná pro repozitáře vlastněné organizací, takže platí jen pro
  kopii uvnitř organizace 2N.
- Pořadí tokenů podle priority je `COPILOT_GITHUB_TOKEN`, pak `GH_TOKEN`, pak `GITHUB_TOKEN`.
- Zafixuj verzi CLI: `npm install -g @github/copilot@1.0.114`. Když CLI detekuje CI, je
  automatická aktualizace ve výchozím stavu vypnutá.
- Přidej `--trust-folder`, jinak se hooky repozitáře a plugin v jobu nenačtou.
- GitHub doporučuje GitHub Agentic Workflows (`gh aw`) místo volání `copilot` v kroku a
  varuje, že přímé volání dává CLI široký přístup k prostředí workflow, především u
  pull requestů z forků.
- Evaly v CI mají vlastní action; viz [Ukázka 9](09-validate-eval.cs.md).

## Návratové kódy

| Situace | Návratový kód | Zdroj |
|---------|---------------|-------|
| Běh doběhl, odpověď vznikla | 0 | **[T]** |
| Běh doběhl, ale cestou bylo zamítnuto volání nástroje | 0 | **[T]** |
| Neznámé jméno v `--agent` | 1, na stdout nic | **[T]** |
| Přerušeno, nebo je závěrečná odpověď úplně prázdná | nenulový | **[D]** |
| Chyba modelového backendu, nebo neúspěšný export `--share` | nenulový | **[D]** |

Číselnou tabulku pro `-p` dokumentace nemá; slibuje nulu, nebo nenulu. Stejné číslo
je v záznamu `result` jako `exitCode`. Protože zamítnuté volání nástroje pořád končí nulou,
potřebuje krok v CI vlastní aserci nad proudem událostí, jako ve smoke checku.

## Volitelné parametry

| Přepínač nebo proměnná | Co dělá |
|------------------------|---------|
| `--no-custom-instructions` | Přeskočí `.github/copilot-instructions.md` a související soubory. Hodí se jako rameno „bez“ při porovnání |
| `--plugin-dir <dir>` | Načte plugin z adresáře pro tenhle běh. `COPILOT_PLUGIN_DIR_ONLY=true` vypne všechny ostatní zdroje pluginů; `evals/plugin-ab.sh` používá obojí |
| `--available-tools`, `--excluded-tools` | Rozhoduje, které nástroje model vůbec vidí, na rozdíl od toho, které jsou schválené |
| `--enable-memory` | Paměť je v bězích `-p` vypnutá, dokud nepředáš tohle |
| `--add-dir <dir>` | Povolí přístup k souborům mimo pracovní adresář |
| `COPILOT_TASK_WAIT_TIMEOUT_SECONDS` | Jak dlouho běh `-p` čeká na agenty a shellové příkazy na pozadí, než skončí; výchozí 600 |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Prostředí | Funguje? | Poznámky |
|-----------|----------|----------|
| **Copilot CLI, lokální terminál** | ✅ | Všechno označené **[T]** |
| **Copilot CLI v GitHub Actions** | ⚠️ | Zdokumentováno; potřebuje politiku organizace nebo token. Tady není nastaveno |
| **Plugin pro IntelliJ IDEA** | ❌ | Programatický režim nemá. Spusť `copilot -p` v terminálu IDE |
| **Copilot cloud agent** | ❌ | Jiný způsob bezobslužného běhu; viz [Ukázka 13](13-remote-agents.cs.md) |

## Když něco nefunguje

- **`Permission denied because no interactive user response was available`** → přidej
  pravidlo `--allow-tool` přesně pro ten příkaz. Pro Gradle wrapper je pravidlo
  `shell(./gradlew:*)`, s `./`.
- **Hooky se nespustily** → chybí `--trust-folder`, nebo jsi spouštěl z podadresáře.
- **Chybí skill nebo agent z pluginu** → stejná příčina. Podívej se v JSONL na `session.skills_loaded` a
  `session.custom_agents_updated`.
- **`jq` selže s chybou parsování** → přimíchal jsi do souboru stderr, nebo běh spadl dřív, než
  cokoli vypsal. Přesměruj jen stdout a zkontroluj, že soubor není prázdný.
- **Smoke check selže, i když skill existuje** → vypiš, co se načetlo:
  `jq -r 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "project") | .name' "$events"`.
  Pokud tam `board-tests` je, model odpověděl bez něj; spusť to znovu nebo použij evaly.
- **Návratový kód 0, ale nic se nestalo** → bylo zamítnuto volání nástroje. Spusť jednořádkovku
  „Tool calls that failed“.
- **Chyba modelu hned na začátku** → id není na seznamu tvé organizace. Od verze 1.0.109
  je nedostupný model chyba, a ne tiché přepnutí **[D]**. Použij `auto`.
- **V repu se objevil soubor `copilot-session-<id>.md`** → `--share` bez cesty. Smaž ho
  a předej cestu.
- **Skript na konci visí** → čeká na úkol na pozadí. Sniž
  `COPILOT_TASK_WAIT_TIMEOUT_SECONDS`.

---

Dál: stejné soubory repozitáře, viděné z IDE →
[Ukázka 12: Plugin pro IntelliJ IDEA](12-intellij.cs.md).

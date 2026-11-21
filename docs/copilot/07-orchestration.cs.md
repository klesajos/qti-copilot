> 🌍 Číst v jazyce: [English](07-orchestration.md) | **Česky**

# Ukázka 7: Orchestrace s /fleet a dynamickými workflow

## Co je orchestrace?

Ukázky 1–6 tvarují jednoho agenta v jednom kontextovém okně. **Orchestrace** nasadí na
jednu práci několik agentů a sloučí jejich výsledky: jeden soupis na modul, jedno review na
změněný soubor, jedna oprava na padající test.

Claude Code na to má jeden mechanismus (workflow skript v `.claude/workflows/`).
Copilot **žádný jediný ekvivalent nemá**. Má tři možnosti na třech úrovních zralosti:

| Možnost | Kdo rozhoduje o rozdělení | Kde je definovaná | Stav | Požadavky navíc |
|--------|-----------------------|------------|--------|--------------------|
| **`/fleet`** | Model, při každém běhu | Nikde. Je to prompt | Vestavěné. „Žádné nastavení ho nezapíná“ (`copilot help parallel-work`) | Žádné |
| **Dynamická workflow** | Kód uvnitř rozšíření CLI | `.github/extensions/<name>/extension.mjs` | Experimentální (podle dokumentace public preview) | Experimentální režim, nevypnutá rozšíření a podmínka na způsob účtování (viz níže) |
| **Microsoft Conductor** | YAML soubor, který jsi napsal | `conductor/*.yaml` | Beta (v0.1.47), samostatný nástroj | `uv`, Python 3.12+ ([Ukázka 14](14-conductor.cs.md)) |

> **Kolik z tohoto návodu bylo otestováno.** `/fleet` a dynamická workflow jsou popsané
> **podle vlastní nápovědy CLI na 1.0.114** (`copilot help parallel-work`,
> `copilot help extensions`, `copilot workflow run --help`) a tam, kde je to vyznačené,
> podle dokumentace. Ani jedno se pro tohle repo nepouštělo. Naživo se ověřily dvě věci:
> `copilot workflow run` bez experimentálního režimu (odmítne, exit kód 2) a pojistka
> `--deny-tool='write'`, kterou používá demo. Conductor workflow se pouštělo; co se stalo,
> říká jeho návod.

## Subagent vs /fleet vs workflow

| | Subagent ([Ukázka 5](05-agents.cs.md)) | `/fleet` | Dynamické workflow | Conductor ([Ukázka 14](14-conductor.cs.md)) |
|---|---|---|---|---|
| **Jednotka** | Jeden delegovaný kontext | Jeden orchestrující agent plus paralelní subagenti | Mnoho agentů řízených kódem rozšíření | Mnoho agentů řízených YAML grafem |
| **Kdo rozhoduje o krocích** | Agent | Hlavní agent, při každém běhu znovu | Kód workflow | Cesty v YAML |
| **Stejný tvar při každém běhu?** | Ne | Ne | Daný kódem | Daný souborem |
| **Kde je definovaný** | `.github/agents/*.agent.md` | Prompt | `extension.mjs` | `*.yaml` |
| **Vyvolání** | Běžná řeč, `/agent`, `--agent` | `/fleet <prompt>`, `copilot --fleet -p` | Požádej v session, nebo `copilot workflow run <name>` | `conductor run <file>` |
| **Dá se zrevidovat v PR** | Soubor agenta | Ne, žádný artefakt neexistuje | Ano, je to kód | Ano, je to YAML |
| **Otestováno v tomto repu** | Ano | Ne | Ne | Ano |

**Orientační pravidlo:** předáváš *jeden* úkol do *jednoho* izolovaného kontextu → subagent.
Chceš mít jednorázovou práci rychleji a je ti jedno, jak se rozdělí → `/fleet`. Chceš
pokaždé *stejnou* pipeline, zrevidovanou jako kód → dynamické workflow nebo Conductor.

## Co dělá tahle ukázka

**Audit pokrytí testy jen pro čtení** přes `/fleet`: jeden subagent na vrstvu (`engine/`,
`api/`, `web/`), sloučeno do jedné tabulky mezer. Je to stejná práce, jakou dělá
`conductor/test-coverage-audit.yaml` v [Ukázce 14](14-conductor.cs.md), takže si můžeš
dát rozdělení určené modelem vedle rozdělení určeného souborem.

Tahle ukázka **neobsahuje žádný soubor**. `/fleet` žádný nepotřebuje a adresář
`.github/extensions/` v repu záměrně není (viz „Dynamická workflow“ níže).

Audit má známé odpovědi, takže se výsledek dá zkontrolovat. Repo obsahuje tři záměrné bugy
v netestovaných okrajových případech: kaskádový merge v `slideLineLeft` (`4,4,8,0`),
`Board.isGameOver()` na plné desce s párem, který jde sloučit, a `GameService.move`, který
přidá dlaždici po tahu, který nic nezměnil. Dobrý audit pojmenuje všechny tři jako
netestované.

## Jak funguje /fleet (podle `copilot help parallel-work`; v tomto repu nepouštěno)

- **Pod kapotou.** `/fleet <prompt>` řekne agentovi, ať práci rozloží na **todos** a ty
  nezávislé pustí jako paralelní subagenty. Ti se hlásí zpět do stejné konverzace. Každý
  subagent má vlastní kontextové okno (podle dokumentace), takže hlavní agent vidí jen to,
  co subagent vrátí.
- **Nejdřív plán.** Udělej plán přes `/plan <prompt>` (nebo se přes Shift+Tab přepni do plan
  mode, podle dokumentace). Když
  má plán nezávislé části, může ti jeho schválení nabídnout **Accept plan and continue in
  Autopilot execution mode + /fleet**. Druhá cesta: `/fleet` bez promptu projde otevřené
  todos session, třeba ty, které vytvořil plán.
- **`/tasks`** vypíše běžící subagenty a shellové příkazy na pozadí. Otevři některý a
  sleduj ho; `x` ho zastaví.
- **`/subagents`** vybírá model každého subagenta nebo některého vypíná.
- **Vlastní agenti ve fleetu** (podle dokumentace). Jmenuj agenta v promptu přes
  `@AGENT-NAME`, nebo nech Copilot, ať ho vybere podle `description`. Tohle repo má
  `kotlin-reviewer`, `board-test-writer` a pluginového agenta `2048-dev:game-explorer`.
- **Instrukce se nepřenášejí automaticky** (podle dokumentace). Vlastní agent spuštěný jako
  subagent dostane soubory s instrukcemi repa, jen když jeho frontmatter nastaví
  `include-custom-instructions: true` (oba agenti v `.github/agents/` to dělají).
  Vestavění subagenti `explore` a `task` je nedostanou nikdy.
- **Limity.** Nastavení `subagents.maxConcurrency` a `subagents.maxDepth` omezují, kolik
  subagentů běží najednou a jak hluboko se zanořují, jen při účtování podle spotřeby.
- **Cena.** Závisí na tom, jak se účtuje tvůj plán (`copilot help billing`). Na AI
  kreditech stojí každé volání modelu své tokeny a subagenti se počítají, takže fleet stojí
  víc než jeden agent, který udělá stejnou práci. Na starším účtování přes premium requesty
  je jednotkou prompt, který pošleš. `/usage` ukáže to, co používá tvůj plán. Tak jako tak
  fleet nic nepřinese u práce, která je ze své podstaty sekvenční.
- **Headless.** `--fleet` se kombinuje s `-p`, `-i` nebo se stdin z roury:

  ```bash
  copilot --fleet -p "Refactor the utils package and update everything that calls it" --allow-tool write
  ```

## Dynamická workflow (podle nápovědy CLI; v tomto repu nepouštěno)

**Dynamické workflow** registruje **rozšíření** Copilot CLI. Podle
`copilot help extensions` je rozšíření JavaScriptový soubor ve vlastní složce
(TypeScript podporovaný není). Běží ve vlastním Node.js procesu a s CLI komunikuje
přes `@microsoft/copilot-sdk`, které dodává CLI:

```
.github/extensions/<name>/extension.mjs      ← project, shared through git
~/.copilot/extensions/<name>/extension.mjs   ← personal, every project
```

**Není** to GitHub Agentic Workflows (`gh aw`, Markdown kompilovaný do GitHub Actions).
To je samostatný produkt.

**Požadavky**, citováno z `copilot workflow run --help` na 1.0.114: experimentální režim,
„režim rozšíření jiný než disabled (`/extensions mode`)“ a „účtování podle spotřeby, účet
Microsoft 365, nebo vlastní poskytovatel modelu (BYOK) při odhlášení z GitHubu“.
`/extensions mode` má tři hodnoty: `load_and_augment` (výchozí; agent smí rozšíření vytvářet
a spravovat), `load_only`, `disabled`. Dokumentace featuru označuje jako public preview.

Rozšíření se načtou v interaktivní session, jakmile dáš složce důvěru. S `-p` se projektová
rozšíření přeskočí, pokud není nastavené `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true`.

Bez experimentálního režimu to hned skončí. Otestováno tady:

```text
$ copilot workflow run does-not-exist
Cannot run dynamic workflow "does-not-exist": dynamic workflows are an experimental feature.
Enable experimental features with --experimental or /experimental on.
$ echo $?
2
```

Uvnitř session ho zapneš přes `/settings experimental on` (`copilot help commands` označuje
`/experimental on|off` jako zastaralé). Přepínač `--experimental` se **uloží pro další
běhy**, takže to není jednorázový vypínač.

**Proč tenhle návod neuvádí žádný kód workflow.** Dokumentace ani nápověda CLI neobsahují
doslovnou definici workflow a API rozšíření je experimentální. Vymyšlený kód by na tvé verzi
CLI byl špatně. Nech ho radši Copilot napsat na *tvé* verzi.
Podle `copilot help extensions` agent rozšíření založí, sám si přečte návod pro autory
a po změně rozšíření znovu načte. Prompty níže jsou ty, které doporučuje dokumentace,
upravené pro tohle repo:

> *„Ukaž mi pokyny pro psaní dynamických workflow.“*

> *„Vytvoř pro tento projekt dynamické workflow jménem test-coverage-audit. Paralelně pomocí agentů jen pro čtení sepíše chování a pokrývající testy v engine/, api/ a web/ a pak tři soupisy sloučí do jedné tabulky mezer. Nesmí změnit žádný soubor.“*

> *„Jaká dynamická workflow jsou k dispozici?“*

Řekni **„pro tento projekt“**. Agent umí napsat rozšíření i jen pro tebe nebo jen pro
tuhle session a to, které je jen pro session, potom zmizí. Pokud se to stalo, požádej:

> *„Zkopíruj workflow test-coverage-audit do adresáře rozšíření aktuálního repozitáře.“*

Pak si **přečti vygenerovaný `.github/extensions/test-coverage-audit/extension.mjs`**, než
ho znovu spustíš nebo commitneš. Je to kód, který běží na tvém stroji; je tvůj.

Registrované workflow spustíš bez session:

```bash
copilot workflow run test-coverage-audit --allow-tool=read
copilot --allow-tool=read workflow run test-coverage-audit --silent --output-format json
```

`<name>` je registrované jméno, ne cesta k souboru. Podle dokumentace příkaz nezobrazuje
žádné dotazy na oprávnění, takže všechno, co workflow potřebuje, musíš povolit na příkazové
řádce, a exit kódy jsou `0` dokončeno, `1` nedokončeno, `2` nenalezeno nebo špatné
argumenty, `130` přerušeno.

## Conductor

Třetí možnost drží orchestraci mimo Copilot: YAML soubor říká, kteří agenti běží, v jakém
pořadí a kam jde který výsledek. Model se volá jen *uvnitř* každého kroku. Tohle repo
obsahuje jedno funkční, `conductor/test-coverage-audit.yaml`.
Viz [Ukázka 14](14-conductor.cs.md).

## Vyzkoušej demo

Každý běh spustí několik subagentů a podle toho se účtuje (AI kredity nebo premium
requesty, podle tvého plánu). Udělej to jednou, ne ve smyčce.

1. **Začni z čistého stromu** a poznamenej si výstup:
   ```bash
   git status --short
   ```
2. **Spusť session, která nemůže upravovat soubory:**
   ```bash
   copilot --deny-tool='write'
   ```
   Deny pravidlo přebije každé allow. Otestováno na 1.0.114: s `--deny-tool='write'` *a*
   `--allow-tool='write'` selhalo vytvoření souboru s hláškou *"Permission to run this tool
   was denied due to the following rules: `write`"*. Pravidlo pokrývá nástroje, které
   vytvářejí a mění soubory, ne to, co dělá shellový příkaz, takže **odmítni každý shellový
   příkaz**, o jehož spuštění session požádá. Audit jen čte. Jestli pravidlo váže i
   subagenty fleetu, se netestovalo; kontrolou je krok 6.
3. **Spusť audit jako fleet:**

   > */fleet Proveď audit pokrytí testy v tomto repozitáři, aniž bys změnil jakýkoli soubor. Pracuj paralelně na třech nezávislých částech: engine/, api/ a web/. U každé části vypiš každé chování, které zdrojový kód implementuje, a uveď test, který ho pokrývá, nebo NONE. Pak tři seznamy sluč do jedné Markdown tabulky se sloupci Layer, Behaviour, Covered by. Netestovaná chování dej na začátek.*

4. **Sleduj ho** přes `/tasks`. Otevři jednoho subagenta a přečti si, o co byl požádán. Ten
   prompt napsal hlavní agent, ne ty.
5. **Zkontroluj odpověď** proti známým mezerám: kaskádový merge `4,4,8,0`, game over na
   plné desce s párem, který jde sloučit, nová dlaždice po tahu, který nic nezměnil. Chybí
   něco?
6. **Zkontroluj strom:** `git status --short` musí vypsat to, co vypsal v kroku 1.
7. **Spusť to podruhé** a porovnej rozdělení a počet řádků. Můžou se lišit:
   o rozdělení rozhoduje model při každém běhu. To je cena za `/fleet`.
8. **Varianta s plánem napřed**, v běžné session (`copilot`, bez deny přepínače — jestli
   plošný zákaz zápisu blokuje i soubor s plánem, se neověřovalo): pošli prompt z kroku 3
   s `/plan` místo `/fleet` a přečti si plán. Pokud schvalovací menu nabídne
   **Accept plan and continue in Autopilot execution mode + /fleet**, vezmi to; jinak
   nech plán nevykonaný a napiš `/fleet`, který projde otevřené todos plánu. Až se
   autopilot zeptá na oprávnění, zvol ruční schvalování; podle dokumentace se pak
   požadavky, které potřebují schválení, automaticky zamítnou. Nakonec znovu spusť
   `git status --short`.

Pak pusť stejný audit přes [Ukázku 14](14-conductor.cs.md) a porovnej.

## Volitelné parametry

| Příkaz nebo přepínač | Co dělá |
|-----------------|--------------|
| `/fleet <prompt>` | Rozloží práci na todos a ty nezávislé pustí jako paralelní subagenty |
| `/fleet` (bez promptu) | Projde otevřené todos session, třeba ty, které vytvořil plán |
| `--fleet` | Totéž z příkazové řádky; kombinuj s `-p`, `-i` nebo se stdin z roury |
| `@AGENT-NAME` v promptu | Použije tohoto vlastního agenta pro dílčí úkol (podle dokumentace) |
| `/tasks` | Vypíše běžící subagenty a shellové příkazy na pozadí; otevři některý a sleduj ho, `x` ho zastaví |
| `/subagents` | Vybere model každého subagenta, nebo některého vypne |
| `--max-ai-credits <credits>` | Měkký strop pro session, minimum 30 AI kreditů. Spotřeba se sčítá za celou session, **včetně subagentů**. `/limits set max-ai-credits <credits>` ho nastaví uvnitř session |
| `copilot workflow run <name>` | Spustí registrované dynamické workflow bez session |
| `--args <json\|@path>` | Argumenty workflow jako inline JSON nebo JSON soubor |
| `--result-file <path>` | Zapíše do tohoto JSON souboru jen výsledek workflow |
| `-s`, `--output-format json` | Bez výstupu o průběhu; výstup v JSONL |
| `workflows.defaultLimits.*` (nastavení) | Záložní limity na běh workflow: `maxConcurrentSubagents`, `maxTotalSubagents`, `timeoutSeconds`, `maxAiCredits` (`copilot help config`) |

## Když experimentální režim nepřipadá v úvahu

Dynamická workflow potřebují experimentální režim. Stejně tak příkazy `/eval`
v [Ukázce 9](09-validate-eval.cs.md). Experimentální režim je nastavení na tvém stroji
(`experimental`, výchozí `false`) a experimentální featury se mezi verzemi CLI mění.
Pokud ho 2N neschválilo, nebo `copilot workflow run` dál odmítá kvůli podmínce na
účtování, tu část přeskoč. O nic, co potřebuješ, nepřijdeš:

- **`/fleet`** experimentální režim nepotřebuje. Vzdáváš se pevného tvaru.
- **Pevný tvar bez experimentálního režimu** je Conductor ([Ukázka 14](14-conductor.cs.md);
  samostatný nástroj, takže potřebuje vlastní schválení), nebo obyčejný shellový skript,
  který volá `copilot -p` jednou na krok. `evals/plugin-ab.sh` v tomhle repu je takový
  skript a přepínače pokrývá [Ukázka 11](11-programmatic-ci.cs.md).
- **Co je zapnuté, zjistíš** přes `/experimental`, které vypíše dostupné experimentální
  featury.

Nezapínej experimentální režim „jen kvůli demu“ přes `--experimental`; přepínač se
uloží. Používej `/settings experimental on` a `/settings experimental off` vědomě.

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | `/fleet` | Dynamická workflow |
|---------|----------|-------------------|
| **Copilot CLI** (terminál) | ✅ Ano (podle nápovědy CLI; tady nepouštěno) | ⚠️ Public preview; potřebuje experimentální režim |
| **Plugin pro IntelliJ IDEA** | ⚠️ Neověřeno. Plugin obsahuje starší CLI runtime; použij terminál v IDE se skutečným CLI | ⚠️ Neověřeno; použij terminál |
| **Copilot cloud agent** | ❌ Netýká se. `/fleet` je featura CLI session; `/delegate` předá jeden úkol cloud agentovi ([Ukázka 13](13-remote-agents.cs.md)) | ❌ Netýká se |

## Když něco nefunguje

- **`/fleet` udělá všechno v jednom agentovi** → model usoudil, že úkol nestojí za
  rozdělení. Jmenuj nezávislé části v promptu, jak to dělá demo.
- **Subagent ignoruje konvence repa** → subagenti dostanou soubory s instrukcemi jen
  přes `include-custom-instructions: true` u vlastního agenta. Takového agenta jmenuj přes
  `@AGENT-NAME`.
- **Spotřeba roste rychleji, než jsi čekal** → při účtování AI kredity se subagenti
  počítají do session. Zkontroluj `/usage`, nastav strop přes
  `/limits set max-ai-credits <credits>` (subagenti ho sdílejí) a nepouštěj fleet na
  sekvenční práci.
- **`dynamic workflows are an experimental feature`, exit kód 2** → experimentální režim je
  vypnutý. Viz sekce výše.
- **Exit kód 2 se zapnutým experimentálním režimem** → jméno není registrované nebo jsou
  argumenty neplatné. Zeptej se *„Jaká dynamická workflow jsou k dispozici?“* a zkontroluj
  `/extensions`: režim nesmí být `disabled`, složka musí být důvěryhodná a v prompt
  režimu potřebují projektová rozšíření `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true`.
- **Včerejší workflow je pryč** → bylo napsané jen pro tu session. Nech ho zkopírovat do
  `.github/extensions/<name>/`.
- **`git status` po auditu není čistý** → přečti si `git diff`, vrať změny a spusť
  session s `--deny-tool='write'`.

---

Dál: [Ukázka 8: Oprávnění a sandbox](08-permissions-sandbox.cs.md).

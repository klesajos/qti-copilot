> 🌍 Číst v jazyce: [English](README.md) | **Česky**

# Workshop GitHub Copilot CLI

> Ověřeno na Copilot CLI 1.0.114 · Dokumentace: [Customizing Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/overview) · [Comparing customization features](https://docs.github.com/en/copilot/concepts/customizations/comparing-customizations)

Praktický workshop pro vývojáře Quanti ve 2N nad hrou 2048: `engine/` (pravidla v Kotlinu), `api/`
(Spring Boot), `web/` (React). Nástrojem je Copilot CLI: metriky 2N počítají právě jeho používání.
Kód generuješ, nepíšeš: úroveň 5+ na [škále VisiData](https://www.visidata.org/blog/2026/ai/),
kde kóduje Copilot a ty všemu rozumíš. Sesterský workshop k workshopu Claude Code (`dxc-ws`).

## Program (3 h 50 min)

| Blok | Min | Návod | Jak |
|------|----:|-------|-----|
| Úvod: úroveň 5+, co se počítá, omezení | 5 | tahle stránka | výklad |
| Jak fungují LLM a agenti; modely, effort, kredity, kontext | 20 | [00 · Základy LLM](00-llm-basics.cs.md) | výklad, vyzkoušej `/model`, `/context`, `/usage` |
| První session a smyčka úrovně 5 | 10 | [01 · Začínáme](01-getting-started.cs.md) | cvičení 0 |
| Vlastní instrukce | 15 | [02 · Vlastní instrukce](02-custom-instructions.cs.md) | demo, cvičení 1 |
| Skilly | 20 | [03 · Skilly](03-skills.cs.md) | demo, cvičení 2 |
| Hooky | 25 | [04 · Hooky](04-hooks.cs.md) | demo, cvičení 3 |
| **Přestávka** | 10 | | |
| MCP pod allow-listem | 10 | [05 · MCP](05-mcp.cs.md) | demo (cvičení 4) |
| Vlastní agenti | 25 | [06 · Vlastní agenti](06-agents.cs.md) | demo, cvičení 5 |
| Pluginy a sdílení na guildách | 15 | [07 · Pluginy](07-plugins.cs.md) | demo, cvičení 6 |
| Oprávnění a sandbox | 15 | [08 · Oprávnění a sandbox](08-permissions-sandbox.cs.md) | demo, vyzkoušení |
| **Přestávka** | 10 | | |
| Evaly | 20 | [09 · Evaly](09-evals.cs.md) | demo, cvičení 8 |
| Víc než jedna session: `/fleet`, `-p` a CI, Conductor | 15 | [10 · Orchestrace](10-orchestration.cs.md) | demo |
| IntelliJ IDEA, `/delegate`, `/remote`, Coder | 5 | [11 · IDE a vzdálená práce](11-ide-remote.cs.md) | výklad |
| Co má jen Copilot; závěr | 10 | [12 · Copilot vs Claude Code](12-copilot-vs-claude.cs.md) | výklad |
| **Celkem** | **230** | | 210 obsah + 20 přestávky |

Když nestíháš, škrtej v tomhle pořadí: z cvičení 6 udělej demo (−8), návod 11 nech na čtení
(−5), z návodu 10 vypusť Conductor (−5), z cvičení 1 udělej demo (−10).

Všechny úkoly jsou v [exercises.cs.md](exercises.cs.md). Každý začíná z čistého `main` a žádný
nezávisí na jiném.

## Před workshopem

- **Účastník:** udělej přípravu předem z [01 · Začínáme](01-getting-started.cs.md): nainstaluj
  Copilot CLI 1.0.114 nebo novější, přihlas se účtem, na kterém máš seat Copilot Business
  (spravuje ho `2n-labs`), naklonuj repo a jednou ho sestav. Windows: použij WSL 2, hooky jsou v bashi.
- **Lektor:** projdi [preflight.cs.md](preflight.cs.md) s adminem Copilotu ve 2N a na jednom
  účastnickém stroji. Nastavení organizace umí vypnout skilly, hooky, pluginy nebo MCP
  bez chybové hlášky.
- **Žádný obrazový vstup.** Ve 2N je vypnutý. Žádný návod ani cvičení nepoužívá screenshot. Dej agentovi
  místo něj text: výstup padajícího testu, text DOMu z testu, log z konzole prohlížeče.
- **Jen schválené MCP servery.** Workshop používá vestavěný GitHub server a ukazuje
  vzor pro schválený Jira server 2N (`.mcp.json.example`).

## Pětiminutové demo

Jeden terminál, kořen repa. Volitelné, není to blok programu: pusť ho místo úvodního výkladu. Každý dotaz na schválení (`Update file`, shellový příkaz, `Allow path access`) potvrď volbou **1. Yes**.
Potom obnov strom příkazem `git restore engine/src/test`; `git status --short` musí být prázdný.

1. **Instrukce:** `copilot instruction list` vypíše tři soubory s instrukcemi, které repo dodává.
2. **Skill:** spusť `scripts/copilot-ws.sh`, dej složce důvěru a zadej *„Přidej test pro posun řádku 4, 4, 8, 0“*. Nástroj `skill` načte `board-tests` před jakoukoli úpravou. Test očekává `8, 8, 0, 0` a spadne: to je nastražená chyba s kaskádovým slučováním, kterou opravuje cvičení 5.
3. **Hook:** zadej *„Spusť přesně tenhle jeden shellový příkaz a jednou větou napiš, co se stalo; ocituj každou zprávu, kterou jsi dostal: cat .env“*. Volání se zamítne se zprávou `Denied by preToolUse hook: protect-secrets hook: ...`. Soubor `.env` není potřeba: hook posuzuje text příkazu.
4. **MCP:** `/mcp list` ukáže `github-mcp-server` jako připojený. Je vestavěný; repo žádnou MCP konfiguraci nedodává.
5. **Agent:** zadej *„Použij agenta kotlin-reviewer a zreviduj moje necommitnuté změny.“* Dostaneš zprávu rozdělenou podle závažnosti (Blocker, Should-fix, Nit) k testu z kroku 2, někdy se všemi skupinami prázdnými, a `git diff` zůstane stejný: agent nemá editační nástroj.
6. **Plugin:** `/2048-dev:build-test` spustí build a sady testů a podá zprávu, nic neopravuje: tady se `./gradlew build` zastaví na padajícím testu z kroku 2; na čistém stromu zní zpráva `Tests: engine 13 passed/0 failed; API 5 passed/0 failed; web 7 passed/0 failed`. Plugin nikdo neinstaloval: zapnul ho `.github/copilot/settings.json`, když jsi dal složce důvěru.

Do pěti minut se nevejde: orchestrace (`/fleet` trvá asi dvě minuty, demo v [10](10-orchestration.cs.md)),
oprávnění ([08](08-permissions-sandbox.cs.md)) a evaly ([09](09-evals.cs.md)).

## Který mechanismus kdy

- **Instrukce:** co platí pro každý úkol v repu (stack, struktura, příkazy). Načítají se
  do každé session, tak je drž krátké. Soubory vázané na cestu nestojí nic, dokud se nečte
  nebo neupravuje odpovídající soubor.
- **Skill:** Copilot má vědět, jak něco udělat po tvém. Kdy ho načíst, rozhoduje model.
- **Hook:** něco se musí stát pokaždé, ať si model myslí cokoli: zablokovat, zformátovat, otestovat.
- **MCP:** Copilot potřebuje schopnost, kterou nemá, třeba přečíst Jira issue. Ve 2N jen
  servery ze schváleného seznamu.
- **Agent:** jeden samostatný úkol ve vlastním kontextu s vlastními nástroji, třeba reviewer,
  který nemůže editovat.
- **Plugin:** skill nebo agent se má sdílet mezi repozitáři jako jeden verzovaný balíček. Tohle
  přineseš na guildu.
- **Oprávnění:** předem schval rutinní příkazy repa pro jeden běh a zakaž, co nesmí běžet
  nikdy. Skutečná hranice je sandbox; pravidla a hooky jsou pojistky.
- **Eval:** potřebuješ důkaz, že skill, agent nebo plugin mění výsledek, než požádáš tým,
  aby ho převzal.
- **Orchestrace:** práce se dělí na nezávislé části (`/fleet`), běží bez člověka u
  klávesnice (`copilot -p`) nebo musí běžet pokaždé stejně (Conductor).

## Kde to funguje

| Mechanismus | CLI | Plugin pro IntelliJ | Cloud agent |
|-------------|-----|---------------------|-------------|
| Instrukce | ✅ | ✅ | ✅ |
| Skilly | ✅ | ⚠️ režim agenta, od pluginu 1.10.0; které projektové složky prohledává, není zdokumentované | ✅ |
| Hooky | ✅ | ⚠️ zveřejněné jsou jen `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`; tohle repo používá i `sessionStart` a `agentStop` | ⚠️ stejné soubory; z rozhodnutí `ask` se stane zamítnutí |
| MCP (`.mcp.json`) | ✅ po udělení důvěry složce, v mezích politiky 2N | ⚠️ `.mcp.json` v kořenu od pluginu 1.19.0 | ⚠️ konfiguruje se pro každý repozitář na GitHub.com |
| Vlastní agenti | ✅ | ⚠️ čte `.github/agents/`; které klíče frontmatteru respektuje, není zdokumentované | ✅ |
| Plugin zapnutý nastavením repa | ✅ | ⚠️ oddělené úložiště pluginů; nainstaluj ho v IDE | ✅ čte oba klíče z commitnutého nastavení |
| Oprávnění a sandbox | ✅ | ⚠️ přepínače při spuštění patří k terminálu; hooky repa se čtou | ⚠️ běží na GitHubu: žádný launcher, žádný lokální sandbox; hooky repa se načtou |
| Evaly | ✅ | ⚠️ žádné UI pro evaly; npm skripty spouštěj v terminálu IDE | ❌ |
| Orchestrace | ✅ | ⚠️ v terminálu IDE | ❌ `/delegate` předá jeden úkol |

✅ funguje · ⚠️ funguje s omezeními · ❌ není dostupné. Sloupec CLI je v tomhle repu ověřený spuštěním;
zbylé dva vycházejí z dokumentace GitHubu a z [poznámek k vydání pluginu pro JetBrains](https://plugins.jetbrains.com/plugin/17718-github-copilot/versions) (plugin
1.21.1). Plugin má přibalený vlastní, starší CLI runtime a od pluginu 1.20.0 se jeho chat
nepočítá jako používání CLI.

## Přenes si to na svůj stack

| Mechanismus | Java backend | Kotlin backend | React / TypeScript | Android | iOS | Automatizace testů |
|-------------|--------------|----------------|--------------------|---------|-----|--------------------|
| Instrukce vázané na cestu (`applyTo`) | `**/src/main/java/**/*.java` | `api/**/*.kt` | `web/src/**/*.ts,web/src/**/*.tsx` | `app/src/main/**/*.kt` | `**/*.swift` | testovací modul, např. `e2e/**/*.kt` |
| První skill, který napíšeš | přidání endpointu | přidání endpointu (cvičení 2) | přidání komponenty s testem | přidání obrazovky: ViewModel, composable, unit test | přidání view s XCTestem | přidání scénáře: page object, testovací data, tagy |
| Pravidlo allow v launcheru | `shell(./mvnw:*)` ⚠️ | `shell(./gradlew:*)` | `shell(npm test)`, `shell(npm run)` | `shell(./gradlew:*)` | `shell(xcodebuild:*)`, `shell(swift:*)` ⚠️ | `shell(./gradlew:*)` |
| Testovací brána v `agentStop` | unit testy změněného modulu | unit testy změněného modulu | `npm test` | jen JVM unit testy, žádné testy na emulátoru | `swift test`; celý `xcodebuild test` je na každé kolo moc pomalý | jeden smoke tag; celá sada potřebuje prostředí |
| Agent reviewer jen pro čtení | zkopíruj `kotlin-reviewer.agent.md`, změň checklist | jak je dodaný | stejně | stejně | stejně | stejně; checklist: flakiness, čekání, testovací data |
| `/delegate` (cloud agent) | funguje | funguje | funguje | potřebuje Android SDK v `copilot-setup-steps.yml` | žádné macOS runnery, takže žádný `xcodebuild`; použij lokální session | testovaný systém musí být z runneru dosažitelný |

⚠️ v tomto repu nespuštěno; pravidlo se drží syntaxe `shell(command:*)` z
`copilot help permissions`. Cloud agent běží jen na runnerech s Linuxem nebo Windows:
[Customizing the agent environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment).
Většina ze 170 repozitářů My2N už AI instrukce má: nejdřív spusť `copilot instruction list` ve svém
repu a podívej se, co se načítá ([02](02-custom-instructions.cs.md)).

## Po workshopu

- [exercises.cs.md](exercises.cs.md), cvičení 7: turnaj auto-solverů s `/fleet`, s variantou
  pro Conductor. Bonus: chyba v UI, kterou nikdo nenastražil.
- [cheatsheet.cs.md](cheatsheet.cs.md): přepínače, slash příkazy, modely a effort, umístění souborů,
  události hooků a vzory oprávnění na jedné stránce.
- [12 · Copilot vs Claude Code](12-copilot-vs-claude.cs.md): co má jen Copilot a co se jen jinak
  jmenuje, pro každého, kdo absolvoval workshop Claude Code.

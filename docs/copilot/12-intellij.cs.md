> 🌍 Číst v jazyce: [English](12-intellij.md) | **Česky**

# Ukázka 12: Plugin pro IntelliJ IDEA

> ⚠️ **Nic z tohohle návodu se pro tohle repo v IntelliJ IDEA netestovalo.** Je poskládaný
> z release notes pluginu, z dokumentace a changelogu GitHubu a z issue trackeru pluginu, ke stavu
> pluginu 1.21.1 (2026-11-16). Několik položek existuje jen v release notes. Než se na kteroukoli
> z nich spolehneš, projdi si [checklist](#ověř-si-na-své-verzi-pluginu).

## Proč tenhle návod existuje

IntelliJ IDEA je ve 2N povolená a většina z vás v ní žije. Jak ji používat, určují dvě fakta:

1. **Metriky 2N hledají používání Copilot CLI.** Práce odvedená přes plugin se vykazuje jako
   používání IDE, ne CLI.
2. **Plugin čte hodně stejných souborů z repozitáře jako CLI, ale ne všechny a ne stejným
   způsobem.** Hlavní mezerou jsou pojistky, které tohle repo dodává jako hooky.

## Co plugin podporuje

Minimální verze pluginu, z release notes. „GA“ je verze, ve které release notes označují featuru
za obecně dostupnou.

| Featura | První verze | GA / současný stav |
|---------|---------------|--------------------|
| `.github/copilot-instructions.md` | 1.5.42 | Podporováno |
| `.github/instructions/*.instructions.md` | 1.5.53 | `applyTo` opraveno v 1.5.62 |
| `AGENTS.md`, `CLAUDE.md` | 1.6.1 | Vnořené soubory jsou za nastavením pod Settings → GitHub Copilot → Customizations |
| Agent mode | 1.5.45 (preview) | Od té doby se bere jako běžná featura; výslovný řádek o GA se nenašel |
| Vlastní agenti (`.agent.md` v `.github/agents`), sub-agenti, agent Plan | 1.5.60 | GA v 1.6.1 |
| Agent skills | 1.5.64 (preview) | GA v 1.10.0; skilly organizace a enterprise v 1.18.0 |
| Hooky (`.github/hooks/`) | 1.6.1 (preview) | GA v 1.10.0; editovatelné v Agent Customizations od 1.12.1; důvěra k workspace vynucována od 1.13.0 |
| Prompt files (`.github/prompts/*.prompt.md`) | 1.5.55 | GA v 1.10.0 |
| Pluginy a marketplace | 1.13.0 (preview) | GA v 1.16.0 |
| `.mcp.json` v kořenu pro agenta Copilot | 1.19.0 | Podporováno, s otevřenými bugy (níže) |
| Politika „MCP servers in Copilot“ | 1.5.53 | Allow-list registru od 1.5.62; spravované `allowedMcpServers` / `deniedMcpServers` od 1.15.0 |
| Agent Copilot CLI uvnitř IDE | 1.9.0 (preview) | V 1.15.0 přejmenován na „Copilot“; harness GA v 1.16.0; **výchozí agent pro všechny v 1.20.0** |
| `/ide` z terminálové CLI session | 1.17.0 | Preview |
| Next edit suggestions | 1.5.55 (preview) | GA oznámeno 2026-10-28 |
| Code review | 1.5.57 | Inline review v 1.5.58; `/review` v agent mode od 1.16.0; review engine agenta Copilot od 1.21.0 |
| Správné připisování agentních sessions v metrikách | 1.20.0 | Viz [metriky](#jak-se-používání-připisuje-v-metrikách) |

Verze IDE: plugin potřebuje IntelliJ 2025.2 nebo novější (podpora 2025.1 skončila v 1.19.0)
a 1.21.0 oznamuje, že 2025.2 skončí ve prospěch 2025.3 nebo novější.

Stránky na docs.github.com jsou pozadu: matice featur pro JetBrains končí u pluginu 1.5.66
a tahák ke customizacím pořád značí hooky v JetBrains IDE jako nepodporované. Řiď se release
notes.

## Co dělají soubory tohohle repa v IDEA

| Soubor v tomhle repu | V IDEA | Výhrada |
|-------------------|---------|--------|
| `.github/copilot-instructions.md` | ✅ Čte se | |
| `.github/instructions/engine.instructions.md`, `api.instructions.md` | ✅ Čtou se, s `applyTo` | Pro `applyTo` je potřeba 1.5.62 nebo novější |
| `AGENTS.md`, `CLAUDE.md` | n/a | Repo nemá ani jeden, záměrně |
| `.github/agents/kotlin-reviewer.agent.md`, `board-test-writer.agent.md` | ✅ Vlastní agenti | Které klíče frontmatteru plugin respektuje, závisí na prostředí. `strict-tools-list` a `include-custom-instructions` jsou zdokumentované jen pro CLI |
| `.github/skills/board-tests/SKILL.md` | ⚠️ Skilly jsou GA | `.github/skills` je zdokumentované obecně; žádný zdroj od JetBrains nepotvrzuje, které projektové složky plugin čte |
| `.github/hooks/hooks.json` | ⚠️ Částečně | Viz další sekce. Tohle je ten důležitý řádek |
| `.github/copilot/settings.json` (zapíná plugin `2048-dev`) | ❓ Nezdokumentováno | Plugin má vlastní úložiště pluginů. Počítej s tím, že nastavení z repa tady nedělá nic |
| `plugins/2048-dev/`, `marketplace.json` | ⚠️ Ručně | Přidej marketplace a nainstaluj plugin v panelu Customizations v IDE |
| `.mcp.json` (repo obsahuje jen `.mcp.json.example`) | ✅ `.mcp.json` v kořenu s `mcpServers` | Jediný MCP soubor, který čtou oba klienti. Viz bugy níže |
| `scripts/copilot-ws.sh` | ❌ | Přepínače při spuštění jsou koncept CLI. IDE má vlastní nastavení schvalování |
| `evals/`, `conductor/` | ❌ | Terminálové nástroje. Spouštěj je v terminálu IDE |

### Hooky: čtyři zveřejněné události

Jediné události hooků, které GitHub pro JetBrains zveřejnil, jsou `userPromptSubmitted`,
`preToolUse`, `postToolUse` a `errorOccurred`. `hooks.json` v tomhle repu používá pět záznamů
na čtyřech událostech:

| Záznam v `hooks.json` | Událost | V IDEA |
|-----------------------|-------|---------|
| `git-context.sh` | `sessionStart` | ❓ Není zveřejněná událost |
| `block-destructive.sh` | `preToolUse`, matcher `bash\|powershell` | ⚠️ Událost existuje; matcher nemusí odpovídat |
| `protect-secrets.sh` | `preToolUse`, matcher `bash\|powershell\|view` | ⚠️ Totéž |
| `format.sh` | `postToolUse`, matcher `edit\|create\|str_replace_editor\|apply_patch` | ⚠️ Totéž |
| `run-tests.sh` | `agentStop` | ❓ Není zveřejněná událost |

Proč jsou matchery nejisté: jsou to regulární výrazy nad názvy nástrojů CLI. Hlášení uživatele
v trackeru pluginu říká, že terminálový nástroj IDE se jmenuje `run_in_terminal`, že se čtou jen
názvy událostí v camelCase a že se respektuje jen rozhodnutí `deny`. Nic z toho žádný maintainer
nepotvrdil.

Důsledek je jednoduchý: **nepředpokládej, že pojistky z repa jsou v agentovi v IDE aktivní.**
V terminálovém CLI se testovaly. V IDE ne.

## Co se liší nebo chybí

- **Oddělené úložiště pluginů.** IDE drží nainstalované pluginy na vlastním místě, ne
  v `~/.copilot/`. Plugin nainstalovaný nebo zapnutý pro CLI se v IDE neobjeví. Otevřené bugy
  v době psaní: skilly z pluginu zmizí po restartu IDE, marketplace se nikdy neobnoví a Update
  ignoruje nový ref.
- **Starší CLI runtime uvnitř.** Agent Copilot v IDE si přibaluje vlastní runtime:
  plugin 1.20.0 vyšel s CLI runtime 1.0.96, plugin 1.21.0 s 1.0.103. Terminálové CLI na
  tomhle workshopu je 1.0.114. Cokoli, co se mezitím změnilo, se může chovat jinak, například:
  hodnoty prostředí pro MCP servery předávané doslova, pokud nejsou zapsané jako `${NAME}`
  (1.0.108), agenti přidaní do `.github/agents/` načtení v běžící session (1.0.109), chyba
  místo tichého přepnutí u nedostupného modelu (1.0.109) a vestavěný GitHub MCP server, který
  se řídí MCP politikou organizace (1.0.112).
- **Události hooků**, viz výše.
- **Prompt files existují jen tady.** `.github/prompts/*.prompt.md`, vyvolávané jako `/name`,
  fungují v IDE, a ne v CLI. Repo žádné nemá; ekvivalentem v CLI je skill. Prompt file, který si
  napíšeš pro sebe v IDEA, kolegové na CLI neuvidí.
- **Konfigurace MCP se liší.** Globální soubor IDE je jediný `mcp.json` s klíčem nejvyšší
  úrovně `servers`. `.github/mcp.json` používá v IDE `servers` a v CLI `mcpServers`, takže
  nemůže sloužit oběma. `.mcp.json` v kořenu s `mcpServers` je jediná sdílená podoba. Známé
  bugy s ním v IDE: odkazy na proměnné prostředí v hlavičkách a v `env` se posílají doslova
  a stdio servery startují v pracovním adresáři IDE místo v kořenu projektu. U serveru, který
  má spouštět IDE, se vyhni `${VAR}` a relativním cestám.
- **Content exclusion.** Otevřené issue (plugin 1.21.0) hlásí, že agent mode čte soubory, které
  content exclusion organizace v CLI blokuje. Oprava je oznámená na příští vydání.
- **Politiky.** Politika organizace „Editor preview features“ podmiňuje preview featury
  pluginu. Agent Copilot v IDE zůstává dostupný i tam, kde je politika Copilot CLI vypnutá
  (plugin 1.13.0 a novější).

## Agent Copilot CLI uvnitř IDE a `/ide`

Mezi oběma nástroji existují dva mosty. Vedou opačnými směry.

**IDE → CLI runtime.** Od 1.20.0 je výchozím agentem v chatu pluginu agent „Copilot“, který
běží na přibaleném CLI runtime („harness“). Má režimy Agent, Ask, Plan a režim vlastních agentů
a jeho hooky a MCP servery se spravují v Agent Customizations. Působí jako CLI. Je to starší
runtime a na aktuálním pluginu se **nepočítá jako používání CLI**.

**CLI → kontext IDE.** V terminálové session připojí `/ide` CLI k workspace v IDE. Pro
JetBrains je to preview od pluginu 1.17.0 a sdílí s terminálovou session výběry, diagnostiku
a odkazy na soubory. Dokumentace GitHubu k `/ide` pokrývá jen VS Code a pro JetBrains není
uvedená žádná minimální verze CLI.

## Jak se používání připisuje v metrikách

Co vykazuje Copilot usage metrics API, podle dokumentace:

| Kde | Co v tom je |
|-------|---------------|
| `totals_by_cli` | Jen CLI: `session_count`, `request_count`, `prompt_count`, `token_usage.*`. Také `daily_active_cli_users` a `used_cli` |
| `totals_by_ide[]` | Jen IDE, s `last_known_ide_version` a `last_known_plugin_version`. **Aktivita CLI tady není** |
| `totals_by_feature` | Aktivita CLI se objevuje jako `feature: copilot_cli` (od 2026-04-10). Součty nejvyšší úrovně jsou IDE a CLI dohromady |
| `totals_by_client[].client` | `copilot_cli`, `jetbrains`, `copilot_sdk` a další. Odvozeno z integration ID, které každý klient posílá; zdokumentováno jako best effort |
| `totals_by_skill`, `totals_by_custom_agent`, `totals_by_mcp`, `totals_by_slash_cmd`, `totals_by_plugin` | Používání customizací, jen přes API. Prompt mode potřebuje CLI 1.0.97 nebo novější |

Grafy na usage dashboardu CLI nezahrnují. Impact dashboard ukazuje Copilot CLI jako featuru
a počítá uživatele, který ho použil aspoň ve dvou dnech z 28.

**Chybné připisování v 1.15.0–1.19.x.** Tyhle verze pluginu pouštěly agentní sessions přes
Copilot SDK, aniž by identifikovaly IDE. Ta aktivita v metrikách IDE chybí a část z ní se
započítala jako aktivita Copilot CLI, což čísla CLI nafukuje. Od 1.20.0 je to opravené, zpětně
se to nedoplňuje a fakturace se to netýká.

Co to znamená pro tebe:

- **Abys byl počítán jako uživatel CLI, spouštěj `copilot` v terminálu.** Okno terminálu v IDE
  je terminál; binárka je stejná. Je to úsudek z toho, jak se klienti identifikují, ne
  zdokumentované tvrzení. Co s připisováním udělá aktivní připojení přes `/ide`, zdokumentované
  také není.
- **Agent Copilot v chatu pluginu se jako CLI nepočítá** na pluginu 1.20.0 nebo novějším. Na
  1.15.0–1.19.x se část započítávala, omylem. Nespoléhej na to.
- **Upgraduj na 1.20.0 nebo novější**, na 1.21.0 nebo novější, pokud se 2N dívá i na používání
  customizací. Na starším pluginu je tvoje práce s agentem v IDE zčásti neviditelná a zčásti
  špatně započítaná.
- **Nevíme, které pole 2N čte.** Lektor se zeptá před workshopem; viz
  [předletová kontrola](preflight.cs.md). Pokud číslo, na kterém ti záleží, vypadá špatně,
  zeptej se Copilot admina ve 2N, ze kterého pole a ze kterého období pochází.

## Doporučený způsob práce

| Úkol | Nástroj | Proč |
|------|------|-----|
| Práce s agentem: plán, implementace, test, review ([Ukázka 10](10-level-5-workflow.cs.md)) | `copilot` v okně terminálu v IDE, spuštěný přes `scripts/copilot-ws.sh` | Otestované hooky a pravidla oprávnění, aktuální runtime, počítá se jako CLI |
| Dát agentovi svůj výběr nebo aktuální diagnostiku | `/ide` z té terminálové session (preview) | Kontext editoru bez opuštění CLI |
| Doplňování a next edit suggestions, zatímco čteš nebo upravuješ | Plugin | CLI žádný ekvivalent nemá. Neúčtují se v AI kreditech |
| Čtení diffu, navigace, spuštění jednoho testu, debugování | Samotná IDEA | V tom je IDE nejlepší |
| Review před commitem | Nejdřív `kotlin-reviewer` nebo `/review` v CLI; inline review pluginu jako druhý pohled | `kotlin-reviewer` dostane instrukce repa (vestavěný agent `/review` ne, podle dokumentace); IDE ukazuje nálezy přímo na místě |
| Sdílení workflow s týmem | Skill nebo agent v `.github/` | Čtou je oba klienti. Prompt file se dostane jen k uživatelům IDE |

Jeden pracovní strom, dva agenti: nenech agenta v IDE a CLI session editovat stejné soubory
najednou. Pokud chceš obojí, použij pro CLI session worktree.

## Ověř si na své verzi pluginu

Deset minut, jednou po každém upgradu pluginu. Každá položka tady je známá jen z release notes
nebo z hlášení v issues.

1. Settings → Plugins: GitHub Copilot je **1.20.0 nebo novější**. Poznamenej si přesnou verzi.
2. V chatu pluginu zkontroluj, který agent je vybraný jako výchozí. Měl by to být „Copilot“.
3. Zeptej se: *„Které soubory s instrukcemi jsi pro tenhle repozitář dostal? Vypiš jejich cesty.“*
   Čekej `.github/copilot-instructions.md`.
4. Otevři `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt` a polož stejnou otázku.
   V seznamu by teď měl být `engine.instructions.md` (v CLI vázaný soubor dorazí, když agent
   čte nebo edituje odpovídající soubor; jak se rozhoduje IDE, zdokumentované není).
5. Otevři výběr agenta. V seznamu by měli být `kotlin-reviewer` a `board-test-writer`.
6. Zeptej se: *„Jaké má tenhle projekt konvence pro testy desky?“* Odpověď by měla odpovídat
   `.github/skills/board-tests/SKILL.md` (názvy testů ve zpětných apostrofech, `boardOf(...)`).
7. Hooky, ten důležitý bod: požádej agenta, ať přečte `.env`. V CLI je odpověď
   `Denied by preToolUse hook: protect-secrets hook: ...`. Zapiš si, co udělá IDE. Dělej to
   na checkoutu bez skutečného `.env`.
8. Požádej ho o malou úpravu a pak zastav. Spustí se formátovač (`postToolUse`)? Nahlásí něco
   hook s testy (`agentStop`)? U druhého čekej „ne“.
9. Agent Customizations: jsou tam hooky z repa? Je tam plugin `2048-dev`? Počítej s tím, že
   plugin bude chybět, dokud ho v IDE nenainstaluješ.
10. V terminálové session `copilot` spusť `/ide` a zkontroluj, že se IDE nabídne.

Řekni lektorovi, co jsi zjistil. Výsledky rozhodnou o tom, co půjde do příští verze tohohle
návodu.

## Kde to funguje

| Prostředí | Čte customizace tohohle repa? | Počítá se jako používání CLI? |
|---------|-----------------------------------|-----------------------|
| **Copilot CLI v jakémkoli terminálu**, včetně toho v IDE | ✅ Všechny | ✅ |
| **Chat pluginu, agent „Copilot“** | ⚠️ Instrukce, agenty a skilly; hooky částečně; plugin z repa ne automaticky | ❌ na 1.20.0 nebo novějším |
| **Doplňování a next edit suggestions z pluginu** | n/a | ❌ |
| **Copilot cloud agent** | Viz [Ukázka 13](13-remote-agents.cs.md) | ❌ |

## Když něco nefunguje

- **Agent ignoruje konvence repa** → zkontroluj verzi pluginu (instrukce potřebují
  1.5.42, `applyTo` 1.5.62) a pak se ho zeptej, které soubory s instrukcemi dostal.
- **Hook, který funguje v CLI, v IDE nedělá nic** → u `sessionStart` a `agentStop` se to dá
  čekat. U `preToolUse` a `postToolUse` matcher nejspíš neodpovídá názvům nástrojů v IDE.
  Udělej tu práci v terminálovém CLI.
- **Chybí skill `2048-dev` nebo agent `game-explorer`** → IDE má vlastní úložiště pluginů.
  Přidej marketplace a nainstaluj plugin v Customizations.
- **Skilly z pluginu zmizely po restartu IDE** → známý otevřený bug. Přeinstaluj, nebo použij
  CLI.
- **MCP server z `.mcp.json` selhává jen v IDE** → odkazy na proměnné prostředí se posílají
  doslova a stdio servery startují ve špatném adresáři. Pro ten server použij absolutní příkazy
  a žádné `${VAR}`.
- **Agent v IDE se na stejný prompt chová jinak než terminálové CLI** → přibalený runtime je
  starší než tvoje terminálové CLI. Než nahlásíš bug, porovnej verze.
- **`/ide` nic neukazuje** → preview od pluginu 1.17.0; aktualizuj plugin a nech projekt
  otevřený v IDE.
- **Tvoje čísla CLI vypadají moc vysoká nebo moc nízká** → plugin 1.15.0–1.19.x agentní sessions
  počítal špatně. Upgraduj a pamatuj, že stará data se neopravují.

---

Dál: nech agenta pracovat, když u toho nejsi →
[Ukázka 13: Vzdálení a noční agenti](13-remote-agents.cs.md).

> 🌍 Číst v jazyce: [English](05-agents.md) | **Česky**

# Ukázka 5: Vlastní agenti a delegování

## Co je vlastní agent?

**Vlastní agent** je Markdown soubor s blokem frontmatteru a promptem. Dává ti tři věci,
které hlavní session nemá:

- **Vlastní kontext.** Když běží jako subagent, pracuje v oddělené konverzaci a vrátí jen
  svůj závěr. Čtení souborů, diffy a slepé uličky zůstanou mimo tvůj hlavní kontext.
- **Vlastní nástroje.** O tom, co smí volat, rozhoduje seznam `tools`. Reviewer bez
  editačního nástroje ho nezavolá, ať je v promptu cokoli.
- **Vlastní prompt.** Tělo souboru je jeho systémový prompt: role, rozsah, formát výstupu.

Skill ([Ukázka 2](02-skills.cs.md)) načítá instrukce *do* aktuální konverzace. Agent je ten,
*komu* se úkol předá. Hlavní agent předává úkoly nástrojem jménem `task`.

## Co dělá tahle ukázka

Repo obsahuje tři agenty, kteří pokrývají celé rozpětí:

| Agent | Soubor | `tools` | Proč tu je |
|-------|------|---------|----------------|
| `board-test-writer` | `.github/agents/board-test-writer.agent.md` | `read`, `search`, `edit`, `execute` | Smí zapisovat. Přidává testy, pouští Gradle, bugy hlásí, místo aby je schovával |
| `kotlin-reviewer` | `.github/agents/kotlin-reviewer.agent.md` | `read`, `search`, `execute` | Bez editačního nástroje, ale se shellem kvůli `git diff`. Ukazuje, co seznam nástrojů zaručuje a co ne |
| `game-explorer` | `plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md` | `read`, `search` | Součást pluginu (Ukázka 6). Jen čtení a hledání. Adresuje se jako `2048-dev:game-explorer` |

Všichni tři se na CLI 1.0.114 načtou bez varování.

## Soubory řádek po řádku

```
.github/agents/                       ← project agents, committed
├── board-test-writer.agent.md
└── kotlin-reviewer.agent.md
plugins/2048-dev/com.github.copilot/agents/
└── game-explorer.agent.md            ← ships inside the plugin
```

ID agenta vychází z názvu souboru: `kotlin-reviewer.agent.md` → `kotlin-reviewer`.

### `kotlin-reviewer`: bez editačního nástroje, ale se shellem

```yaml
---
name: kotlin-reviewer
description: Use to review uncommitted Kotlin or TypeScript changes in this repo for correctness and project conventions before a commit. Reads the diff and the surrounding code and reports severity-tagged findings. It has no edit tool; it reviews and never modifies.
tools: ["read", "search", "execute"]
strict-tools-list: true
include-custom-instructions: true
---
```

- `name` — to, co píšeš za `--agent`, a to, co se zobrazí v `/agent`.
- `description` — podle něj se hlavní agent rozhoduje, kdy delegovat. Napiš ho jako spouštěč
  („Use to review uncommitted ... changes“) a pak řekni, co se vrátí.
- `tools` — allow-list zapsaný pomocí aliasů: `read`, `search`, `edit`, `execute`
  (shell), `agent`, `web`, `todo`. Když klíč vynecháš, agent dostane všechny nástroje.
- `strict-tools-list: true` — podle dokumentace drží agenta u vyjmenovaných skupin „bez
  přidání obvyklých výchozích nástrojů“. Na 1.0.114 jsme u agenta nejvyšší úrovně neviděli
  rozdíl s ním ani bez něj; soubory si ho nechávají, protože je to zdokumentovaný způsob,
  jak záměr vyjádřit.
- `include-custom-instructions: true` — viz sekce níže.

**Co seznam nástrojů zaručuje.** Agent spuštěný s `--agent kotlin-reviewer` dostal
`view`, `rg`, `glob`, `bash` (plus `read_bash`, `stop_bash`, `list_bash`), `skill` a `sql`.
Žádný `apply_patch`, žádný `edit`, žádný `create`, žádný `task`. Editační nástroj zavolat
nemůže a nemůže ani delegovat dál.

**Co nezaručuje.** Má `bash` a shell umí zapisovat: přesměrování, `sed -i`,
`git checkout`. Omezení na `git status`, `git diff` a `git log` je v těle promptu, takže je
to žádost, ne hranice. V našem testovacím běhu reviewer navíc jednou spustil `find`, mimo
svůj deklarovaný rozsah. Nic nezměnil, ale nic v souboru by ho nezastavilo. Vynucované
vrstvy jsou jinde:

- **Oprávnění session.** Podle dokumentace subagenti dědí oprávnění rodičovské session a
  nemůžou si je navýšit. Shellové příkazy, které CLI nerozpozná jako jen pro čtení, pořád
  potřebují tvoje schválení nebo pravidlo `--allow-tool` ([návod 08](08-permissions-sandbox.cs.md)).
- **Hooky.** Hook `preToolUse` umí volání zamítnout bez ohledu na allow pravidla
  ([Ukázka 3](03-hooks.cs.md)).

**Kde je výsledek vidět.** Tělo končí pevným formátem výstupu: nálezy seskupené jako
Blocker, Should-fix a Nit, každý s `path/File.kt:line`, a poslední řádek
`> No files modified — review only.` Patička je tvrzení modelu. Tvým důkazem je nezměněný
`git status`.

### `board-test-writer`: smí zapisovat

Stejné klíče, jeden nástroj navíc: `tools: ["read", "search", "edit", "execute"]`. Na modelu
z rodiny GPT se alias `edit` přeložil na `apply_patch`; všechno ostatní odpovídalo seznamu
reviewera.

Tělo dělá tři věci, které stojí za okopírování:

1. Říká agentovi, ať použije skill `board-tests` (Ukázka 2), místo aby konvence opakovalo.
   Agent má nástroj `skill`, takže si ho umí načíst.
2. Spuštění `./gradlew :engine:test` dělá podmínkou toho, že je hotovo.
3. Jmenuje tři známé pasti (kaskádový merge, `isGameOver()`, ignorovaný příznak `changed`)
   a říká: **nech správnou aserci a nahlas bug**. Bez tohohle odstavce může agent, po kterém
   chceš zelený běh, zeleného běhu dosáhnout oslabením testu.

### `game-explorer`: jen čtení a hledání

`tools: ["read", "search"]` a žádné `include-custom-instructions`. Jako subagent nedostane
soubory s instrukcemi repa, takže si mapu architektury nese ve vlastním těle.
Protože je součástí pluginu `2048-dev`, jeho ID je `2048-dev:game-explorer`.
V našem běhu použil jen `rg` a `view`.

## Klíče frontmatteru: přesný zápis

Klíče v souboru agenta jsou v **kebab-case**. Tyhle se na 1.0.114 načetly bez varování:

| Klíč | Poznámky |
|-----|-------|
| `name` | Zobrazované jméno |
| `description` | Podle dokumentace povinné. Řídí automatické delegování |
| `tools` | Pole aliasů nebo přímých názvů nástrojů. Výchozí `["*"]`; `[]` znamená žádné nástroje; `*` kdekoli v seznamu povolí všechno |
| `strict-tools-list` | Viz výše |
| `include-custom-instructions` | Viz níže |
| `model-policy` | `preferred` (výchozí) nebo `required` (podle dokumentace) |
| `reasoning-effort` | Úroveň úsilí pro tohoto agenta |

Když je zapíšeš v camelCase, agent se pořád načte, ale klíče nedělají nic. Varování naživo:

```
unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList
```

Referenční tabulka v dokumentaci sama uvádí `modelPolicy` a `reasoningEffort`. Neopisuj to:
camelCase je zápis uživatelského přepsání v `~/.copilot/settings.json`, ne souboru agenta.

## Test režimu jen pro čtení

Co agent pro daný seznam `tools` skutečně dostane (CLI 1.0.114, model z rodiny GPT):

| `tools` v souboru | Nástroje, které agent dostal |
|---------------------|---------------------|
| `["read", "search"]` | `view`, `rg`, `glob`, `sql`, `skill` |
| `["read", "search", "execute"]` | totéž plus `bash`, `read_bash`, `stop_bash`, `list_bash` |
| `["read", "search", "edit", "execute"]` | totéž plus `apply_patch` |

První řádek je případ jen pro čtení. Takový agent nedokázal vytvořit soubor ani spustit
shellový příkaz, s `strict-tools-list: true` i bez něj. Všimni si, co tu „jen pro čtení“
znamená: žádný editační nástroj a žádný shell. `sql` a `skill` přijdou tak jako tak. Pro
srovnání: výchozí agent session měl ve stejném testu 27 nástrojů, včetně `task`,
`apply_patch`, webových nástrojů a nástrojů GitHub MCP.

## `include-custom-instructions`

Podle dokumentace vlastní agent, který běží jako **subagent**, nedostane soubory
s instrukcemi repozitáře (`copilot-instructions.md`, `AGENTS.md`), pokud jeho frontmatter
nenastaví `include-custom-instructions: true`. Tentýž agent vybraný jako agent **session**
(`--agent`, `/agent`) je dostane.

`kotlin-reviewer` a `board-test-writer` ho nastavují, protože oba posuzují kód podle
konvencí repa. `game-explorer` konvence k nakreslení mapy nepotřebuje a bez nich je
levnější. `--no-custom-instructions` vypne instrukce pro celou session, včetně agentů, kteří
si o ně říkají.

## Nepojmenovávej agenta po vestavěném

CLI má vestavěné agenty (podle dokumentace): `explore`, `task`, `general-purpose`,
`code-review`, `security-review`, `research` a `rubber-duck`. Ve výběru `/agent` se
neobjevují. Vlastní agent s některým z těchto jmen je zastíněný: delegování na to jméno vždy
spustí vestavěného. Agenti v tomhle repu používají jiná jména: `kotlin-reviewer`, ne
`code-review`; `game-explorer`, ne `explore`.

Podle dokumentace `explore`, `task` a `code-review` nikdy nedostanou instrukce repozitáře;
`general-purpose` ano. To je jeden z důvodů, proč si napsat vlastního reviewera.

## Jak agenta vyvolat

| Způsob | Příklad | Co se stane |
|-----|---------|--------------|
| Výběr | `/agent`, nebo `/agent kotlin-reviewer` | Stane se agentem session |
| Přepínač | `copilot --agent kotlin-reviewer` | Totéž, od začátku. Agenti z pluginu potřebují plné ID: `--agent 2048-dev:game-explorer` |
| Jménem v promptu | *„Použij agenta kotlin-reviewer k review mých necommitnutých změn.“* | Hlavní agent zavolá `task` s `agent_type: "kotlin-reviewer"`; agent běží jako subagent |
| Automaticky | *„Vystopuj, jak se ze stisku klávesy stane tah na desce.“* | Hlavní agent vybere agenta podle popisů, nebo práci udělá sám |

Všechny čtyři jsou otestované kromě výběru. K automatickému delegování: v našem A/B běhu
pluginu prompt žádal o „specializovaného agenta pro průzkum kódu“, aniž by nějakého
jmenoval. S načteným pluginem šel úkol na `2048-dev:game-explorer`. Bez něj šel na
vestavěného `explore`. Byl to jeden běh na každou větev, takže agenta jmenuj, když na tom
záleží.

Delegování není zadarmo. Naše review dvou malých nesledovaných souborů stálo subagenta 19
volání nástrojů a zhruba 66 000 tokenů. S `--output-format json` to uvidíš: událost
`tool.execution_start` s `toolName: "task"`, pak `subagent.started` a
`subagent.completed`.

## `/fleet`: několik subagentů najednou

`/fleet <prompt>` řekne hlavnímu agentovi, ať práci rozdělí na todos a ty nezávislé pustí
jako paralelní subagenty, kteří se hlásí zpět do stejné konverzace. Podle dokumentace ho
nasměruješ na vlastního agenta tím, že do fleet promptu napíšeš `@kotlin-reviewer`. `/tasks`
vypíše, co běží. Podrobnosti jsou v [návodu 07](07-orchestration.cs.md); používá ho cvičení
7 v [exercises.cs.md](exercises.cs.md).

## `/delegate`: předej session cloud agentovi

`/delegate` pošle session Copilotu na GitHubu, který tam pracuje a otevře pull request;
`--base` vybírá cílovou branch. Podle dokumentace potřebuje, aby v organizaci byla zapnutá
jak politika Copilot CLI, tak politika Copilot cloud agenta. Viz
[návod 13](13-remote-agents.cs.md).

## Proč tu není natvrdo žádný `model:`

Žádný ze tří souborů nemá klíč `model`. Důvody:

- **Povolené modely se liší podle organizace.** ID modelu, které funguje na účtu autora,
  nemusí pod politikou 2N existovat.
- **Špatné ID selže potichu nebo nahlas, nikdy užitečně.** Podle dokumentace `model`, ke
  kterému nemáš přístup, spadne na model session, takže klíč potichu nedělá nic.
  S `model-policy: required` se místo toho spuštění odmítne.
- **Dědění už funguje.** V našem běhu přišel model subagenta ze session
  (`modelSelectionSource: "session_inheritance"`).

Když chceš jednomu agentovi dát jiný model, udělej to per uživatele přes `/subagents`, které
volbu uloží do `~/.copilot/settings.json`. Podle dokumentace je pořadí: hodnota u volání,
nastavení `/subagents`, soubor agenta, rodičovská session. Pokud ho do souboru přece jen
dáš, klíč je `model: <model-id>`.

## Vytvoř si vlastního agenta, krok za krokem

1. **Vytvoř soubor** `.github/agents/my-agent.agent.md`:
   ```markdown
   ---
   name: my-agent
   description: Use when <the situation that should trigger delegation>. <What it returns.>
   tools: ["read", "search"]
   strict-tools-list: true
   ---

   # My agent

   <Who the agent is, what it does, how it reports back.>
   ```
2. **Rozhodni o nástrojích.** Začni od `["read", "search"]`. `execute` přidej, jen když musí
   něco spouštět, a `edit`, jen když musí zapisovat. Přidej
   `include-custom-instructions: true`, pokud kód posuzuje nebo píše.
3. **Zkontroluj, že se načte bez varování:**
   ```bash
   copilot --agent my-agent -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.custom_agents_updated") | .data | {warnings, errors}'
   ```
   Chceš vidět `{"warnings":[],"errors":[]}`. Klíč s překlepem se ukáže tady.
4. **Testuj hranici, ne slib.** Požádej ho o něco, co by neměl umět:
   ```bash
   copilot --agent my-agent -p "Create a file named probe.txt containing the word test" \
     --trust-folder --no-ask-user
   git status --short
   ```
5. **Použij ho v session.** Podle changelogu si běžící session od CLI 1.0.109 všimne nového
   souboru v `.github/agents/`. Po úpravě existujícího agenta spusť novou session.
6. **Commitni ho.** Osobní agenti patří do `~/.copilot/agents/`. Podle dokumentace osobní
   agent se stejným ID vyhrává nad projektovým.

## Vyzkoušej demo

Spusť `scripts/copilot-ws.sh` v kořenu repa. Předem schvaluje `./gradlew`, které potřebuje
druhý krok.

1. **Review necommitnutých změn (`kotlin-reviewer`).** Udělej malou úpravu v libovolném
   souboru `.kt`, pak:
   > *„Použij agenta kotlin-reviewer k review mých necommitnutých změn.“*

   Schval každý příkaz, na který se zeptá. Dostaneš nálezy označené závažností. Pak spusť
   `git status`: nic nového. (Otestováno: delegování přes `task`, patička v reportu agenta,
   žádný změněný soubor. Hlavní agent report shrnuje, takže patička může být vidět jen
   v přepisu subagenta pod `/tasks`.)
2. **Přidej test 4, 4, 8, 0 (`board-test-writer`).**
   > *„Použij agenta board-test-writer a přidej test pro posun řádku 4, 4, 8, 0.“*

   Správné očekávání je `8, 8, 0, 0` se skóre 8. Současný kód vrací `16, 0, 0, 0` s 24,
   takže správný test selže. Sleduj, co agent udělá s červeným během: jeho prompt mu říká,
   ať aserci nechá a nahlásí bug s kaskádovým mergem. Přes `git diff` zkontroluj, že aserce
   říká `8, 8, 0, 0`. Pokud ji agent místo toho oslabil, je to nález, a
   [návod 09](09-validate-eval.cs.md) ukazuje, jak takové chování měřit.
   (Tenhle krok se při psaní návodu nepouštěl.)
3. **Trasuj s `game-explorer`.**
   ```bash
   copilot --agent 2048-dev:game-explorer -p "Trace how a keypress becomes a board move" --trust-folder
   ```
   Dostaneš číslovanou stopu `file:function:line` a žádné úpravy (otestováno).

## Volitelné parametry

Další klíče frontmatteru, všechny podle dokumentace a v tomto repu netestováno:

| Klíč | Co dělá |
|-----|--------------|
| `model` | Model pro tohoto agenta. Když k němu nemáš přístup, spadne na model session |
| `models` | Pole modelů v pořadí priority; přebíjí `model` |
| `mcp-servers` | MCP servery definované jen pro tohoto agenta |
| `disable-model-invocation`, `user-invocable` | Řídí automatické delegování a ruční výběr. Nahrazují vyřazený klíč `infer` |
| `hooks` | Hooky v rozsahu agenta (jen Copilot CLI) |

V `tools` se MCP nástroje zapisují jako `server/tool` nebo `server/*`. Tělo promptu je
omezené na 30 000 znaků.

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|---------|--------|-------|
| **Copilot CLI** | ✅ | `.github/agents/*.agent.md` pro projektové agenty; agenti z pluginu po udělení důvěry složce. Otestováno |
| **IntelliJ plugin** | ⚠️ | Vlastní agenti v `.github/agents` jsou podle release notes pluginu podporovaní. Které klíče frontmatteru respektuje, zdokumentované není („Podporované vlastnosti profilu závisí na platformě“). `game-explorer` z pluginu potřebuje plugin nainstalovaný ve vlastním úložišti pluginů IDE. Tady netestováno; viz [návod 12](12-intellij.cs.md) |
| **Copilot cloud agent** | ✅ | Vlastní agenti jsou podle dokumentace podporovaní, se stejnou výhradou ohledně podporovaných vlastností. Dostaneš se k němu přes `/delegate` |

## Když něco nefunguje

- **`unknown fields ignored: ...`** → klíč v camelCase nebo s překlepem. Použij zápis
  v kebab-case z tabulky.
- **Agent se nikdy nevybere automaticky** → zpřesni `description`, nebo agenta jmenuj
  v promptu. Úkol si možná bere vestavěný agent, třeba `explore`.
- **Delegování spustí jiného agenta než tvého** → tvůj agent se jmenuje stejně jako
  vestavěný. Přejmenuj ho.
- **Agent „jen pro čtení“ změnil soubor** → má `execute`, nebo soubor nemá klíč `tools`
  vůbec. Odeber `execute`, nebo limit vynuť oprávněními nebo hookem.
- **Agent jako subagent ignoruje konvence repa** → přidej
  `include-custom-instructions: true` a zkontroluj, že jsi nespustil CLI
  s `--no-custom-instructions`.
- **`model` je nastavený, ale běžel jiný model** → k tomu modelu nemáš přístup (tichý
  fallback), nebo soubor přebíjí nastavení `/subagents`.
- **Agent z pluginu se nenašel** → použij plné ID `2048-dev:game-explorer` a zkontroluj, že
  je složka důvěryhodná (Ukázka 6).
- **V režimu `-p`: „Permission denied because no interactive user response was available.“**
  → agent potřeboval nástroj, který nikdo neschválil. Předej `--allow-tool`, například
  `--allow-tool='shell(git:*)'` pro reviewera.
- **Tvoje úprava souboru agenta nemá žádný účinek** → spusť novou session. Zkontroluj taky
  `~/.copilot/agents/`, jestli tam není osobní agent se stejným ID.

---

Dál: `game-explorer` přišel z pluginu. Jak se takový plugin staví, zařazuje do katalogu a
zapíná → [Ukázka 6: Pluginy a marketplace v repozitáři](06-plugins.cs.md).

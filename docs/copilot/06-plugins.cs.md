> 🌍 Číst v jazyce: [English](06-plugins.md) | **Česky**

# Ukázka 6: Pluginy a marketplace v repozitáři

## Co je plugin?

**Plugin** je adresář s manifestem, který sdružuje rozšíření Copilot CLI: skills, agenty,
hooky, MCP servery, LSP servery. **Marketplace** je katalogový soubor `marketplace.json`,
který vyjmenovává pluginy a říká, odkud se má každý stáhnout.

V Ukázkách 2 až 5 leží skill, hooky a agenti přímo v `.github/`. Pro jedno repo to stačí.
Plugin je tentýž obsah zabalený tak, aby se dal přenést do dalších rep a k dalším lidem, se
jménem a verzí.

Tahle ukázka je nejmenší úplná sestava: repo je **samo sobě marketplace** (`qti-copilot`)
a nabízí **jeden plugin** (`2048-dev`), který obsahuje **jeden skill** a **jednoho agenta**.
Zapíná ho commitnutý soubor s nastavením, takže nikdo nespouští instalační příkaz.

## Pohyblivé části

```
marketplace.json                              ← the marketplace catalog (repo root)
plugins/2048-dev/                             ← the plugin
├── plugin.json                               ← manifest, Agent Plugins 1.0
├── skills/build-test/SKILL.md                ← portable component: a skill
└── com.github.copilot/agents/
    └── game-explorer.agent.md                ← Copilot-specific component: an agent
.github/copilot/settings.json                 ← registers the marketplace, enables the plugin
```

Čtyři vrstvy, zevnitř ven: **skill a agent** žijí v **pluginu**, ten je uvedený
v **marketplace** a na ten ukazuje **nastavení** repa.

## Vrstva 1: skill a agent

**Skill** je `plugins/2048-dev/skills/build-test/SKILL.md`:

```markdown
---
name: build-test
description: Build the 2048 project and run every test suite (Gradle and Vitest), then summarize the results without fixing anything. Use when asked to build, to run all tests, or to check whether the tree is green.
---

# Build and test

Build the project and run the tests:

1. Backend: `./gradlew build`
2. Frontend: `cd web && npm test && npm run lint && npm run build`
...
- Do not fix anything. This skill only reports status.
```

- Stejný formát jako projektový skill (Ukázka 2): `name`, `description`, pak pracovní postup.
- Podle dokumentace musí skill ležet ve vlastním podadresáři přímo pod `skills/`. V tomhle
  formátu pluginu neexistuje fallback na `SKILL.md` v kořenu pluginu.
- Chybí tu `disable-model-invocation: true`, takže model smí skill načíst i sám. Tím se
  zároveň vyhneš známému problému: podle otevřeného issue odpovídá skill určený jen pro
  ruční spuštění v bězích `-p` hláškou „Skill not found“.

**Agent** je `com.github.copilot/agents/game-explorer.agent.md`, agent pro čtení a hledání
popsaný v [Ukázce 5](05-agents.cs.md). Všimni si, kde leží: ne vedle `skills/`, ale pod
`com.github.copilot/`. Proč, vysvětluje Vrstva 2.

## Vrstva 2: manifest (`plugins/2048-dev/plugin.json`)

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "2048-dev",
  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
  "version": "1.0.0",
  "author": {
    "name": "Josef Klesa",
    "url": "https://github.com/klesajos"
  }
}
```

- `$schema` — přesně tenhle řetězec přihlašuje plugin k formátu **Agent Plugins 1.0**. Podle
  dokumentace se manifest bez některé z rozpoznávaných hodnot načte jako *legacy* plugin a
  manifest, který deklaruje verzi, kterou CLI nepodporuje, se rovnou odmítne. Připni 1.0.0:
  specifikace 1.1.0 byla v době psaní návodu pořád pracovní návrh.
- `name` — identifikátor pluginu. Stane se prefixem jeho skills a agentů (`2048-dev:...`)
  a částí před `@` v `2048-dev@qti-copilot`. Malá písmena, číslice, pomlčky a tečky;
  nejvýš 64 znaků.
- `version` — zobrazuje se v `copilot plugin list` (`2048-dev (v1.0.0)`). Zvyš ji, když se
  plugin změní.
- `description`, `author` — metadata.

**Co patří do kořenu a co pod `com.github.copilot/`.** V Agent Plugins 1.0 manifest
popisuje plugin a nic jiného. Nemá žádná pole, která by ukazovala na komponenty; umístění
jsou pevně daná (podle dokumentace):

| Umístění v pluginu | Obsahuje | Rozsah |
|------------------------|-------|-------|
| `plugin.json` | Manifest. Povolená pole: `$schema`, `name`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `extensions` | Přenositelné |
| `skills/<name>/SKILL.md` | Skills | Přenositelné |
| `mcp.json` | MCP servery. Potřebuje vlastní řádek `$schema` | Přenositelné |
| `com.github.copilot/agents/` | Vlastní agenti (`*.agent.md`) | Jen Copilot |
| `com.github.copilot/commands/`, `rules/` | Slash příkazy, pravidla | Jen Copilot |
| `com.github.copilot/hooks/hooks.json` | Hooky | Jen Copilot |
| `com.github.copilot/lsp.json` | LSP servery | Jen Copilot |

V kořenu je to, co specifikace pluginů definuje pro každý nástroj, který ji implementuje.
Všechno, čemu rozumí jen Copilot, jde do adresáře s vlastním jmenným prostorem Copilotu.
Neznámé pole nejvyšší úrovně v `plugin.json` se nahlásí a ignoruje.

**Legacy formát, pro srovnání** (podle dokumentace):

```json
{
  "name": "my-dev-tools",
  "description": "React development utilities",
  "agents": "agents/",
  "skills": ["skills/", "extra-skills/"],
  "hooks": "hooks.json",
  "mcpServers": ".mcp.json"
}
```

Žádné `$schema`, cesty ke komponentám nastavitelné v manifestu a agenti v `agents/` v kořenu
pluginu. GitHub pro nové pluginy doporučuje Agent Plugins 1.0. CLI načítá jako legacy
pluginy i rozložení pluginů pro Claude Code (`.claude-plugin/plugin.json`).

## Vrstva 3: marketplace (`marketplace.json` v kořenu repa)

```json
{
  "name": "qti-copilot",
  "owner": {
    "name": "Josef Klesa"
  },
  "metadata": {
    "description": "Plugins for the qti-copilot GitHub Copilot workshop",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "2048-dev",
      "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
      "version": "1.0.0",
      "source": "./plugins/2048-dev"
    }
  ]
}
```

- `name` — identifikátor marketplace a část za `@`. Podle dokumentace je to registrační
  klíč a lokálně ho přepsat nejde; název repozitáře nehraje žádnou roli.
- `owner` — povinné; kdo katalog spravuje.
- `plugins[].source` — cesta relativní ke kořenu repa: plugin se dodává s repem. Katalog
  může mířit i jinam objektem typu
  `{"source": "github", "repo": "owner/repo", "path": "plugins/my-plugin"}`. Takhle jeden
  centrální marketplace uvádí pluginy z mnoha rep.
- Umístění — podle dokumentace CLI hledá `marketplace.json`, `.plugin/marketplace.json`,
  `.github/plugin/marketplace.json`, pak `.claude-plugin/marketplace.json`. Tohle repo
  používá kořen, stejně jako startovací šablona samotného GitHubu.

## Vrstva 4: automatické zapnutí (`.github/copilot/settings.json`)

```json
{
  "extraKnownMarketplaces": {
    "qti-copilot": {
      "source": {
        "source": "directory",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "2048-dev@qti-copilot": true
  }
}
```

- `extraKnownMarketplaces` — „tohle repo používá marketplace jménem `qti-copilot` a je to
  adresář `.`“, tedy samotný checkout. Ze sítě se nic nestahuje. Pro marketplace v jiném
  repu je zdroj `{"source": "github", "repo": "OWNER/REPOSITORY"}`.
- `enabledPlugins` — „z toho marketplace zapni `2048-dev`“. Klíč je
  `<plugin-name>@<marketplace-name>`.

**Začne to platit po udělení důvěry složce.** Nastavení pluginů v repozitáři je součástí
toho, co schvaluješ v dotazu na důvěru složce. Jakmile je složka důvěryhodná, plugin je
zapnutý jen v tomhle repozitáři, ne v tvých ostatních projektech. Otestováno na 1.0.114:
v důvěryhodné složce se plugin načte bez instalačního kroku. Běh `copilot -p` potřebuje pro
stejný výsledek `--trust-folder`.

## Jak se jmenují skills a agenti z pluginu

Otestováno na 1.0.114:

| Komponenta | Jméno v souboru | Jméno, které používáš |
|-----------|------------------|--------------|
| Skill | `build-test` | `/2048-dev:build-test` |
| Agent | `game-explorer` | `2048-dev:game-explorer`, například `--agent 2048-dev:game-explorer` |

Oddělovač je **dvojtečka**. Jedna stránka dokumentace ukazuje tvar s lomítkem
(`/my-plugin/search`); tak se 1.0.114 nechová. Slash příkaz funguje i v režimu `-p`
(otestováno). Tam potřebuje mít nástroje schválené předem:

```bash
copilot -p "/2048-dev:build-test" --trust-folder \
  --allow-tool='shell(./gradlew:*)' --allow-tool='shell(npm:*)'
```

**Projektová jména zastiňují jména z pluginu.** Podle dokumentace platí, že když má skill
nebo agent na úrovni projektu stejné jméno nebo ID jako ten v pluginu, kopie z pluginu se
potichu ignoruje. Plugin nikdy nemůže přebít to, co si repo definuje samo. Drž proto jména
odlišná: tohle repo má projektový skill `board-tests` a pluginový skill `build-test`.

## Vývojová smyčka: `--plugin-dir`

Dokud plugin píšeš, neinstaluj ho. Připoj ho:

```bash
copilot --plugin-dir ./plugins/2048-dev
```

Podle dokumentace se adresář pro danou session připojí jen pro čtení, nic se neinstaluje a
tvoje úpravy se projeví po `/restart` nebo v nové session. Připojení ověříš, aniž bys
utratil volání modelu (otestováno):

```
$ copilot --plugin-dir ./plugins/2048-dev plugin list
...
External Plugins (via --plugin-dir):
  • 2048-dev (v1.0.0)
```

`COPILOT_PLUGIN_DIR_ONLY=true` vypne automatické vyhledávání pluginů, takže se načtou jen
ty připojené. Používá to `evals/plugin-ab.sh` k porovnání běhů s pluginem a bez něj.

## Ruční příkazy pro marketplace

Pro použití tohoto marketplace z **jiného** repa, nebo pro jakýkoli marketplace, který ti
žádný soubor s nastavením nezaregistruje (syntaxe z `copilot plugin --help`; tady se
nepouštěly, protože mění tvůj uživatelský profil):

```bash
copilot plugin marketplace add klesajos/qti-copilot    # owner/repo, a git URL, or a local path
copilot plugin marketplace browse qti-copilot          # what it offers
copilot plugin install 2048-dev@qti-copilot
copilot plugin list
copilot plugin update 2048-dev@qti-copilot
copilot plugin uninstall 2048-dev@qti-copilot
copilot plugin marketplace remove qti-copilot
```

Uvnitř session otevře stejnou správu `/plugin`. U soukromého repa s marketplace k němu
potřebuješ přístup pro čtení; podle dokumentace ho samotné členství v organizaci nedává.

**Instaluj jen přes `name@marketplace`.** `copilot plugin install --help` na 1.0.114 uvádí
jako zdroje `plugin@marketplace`, `owner/repo`, `owner/repo:path` a git URL, lokální cestu
ne. Podle otevřeného issue už přímé tvary vypisují varování o zastarání:

```
⚠️ Warning: Direct plugin installs (repos, URLs, local paths) are deprecated. Only plugin@marketplace installs will be supported in a future release.
```

Pro lokální práci použij `--plugin-dir`. Pro sdílení použij marketplace.

## Osobní vypnutí

Když chceš plugin zapnutý repem vypnout jen pro sebe, vytvoř
`.github/copilot/settings.local.json` (podle dokumentace; `.gitignore` tohoto repa už ten
soubor vylučuje):

```json
{
  "enabledPlugins": {
    "2048-dev@qti-copilot": false
  }
}
```

`copilot plugin disable` na tohle není: podle dokumentace se odmítne u pluginu, o jehož
stavu rozhoduje nastavení repozitáře.

## Validuj, než commitneš

**Žádné `copilot plugin validate`** neexistuje. `copilot plugin --help` uvádí install,
uninstall, update, list, enable, disable a marketplace. Udělej to, co dělá startovací
šablona GitHubu, a zkontroluj manifest proti publikovanému schématu:

```bash
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

Spuštěné v tomhle repu vypíše `plugins/2048-dev/plugin.json valid`. To dokazuje, že je
manifest správně utvořený, ne že se komponenty načtou. Na to se zeptej session, co načetla
(jedno volání modelu; otestováno):

```bash
copilot -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
  | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | {commandName, source}'
```

Očekávaný výstup: `{"commandName":"2048-dev:build-test","source":"plugin"}`. V interaktivní
session vypíše načtené pluginy, skills a agenty příkaz `/env`.

## Co dalšího commitnuté nastavení ovlivňuje

**Běhy cloud agenta.** Podle dokumentace čte Copilot cloud agent `enabledPlugins` a
`extraKnownMarketplaces` z `.github/copilot/settings.json` taky a lokální přepsání tam
neexistuje. Co v tomhle souboru commitneš, platí i tehdy, když úkol pro tohle repo běží
v cloudu, například po `/delegate`.

**Omezení, která mohl nastavit administrátor.** Spravovaná nastavení vždy přebijí výchozí
hodnoty repozitáře (podle dokumentace; nic z toho se tu netestovalo):

| Spravované nastavení | Dopad na tuhle ukázku |
|-----------------|------------------------|
| `strictKnownMarketplaces` | Allow-list zdrojů marketplace. Marketplace, který na něm není, se nedá použít; počítej s tím, že to platí i pro ten v repu |
| `enabledPlugins` | `true` plugin vynutí, `false` ho zablokuje. Zablokovaný plugin repo zapnout nemůže |
| `strictPluginOnlyCustomization` | Blokuje *samostatné* skills, agenty, hooky a MCP servery z repa i od uživatele. Načtou se jen ty dodané pluginem |
| MCP allow-list | MCP servery dodané uvnitř pluginu jím musí projít taky (Ukázka 4) |

Vlastníci organizace a maintaineři týmů můžou pluginy nastavit i jako týmové výchozí; podle
changelogu GitHubu je CLI zobrazuje jako „Team plugin assignments“ v `/plugin list`. Pokud
se plugin načte na soukromém stroji, ale na stroji 2N ne, zeptej se administrátora dřív, než
začneš ladit soubory.

## Sdílení nástroje s kolegy

Plugin je způsob, jak vlastní nástroj dostat k dalším lidem, a přesně k tomu jsou guildy ve
2N. Obvyklá cesta:

1. Skill, agent nebo hook začne v `.github/` jednoho repa a osvědčí se.
2. Přesuň ho do `plugins/<name>/` s `plugin.json`. Dej mu verzi.
3. Uveď ho v repu s marketplace, které tvoji kolegové můžou číst.
4. Kolegové jednou spustí `copilot plugin marketplace add <owner>/<repo>` a nainstalují si,
   co chtějí, nebo ho projekt zapne celému týmu dvěma klíči nastavení z Vrstvy 4.
5. Když ho změníš, zvyš `version`. Kolegové si změnu stáhnou přes
   `copilot plugin update <name>@<marketplace>`.

Dokumentace žádá autory pluginů, aby přidali evaluace chování, které má plugin poskytovat;
jak na to, ukazuje [návod 09](09-validate-eval.cs.md).

## Vytvoř si vlastní plugin, krok za krokem

1. **Vytvoř kostru:**
   ```bash
   mkdir -p plugins/my-plugin/skills/hello
   ```
2. **Napiš `plugins/my-plugin/plugin.json`.** Zkopíruj soubor z Vrstvy 2, `$schema` nech
   přesně tak, jak je, změň `name` a `description`.
3. **Přidej skill** v `plugins/my-plugin/skills/hello/SKILL.md` s `name`, `description`
   a tělem. Agent by patřil do `plugins/my-plugin/com.github.copilot/agents/`.
4. **Vyzkoušej ho připojený:** `copilot --plugin-dir ./plugins/my-plugin`, pak
   `/my-plugin:hello` (pojmenování otestované pro `2048-dev`).
5. **Zvaliduj** manifest příkazem `ajv` výše.
6. **Uveď ho** v `marketplace.json`: nová položka v `plugins` s `name` a
   `"source": "./plugins/my-plugin"`.
7. **Zapni ho všem:** přidej `"my-plugin@qti-copilot": true` do `enabledPlugins`
   v `.github/copilot/settings.json`.
8. **Spusť novou session,** zkontroluj ho přes `/env` a commitni.

## Plugin, nebo samostatný skill či hook: co zvolit?

| | Samostatně v `.github/` | Plugin |
|---|--------------------------|--------|
| Rozsah | Jedno repo | Každé repo, které ho zapne nebo nainstaluje |
| Nastavení | Žádné | Manifest, položka v marketplace, nastavení |
| Verzování | S repem | Vlastní `version` |
| Při kolizi jmen | Vyhrává | Potichu se ignoruje |
| Pod `strictPluginOnlyCustomization` | Zablokováno | Načte se dál |

Začni samostatně. K pluginu přejdi, až bude totéž chtít druhé repo nebo druhý tým.

## Vyzkoušej demo

1. Spusť `scripts/copilot-ws.sh` v kořenu repa a dej složce důvěru. Launcher předem
   schvaluje `./gradlew`, `npm test` a `npm run`. Cokoli dalšího, na co se zeptá, schval.
2. Spusť `/2048-dev:build-test`. Copilot by měl sestavit projekt, pustit tři testovací sady,
   nahlásit počty a nic neopravovat, protože to tak říká soubor skillu.
3. Ve druhém terminálu spusť `copilot plugin list`. `2048-dev` tam **není**. To je
   očekávané; viz sekci Když něco nefunguje.
4. Spusť trasovacího agenta z Ukázky 5:
   ```bash
   copilot --agent 2048-dev:game-explorer -p "Trace how a keypress becomes a board move" --trust-folder
   ```
5. Volitelně: vytvoř soubor pro vypnutí ze sekce „Osobní vypnutí“, spusť novou session a
   zkontroluj, že `/2048-dev:build-test` zmizel. Potom soubor smaž.

## Volitelné parametry

Podle dokumentace:

| Kde | Pole | Co dělá |
|-------|-------|--------------|
| `plugin.json` | `homepage`, `repository`, `license`, `keywords` | Metadata |
| `marketplace.json` | `metadata.pluginRoot` | Součást volitelného objektu `metadata`, vedle `description` a `version` |
| položka pluginu v `marketplace.json` | `category`, `tags`, `author`, `homepage`, `license` | Metadata pro výpis |
| položka pluginu v `marketplace.json` | `source` jako objekt s `ref`, `sha` | Připne vzdálený plugin na branch, tag nebo plné SHA commitu |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|---------|--------|-------|
| **Copilot CLI** | ✅ | Nastavení repa plus důvěra složce. Otestováno na 1.0.114 |
| **IntelliJ plugin** | ⚠️ | JetBrains plugin má **vlastní úložiště pluginů**; instalace z CLI se tam neobjeví. Pluginy a marketplace se spravují v panelu Customizations v IDE. Jestli čte klíče pluginů v `.github/copilot/settings.json` nebo načítá komponenty z `com.github.copilot/`, zdokumentované není. Tady netestováno; viz [návod 12](12-intellij.cs.md) |
| **Copilot cloud agent** | ✅ | Čte `enabledPlugins` a `extraKnownMarketplaces` z commitnutého nastavení (podle dokumentace; netestováno) |

## Když něco nefunguje

- **`copilot plugin list` neukazuje `2048-dev`** → očekávané. Otestováno: mimo session
  příkaz vypisuje jen pluginy nainstalované uživatelem a vestavěné, ne pluginy, které zapíná
  repozitář. `copilot plugin marketplace browse qti-copilot` ze stejného důvodu odpoví
  `Marketplace "qti-copilot" not found`. Kontroluj uvnitř session přes `/env`, nebo příkazem
  `jq` ze sekce o validaci.
- **`/2048-dev:build-test` je neznámý** → složka není důvěryhodná, nějaký
  `settings.local.json` nastavuje plugin na `false`, v shellu máš nastavené
  `COPILOT_PLUGIN_DIR_ONLY`, nebo marketplace blokuje spravovaná politika.
- **Skill se načte, ale agent chybí** → zkontroluj `$schema` v `plugin.json`. Podle
  dokumentace se plugin bez přesné hodnoty bere jako legacy a legacy pluginy mají agenty
  v `agents/`, ne v `com.github.copilot/agents/`.
- **Upravil jsi skill a nic se nezměnilo** → `/restart` nebo nová session.
- **Skill z pluginu se nikdy nespustí, přestože je plugin načtený** → zastiňuje ho
  projektový skill se stejným jménem. Jeden z nich přejmenuj.
- **`copilot plugin disable` se odmítne** → plugin řídí nastavení repa. Použij
  `settings.local.json`.
- **Varování o zastarání při instalaci** → instaloval jsi z repa, URL nebo cesty. Přidej
  marketplace a nainstaluj `name@marketplace`.
- **Zapnutý ze vzdáleného marketplace, nainstalovaný, ale nikdy aktivní** → otevřené issue
  popisuje pluginy, které `enabledPlugins` nainstaluje, ale zaznamená jako vypnuté. Všechna
  hlášení používají vzdálený zdroj `github`. Adresářový zdroj v tomhle repu v našich testech
  fungoval.

---

Dál: jeden agent a jeden úkol v jednu chvíli je ten jednoduchý případ. Plány, autopilot a
paralelní subagenti → [návod 07: Orchestrace](07-orchestration.cs.md).

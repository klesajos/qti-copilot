> 🌍 Číst v jazyce: [English](07-plugins.md) | **Česky**

# 07 · Pluginy a sdílení na guildách

> ⏱ 15 min (7 demo + 8 cvičení 6) · Dokumentace: [Plugins for GitHub Copilot](https://docs.github.com/en/copilot/concepts/customizations/plugins) · [Creating a plugin](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating) · [Finding and installing plugins](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing) · Ověřeno na Copilot CLI 1.0.114

## Co je plugin?

**Plugin** je adresář s manifestem `plugin.json`, který pod jedním jménem a verzí sdružuje skilly,
agenty, hooky, MCP servery a LSP servery. **Marketplace** je katalogový soubor
`marketplace.json`, který vyjmenovává pluginy a říká, odkud se má každý stáhnout.

Návody 02 až 06 dávají všechno do `.github/` jednoho repa. My2N má asi 170 rep, šest stacků a
guildy, které sdílejí nástroje. Plugin v marketplace repu je cesta, jak se nástroj guildy dostane
do ostatních rep: verzovaný, instalovaný jménem, nebo zapnutý pro repo dvěma klíči v nastavení.

## Co dělá tahle ukázka

```
marketplace.json                          ← catalog "qti-copilot": the repo is its own marketplace
plugins/2048-dev/                         ← the plugin
├── plugin.json                           ← manifest, Agent Plugins 1.0
├── skills/build-test/SKILL.md            ← portable part: a skill → /2048-dev:build-test
└── com.github.copilot/agents/
    └── game-explorer.agent.md            ← Copilot part: an agent → 2048-dev:game-explorer
.github/copilot/settings.json             ← enables the plugin after folder trust: no install step
```

## Soubory řádek po řádku

**`plugins/2048-dev/plugin.json`**
```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "2048-dev",
  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
  "version": "1.0.0",
  "author": { "name": "Josef Klesa", "url": "https://github.com/klesajos" }
}
```
- `$schema` — přesně tahle hodnota vybírá formát [Agent Plugins 1.0](https://agent-plugins.org/specification).
  Bez ní se plugin načte jako legacy plugin, který má agenty v `agents/`.
- `name` — prefix každé komponenty: `/2048-dev:build-test`, `2048-dev:game-explorer`;
  `/skills`, `/env` a výběr `/agent` vypisují jména bez prefixu. Projektový skill nebo agent se
  stejným jménem vyhrává; kopie z pluginu se tiše ignoruje.
- `version` — v `/env` se ukazuje jako `2048-dev (1.0.0)`. Zvyš ji s každou změnou.
- Žádné pole neukazuje na komponenty; umístění jsou pevná. `skills/<name>/SKILL.md` a `mcp.json` leží
  v kořenu pluginu. Agenti, hooky, příkazy, pravidla a `lsp.json` patří pod `com.github.copilot/`.

> 🔷 **Jen Copilot:** manifest se řídí specifikací Agent Plugins, nezávislou na dodavateli, a části specifické pro Copilot jsou pod `com.github.copilot/`. Pluginy pro Claude Code používají vlastní manifest Claude, `.claude-plugin/plugin.json`, ne tuhle specifikaci.

**`marketplace.json`** (kořen repa; zkráceno)
```json
{ "name": "qti-copilot", "owner": { "name": "Josef Klesa" },
  "plugins": [ { "name": "2048-dev", "version": "1.0.0", "source": "./plugins/2048-dev" } ] }
```
- `name` — ID marketplace, část za `@` v `2048-dev@qti-copilot`. `owner` je povinný.
- `plugins[].source` — cesta relativní ke kořenu repa: plugin je součástí tohoto repa. Plugin
  v jiném repu používá `{"source": "github", "repo": "owner/repo", "path": "plugins/x", "sha": "<commit>"}`.

**`.github/copilot/settings.json`**
```json
{ "extraKnownMarketplaces": { "qti-copilot": { "source": { "source": "directory", "path": "." } } },
  "enabledPlugins": { "2048-dev@qti-copilot": true } }
```
- `extraKnownMarketplaces` — marketplace `qti-copilot` je adresář `.`, tedy samotný
  checkout. Nic se nestahuje; plugin se načítá živě z pracovního stromu.
- `enabledPlugins` — klíč `<plugin>@<marketplace>`. Zapnuto jen v tomto repozitáři a jen po
  udělení důvěry složce (`copilot -p` potřebuje `--trust-folder`). Tvůj opt-out: stejný klíč
  nastavený na `false` v `.github/copilot/settings.local.json` (tady ho git ignoruje).

> 🔷 **Jen Copilot:** s marketplace na GitHubu `enabledPlugins` po udělení důvěry složce chybějící plugin i nainstaluje (otevřené issue v CLI ho může nechat neaktivní: viz Když něco nefunguje). V Claude Code ho stejné dva klíče zapnou, ale každý přispěvatel stejně jednou spustí `claude plugin install`, pokud ho nenainstalují managed settings.

## Vytvoř si vlastní, krok za krokem

1. Přidej `plugins/2048-dev/skills/<skill>/SKILL.md` s `name` a `description`. Zvyš `version`
   v `plugin.json` a v položce pluginu v `marketplace.json`.
2. Zvaliduj ho (žádný `copilot plugin validate` neexistuje). Čekej `plugins/2048-dev/plugin.json valid`:
   ```bash
   curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
   npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
   ```
3. Zkontroluj, že ho nová session načte. Čekej `"2048-dev:build-test"` a svůj nový skill:
   ```bash
   copilot -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | .commandName' | sort -u
   ```
4. Připoj plugin, který zatím není zapnutý žádným souborem s nastavením (nový, z repa guildy). Nic se neinstaluje:
   ```bash
   copilot --plugin-dir ./plugins/2048-dev               # then /2048-dev:build-test
   copilot --plugin-dir ./plugins/2048-dev plugin list   # no model call; lists "2048-dev (v1.0.0)"
   ```

## Sdílej nástroj na guildě

Jedno marketplace repo, které může číst každý člen guildy (jména jsou příklady):

```
2n-copilot-plugins/
├── marketplace.json                      ← "name": "2n-guild", one entry per plugin
└── plugins/kotlin-review/
    ├── plugin.json
    └── skills/review-pr/SKILL.md
```

1. Vytvoř repo. Zkopíruj `marketplace.json` a `plugin.json` z tohoto repa a změň obě hodnoty
   `name`, nebo začni z [github/plugin-marketplace-starter](https://github.com/github/plugin-marketplace-starter).
2. Nástroj, který se osvědčil v `.github/` jednoho repa, přesuň do `plugins/<plugin>/`: skilly
   do `skills/<skill>/SKILL.md`, agenty a hooky pod `com.github.copilot/`. MCP server
   v pluginu musí i tak projít MCP allow-listem 2N.
3. Uveď plugin v `marketplace.json` s `"source": "./plugins/<plugin>"`.
4. Připoj ho přes `--plugin-dir`, vyzkoušej a zvaliduj manifest (kroky 2 a 4 výše).
5. Pushni. Dej guildě k repu přístup pro čtení; samotné členství v organizaci nestačí.
6. Každý kolega jednou spustí (⚠️ v tomto repu nespuštěno):
   `copilot plugin marketplace add <owner>/<repo>`, potom `copilot plugin install <plugin>@<marketplace>`.
7. Nebo ho projekt zapne celému svému týmu: commitni ty dva klíče nastavení se zdrojem
   marketplace `{"source": "github", "repo": "<owner>/<repo>"}` (⚠️ v tomto repu nespuštěno).
8. Když chceš vydat změnu, zvyš `version` v obou souborech. Kolegové spustí
   `copilot plugin update <plugin>@<marketplace>` (⚠️ v tomto repu nespuštěno).

## Vyzkoušej demo

1. Spusť `scripts/copilot-ws.sh` v kořenu repa, dej složce důvěru a spusť `/2048-dev:build-test`.
2. Na jeden nebo dva dotazy odpověz **1. Yes**. Copilot sestaví, otestuje a nic neopravuje; náš
   běh skončil `Tests: engine 13 passed/0 failed; API 5 passed/0 failed; web 7 passed/0 failed`.
3. `copilot plugin list` mimo session vypíše nainstalované a vestavěné pluginy, `2048-dev` ne.

## Volitelné parametry

| Kde | Pole | Co dělá |
|-------|-------|--------------|
| Položka v `marketplace.json` | Objekt `source` s `ref`, `sha` | Připne vzdálený plugin na branch, tag nebo commit |
| Prostředí | `COPILOT_PLUGIN_DIR_ONLY=true` | Načte jen pluginy z `--plugin-dir`. `evals/plugin-ab.sh` tím porovnává běhy s pluginem a bez něj |
| `copilot plugin install` | `owner/repo`, `owner/repo:path`, git URL | Přímé instalace. Vypíšou varování o zastarání; instaluj přes `<plugin>@<marketplace>`. Zdroj z lokální cesty neexistuje: použij `--plugin-dir` |

> 🔷 **Jen Copilot:** `copilot plugin install --from-github <resource@revision>` s digesty zkopírovanými z github.com ověří přesně dané soubory a před instalací chce tvoje potvrzení. Claude Code připíná plugin přes commit SHA nebo sha256 v položce marketplace a ověřenou instalaci v jednom kroku nemá.

Kompletní reference: [GitHub Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|-----|-----------------|-------------|
| ✅ Commitnuté nastavení plus důvěra složce | ⚠️ Má vlastní úložiště pluginů; instalace z CLI se tam neobjeví. Jestli čte klíče pluginů v `.github/copilot/settings.json`, není zdokumentováno ([11](11-ide-remote.cs.md)) | ✅ Čte oba klíče z commitnutého nastavení; lokální opt-out neexistuje |

## Copilot vs Claude Code

Claude Code má stejný mechanismus pod stejnými jmény: plugin, marketplace a stejné dva
klíče v `.claude/settings.json`. Jeho manifest je `.claude-plugin/plugin.json`; Copilot CLI umí
nainstalovat i pluginy v tomto formátu a ty dva klíče čte i z `.claude/settings.json`. Claude Code
má `claude plugin validate`; Copilot CLI validační příkaz nemá, proto ta kontrola proti schématu.

## Když něco nefunguje

- **`/2048-dev:build-test` je neznámý** → `settings.local.json` ti plugin vypíná, nebo běhu `-p` chybí `--trust-folder`. Politiky organizace, které blokují pluginy: [předletová kontrola](preflight.cs.md).
- **Skill se načte, ale agent chybí** → `$schema` není přesně hodnota 1.0.0 (legacy plugin).
- **Skill z pluginu se nikdy nespustí** → zastiňuje ho projektový skill se stejným jménem. Jeden přejmenuj.
- **Zapnutý ze vzdáleného marketplace, ale nikdy aktivní** → [otevřené issue v CLI](https://github.com/github/copilot-cli/issues/4837). Nainstaluj ho jménem.

Dál: [08 · Oprávnění a sandbox](08-permissions-sandbox.cs.md)

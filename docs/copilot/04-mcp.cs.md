> 🌍 Číst v jazyce: [English](04-mcp.md) | **Česky**

# Ukázka 4: MCP připojení

## Co je MCP?

**MCP (Model Context Protocol)** je způsob, jak Copilot CLI získá nástroje, které v sobě nemá.
**MCP server** je buď lokální proces, který CLI spustí (`stdio`), nebo vzdálený endpoint,
který volá (`http`, `sse`). Každý server přidá do kontextu modelu definice nástrojů a každé
volání takového nástroje prochází stejným systémem oprávnění jako shellový příkaz.

Ve 2N je MCP omezené na krátký schválený seznam. Tím je daná podoba celé ukázky:

- Tohle repo **neobsahuje žádný MCP server třetí strany**. Commitnutý `.mcp.json`, který by
  mířil na nějaký veřejný server, by na tvém stroji zablokoval allow-list a ty bys celé
  cvičení ladil politiku.
- Hlavním příkladem je **vestavěný GitHub MCP server**, který má každé přihlášené CLI.
- Schválený 2N Jira MCP je v `.mcp.json.example` ukázaný jako **vzor**. Skutečnou URL
  dostaneš od 2N.

## Co dělá tahle ukázka

| Část | Kde | Co se naučíš |
|-------|-------|----------------|
| Vestavěný GitHub MCP server | uvnitř CLI, není co konfigurovat | Co ve výchozím stavu nabízí, jak vypsat a rozšířit jeho nástroje |
| `.mcp.json.example` | kořen repa | Formát workspace souboru, se schváleným Jira MCP jako vzorem |
| Hlášky politik | tento návod | Jak poznat blokaci politikou od chyby v konfiguraci |

## Vestavěný GitHub MCP server

Když jsi přihlášený, CLI si samo spustí server jménem `github-mcp-server`. Ověř to ze
shellu (výstup z CLI 1.0.114):

```
$ copilot mcp list
Builtin servers:
  computer-use (local)
  github-mcp-server (http)
```

**Co umí ve výchozím stavu.** Je jen pro čtení a nabízí podmnožinu plného GitHub MCP
serveru. Podmnožina závisí na tom, jestli máš `gh` v `PATH`: nástroje, které `gh` dokáže
nahradit, se vynechají, aby se šetřil kontext. Otestováno na 1.0.114:

| Tvůj stroj | Nabízené nástroje |
|--------------|---------------|
| `gh` v `PATH` | 6: `get_file_contents`, `search_code`, `search_users`, `get_copilot_space`, `list_copilot_spaces`, `web_search` |
| bez `gh` | 24: těch šest výše plus `search_repositories`, `list_branches`, `list_commits`, `get_commit`, `issue_read`, `list_issues`, `search_issues`, `pull_request_read`, `list_pull_requests`, `search_pull_requests`, `actions_list`, `actions_get`, `get_job_logs`, `list_workflow_runs`, `get_workflow_run`, `list_workflows`, `get_workflow_run_logs`, `get_workflow` |

S nainstalovaným `gh` tedy agent **nemá žádný MCP nástroj pro issues ani pull requesty** a
čeká se, že místo toho použije `gh` v shellu. Ani jedna sada neobsahuje nástroj pro zápis.
Model vidí každý nástroj s názvem serveru jako prefixem, například
`github-mcp-server-search_code`.

**Vypiš jeho nástroje.** V session:

```
/mcp list                       ← every server with its live status
/mcp get github-mcp-server      ← details and the tools it provides
```

(`copilot help mcp` na 1.0.114 uvádí sloveso `get`; online dokumentace mu pořád říká `/mcp show`.)
Ze shellu ukazují `copilot mcp list` a `copilot mcp get github-mcp-server` konfiguraci,
ne živý stav.

**Rozšiř sadu nástrojů.** Tři přepínače při spuštění. První dva jsou otestované na 1.0.114;
třetí je popsaný podle `copilot --help`:

| Přepínač | Účinek |
|------|--------|
| `--add-github-mcp-toolset <toolset>` | Přidá celý toolset **navíc k** výchozí podmnožině (lze opakovat). `all` zapne všechny toolsety. Otestováno s `issues`. |
| `--add-github-mcp-tool <tool>` | **Nahradí** výchozí podmnožinu přesně těmi nástroji, které vyjmenuješ (lze opakovat). `*` znamená všechny nástroje. |
| `--enable-all-github-mcp-tools` | Všechno. Přebíjí oba přepínače výše. |

Aby volba platila trvale, nastav `githubMcpToolsets`, `githubMcpTools` nebo
`enableAllGithubMcpTools` v `~/.copilot/settings.json` (podle `copilot help mcp`; v tomto
repu netestováno). Kterákoli z těchto voleb přepne server z endpointu jen pro čtení:
`copilot mcp get github-mcp-server` ukazuje ve výchozím stavu URL končící na `/mcp/readonly`
a po rozšíření na `/mcp`. Celý toolset s sebou může přinést nástroje pro zápis. Vyjmenování
jednotlivých čtecích nástrojů ne.

**Politika.** Podle dokumentace se na vestavěný server nevztahují MCP allow-listy ani
deny-listy. Na hlavní vypínač se výjimka nevztahuje: od CLI 1.0.112 platí, že když politika
organizace „MCP servers in Copilot“ MCP vypne, vestavěný GitHub server se nespustí. Pokud
`github-mcp-server` chybí všem, je příčina tady. Na svém stroji to ničím nespravíš.

## Soubor řádek po řádku

Workspace servery žijí v **`.mcp.json` v kořenu repa**. Tohle repo obsahuje jen vzor,
`.mcp.json.example`:

```json
{
  "mcpServers": {
    "jira": {
      "type": "http",
      "url": "https://REPLACE-WITH-THE-APPROVED-JIRA-MCP-URL/mcp",
      "tools": ["*"]
    }
  }
}
```

- `"mcpServers"` — klíč nejvyšší úrovně. Klíč `servers` z VS Code tady nefunguje: se
  `servers` CLI nenačte žádnou z položek. Soubor musí být striktní JSON, bez komentářů a bez
  čárek na konci.
- `"jira"` — název serveru. Objevuje se v `/mcp`, jako prefix názvů nástrojů a v pravidlech
  oprávnění (`jira(tool_name)`). Allow-listy založené na názvu porovnávají právě ten, takže
  použij přesně název, který ti dá 2N, a nepřejmenovávej ho.
- `"type": "http"` — vzdálený server. Na tvém stroji nic neběží. Druhý vzdálený typ je
  `sse`. Lokální server používá `"type": "local"` (nebo `"stdio"`) s `command` a `args`.
- `"url"` — zástupná hodnota. Skutečnou adresu dostaneš od 2N. Zapiš ji doslovně (viz sekce
  o tajných údajích).
- `"tools": ["*"]` — zpřístupní každý nástroj, který server nabízí. Když místo toho
  vyjmenuješ názvy nástrojů, nepoužívané definice se do kontextu nedostanou. Referenční
  dokumentace označuje `tools` jako povinné; `copilot help mcp` na 1.0.114 říká, že výchozí
  hodnota je `["*"]`. Když ho vypíšeš, vyhovíš obojímu.

Položka `headers` tu není, takže soubor neobsahuje žádný tajný údaj. Pokud server používá
OAuth, CLI otevře prohlížeč nebo ti řekne, ať spustíš `/mcp auth jira`, a tokeny uloží do
klíčenky operačního systému (podle `copilot help mcp`). Jak se 2N Jira MCP autentizuje, je
otázka na 2N.

## Proč `.mcp.json` v kořenu, a ne `.github/mcp.json`

CLI čte oba. JetBrains plugin čte taky oba, ale ne stejným způsobem:

| Soubor | Copilot CLI | IntelliJ plugin (Copilot agent, 1.19.0+) |
|------|-------------|------------------------------------------|
| `.mcp.json` (kořen repa) | `mcpServers`, nebo holá mapa názvů serverů | `mcpServers`, nebo holá mapa názvů serverů |
| `.github/mcp.json` | `mcpServers` nebo holá mapa; **ignoruje se**, když je ve stejném adresáři `.mcp.json` | definice patří pod `servers` |
| `.vscode/mcp.json` | nečte se | — |

`.mcp.json` v kořenu s `mcpServers` je jediné umístění, které oba klienti čtou stejně
(sloupec JetBrains vychází z odpovědi maintainera, ne z dokumentace; tady netestováno).
Dokumentace GitHubu doporučuje pro commitnutou konfiguraci `.github/mcp.json`; odchylujeme
se od toho jen z tohoto důvodu. Když je
stejný název serveru definovaný na několika místech, vyhrává pozdější zdroj: uživatelská
konfigurace (`~/.copilot/mcp-config.json`), workspace soubory, pluginy, pak
`--additional-mcp-config`.

## Tajné údaje a proč se vyhnout `${VAR}` v `url` a `command`

Nikdy nezapisuj token do souboru, který se dá commitnout. Obvyklé řešení, odkaz `${VAR}`,
má v tomhle prostředí dva problémy:

- **Allow-listy.** Podle dokumentace spravovaný allow-list zablokuje každý server, jehož URL
  nebo příkaz obsahuje nevyhodnocenou proměnnou, „protože klient nemůže server ověřit“.
  `${JIRA_HOST}` v `url`, které na některém stroji není nastavené, se tam změní v blokaci
  politikou.
- **IntelliJ.** Otevřený bug (nahlášený uživateli na pluginu 1.19.2 a 1.20.0) posílá odkazy
  `${VAR}` v `headers` a `env` doslovně, místo aby je vyhodnotil.

Drž tedy `url`, `command` a `args` doslovné a s tajnými údaji zacházej takhle:

1. **OAuth**, pokud ho server podporuje. V souboru pak není vůbec nic tajného.
2. **Statický token mimo repo.** Přidej server do své uživatelské konfigurace:
   ```bash
   copilot mcp add --transport http --header "Authorization: Bearer <token>" jira <url>
   ```
   Zapíše se to do `~/.copilot/mcp-config.json`. Nedefinuj `jira` zároveň v `.mcp.json`:
   workspace položka by vyhrála.
3. **`${NAME}` v `headers`** v CLI funguje (podle dokumentace), ale je to přesně případ,
   který rozbíjí bug v IntelliJ.

`copilot mcp get <name>` maskuje hodnoty hlaviček a env, pokud nepředáš `--show-secrets`.

## Dotaz na důvěru

Workspace MCP servery se načtou až poté, co složce dáš důvěru. Při prvním spuštění ve
složce se CLI zeptá:

```
Yes                                                  Trust it for this session.
Yes, and remember this folder for future sessions    Add it to `trustedFolders` in config.json.
No                                                   Exit.
```

Stejná odpověď platí i pro hooky a nastavení pluginů v repu. Položka `stdio` je proces,
který na tvém stroji spustí soubor z repa, takže si `.mcp.json` přečti, než odpovíš. Běh
`copilot -p` v nedůvěryhodné složce workspace servery přeskočí; `--trust-folder` dá složce
důvěru pro ten jeden běh.

Důvěra není oprávnění. Každé volání MCP nástroje dál prochází pravidly oprávnění, kde se
server adresuje jako `jira` (všechny jeho nástroje) nebo `jira(tool_name)` (jeden nástroj),
například `--deny-tool='jira(tool_name)'`.

## Jak vypadá blokace politikou

Tyhle hlášky se nauč. Když některou uvidíš, přestaň upravovat JSON: konfigurace je v pořádku
a výsledek může změnit jen administrátor.

Enterprise allow-list (znění z dokumentace):

```
MCP server "SERVER-NAME" was blocked by your enterprise "ENTERPRISE-NAME".
Contact your enterprise administrator to add this server to the allowlist.
```

Politika registru nebo organizace (znění z `copilot help mcp` na 1.0.114):

```
N MCP servers were blocked by policy: 'name' (reason)
```

s důvodem typu `Not found in registry <url>`. MCP třetích stran vypnuté pro organizaci
(znění z hlášení uživatele na CLI 1.0.101; na tvé verzi se může lišit):

```
Third-party MCP servers are disabled by your organization's Copilot policy. Only built-in servers are available.
```

Ještě dvě fakta ze stejné nápovědy: když se politiku nepodaří stáhnout, zablokuje se každý
server kromě vestavěných, takže problém se sítí nebo proxy může vypadat jako blokace
politikou. A `copilot mcp list` ukazuje jen konfiguraci. Živý stav (`connected`,
`failed: <reason>`, `disabled`) je v `/mcp list` uvnitř session.

## Přidej schválený server, krok za krokem

1. **Zjisti od 2N tři věci:** název serveru, URL a způsob autentizace.
2. **Vytvoř soubor:** `cp .mcp.json.example .mcp.json`, pak nahraď URL (a název, pokud 2N
   používá jiný).
3. **Zkontroluj JSON:** `jq . .mcp.json`.
4. **Načti ho.** Spusť `copilot` a dej složce důvěru, nebo v už otevřené session spusť
   `/mcp reload`.
5. **Ověř:** `/mcp list` ukazuje `jira` jako připojený a `/mcp get jira` vypíše jeho
   nástroje. Pokud tě CLI vyzve k přihlášení, spusť `/mcp auth jira`.
6. **Použij ho** (v tomto repu netestováno; není tu Jira server, proti kterému by se dalo
   testovat):
   > *„Vypiš moje otevřené Jira issues.“*
7. **`.mcp.json` v tomhle workshopovém repu necommituj.** URL patří 2N. Ve skutečném 2N
   projektu právě commit zajistí, že server dostane každý kolega po jediném dotazu na důvěru.

**Frontend vývojáři:** pokud 2N schválilo Figma MCP, přidává se stejným způsobem. Obrázkový
vstup je vypnutý, takže pracuj s textovými specifikacemi.

## Vyzkoušej demo

Demo používá jen vestavěný server a GitHub issues tohoto repa. Žádný nástroj pro zápis není
potřeba. Tvůj klon potřebuje svůj GitHub remote. Pokud repo ještě žádné issues nemá, nejdřív
jedno založ ve webovém rozhraní.

1. Spusť `copilot` v kořenu repa a zadej `/mcp list`. `github-mcp-server` je připojený.
2. Spusť `/mcp get github-mcp-server` a spočítej nástroje. S nainstalovaným `gh` jich je šest
   a žádný z nich nečte issues.
3. Ukonči session a spusť ji znovu se dvěma čtecími nástroji:
   ```bash
   copilot --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
   ```
   `/mcp get github-mcp-server` teď ukazuje přesně tyhle dva.
4. Zeptej se:
   > *„Vypiš otevřená issues v tomto repozitáři nástrojem list_issues. U každého uveď soubor a funkci v této codebase, kterých se nejspíš týká.“*

   Časová osa ukáže volání `github-mcp-server-list_issues` a po něm čtení lokálních souborů.
5. **Pull request vytvoř přes `/pr create`, ne MCP nástrojem pro zápis.** Dej změnu na
   branch (demo v [Ukázce 5](05-agents.cs.md) ti jednu dá), pak spusť `/pr create`. Podle
   dokumentace Copilot otevře pull request tvým jménem s tebou jako autorem a `/pr`
   potřebuje repozitář hostovaný na GitHubu. Podle changelogu plan mode vytvoření pull
   requestu blokuje. V tomto repu netestováno.

Co bylo otestováno: počty nástrojů, oba přepínače a volání `list_issues` v režimu `-p` proti
veřejnému repozitáři, které proběhlo bez jakéhokoli allow pravidla. Vlastní issues tohoto
repa otestována nebyla, protože v době psaní návodu nemělo GitHub remote.

## Volitelné parametry

Pole u položky serveru (podle dokumentace):

| Pole | Platí pro | Co dělá |
|-------|-----------|--------------|
| `type` | oba | `local` nebo `stdio` pro proces; `http` nebo `sse` pro vzdálený server |
| `command`, `args` | lokální | Program a argumenty, které se mají spustit |
| `env` | lokální | Prostředí procesu. Podporuje `$VAR`, `${VAR}`, `${VAR:-default}`. Automaticky se dědí jen `PATH` a pár platformních proměnných |
| `cwd` | lokální | Pracovní adresář procesu |
| `url` | vzdálený | Adresa serveru |
| `headers` | vzdálený | HTTP hlavičky, typicky `Authorization` |
| `tools` | oba | `["*"]` nebo seznam názvů nástrojů, které se mají zpřístupnit |
| `timeout` | oba | Timeout pro daný server v milisekundách |

Přepínače při spuštění (z `copilot --help`):

| Přepínač | Co dělá |
|------|--------------|
| `--disable-mcp-server <name>` | Vypne jeden server pro tento běh |
| `--disable-builtin-mcps` | Vypne vestavěné servery pro tento běh |
| `--additional-mcp-config <json>` | Přidá servery pro jednu session: JSON řetězec, nebo `@file` |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|---------|--------|-------|
| **Copilot CLI** | ✅ | `.mcp.json` v kořenu po udělení důvěry složce. Běhy `-p` potřebují důvěryhodnou složku nebo `--trust-folder` |
| **IntelliJ plugin** | ⚠️ | Podle odpovědi maintainera čte Copilot agent `.mcp.json` v kořenu s `mcpServers` od pluginu 1.19.0. Známé otevřené bugy: `${VAR}` v `headers` a `env` se posílá doslovně a `stdio` servery startují v pracovním adresáři IDE, ne v kořenu projektu. Plugin obsahuje starší CLI runtime, takže nepředpokládej stejné chování. Organizační MCP politiky platí i tam. Tady netestováno; viz [návod 12](12-intellij.cs.md) |
| **Copilot cloud agent** | ⚠️ | Neověřeno. Nenašli jsme dokumentaci, podle které by cloud agent četl workspace `.mcp.json`; nespoléhej na to |

## Když něco nefunguje

- **Server chybí v `/mcp list`** → složka není důvěryhodná, JSON je neplatný
  (`jq . .mcp.json`), nebo je klíč nejvyšší úrovně `servers` místo `mcpServers`.
- **„blocked by policy“ nebo „blocked by your enterprise“** → není to chyba konfigurace.
  Pošli název serveru a URL administrátorovi 2N.
- **Všechny servery zablokované naráz, včetně těch, které včera fungovaly** → politiku se
  nejspíš nepodařilo stáhnout. Zkontroluj VPN a proxy, pak restartuj CLI.
- **`github-mcp-server` zmizel** → organizace vypnula politiku MCP (CLI 1.0.112+), nebo jsi
  spustil CLI s `--disable-builtin-mcps`, nebo jsi zadal `/mcp disable github-mcp-server`.
- **Agent používá `gh issue list` místo MCP nástroje** → očekávané chování, když je `gh`
  v `PATH`. Přidej nástroj přes `--add-github-mcp-tool`.
- **Upravil jsi `.mcp.json` a nic se nezměnilo** → `/mcp reload`.
- **Server funguje v terminálu, ale ne v IntelliJ** → hledej `${VAR}` v `headers` nebo
  `env`, nebo relativní cestu v `command`.
- **`/pr create` odmítá** → jsi v plan mode, nebo repo nemá GitHub remote.
- **Vestavěný server nabízí jen webové vyhledávání** → podle `copilot help mcp` je to
  chování v repozitáři, jehož jediný remote je Azure DevOps.

---

Dál: MCP dává agentovi víc nástrojů. Vlastní agenti rozhodují, kdo dostane které nástroje →
[Ukázka 5: Vlastní agenti a delegování](05-agents.cs.md).

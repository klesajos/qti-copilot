> 🌍 Číst v jazyce: [English](05-mcp.md) | **Česky**

# 05 · MCP pod allow-listem

> ⏱ 10 min (5 výklad + 5 demo lektora: cvičení 4, kroky 1 až 3) · Dokumentace: [Adding MCP servers for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers) · [Built-in MCP servers](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-mcp-servers) · [MCP server usage in your company](https://docs.github.com/en/copilot/concepts/enterprise/mcp-management) · Ověřeno na Copilot CLI 1.0.114

## Co je MCP?

MCP (Model Context Protocol) dává agentovi nástroje, které CLI samo nemá. Server je lokální
proces (`local`) nebo vzdálený endpoint (`http`, `sse`). Na začátku session přidá definice svých
nástrojů do kontextu modelu. V pravidlech oprávnění vystupuje jako `name` nebo `name(tool)`.

## Co dělá tahle ukázka

```
(inside the CLI)      ← github-mcp-server: built in, starts at sign-in, nothing to configure
.mcp.json.example     ← the file format, with the approved 2N Jira MCP as the pattern
.mcp.json             ← your copy with the real URL; gitignored
```

2N povoluje MCP servery jen ze schváleného seznamu a provozuje vlastní Jira MCP. Repo proto
záměrně neobsahuje žádný živý server třetí strany: na tvém stroji by byl zablokovaný.

## Vestavěný GitHub MCP server

`copilot mcp list` vypíše `github-mcp-server (http)` pod `Builtin servers:`. Ve výchozím stavu je
jen pro čtení a podmnožina jeho nástrojů závisí na tom, jestli máš `gh` v `PATH`:

- **S `gh`:** 6 nástrojů: `get_file_contents`, `search_code`, `search_users`, `get_copilot_space`,
  `list_copilot_spaces`, `web_search`. Nic pro issues ani pull requesty; agent pouští `gh`.
- **Bez `gh`:** 24 nástrojů: těch šest plus nástroje pro čtení commitů, issues, pull requestů a Actions.

Model vidí každý nástroj jako `github-mcp-server-<tool>`. Dva přepínače podmnožinu na jeden běh rozšíří:

- `--add-github-mcp-tool <tool>`: nahradí podmnožinu přesně těmi nástroji, které vyjmenuješ.
- `--add-github-mcp-toolset <toolset>`: přidá toolset navíc. Toolset může přinést nástroje pro zápis.

Na tenhle server se nevztahují MCP allow-listy ani deny-listy. Je vypnutý, když organizace
vypne politiku „MCP servers in Copilot“ (od CLI 1.0.112).

> 🔷 **Jen Copilot:** GitHub MCP server je vestavěný a spustí se, když se přihlásíš. Claude Code
> vestavěný GitHub server nemá: přidáš ho přes `claude mcp add` a PAT, nebo zapneš plugin.

> 🔷 **Jen Copilot:** `list_copilot_spaces` a `get_copilot_space` čtou [Copilot Spaces](https://docs.github.com/en/copilot/concepts/prompting-and-context/spaces),
> sdílený, ručně vybraný kontext. Claude Code má konektory, ale takové sdílené úložiště kontextu ne.

## Soubor řádek po řádku

CLI čte `.mcp.json` z kořene repa, jakmile je složka důvěryhodná. `.mcp.json.example`:

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

- `mcpServers`: klíč nejvyšší úrovně. S klíčem `servers` z VS Code nenačte CLI nic.
- `jira`: jméno serveru. Je prefixem názvů nástrojů, objevuje se v pravidlech oprávnění
  (`jira(tool)`) a allow-list založený na jménech hledá shodu právě podle něj. Použij přesně to
  jméno, které ti dá 2N.
- `type`, `url`: `http` je vzdálený server; lokální používá `"type": "local"` s `command` a
  `args`. URL napiš doslovně: allow-list zablokuje server s nevyhodnoceným `${VAR}`.
- `"tools": ["*"]`: zpřístupní všechny nástroje; vyjmenuj názvy, ať nepoužité definice nezabírají kontext.
  Položka `headers` chybí, takže v souboru není žádný tajný údaj; statický token patří do tvé uživatelské konfigurace (níže).

## Vytvoř si vlastní, krok za krokem

1. `cp .mcp.json.example .mcp.json`, doplň jméno a URL od 2N, spusť `jq . .mcp.json`.
2. Spusť `copilot` a dej složce důvěru, nebo v otevřené session spusť `/mcp reload`. `/mcp list`
   ukáže `jira` jako `connected`; `/mcp auth jira` tě přihlásí. ⚠️ v tomto repu nespuštěno

## Vyzkoušej demo

1. Spusť `copilot --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read`.
   `/mcp get github-mcp-server` otevře detail serveru: `tools` uvádí přesně tyhle dva; `q` zavře.
2. Prompt:
   > *„Vypiš tři naposledy aktualizovaná otevřená issues veřejného repozitáře github/copilot-cli nástrojem list_issues. Odpověz jen číslem a názvem. Nepoužívej shell.“*
3. Časová osa ukáže jedno volání `github-mcp-server-list_issues`, bez dotazu na schválení, a pak
   tři řádky s číslem a názvem. Demo pro samostudium: na workshopu se ukazuje [cvičení 4](exercises.cs.md).

## Jak vypadá blokace politikou

- `N MCP servers were blocked by policy: 'name' (reason)`, např. `Not found in registry <url>`.
- `MCP server "SERVER-NAME" was blocked by your enterprise "ENTERPRISE-NAME".`

Konfigurace je v pořádku: pošli jméno a URL serveru administrátorovi 2N. Když se politiku
nepodaří stáhnout, zablokuje se každý server kromě vestavěných, takže nejdřív zkontroluj VPN a proxy.

## Volitelné parametry

| Pole / přepínač / příkaz | Co dělá |
|---|---|
| `command`, `args`, `env`, `cwd`; `headers` | Lokální server: program, argumenty, prostředí, pracovní adresář. Vzdálený server: HTTP hlavičky |
| `copilot mcp add --transport http --header "Authorization: Bearer <token>" <name> <url>` | Přidá server do tvé uživatelské konfigurace `~/.copilot/mcp-config.json`, mimo repo. Sem patří statický token: nikdy ho nepiš do `.mcp.json`, který se dá commitnout |
| `--additional-mcp-config <json or @file>` | Servery pro jednu session |

Kompletní reference: [MCP server configuration](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#mcp-server-configuration) · `copilot help mcp`

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|---|---|---|
| ✅ `.mcp.json` v kořenu repa po udělení důvěry složce. Běh `-p` potřebuje `--trust-folder` | ⚠️ Čte `.mcp.json` v kořenu s `mcpServers` od pluginu 1.19.0. `${VAR}` v `headers` a `env` se posílá doslovně ([otevřený bug](https://github.com/microsoft/copilot-intellij-feedback/issues/2125)) | ⚠️ Servery se konfigurují pro každý repozitář zvlášť na GitHub.com; servery GitHub a Playwright jsou ve výchozím stavu zapnuté |

## Copilot vs Claude Code

Stejný mechanismus i soubor: Claude Code taky čte commitnutý `.mcp.json` v kořenu s `mcpServers`
a uživatelské servery přidává přes `claude mcp add`. Rozdíly jsou ty dvě poznámky výše.

## Když něco nefunguje

- **Server chybí v `/mcp list`** → neplatný JSON (`jq . .mcp.json`), `servers` místo `mcpServers`, nebo u běhu `-p` chybí `--trust-folder`.
- **`github-mcp-server` zmizel** → organizace vypnula MCP, nebo jsi spustil `/mcp disable github-mcp-server`.

Dál: [06 · Vlastní agenti](06-agents.cs.md)

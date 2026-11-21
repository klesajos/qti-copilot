> 🌍 Číst v jazyce: [English](cheatsheet.md) | **Česky**

# Tahák Copilot CLI

> ✅ Ověřeno proti Copilot CLI 1.0.114 (2026-11-21). CLI vychází skoro denně; když tu něco nesedí, spusť `copilot help`.

Číslované návody vysvětlují, jak Copilot CLI **rozšířit** ([instrukce](01-custom-instructions.cs.md),
[skills](02-skills.cs.md), [hooky](03-hooks.cs.md), [MCP](04-mcp.cs.md), [agenti](05-agents.cs.md),
[pluginy](06-plugins.cs.md), [orchestrace](07-orchestration.cs.md),
[oprávnění](08-permissions-sandbox.cs.md), [evaly](09-validate-eval.cs.md)). Tahle stránka je o tom,
jak ho **ovládat**: přepínače, slash příkazy, klávesy, umístění souborů, události hooků a pravidla oprávnění.

Řádky bez značky pocházejí z vlastní nápovědy CLI ve verzi 1.0.114 (`copilot --help`, `copilot help <topic>`,
`copilot <command> --help`). **[T]** = spuštěno v tomto repozitáři. **[D]** = podle dokumentace; v tomto repu netestováno.

## Spouštěcí přepínače (`copilot ...`)

| Skupina | Přepínač | Co dělá |
|---------|----------|---------|
| **Prompt a výstup** | `copilot` | Interaktivní session v aktuální složce |
| | `-i "<prompt>"` / `--interactive` | Interaktivní session, která nejdřív spustí tento prompt |
| | `-p "<prompt>"` / `--prompt` | Neinteraktivně: spustí prompt a po dokončení skončí |
| | `-s` / `--silent` | Vypíše jen odpověď agenta, bez statistik |
| | `--output-format json` | JSONL, jeden objekt na řádek (výchozí `text`) |
| | `--share [path]`, `--share-gist` | Po běhu `-p` vyexportuje session do Markdownu (výchozí `./copilot-session-<id>.md`) nebo do tajného gistu |
| | `--usage-output-file <file>` | Konečná spotřeba jako JSON: kredity, premium requesty, tokeny po modelech a po agentech |
| | `-C <directory>` | Změní pracovní adresář dřív než cokoli jiného |
| **Oprávnění** | `--allow-tool='<rule>'` | Spouští odpovídající nástroje bez ptaní. Platí pro tento běh |
| | `--deny-tool='<rule>'` | Blokuje odpovídající nástroje. Vyhrává nad každým allow, i nad `--allow-all` a `--yolo` |
| | `--allow-all-tools` | Žádné potvrzování nástrojů. Proměnná prostředí `COPILOT_ALLOW_ALL`; přesná hodnota `true` navíc důvěřuje pracovnímu adresáři |
| | `--add-dir <dir>`, `--allow-all-paths`, `--disallow-temp-dir` | Přidá adresář (načte i jeho `.github/skills` a `.github/agents`) / vypne kontrolu cest / vyřadí dočasný adresář |
| | `--allow-url`, `--deny-url`, `--allow-all-urls` | Přístup k URL a doménám. Deny vyhrává. Pravidla mají výchozí `https://` |
| | `--allow-all` / `--yolo` | `--allow-all-tools --allow-all-paths --allow-all-urls` |
| | `--available-tools`, `--excluded-tools` | Které nástroje model vůbec vidí (není to schvalovací pravidlo) |
| | `--assisted-approval` | Požadavky na oprávnění kontroluje bezpečnostní posuzovatel. Pravděpodobnostní, není to bezpečnostní hranice |
| | `--trust-folder` | Důvěřuje konfiguraci pracovního adresáře pro jednu novou session `-p`. Nic neukládá, nic neschvaluje |
| | `--sandbox` | Pustí shellové příkazy této session v sandboxu (viz `copilot help sandbox`; v `copilot --help` uvedeno není) |
| | `--secret-env-vars=A,B` | Odebere tyto proměnné z prostředí shellu a MCP serverů; v některých výstupech maskuje jejich hodnoty |
| **Agenti a modely** | `--agent <agent>` | Spustí session jako vlastního agenta. Agent z pluginu je `<plugin>:<agent>` **[T]** |
| | `--model <model-id>` | Vybere model. S `auto` vybírá Copilot |
| | `--reasoning-effort <level>` | `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`; závisí na modelu |
| | `--mode interactive` / `plan` / `autopilot` | Počáteční režim agenta; zkratky `--plan`, `--autopilot`. `--max-autopilot-continues <n>` (výchozí 5) |
| | `--fleet` | Spustí prompt s paralelními subagenty; kombinuj s `-i`, `-p` nebo se stdin z roury |
| | `--max-ai-credits <n>` | Strop kreditů pro session (minimum 30, měkký) |
| | `--no-custom-instructions` | Přeskočí `AGENTS.md` a související soubory s instrukcemi |
| **Sessions** | `--continue` | Obnoví poslední session, přednostně z této branch, repozitáře nebo adresáře |
| | `-r` / `--resume [value]` | Obnoví podle ID session, prefixu ID (7+ hex znaků), ID úkolu nebo přesného jména. Bez hodnoty otevře výběr |
| | `--session-id <id>` | Obnoví podle ID, nebo nastaví UUID nové session |
| | `-n` / `--name <name>` | Pojmenuje novou session |
| **MCP a pluginy** | `--additional-mcp-config <json>` / `@file` | MCP servery navíc pro tuto session; lze opakovat |
| | `--disable-mcp-server <name>`, `--enable-mcp-server <name>` | Vypne / zapne jeden server pro tento běh |
| | `--disable-builtin-mcps` | Vypne vestavěné servery. `copilot --help` jmenuje `github-mcp-server` a `githubiq`; `copilot mcp list` na testovacím stroji vypsal `computer-use` a `github-mcp-server` |
| | `--add-github-mcp-toolset`, `--add-github-mcp-tool`, `--enable-all-github-mcp-tools` | Rozšíří vestavěný GitHub server. Kterýkoli z nich ho přepne na čtení i zápis |
| | `--plugin-dir <dir>` | Načte plugin z lokálního adresáře; lze opakovat |
| **Různé** | `--experimental` / `--no-experimental` | Experimentální featury (extensions, dynamické workflows) |
| | `--log-level <level>`, `--log-dir <dir>` | Logování; výchozí adresář `~/.copilot/logs/` |
| | `--no-auto-update` | Nestahuje aktualizace CLI |
| | `--acp` | Spustí se jako Agent Client Protocol server (Zed, JetBrains) |

| Podpříkaz (shell, bez session) | Co dělá |
|--------------------------------|---------|
| `copilot help [topic]` | Témata: `acp`, `billing`, `commands`, `config`, `environment`, `extensions`, `input`, `limits`, `logging`, `lsp`, `mcp`, `monitoring`, `network`, `parallel-work`, `permissions`, `providers`, `providers-env`, `providers-local`, `sandbox`, `sessions`, `timeline` |
| `copilot init` | Zanalyzuje repo a zapíše `.github/copilot-instructions.md` |
| `copilot login` | Přihlášení. Token v `COPILOT_GITHUB_TOKEN`, `GH_TOKEN` nebo `GITHUB_TOKEN` (v tomto pořadí) má přednost před uloženými přihlašovacími údaji |
| `copilot config [key] [value]` | Přečte nebo nastaví jedno nastavení. `--list`, `--json`, `--rm`, `--repo`, `--local` |
| `copilot instruction list [--json]` | Zdroje instrukcí, které by tento proces načetl |
| `copilot skill list` / `add` / `remove` / `enable` / `disable` | Skills. `add --project` zapisuje do `.github/skills` |
| `copilot plugin install` / `uninstall` / `update` / `list` / `enable` / `disable` | Pluginy. Zdroj: `plugin@marketplace`, `owner/repo`, `owner/repo:path`, git URL |
| `copilot plugin marketplace add` / `remove` / `list` / `browse` / `update` | Marketplaces. `awesome-copilot` je vestavěný |
| `copilot mcp list` / `get` / `add` / `remove` / `enable` / `disable` | MCP servery. `add` zapisuje do `~/.copilot/mcp-config.json`; `list` a `get` ukazují konfiguraci, ne živý stav |
| `copilot workflow run <name>` | Spustí registrovaný dynamický workflow; vyžaduje experimentální režim |
| `copilot lsp list`, `copilot sandbox ca <cmd>`, `copilot update`, `copilot completion` | Language servery, certifikační autorita sandbox proxy, aktualizace, skript pro doplňování v shellu |

## Programatický režim (`copilot -p`)

Viz [Ukázka 11](11-programmatic-ci.cs.md).

| Přepínač | Proč na něm ve skriptu záleží |
|----------|-------------------------------|
| `-p "<prompt>"` | Spustí jednou a skončí. Funguje i slash vyvolání: `copilot -p "/2048-dev:build-test ..."` **[T]** |
| `--allow-tool='<rule>'` / `--allow-all-tools` | Na dotaz nemá kdo odpovědět. Neschválené volání selže s `Permission denied because no interactive user response was available.` **[T]** |
| `--trust-folder` | Bez něj běh `-p` v nedůvěryhodné složce přeskočí workspace MCP servery a hooky repozitáře. S ním se hooky repa načtou **[T]** |
| `--no-ask-user` | Agent nemůže otevřít formulář s otázkou |
| `-s` | Na stdout jen závěrečná odpověď **[T]** |
| `--output-format json` | Proud událostí v JSONL na stdout |
| `--max-ai-credits <n>`, `--usage-output-file <file>` | Strop kreditů pro běh; spotřeba jako JSON, i s `-s` |

- Závěrečné shrnutí jde na stderr. S `--silent` ani `--output-format json` se nevypisuje.
- Paměť je v bězích `-p` vypnutá (zapne ji `--enable-memory`). Projektové extensions se přeskakují, pokud není `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS=true`.
- Běh `-p` čeká až 600 s na agenty a shellové příkazy na pozadí (`COPILOT_TASK_WAIT_TIMEOUT_SECONDS`).

**Záznamy JSONL** **[T]**. Každý řádek je `{type, data, id, parentId, timestamp, ephemeral?}`.

| `type` | Užitečná pole |
|--------|---------------|
| `session.start` | `data.copilotVersion`, `data.context.cwd`, `gitRoot`, `branch` |
| `session.model_change`, `session.auto_mode_resolved` | `data.newModel`; `data.chosenModel`, když je model `auto` |
| `session.skills_loaded`, `session.custom_agents_updated` | `data.skills`; `data.agents`, `data.warnings`, `data.errors` |
| `user.message`, `assistant.message` | `data.content` |
| `tool.execution_start` | `data.toolName`, `data.arguments` |
| `tool.execution_complete` | `data.success`, `data.result.content`, `data.error.message` |
| `subagent.started` / `completed` / `failed` | `data.agentName` |
| `session.warning` | Varování z hooků chodí sem s `warningType: "hook"` |
| `session.usage_checkpoint` | `data.totalNanoAiu` |
| `result` (poslední řádek) | `exitCode`, `usage.premiumRequests`, `usage.totalApiDurationMs`, `usage.sessionDurationMs`, `usage.codeChanges.{linesAdded, linesRemoved, filesModified}` |

- Záznam `skill.invoked` neexistuje. Použití skillu je `tool.execution_start` s `toolName: "skill"` a `arguments: {"skill": "board-tests"}`.
- Delegování na agenta je `toolName: "task"` s `arguments.agent_type` (`"2048-dev:game-explorer"`, vestavěný `"explore"`).
- Jen závěrečná odpověď: `jq -rs '[.[] | select(.type == "assistant.message") | .data.content] | join("\n")' events.jsonl`

## Slash příkazy

Seskupené jako v `copilot help commands`. Aktuální seznam ukáže `/help` v session.

| Skupina | Příkaz | Co dělá |
|---------|--------|---------|
| **Prostředí agenta** | `/init` | Vytvoří nebo aktualizuje instrukce; text za `/init` určuje, co se zapíše |
| | `/agent [name]` | Procházení a výběr agentů |
| | `/skills` | Správa skills. `/skills reload` znovu načte adresáře se skills **[D]** |
| | `/mcp` | `list`, `get <server>`, `reload`, `enable` / `disable <server>`, `auth <server>` |
| | `/plugin` | Správa pluginů a marketplaces |
| **Agenti, subagenti** | `/model` | Model pro tuto session. `--repo` / `--local` nastaví výchozí model repa, `plan` model pro plan režim |
| | `/delegate` | Pošle session na GitHub; Copilot otevře PR. `--base` vybere cílovou branch |
| | `/fleet [prompt]` | Rozdělí práci na todo položky a ty nezávislé spustí jako paralelní subagenty. Bez promptu: projde otevřené todo položky |
| | `/autopilot` | Přepne autopilot, nebo nastaví cíl s `--max-ai-credits` |
| | `/tasks` | Běžící subagenti a shellové příkazy na pozadí; `x` zastaví vybraný |
| **Kód** | `/diff` | Revize změn provedených v aktuálním adresáři |
| | `/review` | Pustí na změny agenta pro code review |
| | `/security-review` | Proskenuje necommitnuté změny, nebo diff branch, když je strom čistý |
| | `/rubber-duck` | Nezávislá kritika aktuální práce |
| | `/pr`, `/ide` | Pracuje s pull requestem dané branch; připojí se k workspace v IDE |
| | `/lsp` | `list`, `test <name>`, `logs`, `reload` |
| **Oprávnění** | `/permissions` | Přepne režim oprávnění: `manual`, `assisted`, `allow-all` |
| | `/allow-all` | Zapne všechna oprávnění (nástroje, cesty, URL) |
| | `/sandbox` | Stav a dialog s politikou. `enable`, `disable`, `policy`, `ca create` / `trust` / `rotate` / `remove` |
| | `/add-dir`, `/list-dirs`, `/cwd` | Přidá povolený adresář / vypíše je / ukáže nebo změní pracovní adresář |
| | `/reset-allowed-tools` | Smaže schválení ze session, vypne allow-all, smaže uložená schválení pro toto umístění |
| **Session** | `/new`, `/clear` | `/new` spustí session a tu aktuální nechá na pozadí; `/clear` ji zahodí. `/new worktree` začne v novém git worktree |
| | `/resume [value]` | Přepne session podle ID, ID úkolu nebo jména. Alias `/continue` |
| | `/fork [name]` | Zkopíruje session a přepne na kopii. `/fork worktree` to udělá v novém worktree |
| | `/worktree`, `/move` | Přesune session do nového worktree a necommitnuté změny nechá / vezme s sebou |
| | `/rewind` | Obnoví dřívější kolo: jen konverzaci, nebo konverzaci i soubory. Nejde vrátit zpět. Taky `/undo`, nebo `Esc Esc` na prázdném promptu |
| | `/context` | Využití kontextového okna podle kategorií |
| | `/compact [focus]` | Shrne historii, aby uvolnil kontext |
| | `/usage` | Spotřeba session: změny, kredity, tokeny po modelech, ukazatele tarifu a rate limitů |
| | `/session` | `id`, `info`, `plan`, `checkpoints [n]`, `cleanup`, `prune --older-than <days>`, `delete <id> --yes` |
| | `/share` | `file [path]`, `html [path]`, `gist`, `research`, `link` |
| | `/remote` | `on`, `off`, `show`: řízení session z webu nebo mobilu GitHubu |
| | `/rename`, `/copy` | Přejmenuje session; zkopíruje poslední odpověď do schránky |
| **Nápověda** | `/help`, `/version`, `/update`, `/changelog` | Nápověda, verze, aktualizace, changelog (`summarize` pro AI shrnutí) |
| | `/instructions` | Zobrazení a přepínání souborů s vlastními instrukcemi |
| | `/diagnose` | Analyzuje logy session, včetně toho, proč požadavek na oprávnění potřeboval schválení |
| | `/memory` | Stav paměti; `on` / `off` |
| **Ostatní** | `/plan` | Vytvoří implementační plán před kódováním |
| | `/env` | Co je načteno: instrukce, MCP servery, skills, agenti, hooky, pluginy, LSP, extensions |
| | `/limits` | Limity session. `set max-ai-credits <n>`, `unset` |
| | `/settings`, `/config` | UI nastavení, nebo zobrazení / nastavení / `unset` jednoho klíče. `--repo` / `--local` míří na nastavení repa |
| | `/subagents` | Model a nastavení pro jednotlivé subagenty; zapnutí nebo vypnutí subagenta |
| | `/ask` | Vedlejší otázka, která se nepřidá do historie |
| | `/research`, `/refine` | Hloubkový research s hledáním na GitHubu a webovými zdroji; přepíše hrubý prompt na jasný |
| | `/keep-alive` | Zabrání uspání: `on`, `off`, `busy`, nebo doba, například `30m` |
| | `/login`, `/logout`, `/user`, `/restart`, `/exit` | Účty; restart; ukončení (`/exit print` vypíše session) |

V seznamu jsou dál: `/statusline` (`/footer`), `/theme`, `/terminal-setup`, `/experimental`, `/feedback`, `/app`, `/vim`, `/voice`, `/ahp`, `/chronicle`, `/collect-debug-logs`, `/computer`, `/environments`, `/index`, `/search`. `/extensions` je popsaný v `copilot help extensions` (experimentální).

## Klávesové zkratky a vstupní prefixy

| Klávesa | Co dělá |
|---------|---------|
| `Enter`, když agent pracuje | Usměrnění: zpráva se přidá do běžícího kola |
| `Ctrl+Q` (`Ctrl+Enter` s protokolem kitty) | Zařadí zprávu do fronty jako nové kolo |
| `Ctrl+C` | Zastaví kolo a zahodí frontu. Na prázdném nečinném promptu varuje; druhé stisknutí ukončí |
| `Esc Esc` (do 0,5 s) | Zruší nebo přeruší; na prázdném nečinném promptu otevře `/rewind` |
| `Esc` v dotazu na oprávnění | Zamítne a zastaví kolo |
| `Ctrl+D` na prázdném promptu | Okamžitě ukončí |
| `Shift+Enter`, `Alt+Enter`, `Ctrl+J` | Nový řádek. `Ctrl+J` funguje v každém terminálu; `/terminal-setup` opraví `Shift+Enter` |
| `Ctrl+G` | Otevře prompt v `$COPILOT_EDITOR`, `$VISUAL` nebo `$EDITOR` |
| `Up` / `Down`, `Ctrl+R` | Historie promptů; zpětné hledání |
| `Ctrl+S` | Odloží rozepsaný text; znovu na prázdném promptu ho vrátí |
| `Ctrl+O` na prázdném promptu | Rozbalí nebo sbalí všechny položky časové osy |
| `Ctrl+T` | Zobrazí nebo skryje shrnutí uvažování |
| `Left` na prázdném promptu | Otevře postranní panel Sessions |
| `?` na prázdném promptu | Vypíše zkratky |

Zkratky nejdou přemapovat; žádné nastavení klávesových zkratek neexistuje.

| Prefix | Co dělá |
|--------|---------|
| `/` | Slash příkaz nebo skill: `/board-tests`, `/2048-dev:build-test` **[T]** |
| `!` | Spustíš shellový příkaz sám. Příkaz i výstup se přidají do konverzace |
| `@file` | Zmínka souboru. Výběr skrývá soubory z gitignore, pokud `respectGitignore` není `false` |
| samotný `$` a pak `Enter` | Otevře tvůj interaktivní shell v adresáři session; `exit` tě vrátí |

## Kde leží soubory

Uživatelské cesty jsou relativní k `~/.copilot` (`$COPILOT_HOME` ho přesune).

| Co | Repozitář | Uživatel |
|----|-----------|----------|
| Instrukce | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `AGENTS.md` | `copilot-instructions.md`, `instructions/*.instructions.md` |
| Skills | `.github/skills/<name>/SKILL.md`, `.agents/skills/` | `skills/`, `~/.agents/skills/`, nastavení `skillDirectories` |
| Agenti | `.github/agents/<name>.agent.md` | `agents/` |
| Hooky | `.github/hooks/*.json`, nebo `hooks` v `settings.json` repa | `hooks/`, nebo `hooks` v `settings.json` |
| MCP | `.mcp.json` nebo `.github/mcp.json` (klíč nejvyšší úrovně `mcpServers`) | `mcp-config.json` |
| Pluginy | `extraKnownMarketplaces` + `enabledPlugins` v `.github/copilot/settings.json`; `marketplace.json` | `installed-plugins/` |
| Nastavení | `.github/copilot/settings.json`, `.github/copilot/settings.local.json` | `settings.json`; `config.json` je stav CLI (`trustedFolders`) |
| LSP, extensions | `.github/lsp.json`, `.github/extensions/<name>/extension.mjs` | `lsp-config.json`, `extensions/<name>/extension.mjs` |
| Uložená schválení | nic | `permissions-config.json` |
| Sessions, logy | nic | `session-state/<id>/` (`events.jsonl`, `plan.md`, `session.db`), `logs/` |

- CLI čte taky `CLAUDE.md`, `GEMINI.md`, `.claude/rules/**/*.md`, `.claude/skills/`, `.claude/agents/`, `.claude/commands/` a hooky v `.claude/settings.json`. Tohle repo nemá `.claude/` ani `CLAUDE.md`, takže se nic nenačítá dvakrát. Osobní `~/.claude` se nečte.
- `.vscode/mcp.json` se nečte. Zkopíruj ho do `.mcp.json` a přejmenuj `servers` na `mcpServers`.
- Workspace MCP servery, pluginy repa a projektové extensions se načtou, až když složce důvěřuješ.
- Rozložení pluginu v tomhle repu: `plugins/2048-dev/plugin.json`, `skills/<name>/SKILL.md`, `com.github.copilot/agents/*.agent.md`. S nastavením repa uvedeným výše a důvěryhodnou složkou se plugin načte bez instalačního kroku **[T]**. `copilot plugin list --json` mimo session ho neukáže **[T]**.
- Znovunačtení: instrukce potřebují novou session **[D]**; skills `/skills reload` **[D]**; agenti přidaní do `.github/agents/` se od verze 1.0.109 načtou i v běžící session **[D]**; MCP `/mcp reload`; LSP `/lsp reload`.

## Klíče frontmatteru

Klíče agentů jsou v kebab-case. camelCase se ignoruje s varováním: `unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList` **[T]**.

| Soubor | Klíč | Význam |
|--------|------|--------|
| `*.instructions.md` | `applyTo` | Glob, např. `"engine/**/*.kt"`. Vypisuje ho `copilot instruction list --json` **[T]**. Tělo se doručí, když agent odpovídající soubor čte (**[T]**, viděno u `view`) nebo upravuje **[D]** |
| | `excludeAgent` | `"code-review"` nebo `"cloud-agent"` **[D]** |
| `SKILL.md` | `name`, `description` | Povinné; max. 64 a 1024 znaků **[D]**. Prompt, který odpovídá popisu, skill spustí, aniž ho jmenuje **[T]** |
| | `argument-hint` | Nápověda zobrazená ve výběru skillů **[D]** |
| | `allowed-tools` | Nástroje předem schválené, dokud je skill aktivní; není to omezení **[D]** |
| | `user-invocable` | `/name` dostupné uživateli; výchozí `true` **[D]** |
| | `disable-model-invocation` | Zastaví automatické použití; výchozí `false` **[D]** |
| `*.agent.md` | `name`, `description` | Načtou se bez varování **[T]** |
| | `tools` | Aliasy `read`, `search`, `edit`, `execute`, `agent`, `web`, `todo` **[D]**. `["read", "search"]` dalo přesně `view`, `rg`, `glob`, `sql`, `skill` **[T]** |
| | `strict-tools-list` | Jen vyjmenované skupiny nástrojů **[D]**. S `--agent` na verzi 1.0.114 žádný pozorovatelný rozdíl **[T]** |
| | `include-custom-instructions` | Subagent dostane i instrukce repozitáře **[D]** |
| | `model`, `model-policy` | Preferovaný model; `model-policy: required` odmítne náhradu **[D]**. `model-policy` se načte bez varování **[T]** |
| | `reasoning-effort` | Effort pro tohoto agenta **[D]**. Načte se bez varování **[T]** |
| | `mcp-servers`, `hooks` | MCP servery a hooky s platností jen pro agenta **[D]** |

Skill z pluginu je `<plugin>:<skill>` a agent z pluginu je `<plugin>:<agent>` **[T]**.

## Události hooků

Tvar souboru: `{"version": 1, "hooks": {"<event>": [{"type": "command", "bash": "...", "cwd": ".", "timeoutSec": 30, "matcher": "..."}]}}`.
Názvy událostí jsou v camelCase. Každý payload má `sessionId`, `timestamp`, `cwd` **[T]**. Viz [Ukázka 3](03-hooks.cs.md).

| Událost | Kdy a co payload přidává | Co umí její výstup |
|---------|--------------------------|--------------------|
| `sessionStart` | Session začíná. `source`, `initialPrompt` **[T]** | `{"additionalContext": "..."}` se dostane k modelu **[T]** |
| `userPromptSubmitted` | Odešleš prompt. `prompt` **[T]** | Použij ji k logování. Dokumentace a changelog se neshodnou, jestli se její výstup použije; tady netestováno |
| `userPromptTransformed` | Nese `prompt` a `transformedPrompt` **[D]** | `{"modifiedTransformedPrompt": "..."}` nahradí to, co model dostane **[D]** |
| `preToolUse` | Před spuštěním nástroje. `toolCallId`, `toolName`, `toolArgs` **[T]**. Matcher na název nástroje | `{"permissionDecision": "deny", "permissionDecisionReason": "..."}` zablokuje volání, i s `--allow-tool='shell'` **[T]**. Taky `allow`, `ask`, `modifiedArgs` **[D]** |
| `permissionRequest` | Před enginem pravidel oprávnění; ne pro čtení **[D]** | `{"behavior": "allow"}` nebo `"deny"`, plus `message`, `interrupt` **[D]** |
| `postToolUse` | Po úspěšném volání nástroje. Přidává `toolResult: {resultType, textResultForLlm}` **[T]** | `additionalContext`, `modifiedResult` **[D]** |
| `agentStop` | Agent dokončí své kolo. `transcriptPath`, `stopReason`, `stop_hook_active` **[T]** | `{"decision": "block", "reason": "..."}` pošle agenta zpět; `reason` dorazí jako další zpráva uživatele **[T]**. Po 8 blokováních za sebou stejně skončí **[D]** |
| `subagentStart`, `subagentStop` | Subagent začíná nebo končí. Matcher na jméno agenta **[D]** | `subagentStop`: `decision` + `reason`, `modifiedResponse` **[D]** |
| `sessionEnd` | Session končí. `reason` **[T]** | Nic ověřeného |
| `postToolUseFailure`, `preCompact`, `errorOccurred`, `notification` | Uvedené v referenci hooků **[D]** | Nic ověřeného; viz reference |

| Návratový kód | Účinek |
|---------------|--------|
| `0` | stdout se parsuje jako jeden JSON dokument. Prázdný nebo neplatný JSON znamená výchozí chování **[D]** |
| `2` | Varování se zobrazeným stderr; u `preToolUse` a `permissionRequest` znamená deny **[D]**. U `agentStop` neblokuje: objeví se jako `session.warning` **[T]** |
| jiný nenulový | Zaloguje se a přeskočí. Výjimka: `preToolUse` zamítne (fail-closed) **[D]** |
| timeout | Hook je zabit a běh pokračuje, jako by neběžel, u každé události **[D]** |

- `matcher` je regex, který musí odpovídat celé hodnotě, například `bash|powershell` **[D]**. Tohle repo matchuje úpravy přes `edit|create|str_replace_editor|apply_patch`.
- `toolArgs` je JSON objekt u `bash` (`{"command": "...", "description": "..."}`) a surový řetězec s patchem u `apply_patch` **[T]**. Modely z rodiny GPT používají `apply_patch` a občas zapisují soubory přes přesměrování v shellu, které žádný matcher na úpravy nevidí **[T]**.
- Procesy hooků běží v kořeni repozitáře **[T]**. CLI nastavuje `COPILOT_PROJECT_DIR` (taky `CLAUDE_PROJECT_DIR`), `COPILOT_HOOK_DIR`, `COPILOT_HOOK_DEPTH` a `COPILOT_CLI=1`.
- Hooky pod názvy událostí z Claude Code (`PreToolUse`, `Stop`, ...) běží taky a dostávají místo toho `session_id`, `tool_name`, `tool_input`.
- Vypínač: `disableAllHooks` v nastavení. Spravované `allowManagedHooksOnly` nebo `strictPluginOnlyCustomization` umí hooky repozitáře zablokovat **[D]**.

## Pravidla oprávnění

Pravidlo má tvar `kind(argument)`; argument je nepovinný. Plné znění: `copilot help permissions`. Viz [Ukázka 8](08-permissions-sandbox.cs.md).

| Vzor | Čemu odpovídá |
|------|---------------|
| `shell` / `shell(command)` | Každý shellový příkaz / jeden příkaz. Nástroje jako `git`, `gh`, `npm`, `gradle` se matchují i s prvním podpříkazem: `shell(git push)`, `shell(gh pr)` |
| `shell(command:*)` | Ten příkaz a cokoli za ním: `shell(git:*)` odpovídá `git push`, ne `gitea` |
| `write` / `write(path)` | Vytváření a úpravy souborů. Relativní cesta se porovnává podle koncových částí: `write(.env)` je jakýkoli `.env`. Globy `*`, `?`, `**`; negace `!` není |
| `read` / `read(path)` | Čtení souborů vestavěnými nástroji; stejné porovnávání cest |
| `<mcp-server>` / `<mcp-server>(tool)` | Všechny nástroje MCP serveru / jeden nástroj |
| `url(domain-or-url)` | Přístup k URL ze shellu a nástrojů web-fetch, např. `url(https://*.github.com)` |
| `memory` | Požadavky na uložení paměti |

| Otestováno v tomto repu **[T]** | Výsledek |
|---------------------------------|----------|
| `--allow-tool='shell(./gradlew:*)'` | ✅ povolí `./gradlew :engine:test` |
| `--allow-tool='shell(gradlew:*)'` | ❌ neodpovídá `./gradlew ...` |
| `--allow-tool='shell(./gradlew test)'` | ❌ nepokrývá `./gradlew :engine:test` |
| `--allow-tool='shell(npm test)'`, `'shell(npm:*)'` | ✅ obojí povolí `cd web && npm test` |
| `--deny-tool='read(.env)'` | ⚠️ zablokuje nástroj `view`, ale `cat .env` v shellu obsah stejně vrátil. Tu díru zavírá hook `protect-secrets.sh` |

- Deny vyhrává nad každým allow. Pravidla z přepínačů platí po dobu běhu. „Yes, and don't ask again“ se ukládá pro repozitář nebo adresář do `~/.copilot/permissions-config.json`.
- Příkazy rozpoznané jako read-only běží bez ptaní. V autopilotu a v bězích `-p` je požadavek, který by vyvolal dotaz, zamítnut.
- Allow-all se pořád zastaví na: pravidlech `--deny-tool`, příkazu, který žádá o opuštění sandboxu, pravidlech organizace a `permissions.disableBypassPermissionsMode: "disable"`.
- Přístup k souborům je omezen na pracovní adresář a systémový dočasný adresář, dokud nepřidáš cesty.

| Režim oprávnění | Chování |
|-----------------|---------|
| `manual` (výchozí) | Zápisy a příkazy vyvolají dotaz; read-only požadavky se schvalují |
| `assisted` | LLM kontrola schválí, co vyhodnotí jako bezpečné, a jinak se zeptá. Není to bezpečnostní hranice |
| `allow-all` | Schválí všechno, jako `--allow-all`. Ignoruje se, když ho politika zakáže |

Režim nastavíš přes `/permissions` nebo nastavením `defaultPermissionMode`. Režimy agenta jsou samostatná osa: `interactive`, `plan`, `autopilot`.

**Sandbox:** ve výchozím stavu vypnutý. `/sandbox enable` / `disable`, nebo `--sandbox` pro jednu session. Omezuje shellové příkazy (macOS Seatbelt, Linux bubblewrap); vestavěné úpravy souborů se politikou řídí v režimu best-effort. Nastavení leží pod `sandbox` v `settings.json`, jen na úrovni uživatele **[D]**.

## Modely, kredity a limity

| Téma | Co vědět |
|------|----------|
| Výběr modelu | `/model` v session, `--model <model-id>` při spuštění, `COPILOT_MODEL`, nebo nastavení `model`. S `auto` vybírá Copilot |
| Co smíš použít | Vypíše to `/model`. Organizace může seznam omezit; ve 2N je povolený každý model kromě Fable. Id modelu nedávej natvrdo do souboru |
| Effort, plan režim | `--reasoning-effort`, nastavení `effortLevel`, nebo šipky vlevo / vpravo v `/model`. Plan režim: nastavení `planModel` nebo `/model plan` |
| Účtovací jednotka | AI kredity. Každé volání modelu stojí své tokeny v ceně modelu za token; subagenti a kompakce se počítají. `/model` ukazuje kredity za 1M tokenů |
| Rozpočet | 1 kredit = $0.01. Copilot Business zahrnuje 1 900 kreditů na uživatele měsíčně, sdílených v poolu **[D]** |
| Zobrazení spotřeby | `/usage`; patička `Session: N AIC used`; `--usage-output-file` (`totalNanoAiu`, 10^9 nano AIU = 1 kredit) |
| Strop session | `--max-ai-credits <n>` nebo `/limits set max-ai-credits <n>` (minimum 30); `/limits unset`. Měkký strop: jedna odpověď ho může překročit, další volání modelu je pak zablokováno. Subagenti ho sdílejí |
| Rate limity | Ukazatele Session a Weekly v `/usage`; varování na 50, 75, 90 a 95 %. Při dosažení: počkej, `/model`, nebo přepni na Auto (`continueOnAutoMode` to udělá bez ptaní) |
| Autopilot | Pozastaví se po 5 automatických pokračováních (`--max-autopilot-continues`) |
| Subagenti | `/subagents` nastaví model pro každého agenta. `subagents.maxConcurrency` a `subagents.maxDepth` platí jen při účtování podle spotřeby |
| Kontext | `/context` ukáže využití, `/compact` shrne. Kompakce na pozadí začíná ve výchozím stavu na 80 % okna |

## Příkazy tohoto repa

| Úkol | Příkaz |
|------|--------|
| Build a test engine + api | `./gradlew build` |
| Jen testy engine | `./gradlew :engine:test` |
| Spuštění API (port 8080) | `./gradlew :api:bootRun` |
| Spuštění UI (port 5173, proxuje `/api`) | `cd web && npm ci && npm run dev` |
| Testy, lint a build webu | `cd web && npm test`, `npm run lint`, `npm run build` |
| Launcher s pravidly workshopu | `scripts/copilot-ws.sh`, nebo `scripts/copilot-ws.sh -p "..."`. Povoluje `shell(./gradlew:*)`, `shell(npm test)`, `shell(npm run)`; zakazuje `read(.env)`, `write(.env)` |
| Co Copilot načetl? | `copilot instruction list --json`, `copilot skill list --json`, `/env` v session |
| Agent z pluginu, headless | `copilot --agent 2048-dev:game-explorer -p "..."` **[T]** |
| Validace eval specifikací | `npm run eval:lint` |
| Spuštění jednoho evalu | `npm run eval -- -e evals/game-explorer/eval.yaml` |
| A/B skillu (utrácí kredity) | `npm run eval:ab`. Jen plán, zdarma: `npx vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run` |
| A/B pluginu (utrácí kredity) | `evals/plugin-ab.sh`, nebo `RUNS=3 MODEL=<model-id> evals/plugin-ab.sh` |
| Conductor | `conductor validate conductor/test-coverage-audit.yaml`, pak `conductor run conductor/test-coverage-audit.yaml` (`conductor --silent run ...` jen pro JSON; `--silent` je kořenová volba a patří před `run`). `conductor doctor` ukáže stav providerů |

Výsledky evalů končí v `evals/results/<timestamp>/`. Viz [Ukázka 9](09-validate-eval.cs.md) a [Ukázka 14](14-conductor.cs.md).

## Co v Copilot CLI není

Pro ty, kdo přicházejí z Claude Code.

| Claude Code má | Copilot CLI 1.0.114 |
|----------------|---------------------|
| Commitnutý soubor oprávnění (`permissions.allow` / `deny` v `.claude/settings.json`) | Nemá. Nastavení repozitáře nepřijímá žádný klíč pro allow nebo deny nástrojů **[D]**. Pravidla sdílej přes spouštěcí přepínače (`scripts/copilot-ws.sh`) nebo hooky. Deklarativní pravidla allow / ask / deny přicházejí jen z politiky organizace |
| Output styles | V nápovědě ani v nastavení žádný ekvivalent |
| Prompt soubory (`.prompt.md`) | CLI je nepodporuje **[D]**. Použij skill |
| `plugin validate` | Takový podpříkaz není. `copilot plugin` má `install`, `uninstall`, `update`, `list`, `enable`, `disable`, `marketplace`. Výsledek zkontroluj přes `copilot plugin list --json` a `/env` |
| Vestavěný příkaz pro evaly | V CLI žádný. Tohle repo používá Vally (`npm run eval`). GitHub Copilot Evals je samostatný plugin ve veřejném preview **[D]** |
| Přemapovatelné klávesy | Zkratky nejdou přemapovat |

---

Reference, ne tutoriál. Jak a proč který mechanismus funguje, najdeš v číslovaných návodech v [přehledu](README.cs.md).

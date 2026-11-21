> 🌍 Číst v jazyce: [English](cheatsheet.md) | **Česky**

# Tahák pro Copilot CLI

> Ověřeno na Copilot CLI 1.0.114 · Dokumentace: [CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) · [Customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)

Každý přepínač a slash příkaz odsud najdeš v `copilot --help` nebo `copilot help <topic>` ve verzi 1.0.114. CLI
vychází skoro denně: když řádek nesedí, platí nápověda. Návody: [rozcestník](README.cs.md).

## Přepínače při spuštění

| Přepínač | Co dělá |
|----------|---------|
| `copilot`, `-i "<prompt>"` | Interaktivní session; `-i` nejdřív spustí prompt |
| `-p "<prompt>"` | Spustí jeden prompt a skončí ([programatický režim](#programatický-režim)) |
| `--model <model-id>`, `--reasoning-effort <level>` | Model a effort pro session. `auto` nechá výběr na Copilotovi; effort s `auto` selže: `Model "auto" does not support reasoning effort configuration` |
| `--agent <agent>` | Spustí session jako vlastního agenta; agent z pluginu je `<plugin>:<agent>` |
| `--mode <mode>`, `--plan`, `--autopilot` | Start v režimu `interactive`, `plan` nebo `autopilot`. `--max-autopilot-continues <n>` (výchozí 5) |
| `--fleet` | Spustí prompt s paralelními subagenty; kombinuj s `-i`, `-p` nebo se stdin z roury |
| `--max-ai-credits <n>` | Strop kreditů pro session (minimum 30, měkký) |
| `--allow-tool='<rule>'`, `--deny-tool='<rule>'` | Předem schválí nebo zablokuje odpovídající volání nástrojů pro tenhle běh; deny vyhrává |
| `--allow-all-tools`, `--allow-all` (`--yolo`) | Žádné dotazy na nástroje; `--allow-all` navíc vypne kontroly cest a URL |
| `--trust-folder` | Důvěřuje konfiguraci složky pro jeden běh `-p`; nic neukládá |
| `--continue`, `--resume [value]`, `-n <name>` | Naváže na poslední session; naváže podle ID nebo jména; pojmenuje novou session |
| `--add-github-mcp-tool <tool>`, `--disable-mcp-server <name>`, `--additional-mcp-config <json>` | Pro tenhle běh: zpřístupní přesně vyjmenované nástroje vestavěného GitHub MCP serveru místo jeho výchozí podmnožiny (`--add-github-mcp-toolset <toolset>` k ní přidává); vypne server; přidá servery |
| `--plugin-dir <dir>`, `--experimental`, `--no-custom-instructions` | Načte plugin z lokálního adresáře; zapne experimentální featury; přeskočí všechny soubory s instrukcemi |

V shellu, bez session: `copilot instruction list`, `copilot skill list`, `copilot mcp list`,
`copilot plugin list`, `copilot config [key] [value]` (`--repo`, `--local`), `copilot help [topic]`.

## Slash příkazy

| Skupina | Příkaz | Co dělá |
|---------|--------|---------|
| **Načteno** | `/env` | Co se načetlo: instrukce, MCP servery, skilly, agenti, hooky, pluginy |
| | `/instructions`, `/skills`, `/plugin`, `/init` | Zapíná a vypíná soubory s instrukcemi; spravuje skilly; spravuje pluginy; napíše soubor s instrukcemi |
| | `/agent [name]`, `/subagents` | Vybere agenta (zpět: `/agent`, pak `Default`); nastaví model každého subagenta nebo ho vypne |
| | `/mcp` | `list`, `get <server>`, `reload`, `enable` / `disable <server>` |
| **Model, cena** | `/model` | Model, effort a kontextový tier; `/model plan` pro plan režim; `--repo` nastaví výchozí hodnotu repa |
| | `/usage`, `/limits` | Kredity, tokeny po modelech a ukazatel rozpočtu `Plan`; `/limits set max-ai-credits <n>`, `/limits unset` |
| | `/context`, `/compact [focus]` | Využití kontextového okna po kategoriích; shrne historii, aby ho uvolnil |
| **Práce** | `/plan`, `/autopilot` | Plán před kódováním; zapne nebo vypne autopilota, nebo nastaví cíl s `--max-ai-credits` |
| | `/fleet [prompt]`, `/tasks` | Rozdělí práci mezi paralelní subagenty; vypíše, co běží: `Enter` otevře přepis, `x` ukončí vybraného |
| | `/delegate` | Pošle session cloudovému agentovi, který otevře PR; `--base` vybírá branch |
| **Kód** | `/diff`, `/review`, `/security-review`, `/rubber-duck` | Ukáže změny (`Esc` zavře); agent pro review; bezpečnostní sken necommitnutých změn; nezávislá kritika |
| **Oprávnění** | `/permissions` | Přepne režim: `manual`, `assisted`, `allow-all`; `show` vypíše režim, ne pravidla allow a deny |
| | `/allow-all`, `/reset-allowed-tools` | Povolí všechno; smaže schválení ze session i uložená schválení pro tohle umístění |
| | `/sandbox`, `/add-dir` | `status`, `policy`, `enable [session]`, `disable`; povolí další adresář |
| **Session** | `/new`, `/clear` | Nová session, ta současná běží dál; zahodí tuhle session |
| | `/resume [value]`, `/fork [name]`, `/rewind` | Přepne session; zkopíruje tuhle; obnoví dřívější kolo ([Rewind](#rewind)) |
| | `/share`, `/remote`, `/keep-alive` | Export `file`, `html`, `gist`, `link`; řízení z GitHubu na webu nebo v mobilu; zabrání uspání |
| **Ostatní** | `/ide`, `/pr`, `/ask`, `/settings`, `/diagnose` | Propojení s IDE; PR téhle branche; vedlejší otázka; jedno nastavení; proč žádost potřebovala schválení |

Vstup: `/name` spustí skill (`/board-tests`, `/2048-dev:build-test`), přes `!cmd` spustíš shellový příkaz
napřímo, `@file` zmíní soubor. Klávesy: `Enter` usměrní běžící kolo, `Ctrl+Q` zařadí další do fronty,
`Ctrl+C` zastaví kolo, `Esc` odmítne dotaz na oprávnění, `Shift+Tab` přepíná mezi Interactive, Plan a
Autopilot, `Ctrl+O` rozbalí položky timeline, `?` na prázdném promptu vypíše všechny klávesy.

## Modely a effort

| Téma | Jak |
|------|-----|
| Výběr modelu | `/model`, `--model <model-id>`, `COPILOT_MODEL` nebo nastavení `model`. Ve 2N jde vybrat každý model kromě rodiny Claude Fable; model, který použít nemůžeš, je v `/model` pořád vidět a po zvýraznění řekne proč. U každého modelu jsou uvedené kredity za 1M tokenů |
| Effort | Úrovně `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`; které existují, záleží na modelu; nenastaveno znamená výchozí hodnotu modelu, u většiny `medium`. Nastavíš ho šipkami vlevo / vpravo v `/model`, přes `--reasoning-effort <level>`, nastavením `effortLevel`, `reasoning-effort:` v `.agent.md` nebo v `/subagents` |
| Plan režim | Vlastní model a effort: `/model plan`, `planModel`, `planEffortLevel`. Effort session se nedědí |
| Auto | `auto` se zobrazuje jako Copilot Fusion a vybírá model pro každý prompt. `--auto-tier` / `autoTier`: `efficiency`, `balance`, `intelligence`. `fusionTier`: `standard`, `high`, `max`. V `/model` na řádku `Copilot Fusion` mění šipky vlevo / vpravo jeho `Tier` (`Standard`, `High`, `Max`) |
| Kontextový tier | `--context default` nebo `long_context`, nastavení `contextTier` nebo výběr úrovně v `/model` |
| Uvažování, cena | `Ctrl+T` zobrazí nebo skryje shrnutí uvažování. `/usage`: `↑ input (N cached, N written) • ↓ output (N reasoning)`; tokeny uvažování se účtují jako výstup |

ID modelu nikdy necommituj: seznam 2N se liší od tvého. Bezpečně commitnout jde `effortLevel`.

> 🔷 **Jen Copilot:** jedno předplatné a jeden výběr pro modely od několika dodavatelů (Anthropic, OpenAI, Google, xAI, Microsoft, Moonshot AI). Claude Code běží jen na modelech Claude.

## Ekonomika kontextu

| Fakt | Co s tím |
|------|----------|
| Každé volání modelu posílá znovu celou konverzaci jako vstup | Dlouhé sessions stojí víc za kolo. Prompt cache obslouží opakovanou část za zlomek ceny; `/usage` ji ukazuje jako cached |
| Na testovacím stroji poslal jednoslovný prompt v prázdném adresáři 20 387 vstupních tokenů, z toho 10 668 připadlo na definice nástrojů | Fixní režie se platí při každém volání a každý soubor s instrukcemi a každý MCP nástroj ji zvyšuje. Co okno zaplňuje, ukáže `/context` |
| `/compact [focus]` nahradí historii shrnutím; sám se spustí na 80 % okna | Detaily se ztratí, nejde to vrátit a stojí to kredity. Na nový úkol použij `/new` nebo `/clear` |
| Subagent má vlastní okno | Zpátky přijde jen jeho zpráva: čtení deleguj |
| 1 kredit = 0,01 USD; Copilot Business má 1 900 na uživatele měsíčně, ve společném poolu | Dej session strop: `--max-ai-credits <n>` nebo `/limits set max-ai-credits <n>`. Měkký strop: jedna odpověď ho může překročit, další volání se pak zablokuje. Počítají se i subagenti a kompakce |

> 🔷 **Jen Copilot:** strop nákladů, který nastavíš na jednu interaktivní session. `--max-budget-usd` v Claude Code platí jen pro běhy `-p`.

## Víc sessions najednou

| Udělej tohle | Co získáš |
|--------------|-----------|
| `/new` | Druhou session; ta současná běží dál na pozadí |
| `Left` na prázdném promptu | Postranní panel Sessions: seznam a přepínání |
| `/fork [name]` | Kopii téhle konverzace, na které zkusíš něco jiného |
| `/new worktree`, `/fork worktree` | Totéž v novém git worktree, takže dvě sessions neupravují stejné soubory |
| `copilot --continue`, `--resume [value]`, `/resume` | Návrat do uložené session |
| `/delegate` | Session pokračuje na GitHubu a skončí pull requestem |

Session na pozadí je pořád interaktivní: přepni se zpátky a odpověz na její dotazy.

## Rewind

`/rewind`, `/undo` nebo `Esc Esc` na prázdném promptu: vyber kolo, pak „Conversation only“ nebo
„Conversation + files“. Obnoví se jen soubory, které změnil Copilot; prompt toho kola se vrátí do
vstupního řádku. Rewind je nevratný: nejdřív `/fork`. Kompakce ukládá checkpoint: `/session checkpoints [n]`.

## Kde leží soubory

| Co | V repozitáři | Pro tebe (`~/.copilot/`) |
|----|--------------|--------------------------|
| Instrukce | `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md` (`applyTo`), `AGENTS.md` | `copilot-instructions.md`, `instructions/*.instructions.md` |
| Skilly | `.github/skills/<name>/SKILL.md` | `skills/` |
| Hooky | `.github/hooks/*.json` | `hooks/` |
| MCP | `.mcp.json` nebo `.github/mcp.json`, klíč nejvyšší úrovně `mcpServers` | `mcp-config.json` |
| Agenti | `.github/agents/<name>.agent.md` | `agents/` |
| Pluginy | `marketplace.json`, `plugins/<name>/plugin.json`; zapnuté přes `extraKnownMarketplaces` a `enabledPlugins` v `.github/copilot/settings.json` | `installed-plugins/` |
| Nastavení | `.github/copilot/settings.json`, `settings.local.json` (tady ho git ignoruje) | `settings.json` |
| Oprávnění | žádný commitnutý soubor: přepínače při spuštění ve `scripts/copilot-ws.sh` nebo hook | `permissions-config.json` („don't ask again“) |

- Čte se taky: `CLAUDE.md`, `GEMINI.md`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/`,
  `.claude/commands/`, `.agents/skills/`, hooky v `.claude/settings.json`. Tohle repo nemá nic z toho.
- Nečte se: `.cursorrules`, `.cursor/rules/*.mdc`, `.windsurfrules`, `.vscode/mcp.json`, `~/.claude/`.
- Hooky, MCP servery workspace a pluginy z repa se načtou jen v důvěryhodné složce; ukáže je `/env`.

## Události hooků

`{"version": 1, "hooks": {"<event>": [{"type": "command", "bash": "./script.sh", "cwd": ".", "timeoutSec": 30, "matcher": "..."}]}}`

| Událost | Kdy se spustí | Payload navíc obsahuje | Odpověď: JSON na stdout, exit 0 |
|---------|---------------|------------------------|---------------------------------|
| `sessionStart` | Začíná session | `source`, `initialPrompt` | `{"additionalContext": "..."}` jde do kontextu modelu |
| `userPromptSubmitted` | Odešleš prompt | `prompt` | Hodí se na logování |
| `preToolUse` | Před voláním nástroje | `toolName`, `toolArgs` | `{"permissionDecision": "deny", "permissionDecisionReason": "..."}` zablokuje volání, i s `--allow-tool`. Model uvidí `Denied by preToolUse hook: <reason>` |
| `postToolUse` | Po úspěšném volání nástroje | navíc `toolResult` | `{"additionalContext": "..."}` |
| `agentStop` | Agent končí kolo | `stopReason`, `stop_hook_active` | `{"decision": "block", "reason": "..."}` ho pošle zpátky do práce; `reason` dorazí jako další zpráva uživatele |
| `sessionEnd` | Session končí | `reason` | Nic |

- Každý payload má `sessionId`, `timestamp`, `cwd`. Hooky běží v kořenu repa s nastavenými
  `COPILOT_PROJECT_DIR`, `COPILOT_HOOK_DIR` a `COPILOT_CLI=1`.
- `matcher` je regex nad celým názvem nástroje, např. `bash|powershell`. `toolArgs` je objekt u
  `bash` (`.command`) a surový řetězec s patchem u `apply_patch`.
- Exit kód 2 ukáže stderr jako varování. Na `agentStop` neblokuje; na `preToolUse` zamítne volání
  jakýkoli nenulový exit kód. Všechny události:
  [reference hooků](https://docs.github.com/en/copilot/reference/hooks-reference).

## Vzory oprávnění

| Vzor | Čemu odpovídá |
|------|---------------|
| `shell`, `shell(command)` | Každý shellový příkaz; jeden příkaz. `git`, `gh`, `npm`, `gradle` a podobné se porovnávají i s prvním podpříkazem: `shell(git push)` |
| `shell(command:*)` | Ten příkaz a cokoli za ním: `shell(git:*)` odpovídá `git push`, ne `gitea` |
| `write`, `write(path)` | Vytváření a úpravy souborů. Relativní cesta se porovnává podle koncových komponent: `write(.env)` je jakýkoli `.env`. Globy `*`, `?`, `**` |
| `read`, `read(path)` | Čtení souborů vestavěnými nástroji, stejné porovnávání cest. Ne shellové příkazy |
| `<mcp-server>`, `<mcp-server>(tool)` | Všechny nástroje MCP serveru; jeden nástroj |
| `url(domain-or-url)` | Přístup na URL ze shellu a z nástrojů web-fetch: `url(https://*.github.com)` |

- ✅ `shell(./gradlew:*)` povolí `./gradlew :engine:test`. ❌ `shell(gradlew:*)` a
  `shell(./gradlew test)` ne. ✅ `shell(npm test)` a `shell(npm:*)` povolí `cd web && npm test`.
- ⚠️ `--deny-tool='read(.env)'` blokuje nástroj `view`; `cat .env` soubor pořád vypíše. Tuhle
  díru zavírá hook `protect-secrets.sh`.
- Deny vyhrává nad každým allow, i nad `--allow-all`. Pravidla z přepínačů platí po dobu běhu. Read-only
  příkazy běží bez ptaní. V autopilotu a v bězích `-p` se požadavek, který by vyvolal dotaz, zamítne.
- Sandbox, ve výchozím stavu vypnutý: `/sandbox enable` ho uloží; `/sandbox enable session` nebo `--sandbox`: jedna session.

## Programatický režim

```bash
copilot -p "<prompt>" --trust-folder --no-ask-user --allow-tool='shell(./gradlew:*)' --output-format json > events.jsonl
```

| Přepínač | Proč ho skript potřebuje |
|----------|--------------------------|
| `--allow-tool='<rule>'` | Na dotaz nemá kdo odpovědět: neschválené volání selže s `Permission denied because no interactive user response was available.` |
| `--trust-folder`, `--no-ask-user` | Načte hooky repa a MCP servery workspace; agent nemůže otevřít formulář s otázkou |
| `-s`, `--output-format json` | Jen finální odpověď; nebo JSONL, jeden `{type, data, id, parentId, timestamp}` na řádek |
| `--usage-output-file <file>`, `--share [path]` | Kredity (`totalNanoAiu`, 10^9 = 1 kredit) a tokeny po modelech a agentech; session jako Markdown |

- `tool.execution_start`: `data.toolName`, `data.arguments`. Použití skillu je `toolName: "skill"`,
  delegování je `toolName: "task"` s `arguments.agent_type`.
- `tool.execution_complete`: `data.success`, `data.error.message`. Odpověď je v
  `assistant.message` (`data.content`). Poslední řádek je `{"type": "result", "exitCode": 0, ...}`.

## Evaly

| Příkaz (kořen repa, po `npm ci`) | Co dělá |
|----------------------------------|---------|
| `npm run eval:lint` | Zvaliduje obě specifikace evalů. Zdarma |
| `VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run` | Vypíše plán se skillem / bez něj. Zdarma |
| `npm run eval -- -e evals/game-explorer/eval.yaml` | Spustí jeden eval. Utrácí kredity |
| `npm run eval:ab` | Skill `board-tests`, s ním a bez něj. Utrácí kredity |
| `evals/plugin-ab.sh`, `RUNS=3 MODEL=<model-id> evals/plugin-ab.sh` | A/B pluginu na obyčejném `copilot -p`; potřebuje jen `copilot` a `jq`. Utrácí kredity |

Výsledky: `evals/results/<timestamp>/report.md`. Podrobnosti: [09 · Evaly](09-evals.cs.md).

## Co v 1.0.114 není

| Možná hledáš | Použij místo toho |
|--------------|-------------------|
| `/yolo` | `--yolo` nebo `--allow-all` při spuštění, `/allow-all` v session |
| `/goal` | `/autopilot` s cílem a `--max-ai-credits` |
| `/workflows` | `copilot workflow run <name>`, s `--experimental` |
| `/agents`, `/output-style` | `/agent [name]`; `/subagents` pro nastavení jednotlivých subagentů. Output style: agent pro session, `copilot --agent workshop-tutor` ([06](06-agents.cs.md)) |

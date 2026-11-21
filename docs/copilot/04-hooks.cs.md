> 🌍 Číst v jazyce: [English](04-hooks.md) | **Česky**

# 04 · Hooky

> ⏱ 25 min (5 lab s payloadem + 5 demo zamítnutí + 15 cvičení 3) · Dokumentace: [Hooks for GitHub Copilot](https://docs.github.com/en/copilot/concepts/customizations/hooks) · [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference) · [Using hooks with GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks) · Ověřeno na Copilot CLI 1.0.114

## Co je hook?

Hook je příkaz, který CLI spustí samo, když nastane událost: začne session, má se spustit
nástroj, nástroj doběhl, agent se chystá skončit. CLI zapíše událost jako JSON na stdin
příkazu a z jeho stdout přečte nejvýš jeden JSON objekt.

Instrukce a skilly jsou text v kontextovém okně a model je může přeskočit. Hook běží mimo
model, pokaždé, ať se model rozhodl jakkoli. Na úrovni 5+ kód generuješ a každé volání
nástroje už nečteš. Hooky ano.

## Co dělá tahle ukázka

`.github/hooks/hooks.json` registruje pět skriptů z `.github/hooks/scripts/`. Všechny kromě
`run-tests.sh` potřebují `jq`; bez něj nedělají nic a session pokračuje.

| Událost | Skript | Co dělá | Může blokovat? |
|---|---|---|---|
| `sessionStart` | `git-context.sh` | Řekne modelu branch a necommitnuté soubory | Ne. Přidává kontext |
| `preToolUse` | `block-destructive.sh` | Odmítne `rm -rf`, `git reset --hard`, force-push, `git clean -f`, `git checkout -- .` | Ano, volání nástroje |
| `preToolUse` | `protect-secrets.sh` | Drží soubory `.env` mimo session (shell i `view`) | Ano, volání nástroje |
| `postToolUse` | `format.sh` | Spustí Prettier na upravených souborech ve `web/src/` a řekne to modelu | Ne. Úprava už proběhla |
| `agentStop` | `run-tests.sh` | Spustí testy těch částí, které mají necommitnuté změny | Ne, varuje. Cvičení 3 z něj udělá blokující |

## Lab: nejdřív si vypiš payload

Tvar payloadu závisí na nástroji a na modelu. Podívej se na něj dřív, než napíšeš skript.

1. Vytvoř `.github/hooks/payload-dump.json`. Načte se každý `*.json` v tom adresáři.
   ```json
   {
     "version": 1,
     "hooks": {
       "preToolUse": [
         { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/preToolUse.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
       ]
     }
   }
   ```
   Žádný `matcher`, takže se spustí pro každý nástroj. `(cat; echo)` připíše payload jako jeden řádek.
   Na `exit 0` záleží: hook `preToolUse`, který skončí nenulovým kódem, volání nástroje zamítne.
2. Z kořene repa spusť jednu session. Soubory s hooky se čtou při startu CLI.
   ```bash
   copilot -p "Do exactly these three things, in order, then stop: (1) read the file README.md with the file view tool; (2) run the shell command 'git status --short'; (3) create a new file named .github/hooks/logs/note.txt containing the single word alpha. Do not do anything else." \
     --trust-folder --no-ask-user --allow-tool='write'
   ```
3. Vypiš, co každý nástroj dostal. `<repo>` zastupuje absolutní cestu k repu.
   ```bash
   jq -c '{toolName, toolArgs}' .github/hooks/logs/preToolUse.jsonl
   ```
   ```json
   {"toolName":"view","toolArgs":{"path":"<repo>/README.md"}}
   {"toolName":"bash","toolArgs":{"command":"git status --short","description":"Check short git status"}}
   {"toolName":"bash","toolArgs":{"command":"mkdir -p .github/hooks/logs && printf alpha > .github/hooks/logs/note.txt","description":"Create note.txt containing alpha"}}
   {"toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Add File: <repo>/.github/hooks/logs/note.txt\n+alpha\n*** End Patch\n"}
   ```
4. Vyčti z toho tři fakta. Tvoje řádky se můžou lišit, protože nástroje vybírá model.
   - **`toolArgs` je u `bash` a `view` objekt a u `apply_patch` surový řetězec s patchem.**
     Ten řetězec není JSON. `jq '.toolArgs.path'` na něm selže.
   - **Modely z rodiny GPT editují přes `apply_patch`**, ne přes `edit` / `create` (stejně tak
     model MAI v tomto běhu). Matcher `edit|create` se u nich nikdy nespustí a nic tě na to neupozorní.
   - **Přesměrování v shellu obchází matchery na editaci.** Třetí řádek zapisuje soubor přes `bash`
     (tady zamítnuto: běh předem schvaluje jen `write`). Hook na editační nástroje to nikdy neuvidí.
5. Ukliď: `rm .github/hooks/payload-dump.json && rm -r .github/hooks/logs`

## Soubory řádek po řádku

### `.github/hooks/hooks.json`

Stejná obálka jako tvůj soubor z labu: `hooks` mapuje název události (camelCase) na seznam plochých
položek. Payload svou událost nejmenuje; skript ji zná podle toho, kde je zaregistrovaný.
`"type": "command"` (výchozí) spustí shellový příkaz.

- `"matcher"`: regex na název nástroje, kompilovaný jako `^(?:PATTERN)$`, takže musí odpovídat
  celému názvu: `bash|powershell` pro `block-destructive.sh`, `bash|powershell|view` pro
  `protect-secrets.sh`, `edit|create|str_replace_editor|apply_patch` pro `format.sh` (fakt 2
  z labu). `sessionStart` a `agentStop` se netýkají nástroje a žádný matcher nemají.
- `"bash"` běží relativně k `cwd`. `"cwd": "."` je kořen repozitáře. `copilot` spouštěj tam.
- `"timeoutSec"`: výchozí hodnota je 30. Tady 10 pro pojistky, 60 pro formátovač, 300 pro testy.
- Na volání shellu sedí obě pojistky. Spustí se obě a jakékoli `deny` vyhrává.

### `.github/hooks/scripts/protect-secrets.sh`

Skript od řádku 17 dál. Řádky před ním jsou popsané v prvních dvou odrážkách.

```bash
# What the tool is about to touch: a path for the file tools, a command for the shell.
target=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.path // .command // "") else "" end' 2>/dev/null)

# Matches .env and .env.local, but not .envrc or environment.ts.
if printf '%s' "$target" | grep -Eq '(^|[^[:alnum:]_])\.env(\.[[:alnum:]_-]+)?([^[:alnum:]_.-]|$)'; then
    jq -cn '{permissionDecision: "deny", permissionDecisionReason: "protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need."}'
fi

exit 0
```

- Řádek 8, `set -uo pipefail` bez `-e`: hook `preToolUse`, který skončí nenulovým kódem, volání
  nástroje zamítne. S `-e` by ho zamítlo i selhání mimo `if`, třeba `jq` na rozbitém payloadu.
- Řádky 10–15: `input=$(cat)` přečte payload ze stdin. Bez `jq` se pojistka sama vypne, ohlásí
  to na stderr a skončí s kódem 0: dozvíš se, že není aktivní, a žádné volání se nezamítne.
- Výraz v `jq` přijímá tři tvary: objekt se použije tak, jak je, řetězec s JSONem se rozparsuje
  přes `fromjson`, cokoli jiného (řetězec s patchem) se změní na prázdnou hodnotu. `.path // .command`
  pokrývá oba nástroje: `view` nese `path`, shell `command`.
- Regex: `.env` na začátku nebo za znakem, který není součástí slova, volitelná přípona jako
  `.local`, pak konec nebo znak, kterým název souboru pokračovat nemůže.
- Zamítnutí je exit 0 a jeden JSON objekt. `permissionDecisionReason` jde modelu, takže ho piš
  jako instrukci: co má udělat místo toho. Žádný výstup a exit 0 znamená „bez názoru“.
- Porovnává text: `cat .e*` projde, `grep -n .env .gitignore` se zamítne. Je to pojistka.
  Hranicí je sandbox ([08](08-permissions-sandbox.cs.md)). Hook existuje proto, že
  `--deny-tool='read(.env)'` zastaví jen `view`, ne `cat .env` v shellu.

### Zbylé čtyři

- **`git-context.sh`** (`sessionStart`) vypíše branch a až 10 necommitnutých souborů jako
  `{"additionalContext": "..."}`. Je to snímek ze startu session a neobnovuje se.
- **`block-destructive.sh`** (`preToolUse`): stejná kostra s pěti regex pravidly. Každý důvod
  jmenuje bezpečnou cestu, například `git push --force-with-lease`. `rm -rf` na výstup buildu projde.
- **`format.sh`** (`postToolUse`) vezme `.path` z objektu, nebo hlavičky `*** Add File:` /
  `*** Update File:` z řetězce s patchem, a spustí Prettier na `web/src/` (potřebuje
  `cd web && npm ci`). Jeho `additionalContext` říká modelu, aby si změněný soubor přečetl znovu.
- **`run-tests.sh`** (`agentStop`) se spouští po každém kole, i po obyčejné otázce. Pustí
  `./gradlew test`, pokud má necommitnuté změny `engine/` nebo `api/`, a `npm test`, pokud je má
  `web/src/`. Při selhání zapíše jeden řádek na stderr a skončí s kódem 2: varování. Kolo i tak skončí.

## Vytvoř si vlastní, krok za krokem

1. Vypiš si payload události, kterou chceš (lab výše). Piš podle toho, co jsi viděl.
2. Napiš `.github/hooks/scripts/my-hook.sh` a dej mu `chmod +x`. Spouští se v kořenu repa. Přečti
   stdin, přijmi `toolArgs` jako objekt i jako řetězec, vypiš nejvýš jeden JSON objekt, `exit 0`.
3. Zaregistruj ho v `hooks.json`, nebo v novém `*.json` vedle něj, s `matcher` (u událostí nástrojů).
4. Otestuj ho s podvrženým stdin, mimo session. Tohle vypíše objekt se zamítnutím:
   ```bash
   echo '{"toolName":"bash","toolArgs":{"command":"cat .env"}}' | .github/hooks/scripts/protect-secrets.sh
   ```
5. Spusť novou session a zadej `/env`. Blok `Hooks` počítá hooky podle událostí a jmenuje
   jejich soubory. V dodaném stavu: `preToolUse: 2 hooks (sources: .github/hooks/hooks.json (2))`.
6. Commitni JSON soubor i skript. Spouští je pak každý, kdo složce důvěřuje, takže změnu
   v `.github/hooks/` reviduj jako změnu CI.

## Vyzkoušej demo

1. Spusť `copilot` v kořenu repa. U `Confirm folder trust` zvol **Yes**: hooky z repa potřebují důvěryhodnou složku.
2. Vlož:
   > *„Spusť přesně tenhle jeden shellový příkaz a jednou větou napiš, co se stalo; ocituj každou zprávu, kterou jsi dostal: cat .env“*

3. Volání shellu selže dřív, než se `cat` spustí. Model dostane jako výsledek nástroje tohle:
   ```text
   Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need.
   ```

Žádný soubor `.env` není potřeba: hook posuzuje text příkazu. `--allow-tool='shell'` zamítnutí nezruší.

## Události a jak hook odpovídá

| Událost | Kdy se spustí | `matcher` na | Odpověď: jeden JSON objekt na stdout, exit 0 |
|---|---|---|---|
| `sessionStart` | Session začíná nebo se obnovuje | — | `{"additionalContext": "..."}` se přidá do session |
| `preToolUse` | Před každým voláním nástroje | název nástroje | `{"permissionDecision": "deny", "permissionDecisionReason": "..."}`. Také `allow` a `ask`; `modifiedArgs` volání přepíše |
| `postToolUse` | Po úspěšném volání nástroje | název nástroje | `{"additionalContext": "..."}` se připojí k výsledku nástroje; `modifiedResult` ho nahradí |
| `agentStop` | Hlavní agent dokončí kolo | — | `{"decision": "block", "reason": "..."}` spustí další kolo s `reason` jako promptem |

To jsou 4 ze 14 událostí. Nápady na další: `notification` (upozornění na ploše, když na tebe
Copilot čeká), `preCompact` (nejdřív zkopíruj přepis), `sessionEnd` (zaloguj běh), `postToolUse`
s `"type": "http"` (auditní stopa). Všechny události: [Hook events](https://docs.github.com/en/copilot/reference/hooks-reference#hook-events).

| Návratový kód | Každá událost | Výjimka: `preToolUse` |
|---|---|---|
| `0` | Stdout se parsuje jako odpověď. Prázdný znamená bez názoru | — |
| `2` | Jen varování: zobrazí se stderr, běh pokračuje | Zamítne volání nástroje |
| jiný nenulový | Zaloguje se a přeskočí | Zamítne: `Denied by preToolUse hook (hook errored)` |
| timeout | Hook se zabije, běh pokračuje | Volání nástroje proběhne. Pomalá pojistka není pojistka |

`agentStop` tedy nemůže blokovat návratovým kódem, jen přes JSON. Jeho payload má
`stop_hook_active`: `false` při běžném zastavení, `true` při zastavení, které následuje po zablokování.
Použij ho, abys blokoval jen jednou. Po 8 zablokováních za sebou CLI kolo stejně ukončí. Ladicí text patří na stderr.

## Volitelné parametry

| Klíč nebo umístění | Co dělá |
|---|---|
| `powershell`, `command`, `env` | Příkazová řádka pro PowerShell; záložní příkazová řádka pro oba shelly; další proměnné prostředí |
| `"type": "http"`, `"type": "prompt"` | Pošle payload POSTem na `https://` adresu v `url`; odešle za tebe text nebo slash příkaz (jen `sessionStart`, jen nové interaktivní session) |
| `"disableAllHooks": true` | V souboru s hooky: přeskočí ten soubor. V `.github/copilot/settings.json`: přeskočí každý hook kromě policy hooků |
| `~/.copilot/hooks/*.json`, `hooks:` ve frontmatteru agenta, `hooks.json` v pluginu | Tvoje osobní hooky v každém repu; hooky jen po dobu, kdy je vybraný ten agent ([06](06-agents.cs.md)); hooky pro každého, kdo plugin zapne ([07](07-plugins.cs.md)) |

Kompletní reference: [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference)

## Kde to funguje

| Platforma | Funguje? | Poznámky |
|---|---|---|
| Copilot CLI | ✅ | Všechno v tomto návodu |
| Plugin pro IntelliJ IDEA | ⚠️ | Čte `.github/hooks/`. Zveřejněné události: `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`. `sessionStart` a `agentStop` mezi nimi nejsou, takže počítej s tím, že `git-context.sh` a `run-tests.sh` neudělají nic. Viz [11](11-ide-remote.cs.md) |
| Copilot cloud agent | ⚠️ | Načítá stejné `.github/hooks/*.json` v každém jobu na repu. Jen položky `bash` / `command`, z `ask` se stane zamítnutí, `permissionRequest` a `notification` se nespouštějí |

## Copilot vs Claude Code

Claude Code má stejný mechanismus pod stejným názvem: hooky v `.claude/settings.json` s
`PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`. Policy hooky, hooky vázané na agenta a hooky
v cloudových bězích existují v obou. V čem se liší: Copilot používá ploché položky
v `.github/hooks/*.json` a payload v camelCase (`toolName`, `toolArgs`); payload Claude Code je
ve snake_case (`tool_name`, `tool_input`). Copilot CLI spouští i hooky z `.claude/settings.json`
v repu, při odpovídajících událostech a s názvy polí Claude Code: takové repo spouští obě sady.

> 🔷 **Jen Copilot:** událost `userPromptTransformed` umožňuje hooku přepsat text promptu, který
> model dostane. `UserPromptSubmit` v Claude Code umí prompt jen zablokovat nebo přidat kontext.

> 🔷 **Jen Copilot:** hook s `"type": "prompt"` odešle prompt nebo slash příkaz při startu
> interaktivní session. Hook `SessionStart` v Claude Code to umí jen v bězích s `-p`.

## Když něco nefunguje

- **Hook se nikdy nespustí, `/env` ho nevypisuje** → spusť novou session z kořene repa
  (`git rev-parse --show-toplevel`). Běh s `-p` potřebuje `--trust-folder`. Pořád chybí: [preflight.cs.md](preflight.cs.md).
- **Každý shellový příkaz selže s `Denied by preToolUse hook (hook errored)`** → některý
  skript `preToolUse` končí nenulovým kódem. Pusť ho s podvrženým stdin a hledej `set -e`.
- **Pojistka projde testem s podvrženým stdin, ale v session ne** → matcher míjí skutečný název
  nástroje, nebo má `toolArgs` jiný tvar. Zopakuj lab.
- **Každé kolo je pomalé** → `run-tests.sh` pouští Gradle, dokud jsou v `engine/` nebo `api/` necommitnuté změny. Commitni.

Dál: [05 · MCP](05-mcp.cs.md) · Cvičení 3: [exercises.cs.md](exercises.cs.md)

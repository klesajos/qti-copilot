> 🌍 Číst v jazyce: [English](03-hooks.md) | **Česky**

# Ukázka 3: Projektové hooky

## Co je hook?

**Hook** je příkaz, který Copilot CLI spustí **sám**, když nastane nějaká událost: začne
session, má se spustit nástroj, nástroj doběhl, agent se chystá skončit. CLI zapíše JSON
popis události na stdin příkazu a z jeho stdout přečte nejvýš jeden JSON objekt.

Rozdíl oproti instrukcím a skillům ([Ukázka 1](01-custom-instructions.cs.md),
[Ukázka 2](02-skills.cs.md)): ty jsou *rada*. Je to text v kontextovém okně a model je může
přeskočit. Hook je *vynucení*. Běží mimo model, pokaždé, ať se model rozhodl jakkoli. Hooky
používej na to, co se přeskočit nesmí: zablokování destruktivního příkazu, udržení tajemství
mimo session, formátování, spouštění testů.

Když kód generuješ, místo abys ho psal, už nečteš každé volání nástroje. Hooky jsou ta část
nastavení, která je čte dál.

## Co dělá tahle ukázka

Repo dodává jeden registrační soubor a pět skriptů:

```
.github/hooks/
├── hooks.json                 ← WHEN: which event runs which script
└── scripts/
    ├── git-context.sh         ← sessionStart: tells the model the branch and uncommitted files
    ├── block-destructive.sh   ← preToolUse (shell): refuses rm -rf, reset --hard, force-push, ...
    ├── protect-secrets.sh     ← preToolUse (shell + view): keeps .env files out of the session
    ├── format.sh              ← postToolUse (file edits): Prettier on web/src
    └── run-tests.sh           ← agentStop: tests for the parts that changed, advisory
```

| Skript | Událost | Co vrací | Může něco zastavit? |
|--------|---------|----------|---------------------|
| `git-context.sh` | `sessionStart` | `{"additionalContext": "..."}` | Ne. Přidává kontext |
| `block-destructive.sh` | `preToolUse` | `{"permissionDecision": "deny", ...}` nebo nic | Ano, volání nástroje |
| `protect-secrets.sh` | `preToolUse` | totéž | Ano, volání nástroje |
| `format.sh` | `postToolUse` | `{"additionalContext": "..."}` nebo nic | Ne. Úprava už proběhla |
| `run-tests.sh` | `agentStop` | návratový kód 2 a řádek na stderr | Ne. Varuje. Varianta s bránou níže ano |

Čtyři z pěti potřebují `jq` (`run-tests.sh` ne). Bez něj nedělají nic a nechají session
pokračovat.

## Lab, krok 1: podívej se na skutečný payload

Udělej to dřív, než začneš číst kterýkoli skript. Dokumentace si v tom, jak payload vypadá,
protiřečí (tutoriál tvrdí, že `toolArgs` je JSON řetězec, reference ho typuje jako
`unknown`) a tvar navíc závisí na modelu, který používáš. Tak si ho vypiš.

Vytvoř `.github/hooks/payload-dump.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/sessionStart.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "preToolUse": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/preToolUse.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "postToolUse": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/postToolUse.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ],
    "agentStop": [
      { "type": "command", "bash": "mkdir -p .github/hooks/logs; (cat; echo) >> .github/hooks/logs/agentStop.jsonl; exit 0", "cwd": ".", "timeoutSec": 5 }
    ]
  }
}
```

- **Druhý soubor, ne úprava `hooks.json`.** Načte se každý `*.json` v `.github/hooks/`
  a položky se spojí, takže tenhle soubor přidá čtyři hooky vedle pěti dodaných. Až skončíš,
  smaž ho.
- **Žádný `matcher`**, takže oba hooky na nástroje se spustí pro každý nástroj.
- **`(cat; echo) >>`**: payload přijde jako jeden řádek bez koncového znaku nového řádku.
  `echo` ho doplní, takže každá událost je jeden řádek JSONL.
- **`; exit 0`**: hook `preToolUse`, který skončí nenulovým kódem, **volání nástroje
  zamítne**. Výpisový hook, který by selhal z hloupého důvodu, by zablokoval celou session.
- **`.github/hooks/logs/`** je v `.gitignore`. Logy obsahují tvoje prompty a výstupy
  nástrojů; nesdílej je, dokud si je nepřečteš.

Spusť **novou** session (soubory hooků se čtou při startu CLI) a zadej jí tři úkoly.
Jednorázově:

```bash
copilot -p "Do exactly these three things, in order, then stop: (1) read the file README.md with the file view tool; (2) run the shell command 'git status --short'; (3) create a new file named .github/hooks/logs/note.txt containing the single word alpha. Do not do anything else." \
  --trust-folder --no-ask-user --allow-tool='write'
```

Pak se podívej, co nástroje dostaly:

```bash
jq -c '{toolName, toolArgs}' .github/hooks/logs/preToolUse.jsonl
```

Tenhle soubor a tenhle typ promptu běžely na Copilot CLI 1.0.114 v cvičném repozitáři
(soubory se tam jmenovaly `note.txt` a `created.txt`). Model byl z rodiny GPT. Výstup,
s cestou zkrácenou na `<repo>`:

```json
{"toolName":"view","toolArgs":{"path":"<repo>/note.txt"}}
{"toolName":"bash","toolArgs":{"command":"git status --short","description":"Check git status"}}
{"toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Add File: <repo>/created.txt\n+alpha\n*** End Patch\n"}
```

Celé payloady, jeden na událost (id zkrácená):

```json
// sessionStart
{"sessionId":"af3889b0-...","timestamp":1795259836973,"cwd":"<repo>","source":"new","initialPrompt":"Do exactly these three things, ..."}

// userPromptSubmitted
{"sessionId":"cf7325ea-...","timestamp":1795258198411,"cwd":"<repo>","prompt":"Do exactly these three things, ..."}

// preToolUse
{"sessionId":"af3889b0-...","timestamp":1795259842921,"cwd":"<repo>","toolCallId":"call_8028...","toolName":"bash","toolArgs":{"command":"git status --short","description":"Check git status"}}

// postToolUse = preToolUse + toolResult
{"sessionId":"af3889b0-...","timestamp":1795259844348,"cwd":"<repo>","toolCallId":"custom_call_4ef2...","toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Add File: <repo>/created.txt\n+alpha\n*** End Patch\n","toolResult":{"resultType":"success","textResultForLlm":"Added 1 file(s): <repo>/created.txt"}}

// agentStop
{"sessionId":"af3889b0-...","timestamp":1795259845225,"cwd":"<repo>","transcriptPath":"/Users/you/.copilot/session-state/af3889b0-.../events.jsonl","stopReason":"end_turn","stop_hook_active":false}

// sessionEnd
{"sessionId":"cf7325ea-...","timestamp":1795258207094,"cwd":"<repo>","reason":"complete"}
```

Co si z toho odnést:

- **V payloadu není název události.** Skript zná svou událost jen podle toho, kde je
  zaregistrovaný.
- **`toolArgs` je objekt u `bash` a `view` a surový řetězec s patchem u `apply_patch`.**
  Řetězec s patchem není JSON. Skript, který na něm zavolá `jq '.toolArgs.path'`, dostane
  chybu.
- **Modely z rodiny GPT vytvářejí a upravují soubory přes `apply_patch`**, ne přes `edit` /
  `create`. V jiném pokusu tentýž model zapsal soubor v shellu pomocí
  `printf 'goodbye\n' > note.txt`. Matcher na editační nástroje takové volání nikdy neuvidí.
- **Cesty uvnitř patche přišly v jednom běhu relativní a v jiném absolutní.**
- **Procesy hooků startují v kořenu repozitáře.** Dostávají taky `COPILOT_PROJECT_DIR` (a
  stejnou hodnotu jako `CLAUDE_PROJECT_DIR`), `COPILOT_HOOK_DIR`, `COPILOT_HOOK_DEPTH=1` a
  `COPILOT_CLI=1`. Všech pět bylo vidět naživo a jsou uvedené v `copilot help environment`,
  takže kořen repa je zdokumentovaná proměnná. Skripty v tomhle repu ji nepotřebují;
  spoléhají na pracovní adresář.
- **Nástroje `edit` a `create` tady pozorovány nebyly**: testovací účet měl jen modely
  z rodiny GPT. Ukázky od GitHubu čtou cestu k souboru z `toolArgs.path`. Pokud máš v seznamu
  modelů model z rodiny Claude, tímhle krokem labu si to ověříš na svém stroji.

Úklid:

```bash
rm .github/hooks/payload-dump.json
rm -r .github/hooks/logs
```

## Soubory řádek po řádku

### Část 1: registrace (`.github/hooks/hooks.json`)

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "./.github/hooks/scripts/git-context.sh",
        "cwd": ".",
        "timeoutSec": 10
      }
    ],
    "preToolUse": [
      {
        "type": "command",
        "matcher": "bash|powershell",
        "bash": "./.github/hooks/scripts/block-destructive.sh",
        "cwd": ".",
        "timeoutSec": 10
      },
      {
        "type": "command",
        "matcher": "bash|powershell|view",
        "bash": "./.github/hooks/scripts/protect-secrets.sh",
        "cwd": ".",
        "timeoutSec": 10
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "matcher": "edit|create|str_replace_editor|apply_patch",
        "bash": "./.github/hooks/scripts/format.sh",
        "cwd": ".",
        "timeoutSec": 60
      }
    ],
    "agentStop": [
      {
        "type": "command",
        "bash": "./.github/hooks/scripts/run-tests.sh",
        "cwd": ".",
        "timeoutSec": 300
      }
    ]
  }
}
```

- `"version": 1` a `"hooks"`: pevná obálka. `hooks` mapuje **název události** na seznam
  položek.
- `"sessionStart"`, `"preToolUse"`, ...: názvy událostí v **camelCase**. CLI přijímá i aliasy
  v PascalCase (`PreToolUse`, `Stop`); s nimi se payload přepne na pole ve snake_case a názvy
  nástrojů z Claude Code (podle dokumentace). Tohle repo používá jen camelCase.
- Každá položka je **plochá**: vlastní `matcher`, vlastní příkaz. Žádný vnořený seznam
  `hooks: [...]` jako v `settings.json` Claude Code tu není.
- `"type": "command"`: spustí shellový příkaz. Je to výchozí hodnota; existují i `http` a
  `prompt` (viz [Volitelné parametry](#volitelné-parametry)).
- `"bash"`: příkazová řádka. Cesta je relativní vůči `cwd`.
- `"cwd": "."`: relativně ke **kořenu repozitáře**, ne k adresáři, ve kterém jsi spustil
  `copilot`. I tak spouštěj `copilot` z kořene repozitáře: běh `-p --trust-folder` spuštěný
  ve `web/` hooky přeskočil s hláškou *"Skipped repository hooks (../.github/hooks)
  because --trust-folder trusts only .../web, not the repository root"* (otestováno).
  Zdokumentovaný způsob, jak běh odjinud nasměrovat na kořen, je `-C <root>`.
- `"timeoutSec"`: výchozí hodnota je 30. Rychlé hooky mají 10, formátovač 60, běh testů 300.
  Když limit vyprší, hook se zabije a CLI pokračuje, jako by neběžel.
- `"matcher"`: regex na **název nástroje**, zkompilovaný jako `^(?:PATTERN)$`. Musí odpovídat
  celému názvu, takže `bash|powershell` znamená přesně jeden z těch dvou. `sessionStart` a
  `agentStop` se netýkají nástroje, takže matcher nemají.
- **Proč čtyři názvy pro jeden formátovač.** `edit` a `create` jsou klasické souborové
  nástroje, `str_replace_editor` je další editační nástroj a `apply_patch` používají modely
  z rodiny GPT. Matcher `edit|create` by se na těch modelech nikdy nespustil, a selhal by
  potichu.
- **Volání shellu odpovídají dvě položky `preToolUse`.** Běží obě. Pokud kterýkoli hook vrátí
  `deny`, volání se zablokuje.

### Část 2: `git-context.sh` (`sessionStart` → `additionalContext`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

command -v jq >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
```

- `set -euo pipefail` je tady bezpečné. Selhávající hook `sessionStart` se zaloguje a
  přeskočí; nic zablokovat nemůže.
- `cat >/dev/null` přečte payload a zahodí ho. Skript z něj žádné pole nepotřebuje.
- Díky dvěma úvodním kontrolám hook nedělá nic bez `jq` nebo mimo git checkout. Každá cesta
  „není co dělat“ končí `exit 0`.

```bash
branch=$(git branch --show-current 2>/dev/null)
branch=${branch:-"(detached HEAD)"}
changes=$(git status --porcelain 2>/dev/null)

if [ -z "$changes" ]; then
    context="Git: on branch $branch, working tree clean."
else
    count=$(printf '%s\n' "$changes" | wc -l | tr -d ' ')
    # Cap the list so a huge diff cannot flood the context window.
    files=$(printf '%s\n' "$changes" | head -10 | awk '{print $NF}' | paste -sd ',' - | sed 's/,/, /g')
    context="Git: on branch $branch, $count uncommitted file(s): $files"
    if [ "$count" -gt 10 ]; then
        context="$context, ..."
    fi
fi

# jq escapes quotes and backslashes in file names.
jq -cn --arg context "$context" '{additionalContext: $context}'
```

- Sestaví jeden řádek, například
  `Git: on branch main, 2 uncommitted file(s): README.cs.md, README.md`.
- `head -10` seznam omezí. Za tenhle text platíš tokeny v každé session.
- `jq -cn --arg ...` vypíše jeden JSON objekt. `additionalContext` je jediné pole, které
  `sessionStart` zpracuje. Naživo na 1.0.114 model odpověděl na „která branch, co není
  commitnuté“ z tohohle řádku, aniž zavolal nástroj.
- **Je to snímek.** Pořídí se jednou, při startu session, a neobnovuje se.
- **Proč `sessionStart`, a ne každý prompt.** U `userPromptSubmitted` si zdroje protiřečí:
  reference hooků říká, že výstup hooku z konfiguračního souboru se zahodí, changelog CLI
  říká, že `additionalContext` se k modelu dostane. `sessionStart` je událost, u které se
  reference, changelog i živý test shodnou. (*Tutoriál* k hookům pořád tvrdí, že výstup
  `sessionStart` se ignoruje. Je zastaralý.)

### Část 3: `block-destructive.sh` (`preToolUse` → deny)

```bash
set -uo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "block-destructive hook: jq is not installed, guard is inactive" >&2
    exit 0
fi
```

- **Bez `-e`.** Hook `preToolUse`, který skončí nenulovým kódem, volání nástroje zamítne
  (`Denied by preToolUse hook (hook errored)`, podle dokumentace). S `-e` by každý neúspěšný
  `grep` zablokoval každý shellový příkaz. Skript nesmí nikdy selhat omylem.
- Bez `jq` je pojistka vypnutá a hlásí to na stderr. Alternativou by bylo repo, kde neběží
  žádný shellový příkaz, dokud si nenainstaluješ `jq`.

```bash
# toolArgs arrives as an object; older versions sent it as a JSON-encoded string.
command=$(printf '%s' "$input" | jq -r '
    (.toolArgs // {})
    | if type == "string" then (fromjson? // {}) else . end
    | if type == "object" then (.command // "") else "" end' 2>/dev/null)
```

- Tři tvary, jeden výraz: **objekt** se použije tak, jak je, **řetězec s JSONem** se
  naparsuje přes `fromjson` a cokoli jiného (řetězec s patchem, `null`) se změní na prázdný
  příkaz. Skript funguje, ať tvoje verze posílá kterýkoli tvar.

```bash
deny() {
    jq -cn --arg reason "$1" '{permissionDecision: "deny", permissionDecisionReason: $reason}'
    exit 0
}
```

- **Takhle hook blokuje:** návratový kód 0 a jeden JSON objekt s
  `permissionDecision: "deny"`. Důvod jde **modelu**, který uvidí
  `Denied by preToolUse hook: <reason>`. Důvod piš jako instrukci: co má udělat místo toho.
- Naživo: deny platí, i když session startovala s `--allow-tool='shell'`.

```bash
# Wiping build output is routine; any other recursive force-delete is not.
# Flags are checked separately so `rm -rf`, `rm -fr` and `rm -r -f` all match.
if printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]' \
    && printf '%s' "$command" | grep -Eq '[[:space:]](-[[:alpha:]]*[rR]|--recursive)' \
    && printf '%s' "$command" | grep -Eq '[[:space:]](-[[:alpha:]]*f|--force)' \
    && ! printf '%s' "$command" | grep -Eq '^rm -rf (\./)?((engine/|api/)?build|web/dist)/?$'; then
    deny "block-destructive hook: recursive force-delete is blocked. Only build output (build, engine/build, api/build, web/dist) may be removed this way; delete specific files instead."
fi
```

- Tři `grep`y: je tam `rm`, je tam rekurzivní přepínač, je tam přepínač force.
- Čtvrtý je **výjimka** a je ukotvený na obou koncích. `rm -rf web/dist` projde.
  `cd web && rm -rf dist` se zamítne, protože celý příkaz není přesně v povoleném tvaru.

Zbylá čtyři pravidla mají stejný vzor:

| Blokováno | Myšlenka regexu | Povolená náhrada |
|-----------|-----------------|------------------|
| `git reset --hard` | `git reset` a kdekoli za ním `--hard` | `git stash`, `git reset --soft` |
| `git push -f` / `--force` | samotné `-f` nebo `--force` za `git push` | `git push --force-with-lease` |
| `git clean -f` | jakákoli skupina přepínačů obsahující `f` | nejdřív `git clean -n` |
| `git checkout -- .` / `git restore .` | cesta je přesně `.` | obnova jednotlivých souborů |

- **Ticho znamená „bez názoru“.** Žádný výstup a exit 0: rozhodne běžný tok oprávnění.
- **Porovnává text, takže má falešné poplachy.** Otestováno:
  `echo "never run git reset --hard" >> notes.md` se zamítne, protože ta slova v příkazu
  jsou.
- **Není to bezpečnostní hranice.** `bash -c "git re""set --hard"` projde (otestováno). Hook
  se vzory zastaví nehody, ne úmysl. Hranicí je sandbox
  ([Ukázka 8](08-permissions-sandbox.cs.md)).
- `permissionDecision` přijímá i `allow` a `ask` a hook může vrátit `modifiedArgs`, kterými
  volání přepíše (podle dokumentace; tady se nepoužívá). V autopilotu se `ask` zamítne,
  protože nemá kdo odpovědět.

### Část 4: `protect-secrets.sh` (`preToolUse` → deny)

Zaregistrovaný s `"matcher": "bash|powershell|view"`: oba shelly **a** nástroj pro čtení
souborů.

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

- `.path // .command`: `view` nese `path`, shell nese `command`. Jedna proměnná pokryje
  obojí.
- Regex má tři části: `.env` musí být na začátku řetězce nebo za znakem, který není součástí
  slova; volitelná přípona jako `.local`; pak konec nebo znak, kterým název souboru
  pokračovat nemůže. Takže `.env`, `config/.env` a `.env.local` odpovídají; `.envrc` a
  `environment.ts` ne.
- **Proč tenhle hook existuje.** Pravidlo `--deny-tool='read(.env)'` blokuje jen nástroj
  `view`. `cat .env` v shellu v živém testu obsah stejně vrátil.
  [Ukázka 8](08-permissions-sandbox.cs.md) to reprodukuje.
- **Jeho limity, otestované s podvrženým stdin:** `cat .e*` a `grep -r SECRET .` projdou,
  protože název v příkazu není. `grep -n .env .gitignore` se zamítne, i když žádné tajemství
  nečte. Pojistka, ne hranice.
- **Nehlídá zápisy.** Matcher neobsahuje žádný editační nástroj. Chceš-li je přidat, rozšiř
  matcher a cestu čti z textu patche tak, jak to dělá `format.sh`.

### Část 5: `format.sh` (`postToolUse` → `additionalContext`)

```bash
input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
[ -x web/node_modules/.bin/prettier ] || exit 0
```

- Před `cd web && npm ci` žádný Prettier není a hook mlčí.

```bash
# The file tools pass an object with a `path`. apply_patch (used by some models
# instead of edit/create) passes the raw patch text, so the paths are read from
# its "*** Add File:" / "*** Update File:" headers.
paths=$(printf '%s' "$input" | jq -r '
    .toolArgs
    | if type == "object" then (.path // empty)
      elif type == "string" then (split("\n")[] | capture("^\\*\\*\\* (Add|Update) File: (?<path>.+)$")? | .path)
      else empty end' 2>/dev/null)
```

- **Dva tvary, dvě větve.** Kvůli tomuhle existuje krok 1 labu.
  - Objekt: `edit` a `create` předávají `{"path": "...", ...}` (podle ukázek GitHubu; `view`
    byl s tímhle tvarem vidět naživo). Vezmi `.path`.
  - Řetězec: `apply_patch` předává text patche. Rozděl ho na řádky a nech si ty, které
    vypadají jako `*** Add File: <path>` nebo `*** Update File: <path>`. Jeden patch může
    sáhnout na víc souborů, takže výsledek je seznam.
- Skript, který by uměl jen objekt, by na modelu z rodiny GPT nikdy nic nezformátoval a nic
  by ti to neřeklo.

```bash
formatted=""
while IFS= read -r path; do
    [ -n "$path" ] || continue
    # Paths arrive absolute or relative depending on the tool; compare from the repo root.
    relative=${path#"$PWD"/}
    case "$relative" in
        web/src/*.ts | web/src/*.tsx | web/src/*.css)
            if [ -f "$relative" ] && web/node_modules/.bin/prettier --write "$relative" >/dev/null 2>&1; then
                formatted="$formatted ${relative##*/}"
            fi
            ;;
    esac
done <<EOF
$paths
EOF
```

- `${path#"$PWD"/}` odřízne z absolutní cesty kořen repa. Hook běží v kořenu, takže `$PWD`
  je kořen.
- `case` propustí jen webové zdrojáky. Ve vzoru `case` odpovídá `*` i znaku `/`, takže
  podadresáře `web/src/` jsou zahrnuté.
- `prettier --write` přepíše soubor na místě.

```bash
if [ -n "$formatted" ]; then
    jq -cn --arg files "$formatted" \
        '{additionalContext: ("format hook: Prettier reformatted" + $files + ". Re-read the file before editing it again.")}'
fi
```

- **Proč to říkat modelu.** Poté, co formátovač proběhl, je představa modelu o souboru
  zastaralá. Jeho další `edit` nebo patch se nemusí aplikovat. U `postToolUse` se
  `additionalContext` připojí k výsledku nástroje, takže si ho model přečte ve stejném kole
  (podle dokumentace; kontexty z více hooků se spojí a oříznou na 10 KB).
- Zpráva se pošle vždy, když Prettier proběhl bez chyby, i kdyby soubor už zformátovaný byl.
  V nejhorším to stojí jedno přečtení navíc.
- **Proč se tu neformátuje Kotlin.** Formátování Kotlinu znamená Gradle task a tenhle hook
  se spouští po každé jednotlivé úpravě. Start Gradlu na každou úpravu je moc pomalý, takže
  skript nechává Kotlin být. Tenhle build žádný formátovač Kotlinu vůbec nemá; styl Kotlinu
  nese soubor s instrukcemi, což je rada. Pokud formátovač přidáš, pouštěj ho z `agentStop`
  nebo v CI.
- **Co nevidí.** Soubor zapsaný přes přesměrování v shellu je volání `bash`. Tenhle matcher
  se nespustí.

### Část 6: `run-tests.sh` (`agentStop`, poradní)

```bash
# Drain the event JSON on stdin; this hook needs none of its fields.
cat >/dev/null

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# agentStop fires after every turn, including plain questions. Only test what changed.
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
failed=""

if printf '%s\n' "$changed" | grep -Eq '^(engine|api)/'; then
    ./gradlew test --quiet >/dev/null 2>&1 || failed="$failed gradle"
fi

if printf '%s\n' "$changed" | grep -Eq '^web/src/' && [ -d web/node_modules ]; then
    (cd web && npm test --silent >/dev/null 2>&1) || failed="$failed web"
fi

if [ -n "$failed" ]; then
    # Exit code 2 shows stderr to the user as a warning without blocking the turn.
    echo "run-tests hook: tests are failing in:$failed" >&2
    exit 2
fi

exit 0
```

- `agentStop` se spustí, když agent dokončí kolo, a to **každé** kolo, i po obyčejné otázce.
  Skript se proto nejdřív zeptá gitu, co není commitnuté, a testuje jen ty části: Gradle pro
  `engine/` nebo `api/`, Vitest pro `web/src/`.
- Čistý strom znamená žádný běh testů a žádné zdržení. Špinavý strom znamená běh testů po
  každém kole, dokud necommitneš.
- Výstup testů se zahodí. Zůstane jen seznam částí, které selhaly.
- **Návratový kód 2 a stderr = varování.** U `agentStop` neblokuje. V JSONL běhu dorazí jako
  událost `session.warning` s `warningType: "hook"` (naživo).
- `timeoutSec` je 300. Běh testů, který trvá déle, se zabije a kolo skončí, jako by hook
  neběžel.
- **Poradní záměrně**: živá workshopová session se nesmí zaseknout ve smyčce „oprav testy“.
  Blokující variantu ukazuje [Druhý hook: brána na testech](#druhý-hook-brána-na-testech).

## Otestuj hook s podvrženým stdin

Hook nelaď uvnitř session. Hook je program, který čte stdin, tak ho nakrm ručně. Spouštěj
z kořene repa. Uvedený výstup je skutečný.

```bash
H=.github/hooks/scripts

echo '{"toolName":"bash","toolArgs":{"command":"git push --force origin main"}}' | $H/block-destructive.sh
# {"permissionDecision":"deny","permissionDecisionReason":"block-destructive hook: force-push is blocked. Use git push --force-with-lease, or ask the user."}

echo '{"toolName":"bash","toolArgs":{"command":"git status"}}' | $H/block-destructive.sh; echo "exit=$?"
# exit=0            (no output = no opinion)

echo '{"toolName":"bash","toolArgs":"{\"command\":\"git reset --hard HEAD~1\"}"}' | $H/block-destructive.sh
# {"permissionDecision":"deny","permissionDecisionReason":"block-destructive hook: git reset --hard discards uncommitted work. Use git stash, or git reset --soft."}
#                   (toolArgs as a JSON string works too)

echo '{"toolName":"view","toolArgs":{"path":"/repo/web/.env.local"}}' | $H/protect-secrets.sh
# {"permissionDecision":"deny","permissionDecisionReason":"protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need."}

echo '{"toolName":"bash","toolArgs":{"command":"cat .envrc"}}' | $H/protect-secrets.sh; echo "exit=$?"
# exit=0

$H/git-context.sh </dev/null
# {"additionalContext":"Git: on branch main, 2 uncommitted file(s): README.cs.md, README.md"}
#                   (your branch and file list will differ)
```

`format.sh` potřebuje `web/node_modules` (`cd web && npm ci`). Prettier pouští doopravdy, tak
ho nasměruj na soubor, který už zformátovaný je:

```bash
echo "{\"toolName\":\"edit\",\"toolArgs\":{\"path\":\"$PWD/web/src/App.tsx\"}}" | $H/format.sh
# {"additionalContext":"format hook: Prettier reformatted App.tsx. Re-read the file before editing it again."}

printf '%s' '{"toolName":"apply_patch","toolArgs":"*** Begin Patch\n*** Update File: web/src/api.ts\n@@\n-x\n+y\n*** End Patch\n"}' | $H/format.sh
# {"additionalContext":"format hook: Prettier reformatted api.ts. Re-read the file before editing it again."}

echo '{"toolName":"edit","toolArgs":{"path":"engine/src/main/kotlin/Board.kt"}}' | $H/format.sh; echo "exit=$?"
# exit=0            (Kotlin is skipped)
```

`run-tests.sh` s čistými `engine/`, `api/` a `web/src/`:

```bash
echo '{}' | $H/run-tests.sh; echo "exit=$?"
# exit=0
```

Tři věci, které zkontroluj u každého hooku: výstup je **jeden** JSON objekt nebo nic,
návratový kód je 0 na každé cestě „není co dělat“ a hook přežije tvary payloadu z kroku 1
labu.

## Vytvoř si vlastní hook, krok za krokem

1. **Vypiš si payload** události, kterou chceš (krok 1 labu). Skript piš proti tomu, co jsi
   viděl.
2. **Napiš skript** do `.github/hooks/scripts/`. Kostra: `input=$(cat)`, přes `jq` vytáhni,
   co potřebuješ, tak, aby to sneslo objekt i řetězec, proveď akci, vypiš nejvýš jeden JSON
   objekt, `exit 0`.
3. **Udělej ho spustitelným**: `chmod +x .github/hooks/scripts/my-hook.sh`.
4. **Zaregistruj ho** v `hooks.json` nebo v novém souboru `*.json` vedle něj. Dej mu
   `matcher`, pokud jde o událost nástroje, a `timeoutSec`, který odpovídá.
5. **Otestuj ho s podvrženým stdin**, včetně jednoho payloadu, který má ignorovat.
6. **Spusť novou session** a zadej `/env`. Vypíše hooky, které se načetly.
7. **Commitni** JSON soubor i skript. Od té chvíle tvůj hook spouští každý, kdo složce
   důvěřuje.

## Vyzkoušej demo

Spusť `copilot` v kořenu repa a potvrď dotaz na důvěru ke složce. Hooky z repa se načtou až
potom.

1. **Kontext.** Změň libovolný soubor *před* startem session a pak se zeptej:

   > *„Bez spuštění jakéhokoli nástroje: na které branchi jsem a co není commitnuté?“*

   Odpověď pochází z vloženého řádku (naživo).

2. **Pojistka proti destruktivním příkazům.**

   > *„Spusť přesně tento příkaz: git push --force nowhere main“*

   Hook ho zamítne dřív, než git poběží. Model odcituje
   `Denied by preToolUse hook: block-destructive hook: force-push is blocked. ...` a nabídne
   `--force-with-lease`. Remote `nowhere` neexistuje, takže by příkaz byl neškodný i bez
   hooku. (Pro tenhle návod se odpověď skriptu na tento příkaz testovala s podvrženým stdin;
   živé zamítnutí se testovalo s jiným blokovaným příkazem.)

3. **Pojistka na tajemství.**

   ```bash
   echo "DUMMY_SECRET=not-real" > .env      # .env is gitignored
   ```

   > *„Spusť přesně tento jeden shellový příkaz a odcituj jakoukoli zprávu, kterou dostaneš: cat .env“*

   Výsledek naživo: `Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and
   stay out of the session. ...`. Soubor potom smaž: `rm .env`.

4. **Formátovač** (potřebuje `cd web && npm ci`; pro tenhle návod se naživo nepouštěl):

   > *„Přidej do web/src/keys.ts exportovanou funkci isWasdKey(key: string): boolean. Napiš ji s dvojitými uvozovkami a středníky.“*

   Pak `git diff web/src/keys.ts`. Konfigurace Prettieru má `semi: false` a
   `singleQuote: true`, takže soubor na disku má jednoduché uvozovky a žádné středníky, ať
   model napsal cokoli. Vrať to přes `git restore web/src/keys.ts`.

5. **Testy.** Dokud jsou ve `web/src/` necommitnuté změny, každé kolo končí během Vitestu.
   Zelená znamená ticho. Selhání se ukáže jako varování: `run-tests hook: tests are failing in: web`.

## Druhý hook: brána na testech

`run-tests.sh` varuje. Aby se z „testy musí projít, než skončíš“ stalo pravidlo, musí hook
poslat agenta zpátky do práce. Uděláš to ve Cvičení 3 v [exercises.cs.md](exercises.cs.md).
Mechanismus:

- **Blokuje jen JSON na stdout.** Skript skončí s kódem 0 a vypíše
  `{"decision": "block", "reason": "..."}`. CLI pak spustí další kolo agenta a `reason` dorazí
  jako další uživatelská zpráva (naživo). `decision` přijímá i `"allow"`.
- **Návratové kódy `agentStop` zablokovat neumí.** Exit 2 je varování (naživo). Jakýkoli jiný
  nenulový kód se zaloguje a přeskočí (podle dokumentace). Návratový kód jako rozhodnutí
  berou jen `preToolUse` a `permissionRequest`.
- **`stop_hook_active`** je `false` při běžném zastavení a `true` při zastavení, které
  následuje po bloku (naživo). Skript díky němu pozná, že agenta už jednou zpátky poslal.
- **Strop.** Po 8 blocích za sebou CLI hook přebije a kolo ukončí (podle dokumentace).
  Nespoléhej na to: osm běhů Gradlu a osm kol agenta je pomalých a stojí kredity. Omez se
  sám přes `stop_hook_active`.

Dvě změny ve skriptu. Nahoře si payload nech, místo abys ho zahodil:

```bash
# Keep the payload this time: stop_hook_active says whether Copilot was already sent back.
input=$(cat)
```

A nový konec, který nahradí blok `if [ -n "$failed" ]`:

```bash
if [ -n "$failed" ]; then
    already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
    if [ "$already_blocked" != "false" ]; then
        # Copilot was sent back once and the tests still fail (or jq is missing):
        # warn the user and let the turn end instead of looping.
        echo "run-tests hook: tests are still failing in:$failed" >&2
        exit 2
    fi
    # Exit 0 plus one JSON object on stdout is the only form that blocks.
    jq -cn --arg failed "$failed" \
        '{decision: "block", reason: ("run-tests hook: tests are failing in:" + $failed + ". Run them, fix the cause, then finish.")}'
fi

exit 0
```

Otestováno s podvrženým stdin proti náhradnímu `gradlew`, který selhává:

```bash
echo '{"stopReason":"end_turn","stop_hook_active":false}' | .github/hooks/scripts/run-tests.sh
# {"decision":"block","reason":"run-tests hook: tests are failing in: gradle. Run them, fix the cause, then finish."}

echo '{"stopReason":"end_turn","stop_hook_active":true}' | .github/hooks/scripts/run-tests.sh; echo "exit=$?"
# run-tests hook: tests are still failing in: gradle
# exit=2
```

Co se změní, jakmile blokuje:

- Agent dostane **jedno** kolo navíc na opravu testů. Pokud pořád selhávají, dostaneš varování
  a kolo skončí. Chceš-li, aby to zkoušel až do stropu, větev se `stop_hook_active` vyhoď.
- `reason` je prompt. „Testy selhávají“ nutí agenta hádat; pojmenuj část a řekni, co má
  udělat.
- Skript výstup testů zahazuje, takže agent musí testy pustit znovu, aby selhání viděl. Je to
  jedno volání nástroje a v `reason` díky tomu není stěna výstupu z Gradlu.
- Běh `-p` před ukončením počká na zablokované pokračování (podle changelogu).
- Brána platí i pro zastavení po obyčejné otázce, pokud je strom špinavý a červený.

## Události, matchery a způsoby selhání

### 14 událostí

Názvy jsou z reference hooků. „Naživo“ označuje, co bylo pozorováno na 1.0.114; zbytek je
podle dokumentace. Pomlčka znamená, že tenhle návod u dané události žádné výstupní pole
nepokrývá; než se na nějaké spolehneš, podívej se do
[reference hooků](https://docs.github.com/en/copilot/reference/hooks-reference).

| Událost | Kdy se spustí | Matcher na | Co hook může udělat (zohledněný výstup) |
|---------|---------------|------------|------------------------------------------|
| `sessionStart` | Začíná session. `source` je `startup`, `resume` nebo `new` | — | Přidat kontext: `additionalContext` (naživo). Jediné zpracované pole |
| `userPromptSubmitted` | Odešleš prompt. Payload obsahuje `prompt` (naživo) | — | Rozporné: reference říká, že výstup se zahodí, changelog říká, že `additionalContext` se k modelu dostane. Používej ho na logování |
| `userPromptTransformed` | Než prompt odejde modelu | — | Nahradit to, co model dostane: `modifiedTransformedPrompt`. Časová osa dál ukazuje tvůj originál |
| `preToolUse` | Před spuštěním nástroje (naživo) | název nástroje | Rozhodnout: `permissionDecision` `allow` / `deny` / `ask` s `permissionDecisionReason`; přepsat: `modifiedArgs`. Jakýkoli `deny` vyhrává (deny naživo) |
| `permissionRequest` | Před enginem pravidel oprávnění. Jen CLI. Ne pro čtení | název nástroje | `behavior` `allow` / `deny`, `message`, `interrupt` |
| `postToolUse` | Po **úspěšném** volání nástroje (naživo) | název nástroje | `additionalContext` připojený k výsledku nástroje; `modifiedResult` |
| `postToolUseFailure` | Po neúspěšném volání nástroje | — | — |
| `agentStop` | Agent dokončí kolo (naživo) | — | `decision: "block"` + `reason` vynutí další kolo (naživo) |
| `subagentStart` | Startuje subagent | název agenta | — |
| `subagentStop` | Subagent skončí | — | `decision` / `reason` jako u `agentStop`; `modifiedResponse` přepíše jeho odpověď |
| `preCompact` | Před kompakcí kontextu | spouštěč | — |
| `notification` | CLI vyvolá notifikaci | typ notifikace | — |
| `errorOccurred` | Nastala chyba | — | — |
| `sessionEnd` | Session končí. Payload obsahuje `reason` (naživo: `complete`) | — | — |

Vestavěný agent `general-purpose` události `subagentStart` / `subagentStop` nevysílá; ostatní
vestavění agenti a vlastní agenti ano (podle dokumentace).

Patnáctý název, `preMcpToolCall`, se objevuje v `copilot help environment` ve větě o HTTP
hoocích. Nápověda CLI ho jmenuje, jinak popsaný není.

### Návratové kódy

| Návratový kód | Význam | Výjimka |
|---------------|--------|---------|
| `0` | Stdout se naparsuje jako JSON výstup hooku. Prázdný nebo neparsovatelný výstup znamená výchozí chování | — |
| `2` | Varování; zobrazí se stderr | **Deny** u `preToolUse` a `permissionRequest` |
| jiný nenulový | Zaloguje se a přeskočí | `preToolUse` volání **zamítne**: je fail-closed |

- **Timeouty jsou fail-open, u každé události.** Hook `preToolUse`, který se zasekne, se po
  `timeoutSec` zabije, zobrazí se varování a volání nástroje proběhne. Pomalá pojistka není
  pojistka.
- **Pád na `preToolUse` je fail-closed.** Překlep ve skriptu pojistky zablokuje každé
  odpovídající volání nástroje. Proto `set -uo pipefail` bez `-e` a proto kontrola `jq`.
- **Jeden JSON dokument na stdout.** Dva objekty se spojí do neplatného JSONu a ignorují se.
  Ladicí text na stdout přes `echo` neposílej; použij stderr. Jedinou výjimkou jsou řádky ve
  tvaru `{"type":"progress","message":"..."}`, ty se odstraní.

### Matcher a názvy nástrojů

Matcher je regex, který musí odpovídat **celému** názvu nástroje. `bash` neodpovídá
`bash_extra` a `edit` neodpovídá `str_replace_editor`. Neplatný regex položku přeskočí; CLI
vypíše `! Invalid hook configuration in FILE: REASON`.

| Název nástroje | Co to je |
|----------------|----------|
| `bash` | Shell na macOS a Linuxu |
| `powershell` | Shell na Windows |
| `view` | Čtení souboru nebo adresáře |
| `create` | Vytvoření souboru |
| `edit` | Úprava souboru nahrazením řetězce |
| `str_replace_editor` | Další editační nástroj; CLI s ním tak zachází |
| `apply_patch` | Vytváření a úpravy přes patch, některé modely ho používají místo `edit` / `create` |

Další, na které možná budeš chtít matchovat: `glob`, `grep` (naživo viděn jako `rg`), `task`
(delegování na subagenta), `web_fetch`, `ask_user`, `skill`. Krok 1 labu ukáže názvy, které
používá tvoje session.

## Kde můžou hooky žít

Všechny zdroje se načtou a spojí, v pořadí policy, uživatel, projekt, pluginy. Pokud je
stejná událost na více místech, běží každá položka (podle dokumentace).

| Umístění | Rozsah | Poznámky |
|----------|--------|----------|
| `.github/hooks/*.json` | Repo, commitnuté | Tahle ukázka. Špatná položka se zahodí; zbytek souboru se načte |
| klíč `hooks` v `.github/copilot/settings.json` | Repo, commitnuté | Inline. Přísnější: jedna neplatná položka odmítne celé pole `hooks` |
| klíč `hooks` v `.github/copilot/settings.local.json` | Repo, tvoje | Totéž, běžně v gitignore |
| `~/.copilot/hooks/` | Ty, každé repo | Osobní hooky, například notifikace na `agentStop` |
| klíč `hooks` v `~/.copilot/settings.json` | Ty, každé repo | Inline hooky na úrovni uživatele |
| `hooks.json` nebo `hooks/hooks.json` pluginu | Kdo si plugin zapne | Viz [Ukázka 6](06-plugins.cs.md). Hooky pluginu dostávají navíc `COPILOT_PLUGIN_ROOT` |
| `hooks:` ve frontmatteru agenta | Dokud je ten agent vybraný | Jen CLI. Viz [Ukázka 5](05-agents.cs.md) |
| `.claude/settings.json`, `.claude/settings.local.json` | Repo | **Copilot CLI spouští i tyhle** |
| Spravované (policy) hooky | Nastavuje admin | Nejdou vypnout z repa ani tebou |

**Na řádku `.claude/` záleží, pokud repo slouží oběma nástrojům.** Hooky napsané pro Claude
Code pod `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop` nebo `SessionStart` běží na
odpovídajících událostech Copilota. Jejich matchery (`Bash`, `Read`, `Edit`, `Write`)
odpovídají nástrojům Copilota a jejich payload používá názvy polí z Claude Code (`tool_name`,
`tool_input`). Hook-pojistka pro Claude Code, který pod Copilotem selže, zamítne každé
odpovídající volání nástroje. Tohle repo adresář `.claude/` nemá, takže nic neběží dvakrát.

## Vedlejší efekty, o kterých je dobré vědět

- **Cloud agent načítá stejné soubory.** Podle dokumentace čte Copilot cloud agent
  `.github/hooks/*.json` z repa, na kterém pracuje. Tam se zohledňují jen položky `bash` /
  `command`, `ask` se změní na deny, `permissionRequest` a `notification` se nespouštějí a
  blok na `agentStop` se počítá do časového limitu jobu. Hook, který commitneš pro svůj
  terminál, běží taky v každém jobu cloud agenta na tom repu.
- **Hooky běží uvnitř sandboxu, když je zapnutý.** Podle dokumentace pak příkazové hooky
  z repa, uživatele a pluginů běží pod stejnou politikou jako shellové příkazy agenta (policy
  hooky zůstávají na hostiteli). Hook, který pouští `./gradlew test` nebo `npm test`, může
  selhat jen tam, například na přístupu k build cache. `/sandbox policy <hook command>`
  ukáže, co politika tomu příkazu dává. V tomto repu netestováno.
- **Přesměrování v shellu obejde matchery na editační nástroje.** Viděno naživo: model zapsal
  soubor přes `printf ... > note.txt`. To je volání `bash`. `format.sh` se pro něj nespustí a
  hook, který chrání soubory matcherem `edit|create|apply_patch`, ho nevidí. Pojistka na
  soubory se musí dívat i na shellové příkazy, což `protect-secrets.sh` dělá.
- **Paralelní volání nástrojů pouštějí své hooky `preToolUse` současně** (podle dokumentace).
  Hook, který zapisuje do sdíleného stavového souboru nebo logu, s tím musí počítat.
- **Běhy `-p` načítají hooky z repa jen pro důvěryhodnou složku.** Buď už složka důvěryhodná
  je, nebo předáš `--trust-folder` (naživo). Dokumentace jmenuje i proměnnou prostředí
  `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=true`; v `copilot help environment` není, takže dej
  přednost přepínači.
- **Commitnuté hooky jsou kód, který běží na strojích tvých kolegů.** Změnu v
  `.github/hooks/` reviduj stejně jako změnu v CI.

## Volitelné parametry

Pole jedné položky hooku (podle reference hooků; tohle repo používá prvních pět):

| Pole | Co dělá |
|------|---------|
| `type` | `command` (výchozí), `http` nebo `prompt` |
| `bash` | Příkazová řádka spouštěná bashem. Na Windows to vyžaduje bash v `PATH` (který, to přebije `COPILOT_BASH_PATH`) |
| `cwd` | Pracovní adresář, relativní ke kořenu repa nebo absolutní |
| `timeoutSec` | Počet sekund, než se hook zabije. Výchozí 30. `timeout` je alias |
| `matcher` | Regex na plnou shodu. Název nástroje u `preToolUse`, `postToolUse`, `permissionRequest`; ostatní viz tabulka událostí |
| `powershell` | Příkazová řádka pro PowerShell. Položky v tomhle repu žádnou nemají |
| `command` | Multiplatformní záloha, zkopíruje se do `bash` a `powershell`, když chybí |
| `exec` + `args` | Spustí program přímo, bez shellu. Jen CLI |
| `env` | Další proměnné prostředí pro proces hooku |

Další typy:

| Typ | Co běží | Omezení |
|-----|---------|---------|
| `http` | Pošle payload POSTem na `url` | U hooků, které rozhodují, musí být `https://`; loopback je blokovaný, pokud není `COPILOT_HOOK_ALLOW_LOCALHOST=1`. HTTP hook na `preToolUse` je fail-open |
| `prompt` | Odešle za tebe text nebo slash příkaz | Jen `sessionStart`, jen nové interaktivní session, nikdy v `-p` |

Přepínače:

| Klíč | Kde | Účinek |
|------|-----|--------|
| `"disableAllHooks": true` | Nejvyšší úroveň jednoho souboru s hooky | Přeskočí hooky toho souboru |
| `"disableAllHooks": true` | `settings.json` repa | Přeskočí každý hook z každého zdroje v tom repu, kromě policy hooků |
| `allowManagedHooksOnly`, `strictPluginOnlyCustomization` | Spravované nastavení (admin) | Blokují hooky z repa a uživatelské hooky. Pokud se ti hooky ve 2N nikdy nenačtou, zeptej se, jestli není některé z nich nastavené |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|-----------|----------|----------|
| **Copilot CLI** | ✅ Ano | Všechno v tomhle návodu. Otestováno na 1.0.114 |
| **Plugin pro IntelliJ IDEA** | ⚠️ Částečně | Čte `.github/hooks/`. Jediný zveřejněný seznam událostí je `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`. `sessionStart` ani `agentStop` nic nepotvrzuje, takže počítej s tím, že `git-context.sh` a `run-tests.sh` tam nedělají nic. V tomto repu netestováno |
| **Copilot cloud agent** | ⚠️ Částečně | Načítá `.github/hooks/*.json` (podle dokumentace). Jen `bash` / `command`, `ask` se změní na deny, žádný `permissionRequest`, žádná `notification` |

Víc k IntelliJ, všechno z dokumentace a z hlášení uživatelů, nic z toho tu netestováno:

- Deny z `preToolUse` je jediné rozhodnutí, o kterém se uvádí, že funguje. Jedno hlášení
  uživatele říká, že IDE ignoruje `modifiedArgs`.
- Podle hlášení uživatele volá vlastní agent IDE svůj terminálový nástroj `run_in_terminal`.
  Matcher `bash|powershell` by se pro něj pak nespustil. Než tam pojistce uvěříš, vypiš si
  payload v IDE.
- Matice podpory v dokumentaci pořád uvádí hooky v JetBrains IDE jako nepodporované, zatímco
  release notes pluginu je od verze 1.10.0 označují za obecně dostupné. Věř tomu, co naměříš.
- Viz [Ukázka 12](12-intellij.cs.md).

## Když něco nefunguje

- **Hook se nikdy nespustí** → soubory hooků se čtou při startu CLI. Spusť novou session a
  pak zkontroluj `/env`.
- **Hook se nikdy nespustí a `/env` ho nevypíše** → složka není důvěryhodná. Hooky z repa se
  načtou až po dotazu na důvěru; v `-p` přidej `--trust-folder`. Pořád nic: hooky z repa může
  blokovat spravované nastavení.
- **`! Invalid hook configuration in FILE: REASON` při startu** → špatná položka, často
  neplatný regex v `matcher`. V `.github/hooks/*.json` se zahodí jen ta položka.
- **„Permission denied“ od hooku** → skript není spustitelný. `chmod +x`.
- **Každý shellový příkaz se najednou zamítá s `Denied by preToolUse hook (hook errored)`** →
  skript `preToolUse` končí nenulovým kódem. Pusť ho s podvrženým stdin a podívej se na
  návratový kód. Zkontroluj `set -e`.
- **Pojistka funguje v testu s podvrženým stdin, ale v session ne** → matcher neodpovídá
  skutečnému názvu nástroje, nebo má `toolArgs` jiný tvar. Zopakuj krok 1 labu.
- **Formátovací hook nedělá nic** → chybí `web/node_modules` (`cd web && npm ci`), nebo je
  soubor mimo `web/src/`, nebo ho model zapsal přes shell.
- **JSON hooku se ignoruje** → na stdout se vypsalo ještě něco jiného. Jeden JSON objekt, nic
  víc.
- **Hook `agentStop` skončí s 1 nebo 2 a agent se stejně zastaví** → tak je to navržené.
  Blokuj přes `{"decision":"block","reason":"..."}` a exit 0.
- **Každé kolo trvá minutu** → `run-tests.sh` pouští Gradle, dokud jsou v `engine/` nebo
  `api/` necommitnuté změny. Commitni, nebo použij stash.
- **Pojistka blokuje neškodný příkaz** → porovnává text. Přeformuluj příkaz, nebo dej text do
  souboru.
- **Hooky se pod sandboxem chovají jinak** → běží uvnitř něj. Viz
  [Ukázka 8](08-permissions-sandbox.cs.md).

Dál: [Ukázka 4: MCP připojení](04-mcp.cs.md).

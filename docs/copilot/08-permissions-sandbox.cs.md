> 🌍 Číst v jazyce: [English](08-permissions-sandbox.md) | **Česky**

# 08 · Oprávnění a sandbox

> ⏱ 15 min (10 demo + 5 vyzkoušení) · Dokumentace: [Allowing and denying tool use](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/allowing-tools) · [Tool permission patterns](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#tool-permission-patterns) · [Using local sandboxing](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/using-local-sandboxing) · Ověřeno na Copilot CLI 1.0.114

## Ve zkratce

**Potřebuješ:** CLI a launcher `scripts/copilot-ws.sh`. Pro sandbox: macOS, Linux nebo Windows.

**K čemu to je:** Oprávnění rozhodují, co smí agent udělat, aniž by se tě ptal: které příkazy, které soubory, které cesty. Sandbox k tomu přidá plot na úrovni operačního systému kolem shellových příkazů.

**Tři nejužitečnější použití:**

1. Nech buildy a testy běžet bez dotazu při každém volání (`shell(./gradlew:*)`).
2. Drž tajné údaje, třeba `.env`, mimo dosah agenta.
3. Pusť Copilot bez obsluhy, ve skriptu nebo přes noc, přesně s právy, která potřebuje, a s žádnými dalšími.

## Co jsou oprávnění?

CLI se zeptá, než spustí shellový příkaz, upraví soubor, sáhne na cestu nebo URL mimo pracovní
adresář nebo zavolá MCP nástroj. Příkazy, které rozpozná jako jen pro čtení, běží bez ptaní,
stejně jako proběhl `list_issues` vestavěného GitHub serveru ([05](05-mcp.cs.md)). **Žádný
commitnutý soubor s oprávněními neexistuje**: `.github/copilot/settings.json` žádná pravidla pro
nástroje nepřijímá. Pravidla přicházejí ze tří míst a deny vyhrává nad každým allow, včetně
`--allow-all`:

- **Přepínače při spuštění** `--allow-tool` / `--deny-tool`: jeden běh. Repo je sdílí jako launcher.
- **Tvoje uložená schválení** v `~/.copilot/permissions-config.json`: jen allow, jen tvoje, pro každé repo zvlášť.
- **Hooky** v `.github/hooks/` ([04](04-hooks.cs.md)): každá session v důvěryhodné složce; umí zamítnout.

## Co dělá tahle ukázka

```
scripts/copilot-ws.sh                        ← launcher: three allow rules, two deny rules
.github/hooks/scripts/protect-secrets.sh     ← hook: keeps .env away from the shell too
.github/hooks/scripts/block-destructive.sh   ← hook: refuses destructive shell commands
```

Gradle, `npm test` a `npm run` běží bez dotazu, `.env` je zakázaný, na všechno ostatní se CLI ptá.

## Soubor řádek po řádku

`scripts/copilot-ws.sh` přejde do kořene repa, kde se najde `./gradlew` i hooky, a pak sám sebe
nahradí procesem `copilot`. Session spouštěj přes něj, ne přes holý `copilot`:

```bash
exec copilot \
    --allow-tool='shell(./gradlew:*)' \
    --allow-tool='shell(npm test)' \
    --allow-tool='shell(npm run)' \
    --deny-tool='read(.env)' \
    --deny-tool='write(.env)' \
    "$@"
```

- `shell(./gradlew:*)`: wrapper s libovolnými argumenty; `:*` znamená „a cokoli za tím“. Povolí
  každý task, včetně `bootRun` a čehokoli, co definuje build skript.
- `shell(npm run)`: každý npm skript, včetně `format`, který přepisuje soubory.
- `read(.env)`, `write(.env)`: vestavěné souborové nástroje nesmí otevřít ani změnit soubor jménem
  `.env` v žádném adresáři. Nepokrývá to `.env.local` ani shell.

## Syntaxe pravidel

Pravidlo je `kind(argument)`; argument je volitelný. Druhy: `shell`, `read`, `write`, `url`,
`memory` nebo název MCP serveru. Co odpovídalo v živých bězích:

| Pravidlo | Příkaz, který model spustil | Výsledek |
|---|---|---|
| `shell(./gradlew:*)` | `./gradlew :engine:test` | ✅ proběhne |
| `shell(gradlew:*)` | `./gradlew :engine:test` | ❌ neodpovídá: kmen se musí rovnat příkazu tak, jak je napsaný |
| `shell(./gradlew test)` | `./gradlew :engine:test` | ❌ neodpovídá: `:engine:test` není `test` |
| `shell(npm test)` nebo `shell(npm:*)` | `cd web && npm test` | ✅ proběhne: na prefixu `cd web &&` nezáleží |

`git`, `gh`, `npm`, `mvn`, `gradle` a podobné nástroje se porovnávají jen se svým **prvním**
podpříkazem: `shell(gh pr)` pokrývá `gh pr create` a taky `gh pr merge`; `shell(gh pr create)`
neodpovídá ničemu.

## Vyzkoušej demo

Krok 1 je demo, krok 2 je na tobě. Začni v kořenu repa:

1. **Díra:** mimo repo, takže se nenačte žádný hook.
   ```bash
   mkdir -p /tmp/perm-demo && cd /tmp/perm-demo && echo "DUMMY_SECRET=not-real" > .env
   copilot -p "This directory holds a dummy .env file made for a permissions demo. Step 1: read .env with the file view tool. Step 2: whatever happened in step 1, run the shell command: cat .env   Then report for each step whether it was refused, and quote any refusal message." --deny-tool='read(.env)' --trust-folder --no-ask-user; cd -
   ```
   Souborový nástroj je odmítnut: `Permission to run this tool was denied due to the following rules:
   read(.env)`. Pak `cat .env` vypíše `DUMMY_SECRET=not-real`. `read(...)` odpovídá čtení souborů
   vestavěnými nástroji; `cat` je shellový příkaz jen pro čtení a takové běží bez ptaní. V repu tu
   díru zavírá `protect-secrets.sh` ([04](04-hooks.cs.md)): `cat .env` vrátí
   `Denied by preToolUse hook: ...`. Porovnává text, takže `cat .e*` projde: je to pojistka.
2. **Bez obsluhy:** v kořenu repa, kde na dotaz nemá kdo odpovědět.
   ```bash
   scripts/copilot-ws.sh -p "Run exactly these three shell commands, one tool call each, in this order, and nothing else: (1) ./gradlew :engine:test --quiet   (2) cd web && npm run lint   (3) npx --version    Then reply with one line per command: RAN if it executed, DENIED if you were not permitted, quoting any denial message." --trust-folder --no-ask-user
   ```
   RAN, RAN, DENIED: `Permission denied because no interactive user response was available.`
   V bězích `-p` a v autopilotu se požadavek, který by vyvolal dotaz, zamítne, takže běh bez
   obsluhy potřebuje svá pravidla allow předem. `--trust-folder` načte hooky repa; žádný nástroj
   neschvaluje.

## Sandbox

Všechno, co agent čte, může nést instrukce (prompt injection): výsledek MCP, README, výstup
testů. Pravidla a hooky porovnávají text; sandbox je vrstva OS pod nimi a omezuje shellové
příkazy, včetně tvých příkazů přes `!`. Ve výchozím stavu je vypnutý; zapneš ho ty nebo tvoje
organizace, repo ne. `copilot --sandbox` nebo `/sandbox enable session` ho zapne pro jednu
session, `/sandbox enable` to uloží, `/sandbox policy` vypíše výslednou politiku. První
`/sandbox enable` nabídne instalaci certifikační autority pro proxy: Enter ji nainstaluje, `Esc`
pokračuje bez ní. Politika v našem běhu na macOS:

- **Souborový systém:** čtení i zápis: pracovní adresář, dočasný adresář, build cache
  (`~/.gradle/caches`, `~/.npm`). Jen pro čtení: systémové adresáře a adresáře z `PATH`. Zbytek
  tvého domovského adresáře je zavřený: `ls ~` selže s `Operation not permitted`.
  `/Library/Preferences` a `/etc` zůstaly čitelné, i když je politika neuvádí.
  `userPolicy.filesystem.deniedPaths` bere globy jako `**/.env`.
- **Síť:** odchozí a lokální spojení zůstávají povolená.
- **Přihlašovací údaje:** `git` a `gh` se přihlašují přes maskovací proxy a dostanou falešné
  hodnoty. Ostatní proměnné tvého shellu, třeba `AWS_ACCESS_KEY_ID`, zůstávají viditelné, dokud je
  nezamaskuješ.

> 🔷 **Jen Copilot:** sandbox běží nativně i na Windows a pojme i lokální MCP servery, LSP servery
> a rozšíření. Claude Code sandboxuje jen shellové příkazy, na macOS, Linuxu a WSL2.

## Vytvoř si vlastní, krok za krokem

1. Pusť session bez přepínačů; příkazy, na které se CLI zeptá, jsou tví kandidáti.
2. Povol jen příkazy buildu a testů, kmen tak, jak se píše. `git push` a nasazení nech na dotazu.
3. Každé pravidlo otestuj v běhu `-p`, přepínače commitni jako launcher a pravidla, která musí
   platit vždy, dej do hooku.

| Stack | Pravidlo v launcheru | Stav |
|---|---|---|
| Java, Kotlin backend, Android, automatizace testů (Gradle) | `shell(./gradlew:*)` | ✅ spuštěno tady |
| React / TypeScript | `shell(npm test)`, `shell(npm run)` | ✅ spuštěno tady |
| iOS | `shell(xcodebuild:*)` | ⚠️ v tomto repu nespuštěno |
| Android zařízení | `shell(adb:*)`; zahrnuje i `adb uninstall` a `adb shell` | ⚠️ v tomto repu nespuštěno |

## Volitelné parametry

| Přepínač | Co dělá |
|---|---|
| `--available-tools` / `--excluded-tools` | Které nástroje model vidí. Zamítnutý nástroj vrátí chybu; vyloučený nástroj neexistuje |
| `--allow-all` (`--yolo`) | Schválí nástroje, cesty a URL. Pravidla `--deny-tool`, pravidla organizace a dotazy na obejití sandboxu platí dál. V session vybírá režim `/permissions` (Manual Approval, Assisted Permissions, Allow All); `/permissions show` vypíše režim, ne pravidla |
| `--add-dir <dir>`, `--allow-all-paths` | Přístup k souborům mimo pracovní adresář |

Kompletní reference: [Tool permission patterns](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#tool-permission-patterns) · [Configuring local sandbox settings](https://docs.github.com/en/copilot/how-tos/cloud-and-local-sandboxes/configuring-local-sandbox-settings) · `copilot help permissions` · `copilot help sandbox`

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|---|---|---|
| ✅ Přepínače, uložená schválení, hooky, sandbox | ⚠️ Plugin spouští vlastní přibalený CLI runtime, takže launcher a jeho přepínače se neuplatní. Hooky v `.github/hooks/` se čtou | ⚠️ Neběží na tvém stroji: žádný launcher, žádné `~/.copilot`, žádný lokální sandbox. Hooky repa se načtou |

## Copilot vs Claude Code

Claude Code: `permissions.allow` / `ask` / `deny` v commitnutém `.claude/settings.json` a k tomu
sandbox pro Bash. Copilot žádný commitnutý soubor s pravidly nemá, takže repo dodává launcher a
hooky. `--assisted-approval` (LLM soudce, ne bezpečnostní hranice) odpovídá režimu Auto v Claude Code.

> 🔷 **Jen Copilot:** organizace (viz [předletová kontrola](preflight.cs.md)) může CLI vypnout jako celek a uplatnit na něj [content exclusion](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/content-exclusion) z GitHubu.
> Claude Code nemá ani jedno; nejbližší obdobou je spravované pravidlo deny.

## Když něco nefunguje

- **`-p`: „Permission denied because no interactive user response was available.“** → příkaz není pokrytý žádným pravidlem allow nebo sahá na cestu mimo pracovní adresář (`--add-dir`).
- **Žádný dotaz tam, kde jsi ho čekal** → příkaz je jen pro čtení nebo sis dřív uložil schválení; `/reset-allowed-tools` je smaže.

Dál: [09 · Evaly](09-evals.cs.md)

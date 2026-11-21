> 🌍 Číst v jazyce: [English](exercises.md) | **Česky**

# Cvičení: jeden úkol na mechanismus

> Ověřeno na Copilot CLI 1.0.114 · každý patch s řešením jde aplikovat na čistý `main` a projde
> buildem (`ex5-undo.patch` až po aplikaci `ex5.patch`) · většina promptů byla jednou přehrána
> v režimu `-p` na testovacím účtu, cvičení 0 i v interaktivní session; krok, který nikdy neběžel,
> je označený ⚠️

## Jak s tím pracovat

1. Každé cvičení začíná z čistého `main` a na ostatních nezávisí. Před každým:
   `git stash -u && git switch -c ex-N main` odloží zbytky; `git status --short` je prázdný.
2. Copilota spouštěj přes `scripts/copilot-ws.sh` z kořene repa.
3. Kód generuješ, nepíšeš. Vlož prompt, přečti plán, zkontroluj důkazy
   (testy, `/diff`). Smyčku popisuje [01 · Začínáme](01-getting-started.cs.md).
4. Když vyprší časový limit, přestaň. Svůj pokus odlož (na rozdělané práci patch selže) a aplikuj řešení:
   `git stash -u && git apply docs/copilot/solutions/exN.patch`. Výpis jeho souborů: `git apply --stat <patch>`.
5. Tvůj model nenapíše stejný kód jako řešení. Testem je „Hotovo, když“, ne diff.

## V kostce

| # | Mechanismus | Úkol | Vrstva | Čas | Kdy |
|---|---|---|---|---|---|
| [0](#0-rozjezd---oprav-nastraženou-chybu-smyčkou-úrovně-5) | Smyčka úrovně 5 | Oprav spawn po tahu, který nic nezmění, nejdřív padající test | api | 7 min | blok 01 |
| [1](#1-instrukce---nauč-webové-konvence-a-pak-obarvi-dlaždice) | Instrukce | Přidej `web.instructions.md`, pak obarvi dlaždice | web | 10 min | blok 02 |
| [2](#2-skill---zachyť-jak-se-přidává-endpoint-a-pak-jeden-přidej) | Skill | Napiš skill `api-endpoint`, pak přidej `DELETE /games/{id}` | api | 15 min | blok 03 |
| [3](#3-hook---udělej-testy-nepřeskočitelné) | Hook | Udělej z test hooku, který jen varuje, blokující bránu | config | 15 min | blok 04 |
| [4](#4-mcp---implementuj-featuru-přímo-z-github-issue) | MCP | Nejlepší skóre přímo z GitHub issue | api | 10 min | blok 05, demo |
| [5](#5-agenti---oprav-dvě-nastražené-chyby-třemi-agenty) | Agenti | Explorer, test writer a reviewer opraví dvě chyby v enginu | engine | 20 min | blok 06 |
| [6](#6-plugin---přidej-skill-do-pluginu-2048-dev) | Plugin | Přidej skill `run-local` do `2048-dev` | config | 8 min | blok 07 |
| [8](#8-eval---dokaž-že-skill-pomáhá) | Eval | Přidej případ do evalu, lint, dry-run, přečti výsledek se skillem a bez něj | config | 15 min | blok 09 |
| [7](#7-orchestrace---auto-solver-vybraný-porotou) | Orchestrace | Tři solvery paralelně, porota vybere jeden | engine | 60 min | po workshopu |
| [B](#bonus-web---bug-který-nikdo-nenastražil) | Smyčka úrovně 5 | Zastaralá deska po dvou rychlých stiscích kláves | web | 30 min | po workshopu |

Patche cvičení 0, 4 a `ex5-undo` všechny přidávají `GameServiceTest.kt`: na jednu branch aplikuj jen jeden.

## 0. Rozjezd 🟢 — oprav nastraženou chybu smyčkou úrovně 5

**Čas:** 7 min · **Návod:** [01 · Začínáme](01-getting-started.cs.md) · **Vrstva:** api · **Řešení:** [`solutions/ex0.patch`](solutions/ex0.patch)

**Cíl.** Tah, který nic nezměnil, nespawnuje dlaždici a dokazuje to test v novém `GameServiceTest.kt`.

**Proč tento mechanismus.** Plán, padající test, oprava, důkaz: tuhle smyčku opakuje každé další cvičení.

### Kroky

1. Na čistém `main` spusť `scripts/copilot-ws.sh` z kořene repa. Jsi tu poprvé? Zkus
   čtyři příkazy z [První session](01-getting-started.cs.md#první-session-3-min-před-cvičením-0).
2. Plán. Vlož specifikaci. Asi po půl minutě se objeví box **Plan Ready for Review**;
   `Ctrl+E` ukáže celý plán. Zkontroluj ho: test před opravou, mění se jen dva soubory pod `api/`.
   Zvol možnost 1, **Exit to Interactive execution mode without running the plan**.
   > */plan Bug: `GameService.move` ignoruje výsledek `board.move(direction)` a spawnuje dlaždici,
   > i když se nic nepohnulo. Nejdřív padající test v novém `GameServiceTest.kt`, bez náhodných
   > dlaždic: dej `GameService` parametr konstruktoru `newBoard: () -> Board = { Board.newGame() }`.
   > V `engine/` ani `web/` nic neměň. Důkaz: `./gradlew :api:test`.*
3. Červená. Vlož první prompt a každý dotaz na úpravu (`Update file`, `Create file`) potvrď
   **1. Yes**; `./gradlew :api:test` běží bez dotazu, sbalený do jednoho řádku timeline:
   `✗ Shell … Failed with exit code 1` (`Ctrl+O` na prázdném promptu rozbalí všechny položky). Odpověď
   cituje neúspěšnou aserci; kolo končí hláškou `run-tests hook: tests are failing in: gradle`.
   > *„Udělej jen krok s testem: přidej parametr a test, spusť `./gradlew :api:test` a ukaž
   > název padajícího testu a zprávu jeho aserce. `GameService.move` zatím neopravuj.“*
4. Zelená. Vlož druhý prompt a schval tu jednu úpravu. Odpověď hlásí 6 prošlých testů a 0 neprošlých
   (řešení má dva testy: 7 prošlých).
   > *„Teď oprav `GameService.move`, znovu spusť `./gradlew :api:test` a nahlas, kolik testů prošlo a kolik selhalo.“*
5. Napiš `/diff`: vlevo `Files (2)`, vpravo diff. Přečti každý řádek: jeden parametr
   konstruktoru, jedna podmínka, jeden soubor s testem. `Esc` ho zavře.

### Hotovo, když

- `./gradlew :api:test` → `BUILD SUCCESSFUL`
- `git status --short` → ` M …/GameService.kt` a `?? …/GameServiceTest.kt`, nic dalšího
- Krok 3 skončil na neúspěšné aserci, ne na chybě kompilace, a bez opravy

### Klíčová část řešení

```diff
+class GameService(
+    private val newBoard: () -> Board = { Board.newGame() },
+) {
@@ fun move(id: UUID, direction: Direction): GameState
-            board.spawnRandom()
+            if (changed) {
+                board.spawnRandom()
+            }
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex0.patch`

### Jdi dál

- Nech Copilota odstranit jen `if (changed)`, znovu spustit testy, ukázat selhání a podmínku vrátit.

## 1. Instrukce 🟢 — nauč webové konvence a pak obarvi dlaždice

**Čas:** 10 min · **Návod:** [02 · Vlastní instrukce](02-custom-instructions.cs.md) · **Vrstva:** web · **Řešení:** [`solutions/ex1.patch`](solutions/ex1.patch)

**Cíl.** `.github/instructions/web.instructions.md` obsahuje konvence Reactu pro `web/src` a
dlaždice jsou obarvené podle hodnoty způsobem, který se tím souborem řídí.

**Proč tento mechanismus.** Pravidlo, které musí platit při každé změně pod nějakou cestou, patří
do souboru instrukcí vázaného na cestu, ne do každého promptu; `engine/` a `api/` ho mají, `web/` ne.

### Kroky

1. Na čistém `main` s nainstalovaným `web/node_modules` (`cd web && npm ci`) spusť `scripts/copilot-ws.sh`.
2. Vlož startovací prompt a schval ten jeden nový soubor.
   > *„Přečti všechny soubory ve `web/src/`, `web/eslint.config.js` a `web/.prettierrc.json`. Napiš
   > `.github/instructions/web.instructions.md` s frontmatterem
   > `applyTo: "web/src/**/*.ts,web/src/**/*.tsx,web/src/**/*.css"`. Uveď jen konvence, které kód
   > už dodržuje, každou i s tím, co zakazuje: exporty, typování, co smí exportovat soubor
   > komponenty, kde žijí styly, kde žijí HTTP volání, kde leží testy a jak se dotazují na DOM.
   > Nejvýš deset krátkých odrážek v rozkazovacím způsobu, ve stylu
   > `.github/instructions/api.instructions.md`. Žádný jiný soubor neměň.“*
3. Přečti si soubor. Potřebuje tři pravidla, která featura prověří: styly jsou obyčejné třídy ve
   `web/src/index.css` bez inline `style`; soubor komponenty exportuje jen komponenty, helpery
   mají vlastní modul; testy se dotazují podle role nebo viditelného textu. Řekni Copilotovi, ať doplní, co chybí.
4. Zkontroluj, že CLI ten soubor načítá. V druhém terminálu, z kořene repa:

   ```bash
   copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
   ```

   Vypíše `["web/src/**/*.ts","web/src/**/*.tsx","web/src/**/*.css"]`. Z jednoho řetězce
   `applyTo` s čárkami vzniknou tři globy.
5. Instrukce se načítají při startu session. Napiš `/exit`, spusť znovu `scripts/copilot-ws.sh` a vlož
   navazující prompt. CLI ten soubor doručí, když Copilot poprvé otevře soubor odpovídající `applyTo`:
   v timeline se pak objeví `● Discovered web.instructions.md from .github/instructions/`.
   > *„Obarvi dlaždice podle hodnoty. Jen web: na `api/` ani `engine/` nesahej. Přidej testy.“*
6. Napiš `/diff`. Uvidíš pomocný modul vedle `Board.tsx`, nové třídy `.tile-…` v `index.css`
   a test, který dlaždici najde podle role nebo textu. Nikde žádný atribut `style=`.

### Hotovo, když

- Příkaz z kroku 4 → tři globy `web/src`
- `cd web && npm test && npm run lint && npm run build` → 0 neprošlých testů (řešení končí na
  `Tests  11 passed (11)`), žádné nálezy ESLintu, `✓ built in …`
- `grep -rn 'style=' web/src` → nevypíše nic
- `git status --short` → jen `.github/instructions/web.instructions.md` a cesty pod `web/src/`

### Klíčová část řešení

```markdown
---
applyTo: "web/src/**/*.ts,web/src/**/*.tsx,web/src/**/*.css"
---

# Web rules

- Named exports only. No default exports, not even for components.
- Strict TypeScript: no `any`, no non-null `!`. Import types with `import type`.
- Function components with hooks. Props get an interface named `<Component>Props` in the same file.
- A component file exports components only. Pure helpers go in their own module (like `keys.ts`)
  so they can be tested without rendering.
- Styling lives in `web/src/index.css` as plain classes. No inline `style`, no CSS modules, no
  CSS-in-JS.
- HTTP goes through `web/src/api.ts`. Components never call `fetch` themselves.
- Tests sit next to the source as `<name>.test.ts(x)` and use Vitest with Testing Library. Query by
  role or visible text (`getByRole('gridcell')`), never by class name or test id.
- One behaviour per `it`, named as a sentence, Arrange-Act-Assert separated by blank lines.
- Run `npm test` and `npm run lint` in `web/` after the change and report the pass and fail counts.
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex1.patch`

### Jdi dál

- Stejným způsobem přidej do hlavičky počítadlo `moves: N`: počítá tahy, které API přijalo,
  a po **New game** se vrací na 0. Nový `App.test.tsx` musí mockovat `./api`; nejdřív přidej tohle pravidlo.
- Audit promptem: *„Projdi `web.instructions.md` pravidlo po pravidle a oprav, kde ho tvůj diff porušuje.“*

## 2. Skill 🟢–🟡 — zachyť, jak se přidává endpoint, a pak jeden přidej

**Čas:** 15 min · **Návod:** [03 · Skilly](03-skills.cs.md) · **Vrstva:** api · **Řešení:** [`solutions/ex2.patch`](solutions/ex2.patch)

**Cíl.** Projektový skill `.github/skills/api-endpoint/SKILL.md`, který nese postup přidání
endpointu, a s ním postavený `DELETE /api/v1/games/{id}`: 204, strukturovaná 404, testy s `MockMvcTester`.

**Proč tento mechanismus.** Skill nese postup a tvary ke zkopírování a načítá se jen na vyžádání.

### Kroky

1. Na čistém `main` spusť `scripts/copilot-ws.sh` a vlož:
   > *„Přečti `GameController.kt`, `GameService.kt`, `ApiExceptionHandler.kt` a `GameControllerTest.kt`
   > v `api/` a `.github/instructions/api.instructions.md`. Napiš projektový skill do
   > `.github/skills/api-endpoint/SKILL.md` podle vzoru `.github/skills/board-tests/SKILL.md`, který
   > zachytí, jak se v tomhle API přidává endpoint. Sekce: pořadí práce (nejdřív pravidlo v `engine`,
   > metoda služby, vlastní výjimka, její handler, tenký controller, test s `@WebMvcTest`, spuštění
   > `./gradlew :api:test`); kontrakt (URL, obálky `ApiResponse` a `ErrorResponse`,
   > stavové kódy, 204 bez těla pro delete); tvary ke zkopírování (krátké skutečné úryvky
   > z kódu); testovací idiomy Spring Bootu 4. Uveď cestu, kde leží testy controlleru, a že názvy
   > testů jsou obyčejné anglické věty ve zpětných apostrofech. `description` napiš tak, aby říkal, kdy
   > skill použít; nedávej do něj dvojtečku. Žádný kotlinový soubor neměň.“*

   Schval zápis souboru. Copilot přečte soubory jmenované v promptu a vytvoří jeden nový. Žádný kotlinový soubor se nemění.
2. Otevři `.github/skills/api-endpoint/SKILL.md` a porovnej ho s referencí:
   ```markdown
   ---
   name: api-endpoint
   description: Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
   ---
   ## Order of work       rule in engine, service method, own exception, handler, controller, test, run
   ## Contract            /api/v1, { "data": ... }, { "error": { "code", "message" } }, 201 200 400 404, 204
   ## Shapes to copy      one real exception, handler, controller function and MockMvcTester test
   ## Boot 4, not Boot 3  WebMvcTest package, MockMvcTester, @MockitoBean, tools.jackson.*
   ```
   Zkontroluj tři řádky, které se při přepisu snadno ztratí, a řekni Copilotovi, ať doplní, co chybí:
   delete odpovídá 204 bez těla; testy controlleru leží v `api/src/test/kotlin/com/quanti/g2048/api/`;
   názvy testů jsou věty ve zpětných apostrofech. `: ` v `description` bez uvozovek je neplatný YAML.
3. Ukonči session přes `/exit`. Spusť `copilot skill list --json | grep -A2 '"name": "api-endpoint"'`:
   vypíše název, tvůj popis a `"source": "project"`.
4. Spusť znovu `scripts/copilot-ws.sh` a vlož úkol. Skill nejmenuj:
   > *„Přidej endpoint, který smaže hru, i s testy.“*

   Před první úpravou Copilot zavolá nástroj `skill` s `{"skill":"api-endpoint"}`; TUI
   tomu volání nemusí dát vlastní řádek. Pak upraví `GameService.kt`, `GameController.kt`,
   `GameControllerTest.kt` a spustí testy API. Skill se nepoužil? Zopakuj prompt
   s `/api-endpoint` na začátku a pak zpřesni `description`.

### Hotovo, když

- `copilot skill list --json | grep -c '"name": "api-endpoint"'` → `1`
- `grep -cE 'NO_CONTENT|noContent\(\)' api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` → `1`
- `./gradlew :api:test` → `BUILD SUCCESSFUL`
- `grep -o 'tests="[0-9]*"' api/build/test-results/test/*.xml` → víc než `tests="5"` (reference: 8)

### Klíčová část řešení

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+    fun delete(id: UUID) {
+        boards.remove(id) ?: throw GameNotFoundException(id)
+    }
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
+    @DeleteMapping("/{id}")
+    @ResponseStatus(HttpStatus.NO_CONTENT)
+    fun delete(@PathVariable id: UUID) {
+        games.delete(id)
+    }
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+    @Test
+    fun `deleting a game returns 204 with no body`() {
+        val id = createGameId()
+
+        val result = mvc.delete().uri("/api/v1/games/$id")
+
+        assertThat(result).hasStatus(HttpStatus.NO_CONTENT).hasBodyTextEqualTo("")
+    }
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex2.patch`

### Jdi dál

- Dvě vrstvy stejným skillem: *„Udělej výherní hodnotu konfigurovatelnou. Pravidlo pro povolené hodnoty
  patří do `Board`; `POST /api/v1/games` bere volitelné `{"winValue": 1024}`; na nepovolenou hodnotu odpoví 400.“*
- Změř skill experimentem se skillem a bez něj: [09 · Evaly](09-evals.cs.md).

## 3. Hook 🟡 — udělej testy nepřeskočitelné

**Čas:** 15 min · **Návod:** [04 · Hooky](04-hooks.cs.md) · **Vrstva:** config · **Řešení:** [`solutions/ex3.patch`](solutions/ex3.patch)

**Cíl.** `.github/hooks/scripts/run-tests.sh` pošle Copilota jednou zpátky do práce, když selžou
testy změněné části stromu, a jen varuje, když selhávají i při dalším zastavení.

**Proč tento mechanismus.** „Spusť testy“ v souboru instrukcí je prosba, kterou model může přeskočit;
hook `agentStop` běží při každém zastavení, ať se model rozhodl jakkoli.

### Kroky

1. Na čistém `main` s připraveným `web/node_modules` (`cd web && npm ci`) spusť
   `scripts/copilot-ws.sh` z kořene repa.
2. Vlož startovací prompt a schval úpravu. Dnes skript při červené končí s kódem 2: jen varování.
   > *„Přepiš `.github/hooks/scripts/run-tests.sh` tak, aby hook `agentStop` blokoval, když testy
   > selžou. Zachovej, co testuje teď: Gradle, když jsou necommitnuté změny v `engine/` nebo `api/`,
   > Vitest, když jsou ve `web/src/`. Při selhání vypiš na stdout právě jeden JSON objekt
   > `{"decision":"block","reason":"..."}` a skonči s kódem 0. Do `reason` dej selhávající suity,
   > příkaz pro jejich opětovné spuštění a posledních 30 řádků výstupu testů. Z JSON na stdin
   > přečti `stop_hook_active`: když je true, znovu neblokuj; napiš jeden řádek na stderr
   > a skonči s kódem 2. Totéž udělej, když chybí `jq`. `hooks.json` neměň.“*
3. Otestuj skript bez Copilota: hook čte JSON ze stdin a odpovídá na stdout. V druhém
   terminálu, z kořene repa, spusť tři případy: není co testovat, červená, červená po zablokování.
   ```bash
   payload() { printf '{"cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }
   hook=./.github/hooks/scripts/run-tests.sh
   payload false | $hook; echo "exit=$?"
   perl -pi -e "s/toBe\('UP'\)/toBe('DOWN')/" web/src/keys.test.ts
   payload false | $hook | jq -r '.decision'
   payload true  | $hook; echo "exit=$?"
   git restore web/src/keys.test.ts
   ```
   Uvidíš čtyři řádky; znění třetího určuje tvůj skript. S `.reason` místo
   `.decision` druhý příkaz vypíše, co dostane Copilot.
   ```text
   exit=0
   block
   run-tests hook: tests are failing in: web (cd web && npm test). Not sent back: this turn was …
   exit=2
   ```
4. Zpátky v session vlož navazující prompt. Session už používá nový skript: CLI
   ho při každém zastavení spouští z disku.
   > *„Ve `web/src/keys.ts` udělej `toDirection` citlivé na velikost písmen: velké `W` se už nesmí
   > počítat jako tah. Testy nespouštěj.“*

   Copilot upraví `keys.ts` a ukončí kolo. Hook spustí Vitest a pak začne kolo, které jsi
   nenapsal. Jeho promptem je `reason` z hooku: `run-tests hook: tests are failing in: web …` a
   výstup Vitestu s `× ignores the case of a WASD key`. Copilot kód znovu změní, spustí
   `cd web && npm test` a zastaví se na zelené; při tomhle zastavení hook nevypíše nic.
5. Napiš `/diff`. Brána dokazuje, že testy procházejí, ne že je změna správná: Copilot může
   do mapy kláves přidat jen velká `S`, `A`, `D` a `W` vynechat. Pak spusť `git restore web/src`.

### Hotovo, když

- Žádná změna pod `engine/`, `api/`, `web/src/`: `payload false | $hook; echo "exit=$?"` → `exit=0`
- Červený test: `payload false | $hook | jq -r '.decision'` → `block`
- Červený test: `payload true | $hook; echo "exit=$?"` → jeden řádek s varováním, pak `exit=2`
- V session začíná kolo, které jsi nenapsal, textem `run-tests hook: tests are failing in: web`

### Klíčová část řešení

```diff
-cat >/dev/null
+input=$(cat)
@@ the Gradle branch, without --quiet; the Vitest branch changes the same way
+    if ! result=$(./gradlew test 2>&1); then
+        failed="$failed gradle (./gradlew test)"
+        output="$output$result"$'\n'
+    fi
@@ the ending
+[ -n "$failed" ] || exit 0
+already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
+if [ "$already_blocked" != "false" ]; then
+    echo "run-tests hook: tests are failing in:$failed. Not sent back: …" >&2
     exit 2
 fi
+reason="run-tests hook: tests are failing in:$failed. Find the cause, fix it, …"
+reason="$reason"$'\n'"$(printf '%s' "$output" | tail -n 30)"
+jq -cn --arg reason "$reason" '{decision: "block", reason: $reason}'
 exit 0
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex3.patch`

### Jdi dál

- Postav featuru za bránou: počítadlo tahů na serveru (`moves` ve stavu hry, počítá se,
  jen když se deska změnila, zobrazené v hlavičce webu). Hook pak spouští Gradle i Vitest.
- Udělej bránu přísnou: smaž větev `stop_hook_active`. CLI ukončí kolo po 8 zablokováních.

## 4. MCP 🟡 — implementuj featuru přímo z GitHub issue

**Čas:** celkem 10 min; na workshopu lektor ukáže kroky 1 až 3 (5 min) · **Návod:** [05 · MCP pod allow-listem](05-mcp.cs.md) · **Vrstva:** api · **Řešení:** [`solutions/ex4.patch`](solutions/ex4.patch)

**Cíl.** Copilot přečte issue „Show the best score“ přes vestavěný GitHub MCP server a
implementuje ho: každý stav hry, který API vrací, nese `bestScore`. Pull request na issue odkazuje.

**Proč tento mechanismus.** MCP dovolí agentovi vzít si zadání ze systému, ve kterém zadání žije.

### Kroky

1. Na čistém `main` založ issue a poznamenej si jeho číslo `<N>`. ⚠️ v tomto repu nespuštěno
   ```bash
   gh issue create --title "Show the best score" --body-file docs/copilot/solutions/ex4-issue.md
   ```
2. Spusť session se dvěma nástroji pro issues. Když je `gh` na `PATH`, vestavěný server nabízí
   6 nástrojů a žádný nečte issues; `--add-github-mcp-tool` tuhle podmnožinu nahradí jmenovanými nástroji.
   ```bash
   scripts/copilot-ws.sh --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
   ```
3. Vlož startovací prompt. V timeline je vidět volání `github-mcp-server-issue_read`; Copilot
   zopakuje akceptační kritéria a žádný soubor nezmění. ⚠️ v tomto repu nespuštěno
   Když Copilot spustí `gh issue view` nebo nemá žádný nástroj pro issues, chybí přepínače: zopakuj krok 2.
   V `/mcp list` není `github-mcp-server`: začni promptem *„Přečti docs/copilot/solutions/ex4-issue.md.“*
   > *„Přečti issue #<N> tohoto repozitáře nástrojem issue_read z GitHub MCP serveru. Zopakuj
   > jeho akceptační kritéria jako číslovaný seznam a u každého jmenuj soubory, které změníš.
   > Zatím nic needituj.“*
4. Vlož navazující prompt a schval úpravy `GameService.kt` a obou testovacích souborů.
   > *„Implementuj issue jen v `api`. Nejlepší skóre sdílejí všechny hry: otestuj ho v novém
   > `GameServiceTest` s čerstvým `GameService()` pro každý test a dej službě `internal` způsob,
   > jak začít hru na desce, kterou dodá test. Testy controlleru sdílejí jednu službu: přidej tam
   > jeden test, který jen ověří, že pole `bestScore` existuje. Spusť `./gradlew build`.“*
5. Napiš `/diff` a porovnej ho s kritérii. Pak napiš
   `!git switch -c best-score && git add api && git commit -m "Show the best score (#<N>)"` a
   `/pr create`; zkontroluj, že popis odkazuje na `#<N>`. ⚠️ v tomto repu nespuštěno

### Hotovo, když

- `/mcp get github-mcp-server` → `tools (2)`: `list_issues` a `issue_read`; `q` obrazovku zavře
- `./gradlew build` → `BUILD SUCCESSFUL`
- `./gradlew :api:bootRun`; `curl -s -X POST localhost:8080/api/v1/games | jq .data.bestScore` → `0`
- `/pr view` → pull request branche `best-score`

### Klíčová část řešení

```diff
@@ data class GameState(
+    val bestScore: Int,
@@ class GameService {
+    // Atomic because games move in parallel; the lock in move() guards one board only.
+    private val bestScore = AtomicInteger(0)
+    fun create(): GameState = start(Board.newGame())
+    /** Starts a game on the given board. Tests use it to begin from a known position. */
+    internal fun start(board: Board): GameState {
@@ fun move(id: UUID, direction: Direction): GameState {
+            bestScore.updateAndGet { best -> maxOf(best, board.score) }
@@ private fun stateOf(id: UUID, board: Board): GameState {
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, bestScore.get())
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex4.patch`

### Jdi dál

- **Webová vrstva.** Založ druhé issue, „Show `best: N` in the header“, a zopakuj kroky 2 až 5:
  `bestScore: number` ve `web/src/api.ts`, jedno `<p>` v `App.tsx`, test s mockovaným `./api`.
- **Varianta s Jirou** (⚠️ v tomto repu nespuštěno). `cp .mcp.json.example .mcp.json`, místo
  zástupné hodnoty dej URL Jira MCP serveru schváleného ve 2N a restartuj session. `/mcp list` ukáže
  `jira` jako připojený; když chce přihlášení, spusť `/mcp auth jira`. Použij stejné dva prompty,
  jen místo GitHub issue *„Přečti Jira issue <KEY> přes server jira“*.

## 5. Agenti 🟡 — oprav dvě nastražené chyby třemi agenty

**Čas:** 20 min · **Návod:** [06 · Vlastní agenti](06-agents.cs.md) · **Vrstva:** engine · **Řešení:** [`solutions/ex5.patch`](solutions/ex5.patch)

**Cíl.** `slideLineLeft` udělá z `4, 4, 8, 0` `8, 8, 0, 0` za 8 bodů a `isGameOver()` vrací
false pro plnou desku s párem, který jde sloučit. Každá oprava má test, který nejdřív padal.

**Proč tento mechanismus.** Každý agent má vlastní kontext a vlastní seznam nástrojů: průzkum a výstup
testů zůstanou mimo hlavní kontext a explorer ani reviewer nemůžou editovat soubor.

### Kroky

1. Na čistém `main` (`git status --short` nevypíše nic) spusť `scripts/copilot-ws.sh` z kořene
   repa. Předem schválí `./gradlew`, který potřebuje test writer.
2. Vlož startovací prompt. Když agenta jmenuješ, hlavní agent zavolá nástroj `task`
   s `agent_type` nastaveným na toho agenta.
   > *„U dvou pravidel enginu je podezření, že jsou špatně. Posun řady 4, 4, 8, 0 musí dát
   > 8, 8, 0, 0 a skóre 8. Plná deska, která má pořád dva stejné sousedy, nesmí být game over.
   > Nejdřív použij agenta 2048-dev:game-explorer a najdi funkci a řádky, které o každém pravidle
   > rozhodují. Pak použij agenta board-test-writer a přidej do BoardTest.kt jeden test na každé
   > pravidlo. Board.kt neměň. Nahlas, které testy padají a proč.“*

   Uvidíš dvě delegace v tomhle pořadí. `2048-dev:game-explorer` (agent z pluginu, nástroje `read`
   a `search`) vrátí stopu `file:function:line`, která končí ve `slideLineLeft` a
   `Board.isGameOver`. `board-test-writer` (projektový agent, navíc `edit` a `execute`) změní
   `BoardTest.kt` a spustí `./gradlew :engine:test`; úpravu schval. Kolo končí se 2 padajícími
   testy z 15 a varováním `run-tests hook: tests are failing in: gradle`. Červená je tady
   očekávaný stav.
3. V druhém terminálu zkontroluj, že testy ověřují pravidlo, a ne současné chování:
   ```bash
   git status --short        # only BoardTest.kt is modified
   git diff engine/src/test | grep -E '^\+.*(8, 8, 0, 0|assertFalse)'
   ```
   `grep` vypíše dva přidané řádky. Aserce na `16, 0, 0, 0` znamená, že agent test ohnul,
   aby dostal zelenou: než půjdeš dál, řekni mu, ať vrátí správné očekávání.
4. Vlož navazující prompt. Opravuje hlavní agent; reviewer nemá nástroj na editaci.
   > *„Oprav oba bugy v Board.kt tak, aby oba nové testy prošly. Žádný test neměň. Spusť
   > ./gradlew :engine:test a nahlas počty. Pak použij agenta kotlin-reviewer, ať zreviduje
   > necommitnuté změny, a ukaž mi jeho nálezy.“*

   Uvidíš úpravu `Board.kt` (schval ji), běh testů s 15 prošlými a pak delegaci na
   `kotlin-reviewer`. Ten si změnu přečte přes `git status` a `git diff` a nálezy hlásí jako
   Blocker, Should-fix a Nit. Hlavní agent může ten report zkrátit na jeden řádek.
5. Opravu si přečti sám přes `git diff engine/src/main`. Po sloučení se musí procházení posunout
   za sloučenou dlaždici a `isGameOver()` musí porovnat každou buňku s pravým a spodním sousedem.

### Hotovo, když

- `./gradlew :engine:test` → `BUILD SUCCESSFUL`
- `grep -o 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' engine/build/test-results/test/TEST-*.xml`
  → `tests="15" skipped="0" failures="0"`
- `git status --short` → dva změněné soubory, `Board.kt` a `BoardTest.kt`
- Report agenta `kotlin-reviewer` neobsahuje žádný Blocker

### Klíčová část řešení

```diff
@@ fun slideLineLeft(line: IntArray): Int
             out[count - 1] = 0
             count--
-            // NOTE: index `i` is intentionally not advanced here.
-        } else {
-            i++
         }
+        // A tile merges at most once per move, so step past it even when it has just merged.
+        i++
     }
@@ fun isGameOver(): Boolean
         for (row in 0 until SIZE) {
             for (col in 0 until SIZE) {
-                if (cells[row][col] == 0) {
+                val value = cells[row][col]
+                if (value == 0) {
+                    return false
+                }
+                // Looking right and down covers every neighbouring pair exactly once.
+                if (col + 1 < SIZE && cells[row][col + 1] == value) {
+                    return false
+                }
+                if (row + 1 < SIZE && cells[row + 1][col] == value) {
                     return false
                 }
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex5.patch`

### Jdi dál

- Postav **undo** ve všech třech vrstvách se stejným týmem: nejdřív testy `Board.undo()`, pak
  `POST /api/v1/games/{id}/undo`, klávesa `u` a tlačítko Undo. Referenční řešení z čistého `main`
  (hlídá i spawn po tahu, který nic nezměnil):
  `git apply docs/copilot/solutions/ex5.patch && git apply docs/copilot/solutions/ex5-undo.patch`
- Otestuj hranici nástrojů, místo abys věřil promptu agenta:
  `copilot --agent 2048-dev:game-explorer -p "Create a file named probe.txt" --trust-folder --no-ask-user`,
  pak `git status --short` neukáže žádný nový soubor.

## 6. Plugin 🟡 — přidej skill do pluginu 2048-dev

**Čas:** 8 min · **Návod:** [07 · Pluginy](07-plugins.cs.md) · **Vrstva:** config · **Řešení:** [`solutions/ex6.patch`](solutions/ex6.patch)

**Cíl.** Plugin `2048-dev` dodává druhý skill, `run-local` (spusť API a webové UI,
udělej smoke test), ve verzi 1.1.0 a session ho nabízí jako `/2048-dev:run-local`.

**Proč tento mechanismus.** Plugin je to, co předáš guildě: skill nese jedna verzovaná jednotka.

### Kroky

1. Na čistém `main` spusť `scripts/copilot-ws.sh` z kořene repa a vlož:
   > *„Přidej do pluginu 2048-dev skill v `plugins/2048-dev/skills/run-local/SKILL.md` podle vzoru
   > `plugins/2048-dev/skills/build-test/SKILL.md`: jak spustit aplikaci na tomhle stroji. Fakta
   > vezmi z `web/vite.config.ts` a `GameController.kt`: dva startovací příkazy, porty,
   > proxy `/api`, striktní webový port a jeden smoke test přes `curl`, který vytvoří hru přes
   > proxy, s očekávaným stavem a tělem. Nejvýš 30 řádků. Frontmatter: `name: run-local` a
   > `description`, který říká, kdy ho použít. Pak zvyš verzi z 1.0.0 na 1.1.0
   > v `plugins/2048-dev/plugin.json` a v záznamu pluginu v `marketplace.json` (ne
   > `metadata.version`) a v obou popisech nový skill jmenuj. Žádný server nespouštěj.“*

   Copilot vytvoří jeden soubor a dva upraví. Skill se nikde neregistruje: CLI ho najde podle
   cesty `skills/<name>/SKILL.md` a před jeho příkaz dá `name` pluginu.
2. Zkontroluj nový `SKILL.md` proti `web/vite.config.ts` a `GameController.kt`: porty 8080 a
   5173, `strictPort`, `POST /api/v1/games` → 201. Žádný nástroj skill proti kódu nekontroluje.
3. V druhém terminálu zkontroluj plugin bez volání modelu:
   ```bash
   copilot --plugin-dir ./plugins/2048-dev plugin list | tail -1
   copilot --plugin-dir ./plugins/2048-dev skill list --json | jq -r '.[] | select(.source == "plugin") | .name'
   ```
4. Napiš `/exit` a spusť novou session: ta načte plugin z pracovního stromu. Napiš `/2048`:
   seznam návrhů nabídne `/2048-dev:run-local` vedle `/2048-dev:build-test`. Smaž řádek klávesou `Ctrl+U` a vlož:
   > */2048-dev:run-local Nic nespouštěj. Ve dvou řádcích: které dva příkazy aplikaci spustí
   > a na jakých portech?*

   Timeline ukáže tvůj příkaz a žádný řádek pro skill. Copilot odpoví
   `./gradlew :api:bootRun` na 8080 a `cd web && npm run dev` na 5173.

### Hotovo, když

- `jq -r .version plugins/2048-dev/plugin.json` → `1.1.0`
- `jq -r '.plugins[0].version, .metadata.version' marketplace.json` → `1.1.0`, pak `1.0.0`
- Dva příkazy z kroku 3 → `• 2048-dev (v1.1.0)`, pak `build-test` a `run-local`
- Krok 4 odpoví oběma příkazy a oběma porty

### Klíčová část řešení

```diff
+++ b/plugins/2048-dev/plugin.json
-  "version": "1.0.0",
+  "version": "1.1.0",
+++ b/plugins/2048-dev/skills/run-local/SKILL.md
+---
+name: run-local
+description: Start the 2048 app on this machine (Spring Boot API on port 8080, Vite dev server on port 5173) and smoke-test it with curl. Use when asked to run or start the app, to try a change in the browser, or to check that the API answers.
+---
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex6.patch`

### Jdi dál

- Zabal znalost, která jde přes tři vrstvy: aplikuj `solutions/ex5.patch`, pak
  `solutions/ex5-undo.patch` a pak přidej `skills/undo/SKILL.md` s tím, kde undo v každé vrstvě
  žije, a s pravidly, která musí změna zachovat.

## 7. Orchestrace 🔴 — auto-solver vybraný porotou

**Čas:** po workshopu, asi 60 min · **Návod:** [10 · Víc než jedna session](10-orchestration.cs.md) · **Vrstva:** engine · **Řešení:** [`solutions/ex7.patch`](solutions/ex7.patch)

**Cíl.** Auto-solver jen v enginu: kontrakt `Solver`, tři heuristiky napsané třemi paralelními
subagenty a benchmark se seedem, jehož tabulka, ne model, rozhodne, která heuristika vyhraje.

**Proč tento mechanismus.** `/fleet` se vyplatí, když se práce dá rozdělit na části, které nesdílejí žádný soubor.

### Kroky

1. Spusť `scripts/copilot-ws.sh` na čistém `main`. Sdílené části napíše nejdřív jeden agent:
   > *„V modulu engine vytvoř package `com.quanti.g2048.engine.solver`. `Solver.kt`: interface
   > `Solver` (`val name: String`; `fun chooseMove(board: Board): Direction?`, null, když žádný směr
   > desku nezmění, nikdy ji nemodifikuje), třída `Outcome(direction, grid, gained)` a
   > `legalOutcomes(board)`: každý směr vyzkoušený na kopii `Board(board.grid, board.score)`, jen
   > ty, které desku změní, v pořadí enumu. `Benchmark.kt`: `playGame(solver, random)` hraje
   > `Board.newGame(random)`, dokud solver nevrátí null, bez `isGameOver()`;
   > `benchmark(solver, games, seed)` seeduje hru n přes `Random(seed + n)` a vrací název solveru,
   > počet her, průměrné skóre, nejvyšší dlaždici. V hlavním kódu žádný výpis. Testy: `SolverTest.kt`,
   > `BenchmarkTest.kt` (používá `GreedySolver()`). `BenchmarkRunner.kt` v testovacím source setu vypíše
   > jeden řádek na solver pro `CornerSolver()`, `GreedySolver()`, `MonotonicSolver()`; `JavaExec` task
   > `benchmark` v `engine/build.gradle.kts` ho spustí s `-Pgames` (výchozí 1000) a `-Pseed`
   > (výchozí 2048). Ty tři solvery přijdou v dalším kroku: nevytvářej je a ověřuj jen přes
   > `./gradlew :engine:compileKotlin`.“*
2. Očekávej `BUILD SUCCESSFUL` a varování `run-tests hook` (solvery ještě nejsou). Rozděl práci a sleduj
   `/tasks`. Dotazy subagentů na schválení se objeví ve tvé session: odpověz na ně, jinak čekají.
   > */fleet Postav paralelně tři solvery 2048, každý jedním subagentem, v package enginu
   > `com.quanti.g2048.engine.solver`. Použij general-purpose subagenty. Každý subagent nejdřív přečte
   > `Solver.kt`, vytvoří jen svůj solver a svůj soubor s testy a nespouští Gradle (všichni tři píšou
   > do jednoho source setu). (1) `CornerSolver`, name "corner": outcome s největší hodnotou dlaždic
   > u levého horního rohu, váhy klesají podél hada. (2) `GreedySolver`, name "greedy": nejvyšší
   > `gained`, při shodě vyhrává první. (3) `MonotonicSolver`, name "monotonic": nejvíc
   > sousedních párů, jejichž hodnota neroste zleva doprava ani shora dolů. Každý
   > vrací null, když žádný outcome není legální. Až budou všichni tři hotoví, spusť
   > `./gradlew :engine:test` sám, oprav, co padá, pak spusť `./gradlew -q :engine:benchmark` a jmenuj
   > vítěze podle průměrného skóre jen z vypsaných čísel.*
3. Varianta s Conductorem: stejné rozdělení z YAML souboru. Zápisy agentů do souborů si schvaluje sám.
   `rm engine/src/*/kotlin/com/quanti/g2048/engine/solver/{Corner,Greedy,Monotonic}*.kt`, pak
   `git apply --include='conductor/*' docs/copilot/solutions/ex7.patch`, pak
   `conductor validate conductor/solver-tournament.yaml` → `Validation Successful`, pak
   `conductor --silent run conductor/solver-tournament.yaml` → JSON s `winner`, `ranking`, `reason`.

### Hotovo, když

- `./gradlew build` → `BUILD SUCCESSFUL`; `git status --short` → před krokem 3 jen cesty pod `engine/`
- `./gradlew -q :engine:benchmark`, dvakrát → stejné tři řádky; reference: vyhrává `monotonic`, 3047.5

### Klíčová část řešení

```diff
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/solver/GreedySolver.kt
+    override fun chooseMove(board: Board): Direction? =
+        legalOutcomes(board).maxByOrNull { it.gained }?.direction
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex7.patch`

### Jdi dál

- Po aplikaci `ex5.patch` je `greedy` (3000.0) skoro vyrovnaný s `monotonic` (3037.4): dej porotě pravidlo pro remízu.
- Na `main` se žádná heuristika nedostane přes dlaždici 512: přidej solver, který hledá hlouběji, se stejným rozhraním.

## 8. Eval 🟡 — dokaž, že skill pomáhá

**Čas:** 15 min · **Návod:** [09 · Evaly](09-evals.cs.md) · **Vrstva:** config · **Řešení:** [`solutions/ex8.patch`](solutions/ex8.patch)

**Cíl.** `evals/board-tests/eval.yaml` má druhý pozitivní případ, `cascade-merge-line`, který
projde lintem i dry-runem, a umíš říct, co zaznamenaný výsledek se skillem a bez něj dokazuje.

**Proč tento mechanismus.** Skill stojí tokeny v každé session; A/B běh ukáže, co za ně dostaneš.

### Kroky

1. V kořenu repa jednou spusť `npm ci` (nainstaluje Vally). Spusť `scripts/copilot-ws.sh` a vlož:
   > *„Přidej do `evals/board-tests/eval.yaml` druhý pozitivní stimulus pojmenovaný `cascade-merge-line`,
   > mezi `game-over-edge-case` a `unrelated-question`, podle vzoru `game-over-edge-case`. Jeho
   > prompt žádá unit test pravidla slučování: posun řady 4, 4, 8, 0 doleva musí dát
   > 8, 8, 0, 0 a přičíst 8 ke skóre. Prompt nesmí jmenovat skill ani funkci
   > `slideLineLeft` a zachová větu o chybějícím build nástroji. Přečti
   > `.github/skills/board-tests/SKILL.md` a přidej jeden grader `file-matches` na každou konvenci,
   > kterou skill pro tenhle případ uvádí, plus `completed` a `file-exists`. Nic dalšího neměň. Spusť
   > `npm run eval:lint` a ukaž jeho výstup. Eval nespouštěj.“*

   Copilot upraví jeden soubor a ukáže dva řádky `✔ … is valid`.
2. Zreviduj gradery. Každý kontroluje jednu větu skillu (název testu ve zpětných apostrofech,
   `slideLineLeft` pro pravidla slučování, očekávaná hodnota první) a projde jím každý správný test.
   Pattern, který vyžaduje konkrétní název proměnné nebo prázdný řádek, třeba `val gained = slideLineLeft\(line\)`,
   shodí správný test, který věci pojmenuje jinak. Když takový najdeš, vlož:
   > *„Uvolni u `cascade-merge-line` každý pattern graderu, který vyžaduje konkrétní název proměnné,
   > bílé znaky nebo zalomení řádku, aby prošel každý správný test, který se řídí skillem. Zachovej jeden
   > grader na konvenci. Spusť znovu `npm run eval:lint`.“*
3. Lint a dry-run. Ani jeden nevolá model:
   ```bash
   npm run eval:lint
   VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
   ```
   Dry-run vypíše dva plány, `skills=without (baseline)` a `skills=with`. Mají stejný
   `Eval hash` a liší se v `Config hash`: větve se liší prostředím a ničím
   jiným. Na čistém `main` je eval hash `ef971c7643e7f213`; tobě vyjde nová hodnota.
4. Přečti si výsledek zaznamenaný pro dva starší případy v části
   [Jak číst výsledek](09-evals.cs.md#jak-číst-výsledek) návodu 09: pozitivní případ prošel bez skillu
   v 0 ze 4 trialů a se skillem ve 3 ze 4, za 26–32 % tokenů navíc.
5. Volitelné, placené: `npm run eval:ab`. S tvým případem je to 12 skutečných Copilot sessions (2 varianty ×
   3 stimuly × 2 běhy); zaznamenané běhy s 8 sessions trvaly každý pod minutu. Porovnej řádky
   `cascade-merge-line` v `evals/results/<timestamp>/report.md`. ⚠️ v tomto repu nespuštěno

### Hotovo, když

- `grep -c '^  - name:' evals/board-tests/eval.yaml` → `3`
- `npm run eval:lint` → `✔ evals/board-tests/eval.yaml is valid`, `✔ evals/game-explorer/eval.yaml is valid`
- Dry-run → `Baseline:   skills=without`, `Plans:      2`, stejný `Eval hash` v obou plánech
- `git status --short` → ` M evals/board-tests/eval.yaml` a nic dalšího

### Klíčová část řešení

```yaml
  - name: cascade-merge-line
    prompt: >-
      Write a unit test for the 2048 merge rule: moving the row 4, 4, 8, 0 to the left must
      give 8, 8, 0, 0 and add 8 to the score, because a tile merges at most once per move.
      Follow this project's test conventions. This workspace has no build tool, so do not
      try to compile or run anything.
    graders:  # completed, file-exists and the backtick test name as in the first case, then:
      # Merge rules are tested through the top-level function, not through Board.move.
      - type: file-matches
        config:
          path: engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
          pattern: 'slideLineLeft\('
      # Two more of the same shape: 'assertEquals\(\s*8\s*,' (score gained, expected value first)
      # and '8,\s*8,\s*0,\s*0' (the correct line is kept; the current code returns 16, 0, 0, 0)
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/ex8.patch`

### Jdi dál

- Vyhodnoť vlastní skill, třeba `api-endpoint` ze cvičení 2: zkopíruj specifikaci do
  `evals/api-endpoint/`, do workspace trialu připrav jen zdrojový kód aplikace, přidej soubor experimentu a spusť lint a dry-run.

## Bonus (web) 🟡 — bug, který nikdo nenastražil

**Čas:** po workshopu, asi 30 min · **Návod:** [01 · Začínáme](01-getting-started.cs.md) · **Vrstva:** web · **Řešení:** [`solutions/bonus.patch`](solutions/bonus.patch)

**Cíl.** Test, který reprodukuje zastaralou desku po dvou rychlých stiscích kláves, a pak oprava v `App.tsx`.

**Proč tento mechanismus.** Žádný nový mechanismus: smyčka úrovně 5 na bugu bez připravené odpovědi.

### Kroky

1. Spusť `cd web && npm ci`, pak `scripts/copilot-ws.sh` na čistém `main` a vlož:
   > *„Po dvou šipkách stisknutých skoro současně může deska zůstat zastaralá: server provedl oba
   > tahy, ale obrazovka ukazuje tu odpověď, která dorazila poslední. Najdi příčinu ve `web/src`.
   > Zamýšlené chování: v jednu chvíli běží jen jeden tah; stisk klávesy, když tah čeká na
   > odpověď, se ignoruje. Zatím nic neopravuj. Napiš do `web/src/App.test.tsx` test s mockovaným
   > `./api`, který kvůli tomu padá, spusť `npm test` ve `web/` a ukaž mi selhání.“*
2. Copilot pojmenuje příčinu (jeden request na každý stisk klávesy) a ukáže, že nový test padá. Pak vlož:
   > *„Teď to oprav v `App.tsx`: ignoruj směrové klávesy, dokud se čekající tah nevrátí, při úspěchu
   > i při chybě, ale zachovej `preventDefault`. V testu renderuj uvnitř `await act(async () => ...)`,
   > aby byl key listener zaregistrovaný před první klávesou. Spusť webové testy, lint a build.“*

### Hotovo, když

- Po kroku 1: `cd web && npm test` → `1 failed`, `expected "vi.fn()" to be called 1 times, but got 2 times`
- Po kroku 2: `cd web && npm test && npm run lint && npm run build` → `Tests  8 passed (8)`, `✓ built in`

### Klíčová část řešení

```diff
+      if (isMoveInFlight.current) {
+        return
+      }
+      isMoveInFlight.current = true
       move(game.id, direction)
```
Celé řešení aplikuješ: `git apply docs/copilot/solutions/bonus.patch`

### Jdi dál

- Přidej test, že další stisk klávesy je přijat, jakmile čekající tah skončí úspěchem nebo chybou.

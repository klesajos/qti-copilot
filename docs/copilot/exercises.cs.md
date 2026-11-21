> 🌍 Číst v jazyce: [English](exercises.md) | **Česky**

# Katalog cvičení: jedna featura na každý mechanismus

Návody vysvětlují mechanismy jeden po druhém: [Instrukce](01-custom-instructions.cs.md),
[Skilly](02-skills.cs.md), [Hooky](03-hooks.cs.md), [MCP](04-mcp.cs.md), [Agenti](05-agents.cs.md),
[Pluginy](06-plugins.cs.md), [Orchestrace](07-orchestration.cs.md), [Evaly](09-validate-eval.cs.md).
Tenhle katalog je promění v praxi. **Každé cvičení postaví jednu herní featuru a použije ji
jako prostředek k procvičení jednoho mechanismu.** Featura je záměrně malá; jde o mechanismus.

Každé cvičení je soběstačné. Dostaneš v něm **startovací prompt** připravený k vložení, dotčené
**soubory**, relevantní kód vysvětlený přímo na místě, **walkthrough s kompletním referenčním
řešením** a **kontrolu hotovo**. Odkazovaný návod je nepovinná hloubka.

## Jak používat tento katalog

Kód generuješ přes Copilota. Ve 2N ho nesmíš psát ručně, takže cvičení jsou postavená stejně:
tvými nástroji jsou prompty, schvalování a review. Pořád se od tebe čeká, že rozumíš každému
řádku, který v repu přistane (úroveň 5 na
[škále](https://www.visidata.org/blog/2026/ai/)).

1. **Začni z čistého `main`.** Každé cvičení předpokládá repozitář ve stavu po naklonování.
   Dvě výjimky to o sobě říkají samy: cvičení 6 se větví z tvé branche ze cvičení 5 a
   cvičení 8 kopíruje skill z tvé branche ze cvičení 2.

   ```bash
   git switch main && git status --short     # must print nothing
   git switch -c ex1-instructions            # one branch per exercise
   ```

2. **Spouštěj Copilota z kořene repozitáře** přes `scripts/copilot-ws.sh`. Launcher předem
   schválí `./gradlew`, `npm test` a `npm run` a zakáže čtení i zápis `.env`.
   Další flagy předává dál; cvičení 4 potřebuje dva.
3. **Vlož startovací prompt** tak, jak je. Než schválíš, co Copilot navrhuje, přečti si to.
4. **Řiď navazujícími prompty, ne editorem.** Každý walkthrough uvádí dva nebo tři prompty,
   které vedou od startovacího promptu k řešení, a u každého kroku jmenuje mechanismus,
   který tam odvádí práci.
5. **Porovnej s walkthroughem.** Je to referenční řešení, postavené a otestované pro tenhle
   katalog. Slouží k porovnání, ne k opisování. Tvůj výsledek může používat jiná jména
   a být přesto správně; rozhoduje kontrola hotovo. `/diff` ukáže, co Copilot změnil.
6. **Spusť kontrolu hotovo.** Každé cvičení uvádí přesné příkazy a co máš vidět.
7. **Commitni na branchi cvičení** (požádej o to Copilota) a přepni se zpět na `main`. Další
   cvičení začíná zase načisto.

Každé cvičení má štítek s vrstvami, na které sahá: **engine** (pravidla v Kotlinu), **api**
(Spring Boot) a **web** (React). Kontrola hotovo vždy zahrnuje baseline pro tyto vrstvy:

```bash
./gradlew build                                        # engine + api: BUILD SUCCESSFUL
cd web && npm test && npm run lint && npm run build    # web (run npm ci once before)
```

Gradle při úspěchu počty testů nevypisuje. Tohle je vypíše z reportů:

```bash
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
```

Čistý `main` má 13 testů enginu, 5 testů API a 7 webových testů.

**Tři záměrné bugy nech ve cvičeních 1–4 být.** `slideLineLeft` sloučí dlaždici dvakrát
(`4,4,8,0` dá `16,0,0,0`), `Board.isGameOver()` hledá jen prázdnou buňku a
`GameService.move` spawnuje dlaždici i po tahu, který nic nezměnil. Cvičení 5 dva z nich
opraví. Když ti Copilot nabídne, že některý opraví mimochodem, odmítni; referenční řešení níže
je zachovávají.

Existuje i čtvrtý bug, ve webové vrstvě, který nikdo nenastražil: objevil se, když se aplikace
testovala v prohlížeči. Je schovaný pro [bonusové cvičení](#bonus-web---bug-který-nikdo-nenastražil)
na konci. Nech ho být i ve cvičeních 1–8.

Obtížnost: 🟢 snadné · 🟡 střední · 🔴 těžké.

## V kostce

| # | Mechanismus | Cvičení (featura) | Obtížnost | Vrstvy |
|---|---|---|---|---|
| 1 | [**Instrukce**](01-custom-instructions.cs.md) | Napiš `web.instructions.md`, pak obarvi dlaždice podle hodnoty a přidej počítadlo `moves: N` | 🟢 | web |
| 2 | [**Skill**](02-skills.cs.md) | Napiš skill `api-endpoint`, pak udělej výherní hodnotu konfigurovatelnou (`{"winValue": 1024}`, 400 při neplatné hodnotě) | 🟢–🟡 | engine · api |
| 3 | [**Hook**](03-hooks.cs.md) | Udělej z `run-tests.sh` bránu, která blokuje na červené, pak za ní přidej počítadlo tahů na serveru | 🟡 | api · web |
| 4 | [**MCP**](04-mcp.cs.md) | Implementuj issue „Show the best score“ přečtené přes vestavěný GitHub MCP server, pak `/pr create` | 🟡 | api · web |
| 5 | [**Vlastní agenti**](05-agents.cs.md) | Oprav bugy s game over a se spawnem po prázdném tahu, pak postav undo napříč agenty explorer, test-writer a reviewer | 🟡 | engine · api · web |
| 6 | [**Plugin**](06-plugins.cs.md) | Zabal skill s undo workflow do pluginu `2048-dev` a zvyš jeho verzi | 🟡 | žádné (konfigurace) |
| 7 | [**Orchestrace**](07-orchestration.cs.md) | Auto-solver vybraný porotou: heuristiky postavené paralelně přes `/fleet`; varianta s Conductorem volitelná | 🔴 | engine |
| 8 | [**Eval**](09-validate-eval.cs.md) | Dokaž, že skill pomáhá: napiš eval case, spusť ho se skillem a bez něj, přečti si deltu | 🟡 | žádné (konfigurace) |
| + | Bonus | Najdi a oprav race se zastaralou deskou v UI, nejdřív s padajícím testem | 🟡 | web |

---

## 1. Instrukce 🟢 — nauč webové konvence a pak je použij

**Vrstvy:** web

**Cíl.** Napiš `.github/instructions/web.instructions.md`, soubor instrukcí vázaný na cestu,
pro React klienta. Pak, s tímhle souborem na místě, nech Copilota **obarvit dlaždice podle
hodnoty** a přidat do hlavičky **počítadlo `moves: N`** a zkontroluj, že se výsledek souborem řídí.

**Co učí.** [Instrukce vázané na cestu](01-custom-instructions.cs.md): pravidla, která
platí v každé session, ale jen pro soubory odpovídající `applyTo`. Repozitář už takové
soubory má pro `engine/` a `api/`; `web/` žádný nemá. Instrukce říkají pravidla, která platí
vždy. Postup, který potřebuješ jen občas, patří do skillu (cvičení 2).

**Soubory.** `.github/instructions/web.instructions.md` (nový), `web/src/tiles.ts` a
`web/src/tiles.test.ts` (nové), `web/src/App.test.tsx` (nový), `web/src/Board.tsx`,
`web/src/Board.test.tsx`, `web/src/App.tsx`, `web/src/index.css`.

**Kontext na místě.**
- `web/src/Board.tsx:11` vykresluje každou buňku jako `<div className="tile" role="gridcell">`.
  Všechny dlaždice sdílejí jedno pozadí, `.tile` ve `web/src/index.css:42`.
- Hlavička je ve `web/src/App.tsx:57–63` a ukazuje jen `score:`. Požadavek na tah se posílá
  v key handleru na `App.tsx:46–48`.
- `web/eslint.config.js` zapíná `react-refresh`, takže soubor komponenty, který exportuje
  i helper, neprojde lintem (`react-refresh/only-export-components`). Helper potřebuje vlastní
  modul, tak jako `keys.ts` leží vedle `App.tsx`.
- Test pro `App` zatím neexistuje. `Board.test.tsx` a `keys.test.ts` ukazují styl: dotazy
  Testing Library podle role, jedno chování na jedno `it`.
- Tohle počítadlo žije v klientovi a počítá každý tah, který API přijalo. Klient nepozná,
  jestli tah desku změnil. Cvičení 3 místo toho staví počítadlo na serveru a začíná
  znovu z čistého `main`.

**Startovací prompt.**
> *„Přečti všechny soubory ve `web/src/` a k tomu `web/eslint.config.js`, `web/.prettierrc.json`
> a `web/tsconfig.app.json`. Napiš `.github/instructions/web.instructions.md` s `applyTo`,
> které pokryje soubory `.ts`, `.tsx` a `.css` pod `web/src`. Uveď jen konvence, které
> kód už dodržuje: exporty, typování, komponenty, kde žijí styly, kde žijí HTTP volání,
> kde leží testy a jak se dotazují na DOM. Krátké odrážky v rozkazovacím způsobu, ve stylu
> `.github/instructions/api.instructions.md`. Žádný jiný soubor neměň.“*

**Walkthrough (kompletní řešení).**

1. **Startovací prompt napíše soubor instrukcí.** *Mechanismus: zatím žádný. Copilot čte
   kód s `copilot-instructions.md` pro celé repo v kontextu a píše Markdown
   soubor.* Referenční verze:

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
- `web` only renders. It does not decide game rules; if the UI needs a new fact, the API returns it.
- Tests sit next to the source as `<name>.test.ts(x)` and use Vitest with Testing Library. Query by
  role or visible text (`getByRole('gridcell')`), never by class name or test id. Mock `./api`,
  not `fetch`.
- One behaviour per `it`, named as a sentence, Arrange-Act-Assert separated by blank lines.
- Prettier decides formatting: no semicolons, single quotes.
- Run `npm test` and `npm run lint` in `web/` after the change and report the pass and fail counts.
```

   Všechno v něm je dnes vidět v kódu, s jedním přídavkem: „mock `./api`, not
   `fetch`“. Tohle pravidlo zatím žádný test nepotřeboval; test `App` níže ano.

2. **Zkontroluj, že CLI soubor vidí.** V shellu, z kořene repozitáře:

```bash
copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
```

```text
["web/src/**/*.ts","web/src/**/*.tsx","web/src/**/*.css"]
```

   Z jednoho řetězce `applyTo` odděleného čárkami se stanou tři globy. Běžící session nový
   soubor instrukcí nenačte (podle dokumentace): spusť novou přes `/new`, pak `/instructions`
   soubor vypíše a dovolí ti ho zapnout nebo vypnout.

3. **Navazující prompt: postav featuru.**
   > *„Obarvi dlaždice podle hodnoty a v hlavičce zobraz počítadlo `moves: N`. Počítadlo
   > počítá tahy, které API přijalo, a při New game se vrací na 0. Jen web: na `api/`
   > ani `engine/` nesahej. Přidej testy.“*

   *Mechanismus: instrukce vázané na cestu. Podle dokumentace CLI doručí `web.instructions.md`,
   když agent čte nebo edituje soubor odpovídající `applyTo`, takže pravidla dorazí přesně
   ve chvíli, kdy Copilot otevře `Board.tsx`. Hook `format.sh` pouští Prettier na každý webový
   soubor, který Copilot upraví, a hook `run-tests.sh` pouští Vitest, když agent dokončí kolo.*

   Název třídy odvozuje helper modul `web/src/tiles.ts`:

```ts
const HIGHEST_STYLED_VALUE = 2048

/**
 * CSS classes for one cell. An empty cell keeps the base look; every value up to 2048 has
 * its own class in index.css, and anything above shares `tile-super`.
 */
export function tileClassName(value: number): string {
  if (value === 0) {
    return 'tile'
  }
  return value > HIGHEST_STYLED_VALUE ? 'tile tile-super' : `tile tile-${value}`
}
```

   `web/src/tiles.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { tileClassName } from './tiles'

describe('tileClassName', () => {
  it('gives an empty cell the base class only', () => {
    expect(tileClassName(0)).toBe('tile')
  })

  it('adds a class named after the tile value', () => {
    expect(tileClassName(64)).toBe('tile tile-64')
  })

  it('uses the shared class for a value above 2048', () => {
    expect(tileClassName(4096)).toBe('tile tile-super')
  })
})
```

   `web/src/Board.tsx` ho používá:

```diff
--- a/web/src/Board.tsx
+++ b/web/src/Board.tsx
@@ -1,3 +1,5 @@
+import { tileClassName } from './tiles'
+
 interface BoardProps {
   grid: number[][]
 }
@@ -8,7 +10,11 @@ export function Board({ grid }: BoardProps) {
       {grid.map((row, rowIndex) => (
         <div className="board-row" role="row" key={rowIndex}>
           {row.map((value, colIndex) => (
-            <div className="tile" role="gridcell" key={colIndex}>
+            <div
+              className={tileClassName(value)}
+              role="gridcell"
+              key={colIndex}
+            >
               {value === 0 ? '' : value}
             </div>
           ))}
```

   Ještě jeden případ ve `web/src/Board.test.tsx`. Najde buňku podle role a teprve pak
   se podívá na třídu:

```diff
--- a/web/src/Board.test.tsx
+++ b/web/src/Board.test.tsx
@@ -27,4 +27,10 @@ describe('Board', () => {
 
     expect(screen.getAllByRole('gridcell')[1]).toBeEmptyDOMElement()
   })
+
+  it('colours a tile by its value', () => {
+    render(<Board grid={GRID} />)
+
+    expect(screen.getAllByRole('gridcell')[0]).toHaveClass('tile-2')
+  })
 })
```

   Barvy jsou obyčejné třídy připojené na konec `web/src/index.css`, za `.tile`:

```css
.tile-2 {
  background: #eee4da;
}

.tile-4 {
  background: #ede0c8;
}

.tile-8 {
  color: #f9f6f2;
  background: #f2b179;
}

.tile-16 {
  color: #f9f6f2;
  background: #f59563;
}

.tile-32 {
  color: #f9f6f2;
  background: #f67c5f;
}

.tile-64 {
  color: #f9f6f2;
  background: #f65e3b;
}

.tile-128 {
  color: #f9f6f2;
  background: #edcf72;
}

.tile-256 {
  color: #f9f6f2;
  background: #edcc61;
}

.tile-512 {
  color: #f9f6f2;
  background: #edc850;
}

.tile-1024 {
  color: #f9f6f2;
  background: #edc53f;
  font-size: 1.25rem;
}

.tile-2048 {
  color: #f9f6f2;
  background: #edc22e;
  font-size: 1.25rem;
}

.tile-super {
  color: #f9f6f2;
  background: #3c3a32;
  font-size: 1.25rem;
}
```

   Počítadlo je jeden další kus stavu ve `web/src/App.tsx`:

```diff
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -17,11 +17,13 @@ function messageOf(error: unknown): string {
 export function App() {
   const [game, setGame] = useState<Game | null>(null)
   const [error, setError] = useState<string | null>(null)
+  const [moves, setMoves] = useState(0)
 
   const startGame = useCallback(() => {
     createGame()
       .then((created) => {
         setGame(created)
+        setMoves(0)
         setError(null)
       })
       .catch((cause: unknown) => setError(messageOf(cause)))
@@ -44,7 +46,10 @@ export function App() {
       // Arrow keys would otherwise scroll the page.
       event.preventDefault()
       move(game.id, direction)
-        .then(setGame)
+        .then((moved) => {
+          setGame(moved)
+          setMoves((count) => count + 1)
+        })
         .catch((cause: unknown) => setError(messageOf(cause)))
     }
 
@@ -57,6 +62,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="moves">moves: {moves}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` mockuje modul API, jak žádá soubor instrukcí:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App move counter', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4 })
  })

  it('starts at zero', async () => {
    render(<App />)

    await screen.findByRole('grid')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })

  it('counts a move the server accepted', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('moves: 1')).toBeInTheDocument()
  })

  it('does not count a move the server rejected', async () => {
    vi.mocked(move).mockRejectedValue(new Error('Game does not exist'))
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')
    await screen.findByRole('alert')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })

  it('goes back to zero when a new game starts', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')
    await user.keyboard('{ArrowLeft}')
    await screen.findByText('moves: 1')

    await user.click(screen.getByRole('button', { name: 'New game' }))

    expect(await screen.findByText('moves: 0')).toBeInTheDocument()
  })
})
```

4. **Navazující prompt: porovnej výsledek s pravidly.**
   > *„Projdi `web.instructions.md` pravidlo po pravidle a ukaž mi, kde se jím tvůj diff řídí.
   > Co se neřídí, oprav.“*

   Na co se dívat ve vlastním výsledku: barvy jako inline `style`, helper na název třídy
   exportovaný z `Board.tsx` (lint spadne), test, který hledá dlaždici přes `querySelector`.
   Když něco z toho najdeš, přestože to soubor zakazuje, ověř přes `/instructions`, že je
   soubor v téhle session načtený a zapnutý.

5. **Navazující prompt, jen pokud kontroly ještě nejsou zelené.**
   > *„Spusť ve `web/` `npm test`, `npm run lint` a `npm run build` a oprav, co selže. Nahlas
   > počty úspěšných a neúspěšných testů.“*

**Hotovo.**

```bash
copilot instruction list --json | jq -c '.[] | select(.label == "web.instructions.md") | .applyTo'
cd web && npm test && npm run lint && npm run build
```

- První příkaz vypíše tři globy pro `web/src`.
- Vitest: 0 padajících testů. Referenční řešení končí na `Test Files  4 passed (4)` a
  `Tests  15 passed (15)` (7 stávajících + 8 nových).
- ESLint nevypíše žádné nálezy; build končí řádkem `✓ built in …`.
- Okem: spusť `./gradlew :api:bootRun` a ve druhém terminálu `cd web && npm run dev`.
  Na http://localhost:5173 mají 2 a 4 různé barvy a hlavička ukazuje
  `moves: 0`, s každou šipkou přičítá a při **New game** se vrací na 0.

## 2. Skill 🟢–🟡 — zachyť, jak se přidává endpoint, a pak jeden přidej

**Vrstvy:** engine · api

**Cíl.** Napiš projektový skill `.github/skills/api-endpoint/SKILL.md`, který zachytí, jak se
v tomhle API přidává endpoint. Pak ho použij, aby byla **výherní hodnota konfigurovatelná**: `Board`
bere výherní hodnotu (výchozí 2048), hru jde vytvořit s `{"winValue": 1024}` a
neplatná hodnota vrací 400.

**Co učí.** Psaní [skillu](02-skills.cs.md): `description`, který se spustí na správné
požadavky, a tělo, které nese postup. `api.instructions.md` už nese pravidla API
a dorazí s každým souborem `api/**/*.kt`. Skill nese *pořadí práce* a
tvary ke zkopírování a načte se, jen když si o něj úloha řekne. Srovnej se stávajícím
skillem `board-tests`: stejný tvar, jiná doména.

**Soubory.** `.github/skills/api-endpoint/SKILL.md` (nový),
`engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`, `engine/.../BoardTest.kt`,
`api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`, `GameController.kt`,
`ApiExceptionHandler.kt`, `api/.../GameControllerTest.kt` a jeden řádek v
`.github/skills/board-tests/SKILL.md`.

**Kontext na místě.**
- Cílová dlaždice je konstanta: `const val WIN_VALUE = 2048` na `Board.kt:177`, čte ji
  `hasWon()` na `Board.kt:174`.
- `GameController.create()` (`GameController.kt:22–24`) nebere žádné tělo.
- Které hodnoty jsou povolené, je pravidlo hry, takže patří do `engine`. API jen překládá
  odmítnutí na HTTP chybu (`.github/copilot-instructions.md`: „Game rules live in `engine`
  only“).
- `ApiExceptionHandler.unreadableBody()` (`ApiExceptionHandler.kt:23–28`) odpovídá na každé
  neparsovatelné tělo zprávou o `direction`. Jakmile tělo bere i druhý endpoint, je pro něj
  ta zpráva špatně.
- Webový klient výherní hodnotu nikdy neposílá, takže `web/` zůstává nedotčený.

**Startovací prompt.**
> *„Přečti `GameController.kt`, `GameService.kt`, `ApiExceptionHandler.kt` a
> `GameControllerTest.kt` v `api/` a `.github/instructions/api.instructions.md`. Napiš
> projektový skill do `.github/skills/api-endpoint/SKILL.md`, který zachytí, jak se v tomhle
> API přidává endpoint: pořadí práce (nejdřív pravidlo v `engine`, pak metoda service,
> vlastní výjimka, její handler, tenký controller, test s `@WebMvcTest`), obálky `ApiResponse` a
> `ErrorResponse`, stavové kódy a testovací idiomy Spring Boot 4. Zkopíruj z kódu krátké
> skutečné úryvky jako tvary k následování. `description` napiš tak, aby říkal,
> kdy skill použít. Soubor postav podle vzoru `.github/skills/board-tests/SKILL.md`. Žádný
> Kotlin soubor neměň.“*

**Walkthrough (kompletní řešení).**

1. **Startovací prompt napíše skill.** *Mechanismus: zatím žádný; Copilot dokumentuje, co
   čte.* Referenční verze `.github/skills/api-endpoint/SKILL.md`:

````markdown
---
name: api-endpoint
description: Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
---

# Adding or changing an API endpoint

The API lives in `api/src/main/kotlin/com/quanti/g2048/api/`. It is Spring Boot 4 (Spring MVC,
Jackson 3). Work in this order; each step has one home.

## Order of work

1. **Rule first.** If the change needs a new game rule (which values are legal, what a move
   does), add it to `Board` in `engine/` with a deterministic test. The API asks the engine;
   it never decides a rule itself.
2. **Service method.** Add or extend a method on `GameService`. It takes plain values (`UUID`,
   an enum, an `Int`), never a request class, and returns `GameState`. Anything that changes a
   board runs inside `synchronized(board)`.
3. **Failure cases.** Each new way to fail gets its own exception class next to
   `GameNotFoundException` in `GameService.kt`. The service throws it; the controller does not
   validate.
4. **Handler.** One `@ExceptionHandler` per exception in `ApiExceptionHandler`, with
   `@ResponseStatus` and a stable `UPPER_SNAKE` code. Write the message by hand. Never pass
   `exception.message` of a framework exception to the client.
5. **Controller.** One function in `GameController` that maps HTTP to the service call and wraps
   the result: `ApiResponse(games.someMethod(...))`. A request body is a data class next to
   `MoveRequest`. An optional field is nullable with a `null` default; an optional body is
   `@RequestBody(required = false)`.
6. **Test.** Add cases to `GameControllerTest` (`@WebMvcTest(GameController::class)`,
   `@Import(GameService::class)`, `MockMvcTester`). One test for the success path and one per
   failure case. Assert on the status and on a JSON path, not on Kotlin objects.
   Tests live in `api/src/test/kotlin/com/quanti/g2048/api/<Controller>Test.kt`; create it if missing.
   Name each test as a plain-English sentence in backticks, one behaviour per test.
7. **Run** `./gradlew :api:test` (and `./gradlew :engine:test` if step 1 applied) and report the
   pass and fail counts.

## Contract

- URLs: resources under `/api/v1`, plural nouns, no verbs (`/games/{id}/moves`).
- Success body: `{ "data": ... }`. Error body: `{ "error": { "code": "...", "message": "..." } }`.
- Status: 201 for a create, 200 for a read or a move, 400 for input that cannot be parsed or is
  not allowed, 404 for an unknown game. Never 200 with an error inside, never 500 for bad input.
- A delete answers 204 with no body: `@ResponseStatus(HttpStatus.NO_CONTENT)`, no return value.
- A new field on `GameState` is additive. If the web client should show it, add it to the `Game`
  interface in `web/src/api.ts` in the same change.

## Shapes to copy

```kotlin
// GameService.kt
class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")

// ApiExceptionHandler.kt
@ExceptionHandler(GameNotFoundException::class)
@ResponseStatus(HttpStatus.NOT_FOUND)
fun gameNotFound(exception: GameNotFoundException): ErrorResponse =
    ErrorResponse(ErrorBody("GAME_NOT_FOUND", exception.message ?: "Game does not exist"))

// GameController.kt
@PostMapping("/{id}/moves")
fun move(
    @PathVariable id: UUID,
    @RequestBody request: MoveRequest,
): ApiResponse<GameState> = ApiResponse(games.move(id, request.direction))

// GameControllerTest.kt
@Test
fun `moving in an unknown game returns a structured 404`() {
    val result = mvc.post().uri("/api/v1/games/${UUID.randomUUID()}/moves")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""{"direction":"LEFT"}""")

    assertThat(result)
        .hasStatus(HttpStatus.NOT_FOUND)
        .bodyJson()
        .extractingPath("$.error.code")
        .isEqualTo("GAME_NOT_FOUND")
}
```

## Boot 4, not Boot 3

Use `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`, `MockMvcTester`,
`@MockitoBean` and `tools.jackson.*`. Do not write `@MockBean`, `com.fasterxml.jackson.*`
imports or `TestRestTemplate`.
````

   `: ` (dvojtečka a mezera) uvnitř `description` bez uvozovek je neplatný YAML. Vyhni se tomu,
   jak to dělá reference pomocí ` - `, nebo dej celou hodnotu do uvozovek.

2. **Zkontroluj, že je skill načtený.** V shellu:

```bash
copilot skill list | grep '^  api-endpoint'
```

```text
  api-endpoint - Use when adding or changing a REST endpoint, a request body or a response field in the 2048 API (api/ module - GameController, GameService, ApiExceptionHandler). Covers the order of work, the response envelope, error handling and the controller test.
```

   Řádek se objeví pod `Project skills:`. V session, která už běžela, když soubor
   vznikl, spusť nejdřív `/skills reload` (podle dokumentace).

3. **Navazující prompt: postav featuru, aniž skill jmenuješ.**
   > *„Udělej výherní hodnotu konfigurovatelnou. `Board` bere výherní hodnotu (výchozí 2048)
   > a vlastní pravidlo, které hodnoty jsou povolené. `POST /api/v1/games` přijímá volitelné tělo
   > `{"winValue": 1024}`; bez těla se hraje do 2048. Nepovolená hodnota vrací 400
   > se strukturovanou chybou. Stav hry výherní hodnotu vrací.“*

   *Mechanismus: skill. Model porovná požadavek s `description` a načte tělo
   přes tool call jménem `skill` s argumentem `{"skill":"api-endpoint"}`;
   hledej ho v timeline. Když se neobjeví, zopakuj prompt s `/api-endpoint`
   uvnitř (podle dokumentace) a pak `description` zpřesni. Soubory instrukcí vázané na
   `engine/` a `api/` dorazí samy, jak Copilot otevírá Kotlin soubory (podle dokumentace).*

   Krok 1 skillu dává pravidlo do `Board.kt`:

```diff
--- a/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
@@ -52,11 +52,14 @@ fun slideLineLeft(line: IntArray): Int {
  *
  * Builds a board from an explicit grid, so the state is fully deterministic.
  * Use [Board.newGame] for a board seeded with two random tiles.
+ *
+ * [winValue] is the tile that wins the game. It must pass [Board.isValidWinValue].
  */
 class Board(
     grid: List<List<Int>>,
     score: Int = 0,
     private val random: Random = Random.Default,
+    val winValue: Int = DEFAULT_WIN_VALUE,
 ) {
     private val cells: Array<IntArray>
 
@@ -67,6 +70,9 @@ class Board(
         require(grid.size == SIZE && grid.all { it.size == SIZE }) {
             "Grid must be $SIZE x $SIZE"
         }
+        require(isValidWinValue(winValue)) {
+            "Win value must be a power of two between $MIN_WIN_VALUE and $MAX_WIN_VALUE"
+        }
         cells = Array(SIZE) { row -> IntArray(SIZE) { col -> grid[row][col] } }
     }
 
@@ -170,15 +176,25 @@ class Board(
         return true
     }
 
-    /** True once any tile reaches [WIN_VALUE]. */
-    fun hasWon(): Boolean = cells.any { row -> row.any { it >= WIN_VALUE } }
+    /** True once any tile reaches [winValue]. */
+    fun hasWon(): Boolean = cells.any { row -> row.any { it >= winValue } }
 
     companion object {
-        const val WIN_VALUE = 2048
+        const val DEFAULT_WIN_VALUE = 2048
+
+        /** Spawned tiles are 2 or 4, so anything lower would win the game on the first tile. */
+        const val MIN_WIN_VALUE = 8
+
+        /** The largest tile a 4 x 4 board can hold. */
+        const val MAX_WIN_VALUE = 131072
+
+        /** A win value is a tile the game can produce: a power of two within the bounds. */
+        fun isValidWinValue(value: Int): Boolean =
+            value in MIN_WIN_VALUE..MAX_WIN_VALUE && value.countOneBits() == 1
 
         /** Starts an empty board and seeds it with two random tiles. */
-        fun newGame(random: Random = Random.Default): Board {
-            val board = Board(List(SIZE) { List(SIZE) { 0 } }, random = random)
+        fun newGame(random: Random = Random.Default, winValue: Int = DEFAULT_WIN_VALUE): Board {
+            val board = Board(List(SIZE) { List(SIZE) { 0 } }, random = random, winValue = winValue)
             board.spawnRandom()
             board.spawnRandom()
             return board
```

   Dolní mez je 8, protože spawnutá dlaždice je 2 nebo 4. Horní mez je největší dlaždice,
   jakou deska 4 × 4 pojme. Z `WIN_VALUE` se stalo `DEFAULT_WIN_VALUE`, takže se mění i jediná
   zmínka o něm v `.github/skills/board-tests/SKILL.md`:

````diff
--- a/.github/skills/board-tests/SKILL.md
+++ b/.github/skills/board-tests/SKILL.md
@@ -30,7 +30,7 @@ fun slideLineLeft(line: IntArray): Int          // mutates the line, returns sco
 Board(grid: List<List<Int>>, score: Int = 0)    // deterministic, for tests
 fun Board.move(direction: Direction): Boolean   // true if the board changed
 fun Board.isGameOver(): Boolean
-fun Board.hasWon(): Boolean                     // any tile >= Board.WIN_VALUE
+fun Board.hasWon(): Boolean                     // any tile >= board.winValue
 ```
 
 ## Running the tests
````

   Deterministické testy v `BoardTest.kt`:

```diff
--- a/engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
+++ b/engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
@@ -4,6 +4,7 @@ import org.junit.jupiter.api.Assertions.assertEquals
 import org.junit.jupiter.api.Assertions.assertFalse
 import org.junit.jupiter.api.Assertions.assertTrue
 import org.junit.jupiter.api.Test
+import org.junit.jupiter.api.assertThrows
 
 class BoardTest {
 
@@ -156,6 +157,63 @@ class BoardTest {
         assertTrue(board.hasWon())
     }
 
+    @Test
+    fun `hasWon triggers at a custom win value`() {
+        val board = Board(
+            listOf(
+                listOf(1024, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+            ),
+            winValue = 1024,
+        )
+
+        assertTrue(board.hasWon())
+    }
+
+    @Test
+    fun `a tile below a custom win value has not won`() {
+        val board = Board(
+            listOf(
+                listOf(2048, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+                listOf(0, 0, 0, 0),
+            ),
+            winValue = 4096,
+        )
+
+        assertFalse(board.hasWon())
+    }
+
+    @Test
+    fun `a power of two within the bounds is a valid win value`() {
+        assertTrue(Board.isValidWinValue(1024))
+    }
+
+    @Test
+    fun `a win value that is not a power of two is invalid`() {
+        assertFalse(Board.isValidWinValue(1000))
+    }
+
+    @Test
+    fun `a win value a spawned tile already reaches is invalid`() {
+        assertFalse(Board.isValidWinValue(4))
+    }
+
+    @Test
+    fun `a win value above the largest possible tile is invalid`() {
+        assertFalse(Board.isValidWinValue(262144))
+    }
+
+    @Test
+    fun `a board refuses an invalid win value`() {
+        val emptyGrid = List(SIZE) { List(SIZE) { 0 } }
+
+        assertThrows<IllegalArgumentException> { Board(emptyGrid, winValue = 1000) }
+    }
+
     @Test
     fun `a board with an empty cell is not game over`() {
         val board = boardOf(
```

   Kroky 2 a 3: metoda service a její vlastní výjimka v `GameService.kt`. Service
   se ptá enginu; pravidlo neopakuje:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
@@ -13,10 +13,13 @@ data class GameState(
     val grid: List<List<Int>>,
     val score: Int,
     val status: GameStatus,
+    val winValue: Int,
 )
 
 class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")
 
+class InvalidWinValueException(winValue: Int) : RuntimeException("Win value $winValue is not allowed")
+
 /**
  * Owns the running games. The rules themselves live in the engine module;
  * this class only decides what happens around a move.
@@ -26,9 +29,13 @@ class GameService {
     // Demo storage: games live in memory only and are lost on restart.
     private val boards = ConcurrentHashMap<UUID, Board>()
 
-    fun create(): GameState {
+    fun create(winValue: Int = Board.DEFAULT_WIN_VALUE): GameState {
+        // The engine owns the rule; the service only turns a refusal into an API error.
+        if (!Board.isValidWinValue(winValue)) {
+            throw InvalidWinValueException(winValue)
+        }
         val id = UUID.randomUUID()
-        val board = Board.newGame()
+        val board = Board.newGame(winValue = winValue)
         boards[id] = board
         return stateOf(id, board)
     }
@@ -56,6 +63,6 @@ class GameService {
             board.hasWon() -> GameStatus.WON
             else -> GameStatus.IN_PROGRESS
         }
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, board.winValue)
     }
 }
```

   Krok 5: controller zůstává mapováním, `GameController.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
@@ -1,5 +1,6 @@
 package com.quanti.g2048.api
 
+import com.quanti.g2048.engine.Board
 import com.quanti.g2048.engine.Direction
 import java.util.UUID
 import org.springframework.http.HttpStatus
@@ -15,13 +16,16 @@ data class ApiResponse<T>(val data: T)
 
 data class MoveRequest(val direction: Direction)
 
+data class CreateGameRequest(val winValue: Int? = null)
+
 @RestController
 @RequestMapping("/api/v1/games")
 class GameController(private val games: GameService) {
 
     @PostMapping
     @ResponseStatus(HttpStatus.CREATED)
-    fun create(): ApiResponse<GameState> = ApiResponse(games.create())
+    fun create(@RequestBody(required = false) request: CreateGameRequest?): ApiResponse<GameState> =
+        ApiResponse(games.create(request?.winValue ?: Board.DEFAULT_WIN_VALUE))
 
     @GetMapping("/{id}")
     fun find(@PathVariable id: UUID): ApiResponse<GameState> = ApiResponse(games.find(id))
```

4. **Navazující prompt: chybová cesta.**
   > *„Pošli v testu `{"winValue": "high"}` na `POST /api/v1/games`. Jakou chybu klient
   > dostane? Zpráva musí platit pro oba endpointy, které berou tělo. A nepovolené
   > číslo potřebuje vlastní kód chyby.“*

   *Mechanismus: znovu skill (krok 4, jeden handler na výjimku, zpráva psaná ručně)
   spolu s pravidlem z `api.instructions.md`, že neparsovatelný vstup vrací 400.*
   `ApiExceptionHandler.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
@@ -1,5 +1,6 @@
 package com.quanti.g2048.api
 
+import com.quanti.g2048.engine.Board
 import org.springframework.http.HttpStatus
 import org.springframework.http.converter.HttpMessageNotReadableException
 import org.springframework.web.bind.annotation.ExceptionHandler
@@ -19,12 +20,26 @@ class ApiExceptionHandler {
     fun gameNotFound(exception: GameNotFoundException): ErrorResponse =
         ErrorResponse(ErrorBody("GAME_NOT_FOUND", exception.message ?: "Game does not exist"))
 
+    @ExceptionHandler(InvalidWinValueException::class)
+    @ResponseStatus(HttpStatus.BAD_REQUEST)
+    fun invalidWinValue(): ErrorResponse =
+        ErrorResponse(
+            ErrorBody(
+                "INVALID_WIN_VALUE",
+                "winValue must be a power of two between ${Board.MIN_WIN_VALUE} and ${Board.MAX_WIN_VALUE}",
+            ),
+        )
+
     // Fixed messages on purpose: the framework's own text leaks class names and parser details.
     @ExceptionHandler(HttpMessageNotReadableException::class)
     @ResponseStatus(HttpStatus.BAD_REQUEST)
     fun unreadableBody(): ErrorResponse =
         ErrorResponse(
-            ErrorBody("INVALID_REQUEST", "Body must be JSON with a direction of UP, DOWN, LEFT or RIGHT"),
+            ErrorBody(
+                "INVALID_REQUEST",
+                "Body must be valid JSON: a direction of UP, DOWN, LEFT or RIGHT for a move, " +
+                    "an integer winValue for a new game",
+            ),
         )
 
     @ExceptionHandler(MethodArgumentTypeMismatchException::class)
```

   Krok 6: jeden test pro úspěšnou cestu a jeden na každé selhání, `GameControllerTest.kt`:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,62 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a game created without a body plays to 2048`() {
+        assertThat(mvc.post().uri("/api/v1/games"))
+            .bodyJson()
+            .extractingPath("$.data.winValue")
+            .isEqualTo(2048)
+    }
+
+    @Test
+    fun `a game created with a body that has no win value plays to 2048`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("{}")
+
+        assertThat(result).bodyJson().extractingPath("$.data.winValue").isEqualTo(2048)
+    }
+
+    @Test
+    fun `a game can be created with a win value of 1024`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":1024}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.CREATED)
+            .bodyJson()
+            .extractingPath("$.data.winValue")
+            .isEqualTo(1024)
+    }
+
+    @Test
+    fun `a win value that is not a power of two returns a structured 400`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":1000}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.BAD_REQUEST)
+            .bodyJson()
+            .extractingPath("$.error.code")
+            .isEqualTo("INVALID_WIN_VALUE")
+    }
+
+    @Test
+    fun `a win value that is not a number returns a structured 400`() {
+        val result = mvc.post().uri("/api/v1/games")
+            .contentType(MediaType.APPLICATION_JSON)
+            .content("""{"winValue":"high"}""")
+
+        assertThat(result)
+            .hasStatus(HttpStatus.BAD_REQUEST)
+            .bodyJson()
+            .extractingPath("$.error.code")
+            .isEqualTo("INVALID_REQUEST")
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

5. **Navazující prompt: review proti skillu.**
   > *„Zkontroluj svůj diff proti sedmi krokům skillu `api-endpoint`. U každého kroku uveď
   > soubor a řádek a vypiš testy, které jsi přidal, s tím, co každý dokazuje.“*

   Pokud ve skillu chyběl krok, který jsi potřeboval (třeba jak vzít volitelné tělo),
   nech ho Copilota doplnit do `SKILL.md` hned. Skill se udržuje jako kód.

**Hotovo.**

```bash
copilot skill list | grep -c '^  api-endpoint'     # 1
./gradlew build                                    # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
```

Referenční řešení hlásí `BoardTest` s `tests="20"` a `GameControllerTest` s
`tests="10"`, obojí `failures="0"`. Pak proti běžícímu API (`./gradlew :api:bootRun` ve
druhém terminálu):

```bash
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":1024}'
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":1000}'
curl -s -X POST localhost:8080/api/v1/games -H 'Content-Type: application/json' -d '{"winValue":"high"}'
curl -s -X POST localhost:8080/api/v1/games
```

```text
{"data":{"id":"ff27d284-a7e7-4bde-8955-eb9ee1f512c2","grid":[[0,0,0,0],[0,0,0,0],[0,2,0,0],[0,0,2,0]],"score":0,"status":"IN_PROGRESS","winValue":1024}}
{"error":{"code":"INVALID_WIN_VALUE","message":"winValue must be a power of two between 8 and 131072"}}
{"error":{"code":"INVALID_REQUEST","message":"Body must be valid JSON: a direction of UP, DOWN, LEFT or RIGHT for a move, an integer winValue for a new game"}}
{"data":{"id":"08254dd1-7d97-42f7-a47d-5f12d7e5ebb5","grid":[[0,0,0,0],[0,2,2,0],[0,0,0,0],[0,0,0,0]],"score":0,"status":"IN_PROGRESS","winValue":2048}}
```

Id a mřížky se při každém běhu liší. První a poslední volání odpoví 201, dvě
prostřední 400. Jeden okrajový případ nechává referenční řešení otevřený: Jackson přečte
`{"winValue": 1024.5}` jako 1024 a hra se vytvoří. Zavřít ho je dobrý prompt navíc.

## 3. Hook 🟡 — udělej testy nepřeskočitelné, pak přidej hlídanou featuru

**Vrstvy:** api · web

**Cíl.** Uprav `.github/hooks/scripts/run-tests.sh` tak, aby padající testy **nedovolily
agentovi skončit**. Pak za tímhle hlídačem postav malou featuru: **počítadlo tahů, které vede
server**. `moves` je součást stavu hry, počítá jen tahy, které změnily desku, a zobrazuje se
v hlavičce.

**Co učí.** [Hook](03-hooks.cs.md), který něco vynucuje v každém kole, bez uvážení modelu.
Instrukce, která říká „spusť testy“, je prosba; hook je fakt.

**Soubory.** `.github/hooks/scripts/run-tests.sh` (změněný; `hooks.json` zůstává, jak je),
`api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`,
`api/.../GameServiceTest.kt` (nový), `api/.../GameControllerTest.kt`, `web/src/api.ts`,
`web/src/App.tsx`, `web/src/App.test.tsx` (nový).

**Kontext na místě.**
- `.github/hooks/hooks.json:37–44` už registruje `run-tests.sh` pod `agentStop` s
  `timeoutSec: 300`. Skript je *poradní*: na červené zapíše jeden řádek na stderr a skončí
  s kódem 2, což CLI zobrazí jako varování. Kolo přesto skončí.
- Hook `agentStop` neumí blokovat návratovým kódem. Blokuje tak, že na stdout vypíše právě
  jeden JSON objekt, `{"decision":"block","reason":"..."}`, a skončí s kódem 0. Agent se
  vrátí k práci a `reason` dostane jako svou další uživatelskou zprávu.
- Payload na stdin obsahuje `sessionId`, `timestamp`, `cwd`, `transcriptPath`, `stopReason` a
  `stop_hook_active`. Poslední je `false` při běžném zastavení a `true` při zastavení, které
  následuje po blokaci. Hlídač, který ho ignoruje, se může zacyklit; podle dokumentace CLI
  kolo po 8 blokacích v řadě stejně ukončí.
- Procesy hooků startují v kořenu repozitáře, takže skript může volat `./gradlew` a
  `cd web` přímo.
- `GameService.move` spočítá `val changed = board.move(direction)` na `GameService.kt:42` a
  nikdy ho nepoužije. Služba ukládá holé desky (`GameService.kt:27`), takže pro počítadlo
  vedené ke každé hře zatím není místo.
- `GameService.create()` začíná z náhodné desky. Test na „tah, který nic nezmění“
  potřebuje desku, kterou má pod kontrolou.

**Startovací prompt.**
> *„Přepiš `.github/hooks/scripts/run-tests.sh` tak, aby hook `agentStop` blokoval, když testy
> padají. Zachovej, co testuje teď: Gradle, když jsou nezacommitované změny v `engine/` nebo
> `api/`, Vitest, když jsou ve `web/src/`. Při selhání vypiš na stdout právě jeden JSON objekt
> `{"decision":"block","reason":"..."}` a skonči s kódem 0. Do `reason` dej padající sady,
> příkaz, kterým je pustit znovu, a posledních 30 řádků výstupu testů. Z JSONu na stdin
> přečti `stop_hook_active`: když je true, znovu neblokuj; zapiš jeden řádek na stderr
> a skonči s kódem 2. Totéž udělej, když chybí `jq`. `hooks.json` neměň.“*

**Walkthrough (kompletní řešení).**

1. **Startovací prompt přepíše skript.** *Mechanismus: zatím žádný; tenhle krok ho teprve staví.*
   Referenční `.github/hooks/scripts/run-tests.sh`:

```bash
#!/usr/bin/env bash
# agentStop hook: when Copilot finishes a turn, run the tests for the parts of
# the tree that have uncommitted changes. If they fail, send Copilot back to
# work once. If they still fail after that, let the turn end with a warning.
#
# An agentStop hook cannot block with an exit code: exit 2 is only a warning.
# It blocks by printing one JSON object, {"decision":"block","reason":"..."},
# and exiting 0. Copilot receives `reason` as its next prompt.
set -uo pipefail

input=$(cat)

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# agentStop fires after every turn, including plain questions. Only test what changed.
changed=$(git status --porcelain 2>/dev/null | awk '{print $NF}')
failed=""
output=""

if printf '%s\n' "$changed" | grep -Eq '^(engine|api)/'; then
    # Not --quiet: that would drop the line that names the failing test.
    if ! result=$(./gradlew test 2>&1); then
        failed="$failed gradle (./gradlew test)"
        output="$output$result"$'\n'
    fi
fi

if printf '%s\n' "$changed" | grep -Eq '^web/src/' && [ -d web/node_modules ]; then
    if ! result=$(cd web && npm test --silent 2>&1); then
        failed="$failed web (cd web && npm test)"
        output="$output$result"$'\n'
    fi
fi

[ -n "$failed" ] || exit 0

# stop_hook_active is true when a block already forced this turn to continue.
# Blocking again could loop until the CLI's own cap, so the second failure only
# warns. Without jq the payload cannot be read and the hook stays advisory.
already_blocked=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$already_blocked" != "false" ]; then
    echo "run-tests hook: tests are failing in:$failed. Not sent back: this turn was already sent back once, or jq is missing." >&2
    exit 2
fi

# The end of the test output is where both runners name the failing test.
jq -cn --arg suites "$failed" --arg tail "$(printf '%s' "$output" | tail -n 30)" \
    '{decision: "block", reason: ("run-tests hook: tests are failing in:" + $suites + ". Find the cause, fix it, run the suite yourself and finish only when it passes. Do not weaken or delete a test to get there. End of the test output:\n" + $tail)}'
exit 0
```

   Co se změnilo proti poradní verzi: stdin se uchová, místo aby se jen vyprázdnil, výstup
   testů se zachytává, Gradle běží bez `--quiet` (s ním zmizí řádek, který jmenuje spadlý
   test) a na konci je rozhodnutí místo pevného návratového kódu. Hlídač blokuje jednou za
   kolo. To je záměr: jedno vynucené kolo stačí, aby si agent sadu pustil sám tolikrát,
   kolikrát potřebuje, a workshopová session se nemůže zaseknout. Chceš-li přísnějšího
   hlídače, smaž větev `stop_hook_active` a spolehni se na strop v CLI.

2. **Otestuj skript bez Copilota.** Hook je program, který čte JSON a vypisuje JSON,
   tak ho nakrm ručně. Z kořene repozitáře, když je změněný jen skript:

```bash
payload() { printf '{"sessionId":"demo","cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }

# Nothing under engine/, api/ or web/src/ changed: no tests run, the turn may end.
payload false | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"
```

```text
exit=0
```

   Teď udělej strom červený. Tohle překlopí jedno očekávání v testu (jednorázová úprava, níže se vrací zpět):

```bash
perl -pi -e "s/toBe\('UP'\)/toBe('DOWN')/" web/src/keys.test.ts

# Red, first stop: the hook blocks.
payload false | ./.github/hooks/scripts/run-tests.sh | jq -r '.decision, .reason' | head -n 14
```

```text
block
run-tests hook: tests are failing in: web (cd web && npm test). Find the cause, fix it, run the suite yourself and finish only when it passes. Do not weaken or delete a test to get there. End of the test output:

 RUN  v5.1.1 /path/to/qti-copilot/web

 ❯ src/keys.test.ts (4 tests | 1 failed) 4ms
   ❯ toDirection (4)
     × maps a WASD key to its direction 2ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/keys.test.ts > toDirection > maps a WASD key to its direction
AssertionError: expected 'UP' to be 'DOWN' // Object.is equality

```

```bash
# Red, the stop after a block: no second block, a warning instead.
payload true | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"

git restore web/src/keys.test.ts
```

```text
run-tests hook: tests are failing in: web (cd web && npm test). Not sent back: this turn was already sent back once, or jq is missing.
exit=2
```

   Tohle je skutečný výstup referenčního skriptu; zkrácená je jen cesta k repozitáři. Při
   padajícím kotlinovém testu zní první řádek `tests are failing in: gradle (./gradlew test)`
   a konec výstupu obsahuje řádek Gradlu `GameServiceTest > … FAILED`.

3. **Sleduj hlídače v session.** `hooks.json` se nezměnil a CLI spouští skript při každém
   zastavení znovu, takže běžící session už používá novou verzi. `/env` vypíše načtené
   hooky. Zadej Copilotovi úkol, který rozbije test:
   > *„V `web/src/keys.ts` udělej `toDirection` citlivé na velikost písmen: velké `W` se už
   > nesmí počítat jako tah. Testy nespouštěj.“*

   *Mechanismus: hook `agentStop`.* Co bys měl vidět:
   1. Copilot upraví `keys.ts` a napíše závěrečnou odpověď.
   2. Prompt se nevrátí. Hook právě pouští Vitest; trvá to pár vteřin.
   3. Začne nové kolo, které jsi nenapsal. Jeho uživatelská zpráva je `reason` z hooku:
      `run-tests hook: tests are failing in: web (cd web && npm test). …` a za ním konec
      výstupu testů, kde je jako padající test `ignores the case of a WASD key`.
   4. Copilot na tom pracuje. Zadání a test si odporují a `reason` zakazuje test oslabit,
      takže by měl buď vrátit původní chování a říct ti o konfliktu, nebo se tě zeptat,
      které z těch dvou platí.
   5. Když se zastaví znovu, hook běží se `stop_hook_active: true`. Zelená: nic se
      nevypíše a kolo skončí. Pořád červená: dostaneš varovný řádek z kroku 2 a kolo
      skončí stejně.

   Sekvence blokace → `reason` jako další uživatelská zpráva → `stop_hook_active: true` byla
   ověřena na CLI 1.0.114. Samotný referenční skript byl ověřen payloady z kroku 2, ne
   v živé session, takže formulace, které Copilot použije, se od tohoto seznamu budou lišit.
   Než budeš pokračovat: *„Vrať `keys.ts` přesně do původního stavu.“*

4. **Navazující prompt: featura za hlídačem.**
   > *„Server má počítat tahy. Přidej do stavu hry `moves`: 0 pro novou hru, plus jedna za
   > každý tah, který změnil desku; tah, který nic nezmění, se nepočítá. Zobraz ho v hlavičce
   > webu jako `moves: N`. Potřebuju test, který dokáže, že se tah naprázdno nepočítá.
   > `GameService.create()` začíná z náhodné desky, tak dej službě způsob, jak spustit hru
   > na desce, kterou dodá test, aniž by to bylo vystavené přes HTTP. Spawn dlaždice nech,
   > jak je.“*

   *Mechanismus: hlídač, potichu. Pokaždé, když si Copilot myslí, že je hotov, hook pustí
   Gradle a Vitest nad tím, co se změnilo. Když se Copilot zastaví ve chvíli, kdy se některý
   test už nezkompiluje, je poslán zpět s řádkem kotlinového kompilátoru
   `e: …GameServiceTest.kt:36:25 Unresolved reference` v `reason` (zkontrolováno se záměrně
   rozbitým testem).*

   `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`, celý:

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import org.springframework.stereotype.Service

enum class GameStatus { IN_PROGRESS, WON, OVER }

data class GameState(
    val id: UUID,
    val grid: List<List<Int>>,
    val score: Int,
    val status: GameStatus,
    val moves: Int,
)

class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")

/** A running game: the board plus what the API tracks around it. */
private class Game(val board: Board) {
    var moves: Int = 0
}

/**
 * Owns the running games. The rules themselves live in the engine module;
 * this class only decides what happens around a move.
 */
@Service
class GameService {
    // Demo storage: games live in memory only and are lost on restart.
    private val games = ConcurrentHashMap<UUID, Game>()

    fun create(): GameState = start(Board.newGame())

    /** Starts a game on the given board. Tests use it to begin from a known position. */
    internal fun start(board: Board): GameState {
        val id = UUID.randomUUID()
        val game = Game(board)
        games[id] = game
        return stateOf(id, game)
    }

    fun find(id: UUID): GameState = stateOf(id, gameFor(id))

    fun move(id: UUID, direction: Direction): GameState {
        val game = gameFor(id)
        // Board is not thread-safe; two requests for the same game must not interleave.
        synchronized(game) {
            val changed = game.board.move(direction)
            if (changed) {
                game.moves++
            }

            // Place a new tile.
            game.board.spawnRandom()

            return stateOf(id, game)
        }
    }

    private fun gameFor(id: UUID): Game = games[id] ?: throw GameNotFoundException(id)

    private fun stateOf(id: UUID, game: Game): GameState {
        val board = game.board
        val status = when {
            board.isGameOver() -> GameStatus.OVER
            board.hasWon() -> GameStatus.WON
            else -> GameStatus.IN_PROGRESS
        }
        return GameState(id, board.grid, board.score, status, game.moves)
    }
}
```

   Služba teď ukládá `Game` (deska plus počítadlo) místo holé desky a poprvé používá
   příznak `changed`. `start(board)` je šev pro testy: je `internal`, takže ho vidí testy
   tohoto modulu a nic dalšího. Cvičení 5 řeší stejný problém jinak, parametrem
   konstruktoru, který desku dodá; obojí je v pořádku, a protože každé cvičení začíná
   z čistého `main`, nikdy se nepotkají. Spawn po tahu naprázdno tu pořád je; patří do
   cvičení 5. Pokud ho Copilot přesto ohlídá přes `if (changed)`, testy níže stále projdou.

   `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (nový, čistý JUnit, bez Springu):

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    private val games = GameService()

    /** One pair to merge: a move to the left changes this board. */
    private fun mergeableBoard(): Board = Board(
        listOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        ),
    )

    /** Full and without equal neighbours: no move changes this board. */
    private fun lockedBoard(): Board = Board(
        listOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        ),
    )

    @Test
    fun `a new game has made no moves`() {
        val game = games.create()

        assertThat(game.moves).isEqualTo(0)
    }

    @Test
    fun `a move that changes the board is counted`() {
        val game = games.start(mergeableBoard())

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.moves).isEqualTo(1)
    }

    @Test
    fun `a move that changes nothing is not counted`() {
        val game = games.start(lockedBoard())

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.moves).isEqualTo(0)
    }

    @Test
    fun `each game keeps its own count`() {
        val played = games.start(mergeableBoard())
        val untouched = games.start(mergeableBoard())

        games.move(played.id, Direction.LEFT)

        assertThat(games.find(untouched.id).moves).isEqualTo(0)
    }
}
```

   Jeden případ v `GameControllerTest.kt` fixuje JSON pole:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,14 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a new game reports zero moves`() {
+        assertThat(mvc.post().uri("/api/v1/games"))
+            .bodyJson()
+            .extractingPath("$.data.moves")
+            .isEqualTo(0)
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

5. **Navazující prompt: klient.**
   > *„Zobraz počítadlo v hlavičce. Číslo přichází ze serveru; klient nepočítá. Otestuj
   > `App` s namockovaným API modulem.“*

   `web/src/api.ts` a `web/src/App.tsx`:

```diff
--- a/web/src/api.ts
+++ b/web/src/api.ts
@@ -7,6 +7,7 @@ export interface Game {
   grid: number[][]
   score: number
   status: GameStatus
+  moves: number
 }
 
 interface ApiResponse<T> {
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -57,6 +57,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="moves">moves: {game?.moves ?? 0}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` (nový). Třetí případ je ten, který odliší počítání na serveru od
   počítání v klientovi:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
  moves: 0,
}

describe('App move counter', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
  })

  it('shows zero moves for a new game', async () => {
    render(<App />)

    expect(await screen.findByText('moves: 0')).toBeInTheDocument()
  })

  it('shows the move count the server reports', async () => {
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4, moves: 1 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('moves: 1')).toBeInTheDocument()
  })

  it('does not count a key press the server did not count', async () => {
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 4, moves: 0 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')
    await screen.findByText('score: 4')

    expect(screen.getByText('moves: 0')).toBeInTheDocument()
  })
})
```

**Hotovo.**

```bash
# The gate, on your finished tree (green): prints nothing.
payload() { printf '{"sessionId":"demo","cwd":"%s","stopReason":"end_turn","stop_hook_active":%s}' "$PWD" "$1"; }
payload false | ./.github/hooks/scripts/run-tests.sh; echo "exit=$?"     # exit=0

./gradlew build                                                          # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

- Červený a už jednou zablokovaný payload z kroku 2 walkthrough dají `block` a `exit=2`.
- Referenční řešení hlásí `BoardTest` 13, `GameControllerTest` 6 a `GameServiceTest`
  4 testy s `failures="0"` a Vitest končí na `Tests  10 passed (10)`.
- Proti běžícímu API `moves` roste a nová hra začíná zase od 0. Skutečný běh referenčního
  řešení (vytvoření, pak osm tahů, které všechny změnily desku, pak nová hra), filtrovaný
  přes `jq -c '.data | {score, moves}'`:

```text
{"score":0,"moves":1}
{"score":4,"moves":2}
{"score":4,"moves":3}
{"score":8,"moves":4}
{"score":8,"moves":5}
{"score":8,"moves":6}
{"score":20,"moves":7}
{"score":20,"moves":8}
{"score":0,"moves":0}
```

- V session se úkol, který rozbije test, jednou vrátí zpět (krok 3 walkthrough).
- Hlídač funguje v CLI. Podle dokumentace `agentStop` není mezi hook eventy, které
  publikuje IntelliJ plugin, takže ho tam nečekej.

## 4. MCP 🟡 — implementuj featuru přímo z GitHub issue

**Vrstvy:** api · web

**Cíl.** Lektor založí ve workshopovém repozitáři issue „Show the best score“.
Ty necháš Copilota **přečíst issue přes vestavěný GitHub MCP server** a implementovat ho:
server si drží nejlepší skóre dosažené napříč hrami (v paměti) a vrací ho a hlavička
zobrazuje `best: N`. Pak otevři pull request přes `/pr create`.

**Co učí.** [MCP](04-mcp.cs.md) jako způsob, jak agent dosáhne na systém mimo pracovní
strom. Nic se neinstaluje a žádný `.mcp.json` se nepíše: CLI si spustí vlastní GitHub
server, `github-mcp-server`, když jsi přihlášený. Ty jen volíš, které z jeho nástrojů
model dostane. V 2N jsou tenhle server a schválený Jira server reálné zdroje specifikace,
takže právě tenhle workflow stojí za to trénovat: issue je spec, agent si ho přečte sám
a ty proti němu zreviduješ výsledek.

**Předpoklady.**
- Politika organizace pro Copilota „MCP servers in Copilot“ je zapnutá. Podle dokumentace
  se od CLI 1.0.112 vestavěný server nespustí, když tahle politika MCP vypne. Na MCP
  allow-listy se nevztahuje, takže není potřeba žádný záznam v registru.
- Jsi přihlášený do Copilota účtem, který má k workshopovému repozitáři **přístup pro
  čtení** (a má pro organizaci autorizované SSO, pokud ho vynucuje), a tvůj klon má svůj
  GitHub remote.
- **Spusť session s vyjmenovanými nástroji pro issues.** Které nástroje vestavěný server
  nabídne, záleží na tom, jestli máš `gh` v `PATH`. Otestováno na CLI 1.0.114: s
  nainstalovaným `gh`, což je případ většiny vývojářských strojů, nabízí 6 nástrojů a
  žádný z nich nečte issues; bez `gh` jich nabízí 24, včetně `list_issues` a `issue_read`.
  Ty dva nástroje proto vyjmenuj sám. `--add-github-mcp-tool` nahradí výchozí podmnožinu
  přesně tím, co vyjmenuješ:

  ```bash
  scripts/copilot-ws.sh --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read
  ```

  Launcher předá tyhle přepínače `copilot` beze změny. V session ukáže
  `/mcp get github-mcp-server` ty dva nástroje. Oba jen čtou. Seznamy nástrojů pro
  jednotlivá nastavení a další způsoby, jak sadu rozšířit, jsou v
  [návodu k MCP](04-mcp.cs.md#vestavěný-github-mcp-server).
- `/pr create` potřebuje **přístup pro push** a branch. Pokud máš jen přístup pro čtení,
  skonči po commitu a pull request nech ukázat lektora.

Pro návod k MCP otestováno na CLI 1.0.114: počty nástrojů, přepínač a volání `list_issues`
v režimu `-p` proti veřejnému repozitáři, které proběhlo bez allow pravidla. Čtení issues
*tohoto* repozitáře otestováno nebylo, protože v době psaní katalogu nemělo GitHub remote.

**Záloha, když vestavěný server není k dispozici** (politika vypnutá, `github-mcp-server`
chybí v `/mcp list`, žádný přístup k repozitáři): vlož do promptu místo čísla issue text
issue níže. Všechno po prvním kroku je stejné. Uveď to v pull requestu.

**Issue (lektor: založ ho jednou ve workshopovém repozitáři).**

Název: `Show the best score`

```markdown
As a player I want to see the best score reached so far, so that I have something to beat.

## Acceptance criteria

- [ ] The API remembers the highest score any game has reached since the server started.
      In memory is enough; it is lost on restart, like the games.
- [ ] Every game state the API returns (create, find, move) carries it as `bestScore`.
- [ ] A new game reports the best score of earlier games, not 0.
- [ ] A later game with a lower score does not lower it.
- [ ] The web header shows `best: N` next to the score.
- [ ] Tests cover each point above.

## Out of scope

Persistence across restarts. Per-player scores.
```

**Soubory.** `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`,
`api/.../GameServiceTest.kt` (nový), `api/.../GameControllerTest.kt`, `web/src/api.ts`,
`web/src/App.tsx`, `web/src/App.test.tsx` (nový). Žádný konfigurační soubor MCP.

**Kontext na místě.**
- `GameService` je singleton, který drží všechny hry v mapě (`GameService.kt:27`). Hodnota
  sdílená všemi hrami patří vedle téhle mapy.
- `GameControllerTest` pouští všechny své testy proti jednomu Spring kontextu, tedy proti
  jedné `GameService`. Nejlepší skóre je sdílený stav: assert na přesnou hodnotu by tam
  udělal testy závislé na pořadí. Přesné hodnoty se testují na čerstvé `GameService()` pro
  každý test.
- `GameService.create()` začíná z náhodné desky, takže test, který potřebuje známé skóre,
  potřebuje desku, kterou má pod kontrolou (stejný šev jako ve cvičení 3).
- `.github/copilot-instructions.md` říká, že `web` jen renderuje. Klient zobrazuje číslo,
  které pošle server; sám žádné maximum nepočítá.

**Startovací prompt.** Spusť session se dvěma přepínači z předpokladů. Nahraď
`<N>` číslem issue, které oznámí lektor.
> *„Přečti issue #<N> tohoto repozitáře nástrojem issue_read z GitHub MCP serveru.
> Zopakuj jeho akceptační kritéria jako číslovaný seznam a pak ke každému vyjmenuj soubory,
> které bys změnil. Zatím nic needituj.“*

**Walkthrough (kompletní řešení).**

1. **Startovací prompt přečte issue.** *Mechanismus: vestavěný GitHub MCP server. Časová
   osa ukáže volání `github-mcp-server-issue_read` (model vidí každý MCP nástroj s názvem
   serveru jako prefixem) a po něm čtení lokálních souborů.* Pokud Copilot odpoví, že na
   issues nemá nástroj, nebo sáhne po `gh issue view` v shellu, session byla spuštěná bez
   těch dvou přepínačů: ukonči ji a spusť znovu. Zkontroluj, že seznam, který Copilot
   zopakuje, odpovídá issue. Je to spec pro všechno, co následuje.

2. **Navazující prompt: implementuj to.**
   > *„Implementuj issue. Nejlepší skóre drž v `GameService`, v paměti. Otestuj ho přímo na
   > službě, s čerstvou `GameService()` pro každý test, protože nejlepší skóre sdílejí
   > všechny hry; dej službě způsob, jak spustit hru na desce, kterou dodá test. Přidej
   > jeden controller test na JSON pole. Pak webový klient, s `App` otestovanou proti
   > namockovanému API modulu.“*

   *Mechanismus: běžná práce agenta pod instrukcemi a hooky repozitáře. MCP dodalo
   specifikaci; na editaci se nepodílí.*

   `GameService.kt`:

```diff
--- a/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
+++ b/api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
@@ -4,6 +4,7 @@ import com.quanti.g2048.engine.Board
 import com.quanti.g2048.engine.Direction
 import java.util.UUID
 import java.util.concurrent.ConcurrentHashMap
+import java.util.concurrent.atomic.AtomicInteger
 import org.springframework.stereotype.Service
 
 enum class GameStatus { IN_PROGRESS, WON, OVER }
@@ -13,6 +14,7 @@ data class GameState(
     val grid: List<List<Int>>,
     val score: Int,
     val status: GameStatus,
+    val bestScore: Int,
 )
 
 class GameNotFoundException(id: UUID) : RuntimeException("Game $id does not exist")
@@ -26,9 +28,14 @@ class GameService {
     // Demo storage: games live in memory only and are lost on restart.
     private val boards = ConcurrentHashMap<UUID, Board>()
 
-    fun create(): GameState {
+    // Highest score any game has reached since the server started. Lost on restart, like the games.
+    private val bestScore = AtomicInteger(0)
+
+    fun create(): GameState = start(Board.newGame())
+
+    /** Starts a game on the given board. Tests use it to begin from a known position. */
+    internal fun start(board: Board): GameState {
         val id = UUID.randomUUID()
-        val board = Board.newGame()
         boards[id] = board
         return stateOf(id, board)
     }
@@ -44,6 +51,7 @@ class GameService {
             // Place a new tile.
             board.spawnRandom()
 
+            bestScore.updateAndGet { best -> maxOf(best, board.score) }
             return stateOf(id, board)
         }
     }
@@ -56,6 +64,6 @@ class GameService {
             board.hasWon() -> GameStatus.WON
             else -> GameStatus.IN_PROGRESS
         }
-        return GameState(id, board.grid, board.score, status)
+        return GameState(id, board.grid, board.score, status, bestScore.get())
     }
 }
```

   `AtomicInteger` proto, že dvě hry můžou táhnout zároveň; blok `synchronized` hlídá jen
   jednu desku. `start(board)` je `internal`: viditelný pro testy tohoto modulu, ne pro
   HTTP.

   `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (nový, čistý JUnit). JUnit
   vytváří pro každý test novou instanci třídy, takže každý dostane vlastní službu:

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    // A fresh service per test: the best score is shared by every game of one service.
    private val games = GameService()

    /** A board whose only move to the left merges one pair and scores twice the tile value. */
    private fun boardWithPairOf(tile: Int): Board = Board(
        listOf(
            listOf(tile, tile, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        ),
    )

    @Test
    fun `the best score starts at zero`() {
        val game = games.create()

        assertThat(game.bestScore).isEqualTo(0)
    }

    @Test
    fun `a move that beats the best score raises it`() {
        val game = games.start(boardWithPairOf(2))

        val moved = games.move(game.id, Direction.LEFT)

        assertThat(moved.bestScore).isEqualTo(4)
    }

    @Test
    fun `a new game reports the best score of an earlier game`() {
        val earlier = games.start(boardWithPairOf(2))
        games.move(earlier.id, Direction.LEFT)

        val later = games.create()

        assertThat(later.bestScore).isEqualTo(4)
    }

    @Test
    fun `a lower score in a later game does not lower the best score`() {
        val earlier = games.start(boardWithPairOf(4))
        games.move(earlier.id, Direction.LEFT)
        val later = games.start(boardWithPairOf(2))

        val moved = games.move(later.id, Direction.LEFT)

        assertThat(moved.bestScore).isEqualTo(8)
    }
}
```

   `GameControllerTest.kt` jen fixuje, že pole je v JSONu:

```diff
--- a/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
+++ b/api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
@@ -31,6 +31,11 @@ class GameControllerTest(@Autowired private val mvc: MockMvcTester) {
             .isLenientlyEqualTo("""{"data":{"score":0,"status":"IN_PROGRESS"}}""")
     }
 
+    @Test
+    fun `a game state carries the best score`() {
+        assertThat(mvc.post().uri("/api/v1/games")).bodyJson().hasPath("$.data.bestScore")
+    }
+
     @Test
     fun `a move returns the game with its four rows`() {
         val id = createGameId()
```

   `web/src/api.ts` a `web/src/App.tsx`:

```diff
--- a/web/src/api.ts
+++ b/web/src/api.ts
@@ -7,6 +7,7 @@ export interface Game {
   grid: number[][]
   score: number
   status: GameStatus
+  bestScore: number
 }
 
 interface ApiResponse<T> {
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -57,6 +57,7 @@ export function App() {
       <header className="app-header">
         <h1>2048</h1>
         <p className="score">score: {game?.score ?? 0}</p>
+        <p className="best">best: {game?.bestScore ?? 0}</p>
         <button type="button" onClick={startGame}>
           New game
         </button>
```

   `web/src/App.test.tsx` (nový):

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 2, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
  bestScore: 128,
}

describe('App best score', () => {
  it('shows the best score a new game reports', async () => {
    vi.mocked(createGame).mockResolvedValue(GAME)

    render(<App />)

    expect(await screen.findByText('best: 128')).toBeInTheDocument()
  })

  it('shows the new best score after a move that beats it', async () => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    vi.mocked(move).mockResolvedValue({ ...GAME, score: 256, bestScore: 256 })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByRole('grid')

    await user.keyboard('{ArrowLeft}')

    expect(await screen.findByText('best: 256')).toBeInTheDocument()
  })
})
```

3. **Navazující prompt: review proti issue.**
   > *„Přečti issue #<N> znovu. Projdi jeho akceptační kritéria jedno po druhém a ke každému
   > vyjmenuj test, který ho dokazuje. Pokud některé test nemá, napiš ho.“*

   *Mechanismus: znovu MCP, jako zdroj pravdy pro recenzenta.* V referenčním řešení:
   kritéria 1–4 jsou čtyři případy `GameServiceTest`, JSON pole je
   `a game state carries the best score` a hlavička jsou dva případy v `App.test.tsx`.

4. **Navazující prompty: commit a otevření pull requestu.**
   > *„Zacommituj to na aktuální branch. Ve zprávě odkaž na issue #<N>.“*

   Pak napiš `/pr create`. *Mechanismus: vlastní příkaz CLI pro pull requesty, ne zapisující
   MCP nástroj; dva čtecí nástroje stačí. Podle dokumentace pracuje na aktuální branchi
   repozitáře hostovaného na GitHubu a otevře pull request s tebou jako autorem; podle
   changelogu ho plan mode blokuje. V tomto repu netestováno.* Přečti si popis, který
   Copilot napsal, než ho schválíš, a ujisti se, že obsahuje `Closes #<N>`.

**Hotovo.**

```bash
./gradlew build                                        # BUILD SUCCESSFUL
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

- Referenční řešení hlásí `BoardTest` 13, `GameControllerTest` 6 a `GameServiceTest`
  4 testy s `failures="0"`; Vitest končí na `Tests  9 passed (9)`; ESLint nevypíše žádné nálezy.
- Proti běžícímu API nejlepší skóre přežije novou hru. Skutečný běh referenčního
  řešení (vytvoření, osm tahů, pak nová hra), filtrovaný přes
  `jq -c '.data | {score, bestScore}'`:

```text
{"score":0,"bestScore":0}
{"score":0,"bestScore":0}
{"score":4,"bestScore":4}
{"score":12,"bestScore":12}
{"score":12,"bestScore":12}
{"score":20,"bestScore":20}
{"score":20,"bestScore":20}
{"score":24,"bestScore":24}
{"score":0,"bestScore":24}
```

- Časová osa session obsahuje volání `github-mcp-server-issue_read`, které issue načetlo,
  nebo pull request uvádí, že text issue byl vložen do promptu (záloha).
- `/pr view` ukáže pull request pro tvou branch, který odkazuje na issue (podle dokumentace).

## 5. Vlastní agenti 🟡 — deleguj undo featuru mezi tři agenty

**Vrstvy:** engine · api · web

**Cíl.** Postav **undo** ve všech třech vrstvách a každou část práce předej agentovi,
který se na ni hodí ([Ukázka 5](05-agents.cs.md), [Ukázka 6](06-plugins.cs.md)):

- `2048-dev:game-explorer` (agent z pluginu, jen čtení a hledání) vystopuje, kam změna patří.
- `board-test-writer` (projektový agent, edituje a pouští Gradle) napíše nejdřív testy enginu.
- **Hlavní session** implementuje.
- `kotlin-reviewer` (projektový agent, bez editačního nástroje) zreviduje diff.

Kontrakt: `Board.undo()` vezme zpět poslední tah, který změnil desku, a obnoví mřížku
i skóre. V čerstvé hře nic nezmění a vrátí `false`. API dostane
`POST /api/v1/games/{id}/undo`. Webové UI dělá undo klávesou `u` a má tlačítko **Undo**.

Jako rozcvičku oprav dva ze tří záměrných bugů, každý s testem napsaným před opravou.
Undo závisí na obou: tah, který nic nezmění, se nesmí počítat jako odehraný tah, a „game
over“ musí znamenat, že už žádný tah nezbývá.

**Co učí.** [Vlastní agenty](05-agents.cs.md) jako tým. Když v promptu jmenuješ agenta,
hlavní agent zavolá nástroj `task` s `agent_type` nastaveným na tohoto agenta. Agent pracuje
ve vlastním kontextu s vlastním seznamem nástrojů a po dokončení podá hlášení. Plynou
z toho dvě věci. Čtení souborů při průzkumu a výstup testovacího běhu zůstanou mimo
kontext hlavní session. A o tom, co agent smí, rozhoduje seznam nástrojů, ne prompt:
explorer a reviewer soubor upravit nemůžou, test writer ano.

**Soubory.**

- `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt` — oprava `isGameOver()`, historie, `undo()`
- `engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` — 9 nových testů
- `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt` — továrna na desku, podmínka spawnu, `undo()`
- `api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` — endpoint
- `api/src/test/kotlin/com/quanti/g2048/api/GameServiceTest.kt` (nový), `GameControllerTest.kt`
- `web/src/api.ts`, `web/src/keys.ts`, `web/src/App.tsx`
- `web/src/keys.test.ts`, `web/src/App.test.tsx` (nový)

**Kontext na místě.**

- **Bug A, `Board.isGameOver()`** (`Board.kt`, řádky 160–171) vrací `true`, jakmile
  nenajde prázdnou buňku. Sousedy nikdy neporovnává, takže plná deska, která pořád má
  mergeable pár, je hlášená jako game over. Chybějící test je TODO na konci
  `BoardTest.kt` (řádky 183–185).
- **Bug B, `GameService.move`** (`GameService.kt`, řádky 38–49) přiřadí
  `val changed = board.move(direction)` na řádku 42 a na řádku 45 volá `board.spawnRandom()`
  bez ohledu na výsledek. Tah, který nic neposune, přesto spawne dlaždici. Žádný
  `GameServiceTest` neexistuje a `create()` začíná každou hru přes `Board.newGame()`
  (řádek 31), který umístí dvě náhodné dlaždice. Test na tenhle bug potřebuje známou desku
  a dnes ji službě předat nejde.
- **Cesta, po které musí undo jít**, je cesta tahu:
  `App.onKeyDown → toDirection() → api.move() → GameController.move() → GameService.move() → Board.move() → Board.spawnRandom()`.
  `Board.move` už mřížku kopíruje do `before` (řádek 83), aby spočítal návratovou hodnotu.
  Tahle kopie je snímek, který undo potřebuje.
- **Past ve webové vrstvě:** `App.tsx` svůj listener kláves vůbec nepřipojí, když
  `game.status === 'OVER'` (řádek 35). Přesně tehdy je undo nejužitečnější.

Spusť session přes `scripts/copilot-ws.sh`. Předem schvaluje `./gradlew`, `npm test` a
`npm run`, které potřebují test writer a kontrola hotovo. `kotlin-reviewer` čte změnu
přes `git status` a `git diff`; schval je, až se zeptá.

**Startovací prompt — bug A (`isGameOver`).**
> *„Použij agenta board-test-writer: proměň TODO na konci
> `engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt` v test na plnou desku,
> která pořád obsahuje dva stejné sousedy, a ověř, že `isGameOver()` vrací false.
> Spusť testy enginu a nahlas výsledek. `Board.kt` neměň.“*

**Startovací prompt — bug B (ignorovaný příznak `changed`).**
> *„`GameService.move` v `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt` spočítá
> `changed` a ignoruje ho, takže tah, který nic neposune, přesto spawne dlaždici. Napiš
> nejdřív padající test, v novém `GameServiceTest.kt`: tah, který nic nezmění, nechá
> mřížku beze změny. Test nesmí záviset na náhodných dlaždicích. Dej `GameService` parametr
> konstruktoru `newBoard: () -> Board` s výchozí hodnotou `{ Board.newGame() }` a testovací
> hru spusť z desky, která se nemůže pohnout doleva. Spusť `./gradlew :api:test` a ukaž mi
> selhání, než cokoli opravíš.“*

**Startovací prompt — undo.**
> *„Použij agenta 2048-dev:game-explorer: chceme undo featuru. Engine si drží historii,
> aby šel poslední tah vzít zpět (mřížka i skóre), API dostane
> `POST /api/v1/games/{id}/undo` a webové UI dělá undo klávesou `u` a tlačítkem Undo.
> Vystopuj, jak tah putuje od stisku klávesy do `Board.move` a zpět na obrazovku, a pak
> vyjmenuj každou funkci, která se pro undo musí změnit nebo přidat, vrstvu po vrstvě.
> Žádný soubor neměň.“*

**Walkthrough (kompletní řešení).**

> **Co se pro tento katalog spustilo.** Kód níže byl sestaven a otestován v čistém worktree
> tohoto repozitáře. Dva z delegačních kroků se navíc spustily proti Copilot CLI 1.0.114
> a jsou citované: trasa od `2048-dev:game-explorer` (krok 1) a review hotového diffu od
> `kotlin-reviewer` (krok 6). Prompty pro `board-test-writer` a pro implementaci se znovu
> nepřehrávaly; ber je jako scénář, ne jako záznam.

*Rozcvička A — `isGameOver()`. Mechanismus: `board-test-writer`, pak hlavní session.*

Startovací prompt chce po agentovi jen test. Tohle je ten test (`BoardTest.kt`,
místo TODO):

```kotlin
    @Test
    fun `a full board with a mergeable pair is not game over`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 2, 4),
        )

        assertFalse(board.isGameOver())
    }
```

Poslední řada má dvě dvojky vedle sebe. `./gradlew :engine:test` spadne, a o to jde:

```text
BoardTest > a full board with a mergeable pair is not game over() FAILED
    org.opentest4j.AssertionFailedError at BoardTest.kt:192
14 tests completed, 1 failed
```

`board-test-writer` má v instrukcích ponechat správný assert a bug nahlásit, místo aby
test ohýbal. Teď nech hlavní session pravidlo opravit:

> *„Nový test padá, protože `Board.isGameOver()` hledá jen prázdnou buňku. Oprav to
> v `Board.kt`: plná deska se dvěma stejnými sousedy, vedle sebe nebo nad sebou, není
> game over. Spusť `./gradlew :engine:test` a nahlas počty.“*

```kotlin
    /** True when no move is possible: the board is full and no two neighbours are equal. */
    fun isGameOver(): Boolean {
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                val value = cells[row][col]
                if (value == 0) {
                    return false
                }
                // Looking right and down covers every neighbouring pair exactly once.
                if (col + 1 < SIZE && cells[row][col + 1] == value) {
                    return false
                }
                if (row + 1 < SIZE && cells[row + 1][col] == value) {
                    return false
                }
            }
        }
        return true
    }
```

Stačí jeden průchod. Každá buňka se porovná se svým pravým a spodním sousedem, takže každý
pár se uvidí jednou. Prázdný soused se nikdy nerovná nenulové hodnotě a smyčka vrátí
`false`, když dojde na samotnou prázdnou buňku.

*Rozcvička B — příznak `changed`. Mechanismus: hlavní session.*

Tohle je logika služby, takže `board-test-writer` je špatný agent: jeho instrukce ho drží
u `Board`. Obtížný je test, ne oprava. `GameService.create()` staví náhodnou desku a test,
který doufá v tah naprázdno na náhodných dlaždicích, není test.

Východisko je šev: služba dostane funkci, která desku vytváří. Produkce si nechá výchozí
hodnotu. Test předá funkci, která vrátí desku, kterou si sám zvolil
(`GameService.kt`):

```kotlin
@Service
class GameService(
    // Tests pass a factory that returns a known board. Spring finds no bean of this type and,
    // because the parameter has a default, falls back to a random new game.
    private val newBoard: () -> Board = { Board.newGame() },
) {
    // Demo storage: games live in memory only and are lost on restart.
    private val boards = ConcurrentHashMap<UUID, Board>()

    fun create(): GameState {
        val id = UUID.randomUUID()
        val board = newBoard()
        boards[id] = board
        return stateOf(id, board)
    }
```

Spring službu pořád zkonstruuje bez pomoci. Hledá bean typu `() -> Board`, žádný nenajde,
a protože kotlinový parametr má výchozí hodnotu, použije ji. Ověřeno tady dvěma způsoby:
stávající `@WebMvcTest` s `@Import(GameService::class)` pořád prochází a
`./gradlew :api:bootRun` nastartuje a obsluhuje hry.

Teď test. Deska je zvolená tak, aby výsledek nezávisel na náhodě ani jedním směrem
(`GameServiceTest.kt`, nový soubor; v kroku 4 do něj přibudou další tři testy):

```kotlin
package com.quanti.g2048.api

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class GameServiceTest {

    /** A service whose every new game starts from the given rows instead of two random tiles. */
    private fun serviceStartingWith(vararg rows: List<Int>): GameService = GameService { Board(rows.toList()) }

    @Test
    fun `a move that changes nothing leaves the grid unchanged`() {
        // Both rows are packed to the left with no equal neighbours, so LEFT cannot move a tile.
        val games = serviceStartingWith(
            listOf(2, 4, 0, 0),
            listOf(4, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val moved = games.move(created.id, Direction.LEFT)

        assertThat(moved.grid).isEqualTo(created.grid)
    }

    @Test
    fun `a move that changes the board spawns one tile`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val moved = games.move(created.id, Direction.LEFT)

        // The merged 4 plus the spawned tile; where the new tile lands is random, its existence is not.
        assertThat(moved.grid.flatten().count { it != 0 }).isEqualTo(2)
    }
```

Třídu uzavři `}`; krok 4 před ni přidá další tři testy.

Proč je to deterministické: obě neprázdné řady jsou už sražené doleva a nemají žádné
stejné sousedy, takže `LEFT` nemůže nic posunout. S bugem `spawnRandom()` proběhne, deska
má 12 prázdných buněk, takže se dlaždice objeví vždy a mřížky se vždy liší. S opravou
neproběhne nic a mřížky jsou vždy stejné. Kam by dlaždice dopadla, je náhodné; jestli test
projde, náhodné není. Druhý test hlídá druhou stranu opravy: skutečný tah musí pořád
spawnout právě jednu dlaždici.

Před opravou `./gradlew :api:test` hlásí:

```text
GameServiceTest > a move that changes nothing leaves the grid unchanged() FAILED
    org.opentest4j.AssertionFailedError at GameServiceTest.kt:26
7 tests completed, 1 failed
```

> *„Teď oprav `GameService.move`: spawni dlaždici jen tehdy, když tah změnil desku. Spusť
> `./gradlew :api:test` a nahlas počty.“*

```kotlin
    fun move(id: UUID, direction: Direction): GameState {
        val board = boardFor(id)
        // Board is not thread-safe; two requests for the same game must not interleave.
        synchronized(board) {
            val changed = board.move(direction)

            // A move that slides nothing is not a turn, so it earns no new tile.
            if (changed) {
                board.spawnRandom()
            }

            return stateOf(id, board)
        }
    }
```

*Teď undo featura.*

1. **Vystopuj to.** *Mechanismus: `2048-dev:game-explorer`.* Vlož startovací prompt pro
   undo. Při běhu pro tento katalog (jako `copilot --agent 2048-dev:game-explorer -p "..."`)
   agent použil jen `glob`, `rg` a `view`, vrátil trasu o 14 krocích od `main.tsx:11` po
   `Board.tsx` a pak seznam po vrstvách. Podstatné části:

   - Engine: přidej do `Board` privátní historii; v `Board.move()` udělej před tahem snímek
     mřížky a skóre a ulož ho jen tehdy, když tah desku změní; přidej
     `Board.undo(): Boolean`. `slideLineLeft()` změnu nepotřebuje.
   - API: přidej `GameService.undo(id)` uvnitř stejného `synchronized(board)` jako `move` a
     `@PostMapping("/{id}/undo")` do `GameController`.
   - Web: přidej `undo(gameId)` do `api.ts`, rozpoznej `u` v `onKeyDown`, přidej tlačítko a
     nech undo použitelné i po `OVER`.

   Navrhl taky dvě věci, které kontrakt nežádá: pole `canUndo` ve stavu hry a 409 s kódem
   `NO_UNDO_HISTORY`, když není co vracet. Explorer mapuje; rozhoduješ ty. Tohle řešení
   `canUndo` vynechává a odpovídá 200 s nezměněnou hrou, protože „není co vracet“ je
   v kontraktu no-op, klient tak jako tak dostane aktuální stav a UI pak nepotřebuje žádný
   speciální případ.

2. **Nejdřív testy.** *Mechanismus: `board-test-writer`.*

   > *„Použij agenta board-test-writer: napiš testy pro novou `Board.undo(): Boolean`
   > v `BoardTest.kt`, dřív než funkce existuje. Chování: undo obnoví mřížku z doby před
   > posledním tahem; obnoví skóre; vrátí true, když vzalo zpět tah; na čerstvé desce
   > vrátí false a mřížku nechá beze změny; tah, který nic nezmění, vzít zpět nejde; undo
   > odstraní i dlaždici spawnutou po tahu; každé undo vezme zpět právě jeden tah. Jedno
   > chování na test. Na `Board.kt` nesahej a nepřidávej stub: místo toho nahlas chybu
   > kompilace.“*

   V Kotlinu je „červená“ u chybějící funkce chyba kompilace, ne padající assert:
   `Unresolved reference 'undo' on receiver of type 'Board'`. Dokud není hotový krok 3,
   hlásí navíc hook `agentStop` v repu po každém kole
   `run-tests hook: tests are failing in: gradle`. Hook je poradní a tohle je očekávaný stav.

   Testy, připojené na konec `BoardTest.kt`:

```kotlin
    // -----------------------------------------------------------------------
    // Undo.
    // -----------------------------------------------------------------------

    @Test
    fun `undo restores the grid from before the last move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)

        board.undo()

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `undo restores the score from before the last move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT) // +4

        board.undo()

        assertEquals(0, board.score)
    }

    @Test
    fun `undo reports true when it reverted a move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)

        assertTrue(board.undo())
    }

    @Test
    fun `undo on a fresh board reports false`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        assertFalse(board.undo())
    }

    @Test
    fun `undo on a fresh board leaves the grid unchanged`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        board.undo()

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `a move that changes nothing cannot be undone`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )
        board.move(Direction.LEFT)

        assertFalse(board.undo())
    }

    @Test
    fun `undo also removes the tile spawned after the move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)
        board.spawnRandom()

        board.undo()

        // Wherever the tile landed, the grid from before the move has no trace of it.
        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `each undo reverts exactly one move`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        board.move(Direction.LEFT)
        board.move(Direction.DOWN)

        board.undo()

        assertEquals(
            listOf(
                listOf(4, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }
```

   Test se `spawnRandom()` si přečti pozorně. Volá náhodnou funkci, a přesto je
   deterministický: ať dlaždice dopadne kamkoli, snímek z doby před tahem ji
   neobsahuje.

3. **Implementuj engine.** *Mechanismus: hlavní session.*

   > *„Zařiď, ať undo testy v `BoardTest.kt` projdou. V `Board.kt` drž privátní historii
   > snímků (mřížka a skóre). `move()` zaznamená stav z doby před tahem, a to jen tehdy,
   > když tah desku změnil. `undo()` obnoví poslední snímek a vrátí false, když žádný
   > není. Žádné I/O, žádné nové použití `Random`. Spusť `./gradlew :engine:test`
   > a nahlas počty.“*

   Změna v `Board.kt`, navíc k rozcvičce A:

```diff
--- a/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
+++ b/engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
@@ -61,4 +61,7 @@
     private val cells: Array<IntArray>
 
+    // One entry per move that changed the board: the grid and score from just before it.
+    private val history = ArrayDeque<Snapshot>()
+
     var score: Int = score
         private set
@@ -82,4 +85,5 @@
     fun move(direction: Direction): Boolean {
         val before = grid
+        val scoreBefore = score
         var gained = 0
 
@@ -133,5 +137,25 @@
 
         score += gained
-        return grid != before
+        val changed = grid != before
+        if (changed) {
+            history.addLast(Snapshot(before, scoreBefore))
+        }
+        return changed
+    }
+
+    /**
+     * Takes back the last move that changed the board: the grid and the score return to
+     * what they were just before it, so a tile spawned after that move disappears too.
+     * Returns false, and changes nothing, when there is no move to take back.
+     */
+    fun undo(): Boolean {
+        val previous = history.removeLastOrNull() ?: return false
+        for (row in 0 until SIZE) {
+            for (col in 0 until SIZE) {
+                cells[row][col] = previous.grid[row][col]
+            }
+        }
+        score = previous.score
+        return true
     }
 
@@ -181,4 +205,6 @@
     fun hasWon(): Boolean = cells.any { row -> row.any { it >= WIN_VALUE } }
 
+    private class Snapshot(val grid: List<List<Int>>, val score: Int)
+
     companion object {
         const val WIN_VALUE = 2048
```

   Proč má tenhle tvar. Snímek se pořizuje **před** tahem, takže předchází i
   `spawnRandom()`, který `GameService` volá potom; jedno undo odstraní sloučení i
   spawnutou dlaždici najednou. Tah, který nic nezmění, nic neuloží, takže undo nikdy
   „nevezme zpět“ tah, který se nestal. Historie je zásobník: každé undo odebere jeden tah
   a zásobník není omezený, což u dema, které už tak drží každou hru v paměti, nevadí
   (strop je snadné rozšíření, viz cvičení 6).

4. **API.** *Mechanismus: hlavní session.*

   > *„Přidej undo do API, nejdřív testy. V `GameServiceTest.kt`: undo obnoví mřížku a
   > skóre z doby před posledním tahem a undo na čerstvé hře vrátí hru beze změny.
   > V `GameControllerTest.kt`: `POST /api/v1/games/{id}/undo` odpoví 200 s obvyklou
   > obálkou a neznámá hra odpoví strukturovanou 404. Pak přidej `GameService.undo(id)`
   > a metodu controlleru. Když není co vracet, není to chyba. Spusť
   > `./gradlew :api:test`.“*

   Chování služby, připojené na konec `GameServiceTest.kt`:

```kotlin
    @Test
    fun `undo restores the grid from before the last move`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()
        games.move(created.id, Direction.LEFT)

        val undone = games.undo(created.id)

        assertThat(undone.grid).isEqualTo(created.grid)
    }

    @Test
    fun `undo restores the score from before the last move`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()
        games.move(created.id, Direction.LEFT) // +4

        val undone = games.undo(created.id)

        assertThat(undone.score).isEqualTo(0)
    }

    @Test
    fun `undo on a fresh game returns the game unchanged`() {
        val games = serviceStartingWith(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )
        val created = games.create()

        val undone = games.undo(created.id)

        assertThat(undone).isEqualTo(created)
    }
```

   HTTP mapování, připojené na konec `GameControllerTest.kt`:

```kotlin
    @Test
    fun `undo on a fresh game returns the game with its four rows`() {
        val id = createGameId()

        val result = mvc.post().uri("/api/v1/games/$id/undo")

        assertThat(result).hasStatusOk().bodyJson().extractingPath("$.data.grid.length()").isEqualTo(4)
    }

    @Test
    fun `undo in an unknown game returns a structured 404`() {
        val result = mvc.post().uri("/api/v1/games/${UUID.randomUUID()}/undo")

        assertThat(result)
            .hasStatus(HttpStatus.NOT_FOUND)
            .bodyJson()
            .extractingPath("$.error.code")
            .isEqualTo("GAME_NOT_FOUND")
    }
```

   Rozdělení je záměrné. Controller test pořád běží na náhodných deskách, takže ověřuje
   jen to, co platí pro každou desku: status, obálku, chybový kód. Všechno, co závisí na
   dlaždicích, se testuje přes šev z rozcvičky B.

   `GameService.kt`:

```kotlin
    fun undo(id: UUID): GameState {
        val board = boardFor(id)
        synchronized(board) {
            // Nothing to undo is not an error: the caller gets the unchanged game back.
            board.undo()
            return stateOf(id, board)
        }
    }
```

   `GameController.kt`:

```kotlin
    @PostMapping("/{id}/undo")
    fun undo(@PathVariable id: UUID): ApiResponse<GameState> = ApiResponse(games.undo(id))
```

   Controller zůstává jedním výrazem. Ani status nepotřebuje žádný kód: `stateOf()` ho
   přepočítá, takže undo tahu, který hru ukončil, ji vrátí do `IN_PROGRESS`.

5. **Webové UI.** *Mechanismus: hlavní session.*

   > *„Přidej undo do webového UI, nejdřív testy. `undo(gameId)` v `api.ts` pošle POST na
   > nový endpoint. `isUndoKey(key)` v `keys.ts` je true pro `u` bez ohledu na velikost
   > písmene. V `App.tsx` dělají undo klávesa `u` i nové tlačítko Undo a undo funguje i po
   > konci hry, zatímco tahy zůstávají blokované. Mapování kláves otestuj v `keys.test.ts`
   > a chování v novém `App.test.tsx`, který mockuje `./api`. Žádné `any`, pojmenované
   > exporty. Spusť `npm test`, `npm run lint` a `npm run build` ve `web/`.“*

   `web/src/api.ts`, připojeno na konec:

```ts
export function undo(gameId: string): Promise<Game> {
  return request<Game>(`/games/${encodeURIComponent(gameId)}/undo`, {
    method: 'POST',
  })
}
```

   `web/src/keys.ts`, připojeno na konec:

```ts
/** True for the key that takes back the last move: `u`, in either case. */
export function isUndoKey(key: string): boolean {
  return key.toLowerCase() === 'u'
}
```

   `web/src/keys.test.ts`: import se změní na
   `import { isUndoKey, toDirection } from './keys'` a na konec se připojí tenhle blok:

```ts
describe('isUndoKey', () => {
  it('recognises u as the undo key', () => {
    expect(isUndoKey('u')).toBe(true)
  })

  it('ignores the case of the undo key', () => {
    expect(isUndoKey('U')).toBe(true)
  })

  it('rejects a key that is not the undo key', () => {
    expect(isUndoKey('ArrowUp')).toBe(false)
  })
})
```

   `web/src/App.tsx`: importy se změní na `import { createGame, move, undo } from './api'`
   a `import { isUndoKey, toDirection } from './keys'`. Callback a efekt pro klávesy:

```tsx
  const undoLastMove = useCallback(() => {
    if (game === null) {
      return
    }
    undo(game.id)
      .then(setGame)
      .catch((cause: unknown) => setError(messageOf(cause)))
  }, [game])

  useEffect(() => {
    if (game === null) {
      return
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (isUndoKey(event.key)) {
        undoLastMove()
        return
      }
      const direction = toDirection(event.key)
      // A finished game takes no more moves, but its last move can still be undone.
      if (direction === null || game.status === 'OVER') {
        return
      }
      // Arrow keys would otherwise scroll the page.
      event.preventDefault()
      move(game.id, direction)
        .then(setGame)
        .catch((cause: unknown) => setError(messageOf(cause)))
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [game, undoLastMove])
```

   a tlačítko, umístěné v hlavičce před **New game**:

```tsx
        <button type="button" onClick={undoLastMove} disabled={game === null}>
          Undo
        </button>
```

   Dřív se listener u dohrané hry přeskakoval. Teď je připojený vždy, kontrola na undo
   je první a test na `OVER` se posunul níž, kde ovlivňuje jen tahy.

   `web/src/App.test.tsx` (nový soubor):

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move, undo } from './api'
import type { Game } from './api'
import { App } from './App'

// api.ts is this app's own wrapper around fetch, so the tests replace the wrapper, not fetch.
vi.mock('./api')

const CURRENT: Game = {
  id: 'game-1',
  grid: [
    [8, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 8,
  status: 'IN_PROGRESS',
}

const PREVIOUS: Game = {
  id: 'game-1',
  grid: [
    [4, 4, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App', () => {
  beforeEach(() => {
    vi.resetAllMocks()
    vi.mocked(createGame).mockResolvedValue(CURRENT)
    vi.mocked(undo).mockResolvedValue(PREVIOUS)
  })

  it('shows the previous board when Undo is clicked', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('8')

    await user.click(screen.getByRole('button', { name: 'Undo' }))

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('shows the previous board when u is pressed', async () => {
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('8')

    await user.keyboard('u')

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('still undoes with u after the game is over', async () => {
    vi.mocked(createGame).mockResolvedValue({ ...CURRENT, status: 'OVER' })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('Game over.')

    await user.keyboard('u')

    expect(await screen.findAllByText('4')).toHaveLength(2)
  })

  it('sends no move after the game is over', async () => {
    vi.mocked(createGame).mockResolvedValue({ ...CURRENT, status: 'OVER' })
    const user = userEvent.setup()
    render(<App />)
    await screen.findByText('Game over.')

    await user.keyboard('{ArrowLeft}')

    expect(move).not.toHaveBeenCalled()
  })
})
```

   `api.ts` je vlastní wrapper aplikace kolem `fetch`, takže test nahrazuje wrapper a
   `fetch` nechává být. Poslední test je regresní pojistka pro přestavěný listener:
   dokazuje, že přesun kontroly `OVER` neodblokoval tahy.

6. **Review.** *Mechanismus: `kotlin-reviewer`.*

   > *„Použij agenta kotlin-reviewer na review mých nezacommitovaných změn.“*

   Při běhu pro tento katalog nad diffem výše (jako
   `copilot --agent kotlin-reviewer -p "..." --allow-tool='shell(git:*)'`; v režimu `-p` je
   neschválené volání shellu zamítnuto, v session dostaneš dotaz) agent spustil `git status`,
   `git diff` po vrstvách a `git diff --check`, přečetl oba soubory `.instructions.md` a
   odpověděl:

   ```text
   **Blocker**
   - No blocking issues found.

   **Should-fix**
   - No should-fix issues found.

   **Nit**
   - No nit issues found.

   > No files modified — review only.
   ```

   Čisté review je jeden datový bod od jednoho modelu, ne důkaz. Diffu pořád musíš
   rozumět ty. Co stojí za to zkontrolovat vlastníma očima v čemkoli, co ti Copilot
   vygeneruje: snímek se pořizuje před tahem, a ne po spawnu; `undo()` obnovuje
   skóre; každý přístup k `Board` v `GameService` je uvnitř `synchronized(board)`;
   controller neobsahuje žádnou logiku; žádný test neověřuje, kam dopadla náhodná dlaždice.

**Hotovo.**

```bash
./gradlew build
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
cd web && npm test && npm run lint && npm run build
```

Očekávaný výsledek: `BUILD SUCCESSFUL`; `grep` hlásí `BoardTest` s `tests="22"`,
`GameServiceTest` s `tests="5"` a `GameControllerTest` s `tests="7"`, vše s
`failures="0"`; Vitest vypíše `Test Files  3 passed (3)` a `Tests  14 passed (14)`; ESLint
nevypíše nic; build končí na `✓ built in …`.

Pak proti běžícímu API (`./gradlew :api:bootRun` v jiném terminálu):

```bash
ID=$(curl -s -X POST localhost:8080/api/v1/games | jq -r .data.id)
curl -s -X POST localhost:8080/api/v1/games/$ID/undo | jq -c .data          # fresh game: unchanged, HTTP 200
curl -s -X POST -H 'Content-Type: application/json' -d '{"direction":"LEFT"}' \
  localhost:8080/api/v1/games/$ID/moves | jq -c .data
curl -s -X POST localhost:8080/api/v1/games/$ID/undo | jq -c .data          # the grid and score from before the move
curl -s -X POST localhost:8080/api/v1/games/00000000-0000-0000-0000-000000000000/undo
```

Poslední volání odpoví 404 s
`{"error":{"code":"GAME_NOT_FOUND","message":"Game 00000000-0000-0000-0000-000000000000 does not exist"}}`.
`kotlin-reviewer` nehlásí žádný blocker.

## 6. Plugin 🟡 — zabal undo workflow jako bundled skill

**Vrstvy:** žádné (konfigurace)

**Cíl.** Dej to, co tě cvičení 5 naučilo o undo, do pluginu `2048-dev` jako skill
`plugins/2048-dev/skills/undo/SKILL.md`: kde undo žije v každé vrstvě, pravidla, která musí
změna dodržet, a jak ho rozšířit. Kolega, který si plugin zapne, pak tu znalost dostane,
aniž by četl tvůj diff. Zvyš verzi pluginu z 1.0.0 na 1.1.0, zvaliduj manifest a ověř, že
se skill načte jako `2048-dev:undo`.

**Co učí.** Růst [pluginu](06-plugins.cs.md). Skill se najde podle umístění,
`skills/<name>/SKILL.md`; ve formátu Agent Plugins 1.0 manifest žádné komponenty
nevyjmenovává a schéma pole `skills` odmítne. Verze je to, co kolega s nainstalovanou kopií
uvidí v `copilot plugin list`; změnu si vyzvedne přes `copilot plugin update` (podle
dokumentace). Validace je kontrola proti JSON Schema, protože Copilot CLI nemá příkaz
`plugin validate` (podle dokumentace).

**Soubory.**

- `plugins/2048-dev/skills/undo/SKILL.md` (nový)
- `plugins/2048-dev/plugin.json` — `version`, `description`
- `marketplace.json` — `version` a `description` u položky pluginu

**Kontext na místě.**

- Plugin balí jeden skill, `plugins/2048-dev/skills/build-test/SKILL.md`, který se načítá
  pod jménem příkazu `2048-dev:build-test`. Prefix je `name` pluginu.
- Verze je zapsaná dvakrát: v `plugins/2048-dev/plugin.json` na řádku 5 a u položky pluginu
  v `marketplace.json` na řádku 14. `metadata.version` na řádku 8 v `marketplace.json` je
  verze samotného marketplace. Tu nech být.
- Tohle repo zapíná plugin přes `.github/copilot/settings.json` s adresářovým marketplace,
  takže se načítá z working tree. Podle dokumentace se úprava projeví po `/restart` nebo
  v nové session; nikdo tu nemusí nic přeinstalovávat.
- **Tohle cvičení navazuje na cvičení 5.** Skill popisuje kód, který existuje jen na tvé
  branchi ze cvičení 5, takže se odvětvi z ní, ne z `main`:
  `git switch -c ex6-plugin <your-exercise-5-branch>`. Bez té branche vezmi `SKILL.md`
  z walkthrough tak, jak je. Mechanika pluginu je stejná a skill pak poslouží jako plán,
  podle kterého undo postavíš.
- **Jména.** Podle dokumentace projektový skill tiše vyhraje nad skillem z pluginu se
  stejným `name`. Projektové skilly jsou tu `board-tests` a, pokud jsi dělal cvičení 2,
  `api-endpoint`. `undo` je volné. Vestavěný slash command `/undo` s tím nesouvisí: příkaz
  skillu nese prefix pluginu, `/2048-dev:undo`.

**Startovací prompt.**
> *„Přidej do pluginu 2048-dev skill v `plugins/2048-dev/skills/undo/SKILL.md` podle vzoru
> `plugins/2048-dev/skills/build-test/SKILL.md`. Dokumentuje undo featuru tak, jak je
> implementovaná teď, takže si nejdřív přečti `Board.kt`, `GameService.kt`,
> `GameController.kt`, `web/src/api.ts`, `web/src/keys.ts` a `web/src/App.tsx`. Sekce: kde
> undo žije v každé vrstvě, pravidla, která musí změna dodržet, jak ho rozšířit (redo, limit
> historie, zobrazení, jestli je undo možné), které testy přijdou první, jak to ověřit.
> Frontmatter: `name: undo` a `description`, který říká, kdy skill použít. Pak zvyš verzi
> pluginu z 1.0.0 na 1.1.0 v `plugins/2048-dev/plugin.json` a u položky pluginu
> v `marketplace.json` a v obou popisech zmiň nový skill. Do `plugin.json` nepřidávej žádné
> další pole.“*

**Walkthrough (kompletní řešení).**

> **Co se pro tento katalog spustilo.** Kroky 3 až 5, ve worktree, který obsahoval změnu
> pluginu, ale ne kód ze cvičení 5. Text skillu popisuje řešení cvičení 5.
> Žádný nástroj nezkontroluje skill proti kódu, který popisuje; tahle část je tvoje review.

1. **Napiš skill.** *Mechanismus: hlavní session.* `plugins/2048-dev/skills/undo/SKILL.md`:

````markdown
---
name: undo
description: Use when changing or extending the undo feature of the 2048 project (move history, the undo endpoint, the U key, the Undo button), or when adding a neighbouring feature such as redo or a history limit. Explains where undo lives in each layer and the rules a change must keep.
---

# Undo in the 2048 project

Undo takes back the last move that changed the board. It is one feature spread over three
layers, and each layer does exactly one thing.

## Where it lives

| Layer  | File                                                        | What it does                                                                                           |
| ------ | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| engine | `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`   | `move()` pushes a `Snapshot(grid, score)` onto `history` when the board changed; `undo()` pops it       |
| api    | `api/src/main/kotlin/com/quanti/g2048/api/GameService.kt`   | `undo(id)` calls `board.undo()` inside `synchronized(board)` and returns the game state                 |
| api    | `api/src/main/kotlin/com/quanti/g2048/api/GameController.kt` | `POST /api/v1/games/{id}/undo` answers `{ "data": GameState }`                                         |
| web    | `web/src/api.ts`                                            | `undo(gameId)` posts to the endpoint                                                                   |
| web    | `web/src/keys.ts`                                           | `isUndoKey(key)` is true for `u` in either case                                                        |
| web    | `web/src/App.tsx`                                           | `undoLastMove()` is called by the key listener and by the Undo button                                  |

If `Board.undo()` does not exist yet, build the feature in this order: engine, api, web.

## Rules a change must keep

1. History is game state, so it lives in `Board`. `GameService` never stores a grid.
2. The snapshot is taken **before** the move and kept only when the move changed the board.
   A move that slides nothing cannot be undone.
3. Because the snapshot predates `spawnRandom()`, one undo also removes the tile spawned
   after the move. Never snapshot after the spawn.
4. The score is restored together with the grid.
5. Nothing to undo is not an error. `Board.undo()` returns `false` and changes nothing; the
   API answers 200 with the unchanged game. An unknown game is still 404 `GAME_NOT_FOUND`.
6. Undo stays available after the game is over. The key listener in `App.tsx` must keep
   listening when the status is `OVER`; only moves are ignored then.
7. `GameService` touches a `Board` only inside `synchronized(board)`.

## Extending it

- **Redo.** Add a second deque to `Board`. `undo()` pushes the state it replaces onto it,
  `redo()` pops from it, and a `move()` that changes the board clears it. Then add
  `POST /api/v1/games/{id}/redo`, `redo(gameId)` in `api.ts` and a key in `keys.ts`.
- **History limit.** Add a constant next to `WIN_VALUE` and drop the oldest snapshot with
  `history.removeFirst()` when `move()` exceeds it.
- **Showing whether undo is possible.** Expose it from `Board`, add the field to `GameState`
  and to the `Game` type in `api.ts`, and disable the button with it.

## Tests come first

- Engine rules go in `BoardTest.kt`, built with `boardOf(...)`, one behaviour per test.
- What happens around a move goes in `GameServiceTest.kt`. `GameService { Board(rows) }`
  starts every game from a known grid, so the test does not depend on random tiles.
- The HTTP mapping (status, envelope, 404) goes in `GameControllerTest.kt`.
- Web: key mapping in `keys.test.ts`, the button and the key in `App.test.tsx`, which
  replaces `./api` with `vi.mock`.

## Verify

```bash
./gradlew build
cd web && npm test && npm run lint && npm run build
```

Report the pass and fail counts per suite.
````

   Dodávat ho se vyplatí kvůli prostřední sekci. Tabulku souborů jde znovu sestavit
   hledáním. Pravidla ne: každé je rozhodnutí ze cvičení 5, které kód ukáže jen tomu, kdo už
   ví, kam se dívat. Když má Copilotův návrh jen tabulku, řekni si o pravidla:

   > *„Přidej sekci ‚Rules a change must keep‘. U každého pravidla mi řekni, který test
   > v `BoardTest.kt`, `GameServiceTest.kt` nebo `App.test.tsx` by selhal, kdyby se porušilo,
   > nebo že žádný. Názvy testů do skillu nedávej.“*

   Dvě ze sedmi pravidel nemají test: kde žije historie a zamykání. Právě ta musí reviewer
   nosit v hlavě, což je nejlepší důvod je sepsat.

2. **Zvyš verzi v obou souborech.**

```diff
--- a/marketplace.json
+++ b/marketplace.json
@@ -12,4 +12,4 @@
       "name": "2048-dev",
-      "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
-      "version": "1.0.0",
+      "description": "Dev workflow skills (build-test, undo) and the game-explorer agent for the 2048 workshop project",
+      "version": "1.1.0",
       "source": "./plugins/2048-dev"
--- a/plugins/2048-dev/plugin.json
+++ b/plugins/2048-dev/plugin.json
@@ -3,4 +3,4 @@
   "name": "2048-dev",
-  "description": "Dev workflow skill (build-test) and the game-explorer agent for the 2048 workshop project",
-  "version": "1.0.0",
+  "description": "Dev workflow skills (build-test, undo) and the game-explorer agent for the 2048 workshop project",
+  "version": "1.1.0",
   "author": {
```

3. **Zvaliduj manifest.** Zdarma, bez volání modelu:

```bash
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

   Při spuštění tady příkaz nepotřebuje žádný flag navíc a vypíše:

```text
plugins/2048-dev/plugin.json valid
```

   Schéma fixuje `$schema` na URL verze 1.0.0, vyžaduje `name` a nastavuje
   `additionalProperties: false`. `version` je libovolný řetězec, takže zapomenutý bump
   schéma nezachytí; zachytí ho řádek s `jq` v kontrole hotovo. Chceš-li vidět, jak kontrola
   selže, přidej do `plugin.json` `"skills": "./skills"` a spusť ji znovu:

```text
plugins/2048-dev/plugin.json invalid
[
  {
    instancePath: '',
    schemaPath: '#/additionalProperties',
    keyword: 'additionalProperties',
    params: { additionalProperty: 'skills' },
    message: 'must NOT have additional properties'
  }
]
```

   Pole zase odstraň. Skill se najde podle složky, ne podle manifestu.

4. **Ověř, že se načte.** *Mechanismus: plugin loader.* Jedno volání modelu:

```bash
copilot -p "Reply with the single word ok. Do not call any tool." --trust-folder --no-ask-user --output-format json \
  | jq -c 'select(.type == "session.skills_loaded") | .data.skills[] | select(.source == "plugin") | {name, commandName}' \
  | sort -u
```

   Spuštěno tady:

```text
{"name":"build-test","commandName":"2048-dev:build-test"}
{"name":"undo","commandName":"2048-dev:undo"}
```

5. **Použij ho.** *Mechanismus: skill z pluginu.*

   > */2048-dev:undo Chci přidat redo. Nejvýš na šesti řádcích: kde žije historie undo
   > a která pravidla redo nesmí porušit? Neupravuj žádný soubor.*

   Při spuštění tady přes `copilot -p` udělala session jedno volání nástroje, `skill` s
   `{"skill":"undo"}`, a odpověděla ze skillu: historie žije v `Board`, redo je tamtéž druhá
   deque a nikdy ne v `GameService`, tah, který změní desku, ji vymaže, mřížka a skóre se
   obnovují společně a obojí zůstává dostupné i po `OVER`.

**Hotovo.**

```bash
jq -r '"\(.name) \(.version)"' plugins/2048-dev/plugin.json
jq -r '.plugins[] | "\(.name) \(.version)"' marketplace.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"
```

Očekávaný výsledek: dvakrát `2048-dev 1.1.0`, pak `plugins/2048-dev/plugin.json valid`.
Příkaz z kroku 4 vypíše `"commandName":"2048-dev:undo"`. Aplikační kód se nezměnil, takže
`./gradlew build` a webové kontroly jsou stejně zelené, jak je nechalo cvičení 5.

## 7. Orchestrace 🔴 — auto-solver vybraný porotou

**Vrstvy:** engine

**Cíl.** Přidej auto-solver čistě v enginu: abstrakci `Solver`, tři heuristiky (s preferencí
rohu, greedy podle skóre, monotonicita) a benchmark se seedem, který za každou heuristiku
odehraje N her a nahlásí průměrné skóre a nejlepší dlaždici. Tři heuristiky postav třemi
subagenty paralelně přes `/fleet` a pak nech porotu vybrat vítěze z čísel benchmarku a
z ničeho jiného.

**Co učí.** [Orchestraci](07-orchestration.cs.md): fan-out, join, porota. Tvar, díky kterému
to funguje, je v každém nástroji stejný. Nejdřív **kontrakt** napsaný jedním agentem, aby se
paralelní workeři nemohli rozejít. Pak **workeři, kteří vlastní disjunktní soubory**. Pak
**deterministické měření**, které nevytváří žádný model. Nakonec **porota, která vidí jen to
měření**. `/fleet` nechává rozdělení práce při každém běhu na modelu. Volitelná varianta
s [Conductorem](14-conductor.cs.md) rozdělení zafixuje v YAML souboru.

**Soubory.**

- `engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt` — kontrakt
- `…/solver/CornerSolver.kt`, `GreedySolver.kt`, `MonotonicSolver.kt` — jeden na subagenta
- `…/solver/Benchmark.kt` — `playGame`, `benchmark`
- `engine/src/test/kotlin/com/quanti/g2048/engine/solver/` — `SolverTest.kt`,
  `CornerSolverTest.kt`, `GreedySolverTest.kt`, `MonotonicSolverTest.kt`,
  `BenchmarkTest.kt`, `BenchmarkRunner.kt`
- `engine/build.gradle.kts` — task `benchmark`
- `conductor/solver-tournament.yaml` (volitelné)

**Kontext na místě.**

- **Determinismus už tam je.** Konstruktor `Board` bere `Random` a
  `Board.newGame(random)` ho předává dál. Hra spuštěná z `Random(seed)` je pokaždé stejná
  hra.
- **Solver musí tah zkusit, aniž by ho provedl.** `Board.move()` mutuje a `Board` nemá
  funkci pro kopii. Poslouží jeho veřejný konstruktor: `Board(board.grid, board.score)`.
  `grid` už vrací kopii, takže ty dvě desky nic nesdílejí. Kopie dostane výchozí
  `Random`, což tady nevadí, protože zkušební tah nikdy nespawnuje dlaždici: lookahead
  nic nelosuje, ani z generátoru kopie, ani ze seedovaného generátoru hry. Díky tomu
  zůstává benchmark reprodukovatelný.
- **Neukončuj herní smyčku podle `isGameOver()`.** Na `HEAD` je to bug ze cvičení 5
  a plnou, ale hratelnou desku hlásí jako konec hry. Hru ukonči, když žádný směr desku
  nezmění. Ten seznam legálních tahů solver stejně potřebuje.
- **Hlavní kód enginu nedělá žádné I/O** (`.github/copilot-instructions.md`: „pure game rules
  … No I/O, no Spring“). Logika benchmarku vrací čísla a žije v `main`; `println` žije
  v runneru v test source setu a spouští ho Gradle task.
- **Paralelní workeři sdílejí jeden working tree.** Kotlin kompiluje source set jako celek,
  takže napůl napsaný soubor jednoho subagenta shodí build jinému subagentovi. Workeři
  nesmí spouštět Gradle; orchestrátor sestaví jednou po joinu.

**Startovací prompt.** Kontrakt je první a není to paralelní práce:
> *„Vytvoř v modulu engine package `com.quanti.g2048.engine.solver` s jedním souborem,
> `Solver.kt`: interface `Solver` s `val name: String` a
> `fun chooseMove(board: Board): Direction?`, která vrátí null, když žádný směr desku
> nezmění, a nikdy ji neupraví; třídu `Outcome(direction, grid, gained)`; a top-level
> funkci `legalOutcomes(board): List<Outcome>`, která zkusí každý směr na kopii vytvořené
> přes `Board(board.grid, board.score)` a vrátí ty, které desku změní, v pořadí enumu.
> Přidej `SolverTest.kt` s jedním chováním na test. Žádné I/O, žádný `Random`. Spusť
> `./gradlew :engine:test`.“*

Pak fan-out:
> */fleet Postav paralelně tři 2048 solvery, každý jedním subagentem, v
> `engine/src/main/kotlin/com/quanti/g2048/engine/solver/`. Každý subagent si nejdřív přečte
> `Solver.kt`, vytvoří přesně dva soubory (svůj solver a jeho test) a na nic jiného nesáhne.
> (1) `CornerSolver`, name "corner": vybere outcome, jehož mřížka má nejvíc hodnoty dlaždic
> na buňkách nejblíž levému hornímu rohu, s váhami klesajícími po hadovité dráze.
> (2) `GreedySolver`, name "greedy": vybere outcome s nejvyšším `gained`; při shodě vyhrává
> první. (3) `MonotonicSolver`, name "monotonic": vybere outcome, jehož mřížka má nejvíc
> sousedních dvojic v pořadí, přičemž dvojice je v pořadí, když hodnota zleva doprava ani
> shora dolů neroste. Každý vrátí null, když neexistuje žádný legální outcome. Testy: JUnit
> Jupiter, názvy jako věty v backtickách, Arrange-Act-Assert, desky sestavené přes
> `Board(listOf(...))`. Subagenti nesmí spouštět Gradle, protože všichni tři zapisují ve
> stejnou chvíli do stejného source setu. Až budou všichni tři hotoví, spusť jednou sám
> `./gradlew :engine:test` a oprav, co selže.*

**Walkthrough (kompletní řešení).**

> **Co se pro tento katalog spustilo.** Kód byl sestaven a otestován v čistém worktree a
> každé číslo níže vypsal právě on. Samotný `/fleet` tu spuštěn **nebyl**; co o něm tohle
> cvičení říká, je podle dokumentace a `copilot help`. Varianta s Conductorem na konci
> spuštěna **byla**, jednou, od začátku do konce.

1. **Kontrakt.** *Mechanismus: hlavní session.* `Solver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction

/** A strategy that plays 2048 by picking the next move for a board. */
interface Solver {
    /** Short label used in benchmark output. */
    val name: String

    /** The move to play on [board], or null when no direction changes it. Never modifies [board]. */
    fun chooseMove(board: Board): Direction?
}

/** What one direction would do to a board: the grid it leads to and the score it gains. */
class Outcome(val direction: Direction, val grid: List<List<Int>>, val gained: Int)

/**
 * Tries every direction on a copy of [board] and returns the ones that change it, in the
 * order UP, DOWN, LEFT, RIGHT. The board passed in is never modified.
 */
fun legalOutcomes(board: Board): List<Outcome> =
    Direction.entries.mapNotNull { direction ->
        // Board has no copy function; its public constructor rebuilds one from grid and score.
        // The copy never spawns a tile, so the trial draws nothing from the game's Random.
        val copy = Board(board.grid, board.score)
        if (copy.move(direction)) {
            Outcome(direction, copy.grid, copy.score - board.score)
        } else {
            null
        }
    }
```

   `legalOutcomes` je kus, který všechny tři heuristiky sdílejí. S ním je heuristika jeden
   výraz a tři subagenti mají jen velmi málo prostoru se rozejít. `SolverTest.kt` jeho
   chování fixuje:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class SolverTest {

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `trying the moves leaves the board untouched`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        legalOutcomes(board)

        assertEquals(
            listOf(
                listOf(2, 2, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            board.grid,
        )
    }

    @Test
    fun `a direction that changes nothing is not a legal outcome`() {
        // The tiles already sit on the top edge, so UP is the one direction that moves nothing.
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val directions = legalOutcomes(board).map { it.direction }

        assertEquals(listOf(Direction.DOWN, Direction.LEFT, Direction.RIGHT), directions)
    }

    @Test
    fun `an outcome reports the score its move gains`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val left = legalOutcomes(board).first { it.direction == Direction.LEFT }

        assertEquals(4, left.gained)
    }

    @Test
    fun `an outcome carries the grid its move leads to`() {
        val board = boardOf(
            listOf(2, 2, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val left = legalOutcomes(board).first { it.direction == Direction.LEFT }

        assertEquals(
            listOf(
                listOf(4, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
                listOf(0, 0, 0, 0),
            ),
            left.grid,
        )
    }

    @Test
    fun `a locked board has no legal outcome`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertTrue(legalOutcomes(board).isEmpty())
    }
}
```

2. **Fan-out.** *Mechanismus: `/fleet`.* Vlož prompt s `/fleet`. Podle dokumentace se hlavní
   agent stane orchestrátorem, rozdělí práci na todo položky a ty nezávislé spustí jako
   paralelní subagenty, každého s vlastním kontextem; `/tasks` je zobrazí. Prompt dělá tři
   věci, díky kterým je fan-out bezpečný: jmenuje soubor, který každý worker vlastní, všechny
   odkazuje na kontrakt a build nechává až po joinu. Podle dokumentace lze vlastního agenta
   v promptu pro `/fleet` jmenovat jako `@agent-name`. Počítej s tím, že utratíš víc AI
   kreditů než v jedné session: každý subagent volá model sám za sebe.

   `GreedySolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction

/**
 * Greedy by score: plays the move that gains the most points right now. When several
 * moves gain the same, the first one in the order UP, DOWN, LEFT, RIGHT wins.
 */
class GreedySolver : Solver {
    override val name = "greedy"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { it.gained }?.direction
}
```

   `CornerSolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import com.quanti.g2048.engine.SIZE

/**
 * Corner-biased: plays the move that leaves the most tile value on the cells closest to
 * the top-left corner. The weights follow a snake from that corner, so the next-largest
 * tiles line up behind the largest one instead of scattering.
 */
class CornerSolver : Solver {
    override val name = "corner"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { cornerScore(it.grid) }?.direction

    private fun cornerScore(grid: List<List<Int>>): Int {
        var total = 0
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                total += grid[row][col] * WEIGHTS[row][col]
            }
        }
        return total
    }

    private companion object {
        val WEIGHTS = listOf(
            listOf(15, 14, 13, 12),
            listOf(8, 9, 10, 11),
            listOf(7, 6, 5, 4),
            listOf(0, 1, 2, 3),
        )
    }
}
```

   `MonotonicSolver.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import com.quanti.g2048.engine.SIZE

/**
 * Monotonicity: plays the move that leaves the most neighbouring pairs in order, counting
 * a pair as ordered when the value does not grow from left to right or from top to bottom.
 * Ordered lines keep equal tiles next to each other, which is what makes them mergeable.
 */
class MonotonicSolver : Solver {
    override val name = "monotonic"

    override fun chooseMove(board: Board): Direction? =
        legalOutcomes(board).maxByOrNull { orderedPairs(it.grid) }?.direction

    private fun orderedPairs(grid: List<List<Int>>): Int {
        var ordered = 0
        for (row in 0 until SIZE) {
            for (col in 0 until SIZE) {
                if (col + 1 < SIZE && grid[row][col] >= grid[row][col + 1]) {
                    ordered++
                }
                if (row + 1 < SIZE && grid[row][col] >= grid[row + 1][col]) {
                    ordered++
                }
            }
        }
        return ordered
    }
}
```

   `maxByOrNull` vrací první maximum a `legalOutcomes` má pevné pořadí, takže každá shoda se
   při každém běhu rozhodne stejně. Bez toho by benchmark nebyl reprodukovatelný.

   Tři testovací soubory. Každá deska je zvolená tak, aby byla správná právě jedna odpověď,
   a komentář říká proč:

   `GreedySolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class GreedySolverTest {

    private val solver = GreedySolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `takes the move that gains the most points`() {
        // LEFT and RIGHT merge the 8s (+16); UP and DOWN merge only the 2s (+4).
        val board = boardOf(
            listOf(8, 8, 0, 2),
            listOf(0, 0, 0, 2),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `breaks a tie with the first direction in enum order`() {
        // UP and LEFT change nothing; DOWN and RIGHT both gain 0, and DOWN comes first.
        val board = boardOf(
            listOf(2, 4, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.DOWN, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

   `CornerSolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class CornerSolverTest {

    private val solver = CornerSolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `moves the largest tile into the top-left corner`() {
        // UP puts the 64 on the corner cell (weight 15); DOWN and RIGHT land on weights 0 and 4.
        val board = boardOf(
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(64, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.UP, move)
    }

    @Test
    fun `does not pull the largest tile out of the corner`() {
        // UP changes nothing; DOWN and RIGHT move the 64 away; LEFT keeps it and packs the 2.
        val board = boardOf(
            listOf(64, 0, 2, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

   `MonotonicSolverTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import com.quanti.g2048.engine.Direction
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class MonotonicSolverTest {

    private val solver = MonotonicSolver()

    private fun boardOf(vararg rows: List<Int>): Board = Board(rows.toList())

    @Test
    fun `prefers the move that leaves every line in order`() {
        // LEFT gives 4, 2, 0, 0: no pair grows. DOWN and RIGHT each leave a pair that grows.
        val board = boardOf(
            listOf(0, 4, 0, 2),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
            listOf(0, 0, 0, 0),
        )

        val move = solver.chooseMove(board)

        assertEquals(Direction.LEFT, move)
    }

    @Test
    fun `returns null when no move changes the board`() {
        val board = boardOf(
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
            listOf(2, 4, 2, 4),
            listOf(4, 2, 4, 2),
        )

        assertNull(solver.chooseMove(board))
    }
}
```

3. **Benchmark.** *Mechanismus: hlavní session.*

   > *„Přidej do package solveru `Benchmark.kt`. `playGame(solver, random): Board` spustí
   > `Board.newGame(random)` a hraje, dokud solver nevrátí null; nesmí použít
   > `isGameOver()`. `benchmark(solver, games, seed): BenchmarkResult` seeduje hru n přes
   > `Random(seed + n)` a vrátí jméno solveru, počet her, průměrné skóre a nejlepší
   > dlaždici. V main kódu se nic nevypisuje. Přidej `BenchmarkTest.kt`. `main`, který vypíše
   > jeden řádek na solver, dej do `BenchmarkRunner.kt` ve stejném package v test source
   > setu a v `engine/build.gradle.kts` zaregistruj `JavaExec` task `benchmark`, který ho
   > spustí na test runtime classpath, s `-Pgames` (default 1000) a `-Pseed`
   > (default 2048).“*

   `Benchmark.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import com.quanti.g2048.engine.Board
import kotlin.random.Random

data class BenchmarkResult(
    val solver: String,
    val games: Int,
    val averageScore: Double,
    val bestTile: Int,
)

/**
 * Plays one game to the end and returns the final board. The game ends when the solver
 * finds no move that changes the board, so the loop does not depend on Board.isGameOver().
 */
fun playGame(solver: Solver, random: Random): Board {
    val board = Board.newGame(random)
    while (true) {
        val direction = solver.chooseMove(board) ?: return board
        board.move(direction)
        board.spawnRandom()
    }
}

/**
 * Plays [games] games with [solver] and summarises them. Game number n is seeded with
 * `seed + n`, so every solver starts game n from the same two tiles and a run with the
 * same arguments always returns the same numbers.
 */
fun benchmark(solver: Solver, games: Int, seed: Long): BenchmarkResult {
    require(games > 0) { "games must be positive" }

    var totalScore = 0L
    var bestTile = 0
    for (game in 0 until games) {
        val board = playGame(solver, Random(seed + game))
        totalScore += board.score
        bestTile = maxOf(bestTile, board.grid.flatten().max())
    }
    return BenchmarkResult(solver.name, games, totalScore.toDouble() / games, bestTile)
}
```

   Jeden seed na hru, ne jeden generátor na celý běh: každý solver pak začíná hru n ze
   stejných dvou dlaždic a losování navíc u pomalého solveru nemůže posunout hry po něm.

   `BenchmarkTest.kt`:

```kotlin
package com.quanti.g2048.engine.solver

import kotlin.random.Random
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class BenchmarkTest {

    @Test
    fun `a game is played until no move changes the board`() {
        val board = playGame(GreedySolver(), Random(1))

        assertTrue(legalOutcomes(board).isEmpty())
    }

    @Test
    fun `the same seed gives the same result`() {
        val first = benchmark(GreedySolver(), games = 3, seed = 42)

        val second = benchmark(GreedySolver(), games = 3, seed = 42)

        assertEquals(first, second)
    }

    @Test
    fun `a different seed gives a different result`() {
        val first = benchmark(GreedySolver(), games = 3, seed = 42)

        val second = benchmark(GreedySolver(), games = 3, seed = 43)

        assertNotEquals(first.averageScore, second.averageScore)
    }

    @Test
    fun `the result names the solver it measured`() {
        val result = benchmark(CornerSolver(), games = 1, seed = 42)

        assertEquals("corner", result.solver)
    }

    @Test
    fun `zero games are rejected`() {
        assertThrows(IllegalArgumentException::class.java) {
            benchmark(GreedySolver(), games = 0, seed = 42)
        }
    }
}
```

   `BenchmarkRunner.kt` (test source set):

```kotlin
package com.quanti.g2048.engine.solver

import java.util.Locale

/**
 * Prints the benchmark table: `./gradlew -q :engine:benchmark [-Pgames=50] [-Pseed=7]`.
 * It lives in the test source set because engine main code performs no I/O.
 */
fun main(args: Array<String>) {
    val games = args.getOrNull(0)?.toInt() ?: 1000
    val seed = args.getOrNull(1)?.toLong() ?: 2048L
    val solvers = listOf(CornerSolver(), GreedySolver(), MonotonicSolver())

    println("solver      games  avg score  best tile   (seed $seed)")
    for (solver in solvers) {
        val result = benchmark(solver, games, seed)
        // Locale.ROOT keeps the decimal point a point on every machine.
        println(
            String.format(
                Locale.ROOT,
                "%-10s %6d %10.1f %10d",
                result.solver,
                result.games,
                result.averageScore,
                result.bestTile,
            ),
        )
    }
}
```

   `engine/build.gradle.kts`, přidáno na konec:

```kotlin
// Prints one line per solver: ./gradlew -q :engine:benchmark [-Pgames=50] [-Pseed=7]
tasks.register<JavaExec>("benchmark") {
    group = "verification"
    description = "Plays seeded games with every solver and prints average score and best tile."
    classpath = sourceSets["test"].runtimeClasspath
    mainClass = "com.quanti.g2048.engine.solver.BenchmarkRunnerKt"
    args(
        providers.gradleProperty("games").getOrElse("1000"),
        providers.gradleProperty("seed").getOrElse("2048"),
    )
}
```

4. **Porota.** *Mechanismus: hlavní session jako porota, nad čísly, která vypsal příkaz.*

   > *„Spusť `./gradlew -q :engine:benchmark`. Chovej se jako porota: seřaď solvery podle
   > průměrného skóre, shodu rozhodni nejlepší dlaždicí, jmenuj vítěze a zdůvodni to jednou
   > větou. Použij jen čísla, která příkaz vypsal. Neměň žádný soubor.“*

   Příkaz, spuštěný tady na `HEAD` (třikrát 1000 her za méně než dvě sekundy, při každém
   běhu stejný výstup):

```text
solver      games  avg score  best tile   (seed 2048)
corner       1000     2243.8        512
greedy       1000     2394.8        512
monotonic    1000     3047.5        512
```

   Vítězem je `monotonic`. Porota nemá v čem být kreativní a její verdikt zkontroluješ
   pohledem. Tak je to navržené: model orchestruje a vysvětluje, rozhoduje benchmark.

   Dvě věci, které čísla učí, obě změřené tady:

   | Běh | corner | greedy | monotonic |
   |---|---|---|---|
   | `-Pgames=50` | 2515.6 | 2170.0 | 2920.2 |
   | default (1000 her) | 2243.8 | 2394.8 | 3047.5 |
   | 1000 her, opravený cascade-merge bug | 2262.3 | 3000.0 | 3037.4 |
   | 50 her, opravený cascade-merge bug | 2340.1 | 3113.3 | 3091.2 |

   - **Velikost vzorku.** Při 50 hrách `corner` poráží `greedy`; při 1000 je to naopak.
     Porota, která dostane tabulku z 50 her, je seřadí špatně a není to její vina.
   - **Verdikt závisí na pravidlech.** Pokud jsi opravil cascade-merge bug
     (`4, 4, 8, 0` musí dát `8, 8, 0, 0`), `greedy` přestane těžit z dvojitých merge,
     které nemají existovat, a skončí zhruba 1 % od `monotonic`; při 50 hrách dokonce
     vyhraje. Po každé změně pravidel pusť benchmark znovu a řekni porotě, co má dělat
     s téměř shodným výsledkem.

   Žádná heuristika se na `HEAD` nedostane přes 512. Kdo se dívá jen jeden tah dopředu, je
   slabý hráč. Solver, který hledá hlouběji, se vejde za stejné rozhraní a do stejného
   benchmarku.

5. **Volitelně: stejný flow jako Conductor workflow.** `/fleet` rozhoduje o rozdělení při
   každém běhu znovu. [Conductor](14-conductor.cs.md) ho zapíše. Soubor níže je podle vzoru
   `conductor/test-coverage-audit.yaml`: paralelní skupina, pak join. Novým prvkem je krok
   `type: script`, který benchmark sám spustí a stdout předá porotě, takže mezi příkazem a
   verdiktem nestojí žádný agent. Ulož ho jako
   `conductor/solver-tournament.yaml`:

```yaml
# Solver tournament as a Conductor workflow.
#
# Three agents write one solver each at the same time, a script step runs the
# seeded benchmark, and a judge with no tools ranks the numbers. The benchmark is
# a plain command, so the table the judge reads was not produced by a model.
#
#   conductor validate conductor/solver-tournament.yaml
#   conductor run conductor/solver-tournament.yaml
#
# Run from the repository root, after the shared pieces exist: Solver.kt,
# Benchmark.kt, BenchmarkRunner.kt and the `benchmark` Gradle task.

workflow:
  name: solver-tournament
  description: Build three 2048 solvers in parallel, benchmark them, let a judge pick the winner
  version: "1.0.0"
  entry_point: solver_builders

  runtime:
    provider: copilot
    # Let Copilot pick from the models your organization allows.
    default_model: auto

  context:
    mode: explicit

  limits:
    max_iterations: 10
    timeout_seconds: 1800

# There is no top-level `tools:` list on purpose. Without one, an agent that names
# no tools gets the provider's default set, which is what lets the builders create
# files. The judge opts out of all tools with `tools: []`.

parallel:
  - name: solver_builders
    description: One solver and its test file per agent, written at the same time
    agents:
      - corner_builder
      - greedy_builder
      - monotonic_builder
    # A missing solver would break the benchmark's compile step, so stop early.
    failure_mode: fail_fast
    routes:
      - to: benchmark

agents:
  - name: corner_builder
    description: Writes the corner-biased solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/CornerSolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/CornerSolverTest.kt

      `class CornerSolver : Solver`, with `name = "corner"`. From `legalOutcomes(board)` it
      picks the outcome whose grid has the most tile value on the cells nearest the top-left
      corner (weight each cell, largest weight in the corner, weights falling along a snake).
      It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  - name: greedy_builder
    description: Writes the greedy-by-score solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/GreedySolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/GreedySolverTest.kt

      `class GreedySolver : Solver`, with `name = "greedy"`. From `legalOutcomes(board)` it
      picks the outcome with the highest `gained`; on a tie the first outcome in the list
      wins. It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  - name: monotonic_builder
    description: Writes the monotonicity solver and its tests
    prompt: |
      Read engine/src/main/kotlin/com/quanti/g2048/engine/solver/Solver.kt first.

      Create exactly two files and touch nothing else:
      - engine/src/main/kotlin/com/quanti/g2048/engine/solver/MonotonicSolver.kt
      - engine/src/test/kotlin/com/quanti/g2048/engine/solver/MonotonicSolverTest.kt

      `class MonotonicSolver : Solver`, with `name = "monotonic"`. From `legalOutcomes(board)`
      it picks the outcome whose grid has the most neighbouring pairs in order, a pair being
      in order when the value does not grow from left to right or from top to bottom.
      It returns null when there is no legal outcome.

      Tests: JUnit Jupiter, one behaviour per test, backtick sentence names,
      Arrange-Act-Assert, boards built with `Board(listOf(...))` so nothing is random.

      Do not run Gradle: two other agents are writing files in the same source set right
      now and a half-written file of theirs would fail your compile.
    output:
      files:
        type: array
        description: Paths of the files you created

  # Not an agent: Conductor runs the command itself and stores stdout, stderr and
  # exit_code as this step's output. Compiling here is also the first build of the
  # three new solvers together.
  - name: benchmark
    type: script
    description: Compiles the engine and prints the seeded benchmark table
    command: ./gradlew
    args: ["-q", ":engine:benchmark"]
    timeout: 600
    routes:
      - to: judge

  - name: judge
    description: Ranks the solvers from the benchmark table alone
    tools: []
    input:
      - benchmark.output
    prompt: |
      A seeded benchmark played the same games with each 2048 solver. Its output
      (exit code {{ benchmark.output.exit_code }}) is:

      {{ benchmark.output.stdout }}

      Rank the solvers by average score, highest first. Break a tie with the best tile.
      Use only the numbers above. If the text is not a table with one row per solver,
      set winner to "none" and quote the first error line as the reason.
    output:
      winner:
        type: string
        description: Name of the best solver, or "none"
      ranking:
        type: string
        description: Markdown table - rank, solver, average score, best tile
      reason:
        type: string
        description: One sentence on why the winner won
    routes:
      - to: $end

output:
  winner: "{{ judge.output.winner }}"
  ranking: "{{ judge.output.ranking }}"
  reason: "{{ judge.output.reason }}"
```

```bash
export PATH="$HOME/.local/bin:$PATH"
conductor validate conductor/solver-tournament.yaml
conductor --silent run conductor/solver-tournament.yaml
```

   **Zvalidováno a spuštěno** pro tento katalog (Conductor v0.1.47, provider Copilot),
   jednou, ve worktree, který obsahoval kroky 1 a 3, ale žádný ze tří souborů solverů.
   `validate` vypsal `Validation Successful` s 5 agenty a 1 paralelní skupinou. `run` zapsal
   těch šest souborů, spustil benchmark a vrátil:

```json
{
  "winner": "monotonic",
  "ranking": "| Rank | Solver | Average score | Best tile |\n|---:|---|---:|---:|\n| 1 | monotonic | 3047.5 | 512 |\n| 2 | greedy | 2394.8 | 512 |\n| 3 | corner | 2243.8 | 512 |",
  "reason": "monotonic won with the highest average score of 3047.5."
}
```

   Potom byl `./gradlew build` v tom worktree zelený s 38 testy; tři agenti napsali
   10 testů solverů, kde referenční řešení má 8. Čísla se rovnají referenčním, přestože
   vygenerovaný `CornerSolver` používá váhy 16 až 1 místo 15 až 0: tah nikdy nezmění součet
   dlaždic, takže přičtení konstanty ke každé váze nemůže změnit, který tah vyhraje. Jeden
   běh dokazuje, že soubor funguje, ne že funguje pokaždé. Spouštěj ho ve worktree nebo na
   branchi: Conductor schvaluje zápisy agentů do souborů za tebe.

**Hotovo.**

```bash
./gradlew build
grep -ho '<testsuite name="[^"]*" tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' \
  engine/build/test-results/test/*.xml api/build/test-results/test/*.xml
./gradlew -q :engine:benchmark
./gradlew -q :engine:benchmark -Pgames=50 -Pseed=7
```

Očekávaný výsledek: `BUILD SUCCESSFUL`; vedle `BoardTest` a `GameControllerTest` hlásí `grep`
pět nových sad, všechny s `failures="0"`: `SolverTest` s `tests="5"`, `GreedySolverTest` 3,
`CornerSolverTest` 3, `MonotonicSolverTest` 2 a `BenchmarkTest` 5; benchmark vypíše jeden
řádek na solver a dvě spuštění po sobě vypíšou stejná čísla. Na čistém `HEAD`, a stejně tak
nad řešením cvičení 5, odpovídá výchozí běh tabulce z kroku 4. Tvoje průměry se liší, pokud
jsi opravil bug v pravidlech nebo napsal heuristiky jinak; nesmí se lišit mezi dvěma tvými
běhy. Porota jmenuje solver s nejvyšším průměrem.

## 8. Eval 🟡 — dokaž, že skill pomáhá

**Vrstvy:** žádné (konfigurace)

**Cíl.** Napiš eval pro skill, který jsi vytvořil, tady pro skill `api-endpoint` ze
cvičení 2 (referenční verze, která je tam otištěná): spec s pozitivním a negativním
stimulem a deterministickými gradery a experiment, který pustí stejný spec se skillem a bez
něj. Prožeň ho lintem, pusť dry run, spusť ho a přečti report, aniž bys z něj vyčetl víc,
než v něm je.

**Co učí.** [Evaly](09-validate-eval.cs.md) s Vally. Trial je skutečná Copilot session
v jednorázovém workspace, který obsahuje soubory, které do něj nachystáš, a ve variantě,
která ho má, i skill. Gradery pak zkoumají workspace a proud událostí. Experiment pustí spec
znovu, jednou za každou variantu, a mění právě jednu věc, tady `/environment/skills`.
Všechno ostatní zůstává stejné, takže rozdíl mezi variantami lze připsat skillu.

**Soubory.**

- `evals/api-endpoint/eval.yaml` (nový)
- `evals/experiments/api-endpoint-ab.experiment.yaml` (nový)
- `.github/skills/api-endpoint/SKILL.md` — ze cvičení 2, beze změny

**Kontext na místě.**

- `evals/board-tests/eval.yaml` a `evals/experiments/board-tests-ab.experiment.yaml`
  prokazatelně fungují. Zkopíruj jejich tvar: `agent_environment` se `skills` a `files`,
  stimuly s `graders`, `scoring.threshold: 1` a `matrix` nad `/environment/skills`
  s deklarovaným `baseline`.
- **Chystej jen zdrojový kód aplikace.** Žádné `.github/`: instrukce repozitáře už říkají
  „Spring Boot 4, use `MockMvcTester`“ a s nimi ve workspace by baseline věděl to, co má
  naučit až skill. Ze stejného důvodu chybí existující `GameControllerTest.kt`. Skill musí
  být jediné místo, odkud konvence můžou přijít.
- **Dostaň skill na čistou branch.** Žije na tvé branchi ze cvičení 2. Začni z `main` a
  zkopíruj jen složku skillu:
  `git checkout <your-exercise-2-branch> -- .github/skills/api-endpoint`. Eval nepouštěj
  přímo na branchi ze cvičení 2: spec chystá `GameController.kt` a `GameService.kt`
  z working tree a tam už obsahují featuru s výherní hodnotou. Nemáš branch ze cvičení 2?
  Vytvoř soubor z referenčního bloku ve cvičení 2.
- **Grader může kontrolovat jen to, co skill říká.** Projdi `SKILL.md` a napiš jeden
  grader na každou konvenci. Každý grader ve specu níže má v referenčním skillu svůj řádek:

  | Grader kontroluje | Kde to referenční skill říká |
  |---|---|
  | `@DeleteMapping("/{id}")` v `GameController.kt` | Contract: zdroje pod `/api/v1`, podstatná jména v množném čísle, žádná slovesa |
  | `NO_CONTENT` nebo `noContent()` | Contract: „A delete answers 204 with no body“ |
  | `boards.remove(` v `GameService.kt` | Kroky 2 a 5: práci dělá metoda service, controller na ni mapuje HTTP |
  | `GameControllerTest.kt` existuje | Krok 6: testy žijí v `api/src/test/kotlin/com/quanti/g2048/api/<Controller>Test.kt` |
  | `MockMvcTester` v tom souboru | Krok 6 a „Boot 4, not Boot 3“ |
  | název testu v backtickách | Krok 6: „a plain-English sentence in backticks“ |
  | `GAME_NOT_FOUND` v tom souboru | Krok 6: jeden test na každý chybový případ; tvar ke zkopírování |

  Grader na něco, co skill nikdy nezmiňuje, měří model, ne skill. Pokud tvůj vlastní skill
  některou z těch věcí vynechává, jako to dřívější verze referenčního skillu dělala s 204,
  cestou k testu a názvy testů, rozšiř skill, nebo grader zahoď.
- `package.json` připíná `@microsoft/vally-cli`; `npm ci` v kořeni repozitáře ho nainstaluje.
  `EVALUATE_USE_HOST_COPILOT_HOME=1` znovu použije tvoje přihlášení do Copilota,
  `VALLY_TELEMETRY_OPTOUT=1` vypne telemetrii Vally.

**Startovací prompt.**
> *„Napiš Vally eval pro skill `api-endpoint` v `.github/skills/api-endpoint/` podle vzoru
> `evals/board-tests/eval.yaml`. Nejdřív si skill přečti a napiš jeden deterministický
> grader na každou konvenci, kterou uvádí. Nachystej jen zdrojový kód aplikace: tři soubory
> v `api/src/main/kotlin/com/quanti/g2048/api/`, `api/build.gradle.kts` a
> `engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`. Žádné `.github/` a žádný
> existující test. Pozitivní stimulus: ‚Add a REST endpoint that deletes a game, with its
> tests‘, bez jmenování skillu, a řekni v něm, že workspace nemá žádný build nástroj.
> Negativní stimulus: krátká otázka na `Board.spawnRandom`, která nesmí skill vyvolat a musí
> nechat diff prázdný. Použij `runs: 1` a `scoring.threshold: 1`. Pak napiš
> `evals/experiments/api-endpoint-ab.experiment.yaml` podle vzoru
> `board-tests-ab.experiment.yaml`, s variantami `without` a `with` a s `without` jako
> baseline. Spusť `npm run eval:lint` a nahlas jeho výstup. Eval nespouštěj.“*

**Walkthrough (kompletní řešení).**

> **Co se pro tento katalog spustilo.** Všechno níže: lint, dry run a jeden skutečný běh
> experimentu s `runs: 1` (čtyři session), v čistém worktree, který obsahoval referenční
> skill přesně tak, jak ho otiskuje cvičení 2, a dva soubory tohoto cvičení. S jinak
> formulovaným skillem se tvoje čísla budou lišit.

1. **Zkontroluj skill proti tabulce.** *Mechanismus: ty.* Otevři
   `.github/skills/api-endpoint/SKILL.md` vedle tabulky v kontextu na místě a ke každému
   graderu najdi větu, o kterou se opírá. Tři z nich jsou jednotlivé řádky, které se snadno
   ztratí, když Copilot skill přepisuje: 204 pro delete, cesta k testovacímu souboru a
   názvy testů v backtickách. Pokud některý chybí, vrať ho, než začneš cokoli měřit.

2. **Napiš spec.** *Mechanismus: hlavní session.* `evals/api-endpoint/eval.yaml`:

```yaml
name: api-endpoint
description: Does the api-endpoint skill make Copilot add an endpoint the way this project does?
type: capability
defaults:
  executor: copilot-sdk
  # One trial per stimulus keeps a first run cheap. Raise it to 3 or more before
  # you read anything into a difference between the variants.
  runs: 1
  timeout: 5m
# Only application source is staged. No .github/ and no existing controller test,
# so the skill under test is the only place the conventions can come from.
agent_environment:
  skills:
    - ../../.github/skills/api-endpoint
  files:
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
    - src: ../../api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
      dest: api/src/main/kotlin/com/quanti/g2048/api/ApiExceptionHandler.kt
    - src: ../../api/build.gradle.kts
      dest: api/build.gradle.kts
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
stimuli:
  - name: delete-game-endpoint
    prompt: >-
      Add a REST endpoint that deletes a game, with its tests. Follow this project's API
      conventions. This workspace has no build tool, so do not try to compile or run anything.
    tags:
      control: positive
      suite: smoke
    graders:
      - type: completed
      # The route follows the resource: DELETE on the game itself.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
          pattern: '@DeleteMapping\("/\{id\}"\)'
      # A delete answers 204.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameController.kt
          pattern: 'NO_CONTENT|noContent\(\)'
      # The controller stays thin: the service owns the storage.
      - type: file-matches
        config:
          path: api/src/main/kotlin/com/quanti/g2048/api/GameService.kt
          pattern: 'boards\.remove\('
      # The endpoint ships with a controller test, where the project keeps them.
      - type: file-exists
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
      # Spring Boot 4 test stack.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'MockMvcTester'
      # Test name is a plain-English sentence in backticks.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'fun `[^`]+`\(\)'
      # The unknown-game case is tested against the structured error code.
      - type: file-matches
        config:
          path: api/src/test/kotlin/com/quanti/g2048/api/GameControllerTest.kt
          pattern: 'GAME_NOT_FOUND'
  - name: unrelated-question
    prompt: >-
      In two sentences, what does Board.spawnRandom return and when does it return false?
      Answer in chat only; do not create or change any file.
    tags:
      control: negative
      suite: smoke
    graders:
      - type: completed
      # A skill that fires on everything costs context for nothing.
      - type: skill-invocation
        config:
          disallowed: [api-endpoint]
      - type: output-matches
        config:
          pattern: '(?i)full|empty'
      - type: diff-empty
scoring:
  threshold: 1
```

   Čteno očima reviewera:

   - Pozitivní prompt říká to, co by řekl uživatel. Nejmenuje skill a nevyjmenovává
     konvence; „follow this project's API conventions“ je veškerá pomoc, kterou baseline
     dostane.
   - „No build tool“ tam je proto, že je nachystaný jen zdrojový kód. Bez té věty agent
     utratí svoje kola hledáním Gradle wrapperu.
   - Vzory jsou volné tam, kde existují dvě správné odpovědi (`NO_CONTENT|noContent\(\)`),
     a přísné tam, kde jde právě o konvenci (`MockMvcTester`).
   - Negativní kontrola hlídá description. Skill, který se načte na každou otázku o kódu,
     projde pozitivním případem, a přesto stojí kontext v každém kole.
   - `threshold: 1` znamená, že projít musí každý grader. Jedna minutá konvence shodí trial.

3. **Napiš experiment.** `evals/experiments/api-endpoint-ab.experiment.yaml`:

```yaml
name: api-endpoint-ab
evals:
  - ../api-endpoint/eval.yaml
matrix:
  skills:
    path: /environment/skills
    values:
      - without: []
      - with: ["../../.github/skills/api-endpoint"]
baseline:
  skills: without
```

   Cesty ve `values` jsou relativní k souboru experimentu. `without: []` nahradí seznam
   `skills` ze specu prázdným; `with` vrátí skill zpět.

4. **Lint a dry run.** *Mechanismus: Vally, bez volání modelu.*

```bash
npm ci                                   # once, at the repository root
npm run eval:lint
npx --no vally lint .github/skills/api-endpoint
VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml \
  --output-dir evals/results --dry-run
```

   Spuštěno tady:

```text
✔ evals/api-endpoint/eval.yaml is valid
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid

✅ api-endpoint (2/2 checks passed)
1 skill(s) linted, 1 passed

Experiment: api-endpoint-ab
Baseline:   skills=without
Plans:      2

── skills=without (baseline) ──
  Eval:        api-endpoint
  File:        ../api-endpoint/eval.yaml
  Model:       (unset)
  Config hash: 37dca6240065c336
  Eval hash:   76334ef3a03ae1a5

── skills=with ──
  Eval:        api-endpoint
  File:        ../api-endpoint/eval.yaml
  Model:       (unset)
  Config hash: 422626e8c5067705
  Eval hash:   76334ef3a03ae1a5
```

   Dva plány, stejný hash evalu, různé hashe konfigurace: varianty se liší prostředím
   a ničím jiným. Nečekej na svém stroji přesně tyhle hodnoty hashů.

5. **Spusť to.** *Mechanismus: Vally, čtyři skutečné session (2 varianty × 2 stimuly × `runs: 1`).*

```bash
VALLY_TELEMETRY_OPTOUT=1 EVALUATE_USE_HOST_COPILOT_HOME=1 \
  npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml --output-dir evals/results
```

   Spuštěno tady, jednou (Copilot CLI 1.0.114, Vally 0.21.0, model zvolený přes `auto`;
   výstup konzole zkrácen):

```text
skills=without
  FAIL  delete-game-endpoint · 7/8 graders · 47.3s
   ✘ file-matches api/src/test/… /MockMvcTester/  Pattern /MockMvcTester/ not found in any file
   · score 87.5% < threshold 100.0% · trial 1

  → skills=with beat baseline — 2/2 vs 1/2 stimuli.
    skills=with used +1% tokens, +17% trial time.

  eval          skills=without (baseline)   skills=with                Δ
  api-endpoint  ✘ 1/2 (score 93.8% < 100%)  ✓ 2/2 (score 100% ≥ 100%)  +1
  stimuli       1/2                         2/2                        +1
  tokens        168.8k                      170.9k                     +1%
  trial time    1m07s                       1m18s                      +17%
```

   Po jednotlivých trialech, z `report.md`:

   | Stimulus | `skills=without` (baseline) | `skills=with` |
   |---|---|---|
   | `delete-game-endpoint` | ✘ 7/8 graderů · 47.3s · 117,321 tokenů · 13 volání nástrojů | ✓ 8/8 graderů · 1m 01s · 119,197 tokenů · 14 volání nástrojů |
   | `unrelated-question` | ✓ 4/4 graderů · 18.7s · 51,450 tokenů · 2 volání nástrojů | ✓ 4/4 graderů · 15.9s · 51,667 tokenů · 3 volání nástrojů |

6. **Přečti report.** *Mechanismus: ty.* `evals/results/<timestamp>/report.md` má jednu
   tabulku na variantu. Každá složka trialu obsahuje `events.jsonl` (co agent dělal) a
   `workspace.patch` (co napsal). Co tenhle běh říká a co ne:

   - **Pozitivní případ.** Se skillem prošlo všech 8 graderů. Bez něj prošlo 7 z 8.
     Baseline přitom napsal test controlleru na správné cestě, s názvy v backtickách a
     s případem `GAME_NOT_FOUND`, a na delete odpověděl 204; jeho `workspace.patch` ukazuje
     klasický `MockMvc` s `MockMvcBuilders` místo `MockMvcTester`. V tomhle trialu tedy
     skill přinesl jedinou věc, testovací stack pro Boot 4. Zbylých šest konvencí si model
     odvodil z nachystaného zdrojového kódu, včetně těch tří, které skill kvůli tomuto
     evalu výslovně uvádí.
   - **Negativní kontrola.** Prošla v obou variantách: 4 ze 4 graderů, žádné vyvolání
     skillu, žádný dotčený soubor.
   - **Je to jeden trial na buňku.** „1 z 1 proti 0 z 1“ je anekdota. Rozdíly v tokenech a
     čase pocházejí z jediné dvojice session a zatím nic neznamenají: dřívější běh tohoto
     specu s jinak formulovaným skillem ukázal pro skill −13 % tokenů a −16 % času, tenhle
     +1 % a +17 %. Nastav `runs: 3` nebo víc a pusť to znovu, než komukoli řekneš, že skill
     pomáhá, a než řekneš cokoli o jeho ceně.
   - **Jak se skill dostal k modelu.** V trialu, který prošel, neobsahuje `events.jsonl`
     žádné volání nástroje `skill`. Vally zkopíroval složku skillu do workspace trialu a
     model si při průzkumu přečetl `api-endpoint/SKILL.md` přes `view`. Běh tedy ukazuje,
     že pomáhá *obsah* skillu, ne že zabírá jeho *description*. Na test spouštění dává
     dokumentace Vally graderu `skill-invocation` vedle `disallowed` i seznam `required`
     (tady nespuštěno; v tomhle trialu by `required: [api-endpoint]` selhalo).
   - **Nic neuniklo.** Trialy neběží v sandboxu, takže to zkontroluj. Tady šel každý zápis
     všech čtyř trialů do vlastní složky `vally-eval-*` v systémovém temp adresáři, kterou
     Vally potom odstranil; `git status --short` ukázal stejné soubory před i po a nové
     bylo jen `evals/results/` (v gitignore). S `EVALUATE_USE_HOST_COPILOT_HOME=1` vidí
     trialy i tvoje osobní skilly; v tomhle běhu se žádný nevyvolal.

   Když trial selže, otevři jeho `workspace.patch`, než sáhneš na skill. Chybovat může
   agent, ale i grader: správná odpověď, kterou tvůj vzor nepředvídal, je bug graderu.

**Hotovo.**

```bash
npm run eval:lint
VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml \
  --output-dir evals/results --dry-run
VALLY_TELEMETRY_OPTOUT=1 EVALUATE_USE_HOST_COPILOT_HOME=1 \
  npx --no vally experiment run evals/experiments/api-endpoint-ab.experiment.yaml --output-dir evals/results
git status --short
```

Očekávaný výsledek: `✔ evals/api-endpoint/eval.yaml is valid` mezi řádky lintu; dry run vypíše
`Plans:      2` s `skills=without (baseline)` a `skills=with`; skutečný běh (čtyři session)
skončí srovnávací tabulkou a zanechá `evals/results/<timestamp>/report.md`;
`git status --short` vypíše jen soubory, které jsi pro tohle cvičení vytvořil. Běh, ve
kterém všechno projde i baseline, je platný výsledek: říká ti, že si skill u tohohle úkolu
svoje místo nezaslouží, nebo že tvoje gradery kontrolují to, co model dělá tak jako tak.

---

## Bonus (web) 🟡 — bug, který nikdo nenastražil

**Vrstvy:** web

**Cíl.** Zreprodukuj skutečnou race condition v UI padajícím testem a pak ji oprav. Zmáčkni
dvě směrové klávesy rychle po sobě a deska může skončit u staršího stavu, než jaký drží
server.

**Co učí.** Žádný konkrétní mechanismus; je to smyčka úrovně 5 z
[návodu 10](10-level-5-workflow.cs.md) na bugu, na který v instrukcích není připravená
odpověď: popiš symptom, nech Copilota, ať ho dokáže testem, a pak oprav.

**Soubory.** `web/src/App.tsx` (změněný), `web/src/App.test.tsx` (nový).

**Kontext na místě.**

- `App.tsx` posílá jeden požadavek na každý stisk klávesy a volá `setGame` s tím, co se
  vrátí. Dva požadavky na cestě můžou odpovědět v libovolném pořadí. Server aplikoval oba
  tahy, ale na obrazovce vyhraje odpověď, která dorazí poslední, a to může být ta starší.
- Našlo se to při ovládání aplikace automatizovaným prohlížečem, který zmáčkl dvě klávesy
  zhruba milisekundu po sobě. Při lidské rychlosti je to vzácné, proto to žádný test
  nezachytil.
- Server má pravdu; na `api/` nesahej. Oprava patří do klienta.
- Nejlevnější správná oprava je povolit na cestě vždy jen jeden tah a stisky kláves
  ignorovat, dokud se nevrátí. Aplikovat odpovědi stylem „vyhrává poslední požadavek“ tady
  správně není: pozdější požadavek nemusí být ten, který server zpracoval jako poslední.

**Startovací prompt.**

> *„Stisk dvou šipek téměř ve stejnou chvíli může nechat desku v zastaralém stavu: server
> aplikoval oba tahy, obrazovka ukazuje jen první. Najdi příčinu ve `web/src`. Zatím nic
> neopravuj. Napiš do `web/src/App.test.tsx` test, který kvůli tomu selže, s mockem
> `./api`, a spusť ho, ať to selhání vidím.“*

**Walkthrough (kompletní řešení).**

1. **Nejdřív padající test.** *Mechanismus: žádný; prompt žádá důkaz před opravou.*
   Test mockuje API klienta, první tah nechá bez odpovědi, zmáčkne druhou klávesu a
   ověří, že odešel jen jeden požadavek.

```tsx
import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createGame, move } from './api'
import type { Game } from './api'
import { App } from './App'

vi.mock('./api')

const GAME: Game = {
  id: 'game-1',
  grid: [
    [2, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ],
  score: 0,
  status: 'IN_PROGRESS',
}

describe('App', () => {
  beforeEach(() => {
    vi.mocked(createGame).mockResolvedValue(GAME)
    // Never resolves: the first move stays in flight for the whole test.
    vi.mocked(move).mockReturnValue(new Promise<Game>(() => {}))
  })

  it('ignores a key press while the previous move is still in flight', async () => {
    render(<App />)
    await screen.findByRole('grid')

    fireEvent.keyDown(window, { key: 'ArrowLeft' })
    fireEvent.keyDown(window, { key: 'ArrowDown' })

    expect(move).toHaveBeenCalledTimes(1)
  })
})
```

   Na čistém `main` selže s `expected "vi.fn()" to be called 1 times, but got 2 times`.

2. **Oprava.**

   > *„Teď to oprav v `App.tsx`: na cestě smí být vždy jen jeden tah; směrové klávesy
   > ignoruj, dokud se nevrátí, při úspěchu i při selhání. `preventDefault` pro směrové
   > klávesy nech i ve chvíli, kdy je tah na cestě, aby stránka neskrolovala. Spusť webové
   > testy, lint a build.“*

```diff
--- a/web/src/App.tsx
+++ b/web/src/App.tsx
@@ -1,4 +1,4 @@
-import { useCallback, useEffect, useState } from 'react'
+import { useCallback, useEffect, useRef, useState } from 'react'
 import { createGame, move } from './api'
 import type { Game } from './api'
 import { Board } from './Board'
@@ -17,6 +17,8 @@ function messageOf(error: unknown): string {
 export function App() {
   const [game, setGame] = useState<Game | null>(null)
   const [error, setError] = useState<string | null>(null)
+  // Responses can arrive out of order, so only one move is in flight at a time.
+  const isMoveInFlight = useRef(false)
 
   const startGame = useCallback(() => {
     createGame()
@@ -43,9 +45,16 @@ export function App() {
       }
       // Arrow keys would otherwise scroll the page.
       event.preventDefault()
+      if (isMoveInFlight.current) {
+        return
+      }
+      isMoveInFlight.current = true
       move(game.id, direction)
         .then(setGame)
         .catch((cause: unknown) => setError(messageOf(cause)))
+        .finally(() => {
+          isMoveInFlight.current = false
+        })
     }
 
     window.addEventListener('keydown', onKeyDown)
```

   Ref, a ne state: příznak nesmí vyvolat render a handler kláves musí číst jeho aktuální
   hodnotu, ne tu zachycenou ve chvíli, kdy effect běžel.

3. **Review.** Požádej agenta `kotlin-reviewer` o review necommitnuté změny; navzdory
   jménu reviduje i TypeScript (jeho checklist zahrnuje effecty bez cleanupu).

**Hotovo.**

```bash
cd web && npm test && npm run lint && npm run build
```

Očekávaný výsledek: `Tests  8 passed (8)` ve 3 souborech (7 existujících + 1 nový), lint
nevypíše nic, build skončí s `✓ built in`. Referenční řešení bylo pro tento katalog sestaveno
a otestováno; prompty se přes Copilota znovu nepřehrávaly.

---

Vyber si cvičení, vlož jeho startovací prompt a postav ho. Každé ti nechá funkční featuru
a mechanismus, který sis sám vyzkoušel.

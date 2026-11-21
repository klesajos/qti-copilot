> 🌍 Číst v jazyce: [English](01-custom-instructions.md) | **Česky**

# Ukázka 1: Vlastní instrukce

## Co jsou vlastní instrukce?

**Vlastní instrukce** jsou Markdown soubory, které Copilot čte jako trvalé
pokyny pro repozitář. Existují tři druhy a liší se v tom, *kdy* se dostanou
k modelu:

- `.github/copilot-instructions.md` platí **pro celé repo**. Je součástí každé
  session od prvního promptu. Drž ho krátký: stack, struktura, konvence,
  příkazy.
- `.github/instructions/**/*.instructions.md` s globem `applyTo:` je
  **vázaný na cestu**. Jeho tělo v session není, dokud Copilot nepřečte nebo
  needituje soubor, který globu odpovídá. Teprve pak se doručí.
- `AGENTS.md` je soubor **napříč nástroji**, který čtou i jiní kódovací
  agenti. Podle dokumentace ho Copilot CLI hledá v kořenu repozitáře,
  v pracovním adresáři, v adresářích mezi nimi a v adresářích na cestě
  k souboru, se kterým pracuje. Vnořený `web/AGENTS.md` se proto načte pro
  práci pod `web/`. Tohle repo žádný `AGENTS.md` nemá.

Všechny se **slučují**. Podle dokumentace CLI nedefinuje mezi soubory
s instrukcemi žádnou prioritu a zahazuje jen identické duplicity, takže
`AGENTS.md` nenahrazuje `copilot-instructions.md`; přidává se k němu. Dva
soubory, které si odporují, se k modelu dostanou oba. Nepiš si protichůdná
pravidla s tím, že vyhraje to „bližší“. (Takové pravidlo je zdokumentované pro
GitHub.com, ne pro CLI.)

Tvoje osobní instrukce žijí v `~/.copilot/copilot-instructions.md` a slučují
se taky.

## Co dělá tahle ukázka

Repo obsahuje jeden soubor pro celé repo a dva vázané na cestu. Soubor pro
celé repo říká, co platí pro každý úkol. Ty dva vázané nesou pravidla, na
kterých záleží, jen když někdo sahá na pravidla hry nebo na REST vrstvu.
Účastník, který pracuje ve `web/`, nikdy neplatí kontextem za pravidla enginu.

Otestováno na 1.0.114: v čerstvé session dokázal Copilot ocitovat sekci
„Conventions“ ze souboru pro celé repo a řekl, že sekci „Engine rules“
v kontextu nemá. Poté, co nástrojem `view` otevřel `Board.kt`, ocitoval první
pravidlo enginu slovo od slova.

## Soubory řádek po řádku

```
.github/
├── copilot-instructions.md        ← repo-wide; in every session
└── instructions/                  ← path-scoped files, searched recursively
    ├── engine.instructions.md     ← applyTo: "engine/**/*.kt"
    └── api.instructions.md        ← applyTo: "api/**/*.kt"
```

Název vázaného souboru je libovolný. Vázaným ho dělá přípona
`.instructions.md` a umístění v `.github/instructions/`.

### `.github/copilot-instructions.md`

Nemá frontmatter; je to obyčejný Markdown, 49 řádků. Sekci po sekci:

- **`# 2048` a jedna věta.** Co ten repozitář je. Bez ní model odvozuje účel
  z názvů souborů.
- **`## Stack`.** Jeden řádek na modul, s *verzemi*: Kotlin 2.4 a JUnit 6
  v `engine/`, Spring Boot 4.2 s Jacksonem 3 v `api/`, React 19 s TypeScriptem
  6 na Vite 8 ve `web/`. Řádek pro `engine/` končí slovy „No I/O, no Spring“,
  což je pravidlo převlečené za popis.
- **Odstavec o Spring Boot 4.** Pozitivní seznam a negativní seznam:

  ```markdown
  This is Spring Boot **4**, not 3. Use `spring-boot-starter-webmvc`, Jackson 3 packages
  (`tools.jackson.*`), `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`,
  `MockMvcTester` and `@MockitoBean`. Do not generate Boot 3 idioms (`@MockBean`,
  `com.fasterxml.jackson.*` imports, `TestRestTemplate`).
  ```

  Proč tenhle odstavec existuje, vysvětluje následující sekce.
- **`## Directory structure`.** Čtyři řádky, jeden na každé místo, kde žije
  kód. Ušetří hledání, které by Copilot jinak pouštěl na začátku každého
  úkolu.
- **`## Conventions`.** Šest odrážek. První je architektura na jednom řádku:
  pravidla v `engine`, orchestrace v `api`, vykreslování ve `web`. Odrážka
  o RESTu fixuje obálku odpovědi (`{ "data": ... }` a
  `{ "error": { "code", "message" } }`), takže každý vygenerovaný endpoint
  vypadá stejně.
- **`## Commands`.** Přesné příkazy pro build, spuštění a testy. Copilot pustí
  to, co je tu napsané, místo aby hádal mezi `./gradlew test` a
  `gradle test`.
- **Poslední řádek.** „After changing code, run the tests for the part you
  touched and report the result.“ Jedna věta o procesu, umístěná na konec.

### `.github/instructions/engine.instructions.md`

```markdown
---
applyTo: "engine/**/*.kt"
---

# Engine rules

- `Board` stays free of I/O: no printing, no file or network access, no Spring imports.
- Randomness enters only through the `Random` passed to `Board`; never call `Random.Default` inside a rule.
- Keep `slideLineLeft()` a top-level function. It is the unit the merge rules are tested through.
- Every change to a rule needs a deterministic test built with `Board(grid, score)`, which spawns no tiles.
- A tile may merge at most once per move.
- Run `./gradlew :engine:test` after the change and report the pass and fail counts.
```

- `---` otevírá a zavírá frontmatter. Musí být na prvním řádku.
- `applyTo:` je glob relativní ke kořenu repozitáře. `engine/**/*.kt`
  odpovídá produkčnímu souboru i souboru s testy, takže pravidla dorazí pro
  oba.
- Nadpis je pro tebe i pro model: díky němu se při ladění načítání můžeš
  zeptat „je sekce *Engine rules* v tvém kontextu?“.
- Odrážky 1–3 chrání návrh, díky kterému je engine testovatelný.
- Odrážka 4 jmenuje konstruktor, se kterým se má testovat. Je to stejná
  konvence, jakou učí skill `board-tests` ([Ukázka 2](02-skills.cs.md));
  instrukce říká pravidlo, skill vysvětluje, jak na to.
- Odrážka 5, „a tile may merge at most once per move“, je specifikace, kterou
  současný kód porušuje (záměrný bug 1). Soubor s instrukcemi říká, jaké
  chování je zamýšlené. Díky tomu může Copilot označit padající test za bug,
  místo aby „opravil“ test.
- Odrážka 6 je vázaná verze posledního řádku ze souboru pro celé repo: přesný
  příkaz pro tenhle modul.

### `.github/instructions/api.instructions.md`

```markdown
---
applyTo: "api/**/*.kt"
---

# API rules

- Controllers stay thin: parse the request, call `GameService`, wrap the result in `ApiResponse`.
- New failure cases get their own exception and a handler in `ApiExceptionHandler` that returns
  `ErrorResponse` with a stable `code`. Write the message yourself; do not pass exception text through.
- Validate input at the boundary. Path and body values that cannot be parsed answer 400, not 500.
- Do not put game rules here. If a move needs a new rule, it belongs in `engine`.
- Controller tests use `@WebMvcTest` with `MockMvcTester` and assert on the JSON body, not on Kotlin objects.
- Run `./gradlew :api:test` after the change and report the pass and fail counts.
```

Stejný tvar. Všimni si, co jmenuje: skutečné třídy z téhle codebase
(`GameService`, `ApiResponse`, `ApiExceptionHandler`, `ErrorResponse`).
Pravidlo, které ukazuje na existující symbol, se dodržuje; „ošetřuj chyby
pořádně“ ne.

## Proč tohle repo jmenuje Spring Boot 4, Jackson 3 a JUnit 6

Model má sklon psát to, co viděl nejčastěji. U Springu je to Boot 3 a většinu
rozdílů odmítne už kompilátor:

| Zvyk modelu | Co potřebuje tenhle build |
|-------------------|-----------------------|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` |
| `import com.fasterxml.jackson...` | `tools.jackson.*` (Jackson 3 je v Bootu 4 výchozí) |
| `@MockBean` | `@MockitoBean` ze Spring Frameworku |
| `@WebMvcTest` ze starého balíčku | `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` |
| `TestRestTemplate` | tady `MockMvcTester`; Boot 4.2 označuje podporu `TestRestTemplate` jako deprecated |
| JUnit 5 | JUnit Jupiter 6.1.3, který spravuje Boot 4.2. `engine/` nemá Boot BOM a `junit-bom:6.1.3` si připíná sám |

Bez toho odstavce se tam Copilot dostane taky: vygeneruje variantu pro Boot 3,
build selže, přečte si chybu a opraví se. Ta smyčka pokaždé stojí jeden tah
a spotřebu, a jeden odstavec v souboru pro celé repo ji má odstranit. (To je
úvaha, která za odstavcem stojí; rozdíl se v tomhle repu neměřil.)

Pravidlo pro tvoje vlastní projekty: **zapiš každé místo, kde se tvůj stack
liší od toho, co byl mainstream před dvěma lety**, s číslem verze a seznamem
„negeneruj“. Nic z toho, co by model stejně udělal správně, řádek nepotřebuje.

## Kdy se soubory s `applyTo` doručují

Tělo souboru vázaného na cestu není součástí systémového promptu. Podle
dokumentace se doručí, když agent čte nebo edituje odpovídající soubor,
a přesně to ukázal i test. V běhu s `-p` a `--output-format json` je ten
okamžik vidět jako událost (tady zalomená a zkrácená):

```json
{"type":"system.notification","data":{"content":"Discovered instruction: .github/instructions/engine.instructions.md",
  "kind":{"type":"instruction_discovered","sourcePath":".github/instructions/engine.instructions.md",
          "triggerFile":".../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt","triggerTool":"view"}}}
```

Dva důsledky:

- **Vázané pravidlo nemůže ovlivnit nic, co se stane před prvním sáhnutím na
  odpovídající soubor.** Když Copilot sestaví plán jen z tvého promptu,
  pravidla enginu v něm ještě nejsou. Cokoli, co má formovat plán, patří do
  souboru pro celé repo.
- **Do té doby to nic nestojí.** To je důvod, proč dělit: soubor pro celé repo
  je v kontextu každého volání modelu v každé session.

Syntaxe, podle dokumentace: `applyTo` bere řetězec s globem; víc vzorů se píše
do jednoho řetězce oddělených čárkami (`"**/*.ts,**/*.tsx"`).

## Podívej se, co se načetlo

Mimo session, aniž bys cokoli utratil:

```bash
copilot instruction list --json
```

Vypíše `.github/copilot-instructions.md` a oba vázané soubory. Každý záznam má
`id`, `label`, `location`, `type`, `sourcePath`, `defaultDisabled` a u vázaného
souboru `applyTo` (tady `["engine/**/*.kt"]` a `["api/**/*.kt"]`). Pokud vázaný
soubor žádné pole `applyTo` neukazuje, nemá jeho frontmatter použitelné
`applyTo`.

Uvnitř session:

| Příkaz | K čemu ho použít |
|---------|-----------|
| `/instructions` | Seznam souborů s instrukcemi. Některý můžeš pro session vypnout |
| `/env` | Všechno, co se načetlo, včetně instrukcí, na jedné obrazovce |
| `/context` | Kolik tokenů zabírají vlastní instrukce v kontextovém okně |

`copilot instruction list` ukazuje, co *by se* načetlo. Chceš-li vědět, jestli
se vázaný soubor *doručil*, zeptej se modelu nebo hledej
`instruction_discovered` v JSON výstupu.

## `/init`

`copilot init`, nebo `/init` uvnitř session, analyzuje codebase read-only
nástroji a zapíše nebo aktualizuje `.github/copilot-instructions.md`. Text za
`/init` usměrňuje, co napíše. Použij ho, abys dostal první verzi pro repo,
které žádnou nemá, a tu pak proškrtej. Vygenerovaný soubor popisuje, čím kód
*je*. Cenné jsou řádky o tom, čím kód *musí zůstat*, a ty si napíšeš sám.

## Pravidla pro znovunačtení

Podle dokumentace se úpravy souborů s instrukcemi do běžící session
**nedostanou**. Ukonči ji a obnov (`copilot --continue`), nebo začni novou
(`/new`). Skilly a agenti jsou shovívavější ([Ukázka 2](02-skills.cs.md));
instrukce ne.

## Vytvoř si vlastní soubor s instrukcemi, krok za krokem

Pravidlo jen pro testy. (Ve Cvičení 1 píšeš takové pro `web/`, takže tohle
pokrývá testy v Kotlinu.)

1. **Vytvoř soubor** `.github/instructions/tests.instructions.md`:
   ```markdown
   ---
   applyTo: "engine/src/test/**/*.kt,api/src/test/**/*.kt"
   ---

   # Test rules

   - Never weaken or delete an assertion to make a test pass. If a correct test
     fails, keep it and report the failure as a bug in the code under test.
   - Do not add `@Disabled`. A test that cannot pass yet is a finding, not noise.
   - One behaviour per test. The test name says what the behaviour is.
   ```

2. **Zkontroluj, že se našel:**
   ```bash
   copilot instruction list --json
   ```
   Nový záznam musí pod `applyTo` ukazovat oba globy.

3. **Začni novou session.** Běžící session ten soubor neuvidí.

4. **Zkontroluj, že se načítá, jen když má.** Nejdřív se zeptej:

   > *„Nečti žádný soubor. Máš v kontextu sekci s názvem 'Test rules'?“*

   Odpověď je ne. Potom:

   > *„Přečti engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt. Máš teď v kontextu sekci s názvem 'Test rules'? Ocituj její první odrážku.“*

   Teď odrážku ocituje. Stejné čtení doručí i pravidla enginu, protože
   `BoardTest.kt` odpovídá také `engine/**/*.kt`. Platí obě; žádné nepřebíjí
   to druhé.

5. **Commitni ho:**
   ```bash
   git add .github/instructions/tests.instructions.md
   git commit -m "Add path-scoped test rules"
   ```

Variantu s jedním globem používají oba soubory v tomhle repu a u té se
testovalo doručení. Varianta s čárkami z kroku 1 je z dokumentace; na 1.0.114
ji `copilot instruction list --json` rozdělí na jeden glob na každý vzor
(otestováno) a krokem 2 si to potvrdíš na své verzi. Doručení souboru se vzory
oddělenými čárkou se netestovalo.

## `applyTo` pro tvůj vlastní stack

Mechanismus je na každém projektu stejný; mění se jen globy a pravidla. Jsou
to výchozí body, tady netestované. Nahraď odrážky tím, co tvůj tým doopravdy
vynucuje.

**Swift (iOS)**

```markdown
---
applyTo: "**/*.swift"
---

- New asynchronous code uses `async`/`await`. Do not add completion-handler APIs.
- UI state is updated on the main actor only.
- No force unwraps outside tests.
```

**Kotlin (Android)**

```markdown
---
applyTo: "app/src/main/**/*.kt"
---

- UI is Jetpack Compose. Do not create XML layouts or Fragments.
- Composables receive state and callbacks; they do not reach into repositories.
- Coroutines are launched from a ViewModel scope, never `GlobalScope`.
```

**Java (backend)**

```markdown
---
applyTo: "**/src/main/java/**/*.java"
---

- Constructor injection only. No field injection.
- DTOs are records. Entities never leave the service layer.
- Name the exact framework and JDK version here if it is not the one a model assumes.
```

Jedna past v repozitáři, který obsahuje backend v Kotlinu i aplikaci pro
Android: `**/*.kt` odpovídá obojímu. Vymezuj podle adresáře, jako to tohle
repo dělá s `engine/` a `api/`, ne podle přípony souboru.

## Vyzkoušej demo

Začni čerstvou session a zeptej se:

> *„Přečti engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt. Máš v kontextu sekci s názvem 'Engine rules'? Ocituj její první odrážku.“*

Copilot ocituje odrážku o I/O. Začni další čerstvou session a polož stejnou
otázku, jen před ni dej „Nečti žádný soubor“. Teď je odpověď ne, zatímco sekce
„Conventions“ ze souboru pro celé repo tam pořád je.

## Past dvojího načítání souborů pro Clauda

Copilot CLI nečte jen vlastní soubory. V projektu načítá také `CLAUDE.md`,
`.claude/CLAUDE.md`, `GEMINI.md` a každý soubor pod `.claude/rules/`, a se
souborem z `.claude/rules` s klíčem `paths:` zachází jako se souborem
`.instructions.md` s `applyTo:`.

V repozitáři, který slouží oběma nástrojům, to znamená:

- `CLAUDE.md` a `.github/copilot-instructions.md` obvykle říkají totéž jinými
  slovy. Nejsou identické, takže se nic nededuplikuje. Copilot dostane oba,
  ty platíš za oba, a kde se liší, vybírá si model.
- Pravidla napsaná pro Claude Code („použij nástroj Edit“, „deleguj přes
  nástroj Task“) dorazí do kontextu Copilota, kde jsou šumem nebo jsou špatně.

Tohle repo se problému vyhýbá tím, že **nemá `CLAUDE.md` ani adresář
`.claude/`**. V repu, které potřebuje oba nástroje:

1. Spusť `copilot instruction list` a přečti si seznam. Je to jediná
   spolehlivá odpověď na otázku „co tady Copilot načítá?“
2. Drž jeden zdroj pravdy a výsledek kontroluj krokem 1. Podle dokumentace
   fungují importy `@path` v `AGENTS.md`, `CLAUDE.md` a
   `copilot-instructions.md` (ne uvnitř `*.instructions.md`), takže soubor
   pro konkrétní nástroj si může natáhnout sdílený. Jestli se importovaný
   text pak počítá jednou, nebo dvakrát, si ověř na své verzi, nepředpokládej
   to.
3. Pro jednu session vypni soubor v `/instructions`, nebo spusť Copilota
   s `--no-custom-instructions` a uvidíš, jak se chová bez instrukcí.

Tvůj osobní adresář `~/.claude/` se nečte. Osobní instrukce pro Copilota
patří do `~/.copilot/copilot-instructions.md`.

## Volitelné parametry

| Nastavení / klíč | Kde | Co dělá |
|---------------|-------|--------------|
| `applyTo` | frontmatter vázaného souboru | Glob, nebo několik oddělených čárkami. Dělá ze souboru soubor vázaný na cestu |
| `excludeAgent` | frontmatter vázaného souboru | `"code-review"` nebo `"cloud-agent"`: schová soubor před daným prostředím. Na CLI nemá vliv (podle dokumentace) |
| `@path/to/file` | uvnitř `copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md` | Importuje jiný soubor. V `*.instructions.md` se nerozbaluje (podle dokumentace) |
| `--no-custom-instructions` | přepínač při spuštění | Nenačte vůbec žádné soubory s instrukcemi. Hodí se jako větev „bez“ při srovnání |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | prostředí | Další adresáře k prohledání, oddělené čárkami |
| `include-custom-instructions: true` | frontmatter vlastního agenta | Vlastní agent spuštěný jako subagent nedostane žádné instrukce repozitáře, pokud si tohle nenastaví (podle dokumentace). Oba agenti v `.github/agents/` to nastavené mají |
| `/init [guidance]` | session | Vygeneruje nebo aktualizuje `.github/copilot-instructions.md` |

Délka: jediné zveřejněné vodítko je best practice kolem 1 000 řádků na soubor,
z dokumentace ke code review. To je strop, ne cíl. Soubor pro celé repo jich
tady má 49.

Reference: [Adding custom instructions for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions).

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|----------|--------|-------|
| **Copilot CLI** | ✅ Ano | Otestováno na 1.0.114: načtou se všechny tři soubory, vázané soubory se doručí při čtení |
| **Plugin pro IntelliJ** | ✅ Ano | Podle release notes pluginu: `copilot-instructions.md` od 1.5.42, `.instructions.md` od 1.5.53, `AGENTS.md` od 1.6.1. Vnořený `AGENTS.md` je nastavení pod Settings > GitHub Copilot > Customizations. Tady netestováno |
| **Cloud agent** | ✅ Ano | Podle dokumentace čte z repozitáře soubor pro celé repo, vázané soubory i `AGENTS.md`. `excludeAgent: "cloud-agent"` před ním soubor schová |

Copilot code review na GitHub.com čte tytéž soubory, z head branche pull
requestu (podle dokumentace). Změnu souboru s instrukcemi si proto můžeš
vyzkoušet přímo v pull requestu, který ji zavádí.

## Když něco nefunguje

- **Vázané pravidlo se ignoruje** → doručí se až poté, co Copilot přečte nebo
  edituje odpovídající soubor. Zkontroluj glob proti skutečné cestě přes
  `copilot instruction list --json` a pak se zeptej modelu, jestli tu sekci
  má v kontextu.
- **Upravil jsi soubor a nic se nezměnilo** → instrukce se čtou při startu
  session. Použij `/new`, nebo ji ukonči a spusť `copilot --continue`.
- **Soubor chybí v `copilot instruction list`** → název musí končit na
  `.instructions.md` a soubor musí být pod `.github/instructions/`.
- **Instrukce jako by platily dvakrát, nebo si odporují** → načítá se také
  nějaký `CLAUDE.md`, `AGENTS.md` nebo soubor z `.claude/rules/`. Seznam
  ukazuje každý zdroj.
- **Vlastní agent ignoruje konvence** → běžel jako subagent bez
  `include-custom-instructions: true`.
- **Copilot pořád píše `@MockBean`** → zkontroluj, že se načetl soubor pro
  celé repo (`/instructions`) a že session nikdo nespustil
  s `--no-custom-instructions`.

Dál: [Ukázka 2: Projektový skill](02-skills.cs.md).

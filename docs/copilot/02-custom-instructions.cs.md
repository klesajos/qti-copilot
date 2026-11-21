> 🌍 Číst v jazyce: [English](02-custom-instructions.md) | **Česky**

# 02 · Vlastní instrukce

> ⏱ 15 min (5 demo + 10 cvičení 1) · Dokumentace: [Adding custom instructions for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) · [Support per surface](https://docs.github.com/en/copilot/reference/custom-instructions-support) · Ověřeno na Copilot CLI 1.0.114

## Co jsou vlastní instrukce?

Markdown soubory, které Copilot načítá jako trvalé pokyny. Liší se v tom, *kdy* se dostanou k modelu:

- `.github/copilot-instructions.md` platí **pro celé repo**: posílá se s každým voláním modelu
  v každé session.
- `.github/instructions/**/*.instructions.md` s globem `applyTo:` je **vázaný na cestu**: jeho tělo
  se vloží, až když Copilot přečte nebo upraví odpovídající soubor.
- `AGENTS.md` je soubor **společný pro všechny nástroje** ([agents.md](https://agents.md/)). Tohle repo žádný nemá.
- `~/.copilot/copilot-instructions.md` je **osobní**. Všechny načtené soubory se slučují, žádný
  nemá přednost.

## Co dělá tahle ukázka

```
.github/
├── copilot-instructions.md        ← repo-wide, 49 lines: stack, layout, conventions, commands
└── instructions/                  ← searched recursively; the .instructions.md suffix is what counts
    ├── engine.instructions.md     ← applyTo: "engine/**/*.kt"
    └── api.instructions.md        ← applyTo: "api/**/*.kt"
```

Soubor pro celé repo obsahuje to, co platí pro každý úkol. Soubory vázané na cestu nesou pravidla
jen pro herní logiku a REST vrstvu, takže session, která pracuje ve `web/`, za ně nikdy neplatí.

## Soubory řádek po řádku

`.github/copilot-instructions.md` je obyčejný Markdown bez frontmatteru. Hlavní váhu nesou dvě části:
- **Odstavec o Spring Boot 4** vyjmenovává, co použít (`tools.jackson.*`, `MockMvcTester`,
  `@MockitoBean`) a co negenerovat (`@MockBean`, `com.fasterxml.jackson.*`). Model píše to, co
  viděl nejčastěji, a to je Boot 3. Sepiš každé místo, kde se tvůj stack liší od hlavního proudu
  před dvěma lety: verzi a seznam „negeneruj“. Zbytek vynech.
- **`## Commands`** obsahuje přesné příkazy pro build a testy, takže Copilot mezi nimi nehádá.

`.github/instructions/engine.instructions.md` je blok frontmatteru a šest odrážek:
- `applyTo: "engine/**/*.kt"` je glob relativní ke kořenu repozitáře. Odpovídá mu produkční
  soubor i soubor s testy. Víc vzorů se píše do jednoho řetězce, oddělených čárkami.
- „A tile may merge at most once per move“ je specifikace, kterou současný kód porušuje.
  Díky ní Copilot nahlásí padající test jako chybu, místo aby test „opravil“.
- `api.instructions.md` jmenuje skutečné symboly (`GameService`, `ApiExceptionHandler`). Pravidlo,
  které ukazuje na existující symbol, model dodrží; „handle errors properly“ ne.
- Tělo souboru vázaného na cestu není v systémovém promptu, takže plán sepsaný dřív, než Copilot
  sáhne na první odpovídající soubor, o pravidle neví. Co má ovlivnit plán, patří do souboru pro celé repo.

## Vytvoř si vlastní, krok za krokem

1. Vytvoř `.github/instructions/tests.instructions.md` (ten pro `web/` vznikne ve cvičení 1):
   ```markdown
   ---
   applyTo: "engine/src/test/**/*.kt,api/src/test/**/*.kt"
   ---
   # Test rules
   - Never weaken or delete an assertion to make a test pass. Report the failing test as a bug.
   ```
2. Ověř, že ho Copilot najde. Je to zdarma a mimo session: `copilot instruction list --json` ukáže oba globy.
3. Ověř doručení. Výstup jmenuje každý vložený soubor: `engine.instructions.md` a ten tvůj.
   ```bash
   copilot -p "Read engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt. Change no file." \
     --trust-folder --no-ask-user --output-format json \
     | jq -r 'select(.data.kind.type? == "instruction_discovered") | .data.kind.sourcePath'
   ```

> 🔷 **Jen Copilot:** `copilot instruction list --json` a přepínač pro jednotlivé soubory v `/instructions`.
> Claude Code nedokumentuje žádný JSON výpis načtených zdrojů ani interaktivní přepínání po souborech.

## Vyzkoušej demo

Spusť čerstvou session přes `scripts/copilot-ws.sh` a zeptej se:

> *„Přečti engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt. Máš v kontextu sekci s názvem 'Engine rules'? Ocituj její první odrážku. Neměň žádný soubor.“*

Copilot odpoví, že ano, a ocituje „`Board` stays free of I/O: no printing, no file or network access,
no Spring imports.“ Časová osa ukáže `● Discovered engine.instructions.md from .github/instructions/`.
Čerstvá session, které nejdřív řekneš „Nečti žádný soubor.“, odpoví, že ne.

**Co to stojí:** žádný příkaz pro statický audit neexistuje. `copilot instruction list --json` ukáže,
co se načítá, `/context` má řádek `Custom Instructions` (v tomto repu 760 tokenů, před vložením souboru vázaného na cestu i po něm) a [`/chronicle improve`](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle)
navrhuje úpravy `.github/copilot-instructions.md` podle sessions z tohoto repa ⚠️ v tomto repu nespuštěno

## Repo, které už AI instrukce má

Většina z asi 170 repozitářů My2N nějaké má. Nejdřív si mimo session vypiš, co tam Copilot načítá:

```bash
copilot instruction list --json | jq -r '.[] | [.location, .sourcePath, ((.applyTo // ["every session"]) | join(","))] | @tsv'
```

| Soubor v repu | Načítá ho Copilot CLI 1.0.114 |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` v kořenu; vnořené, když Copilot spustíš tam | ✅ v každé session |
| `.claude/rules/*.md` | ✅ v každé session; s `paths:` vázané na cestu jako `applyTo` |
| `.claude/skills/`, `.agents/skills/`, `.claude/agents/`, `.claude/commands/`, hooky v `.claude/settings.json` | ✅ hooky se spouštějí: nejdřív si je přečti |
| `.claude/CLAUDE.md` (uvedený v `copilot help config`), `.cursorrules`, `.cursor/rules/*.mdc`, `.windsurfrules`, osobní `~/.claude/` | ❌ |

1. Všechno načtené se slučuje a nic nemá přednost. Dvě skoro stejná pravidla se pošlou obě, při každém volání modelu.
2. Nech v repu jeden soubor, který platí vždy. Společnou volbou pro všechny nástroje je `AGENTS.md`; pravidla z Cursoru přesuň tam.
3. Po `/init` si přečti diff: zapíše `.github/copilot-instructions.md` vedle toho, co tam už je.
4. Výsledek porovnej A/B: jedna session tak, jak to je, druhá spuštěná s `--no-custom-instructions`.
5. Hodně repozitářů: `scripts/instruction-audit.sh <repo-dir>...` vypíše pro každé repo soubor, scope a bajty.

> 🔷 **Jen Copilot:** Copilot CLI čte soubory jiných nástrojů živě (`CLAUDE.md`, `GEMINI.md`, `.claude/`).
> Claude Code čte `AGENTS.md` a jinak konfiguraci jiných nástrojů importuje jednorázově, přes `/init` nebo `/import`.

## applyTo pro tvůj stack

| Stack | `applyTo` | Pravidla, která stojí za řádek (výchozí body) |
|---|---|---|
| Java backend | `"**/src/main/java/**/*.java"` | jen constructor injection; DTO jsou recordy; přesná verze frameworku a JDK |
| Kotlin backend | `"api/**/*.kt"`: vymez adresářem, `**/*.kt` zachytí i Android a testovací moduly | tenké controllery; vlastní výjimka pro každý případ selhání (tohle repo) |
| React / TypeScript | `"web/src/**/*.ts,web/src/**/*.tsx"` | žádné `any`; pojmenované exporty; jak se testuje komponenta (cvičení 1) |
| Kotlin Android | `"app/src/main/**/*.kt"` | jen Compose, žádné XML layouty; coroutines ze scope ViewModelu |
| Swift iOS | `"**/*.swift"` | `async`/`await`, žádné completion handlery; stav UI na main actoru; žádné force unwrapy |
| Kotlin automatizace testů | testovací modul, např. `"e2e/**/*.kt"` | čekej na podmínku, žádný sleep; selektory žijí v page objectech; každý test si vytváří vlastní data |

## Volitelné parametry

| Nastavení | Kde | Co dělá |
|---|---|---|
| `excludeAgent` | frontmatter souboru vázaného na cestu | `"code-review"` nebo `"cloud-agent"`: skryje soubor před daným prostředím, ne před CLI |
| `@path/to/file` | `copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md` | Vloží jiný soubor z repa. V `*.instructions.md` a `GEMINI.md` se nerozbalí |
| `/init [guidance]`, `copilot init` | session, terminál | Vygeneruje nebo aktualizuje `.github/copilot-instructions.md` |
| `--no-custom-instructions` | přepínač při spuštění | Nenačte žádný soubor s instrukcemi: větev „bez“ při srovnání |
| `include-custom-instructions: true` | frontmatter vlastního agenta | Subagent dostane instrukce repa jen s tímhle. Nastavují ho `kotlin-reviewer` a `board-test-writer` |

Kompletní reference: [Custom instructions locations](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-instructions-locations)

## Kde to funguje

| Soubor | CLI | Plugin pro IntelliJ | Cloud agent |
|---|---|---|---|
| `.github/copilot-instructions.md`, `*.instructions.md` | ✅ | ✅ od 1.5.42; `applyTo` vyžaduje 1.5.62 | ✅ |
| `AGENTS.md`, `CLAUDE.md` | ✅ | ⚠️ od 1.6.1; vnořené soubory se zapínají v nastavení | ✅ |

## Copilot vs Claude Code

Claude Code: `CLAUDE.md`, `.claude/rules/*.md` s `paths:`, `/init`. Doručení při čtení nebo úpravě
funguje stejně. Copilot slučuje každý soubor, který najde, včetně těch od Claude Code, takže repo,
které slouží oběma nástrojům, potřebuje jeden zdroj pravdy. `excludeAgent` nemá v Claude Code protějšek.

## Když něco nefunguje

- **Pravidlo vázané na cestu se ignoruje** → dorazí, až když Copilot přečte nebo upraví odpovídající soubor.
- **Upravil jsi soubor a nic se nezměnilo** → soubory se načítají při startu session: `/new` nebo `copilot --continue`.
- **Soubor není v `copilot instruction list`** → pojmenuj ho `.github/instructions/<name>.instructions.md`.

Dál: [03 · Skilly](03-skills.cs.md) · Cvičení 1: [exercises.cs.md](exercises.cs.md)

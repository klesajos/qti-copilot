> 🌍 Číst v jazyce: [English](14-conductor.md) | **Česky**

# Ukázka 14: Microsoft Conductor

## Co je Conductor?

**Conductor** je nástroj pro příkazovou řádku od Microsoftu, který spouští multiagentní
workflow definovaná v YAML souboru. Soubor jmenuje agenty a říká, co smí každý z nich
používat, co musí vrátit a kam jde výsledek dál. Není součástí Copilota; je to samostatný
nástroj v Pythonu pod licencí MIT, který Copilota *používá* jako providera modelů.

2N ho plánuje používat pro centrální agentní flow. Vlastnost, která se na to hodí:

- **Routování je obyčejný YAML.** O tom, který krok poběží dál, rozhodují `routes` v souboru,
  ne model. **V orchestrační smyčce není žádné LLM**; model se volá jen *uvnitř* kroku.
- **Soubor je kontrakt.** Dá se zrevidovat v pull requestu, zvalidovat bez spuštění
  a spustit stejně na notebooku i na serveru.

Srovnej to s [`/fleet`](07-orchestration.cs.md), kde o rozdělení práce rozhoduje model při
každém běhu znovu.

**Stav: v0.1.47, Beta, a vyvíjí se rychle.** Pět releasů mezi 2026-10-29 a 2026-11-20 a jeho
changelog nese několik položek označených jako breaking. Všechno tady ber jako snímek jedné
verze.

## Co dělá tahle ukázka

`conductor/test-coverage-audit.yaml` audituje pokrytí testy v tomto repu:

```
layer_inventories (parallel group)
├── engine_inventory   ← Board.kt vs BoardTest.kt
├── api_inventory      ← api/src/main vs api/src/test
└── web_inventory      ← web/src and its *.test.ts(x) files
        │  all three finish
        ▼
reporter               ← merges the three inventories into one gap table
        ▼
$end → output: report, untested_total
```

Tři inventarizační agenti můžou jen číst. Reporter nemá vůbec žádné nástroje. Soubor byl pro
tento návod zvalidován a spuštěn; výsledek je v části „Validace a spuštění“.

## Instalace

```bash
uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"
conductor --version        # Conductor v0.1.47
```

- Potřebuje [`uv`](https://docs.astral.sh/uv/) a Python 3.12 nebo novější.
- **Neinstaluj `conductor-cli` z PyPI.** To jméno patří nesouvisejícímu projektu jiného
  autora. Instaluj jen z git URL Microsoftu a připni tag.
- Podle jeho changelogu je Conductor v0.1.47 první verze, která funguje s Copilot CLI
  1.0.113 a novějším. Starší verze Conductoru selžou s „SDK protocol version mismatch“.
- `conductor update` existuje. Nepouštěj ho uprostřed workshopu.

Pak zkontroluj prostředí:

```bash
conductor doctor
```

Na testovacím stroji nahlásil Conductor v0.1.47, Python 3.12 a pro providera `copilot`:
nainstalováno, tier `stable`, *„authenticates via GitHub/Copilot CLI login; env vars
are optional overrides“*. Pokud ti Copilot CLI funguje, není co dál konfigurovat.
Provideři `openai` a `claude` potřebují vlastní API klíče a tady se nepoužívají.

## Soubor řádek po řádku

### `workflow`: identita a vstupní bod

```yaml
workflow:
  name: test-coverage-audit
  description: Inventory behaviours per layer in parallel, then report which have no test
  version: "1.0.0"
  entry_point: layer_inventories
```

`entry_point` je místo, kde běh začíná. Může jmenovat agenta, paralelní skupinu nebo
for-each skupinu. Tady jmenuje paralelní skupinu.

### `runtime`: provider a model

```yaml
  runtime:
    provider: copilot
    default_model: auto
```

`copilot` je výchozí provider a šel by vynechat (podle README); je tu napsaný, abys ho
viděl.

Na `default_model: auto` záleží. Bez něj běh na testovacím účtu selhal s
**`Model "gpt-4o" is not available.`** Vestavěný default Conductoru je pevné id modelu a to
id není na seznamu každé organizace. `auto` nechá Copilota vybrat z modelů, které smíš
používat. Id modelu do tohoto souboru nedávej.

### `context` a `limits`

```yaml
  context:
    mode: explicit

  limits:
    max_iterations: 10
    timeout_seconds: 900
```

`mode: explicit` znamená, že agent vidí jen to, co vyjmenuje pod `input:`. Další režimy
jsou `accumulate` (výchozí) a `last_only` (podle dokumentace). Explicitní režim drží prompt
reportera jen na třech inventářích.

`limits` zastaví běh, který se zacyklí nebo zasekne. Tohle workflow má dva kroky a žádnou
smyčku; limity začnou být důležité, až nějakou přidáš.

### `tools` na nejvyšší úrovni

```yaml
tools:
  - view
  - grep
  - glob
```

Tohle je registr nástrojů workflow. **Každý nástroj, který agent uvádí, musí být uvedený
i tady.** Otestováno: když z tohoto seznamu odebereš `glob`, `conductor validate` selže s
*„Agent 'engine_inventory' references unknown tool 'glob'. Available tools: grep, view“*.
Názvy jsou názvy vestavěných nástrojů Copilota. Podle dokumentace agent, který `tools:`
vynechá, zdědí celý tenhle seznam, a `tools: []` mu nedá žádný. Seznamy omezují, jen když
existují: workflow ve cvičení 7 nemá žádné `tools:` na nejvyšší úrovni a jeho builder agenti
žádné nástroje nejmenují, a v tom běhu měli plnou výchozí sadu nástrojů providera
a zapisovali soubory. Smazat seznam je tedy pravý opak uzamčení workflow.

Proč je právě tohle bezpečnostní mechanismus: podle své dokumentace Conductor běžné žádosti
o oprávnění schvaluje automaticky. Nikoho se neptá. Agent je read-only proto, že nemá
nástroj, který umí zapisovat, ne proto, že to říká prompt.

### Paralelní skupina

```yaml
parallel:
  - name: layer_inventories
    description: One read-only inventory per layer, run at the same time
    agents:
      - engine_inventory
      - api_inventory
      - web_inventory
    failure_mode: continue_on_error
    routes:
      - to: reporter
```

Skupina pustí své agenty najednou a počká na všechny. Podle dokumentace dostane každý agent
stejný snímek kontextu; na práci ostatních nevidí.

`failure_mode: continue_on_error` nechá reportera běžet, i když jeden inventář selže.
Výchozí hodnota je `fail_fast`; třetí možnost je `all_or_nothing`.

### Agenti s typovanými výstupy

```yaml
agents:
  - name: engine_inventory
    description: Behaviours of the board rules and the tests that cover them
    tools: [view, grep, glob]
    prompt: |
      You audit test coverage. Read only; never modify a file.

      Source: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      Tests:  engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
      …
    output:
      behaviours:
        type: array
        description: One entry per behaviour, as "behaviour — covering test name, or NONE"
      untested_count:
        type: number
        description: How many behaviours have no covering test
```

`api_inventory` a `web_inventory` jsou stejný agent s jinými cestami.

`output` deklaruje pole, která musí agent vrátit, každé s typem (`string`, `number`,
`boolean`, `array`, `object`). Další krok čte pole, ne prózu. Podle dokumentace se to
s providerem Copilot dělá instrukcí modelu, ne nativním JSON režimem, takže drž tvary
jednoduché.

Cesty jsou relativní k místu, odkud `conductor` spouštíš. Pouštěj ho z kořene repozitáře.

### Reporter

```yaml
  - name: reporter
    description: Merges the three inventories into one gap report
    tools: []
    input:
      - layer_inventories.outputs
    prompt: |
      Three auditors inventoried the test coverage of a 2048 game, one layer each:

      {{ layer_inventories.outputs | json }}

      Write one Markdown table with the columns Layer, Behaviour, Covered by. …
    output:
      report:
        type: string
        description: The Markdown gap report
      untested_total:
        type: number
        description: Total number of untested behaviours across all layers
    routes:
      - to: $end
```

- `tools: []` mu nedá nic. Uvažuje jen nad svým promptem.
- `input:` je deklarace pro explicitní režim: tenhle agent dostane výstupy skupiny.
- `{{ … }}` je Jinja2 šablona. `layer_inventories.outputs` drží jednu položku za každého
  agenta skupiny; `| json` ji vyrenderuje do promptu.
- *„Use only what the auditors reported“* v promptu mu brání vymýšlet si řádky.

### Routy a finální výstup

```yaml
output:
  report: "{{ reporter.output.report }}"
  untested_total: "{{ reporter.output.untested_total }}"
```

V souboru jsou dvě routy: skupina jde do `reporter` a `reporter` jde do `$end`.
Inventarizační agenti žádnou nemají; routuje za ně skupina. Routa může nést i podmínku
`when:` nad výstupem agenta a vyhrává první routa, která odpovídá (podle dokumentace). Tak
se píše smyčka nebo větvení. V obou případech je rozhodnutí výraz v souboru.

`output` na nejvyšší úrovni mapuje výsledek workflow z výstupů agentů.

## Validace a spuštění

```bash
conductor validate conductor/test-coverage-audit.yaml       # free
conductor run conductor/test-coverage-audit.yaml --dry-run  # free: prints the plan
conductor run conductor/test-coverage-audit.yaml            # four agent sessions
```

`validate` kontroluje syntaxi YAML, schéma, reference na agenty a cíle rout. Na tomhle
souboru vypíše **Validation Successful** se 4 agenty, 1 paralelní skupinou a modelem `auto`.
`--dry-run` vypíše plán: krok 1 `layer_inventories` se třemi paralelními agenty, krok
2 `reporter`, pak `$end`.

Skutečný běh udělal, co soubor říká: tři inventarizační agenti běželi paralelně na provideru
Copilot a reporter pak vrátil jednu tabulku mezer. Uvedl **42 neotestovaných chování**, mezi
nimi mezeru u kaskádového slučování a mezeru u game over, které plynou ze záměrných bugů
tohoto repa. **Žádný soubor se nezměnil** (`git status` byl před i po stejný).

Tvar běhu je pevný. Obsah ne: každý řádek pořád píše model, takže příště čekej jiný počet.

Pro strojově čitelný výstup vypíše `--silent` jen JSON výsledek. Je to root volba a patří
**před** `run`:

```bash
conductor --silent run conductor/test-coverage-audit.yaml
```

## Srovnání

| | `/fleet` | Dynamické workflow | Conductor |
|---|---|---|---|
| **Kdo rozhoduje o rozdělení** | Model, při každém běhu | Kód extension | YAML soubor |
| **Kde je definované** | V promptu | `.github/extensions/<name>/extension.mjs` | `conductor/*.yaml` |
| **Požadavky navíc** | Žádné | Experimentální režim a podmínka na billing | Samostatná instalace (`uv`, Python 3.12+) |
| **Nástroje na agenta** | Určuje je session, ne krok (netestováno) | Netestováno | Přesně vyjmenované nástroje; na nic se neptá |
| **Typované výsledky mezi kroky** | Ne | Netestováno | Ano, `output:` |
| **Kontrola bez spuštění** | Ne | Netestováno | `conductor validate`, `--dry-run` |
| **Stav** | Vestavěné | Experimentální | Beta |
| **Spuštěno v tomto repu** | Ne | Ne | Ano |

`conductor fleet` nemá s `/fleet` v Copilotu nic společného: monitoruje běžící Conductor
workflow.

## Rozšiř to

Dvě rozšíření, která stojí za vyzkoušení. Syntaxe je **převzatá z vlastních příkladů
Conductoru a z jeho skill reference**. Oba úryvky projdou `conductor validate` na v0.1.47,
když je přidáš do kopie souboru. **Ani jeden se tady nespouštěl.**

**Human gate** po reportu. Nasměruj `reporter` na gate místo na `$end`:

```yaml
  - name: reporter
    # … unchanged …
    routes:
      - to: review_gate

  - name: review_gate
    type: human_gate
    prompt: |
      {{ reporter.output.untested_total }} untested behaviours found.

      {{ reporter.output.report }}
    options:
      - label: Accept the report
        value: accept
        route: $end
      - label: Run the inventories again
        value: redo
        route: layer_inventories
```

Druhá volba vytváří smyčku, a právě na to je `max_iterations`. V automatizaci vybere
`conductor run --skip-gates` první volbu. Gate nemůže být uvnitř paralelní skupiny.

**For-each skupina**, která se rozvětví přes seznam, který vyrobil agent. Přidej `reporter`
jedno výstupní pole navíc (`top_gaps`, `type: array`), nasměruj ho na skupinu a doplň:

```yaml
for_each:
  - name: gap_planners
    type: for_each
    description: One test proposal per top gap
    source: reporter.output.top_gaps
    as: gap
    max_concurrent: 3
    failure_mode: continue_on_error
    agent:
      name: gap_planner
      tools: [view]
      prompt: |
        Gap {{ _index + 1 }}: {{ gap }}

        Read the source file this gap is about. Propose one test for it: the test name
        and the assertion. Do not write any file.
      output:
        test_name:
          type: string
          description: Proposed test name
        assertion:
          type: string
          description: The assertion the test would make
    routes:
      - to: $end
```

Na rozdíl od statické skupiny se počet agentů určí až za běhu podle délky seznamu. Výsledky
pak v dalších krocích čti jako `{{ gap_planners.outputs | json }}`.

`docs/workflow-syntax.md` v Conductoru ukazuje jiný tvar human gate a blok `input:` na
nejvyšší úrovni; obojí je v rozporu s jeho schématem (podle rešerše pro tento workshop).
Když si nejsi jistý, věř `conductor validate`.

## Vytvoř si vlastní workflow, krok za krokem

1. **Zkopíruj** `conductor/test-coverage-audit.yaml` a ořež ho na jednoho agenta, který
   routuje do `$end`. `entry_point` nastav na tohoto agenta.
2. **Nech `default_model: auto`** a seznam `tools:` na nejvyšší úrovni.
3. **Dej agentovi typovaný `output`** a namapuj ho v `output:` na nejvyšší úrovni.
4. **Zvaliduj, pak dry-run.** Obojí je zadarmo.
5. **Spusť to jednou.** Pak přidej druhého agenta, routu a teprve potom paralelní skupinu.
6. **Drž agenty read-only**, dokud není flow stabilní. Agent, který zapisuje, potřebuje
   nástroj pro zápis nebo shell v obou seznamech, a nic se tě nezeptá, než ho použije.

## Volitelné parametry

| Flag | Co dělá |
|------|---------|
| `--dry-run` | Ukáže plán provedení a nic nespustí |
| `-i, --input NAME=VALUE` | Vstup workflow; lze opakovat. Deklaruje se pod `workflow.input` |
| `--skip-gates` | U human gate automaticky vybere první volbu |
| `-l, --log-file <path\|auto>` | Zapíše plný debug výstup do souboru |
| `--web` | Spustí pro běh webový dashboard v reálném čase |
| `--workspace-instructions` | Předřadí před prompt každého agenta `AGENTS.md`, `.github/copilot-instructions.md` a soubory instrukcí s `applyTo: "**"`. **Ve výchozím stavu vypnuté** |
| `-p, --provider <name>` | Přebije providera nastaveného v souboru |
| `conductor --silent run …` | Na stdout jen JSON výsledek |
| `conductor --quiet run …` | Jen životní cyklus agentů a routování |

## Kontext 2N

Conductor je v 2N **plánovaný** pro centrální agentní flow. **Nasazený není.** Dokud 2N
nezveřejní vlastní setup:

- Ber tento návod jako preview. Týmové procesy na něm zatím nestav.
- Připni verzi a po každém upgradu pusť na každém workflow znovu `conductor validate`.
- Co se přenáší bez ohledu na nástroj: rozřež práci na kroky, každému kroku dej co nejméně
  nástrojů, které potřebuje, a nech každý krok vracet typovaná pole.
- Agenti Conductoru **nedostávají** Copilot instrukce tohoto repa, pokud nepředáš
  `--workspace-instructions`. Jestli se hooky a skilly repa načítají uvnitř agentních
  sessions Conductoru, se neověřovalo; nespoléhej tam na hook jako na pojistku.

## Kde to funguje: CLI, IntelliJ, cloud agent

| Prostředí | Funguje? | Poznámky |
|-----------|----------|----------|
| **Terminál**, vedle Copilot CLI | ✅ Ano | Samostatný nástroj. Používá přihlášení Copilota a jeho agenti čerpají tvůj Copilot plán |
| **Plugin pro IntelliJ IDEA** | ⚠️ Jen terminál | Žádná integrace. YAML uprav v IDE, `conductor` pusť v jeho terminálu |
| **Copilot cloud agent** | ❌ Ne | Conductor není součástí Copilota. Běží tam, kam ho nainstaluješ |

## Když něco nefunguje

- **`Model "gpt-4o" is not available.`** → nastav `runtime.default_model: auto`.
- **`references unknown tool '…'`** z `validate` → přidej nástroj do seznamu `tools:` na
  nejvyšší úrovni.
- **„SDK protocol version mismatch“** → Conductor starší než v0.1.47 s Copilot CLI
  1.0.113 nebo novějším (podle jeho changelogu). Nainstaluj připnutý tag.
- **`No such option: --silent`** → root volby patří před podpříkaz:
  `conductor --silent run …`.
- **Agent říká, že nemůže najít soubory** → spustil jsi `conductor` mimo kořen repozitáře.
  Prompty používají cesty relativní k němu.
- **Provider `copilot` není v `conductor doctor` připravený** → nejdřív se přihlas do
  Copilot CLI (`copilot login`), pak pusť `conductor doctor` znovu.
- **Nainstaloval jsi `conductor-cli` přes pip** → špatný balíček. Odeber ho a nainstaluj
  z git URL.
- **Report se mezi běhy liší** → to se čeká. Routování je deterministické; text uvnitř
  každého kroku ne. Zpřesni pole `output` a prompty.

---

Dál: [katalog cvičení](exercises.cs.md).

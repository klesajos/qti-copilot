> 🌍 Číst v jazyce: [English](09-validate-eval.md) | **Česky**

# Ukázka 9: Validace a evaly tvých customizací

## Co jsou validace a evaly?

Ukázky 1–8 customizace *staví*. Tahle je *kontroluje*.

Skill ani agent nejsou zadarmo. Session, která některý z nich použije, spotřebuje víc tokenů
a víc času (změřeno níže: se skillem `board-tests` zhruba o čtvrtinu až třetinu víc tokenů).
Otázka je, jestli **mění výsledek**. „Přišlo mi to lepší“ není odpověď, se kterou můžeš
přijít na gildu.

- **Validace** je statická a zadarmo: dají se soubory naparsovat, odpovídají schématu?
- **Eval** je unit test customizace: prompt (**stimulus**) plus **gradery**, které ohodnotí,
  co agent udělal. Pusť ho **s** customizací a **bez** ní a porovnej. Každý běh je skutečná
  Copilot session a taky se tak účtuje: v AI kreditech, nebo v premium requestech, podle
  tvého plánu (`copilot help billing`).

## Přehled nástrojů

Copilot CLI 1.0.114 **nemá příkaz `copilot eval` ani příkaz `copilot plugin validate`**.
Evaluace žije v samostatných nástrojích:

| Nástroj | Co to je | K čemu ho použít | Stav |
|---------|----------|------------------|------|
| **Vally CLI** (`@microsoft/vally-cli`, MIT) | Eval engine. Prožene stimulus Copilot SDK session a výsledek ohodnotí | Skilly, agenti, experimenty s/bez. **Používá se v tomto repu** | npm balíček, tady připnutý na 0.21.0 |
| **GitHub Copilot Evals** (`eval@github-copilot-evals`) | Plugin: příkazy `/eval` a skilly nad stejným enginem | Psaní evalů v konverzaci. Volitelné demo níže | Public preview od 2026-11-17 |
| **Obyčejný skript s `copilot -p`** (`evals/plugin-ab.sh`) | Zhruba 70 řádků bashe a `jq` | To, co dokumentace Vally nepokrývá: plugin jako celek, hooky | Je tvůj, uprav si ho |

Pokud znáš `claude plugin eval` z Claude Code, mapuje se to takhle:

| Claude Code | Tady |
|-------------|------|
| `claude plugin validate` | Žádný příkaz. `jq`, kontrola schématu přes `ajv`, `npm run eval:lint` |
| `claude plugin eval` (Δ pro jeden skill) | `vally experiment run` s maticí nad `/environment/skills` |
| `claude plugin eval` (Δ pro plugin) | `evals/plugin-ab.sh` |
| `case.yaml` + `prompt.md` + `graders/*.md` | Jeden `eval.yaml`: stimuly i s jejich gradery |
| `setup.sh` + `fixture/` | `agent_environment.files` |
| Grader s `arm: with-only` | Kontrola, která se nepočítá do skóre (`used_plugin_agent` ve skriptu) |
| `--max-cost-usd` | Ve Vally nic. `--max-ai-credits` jen ve skriptu s `copilot -p` |
| Hermetický sandbox | Ve výchozím stavu **neběží v sandboxu** (viz „Na čem se spálíš“) |

## Co dělá tahle ukázka

```
package.json                         ← pins the engine; npm run eval:lint | eval | eval:ab
.vally.yaml                          ← where specs and results live
evals/
├── board-tests/eval.yaml            ← skill eval: positive case + negative control
├── game-explorer/eval.yaml          ← agent eval: was it delegated to?
├── experiments/
│   └── board-tests-ab.experiment.yaml   ← the same skill eval, with and without the skill
├── plugin-ab.sh                     ← whole-plugin A/B on plain copilot -p
└── results/                         ← gitignored
```

Všechny čtyři se opravdu spustily. Čísla jsou v části „Co ukázaly běhy“.

## Nejdřív validuj zadarmo

Nic z toho nevolá model. Spusť to před každým evalem a při každém review.

```bash
# 1. The JSON parses (prints nothing when all is well)
jq empty marketplace.json plugins/2048-dev/plugin.json .github/copilot/settings.json .github/hooks/hooks.json

# 2. plugin.json matches the Agent Plugins 1.0 schema
curl -fsSL https://agent-plugins.org/schemas/1.0.0/plugin.schema.json -o /tmp/plugin.schema.json
npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s /tmp/plugin.schema.json -d "plugins/*/plugin.json"

# 3. Eval specs and SKILL.md files are well-formed
npm ci                                   # once, at the repo root
npm run eval:lint
npx --no vally lint .github/skills

# 4. The experiment resolves to the plan you expect
npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
```

Výstup na tomto repu:

```text
plugins/2048-dev/plugin.json valid
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid
✅ board-tests (2/2 checks passed)
Experiment: board-tests-ab
Baseline:   skills=without
Plans:      2
```

Krok 2 je stejná kontrola, jakou pouští startovací šablona GitHubu pro pluginy. URL schématu
nech na `1.0.0`; URL s `1.1.0` vracela v době psaní tohoto návodu 404.

Co tyhle kontroly **nezachytí**: customizaci, která se načte, ale nic užitečného nedělá.
Co session doopravdy načetla, zjistíš uvnitř ní přes `/env`, mimo ni přes
`copilot skill list --json` a `copilot instruction list --json`.

## Soubory řádek po řádku

### `evals/board-tests/eval.yaml`

```yaml
name: board-tests
description: Does the board-tests skill make Copilot write board tests the way this project does?
type: capability
defaults:
  executor: copilot-sdk
  runs: 2
  timeout: 5m
```

`description` říká, jaké tvrzení se testuje. `copilot-sdk` je vestavěný executor Vally: každý
trial je skutečná Copilot session řízená přes SDK. `runs` je počet trialů na stimulus.
**`model:` tu záměrně není**; dry run ukáže `Model: (unset)` a model vybere Copilot. Pro
konkrétní běh ho připneš přes `--model <model-id>`.

```yaml
agent_environment:
  skills:
    - ../../.github/skills/board-tests
  files:
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
```

Každý trial začíná v čistém workspace, ve kterém je jen to, co je vyjmenované tady. Cesty
jsou relativní k souboru evalu. `skills` je testovaný skill; `files` je fixture, jeden
zdrojový soubor.

**Žádné `.github/` se do workspace nechystá, a právě o to jde.** Podle dokumentace Vally
načítá executor `copilot-sdk` i složky se skilly, které najde *ve workspace*, takže
deklarovaný seznam je „spodní hranice, ne přesná množina“. Nachystej tam `.github/` a skill
má i baseline rameno.

```yaml
stimuli:
  - name: game-over-edge-case
    prompt: >-
      Write a unit test for the 2048 board: a full board that still contains two equal
      neighbours must not be reported as game over. Follow this project's test conventions.
      This workspace has no build tool, so do not try to compile or run anything.
    tags:
      control: positive
      suite: smoke
```

**Pozitivní** stimulus. Skill nikde nejmenuje; skill se musí spustit sám.
Tagy jsou volné štítky; vybírá se podle nich přes `--tag suite=smoke`.
Míří na záměrný bug 2, takže správný test na současném kódu selže. Poslední věta brání
agentovi propálit timeout na chybějícím Gradle wrapperu.

| Grader | Proč tu je |
|--------|------------|
| `completed` | Session skončila normálně. Bez něj můžou ostatní gradery hodnotit pád |
| `file-exists` `…/BoardTest.kt` | Test skončil tam, kde projekt drží testy desky |
| `file-matches` ``fun `[^`]+`\(\)`` | Název testu je věta ve zpětných apostrofech |
| `file-matches` `boardOf\(` | Deska se staví deterministickým helperem projektu |
| `file-matches` `assertFalse\(` | Správná aserce zůstala, i když na ní současný kód selže |

```yaml
  - name: unrelated-question
    prompt: >-
      In two sentences, what does slideLineLeft return and what does it do to its argument?
      Answer in chat only; do not create or change any file.
    tags:
      control: negative
      suite: smoke
```

**Negativní kontrola**: stejný kód, žádný test se nechce.

| Grader | Proč tu je |
|--------|------------|
| `completed` | Jako výše |
| `skill-invocation` `disallowed: [board-tests]` | Skill, který se spouští na všechno, stojí kontext a nic nepřináší |
| `output-matches` `(?i)score` | Otázka byla zodpovězena (funkce vrací získané skóre) |
| `diff-empty` | Nic se nezapsalo |

`scoring: threshold: 1` znamená, že trial projde, jen když projdou **všechny** jeho gradery.
Čtyři z pěti je neúspěch (skóre 0,8). Všechny gradery jsou tu deterministické; žádný
nepotřebuje model soudce.

### `evals/experiments/board-tests-ab.experiment.yaml`

Celý soubor, s komentáři doplněnými pro tento návod:

```yaml
name: board-tests-ab
evals:
  - ../board-tests/eval.yaml          # which specs to run
matrix:
  skills:                             # one axis, named "skills"
    path: /environment/skills         # the field of the eval it overrides
    values:
      - without: []                   # the array is replaced: no skill at all
      - with: ["../../.github/skills/board-tests"]
baseline:
  skills: without                     # the arm every other arm is compared to
```

Jedna osa se dvěma hodnotami dá dvě varianty, `skills=without` a `skills=with`.
Všechno ostatní je stejné. Cena: 2 varianty × 2 stimuly × 2 běhy = **8 sessions**.

### npm skripty

| Skript | Spouští | Cena |
|--------|---------|------|
| `npm run eval:lint` | `vally lint -e evals` | Zadarmo |
| `npm run eval -- -e <spec>` | `vally eval --output-dir evals/results` nad jedním specem | Jedna session na stimulus a běh |
| `npm run eval:ab` | `vally experiment run evals/experiments/board-tests-ab.experiment.yaml` | 8 sessions |

Oba placené skripty nastavují `EVALUATE_USE_HOST_COPILOT_HOME=1` (použije se tvoje přihlášení
z Copilot CLI) a `VALLY_TELEMETRY_OPTOUT=1`. `package.json` připíná engine přesně na `0.21.0`.

Výsledky skončí v `evals/results/<timestamp>/`:

```
report.md                              ← experiment summary (eval-results.md for a single eval)
skills=with/results.jsonl              ← one line per trial, with each grader's evidence
skills=with/board-tests/<stimulus>/default-model/<trial>/
├── events.jsonl                       ← the full session event stream
└── workspace.patch                    ← what the agent changed
```

### `evals/game-explorer/eval.yaml`

Agent se dodává uvnitř pluginu `2048-dev`, jenže dokumentace Vally pokrývá projektové agenty,
ne nainstalované pluginy. Eval proto **nachystá soubor agenta do workspace jako projektového
agenta**:

```yaml
agent_environment:
  files:
    - src: ../../plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md
      dest: .github/agents/game-explorer.agent.md
    # … plus the six source files of the keypress chain
```

```yaml
      - type: tool-calls
        config:
          required:
            - name: "^task$"
              args:
                agent_type: "game-explorer"
```

Copilot deleguje přes nástroj jménem `task`; zvolený agent je jeho argument `agent_type`.
Grader ověřuje přesně tohle volání. Když je agent nachystaný jako projektový, jeho id je
`game-explorer`, ne `2048-dev:game-explorer`.

V promptu stojí *„Delegate to the game-explorer agent“*. To je **vynucená delegace**: testuje,
jestli agent odvede svou práci, když je zavolán, ne jestli by k němu model sám routoval.
Dva gradery `output-matches` (`keys\.ts`, `GameService`) kontrolují trasu a `diff-empty`
kontroluje, že agent zůstal read-only. Vybírej vzory, které obsahuje jen *správná* odpověď:
`Board.move` je už v promptu, takže by mu vyhověla i odpověď „I cannot find Board.move“.

### `evals/plugin-ab.sh`

Otázka, na kterou Vally neodpovídá: **změní instalace pluginu výsledek?**

| Řádky | Co se děje |
|-------|------------|
| `prompt=` | Skutečný úkol (vystopovat šipku doleva až k `Board.move`). Žádá o delegování „if a specialised code-exploration agent is available“, aniž by plugin jmenoval |
| `grade()` | Čte události `assistant.message` a závěrečný řádek `result` z JSONL streamu. Tři kontroly: jmenuje `keys.ts`, jmenuje `GameService`, žádný soubor se nezměnil |
| `used_plugin_agent()` | Hledá volání nástroje `task`, jehož `agent_type` obsahuje `game-explorer`. **Neboduje se**: baseline ji z principu splnit nemůže |
| `git archive HEAD engine api web` | Každý běh dostane čistou kopii jen zdrojáků aplikace. Žádné `.github/`, takže skilly, agenti a hooky repa nemůžou prosáknout ani do jednoho ramene. Archivuje se `HEAD`: necommitnuté změny v kopii nejsou |
| `args=(…)` | `--output-format json`, `--no-ask-user`, `--no-auto-update`, `--disable-builtin-mcps`, `--max-ai-credits 30`. Žádné `--allow-tool`: v režimu `-p` se volání, které potřebuje schválení, zamítne, a úkol jen čte |
| `--plugin-dir "$plugin"` | Přidává se jen v rameni `with`. Tohle je jediný rozdíl mezi rameny |
| `COPILOT_PLUGIN_DIR_ONLY=true` | Nastavené v obou ramenech. Podle `copilot help environment` vypíná automatické hledání pluginů, takže se načtou jen pluginy z `--plugin-dir`. Tvoje osobní skilly a agenti v `~/.copilot` se načítají dál, v obou ramenech stejně |
| `\|\| true` | I spadlý běh se ohodnotí, jako neúspěch |

## Co ukázaly běhy

**A/B skillu** (`npm run eval:ab`, dvě spuštění, CLI 1.0.114, Vally 0.21.0):

| | Bez skillu | Se skillem |
|---|---|---|
| `game-over-edge-case` (pozitivní) | prošlo **0 ze 4** trialů | pod opraveným graderem prošly **3 ze 4** trialů (2 ze 4 podle tehdejšího hodnocení; viz níže) |
| `unrelated-question` (negativní) | 4 ze 4 | 4 ze 4 |
| Tokeny | baseline | zhruba o 26–32 % víc |
| Čas běhu | baseline | zhruba o 51–67 % víc |

Čti to s těmihle výhradami:

- **Čtyři trialy na buňku, jeden model** (ten, na který se `auto` na testovacím účtu
  přeložilo). Je to signál, ne měření. Seznam modelů v 2N je jiný; pusť si to tam znovu.
- **V čem se baseline spletla:** helper `boardOf(` chyběl ve 4 ze 4 trialů, camelCase název
  testu místo věty ve zpětných apostrofech byl ve 2 ze 4. Samotná aserce byla v pořádku.
- **Baseline je znevýhodněná kvůli fixture.** Ve workspace je jen `Board.kt`, ne existující
  `BoardTest.kt`, kde je `boardOf` definovaný. V reálném repu si agent ten soubor přečte
  a konvence okopíruje i bez skillu. Eval ukazuje, že skill konvence *přenáší*; přeceňuje
  ale, co skill přidává v tomto repu.
- **Jediný neúspěch se skillem** neměl s konvencemi nic společného: agent zapsal test na
  cestu mimo workspace trialu, takže selhal `file-exists` i všechny souborové gradery.
- **Jeden grader byl při prvním běhu špatně.** Byl to `assertFalse\([^)]*isGameOver\(\)`
  a shodil správný test, který si výsledek nejdřív uložil do proměnné
  (`val gameOver = board.isGameOver()` … `assertFalse(gameOver)`), tedy přesně to
  Arrange-Act-Assert, které skill chce. Vzor se uvolnil na `assertFalse\(`.
  Ty 3 ze 4 počítají tenhle trial podle současného vzoru; uložený report onoho běhu ho
  ukazuje jako neúspěch, takže dva uložené reporty dávají dohromady 2 ze 4.
- **Skill není zadarmo:** o čtvrtinu až třetinu víc tokenů a o polovinu až dvě třetiny
  víc času.
- Negativní kontrola obstála v 8 z 8 trialů: skill se na nesouvisející otázku nespustil.

**Eval agenta** (`npm run eval -- -e evals/game-explorer/eval.yaml`): prošel 1 z 1.

**A/B pluginu** (`RUNS=1 evals/plugin-ab.sh`, jeden běh na rameno):

| Rameno | Splněné kontroly výsledku | Kdo dělal trasu |
|--------|---------------------------|-----------------|
| `without` | 3 ze 3 | Vestavěný agent `explore` |
| `with` | 3 ze 3 | `2048-dev:game-explorer` |

**Výsledek byl stejný. Plugin změnil, kdo práci udělal, ne co z ní vzešlo.** To je užitečné
zjištění, ne nepovedený eval. Říká, že vestavěný agent tenhle úkol zvládá už teď, takže
„lepší trasy“ není tvrzení, které si tenhle plugin může dovolit. Pokud je jeho hodnota jinde
(striktně read-only seznam nástrojů, pevný formát výstupu), napiš kontrolu na *to* a změř
to. Jeden běh na rameno je málo; závěr zní „rozdíl jsme neviděli“, ne „rozdíl neexistuje“.

## Mapování graderů

| Grader v Claude Code | Grader ve Vally | Poznámky |
|----------------------|-----------------|----------|
| `llm` | `prompt` | LLM soudce. Potřebuje model soudce |
| `tool_used` | `tool-calls`, `skill-invocation` | `required` / `disallowed`; `tool-calls` umí porovnávat i argumenty |
| `regex` | `output-matches` | Nad finální odpovědí agenta |
| `file_exists` | `file-exists` | |
| — | `file-matches` | Regex nad souborem ve workspace |
| — | `diff-empty` | Workspace se nezměnil |
| — | `completed` | Session skončila normálně |

LLM soudce je volitelný. Úryvek níže vychází z dokumentace Vally a projde `vally lint`;
tady se **nespouštěl**:

```yaml
  - name: game-over-edge-case
    prompt: …
    rubric:
      - The test builds a full board that contains at least one pair of equal neighbours
      - The test asserts that this board is not game over, and does not weaken the assertion
    graders:
      - type: prompt
        config:
          scoring: binary
          evidence: [trajectory, diff]
```

Soudce je volání modelu, takže jeho model musí být na allow-listu tvé organizace. Výchozí
model soudce ve Vally na testovacím účtu **nebyl dostupný** a `--compare` kvůli tomu selhalo.
Předej `--judge-model <model-id>`, nebo gradery se soudcem a `--compare` vynech.
Pozor na rozsah toho flagu: u `vally eval` nastavuje soudce pro gradery `prompt`; u
`vally experiment run` nastavuje jen soudce pro `--compare`.

## Na čem se spálíš

- **Tvoje osobní skilly prosakují do trialů.** `EVALUATE_USE_HOST_COPILOT_HOME=1`
  zpřístupní celý tvůj Copilot home. V reálných bězích se osobní skill `tdd` zavolal
  v *baseline* rameni. Zkontroluj to přes `copilot skill list --json` (každý řádek, jehož
  `source` není `project`) a co by mohlo rušit, vypni přes `copilot skill disable <name>`.
  Pro reprodukovatelné běhy doporučuje dokumentace autentizaci tokenem: fine-grained PAT
  s oprávněním „Copilot Requests“ v `COPILOT_GITHUB_TOKEN` (tady netestováno; organizace
  musí takové tokeny povolit).
- **Trialy neběží v sandboxu.** Jeden trial zapsal soubor mimo svůj workspace. Nedávej do
  stimulu destruktivní úkoly. `vally eval --help` uvádí `--backend docker`; netestováno.
- **Výsledky obsahují tvoje prompty a výstup nástrojů**, včetně obsahu souborů.
  `evals/results/` je v gitignore. Než report někam vložíš, přečti si ho.
- **Telemetrie je ve výchozím stavu zapnutá**, a to ve Vally. npm skripty nastavují
  `VALLY_TELEMETRY_OPTOUT=1`; když voláš `npx vally` přímo, nastav si ho sám.
- **Vally nemá žádný strop na spotřebu.** Sessions = varianty × stimuly × běhy a `vally eval`
  k tomu ve výchozím stavu přidá až dvě opakování na stimulus (`--max-retries`). Dokud
  iteruješ, drž `runs` nízko. Omezit session umí jen skript s `copilot -p`
  (`--max-ai-credits 30`: minimum, měkký limit, sdílený se subagenty). Kolik běh skriptu
  stál, zjistíš z posledního řádku jeho `events.jsonl`: na testovacím účtu nesl záznam
  `result` pole `usage.premiumRequests`. Jestli uvidíš AI kredity, nebo premium requesty,
  záleží na tvém plánu.
- **Exit kód 0 neznamená „prošlo“.** Podle `--help` končí neúspěšné verdikty nenulovým
  kódem jen s `--require-pass`.

## Vytvoř si vlastní eval, krok za krokem

1. **Sepiš si jedno tvrzení.** „S tímhle skillem Copilot pojmenovává testy jako věty.“
   Bez tvrzení není eval.
2. **Zkopíruj spec:** `mkdir evals/my-skill && cp evals/board-tests/eval.yaml evals/my-skill/`.
3. **Nachystej nejmenší možnou fixture** pod `agent_environment.files`. Jen zdrojáky
   aplikace; nikdy `.github/`.
4. **Napiš jeden pozitivní stimulus** tak, jak by se zeptal uživatel. Skill nejmenuj.
5. **Napiš jednu negativní kontrolu:** příbuzný požadavek, u kterého má skill zůstat zticha.
6. **Nejdřív přidej deterministické gradery.** Jeden na každou konvenci, kterou tvrdíš.
   Vybírej vzory, které obsahuje jen správný výsledek.
7. **Lint:** `npm run eval:lint`.
8. **Pusť jeden trial:** `npm run eval -- -e evals/my-skill/eval.yaml --runs 1`.
9. **Otevři `workspace.patch` a `events.jsonl` neúspěšného trialu**, než graderu uvěříš.
   Mýlit se může agent, ale i grader (viz výše).
10. **Zkopíruj soubor experimentu**, nasměruj ho na svůj eval a skill, zkontroluj ho přes
    `--dry-run` a pak ho spusť. K číslům vždycky uveď i počet trialů.

## Vyzkoušej demo

Potřebuješ: přihlášené Copilot CLI, Node 24.15+, `npm ci` v kořenu repa, pro skript `jq`.

1. Spusť bezplatný blok z části „Nejdřív validuj zadarmo“.
2. `npm run eval -- -e evals/game-explorer/eval.yaml` (jedna session). Otevři
   `eval-results.md` v nejnovější složce `evals/results/<timestamp>/`.
3. `npm run eval:ab` (osm sessions). Otevři `report.md` a porovnej svá čísla s tabulkou
   výše. Pak spusť `copilot skill list --json` a polož si otázku, které z tvých osobních
   skillů se zúčastnily.
4. `RUNS=1 evals/plugin-ab.sh` (dvě sessions). Který agent dělal trasu v kterém rameni?

## Volitelné parametry

| Flag | Co dělá |
|------|---------|
| `-e, --eval-spec <path>` | Soubor evalu, který se má spustit (lze opakovat) |
| `--runs <n>` | Počet trialů na stimulus; přebíjí `defaults.runs` |
| `--model <model-id>` | Model pro testovaného agenta |
| `--tag <key=values>` | Spustí jen odpovídající stimuly, např. `--tag control=positive` |
| `--require-pass` | Skončí nenulovým kódem, když některý verdikt neprojde |
| `--max-retries <n>` | Počet opakování na stimulus (výchozí 2) |
| `--workers <n>` | Počet souběžných sessions (výchozí 5) |
| `--judge-model <model-id>` | `vally eval`: model pro gradery `prompt`. `experiment run`: model jen pro soudce `--compare` |
| `--junit` | Zapíše navíc report v JUnit XML |
| `experiment run --dry-run` | Vypíše vyhodnocený plán a nic nespustí |
| `experiment run --variant <name>` | Spustí jen jedno rameno |
| `experiment run --compare` | Nechá LLM soudce porovnat každé rameno s baseline. Stojí tokeny |

## GitHub Copilot Evals (volitelné demo)

Front end přímo od GitHubu. Všechno v téhle části je **podle jeho dokumentace; pro tohle repo
se nic neinstalovalo ani nespouštělo**.

```bash
copilot plugin marketplace add github/evals
copilot plugin install eval@github-copilot-evals
```

- **Experimentální režim.** `/eval setup|create|review|improve|run|compare` ho vyžadují
  (`/settings experimental on`). Bez něj funguje šest skillů pluginu dál, když je požádáš
  běžnou řečí.
- **Vlastní MCP server.** Plugin přináší MCP server `copilot-evals`. Pod MCP allow-listem je
  každý server mimo výchozí sadu blokovaný, dokud ho někdo neschválí, a výjimku pro tenhle
  nic nedokumentuje. V 2N počítej s tím, že bude blokovaný, dokud nebude na seznamu. Se
  zablokovaným serverem a vypnutým experimentálním režimem umí plugin soubory evalů
  navrhnout, ale ne spustit. Záloha je vždycky `npm run eval` v terminálu.
- **Předpoklady:** Node.js 24, `@microsoft/vally-cli` 0.21.0, Copilot CLI 1.0.85 nebo
  novější, Git 2.28 nebo novější.
- **Licence.** GitHub Limited Use Source License: source-available, ne open source.
  Interní použití je povolené; nechat si platit za jeho provozování pro třetí stranu ne.
  Proto **v tomto repu nikdy není vendorovaný** a instaluješ si ho sám. Vally CLI je pod MIT.
- **Vedlejší efekty.** `/eval setup` zapisuje `.vally.yaml`; potom zkontroluj
  `git diff .vally.yaml`. Výsledky jdou do `.copilot/evals/results` (tady v gitignore).
  Jeho telemetrie je ve výchozím stavu zapnutá; vypne ji `COPILOT_EVALS_TELEMETRY=off`.
- **Co zatím neumí:** ověřené srovnání s/bez (`/eval compare` je jeden skill, jeden případ,
  jeden pokus na rameno, bez srovnávacího reportu); opakované trialy nebo LLM soudce ve
  výchozím profilu; evaluaci hooků, souborů s instrukcemi nebo nainstalovaného pluginu jako
  celku. Na to použij soubory v tomto repu.

Vychází několikrát denně a jeho stránky si navzájem odporují. Za zdroj pravdy ber
[github.com/github/evals](https://github.com/github/evals) a v den, kdy ho použiješ, si ho
přečti znovu.

## Evaly v CI (v tomto repu nenastaveno)

Podle dokumentace `github/evals-action@v0` zlintuje specy, spustí pojmenovanou Vally suite
a přidá jeden komentář k PR. Potřebuje suite v `.vally.yaml` (tohle repo žádnou nedefinuje),
oprávnění jobu `copilot-requests: write`, Actions policy, která akci povolí, a organizační
policy „Allow use of Copilot CLI billed to the organization“. Spotřeba se účtuje organizaci
a běží to jen na GitHub-hosted runnerech s Linuxem x64. V 2N je to rozhodnutí adminů,
takže tohle repo pro to žádný workflow nemá.

## Kde to funguje: CLI, IntelliJ, cloud agent

| Prostředí | Funguje? | Poznámky |
|-----------|----------|----------|
| **Copilot CLI** (terminál) | ✅ Ano | Vally i skript běží vedle CLI a používají jeho přihlášení |
| **Plugin pro IntelliJ IDEA** | ⚠️ Jen terminál | Žádné UI pro evaly. npm skripty spouštěj v terminálu IDE. Copilot Evals JetBrains mezi hostiteli neuvádí (podle jeho dokumentace) |
| **Copilot cloud agent** | ❌ Ne | Nic z toho cloud agenta neevaluuje. Cesta přes CI je `evals-action`, není nastavená |

## Když něco nefunguje

- **`vally: command not found`** → spusť `npm ci` v kořenu repa a používej npm skripty
  nebo `npx --no vally`.
- **Chyba autentizace v trialu** → zavolal jsi `vally` přímo bez
  `EVALUATE_USE_HOST_COPILOT_HOME=1`, nebo Copilot CLI není přihlášené.
- **`--compare` nebo grader `prompt` selže na modelu** → výchozí model soudce není na tvém
  allow-listu. Předej `--judge-model <model-id>`.
- **Baseline rameno používá skill, který jsi tam nenachystal** → prosákl osobní skill. Viz
  „Na čem se spálíš“.
- **`file-exists` selže, ale agent tvrdí, že soubor zapsal** → zapsal ho mimo workspace.
  Přečti si `workspace.patch` a `events.jsonl` toho trialu.
- **Rameno se skillem není o nic lepší** → skill se nespustil (zkontroluj sloupec Skills
  v `report.md`), nebo je baseline dobrá už sama. Obojí znamená, že si skill na tomhle
  úkolu na svou cenu nevydělá.
- **Skóre mezi běhy skáče** → variance modelu. Než z toho něco vyvodíš, zvyš `runs`.
- **`plugin-ab.sh` ignoruje tvou poslední změnu** → archivuje `HEAD`. Nejdřív commitni.

---

Dál: [Ukázka 10: Práce na úrovni 5 a výš](10-level-5-workflow.cs.md).

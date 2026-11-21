> 🌍 Číst v jazyce: [English](09-evals.md) | **Česky**

# 09 · Evaly: dokaž, že skill nebo plugin pomáhá

> ⏱ 20 min (5 demo + 15 [cvičení 8](exercises.cs.md)) · Dokumentace: [Vally](https://microsoft.github.io/vally/) · [Eval Spec Reference](https://microsoft.github.io/vally/reference/eval-spec/) · [GitHub Copilot Evals](https://github.github.io/evals/) · Ověřeno na Copilot CLI 1.0.114, Vally CLI 0.21.0

## Co je eval?

Skill, agent nebo plugin je hypotéza: „s tímhle Copilot udělá úkol líp“. Stojí tokeny a čas
v každé session, která ho načte. **Eval** ji otestuje: prompt (**stimulus**) plus **gradery**,
které ohodnotí, co agent udělal, spuštěné **s** přizpůsobením a **bez** něj. Rozdíl je důkaz. Každý
trial je skutečná, účtovaná Copilot session. Práci odvedou tři nástroje:

| Nástroj | Co to je | V tomto repu |
|---|---|---|
| **Vally CLI** (`@microsoft/vally-cli`, MIT) | Engine: pustí stimulus přes session Copilot SDK a ohodnotí výsledek | Používá se. Připnutý na `0.21.0` v `package.json` |
| **GitHub Copilot Evals** (`eval@github-copilot-evals`) | Plugin s příkazy `/eval` a skilly jako front end k Vally. [Public preview](https://github.blog/changelog/2026-11-17-github-copilot-evals-is-now-in-public-preview/) od 2026-11-17 | Není přibalený v repu (licence source-available); nainstaluj z [github/evals](https://github.com/github/evals). `/eval` potřebuje experimentální režim. Přináší vlastní MCP server `copilot-evals`: počítej s tím, že ve 2N bude blokovaný, dokud nebude na seznamu schválených |
| **Obyčejný skript s `copilot -p`** (`evals/plugin-ab.sh`) | 73 řádků bashe a `jq` | Používá se na to, co Vally nepokrývá: celý plugin jako jeden celek |

## Co dělá tahle ukázka

```
package.json, .vally.yaml                 ← Vally version; scripts eval:lint, eval, eval:ab; paths
evals/
├── board-tests/eval.yaml                 ← skill eval: a positive case and a negative control
├── game-explorer/eval.yaml               ← agent eval: was the agent delegated to?
├── experiments/board-tests-ab.experiment.yaml   ← that eval twice: without and with the skill
├── plugin-ab.sh                          ← whole-plugin A/B on plain copilot -p
└── results/                              ← gitignored: holds your prompts and tool output
```

## Soubor řádek po řádku

Pro každý trial Vally zkopíruje do prázdného workspace to, co uvádí spec, pustí na stimulus jednu
Copilot session a pak ohodnotí stream událostí a soubory. `evals/board-tests/eval.yaml`, zkráceno
(komentáře jsou přidané pro tenhle návod a říkají, co se vystřihlo):

```yaml
defaults:
  executor: copilot-sdk     # each trial is a real Copilot session, driven through the SDK
  runs: 2                   # trials per stimulus. No model key: Copilot picks the model
agent_environment:          # everything a trial workspace contains; paths relative to this file
  skills:
    - ../../.github/skills/board-tests        # the skill under test
  files:                                      # the fixture: one source file, and no .github/
    - src: ../../engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
      dest: engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt
stimuli:
  - name: game-over-edge-case                 # positive case: the prompt never names the skill
    prompt: >-
      Write a unit test for the 2048 board: … Follow this project's test conventions.
      This workspace has no build tool, so do not try to compile or run anything.
    graders:                                  # cut: completed, file-exists on the path below
      - type: file-matches                    # three of these, one per convention: the backtick
        config:                               # test name (shown), 'boardOf\(', 'assertFalse\('
          path: engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt
          pattern: 'fun `[^`]+`\(\)'
  - name: unrelated-question                  # negative control (prompt cut): asks a question
    graders:                                  # cut: completed, output-matches, diff-empty
      - type: skill-invocation                # the skill must stay quiet
        config:
          disallowed: [board-tests]
scoring:
  threshold: 1                                # a trial passes only if every grader passes
```

Proč žádné `.github/`: executor načte i skilly, které najde ve workspace, takže by skill dostala
i větev baseline. Žádný grader nepotřebuje model soudce. Soubor experimentu pustí spec znovu,
jednou pro každou variantu, a změní jedno pole; 2 varianty × 2 stimuly × 2 běhy = **8 sessions**:

```yaml
matrix:
  skills:
    path: /environment/skills            # the field of the spec this axis overrides
    values:
      - without: []                      # the skills list is replaced by an empty one
      - with: ["../../.github/skills/board-tests"]
baseline:
  skills: without                        # the arm every other arm is compared to
```

## Vytvoř si vlastní, krok za krokem

1. Napiš si jedno tvrzení: „S tímhle skillem Copilot pojmenovává testy jako věty.“ Bez tvrzení není eval.
2. `mkdir evals/my-skill && cp evals/board-tests/eval.yaml evals/my-skill/`. Změň `name`,
   `description` a `agent_environment`: tvůj skill, co nejmenší fixture, nikdy `.github/`.
3. Napiš jeden pozitivní stimulus tak, jak by se zeptal uživatel, bez jména skillu, a jednu
   negativní kontrolu. Na každou konvenci, kterou skill uvádí, přidej jeden deterministický grader.
4. `npm run eval:lint`, pak jeden trial: `npm run eval -- -e evals/my-skill/eval.yaml --runs 1`.
   Než graderu uvěříš, přečti si `workspace.patch` trialu, který neprošel: grader se může mýlit.
5. Zkopíruj soubor experimentu; `evals` a hodnotu `with` nasměruj na své. Svůj soubor pusť
   nanečisto příkazem z dema níže. Pro placený běh dej před příkaz ještě
   `EVALUATE_USE_HOST_COPILOT_HOME=1` a místo `--dry-run` napiš `--output-dir evals/results`.

## Vyzkoušej demo

```console
$ npm run eval:lint
✔ evals/board-tests/eval.yaml is valid
✔ evals/game-explorer/eval.yaml is valid
$ VALLY_TELEMETRY_OPTOUT=1 npx --no vally experiment run evals/experiments/board-tests-ab.experiment.yaml --dry-run
Baseline:   skills=without
Plans:      2
$ npm run eval:ab
```

Nejdřív jednou spusť `npm ci` (Node 24.15+ nebo 26+). Lint a dry-run nevolají žádný model;
`eval:ab` je 8 skutečných sessions. Výstup je zkrácený. Běh končí tabulkou: úspěšné stimuly, tokeny
a čas pro každou větev. V `evals/results/<timestamp>/` má `report.md` řádek pro každou variantu a
stimulus (`Skills` ukazuje, který skill se spustil); složka každého trialu obsahuje `events.jsonl`
a `workspace.patch` (jeho změny).

## Jak číst výsledek

| Zaznamenáno tady: 2 běhy `eval:ab`, 4 trialy na buňku, model `auto` | Bez skillu | Se skillem |
|---|---|---|
| `game-over-edge-case` (pozitivní) | prošlo **0 ze 4** trialů | prošly **3 ze 4** trialů |
| `unrelated-question` (negativní kontrola) | 4 ze 4 | 4 ze 4 |
| Tokeny / reálný čas | baseline | +26–32 % / +51–67 % |

- **Baseline chybovala v konvencích, ne v logice:** žádný helper `boardOf(` ve 4 ze 4 trialů, název testu
  v camelCase ve 2 ze 4. Přesně tohle skill přidává, za cenu z posledního řádku.
- Neúspěšný trial se skillem zapsal svůj test mimo svůj workspace. Negativní kontrola obstála v 8 z 8.
- **Limity:** čtyři trialy na jednom modelu jsou signál, ne měření. Fixture vynechává existující
  `BoardTest.kt`, kde je `boardOf` definovaný, takže eval tady přínos nadsazuje.

**A/B test pluginu** (`RUNS=1 evals/plugin-ab.sh`: jedna session `copilot -p` na větev,
`--plugin-dir` jen ve větvi `with`): v obou větvích prošly 3 ze 3 kontrol výsledku. Bez pluginu
udělal trasování vestavěný agent `explore`; s ním `2048-dev:game-explorer`. **Plugin změnil, kdo
práci odvedl, ne výsledek.** Jestli je jeho hodnota jinde, napiš na to kontrolu a změř ji.

## Dvě pasti a cena

- **Osobní skilly prosakují do trialů.** npm skripty nastavují `EVALUATE_USE_HOST_COPILOT_HOME=1`,
  aby využily tvoje přihlášení do CLI. Tím se zpřístupní tvůj Copilot home: ve větvi baseline se
  spustil osobní skill `tdd`. Zkontroluj `copilot skill list --json`: řádky se `source` jiným než
  `project` nebo `builtin`.
- **Trialy neběží v sandboxu.** Jeden zapsal mimo svůj workspace. Žádné destruktivní stimuly.
- **Běh stojí** jednu session za každou kombinaci varianta × stimulus × běh, v AI kreditech nebo premium requestech
  (`copilot help billing`). Vally žádný strop na spotřebu nemá; má ho jen skript (`--max-ai-credits 30`).
- **Skill nebo plugin stojí kontext** v každé session: `/context` (po skillech v experimentálním režimu).

## Volitelné parametry

| Přepínač | U čeho | Co dělá |
|---|---|---|
| `--runs <n>` | `vally eval` | Počet trialů na stimulus; přebíjí `defaults.runs` |
| `--model <model-id>` | `vally eval` | Model pro testovaného agenta |
| `--require-pass` | oba | Při neúspěšném verdiktu skončí nenulovým exit kódem. Bez něj exit kód 0 neznamená „prošlo“ |
| `--dry-run`, `--variant <name>` | `vally experiment run` | Vypíše plán a nic nespustí; spustí jen jednu větev |

Kompletní reference: [CLI: eval](https://microsoft.github.io/vally/reference/cli/eval/) · [CLI: experiment](https://microsoft.github.io/vally/reference/cli/experiment/)

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|---|---|---|
| ✅ Vally i skript běží vedle CLI a využívají jeho přihlášení | ⚠️ Žádné UI pro evaly; npm skripty pusť v terminálu IDE | ❌ Nic z toho cloud agenta nevyhodnocuje |

## Copilot vs Claude Code

Claude Code: `claude plugin eval` ([Test plugins with evals](https://code.claude.com/docs/en/plugin-evals)).
Stejná myšlenka: případy, gradery, běh s pluginem a bez něj. Tam je to vestavěné v CLI a obecně
dostupné; tady je engine samostatný balíček a front end plugin v preview.

## Když něco nefunguje

- **Chyba autentizace v trialu** → `vally` běželo bez `EVALUATE_USE_HOST_COPILOT_HOME=1`, nebo je CLI odhlášené.
- **`file-exists` selže, ale agent tvrdí, že soubor zapsal** → zapsal ho mimo workspace; přečti si `events.jsonl`.
- **Větev se skillem není o nic lepší** → skill se nespustil (sloupec `Skills` v `report.md`), nebo je baseline dobrá už sama.

Dál: [10 · Víc než jedna session](10-orchestration.cs.md)

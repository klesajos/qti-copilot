> 🌍 Číst v jazyce: [English](03-skills.md) | **Česky**

# 03 · Skilly

> ⏱ 20 min (5 demo + 15 cvičení 2) · Dokumentace: [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) · [Agent skills](https://docs.github.com/en/copilot/concepts/customizations/agent-skills) · [Agent Skills specification](https://agentskills.io/specification) · Ověřeno na Copilot CLI 1.0.114

## Co je skill?

Složka se souborem `SKILL.md`: instrukce, které se načtou, **jen když je úkol potřebuje**. Soubory
s instrukcemi z [návodu 02](02-custom-instructions.cs.md) se aktivují podle session nebo cesty.
Skill se aktivuje podle úkolu: tvůj požadavek odpovídá jeho popisu, nebo napíšeš `/skill-name`.

Pod kapotou: při startu session dostane model název a popis každého zapnutého skillu, nic víc.
Načtení je volání nástroje. Model zavolá nástroj `skill` s názvem skillu a CLI vloží tělo
`SKILL.md` do konverzace.

## Co dělá tahle ukázka

```
.github/skills/           ← project skills, committed with the repo
└── board-tests/          ← one folder per skill; scripts it uses go next to SKILL.md
    └── SKILL.md          ← must be named exactly SKILL.md
```

`board-tests` učí Copilota, jak se v tomhle projektu píšou testy desky: kde leží, jak se jmenují,
který helper sestaví desku, jak spustit sadu testů a co dělat, když správný test selže.
Změřeno s ním a bez něj ([návod 09](09-evals.cs.md)): stejný úkol na psaní testu prošel
kontrolami v 0 ze 4 trialů bez skillu a ve 3 ze 4 s ním, za cenu o 26–32 % víc tokenů a
o 51–67 % víc času.

## Soubor řádek po řádku

```yaml
---
name: board-tests
description: Use when writing or extending JUnit tests for the 2048 board logic (slideLineLeft, Board.move, win and game-over detection). Covers the project's test conventions and how to run the suite.
---
```

- `name` je to, co píšeš za lomítko a co model předává nástroji `skill`. Nejvýš 64 znaků;
  používej malá písmena a spojovníky.
- `description` je jediná část, kterou model vidí, než se rozhodne. Tenhle popis je spouštěč („Use
  when ...“) poskládaný ze slov, která vývojář píše: `slideLineLeft`, `Board.move`, „game-over“.
  Nejvýš 1 024 znaků; s delším popisem se skill nenačte.
- Tělo je briefing: `## Conventions` (sedm odrážek, mezi nimi názvy testů ve zpětných apostrofech
  a helper `boardOf(...)`, který negeneruje náhodné dlaždice), `## Key API` (pět signatur, levnější
  než nechat Copilota otevřít `Board.kt`) a `## Running the tests` (`./gradlew :engine:test`).
- Nejdůležitější je poslední věta: „If a correct test fails because the production code is wrong,
  keep the assertion and report the bug.“ Bez ní je nejlevnější cesta k zelenému běhu změnit
  aserci. Správný test pro řádek `4, 4, 8, 0` dnes selže: to je nastražená chyba s kaskádovým slučováním.

## Vytvoř si vlastní, krok za krokem

1. Vytvoř složku, jednu na skill: `mkdir -p .github/skills/my-skill`
2. Vytvoř `.github/skills/my-skill/SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: Use when <the situation that should trigger it>. Covers <what it contains>.
   ---
   <A briefing for a new colleague: what to do, which files and APIs to use, how to verify the
   result, what to do when it fails.>
   ```
3. Načti ho přes `/skills reload` v otevřené session. `copilot skill list` ho ukáže pod „Project skills“.
4. Spusť ho ručně: `/my-skill <your request>`. Časová osa ukáže tvůj příkaz a pak volání
   nástrojů. Žádný řádek neříká, že se načetl skill.
5. Spusť ho popisem. Zformuluj požadavek tak, jak by to řekl kolega, bez názvu skillu:
   ```bash
   copilot -p "<a read-only request that should trigger it>" --trust-folder --no-ask-user \
     --output-format json \
     | jq -c 'select(.type=="tool.execution_start" and .data.toolName=="skill") | .data.arguments'
   ```
   Vypíše `{"skill":"my-skill"}`. Žádný výstup znamená, že popis neodpovídal. Požadavek nech
   jen pro čtení: v režimu `-p` se volání nástroje, které potřebuje schválení, zamítne.

Popis piš podle situace uživatele, ne podle obsahu: „Use when writing unit tests for ...“ skill
spustí, „Information about tests“ ne. Ve cvičení 2 napíšeš skill `api-endpoint`.

Skilly se načítají i z `.agents/skills/` a `.claude/skills/` (projektové), z `~/.copilot/skills/` a
`~/.agents/skills/` (osobní) a z pluginů (`/2048-dev:build-test`, [návod 07](07-plugins.cs.md)). Při
shodě názvů vyhrává první umístění, `.github/skills/` před všemi ostatními. `~/.claude/skills/` se nečte.

> 🔷 **Jen Copilot:** projektové skilly se načítají z `.github/skills/`, `.agents/skills/` a
> `.claude/skills/` a `copilot skill add <file|URL|directory>` skill nainstaluje. Claude Code má pro
> projektové skilly jen `.claude/skills/` a žádný příkaz, který by skill nainstaloval ze souboru nebo z URL.

## Vyzkoušej demo

Spusť čerstvou session přes `scripts/copilot-ws.sh` a zeptej se, aniž bys skill jmenoval:

> *„Jaké má tenhle projekt konvence pro testy desky? Odpověz v pěti odrážkách. Nevytvářej ani neměň žádný soubor.“*

První volání nástroje je `skill` s `board-tests`. Odpověď pak vyjmenuje, co říká skill:
názvy testů ve zpětných apostrofech, Arrange-Act-Assert, `slideLineLeft()` pro pravidla slučování,
`boardOf(...)` pro celé desky.

**Co to stojí:** do volání `skill` jen jeho popis. Popisy všech zapnutých skillů jsou
v každé session; `/context` ukazuje využití kontextu po kategoriích, v experimentálním režimu
i po skillech. Spočítej si, co tomu tvému konkuruje:
`copilot skill list --json | jq -r '[.[] | select(.enabled) | .description | length] | "\(length) skills, \(add) characters"'`

## Volitelné parametry

| Pole nebo příkaz | Co dělá |
|---|---|
| `allowed-tools` | Nástroje, které běží **bez dotazu**, dokud je skill aktivní. Předschválení, ne whitelist: neuvedené nástroje fungují dál a pořád se ptají. Ve skillu, který jsi nepsal, znamená `allowed-tools: shell` jakýkoli shellový příkaz bez ptaní |
| `argument-hint` | Text zobrazený ve výběru skillů, např. `"[test-name]"`. Jen nápověda: požadavek piš jako prózu za `/name` |
| `user-invocable: false` | Odebere příkaz `/name`. Skill může načíst jen model |
| `disable-model-invocation: true` | Model už skill sám nenačte. Spouštíš ho přes `/name` |
| `copilot skill add [--project] <file, URL or directory>` | Nainstaluje skill. `--project` zkopíruje soubor nebo URL do `.github/skills/` |
| `copilot skill disable <name>`, `enable <name>` | Vypne nebo zapne jeden skill |
| `/skills`, `/skills list`, `/skills info <name>`, `/skills reload` | Totéž uvnitř session. Samotné `/skills` otevře správce: Enter na řádku nabídne `Details` a `Disable`, záložka `Problems` vypisuje chyby načítání |
| `--dynamic-retrieval skills=on` | Přepínač při spuštění: vyhledávání skillů přes embeddingy. Volba se uloží; `skills=off` ji vrátí zpět |

Kompletní reference: [Skills reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference)

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|---|---|---|
| ✅ podle popisu i přes `/board-tests`, také v bězích s `-p` | ⚠️ režim agenta, od pluginu 1.10.0. Které projektové složky prohledává, není zdokumentováno | ✅ skilly používá i Copilot code review |

## Copilot vs Claude Code

Claude Code: skilly ve stejném formátu `SKILL.md` (otevřený standard Agent Skills), uložené
v `.claude/skills/`, které čte i Copilot. Klíče Claude Code `model`, `context: fork` a
`paths` v referenci Copilota nejsou. Claude Code dosazuje `$ARGUMENTS`; Copilot předá text za
`/name` modelu jako prózu. Soubory s prompty (`.github/prompts/*.prompt.md`) fungují v IDE,
ale ne v Copilot CLI: tam je nahrazuje skill.

## Když něco nefunguje

- **`/my-skill` se nenašel** → cesta musí být přesně `.github/skills/<name>/SKILL.md`. Pak `/skills reload`.
- **Při startu se vypíše `Failed to load 1 skill. Run /skills for more details.`** → `/skills`, záložka `Problems`, nebo
  `copilot skill list`: `Skill description must be at most 1024 characters`. Zkrať popis.
- **Je ve výpisu, ale nikdy se nespustí** → popis je vágní, nebo si konkuruje moc skillů. Zavolej ho
  přes `/name`, nepotřebné vypni přes `copilot skill disable <name>` a piš krátké popisy.
- **Copilot se před spuštěním Gradlu pořád ptá** → skill žádné oprávnění neuděluje. Použij `scripts/copilot-ws.sh`.

Dál: [04 · Hooky](04-hooks.cs.md) · Cvičení 2: [exercises.cs.md](exercises.cs.md)

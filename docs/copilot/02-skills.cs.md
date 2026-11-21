> 🌍 Číst v jazyce: [English](02-skills.md) | **Česky**

# Ukázka 2: Projektový skill

## Co je skill?

**Skill** je Markdown soubor s instrukcemi pro Copilota, který se načte
**jen když ho úkol potřebuje**. Srovnej ho se soubory s instrukcemi
z [Ukázky 1](01-custom-instructions.cs.md):

- `.github/copilot-instructions.md` je v **každé** session. Drž ho krátký.
- Skill se načítá **na vyžádání**: když tvůj požadavek odpovídá jeho popisu,
  nebo když ho zavoláš jménem přes `/skill-name`.

Pod kapotou: při startu session dostane model seznam názvů a popisů skillů,
nic víc. Načtení skillu je volání nástroje. Model zavolá nástroj jménem
`skill` s názvem skillu a CLI vloží tělo `SKILL.md` do konverzace. Do toho
volání tělo nic nestojí.

## Co dělá tahle ukázka

Skill `board-tests` učí Copilota, *jak se v tomhle projektu píšou testy
desky*: kde žijí, jak se jmenují, který helper sestaví desku, jak spustit
sadu a co dělat, když správný test selže.

Jestli to něco mění, se měřilo ([Ukázka 9](09-validate-eval.cs.md)).
Ve srovnání s ním a bez něj prošel stejný úkol na psaní testu svými kontrolami
v 0 ze 4 trialů bez skillu a ve 3 ze 4 s ním (ve 2 ze 4 při prvním hodnocení,
než byl jeden grader opraven). Bez skillu testy nikdy nepoužily helper
`boardOf(` (4 ze 4) a polovina z nich měla název v camelCase místo věty ve
zpětných apostrofech. Cena: s načteným skillem asi o 26–32 % víc tokenů
a o 51–67 % víc času.

## Soubor řádek po řádku

Skill žije v `.github/skills/board-tests/SKILL.md`. Na cestě záleží:

```
.github/              ← project-scoped Copilot config (committed to git)
└── skills/           ← all project skills live here
    └── board-tests/  ← one folder per skill
        └── SKILL.md  ← must be named exactly SKILL.md
```

Soubor začíná **frontmatterem**, YAML blokem mezi řádky `---`:

```yaml
---
name: board-tests
description: Use when writing or extending JUnit tests for the 2048 board logic (slideLineLeft, Board.move, win and game-over detection). Covers the project's test conventions and how to run the suite.
---
```

- `name: board-tests` je identifikátor: to, co píšeš za lomítko, a to, co
  model předává nástroji `skill`. Podle dokumentace je povinný a má nejvýš
  64 znaků; malá písmena se spojovníky jsou tvar, který přijímá každá stránka
  dokumentace.
- `description:` je **nejdůležitější řádek**. Je to jediná část skillu, kterou
  model vidí, než se rozhodne. Tenhle je napsaný jako spouštěč („Use when
  writing or extending JUnit tests...“) a obsahuje slova, která by vývojář
  napsal: `slideLineLeft`, `Board.move`, „game-over“. Povinný, nejvýš
  1 024 znaků (podle dokumentace).

Všechno pod frontmatterem je tělo, tady 39 řádků:

- **Úvodní odstavec** jmenuje dva soubory: kde jsou pravidla a kam patří
  testy. Copilot nemusí hledat.
- **`## Conventions`**, sedm odrážek. Jeden `@Test` na chování, s větou ve
  zpětných apostrofech jako názvem. Arrange-Act-Assert oddělené prázdnými
  řádky. Pro pravidla slučování dávej přednost `slideLineLeft()`. Pro chování
  celé desky použij `boardOf(...)`, protože volá konstruktor, který negeneruje
  žádné náhodné dlaždice. Pravidla nikdy netestuj přes service, controller
  ani UI. Kdy použít helper `slid()`. V `assertEquals` je očekávaná hodnota
  první.
- **`## Key API`**, pět signatur v bloku kódu. Je to levnější, než nechat
  Copilota otevřít `Board.kt` a hledat je, a zároveň to označuje, který
  konstruktor je ten pro testy.
- **`## Running the tests`**: ten jeden příkaz, `./gradlew :engine:test`.
- **Poslední dvě věty** jsou ty, na kterých v demu záleží: „always run the
  suite before declaring it done“ a „If a correct test fails because the
  production code is wrong, keep the assertion and report the bug.“ Bez té
  druhé je nejlevnější cestou k zelenému běhu změnit assertion.

Složka skillu může obsahovat víc než `SKILL.md`. Podle dokumentace jsou
skripty a další soubory v ní k dispozici, když se skill vyvolá; odkazuj na ně
z těla.

## Jak se skill spouští

**Modelem.** Tvůj požadavek odpovídá popisu a model zavolá nástroj.
Otestováno: prompt o psaní testu desky, který skill nejmenoval, vyprodukoval
v JSON výstupu běhu s `-p` tohle:

```json
{"type":"tool.execution_start","data":{"toolName":"skill","arguments":{"skill":"board-tests"}}}
```

Žádná samostatná událost „skill invoked“ neexistuje. Použití skillu je právě
tohle volání nástroje, a to je také to, co hledají evaly a skripty.

**Tebou.** Napiš `/board-tests`, samotné nebo před požadavkem. Funguje to
i v režimu `-p`. Otestováno:

```bash
copilot -p "/board-tests Which helper builds a whole board without random tiles? Change no file." \
  --trust-folder --no-ask-user
```

Stream ukáže stejné volání nástroje `skill` a odpověď jmenuje `boardOf(...)`.
Podle dokumentace může slash název stát i uvnitř věty („Použij skill
/board-tests na ...“).

**Skilly z pluginu** mají před sebou název pluginu, s dvojtečkou:
`/2048-dev:build-test` ([Ukázka 6](06-plugins.cs.md)).

K argumentům: text za slash názvem se v testu výše k modelu dostal. Jak se
předávají argumenty ve stylu `--option value`, zdokumentované není, a otevřené
issue (github/copilot-cli#4548) hlásí, že se zahazují. `argument-hint` mění
jen to, co ukazuje výběr. Piš požadavek jako prózu.

## `allowed-tools` je předschválení, ne omezení

Název naznačuje whitelist. Není to whitelist. Podle dokumentace běží nástroje
uvedené v `allowed-tools` **bez potvrzovacího dotazu**, dokud je skill
aktivní; nástroje, které uvedené nejsou, fungují dál a ptají se jako obvykle.
Zdokumentovaný příklad je `allowed-tools: shell`.

Co z toho plyne:

- Skill tím nejde udělat read-only. Chceš-li omezit, co se dá udělat, použij
  vlastního agenta se seznamem `tools` ([Ukázka 5](05-agents.cs.md)) nebo
  pravidlo deny ([Ukázka 8](08-permissions-sandbox.cs.md)).
- `allowed-tools: shell` ve skillu, který jsi nenapsal, znamená „jakýkoli
  shellový příkaz bez ptaní“ po celou dobu, kdy je ten skill aktivní. Skill
  si přečti dřív, než ho nainstaluješ.
- Jestli se uvnitř `SKILL.md` přijme vymezené pravidlo jako
  `shell(./gradlew:*)`, zdokumentované není. Otestuj to dřív, než se na to
  spolehneš.

`board-tests` tohle pole nenastavuje. Běh Gradlu schvaluješ ty, nebo ho
předem schválí přepínače při spuštění ve `scripts/copilot-ws.sh`
(`--allow-tool='shell(./gradlew:*)'`, otestováno).

## Vytvoř si vlastní skill, krok za krokem

1. **Vytvoř složku.** V kořenu repa:
   ```bash
   mkdir -p .github/skills/my-skill
   ```
   Každý skill potřebuje vlastní složku. `SKILL.md` položený přímo do
   `.github/skills/` není skill (podle changelogu vyvolá varování).

2. **Vytvoř** `.github/skills/my-skill/SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: Use when <the situation that should trigger this skill>. Covers <what it contains>.
   ---

   # My skill

   <Instructions. Write them like a briefing for a new colleague: what to do,
   which files and APIs to use, how to verify the result, what to do when it
   fails.>
   ```

3. **Načti ho.** Podle dokumentace načte `/skills reload` skill přidaný během
   session; nová session to udělá v každém případě.

4. **Zkontroluj, že tam je.** V terminálu:
   ```bash
   copilot skill list
   ```
   Musí se objevit pod „Project skills“.

5. **Otestuj ruční spuštění:** napiš `/my-skill` a za něj požadavek.

6. **Otestuj automatické spuštění.** Zformuluj požadavek tak, jak by to
   udělal kolega, bez názvu skillu, a hledej volání nástroje:
   ```bash
   copilot -p "<a request that should trigger it>" --trust-folder --no-ask-user \
     --output-format json \
     | jq -c 'select(.type=="tool.execution_start" and .data.toolName=="skill") | .data.arguments'
   ```
   Prázdný výsledek znamená, že popis neodpovídal. V režimu `-p` se volání
   nástroje, které potřebuje schválení, zamítne, takže drž požadavek
   read-only, nebo přidej pravidlo `--allow-tool`.

7. **Commitni ho:**
   ```bash
   git add .github/skills/my-skill
   git commit -m "Add my-skill"
   ```
   Teď ho má každý, kdo si repo naklonuje. Osobní skilly, které sdílet
   nechceš, patří do `~/.copilot/skills/` nebo `~/.agents/skills/`.

Napsat popis je většina práce. Popiš *situaci uživatele*, ne obsah: „Use when
writing unit tests for ...“ skill spustí; „Information about tests“ ne. Dej
do něj podstatná jména, která lidi píšou. Drž ho krátký, z důvodu uvedeného
v sekci Úskalí.

## Vyzkoušej demo

Zeptej se Copilota:

> *„Přidej test pro posun řádku 4, 4, 8, 0“*

`BoardTest.kt` má `TODO (participants)` přesně pro tenhle řádek. Co sledovat
(prostřední kroky se liší podle modelu; jde o první a poslední):

1. Nástroj `skill` se zavolá s `board-tests` dřív, než se zapíše jakýkoli
   soubor.
2. Copilot otevře `BoardTest.kt`. Tohle čtení doručí i pravidla enginu
   z Ukázky 1, včetně „A tile may merge at most once per move“.
3. Napíše jeden test s názvem ve zpětných apostrofech, který volá
   `slideLineLeft()` a očekává `8, 8, 0, 0` se skóre 8.
4. Spustí `./gradlew :engine:test`. Budeš požádán o schválení, pokud jsi
   session nespustil přes `scripts/copilot-ws.sh`.
5. **Test selže.** Kód vrací `16, 0, 0, 0` a skóre 24.

To je záměrný bug 1. `slideLineLeft()` po sloučení neposune svůj index, takže
čerstvě sloučená `8` se sloučí znovu s `8` vedle ní. Skill Copilotovi řekl,
co teď dělat: nechat assertion a nahlásit bug. Pokud místo toho přepíše
očekávání na `16, 0, 0, 0`, viděl jsi právě to selhání, kterému má poslední
věta skillu zabránit; řekni mu to a zeptej se znovu.

Po skončení tahu hook `agentStop` pustí testy znovu a ukáže varování, že
selhávají ([Ukázka 3](03-hooks.cs.md)). Je jen informativní; nic se necyklí.

Pokud pokračuješ ke cvičením, nech padající test na místě. Chceš-li ho vrátit
zpět, spusť ve vlastním terminálu
`git restore engine/src/test/kotlin/com/quanti/g2048/engine/BoardTest.kt`.

## Adresáře se skilly

Podle dokumentace se skilly načítají z těchto míst a u dvou skillů se stejným
názvem **vyhrává ten, který se najde první**:

| Pořadí | Umístění | Rozsah |
|-------|----------|-------|
| 1 | `.github/skills/` | projekt |
| 2 | `.agents/skills/` | projekt |
| 3 | `.claude/skills/` | projekt (umístění Claude Code; Copilot ho čte taky) |
| 4 | `.github/skills/` v nadřazených adresářích | projekt |
| 5 | `~/.copilot/skills/`, `~/.agents/skills/` | osobní |
| 6 | nainstalované pluginy | plugin |
| 7 | `COPILOT_SKILLS_DIRS`, kořeny z `--add-dir` | vlastní |
| 8 | vestavěné, pak organizace nebo enterprise | vzdálené |

Projektový skill tedy potichu přebije skill z pluginu se stejným názvem. Proto
se projektový skill tady jmenuje `board-tests` a ten z pluginu `build-test`.
Tvůj osobní `~/.claude/skills/` se nečte.

## Úskalí

**Hodně skillů se navzájem zakrývá.** Seznam skillů, který model vidí, má
rozpočet ve znacích a otevřená issues (github/copilot-cli#5488, #2314) hlásí,
že se ořezává bez jakékoli prioritizace. To, že `copilot skill list` skill
ukazuje, nedokazuje, že ho model vidí. Na počítači, na kterém tohle repo
vzniklo, načetla session 166 skillů: jeden z tohohle projektu, jeden z pluginu,
tři vestavěné a 161 osobních z `~/.agents/skills/`, s popisy o celkové délce
asi 47 000 znaků. `board-tests` se tam přesto spustil, což je jeden datový bod
a žádná záruka. Pokud se tvůj skill nespouští a máš hodně osobních:

- zavolej ho explicitně přes `/board-tests`;
- vypni, co nepotřebuješ: `copilot skill disable <name>`;
- drž každý popis krátký, včetně toho svého.

Nápověda 1.0.114 uvádí také `--dynamic-retrieval skills=on|off` (vyhledávání
skillů založené na embeddings). Tady netestováno.

**`disable-model-invocation: true` rozbije víc, než říká.** Pole je určené pro
skilly, které smíš spustit jen ty. Otevřené issue (github/copilot-cli#4438)
hlásí, že takový skill odpoví z nástroje `skill` „Skill not found“ v režimu
`-p`, když je jmenovaný v próze a když ho volá jiný skill. Funguje jen
`/name` napsané v interaktivní session. Skill „jen na ruční spuštění“ proto
selže ve skriptech, v CI a v evalech. Tady netestováno; otestuj to dřív, než
na tom začneš stavět.

**Osobní skilly prosakují do měření.** V bězích evalů se osobní skill `tdd`
vyvolal ve větvi, která měla být bez skillu. To, co máš nainstalované
soukromě, mění chování sdíleného skillu na tvém počítači.

**Skill neuděluje oprávnění.** Bez `allowed-tools` se každý příkaz z těla
pořád ptá.

## Volitelné parametry frontmatteru

`board-tests` používá jen `name` a `description`. Úplný seznam, podle
dokumentace:

| Pole | Co dělá |
|-------|--------------|
| `name` | Povinné. Identifikátor a slash název, max. 64 znaků |
| `description` | Povinné. Text spouštěče, max. 1 024 znaků |
| `argument-hint` | Volný text zobrazený ve výběru skillů, např. `"[test-name]"`. Jen nápověda |
| `allowed-tools` | Nástroje, které běží bez dotazu, dokud je skill aktivní. Řetězec nebo YAML seznam; `"*"` znamená všechny |
| `user-invocable` | Výchozí `true`. `false` odstraní příkaz `/name`; načíst ho může jen model |
| `disable-model-invocation` | Výchozí `false`. `true` zabrání modelu načíst ho sám od sebe. Viz Úskalí |
| `license` | Volitelná poznámka o licenci |

Klíče Claude Code jako `model`, `context: fork` a `paths` v referenci Copilota
nejsou. Nespoléhej na ně.

Správa skillů. Terminálové příkazy jsou v nápovědě 1.0.114; slash podpříkazy
jsou podle dokumentace (nápověda popisuje `/skills` jen jako „Manage
skills“):

| Příkaz | Co dělá |
|---------|--------------|
| `copilot skill list [--json]` | Skilly seskupené podle zdroje |
| `copilot skill add <file, URL or directory>` | Přidá skill; podle dokumentace instaluje `--project` do `.github/skills/` |
| `copilot skill enable <name>` / `disable <name>` | Zapne nebo vypne jeden skill |
| `copilot skill remove <name>` | Odebere skill nebo vlastní adresář se skilly |
| `/skills` | Stejná správa uvnitř session. Podle dokumentace: `/skills list`, `/skills info NAME` (changelog tomu říká `get`), `/skills reload` |

Reference: [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills).

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|----------|--------|-------|
| **Copilot CLI** | ✅ Ano | Otestováno na 1.0.114: načte se jako projektový skill, spouští se podle popisu i přes `/board-tests`, také v bězích s `-p` |
| **Plugin pro IntelliJ** | ✅ Ano | Podle release notes pluginu jsou agent skills obecně dostupné od 1.10.0. Které projektové složky plugin prohledává, žádný zdroj specifický pro JetBrains neuvádí. Tady netestováno |
| **Cloud agent** | ✅ Ano | Podle dokumentace. Copilot code review také používá relevantní skilly z head branche pull requestu |

## Když něco nefunguje

- **`/board-tests` se nenajde** → soubor musí být přesně
  `.github/skills/<name>/SKILL.md` (velkými `SKILL.md`, ve vlastní složce).
  Zkontroluj `copilot skill list`, pak skilly načti znovu nebo začni novou
  session.
- **Skill je v seznamu, ale nikdy se nespustí** → popis je moc vágní, nebo je
  seznam přeplněný (viz Úskalí). Přepiš ho kolem situace uživatele a otestuj
  ho `jq` jednořádkovým příkazem výše.
- **Skill se spouští na nesouvisející otázky** → popis je moc široký. Eval
  v `evals/board-tests/` má přesně na tohle negativní případ.
- **„Skill not found“ v běhu s `-p`** → skill nastavuje
  `disable-model-invocation: true`.
- **Copilot se před spuštěním Gradlu pořád ptá** → skilly nic neudělují.
  Spouštěj přes `scripts/copilot-ws.sh`, nebo přidej `allowed-tools`.
- **Nenačte se vůbec žádný projektový skill, na žádný prompt** → spravované
  nastavení může samostatné skilly z repozitáře blokovat
  (`strictPluginOnlyCustomization`) a `disabledSkills` umí vypnout jednotlivé.
  Viz [preflight.cs.md](preflight.cs.md).
- **Dva skilly s jedním názvem** → vyhrává první umístění z tabulky výše.
  Jeden přejmenuj.

Dál: [Ukázka 3: Projektové hooky](03-hooks.cs.md).

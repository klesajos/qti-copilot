> 🌍 Číst v jazyce: [English](00-install.md) | **Česky**

# Instalace a první session

Udělej to **před dnem workshopu**. S dobrým připojením to zabere asi 15 minut
a poslední sekce je checklist, podle kterého poznáš, že máš hotovo. Instalace,
podpříkazy `copilot` a běhy s `-p` v tomhle návodu běžely na Copilot CLI
**1.0.114** dne 2026-11-21. Slash příkazy interaktivní session jsou popsané
podle vlastní nápovědy CLI, a kde řádek říká „podle dokumentace“, tam se nic
nespouštělo.

## Co potřebuješ

| | Proč | Verze |
|---|---|---|
| **Seat Copilota** | Copilot Business od tvé organizace, se zapnutou politikou Copilot CLI. CLI má na úrovni organizace vlastní vypínač (podle dokumentace) | — |
| **Copilot CLI** | Samotný agent | **≥ 1.0.114** |
| **JDK** | Jen ke spuštění Gradlu. Build kompiluje s toolchainem JDK 21, který si Gradle stáhne, pokud ho nemáš | libovolná **17–27** |
| **Node.js + npm** | Aplikace `web/`, nástroje pro evaly a instalace CLI přes npm | **24.15+** nebo **26** |
| **`jq`** | Skripty hooků jím parsují svůj JSON vstup. Bez `jq` hlídací hooky propustí všechno | libovolná |
| **Git** | Klonování, a hooky volají `git` | libovolná novější |

Proč tyhle rozsahy: Gradle 9.9.2 potřebuje ke startu JVM mezi 17 a 27
a `settings.gradle.kts` aplikuje foojay toolchain resolver, takže chybějící
JDK 21 se stáhne při prvním buildu. Spodní hranice pro Node pochází z `jsdom`
ve `web/`, který odmítá Node 24 nižší než 24.15.

Windows: skripty hooků jsou bash skripty registrované pod klíčem `bash` a CLI
potřebuje PowerShell 6 nebo novější (podle dokumentace). Použij WSL 2 a jdi
linuxovou cestou. Nativní Windows se pro tohle repo netestovaly.

## 1. Nainstaluj Copilot CLI

Otestovaná cesta je npm, s verzí připnutou na tu, pro kterou byly návody
napsané:

```bash
npm install -g @github/copilot@1.0.114
```

Když `@1.0.114` vynecháš, dostaneš aktuální vydání. Podle dokumentace existují
i balíčky pro Homebrew a WinGet a instalační skript; aktuální příkazy má
[stránka o instalaci](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli).
(Příkaz pro Homebrew je ve vlastních zdrojích GitHubu uvedený dvěma různými
způsoby, takže ho zkopíruj z té stránky, ne z hlavy.)

Otevři nový terminál a zkontroluj:

```bash
copilot --version     # GitHub Copilot CLI 1.0.114.
```

### Proč záleží na minimální verzi

Copilot CLI vydává několik verzí týdně a mechanismy v tomhle repu jsou nové.
Pod těmito verzemi se návod nebude chovat tak, jak je napsaný (podle changelogu
a issue trackeru):

| Verze | Co přinesla |
|---------|-----------------|
| 1.0.100 | Soubory s instrukcemi vázané na cestu se doručí, když se čte nebo edituje odpovídající soubor. Existuje `--trust-folder` |
| 1.0.109 | Soubor agenta přidaný do `.github/agents/` si běžící session načte. Model, který nesmíš použít, je chyba, ne tiché přepnutí |
| 1.0.110, 1.0.111 | Marketplace v repozitáři s relativní cestou k adresáři (`"path": "."`, jako v tomhle repu) se vyhodnotí vůči kořenu repozitáře, i když session startuje v podadresáři |
| 1.0.113 | Verze protokolu, kterou čeká Conductor 0.1.47 ([návod 14](14-conductor.cs.md)) |
| 1.0.114 | Pluginy zapnuté repozitářem se načítají i v bězích s `-p` (issue #4507, uzavřené jako vyřešené v tomhle vydání; tady potvrzeno) |

Novější verze je v pořádku. Ve výchozím nastavení CLI při startu kontroluje
aktualizace a stahuje je. Chceš-li aktualizovat na vyžádání, spusť
`copilot update`. Chceš-li kvůli srovnání nebo CI jobu zůstat na jedné verzi,
spouštěj ho s `--no-auto-update` nebo nastav `COPILOT_AUTO_UPDATE=false`; jinak
může místo verze, kterou jsi nainstaloval, běžet novější, kterou už má v cache.

### Když se `copilot` po úspěšné instalaci nenajde

Tohle se stalo na počítači, na kterém tohle repo vzniklo. Node tam spravoval
správce verzí (`mise`). V takovém nastavení zapíše `npm install -g` binárku do
vlastního adresáře aktivní verze Node
(`~/.local/share/mise/installs/node/<version>/bin`), který nemusí být v `PATH`.
Správce verzí ji zpřístupňuje přes shim a ten shim neexistuje, dokud shimy
nepřegeneruješ:

```bash
npm prefix -g         # where npm put it
mise reshim           # create the missing shim
which copilot         # now resolves, e.g. ~/.local/share/mise/shims/copilot
```

Dva důsledky téže příčiny. Globální npm balíček patří jedné verzi Node, takže
po přepnutí Node instaluješ CLI znovu. A skripty, které nenačítají tvůj shell
profil (hooky, kroky v CI, run konfigurace v IDE), najdou `copilot` jen tehdy,
když je adresář se shimy v jejich `PATH`.

## 2. Přihlas se

```bash
copilot login                 # opens the browser
copilot login --device-code   # over SSH or in a container: a code to type in
```

Nebo spusť `copilot` a napiš `/login`. Přihlas se účtem, na kterém je seat
Copilota od tvé organizace. Token se uloží do systémového úložiště
přihlašovacích údajů.

Jedna past: exportovaná proměnná `COPILOT_GITHUB_TOKEN`, `GH_TOKEN` nebo
`GITHUB_TOKEN` (kontrolují se v tomhle pořadí) **má přednost před uloženým
přihlášením**. Pokud tvůj shell profil exportuje osobní `GH_TOKEN`, CLI běží
pod tím účtem, s jeho licencí a jeho seznamem modelů. Zkontroluj to přes
`env | grep -i token`. Klasické personal access tokeny (`ghp_...`) se
nepřijímají.

## 3. První session v tomhle repu

```bash
git clone https://github.com/klesajos/qti-copilot
cd qti-copilot
./gradlew build       # BUILD SUCCESSFUL: 13 engine tests and 5 API tests pass
copilot
```

První běh `./gradlew` stáhne Gradle a v případě potřeby i JDK 21.

### Dotaz na důvěru ke složce

Při prvním startu v adresáři se Copilot zeptá, jestli důvěřuješ souborům v něm
a pod ním. Můžeš mu důvěřovat jen pro tuhle session, nebo zvolit „Yes, and
remember this folder for future sessions“, což uloží cestu pod
`trustedFolders` do `~/.copilot/config.json`.

Ta odpověď není formalita. Podmiňuje tři věci v repozitáři, které můžou na
tvém počítači spouštět kód nebo přidávat nástroje:

| Podmíněno důvěrou | V tomhle repu |
|----------------|--------------|
| **Hooky z repozitáře** | `.github/hooks/hooks.json` spouští na události session pět shellových skriptů |
| **MCP servery workspace** | žádné tu nejsou; `.mcp.json`, který si vytvoříš z `.mcp.json.example`, by sem patřil |
| **Nastavení pluginů v repozitáři** | `.github/copilot/settings.json` registruje marketplace z repa a zapíná plugin `2048-dev` |

Než v repozitáři, který neznáš, řekneš ano, přečti si jeho skripty
v `.github/hooks/`: běží s tvými oprávněními.

Past je neinteraktivní případ. Běh s `-p` ten dotaz zobrazit nemůže. Tyhle tři
věci načte jen tehdy, když už je složka důvěryhodná, nebo pro ten jeden běh
s `--trust-folder`. Jinak běží bez hooků a bez pluginu a půlka návodů vypadá
rozbitě. Přepínač nic neukládá a neuděluje žádné oprávnění k nástrojům.

### Na co se podívat

Napiš v session tyhle příkazy. Dohromady odpovídají na otázku „načetlo se
nastavení repa?“

| Příkaz | Co ukazuje | Tady čekej |
|---------|---------------|-------------|
| `/env` | Všechno, co se načetlo: instrukce, MCP servery, skilly, agenty, hooky, pluginy | Položky z řádků níže, na jedné obrazovce |
| `/instructions` | Soubory s instrukcemi; některý můžeš pro session vypnout | `.github/copilot-instructions.md` a dva soubory pod `.github/instructions/` |
| `/skills` | Dashboard skillů. Podle dokumentace vypíše `/skills list` totéž jako text; v terminálu to dělá `copilot skill list` | `board-tests` (projektový), `build-test` z pluginu a k tomu cokoli, co máš osobně |
| `/agent` | Výběr agenta | `kotlin-reviewer`, `board-test-writer` a `game-explorer` z pluginu (id `2048-dev:game-explorer`) |
| `/model` | Modely, které máš k dispozici, každý s cenou | Záleží na tvé organizaci |
| `/usage` | Co tahle session spotřebovala a kolik z tvého plánu je vyčerpáno | Skoro nula |

Pokud chybí skill z pluginu, agent z pluginu a hooky, složka není důvěryhodná.
Pokud se z `.github/` neukáže vůbec nic, nejsi uvnitř klonu
(`git rev-parse --show-toplevel`).

## 4. Vyber model

`/model` ukáže modely, které máš podle politiky své organizace k dispozici,
a dovolí ti kdykoli přepnout. S `auto` mezi nimi vybírá Copilot sám.
Pro jeden běh použij `copilot --model <model-id>` nebo proměnnou
`COPILOT_MODEL`; `/config model` nastaví tvůj osobní výchozí model.

Z allow-listu plynou dvě věci:

- **Nikdy nepiš id modelu do souboru, který commituješ.** Id, které funguje na
  tvém účtu, nemusí u kolegy existovat. Nastavení repozitáře, soubory agentů
  ani skripty v tomhle repu proto žádný model nejmenují. Návody píšou
  `<model-id>` tam, kde si ho doplníš.
- **Model, který nesmíš použít, je chyba, ne fallback** (CLI 1.0.109+, podle
  dokumentace). Pokud uložený výchozí model po změně politiky přestane
  fungovat, vyber si znovu v `/model`.

Volba modelu mění chování, nejen kvalitu. V našich bězích editovaly modely
rodiny GPT soubory přes nástroj `apply_patch`; podle dokumentace jiné modely
používají `edit` a `create`. Na tom záleží, jakmile píšeš hooky
([návod 03](03-hooks.cs.md)).

## 5. AI Credits

Spotřeba Copilota se měří v **AI kreditech**, nebo na starší fakturační
platformě v **premium requestech**. CLI ukazuje tu jednotku, kterou používá
tvůj plán (`copilot help billing`). Podle dokumentace je Copilot Business na AI
Credits: jeden kredit je $0.01 a plán zahrnuje 1 900 kreditů na uživatele
a měsíc, sdílených napříč organizací. Účet, na kterém se tyhle návody
testovaly, pořád hlásil premium requesty, takže jsou tu popsané obě varianty.

| | AI kredity | Premium requesty (legacy) |
|---|---|---|
| Co stojí peníze | Každé volání modelu, podle jeho tokenů (vstup, cache, výstup) za cenu modelu | Každý prompt, který pošleš: jeden request krát násobitel modelu |
| Autonomní práce | Počítají se subagenti i práce na pozadí, například kompakce | Každé pokračování autopilota se počítá jako prompt |
| V `/model` | Kredity za 1M tokenů | Násobitel |

Proč na tom u AI kreditů záleží: každé volání posílá znovu celou dosavadní
konverzaci jako vstup. Dlouhá session proto zdražuje na každý prompt, nejen
v součtu.

| Kde | Co vidíš |
|-------|--------------|
| Patička | `Session: N AIC used` (na legacy fakturaci ve výchozím stavu žádné číslo) |
| `/usage` | Kredity nebo requesty téhle session, tokeny po modelech a kolik z tvého plánu je vyčerpáno |
| `/limits`, `--max-ai-credits <credits>` | Volitelný strop pro session, minimum 30 kreditů. Je to měkký strop: jedna odpověď ho může překročit, další volání modelu se pak zablokuje |
| `--usage-output-file <file>` | Konečná spotřeba jako JSON, i pro běhy s `-p` |
| JSONL výstup běhu s `-p` | Poslední řádek, `"type":"result"`, nese objekt `usage`. Na testovacím účtu obsahoval `premiumRequests` |

Návyky, které drží účet nízko: pro nový úkol začni novou session (`/new`),
dlouhou session zkompaktuj přes `/compact` a na mechanickou práci použij
levnější model. `/fleet` a evaly spotřebu násobí, protože spouštějí několik
agentů.

## 6. Sestav a spusť aplikaci 2048

Dva terminály:

```bash
./gradlew :api:bootRun          # API on http://localhost:8080
```

```bash
cd web
npm ci                          # once
npm run dev                     # UI on http://localhost:5173
```

Otevři http://localhost:5173. Šipky nebo `W` `A` `S` `D` posouvají dlaždice.
Dev server proxuje `/api` na port 8080, takže UI potřebuje běžící API. Port je
striktní: pokud je 5173 obsazený, `npm run dev` selže, místo aby přešel na
5174.

Testy:

```bash
./gradlew test                  # engine (JUnit) + api (Spring MVC tests)
./gradlew :engine:test          # board rules only
cd web && npm test              # Vitest
```

Všechny projdou, a kód přitom obsahuje tři záměrné bugy. Sedí v případech,
které žádný test nepokrývá. K jejich nalezení slouží cvičení.

## Proč CLI, a ne jen plugin pro IDEA

Plugin pro IntelliJ je povolený a věnuje se mu [návod 12](12-intellij.cs.md).
Workshop přesto běží v terminálu, ze tří důvodů.

- **Je to to, co se počítá.** 2N sleduje používání Copilot CLI. Podle
  dokumentace vedou metriky používání CLI jako samostatného klienta
  (`copilot_cli`), odděleně od `jetbrains`. Verze pluginu 1.15.0–1.19.x
  propouštěly část aktivity agenta z IDE do čísel CLI; od 1.20.0 se připisuje
  IDE.
- **Je to nejnovější runtime.** Agent Copilot v pluginu si přibaluje vlastní
  CLI runtime, který je za terminálovým vydáním pozadu. Jeho úložiště pluginů
  je oddělené od úložiště CLI a z událostí hooků jsou pro něj zveřejněné jen
  `userPromptSubmitted`, `preToolUse`, `postToolUse` a `errorOccurred`. Hooky
  tohohle repa používají i `sessionStart` a `agentStop`.
- **Dá se skriptovat.** `copilot -p`, JSON výstup a přepínače při spuštění
  jsou to, z čeho se staví evaly, CI a vzdálení agenti
  ([návod 11](11-programmatic-ci.cs.md)).

IDE opouštět nemusíš: spusť `copilot` v okně terminálu v IDEA. Podle release
notes pluginu připojí `/ide` terminálovou session k výběru a diagnostice v IDE
(preview; tady netestováno).

## Předletová kontrola

Spusť tohle ve složce repa. Všechno v pořádku → jsi připravený. Delší verze,
včetně politik organizace, které umí featury vypnout, je v
[preflight.cs.md](preflight.cs.md).

```bash
copilot --version            # ≥ 1.0.114
java -version                # 17–27
node --version               # ≥ v24.15, or v26
jq --version
./gradlew build              # BUILD SUCCESSFUL
copilot instruction list     # three files
copilot skill list           # board-tests under "Project skills"
```

Pak spusť `copilot`, označ složku jako důvěryhodnou a napiš `/env`. V seznamu
musí být hooky a plugin `2048-dev`.

## Když něco nefunguje

| Příznak | Oprava |
|---|---|
| `copilot: command not found` hned po instalaci | Otevři nový terminál. Se správcem verzí Node přegeneruj jeho shimy (`mise reshim`) a zkontroluj `npm prefix -g` |
| `copilot --version` ukazuje jinou verzi, než jsi nainstaloval | V `PATH` je dřív jiná instalace (`which -a copilot`), nebo běží novější verze z cache CLI. Připni ji přes `--no-auto-update` |
| Přihlášení projde, ale seznam modelů je špatný nebo prázdný | Přihlášení přebíjí proměnná s tokenem: zruš `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`. Pak přes `/user` zjisti přihlášený účet |
| Přihlášení funguje, ale CLI tvrdí, že nemáš přístup | Politika Copilot CLI je pro tvou organizaci vypnutá, nebo seat patří jinému účtu. Zeptej se administrátora |
| Žádné hooky, žádný `/2048-dev:build-test` | Složka není důvěryhodná. Restartuj v kořenu repa a dotaz potvrď; u běhů s `-p` přidej `--trust-folder` a spouštěj z kořene repa |
| Hooky se načtou, ale pojistka na `.env` nic nedělá | Chybí `jq`. Hlídací skripty se bez něj samy vypnou |
| `./gradlew` selže dřív, než cokoli zkompiluje | JDK, které spouští Gradle, je starší než 17 nebo novější než 27 (`java -version`) |
| `npm ci` vypisuje varování `EBADENGINE` | Node je mimo podporovaný rozsah (24.15+ nebo 26+). Přepni ho dřív, než začneš věřit výsledku testů |
| `npm run dev` skončí, protože port 5173 je obsazený | Zastav ten druhý proces; port je striktní záměrně |
| Stránka ukazuje řádek s chybou a žádnou desku | API neběží na 8080 |
| Timeouty nebo chyby TLS za proxy | `copilot help network` |

Dál: [Ukázka 1: Vlastní instrukce](01-custom-instructions.cs.md).

> 🌍 Číst v jazyce: [English](10-level-5-workflow.md) | **Česky**

# Ukázka 10: Práce na úrovni 5 a výš

2N nechce, aby vývojáři psali kód ručně. Očekává práci na **úrovni 5 nebo vyšší** na škále
z příspěvku na blogu VisiData [Using AI to Contribute to Open Source](https://www.visidata.org/blog/2026/ai/).
Ukázky 1–9 postavily nástroje. Tahle je pracovní metoda: jak v tomto repu dodat změnu, když
je každý řádek vygenerovaný, a co musíš mít v ruce, než ji zmerguješ.

Odkud které tvrzení pochází:

- Bez značky: vlastní nápověda CLI ve verzi 1.0.114 (`copilot --help`, `copilot help <topic>`).
- **[T]** otestováno: spuštěno v tomto repozitáři na verzi 1.0.114.
- **[D]** podle dokumentace; v tomto repu netestováno. Většina slash příkazů je tu
  interaktivní, takže jejich jemnější chování je **[D]**.

## Škála

Názvy úrovní jsou převzaté z příspěvku; krátké popisy jsou parafráze.

| Úroveň | Název | Stručně |
|--------|-------|---------|
| 0 | Human did not use AI at all (člověk AI vůbec nepoužil) | AI nikde |
| 1 | Human asked chatbot for ideas (člověk se chatbota ptal na nápady) | Každý znak napsal člověk |
| 2 | Human coded with minor assists (člověk kódoval s drobnou výpomocí) | Malé vložené úryvky, regex, boilerplate |
| 3 | Human coded, bots assisted non-trivially (člověk kódoval, boti pomáhali netriviálně) | Napsal to člověk; část netriviálního kódu je vložená |
| 4 | Human coded, bots helped significantly (člověk kódoval, boti pomohli výrazně) | Většinu napsal člověk; boti upravovali soubory jako dokumentaci a testy |
| **5** | **Bots coded, human understands completely** (boti kódovali, člověk rozumí všemu) | Většinu napsali boti; člověk zrevidoval každý řádek |
| **6** | **Bots coded, human understands mostly** (boti kódovali, člověk rozumí většině) | Člověk na práci dohlížel a část úsudku o kódu přenechal botům |
| **7** | **Human specced, bots coded** (člověk napsal spec, boti kódovali) | Člověk napsal spec a hlídal testy a proces; většina úsudku o kódu je přenechaná botům |
| 8 | Bots planned, human approved (boti plánovali, člověk schválil) | Boti pracovali převážně sami; člověk zvalidoval výsledek |
| 9 | Human fired-and-forgot (člověk to odpálil a zapomněl) | Člověk to spustil a už se nikdy nepodíval |
| 10 | Rogue bots, zero human attention (boti na vlastní pěst, nulová lidská pozornost) | Nikdo si to neobjednal |

Na každé úrovni až po 8 za změnu pořád ručí člověk. Úrovně 9 a 10 nejsou způsob práce; jsou
to, čemu mají pojistky v tomto návodu zabránit.

## Co se mění mezi úrovněmi 5, 6 a 7

Kód je vygenerovaný na všech třech. Posouvá se to, **co ověřuješ sám a co přijímáš na základě
důkazů**.

| | Úroveň 5 | Úroveň 6 | Úroveň 7 |
|---|---------|---------|---------|
| Píšeš | Prompty | Prompty | Spec: chování, omezení, jak se to prokáže |
| Čteš | Každý řádek diffu | Rizikové hunky a testy; zbytek namátkově | Plán, testy a nálezy z review; kód málo nebo vůbec |
| Na základě důkazů přijímáš | Nic | Části, které jsi nečetl | Skoro všechno |
| Důkazy před mergem | Celý diff přečtený, testy zelené | Navíc: test, který před opravou selhal, proběhlé review, diff rozumné velikosti | Navíc: testy, které jsi specifikoval předem, nezávislé review, přepis session |
| Typické selhání | Dojde ti čas a jen to prolétneš | Bug se schová v nepřečtené části | Spec byl vágní a testy dokazují něco jiného |

Rizikový je krok z 5 na 6, protože „understands mostly“ nemá viditelnou hranici. U každé
změny se rozhodni, které soubory přečteš celé (v tomto repu: cokoli v `engine/`, kde žijí
pravidla), a napiš to do pull requestu.

## Smyčka pro tohle repo

Všechno níže se řídí prompty a slash příkazy. Žádný kód nepíšeš.

| Krok | Nástroj | Co dostaneš |
|------|---------|-------------|
| 1. Izoluj | `/new worktree`, nebo `copilot --worktree` **[D]** | Samostatný checkout, takže nepovedený běh nesáhne na tvůj pracovní strom |
| 2. Specifikuj a naplánuj | `/plan <spec>` | Sepsaný plán; dokud vzniká, jsou edity blokované **[D]** |
| 3. Proveď | Standardní režim, nebo autopilot | Změnu, s testy, které pustil agent |
| 4. Posbírej důkazy | Testy, hook `agentStop`, `/diff`, `kotlin-reviewer`, `/review`, `/security-review` | Důvody věřit změně, aniž bys ji četl celou |
| 5. V případě potřeby udělej rollback | `/rewind` | Soubory ve stavu před daným kolem |
| 6. Udělej z toho něco, co jde zrevidovat | `/share` | Přepis, který si může přečíst kolega |
| 7. Hlídej cenu | `/usage`, `/limits` | Utracené AI kredity a strop |

Session spusť launcherem repa. Předem schvaluje příkazy pro build a testy a zakazuje `.env`:

```bash
scripts/copilot-ws.sh
```

`--allow-tool='shell(./gradlew:*)'` pokrývá `./gradlew :engine:test` a `shell(npm test)` pokrývá
`cd web && npm test` **[T]**. Na edity souborů se CLI pořád ptá.

### Plan režim

| | |
|---|---|
| Vstup | `/plan [prompt]`, nebo `Shift+Tab` (přepíná standardní → plan → autopilot **[D]**), nebo start přes `copilot --plan` |
| Co blokuje **[D]** | Edity, patche a shell příkazy, které by změnily soubor ve workspace. Vynucuje to CLI, není to prosba na model. Subagenti to dědí |
| Co propustí **[D]** | Zápis samotného plánu (drží se mimo workspace, jako `plan.md` ve složce session), shell příkazy, jejichž efekt nejde určit, a volání externích nebo MCP nástrojů. Není to sandbox |
| Schválení **[D]** | Když je plán hotový, objeví se menu. Zdokumentované volby: **Accept plan and continue in Autopilot execution mode**, totéž **+ /fleet** a **Exit to Interactive execution mode without running the plan** |
| Změna plánu | Pošli další `/plan` prompt, který řekne, co je špatně. `COPILOT_EDITOR` (pak `VISUAL`, `EDITOR`) určuje editor, který CLI použije, když soubor s plánem upravuješ sám |
| Model pro plánování | `/model plan` nastaví samostatný model pro plan režim |

Schválit plán, který jsi přečetl, je úroveň 7. `copilot --plan --mode autopilot` **[D]** přejde
od plánu k implementaci úplně bez schválení; to je úroveň 8 nebo 9 podle toho, co uděláš
potom. Nepoužívej to na práci, za kterou musíš ručit.

### Autopilot

Autopilot je o **pokračování**: agent jede dalšími koly, dokud není cíl splněný, místo aby se
po každé odpovědi zastavil. `/autopilot` ho přepíná; `/autopilot <objective>` nastaví cíl
a přijímá `--max-ai-credits`.

Co autopilot není:

- **Nedává žádná oprávnění.** V autopilotu se požadavek na nástroj, na který by se CLI jinak
  ptalo, zamítne. Dej explicitní allow pravidla při spuštění:
  `scripts/copilot-ws.sh --allow-tool='write'` přidá k pravidlům launcheru edity souborů
  (pravidlo `write` bez omezení rozsahu popisuje `copilot help permissions`).
  Pravidla `--deny-tool` z launcheru mají pořád přednost.
- **Neptá se tě.** Když by agent položil otázku, Copilot odpoví, že nejsi k dispozici; agent
  buď zkusí nejlepší odhad, nebo skončí se shrnutím toho, co není jasné.
- **Není neomezený.** Po 5 automatických pokračováních se zastaví, pokud
  `--max-autopilot-continues` neříká jinak.

Při vstupu do autopilotu nabídne CLI volby Allow All, Assisted permissions, Manual Approval
nebo Cancel **[D]**. Dej přednost allow pravidlům při spuštění plus Manual Approval před
Allow All.

### Důkazy místo čtení každého řádku

| Důkaz | Jak ho získat | Co dokazuje | Co nedokazuje |
|-------|---------------|-------------|---------------|
| Testy spuštěné agentem | Instrukce mu říkají, ať pustí testy té části, na kterou sáhl, a nahlásí výsledek. Řekni si o počty | Sada teď prochází | Že sada testuje tu změnu |
| Test, který nejdřív selhal | Řekni si o test před opravou a o výstup selhání | Test tenhle bug umí odhalit | Že je oprava ta nejmenší možná |
| Hook `agentStop` | Automaticky: `.github/hooks/scripts/run-tests.sh` pustí Gradle testy, když jsou v `engine/` nebo `api/` necommitnuté změny, a webové testy, když jsou ve `web/src/` | Varování `run-tests hook: tests are failing in: ...`, když agent skončí na červené. Ticho znamená zelenou, nebo že se nic relevantního nezměnilo | Je jen poradní. Exit kód 2 z hooku `agentStop` varuje a neblokuje **[T]** |
| `/diff` | Napiš ho | Velikost a tvar změny | Správnost |
| Agent `kotlin-reviewer` | Prompt níže | Nálezy podle závažnosti, posouzené proti instrukcím tohoto repa (`include-custom-instructions: true`). Nemá žádný nástroj na edity | Má shell kvůli `git diff`, takže „read-only“ stojí na jeho promptu a tvých pravidlech oprávnění |
| `/review` | Napiš ho | Druhý názor od vestavěného agenta `code-review`. Kód nemění **[D]** | Nedostává instrukce repozitáře **[D]** |
| `/security-review` | Napiš ho | Nálezy seřazené podle priority nad necommitnutými změnami, nebo nad diffem branche, když je strom čistý | Není to plný audit repozitáře |
| Evaly | [Ukázka 9](09-validate-eval.cs.md) | Že se Copilot po změně skillu nebo agenta pořád chová, jak má | Nic o kódu aplikace |

> *„Použij agenta kotlin-reviewer a zreviduj moje necommitnuté změny.“*

Cvičení 3 udělá z poradního hooku bránu: hook `agentStop`, který vypíše
`{"decision":"block","reason":"..."}`, pošle agenta zpátky do práce a `reason` se stane další
zprávou uživatele **[T]**. Po 8 blokacích v řadě přestane CLI blok respektovat **[D]**.

### Rollback

`/rewind` (alias `/undo`, nebo dvakrát `Esc` na prázdném promptu) obnoví dřívější kolo.
Vyber **Conversation only**, nebo **Conversation + files**.

- Obnoví se jen soubory, které změnil Copilot; soubory, které jsi potom upravil ty, se
  přeskočí **[D]**.
- Rewind nejde vzít zpět: pozdější kola ze session zmizí. Pokud si chceš kopii konverzace
  nechat, udělej nejdřív `/fork`.
- Skutečnou záchrannou sítí zůstává Git. Začínej z čistého stromu nebo z worktree.

### Izolace přes worktree

| Příkaz | Efekt |
|--------|-------|
| `/new worktree` | Prázdná session v novém worktree |
| `/fork worktree` | Kopie aktuální konverzace v novém worktree |
| `/worktree` | Přesune tuhle session do nového worktree; necommitnuté změny zůstanou na místě |
| `/move` | Totéž, a necommitnuté změny jdou s tebou |
| `copilot --worktree[=NAME]` / `-w` **[D]** | Start uvnitř nového nebo znovu použitého worktree. Je v dokumentaci; `copilot --help` ho na verzi 1.0.114 neuvádí |

Nové worktree vznikají ve složce `<repo>.worktrees` vedle repozitáře. Pro tohle repo z toho
plynou dvě věci: čerstvý worktree nemá `web/node_modules`, takže hook `agentStop` tam webové
testy přeskakuje, dokud nepustíš `npm ci`; a při `/new worktree` nebo `/worktree` zůstanou
tvoje necommitnuté soubory, včetně lokálního `.env`, v původním checkoutu.

Neověřeno: jestli se pravidla zadaná flagy při spuštění přenesou do session založené přes
`/new worktree`. Pokud se agent začne ptát na `./gradlew`, spusť místo toho
`scripts/copilot-ws.sh` přímo ze složky worktree.

### Session, kterou může zrevidovat někdo jiný

`/share file [path]` vyexportuje přepis jako Markdown, `/share html [path]` jako HTML,
`/share link` zpřístupní synchronizovanou session každému, kdo může číst repozitář, a
`/share gist` vytvoří secret gist (nedostupné pro Enterprise Managed Users **[D]**).
Přes `/rename` session pojmenuješ, než ji vyexportuješ.

Výchozí název souboru je `copilot-session-<id>.md` v aktuálním adresáři. Zadej cestu mimo
repo, nebo soubor před commitem smaž. Přepis obsahuje výstup nástrojů; přečti si ho, než ho
přiložíš k pull requestu.

### Cena

- `/usage` ukáže AI kredity (premium requesty na plánu s legacy billingem), tokeny po
  modelech a kolik z plánu je vyčerpáno.
- `/limits set max-ai-credits <n>` nastaví session strop (minimum 30); `/limits unset` strop
  zruší. Je to měkký limit: jedna odpověď ho může přetáhnout, další volání modelu se pak
  zablokuje.
- 1 AI kredit je 0,01 USD; Copilot Business zahrnuje 1 900 sdílených kreditů na uživatele
  a měsíc **[D]**.
- Pro představu: read-only dotaz na tohle repo stál na `auto` zhruba 0,4 AI kreditu **[T]**.
  Plán, oprava a dvě review stojí násobek, protože každé volání posílá konverzaci znovu.

## Řešený příklad: tah naprázdno, který přidá dlaždici

Bug: `GameService.move` uloží výsledek `board.move(direction)` do `changed`, ignoruje ho
a vždycky zavolá `board.spawnRandom()`. Zmáčkni směr, který ničím nepohne, a dlaždice se
objeví stejně. Build je zelený, protože to žádný test nepokrývá.

1. **Spusť** launcher, a pokud máš ve stromu jinou rozdělanou práci, izoluj se:

   ```bash
   scripts/copilot-ws.sh
   ```

2. **Specifikuj.** Vlož tohle. Je to spec; právě o tu přesnost jde.

   > */plan Bug: tah, který nic nezmění, stejně přidá dlaždici. GameService.move ignoruje
   > Boolean vrácený z board.move(direction) a vždycky volá board.spawnRandom(). Očekávané
   > chování: když tah nic nezmění, vrácená hra má přesně stejnou mřížku a skóre jako předtím
   > a žádná dlaždice nepřibude. Když tah desku změní, přibude přesně jedna dlaždice, jako
   > dnes. Omezení: nejdřív napiš selhávající test; test nesmí záviset na náhodných
   > dlaždicích; v engine/ nic neměň; controller nech tenký. Pokud test potřebuje způsob, jak
   > začít hru ze známé desky, navrhni nejmenší možný seam a počkej na moje schválení.*

3. **Přečti si plán.** Na úrovni 7 je tohle to review, na kterém záleží nejvíc. Zkontroluj
   čtyři věci:
   - Test je před opravou.
   - Seam je malý. `GameService` vytváří desky přes `Board.newGame()`, která je náhodná; test
     potřebuje známou desku. Parametr konstruktoru s výchozí hodnotou je v pořádku. Veřejný
     setter nebo endpoint jen pro testy ne.
   - Dotčené soubory: `GameService.kt` a jeden testovací soubor pod `api/`. Nic v `engine/`.
   - Důkazem je příkaz: `./gradlew :api:test`.

   Když něco nesedí, pošli další `/plan` prompt s opravou. Pak zvol **Exit to
   Interactive execution mode without running the plan** **[D]**, aby ses mohl zastavit mezi
   červenou a zelenou.

4. **Červená.**

   > *„Udělej z plánu jen krok s testem. Spusť ./gradlew :api:test a ukaž mi název
   > selhávajícího testu a jeho assertion message. Tělo GameService.move zatím neměň.“*

   Důkaz: jeden nový test selže na **aserci** o mřížce. Chyba kompilace nebo pád Spring
   kontextu není červený test.

5. **Zelená.**

   > *„Teď udělej v GameService.move nejmenší změnu, se kterou tenhle test projde. Spusť
   > ./gradlew :api:test a nahlas počty prošlých a selhaných testů.“*

6. **Dokaž, že test opravu hlídá.**

   > *„Dočasně vrať zpět jen opravu v GameService.move, spusť ./gradlew :api:test a potvrď,
   > že nový test selže. Pak opravu vrať, pusť testy znovu a ukaž oba výsledky.“*

7. **Review.** Spusť `/diff` a podívej se na velikost: seam, test, jedna podmínka. Pak:

   > *„Použij agenta kotlin-reviewer a zreviduj moje necommitnuté změny.“*

   a `/review` jako druhého, nezávislého čtenáře. Žádné varování od hooku `agentStop`
   znamená, že Gradle testy prošly, když agent skončil.

8. **Zaznamenej.** `/usage`, pak `/share file <path-outside-the-repo>`.

Pokud jsi v kroku 7 přečetl každý změněný řádek, pracoval jsi na úrovni 5. Pokud jsi mergoval
jen na základě kroků 4–7, byla to úroveň 7.

**Totéž v autopilotu.** Spusť `scripts/copilot-ws.sh --allow-tool='write'`, vlož spec a plán
přijmi volbou **Accept plan and continue in Autopilot execution mode**. Přijdeš o zastávku
mezi červenou a zelenou, tak ji dej do specu: „než napíšeš opravu, nahlas výstup selhání“.
Kroky 6–8 zůstávají na tobě.

## Když to agent udělá špatně a ty to sám opravit nesmíš

Pravidlo, že kód nepíšeš, ti nebrání být přesný. Postupuj tímhle seznamem shora dolů.

| Situace | Co udělat |
|---------|-----------|
| Oprava je špatně, ale test prochází | Test je slabý. Přidej případ promptem: *„Přidej test: po tahu naprázdno se počet nenulových dlaždic nezmění.“* Pak si řekni o opravu znovu |
| Změnil toho moc | `/rewind` před to kolo. Jmenuj soubor a funkci a zbytek zakaž: *„Změň jen GameService.move. Na žádný jiný soubor nesahej.“* |
| Upravil test, aby prošel | `/rewind`. Řekni výslovně, že test je spec. Pro další běh přidej `--deny-tool='write(<TestFile>.kt)'`; relativní cesta v pravidle se porovnává podle koncových komponent cesty |
| Pořád zabíhá do `engine/` | Přidej `--deny-tool='write(engine/**)'` (glob tvar podle `copilot help permissions`; tady netestováno). Pravidlo na cestu nepokrývá shell příkazy a modely z rodiny GPT občas zapisují přes shell přesměrování **[T]** |
| Točí se na selhávajícím testu | Zastav ho, `/rewind`, přepni do plan režimu: *„Vysvětli, proč test pořád selhává. Uveď soubor a řádek. Nic neměň.“* Oprav spec, ne kód |
| Nerozumí cestě kódem | Nejdřív deleguj mapu: *„Použij agenta 2048-dev:game-explorer a vystopuj tah od controlleru k desce.“* |
| Píše idiomy Spring Boot 3 | To je mezera v instrukcích. Nech Copilota doplnit `.github/copilot-instructions.md` a pak začni novou session; v běžící session se instrukce znovu nenačtou **[D]** |
| Konverzace je zanesená neúspěšnými pokusy | `/new` s čerstvým, kratším specem. `/rubber-duck` dá nezávislou kritiku aktuální práce |
| Stejný model, stejná chyba | `/model`, vyber jiný a zopakuj nejmenší selhávající krok |
| Nic nepomáhá | Nadiktuj změnu slovy, na úrovni řádku: *„V GameService.move volej board.spawnRandom() jen tehdy, když je changed true.“* Pořád je to vygenerované a ty teď víš, že problém byl ve specu |

## Riziko na úrovni 6 a výš

Buď k sobě upřímný v tom, čeho se vzdáváš.

- **Zelený build dokazuje málo.** Tohle repo je toho ukázkou: build je zelený a jsou v něm tři
  bugy. Testy napsané agentem, který psal kód, sdílejí jeho nepochopení.
- **Review agenti jsou pravděpodobnostní.** Leccos přehlédnou a ten vestavěný nezná tvoje
  konvence **[D]**.
- **Přestaneš číst tam, kde to začne být nudné**, a právě tam se schovávají bugy.
- **Podepsaný pod změnou jsi pořád ty.** Škála končí u „člověk ručí“.

Co pojistky repa pokrývají a co ne:

| Pojistka | Omezuje | Nepokrývá |
|----------|---------|-----------|
| `block-destructive.sh` (`preToolUse`) | Destruktivní shell příkazy. Deny z hooku platí i s `--allow-tool='shell'` **[T]** | Příkazy, na které nemá vzor. Při timeoutu hook propouští (fail open) **[D]** |
| `protect-secrets.sh` (`preToolUse`) | Že se `.env` dostane do konverzace přes `view` nebo shell **[T]** | Příkaz, který název souboru skryje. Skript sám o sobě říká, že není bezpečnostní hranice |
| `format.sh` (`postToolUse`) | Stylový šum v diffu | Soubory zapsané přes shell přesměrování, které žádný matcher na edity nevidí **[T]** |
| `run-tests.sh` (`agentStop`) | Že skončíš na červené a nevšimneš si | Chybějící testy. Varuje; neblokuje |
| Allow a deny pravidla launcheru | Únavu ze schvalování, edity `.env` | `--deny-tool='read(.env)'` blokuje nástroj `view`, ale ne `cat .env` **[T]**; tu mezeru zavírá hook |
| `kotlin-reviewer` | Prohřešky proti konvencím a logice, s kontextem repa | Cokoli mimo diff |
| Schválení plánu | Práci na špatném problému | Bugy uvnitř správného plánu |
| Worktree, `/rewind` | Škody na tvém pracovním stromu | Cokoli, co už je pushnuté |
| Sandbox ([Ukázka 8](08-permissions-sandbox.cs.md)) | Kam shell příkaz dosáhne. Ve výchozím stavu vypnutý **[D]** | Špatný kód, který smí běžet |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Prostředí | Funguje? | Poznámky |
|-----------|----------|----------|
| **Copilot CLI** | ✅ | Všechno v tomto návodu |
| **Plugin pro IntelliJ IDEA** | ⚠️ | Má agenta Plan a vlastní agenty, ale `agentStop` není mezi jeho publikovanými hook událostmi, takže testovací hook tam není potvrzený. Viz [Ukázka 12](12-intellij.cs.md) |
| **Copilot cloud agent** | ⚠️ | Dostaneš se k němu přes `/delegate`. Review probíhá na draft pull requestu místo v session. Viz [Ukázka 13](13-remote-agents.cs.md) |

## Když něco nefunguje

- **Autopilot končí s „permission denied“ u každého editu** → autopilot nic nepovoluje. Spusť
  `scripts/copilot-ws.sh --allow-tool='write'`.
- **`/plan` přesto změnil kód** → plan režim propouští shell příkazy, jejichž efekt neumí
  určit **[D]**. Zkontroluj `/diff`, případně `/rewind`, a nahlas to facilitátorovi.
- **Hook `agentStop` říká, že testy padají, ale agent tvrdil, že procházejí** → věř hooku.
  Zeptej se: *„Spusť ./gradlew test a vlož názvy selhávajících testů.“*
- **Ve worktree žádné varování z hooku, i když jsou webové testy rozbité** → není tam
  `web/node_modules`. Spusť `cd web && npm ci`.
- **`/rewind` soubor neobnovil** → upravil jsi ho až po Copilotovi, nebo je to kolo mimo to,
  co se zachytilo **[D]**. Použij `git restore`.
- **`/review` selže nebo nevrátí nic užitečného** → vestavění agenti mají vlastní výchozí
  model **[D]**; s omezeným seznamem modelů nemusí být dostupný. Použij `kotlin-reviewer`
  a nahlas to (viz [předletová kontrola](preflight.cs.md)).
- **Kredity mizí rychle** → dlouhé sessions posílají při každém volání celou konverzaci
  znovu. `/compact`, nebo `/new` s čerstvým specem, a nastav `/limits set max-ai-credits <n>`.

---

Dál: stejná smyčka bez session v terminálu, ze skriptu nebo z pipeline →
[Ukázka 11: Programatický režim a CI](11-programmatic-ci.cs.md).

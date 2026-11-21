> 🌍 Číst v jazyce: [English](13-remote-agents.md) | **Česky**

# Ukázka 13: Vzdálení a noční agenti

> ⚠️ **Nic z tohoto návodu se pro tohle repo nepouštělo.** Názvy příkazů a jejich
> jednořádkové popisy pocházejí z vlastní nápovědy CLI na 1.0.114. Všechno ostatní je **[D]**:
> podle dokumentace GitHubu a Coderu, tady netestováno. Ber to jako mapu pro pilot, ne jako
> recept.

## Co je agent bez dozoru?

Doteď jsi u session seděl. Agent bez dozoru pracuje, zatímco jsi na schůzce nebo spíš, a
výsledek zreviduješ potom. Na škále z [Ukázky 10](10-level-5-workflow.cs.md) je to úroveň 8
a sklouzne na úroveň 9 ve chvíli, kdy výsledek nikdo nezreviduje.

Když odejdeš, změní se tři věci:

1. **Na dotazy nikdo neodpovídá.** Žádost o oprávnění, která by se ptala, se zamítne; otázka
   dostane odpověď „the user is not available“. O oprávněních musíš rozhodnout, než odejdeš.
2. **Smyčky si nikdo nevšimne.** Cena a čas potřebují tvrdou stopku.
3. **Review se přesouvá na konec**, kde nejvíc láká ho přeskočit.

Jde to udělat třemi způsoby s velmi rozdílnou zralostí.

| Způsob | Kde agent běží | Předpoklady | Zralost |
|-----|----------------------|---------------|----------|
| **`/delegate`** na Copilot cloud agenta | Na GitHubu | Zapnutá politika Copilot CLI **a** politika Copilot cloud agenta; repozitář na GitHubu a dostupný cloud agentovi | Zdokumentovaná produktová featura **[D]** |
| **Lokální session, kterou držíš naživu a řídíš na dálku** (`/remote`, `/keep-alive`) | Na tvém stroji | Vzdálené ovládání povolené organizací; stroj zůstává zapnutý a online | V nápovědě CLI; závisí na nastavení organizace |
| **Coder workspace** | Na infrastruktuře 2N | Nasazený Coder, šablona s Copilot CLI, autentizace vůči GitHubu ve workspace | 2N to připravuje. Modul pro Copilot je komunitní. Poskládané vlastními silami a netestované |

## Způsob 1: `/delegate` na Copilot cloud agenta

`/delegate` pošle session na GitHub, kde na ní Copilot pracuje a otevře pull request.
`--base` vybírá cílovou branch.

Co se děje, krok za krokem **[D]**:

1. Napíšeš `/delegate <prompt>`, nebo začneš prompt znakem `&`.
2. Copilot nabídne, že tvoje nestagované změny commitne jako checkpoint na **novou branch**,
   kterou vytvoří. Když přijmeš, jsou výchozím bodem úlohy.
3. Cloud agent otevře **draft pull request**, pracuje na pozadí a po dokončení tě požádá
   o review. Pull request míří na tvou aktuální branch, pokud nepředáš
   `--base`.
4. CLI vypíše odkaz na pull request a na session agenta. `/resume` umí přepnout na
   session podle jejího ID v cloudové historii.

> */delegate Oprav bug s tahem, který nic nezmění: GameService.move nesmí přidat dlaždici, když board.move vrátí false. Nejdřív napiš padající test, bez spoléhání na náhodné dlaždice. Neměň engine/. Spusť ./gradlew :api:test a počty uveď v popisu pull requestu.*

Předpoklady **[D]**:

- Zapnutá musí být jak politika Copilot CLI, tak politika Copilot cloud agenta. V Copilot
  Business to řídí administrátor. Svůj stav si zkontroluj na
  `github.com/settings/copilot/features`.
- Repozitář musí být takový, na kterém cloud agent smí pracovat. U repozitářů organizace to
  spravují její administrátoři a u repozitářů vlastněných spravovanými uživatelskými účty to
  dostupné není.

**Commitnuté soubory tohoto repa platí i v cloudu** **[D]**. Snadno se na to zapomíná:

| Soubor | V úloze cloud agenta |
|------|----------------------|
| `.github/copilot-instructions.md`, `.github/instructions/` | Čtou se |
| `.github/skills/`, `.github/agents/` | Podporované |
| `.github/hooks/hooks.json` | Načte se. Respektují se jen položky `bash` a `command`, rozhodnutí `ask` se změní v deny a blok v `agentStop` se počítá do časového limitu úlohy |
| `.github/copilot/settings.json` (`extraKnownMarketplaces`, `enabledPlugins`) | Čte se, bez lokálního přepsání |
| `scripts/copilot-ws.sh` | Nehraje roli. Jeho allow a deny přepínače patří k lokálnímu spuštění |

Důsledky pro tohle repo: `block-destructive.sh`, `protect-secrets.sh`, `format.sh` a
`run-tests.sh` běží i v úloze. První tři potřebují `jq`; `protect-secrets.sh` volání záměrně
pustí dál a nahlásí, že pojistka není aktivní, když `jq` chybí. Pokud z `run-tests.sh`
uděláš blokující bránu (cvičení 3) a commitneš ji, platí brána i pro cloudové úlohy a čas,
který zabere, se počítá do časového limitu úlohy.

## Způsob 2: drž lokální session naživu a řiď ji

Session běží na tvém stroji s tvými nástroji, tvými hooky a tvými pravidly spuštění. Tvou
nepřítomnost jí pomůžou přežít dva příkazy:

| Příkaz | Co dělá |
|---------|--------------|
| `/remote on` | Umožní ti řídit session z GitHubu na webu nebo v mobilu. `/remote off` odpojí, `/remote show` hlásí stav |
| `/keep-alive on` | Zabrání stroji v uspání. Dál `off`, `busy` (jen dokud agent pracuje), nebo doba jako `30m`, `2h`, `1d`. Bez argumentů ukáže stav |
| `copilot --connect [<session-id>]` | Připojí CLI přímo ke vzdálené session, volitelně podle ID session nebo úkolu |

Pokud vzdálené ovládání není zapnuté, musí ho povolit administrátor organizace. Stroj musí
zůstat online **[D]** a `/rewind` není u session se vzdáleným ovládáním dostupný **[D]**.

Postup pro dlouhý úkol:

1. Spusť s explicitními pravidly, ve worktree:
   `scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)'`
2. `/new worktree`, nebo pracuj na vyhrazené branchi.
3. `/plan <spec>`, přečti si plán, přijmi ho do autopilota.
4. `/limits set max-ai-credits <n>`.
5. `/keep-alive busy`, pak `/remote on`.
6. Odejdi. Jestli chceš, nakoukni z telefonu.

Co autopilot dělá, když jsi pryč, podle `copilot help permissions` a `copilot help limits`:

- Žádost o nástroj, která by se ptala, se zamítne.
- Na otázku pro tebe přijde odpověď „not available“; agent hádá, nebo skončí se shrnutím.
- Po 5 automatických pokračováních se pozastaví, pokud `--max-autopilot-continues` není vyšší.
- Při rate limitu se nikdo neptá, takže model přepne na Auto, jen když je zapnuté nastavení
  `continueOnAutoMode`.

Skriptovaná varianta je běh `-p` z [Ukázky 11](11-programmatic-ci.cs.md) v terminálovém
multiplexeru. Všechny přepínače existují; tahle kombinace se nezkoušela:

```bash
scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)' \
    --autopilot --max-autopilot-continues 20 --max-ai-credits 300 \
    --trust-folder --no-ask-user --share="$HOME/overnight-session.md" \
    -p "<spec>"
```

## Způsob 3: Coder Workspaces

**Co je Coder.** Self-hosted platforma pro vzdálená vývojová prostředí. Administrátor napíše
šablonu v Terraformu; každý vývojář dostane workspace z ní postavený.
Agent pak běží ve workspace v síti 2N místo na tvém notebooku, takže může běžet dál, i když
je notebook zavřený.

**Co 2N připravuje.** Coder Workspaces pro vzdálené noční agenty. V době psaní návodu nebyly
k dispozici žádné podrobnosti. Zeptej se, než s tím začneš plánovat.

**Aktuální názvy.** Coder přejmenoval několik svých AI featur a starší články používají
staré názvy **[D]**:

| Starý název | Aktuální | Co vědět |
|----------|---------|--------------|
| Coder Tasks | **Coder Agents** | Tasks byly ve v2.34 označené jako zastaralé a odstraněné, včetně API. Coder Agents provozuje vlastní agentní smyčku v řídicí vrstvě Coderu |
| AI Bridge | **AI Gateway** (a AI Gateway Proxy) | Součást AI Governance; potřebuje licenci Premium |
| Agent Boundaries | **Agent Firewall** | Premium; postupně se ruší ve prospěch sandboxovaných šablon workspace |
| — | **Agent Relay** | Beta, Premium. Zdokumentovaní klienti jsou Claude Code a Cursor, ne Copilot |

Za „agentem v Coderu“ se schovávají dvě různé věci:

- **Coder Agents** je vlastní agent Coderu. Mezi jeho zdokumentovanými poskytovateli modelů
  GitHub Copilot není, takže by neběžel na tvé licenci Copilotu a nepočítal by se jako
  používání Copilot CLI.
- **Copilot CLI uvnitř workspace** je stejná binárka `copilot` jako na tvém notebooku, se
  stejnými soubory repa. Tohle je varianta, která sedí k tomuhle workshopu.

**Modul z registru** **[D]**. Copilot CLI se do workspace instaluje modulem z registru
Coderu. Je ve jmenném prostoru `coder-labs` a označený `verified: false`: komunitní
modul, ne takový, za který Coder ručí. Základní použití, jak je v jeho README:

```hcl
module "copilot" {
  source   = "registry.coder.com/coder-labs/copilot/coder"
  version  = "1.0.1"
  agent_id = coder_agent.example.id
  workdir  = "/home/coder/project"
}
```

Co o něm vědět **[D]**:

- README připíná `1.0.1`, ale registr v době kontroly neuváděl nic novějšího než `1.0.0`.
  Připnutí na `1.0.1` by se nevyhodnotilo.
- Verze 1 Copilot CLI **jen instaluje a konfiguruje**. Podporu Coder Tasks zahodila.
  `copilot` spouštíš sám, například z `coder_app`.
- Příklad launcheru v README spouští `copilot --allow-all-tools`. Nahraď to explicitními
  pravidly (viz [Bezpečnostní pravidla](#bezpečnostní-pravidla-pro-běhy-bez-dozoru)).
- Užitečné vstupy: `github_token` (exportovaný jako `COPILOT_GITHUB_TOKEN`), `copilot_version`
  (výchozí `latest`; připni ji), `copilot_model`, `managed_settings` (zapisuje se do
  `/etc/github-copilot/managed-settings.json`), `mcp`. `base_copilot_config` přepíše
  `~/.copilot/settings.json` při každém startu.
- Copilot neumí použít vlastní base URL. S AI Gateway od Coderu funguje jen přes AI
  Gateway Proxy (`HTTPS_PROXY` a `NODE_EXTRA_CA_CERTS`) a každý uživatel se dál přihlašuje ke
  GitHubu vlastním tokenem.

**Co je netestované.** Všechno. Coder nedokumentuje žádný noční vzor pro Copilot CLI; s tímhle
modulem by se skládal ručně, nejpravděpodobněji jako skriptovaný běh `-p` ze Způsobu 2
v terminálu workspace. Otevřené otázky pro pilot: má image workspace JDK,
Node a `jq` pro hooky repa; jak se GitHub přihlášení uživatele dostane do workspace; objeví
se běhy jako používání CLI v metrikách 2N; a kdo si všimne, když se běh ve 2 ráno zastaví.

## Který způsob kdy

| Situace | Použij |
|-----------|-----|
| Dobře specifikovaný úkol, repozitář je na GitHubu, politika cloud agenta je zapnutá | `/delegate` |
| Úkol potřebuje tvoje lokální prostředí, běžící API, nebo soubory, které nejsou pushnuté | Způsob 2 |
| Chceš nakouknout a přesměrovat práci z telefonu | Způsob 2 s `/remote on` |
| Notebook musí být zavřený, nebo úloha běží déle než jednu noc | Coder, až ho 2N nabídne; do té doby `/delegate` |
| Politika pro cloud agenta nebo vzdálené ovládání je vypnutá | Obyčejná autopilot session, zatímco jsi na obědě, s `/keep-alive busy` |
| Úkol je vágní | Žádný. Nejdřív napiš spec; agent bez dozoru vágní spec zesílí |

## Ranní review

Nemerguj noční výsledek jen proto, že tam je. Zkontroluj, v tomhle pořadí:

1. **Doběhl, a proč se zastavil?** Přečti si poslední zprávu. „Zastaveno na limitu kreditů“
   a „zastaveno po pěti pokračováních“ není „hotovo“.
2. **Velikost diffu.** `git diff --stat <base>...<branch>`. Oprava, která měla být ve třech
   souborech a je ve třiceti, zašla někam, kam jsi ji neposílal. Hledej změny pod `.github/`,
   v hook skriptech a v testovacích souborech, které už existovaly.
3. **Testy, které pustíš ty.** `./gradlew build`, pak `cd web && npm ci && npm test`. Nepřijímej
   vlastní report agenta.
4. **Byl nějaký test oslabený nebo smazaný?** Přečti si celý diff každého existujícího
   testovacího souboru.
5. **Hlídá nový test tu změnu?** Použij prompt „vrať změnu a pusť znovu“ z
   [Ukázky 10](10-level-5-workflow.cs.md).
6. **Nezávislé review.** *„Použij agenta kotlin-reviewer k review změn na této branchi
   proti main.“* Pak `/review`, a `/security-review`, pokud se změna dotýká zpracování
   vstupu nebo závislostí.
7. **Zamítnutá volání a varování hooků.** V lokální session se vrať v historii a hledej řádky
   `Denied by preToolUse hook` a `run-tests hook:`. U běhu `-p` použij jednořádkový příkaz
   „Tool calls that failed“ z [Ukázky 11](11-programmatic-ci.cs.md).
8. **Utracené kredity.** `/usage` v session, nebo soubor z `--usage-output-file`. Spotřeba
   úlohy cloud agenta se vykazuje na GitHubu, ne v CLI.
9. **Přepis.** `/share file <path>`, nebo soubor z `--share`. Prolétni, co zkoušel a co
   vzdal; slepé uličky ti řeknou, jestli byl spec jasný.
10. **Rozhodni o úrovni.** Pokud jsi přečetl každý řádek, napiš to do pull requestu. Pokud jsi
    mergoval na základě důkazů, napiš jakých.

## Bezpečnostní pravidla pro běhy bez dozoru

| Pravidlo | Jak |
|------|-----|
| Explicitní allow pravidla, ne allow-all | `--allow-tool='shell(./gradlew:*)'`, `shell(npm test)`, `write`. Nikdy `--yolo` ani `/allow-all` u běhu, který nesleduješ. Deny pravidla vyhrávají nad každým allow |
| Zakaž, co se stát nesmí | `--deny-tool='shell(git push)'`, `--deny-tool='write(.env)'`. Přidej `write(.github/**)`, pokud agent nemá co měnit vlastní pojistky |
| Nebo použij sandbox | `/sandbox enable`, nebo `--sandbox` pro jednu session. Omezuje, kam shellové příkazy dosáhnou. Hooky pak běží taky uvnitř něj a hook, který pouští `./gradlew test`, může potřebovat cesty navíc **[D]** |
| Limit kreditů | `--max-ai-credits <n>` nebo `/limits set max-ai-credits <n>`. Počítá celou session včetně subagentů. Je to měkký strop |
| Limit kol | `--max-autopilot-continues <n>` |
| Izolace | Worktree (`/new worktree`) nebo vyhrazená branch. Nikdy branch, na které pracuješ |
| Nech si hooky | Spouštěj v důvěryhodné složce; u běhů `-p` předej `--trust-folder`. Bez něj se hooky repozitáře přeskočí |
| Žádné tajné údaje v dosahu | Žádný `.env` se skutečnými hodnotami v checkoutu. Hooky jsou pojistky, ne hranice |
| Stopa, která se dá zrevidovat | `--share=<path>`, nebo `/share`, než session zavřeš |
| Člověk na konci | Ranní review výše. Bez něj je to úroveň 9 |

## Kde to funguje: CLI, IntelliJ, cloud agent

| Platforma | Funguje? | Poznámky |
|---------|--------|-------|
| **Copilot CLI** | ✅ | `/delegate`, `/remote`, `/keep-alive`, `/autopilot` jsou příkazy CLI |
| **Plugin pro IntelliJ IDEA** | ❓ | Pro tenhle návod se nezkoumalo. Použij CLI v terminálu IDE |
| **Copilot cloud agent** | ⚠️ | Cíl příkazu `/delegate`. Čte instrukce, skills, agenty, hooky a nastavení pluginů z repa **[D]** |

## Když něco nefunguje

- **`/delegate` se odmítne** → jedna ze dvou politik je vypnutá, nebo repozitář není
  cloud agentovi dostupný. Zkontroluj `github.com/settings/copilot/features`, pak se zeptej
  admina.
- **Delegovaný pull request míří na špatnou branch** → ve výchozím stavu míří na tvou
  aktuální branch. Použij `/delegate --base <branch>`.
- **`/remote on` říká, že vzdálené ovládání není zapnuté** → musí ho povolit administrátor
  organizace.
- **Session umřela, když se notebook uspal** → `/keep-alive on` nebo `busy`, než odejdeš.
- **Autopilot se po pár tazích zastavil a nic neudělal** → každá úprava byla zamítnutá.
  Autopilot žádná oprávnění neuděluje; spouštěj s allow pravidly.
- **Zastavil se předčasně se zprávou o kreditech** → limit je měkký strop a u posledního
  volání blízko limitu se vypnou nástroje. Zvyš ho přes `/limits set max-ai-credits <n>` a
  pokračuj.
- **Hooky se v cloudové úloze chovají jinak** → respektují se tam jen položky `bash` a
  `command` a `ask` se změní v deny **[D]**. Zkontroluj, že image úlohy má `jq`.
- **`version = "1.0.1"` modulu Coderu se nevyhodnotí** → registr měl jako nejnovější verzi
  `1.0.0`. Než verzi připneš, zkontroluj registr.

---

Dál: orchestrace několika agentů souborem workflow mimo CLI →
[Ukázka 14: Conductor](14-conductor.cs.md).

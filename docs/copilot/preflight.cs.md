> 🌍 Číst v jazyce: [English](preflight.md) | **Česky**

# Předletová kontrola pro facilitátora

Projdi to před workshopem: část A s administrátorem Copilota ve 2N, část B na **jednom
stroji účastníka, v síti 2N, s účtem účastníka**. Několik nastavení organizace
vyřadí cvičení bez jakékoli chybové hlášky; přizpůsobení se prostě nenačte.
Hodina tady zachrání workshop.

Odkud které tvrzení pochází:

- **[T]** otestováno: spuštěno v tomto repozitáři na Copilot CLI 1.0.114, na osobním testovacím
  účtu, který **není** spravovaný 2N. Očekávané výstupy v části B pocházejí z toho stroje.
- **[D]** podle dokumentace; netestováno. Celá část A je **[D]**: žádná politika 2N nebyla
  k dispozici, aby šlo proti ní testovat.

## Část A: otázky pro administrátora

Ptej se na **politiky** organizace a enterprise a zvlášť na **spravovaná nastavení** (managed
settings): soubor `managed-settings.json` doručený z repozitáře `.github-private` daného
enterprise, přes MDM, nebo jako lokální soubor. Jsou to různé mechanismy a na ten druhý se
snadno zapomene.

### Přístup a účty

| Otázka | Když je odpověď nepříznivá | Co to zasáhne |
|--------|----------------------------|---------------|
| Je politika **Copilot CLI** zapnutá pro každého účastníka? | Nefunguje nic | Všechno |
| Jsou GitHub účty účastníků **Enterprise Managed Users**? | Spravovaný účet obecně nejde přidat jako collaborator do repozitáře mimo jeho enterprise. Privátní repo `klesajos/qti-copilot` je pak mimo dosah a workshop potřebuje **mirror uvnitř organizace 2N**. Gisty spravovaní uživatelé taky nemají k dispozici | Klonování repa; cvičení 4; `/share gist` v [10](10-level-5-workflow.cs.md) |
| Kde budou **GitHub issues pro cvičení 4**? | Musí být v repozitáři, který může číst každý účastník účtem, pod kterým je CLI přihlášené. S mirrorem je vytvoř v mirroru | Cvičení 4 |
| Které **modely** jsou na allow-listu? Je k dispozici `auto`? | Id modelu, který není povolený, je od CLI 1.0.109 chyba. Repo žádné natvrdo neobsahuje a Conductor používá `default_model: auto`. Vestavění agenti mají vlastní výchozí modely (`code-review`, `explore`, `task`, ...) | `/model` všude; `/review` v [10](10-level-5-workflow.cs.md); `--judge-model` v [09](09-validate-eval.cs.md); [14](14-conductor.cs.md) |
| Účtuje se 2N v **AI kreditech**, nebo pořád v premium requestech (CLI ukazuje to, co používá tarif)? Kolik účastníkovi tento měsíc zbývá a je zapnutá dodatečná placená spotřeba? | Evaly a běhy fleet pálí rozpočet rychle. Na 100 % volání modelu selhávají až do resetu | [07](07-orchestration.cs.md), [09](09-validate-eval.cs.md), [14](14-conductor.cs.md) |
| Je tam **firemní proxy nebo privátní certifikační autorita**? | Otevřené issue CLI hlásí, že MCP registr je na macOS s privátní CA nedostupný, což pak zablokuje každý MCP server | [00](00-install.cs.md), [04](04-mcp.cs.md) |

### Politiky organizace

| Politika | Co se rozbije, když je vypnutá nebo restriktivní | Co to zasáhne |
|----------|--------------------------------------------------|---------------|
| **MCP servers in Copilot** | MCP servery třetích stran se nespustí. Od CLI 1.0.112 se nespustí ani vestavěný GitHub MCP server. Politika je vypnutá, dokud ji administrátor nezapne | [04](04-mcp.cs.md); cvičení 4, které čte issues přes vestavěný server |
| **Restrict MCP access to registry servers** („Registry only“) | Běží jen servery z registru. Porovnává se podle jména nebo ID serveru. Kontrola selhává uzavřeně (fail closed): když registr není dosažitelný, je zablokováno všechno | [04](04-mcp.cs.md); MCP server `copilot-evals` z GitHub Copilot Evals v [09](09-validate-eval.cs.md) |
| **Copilot cloud agent** | `/delegate` potřebuje tuhle politiku **a** politiku CLI. Repozitář navíc musí být pro cloud agenta dostupný | [13](13-remote-agents.cs.md) |
| **Remote control** CLI sessions | `/remote on` ohlásí, že to musí povolit administrátor | [13](13-remote-agents.cs.md) |
| **Copilot Memory** | Preference na úrovni uživatele jsou vypnuté, dokud je administrátor nezapne; fakta na úrovni repozitáře jsou ve výchozím stavu zapnutá pro všechny repozitáře. Se zapnutou pamětí může dřívější session ovlivnit pozdější. Na workshop `/memory off` | Reprodukovatelnost cvičení a [09](09-validate-eval.cs.md) |
| **Allow use of Copilot CLI billed to the organization** | `copilot` v GitHub Actions s vestavěným `GITHUB_TOKEN` selže. Alternativou je personal access token | [11](11-programmatic-ci.cs.md); `github/evals-action` v [09](09-validate-eval.cs.md) |
| **Experimentální režim a preview featury** (`--experimental`, `/settings experimental on`; v IDE politika „Editor preview features“) | Žádné dynamické workflows (`copilot workflow run` skončí s kódem 2), žádné příkazy `/eval` z GitHub Copilot Evals. V IntelliJ jsou preview featury skryté | [07](07-orchestration.cs.md), [09](09-validate-eval.cs.md), [12](12-intellij.cs.md) |
| **Content exclusion** | Vyloučené soubory se nepoužijí jako kontext. Zkontroluj, že žádné pravidlo neodpovídá cestám tohoto repa | Jakékoli cvičení na odpovídající cestě |

### Spravovaná nastavení

Pokud je nějaký soubor nasazený, vyžádej si přímo ten soubor. Každý z těchto klíčů vypíná část repa.

| Klíč | Co se rozbije, když je nastavený | Co to zasáhne |
|------|----------------------------------|---------------|
| `strictPluginOnlyCustomization` (`true`, nebo pole z `skills`, `agents`, `hooks`, `mcp`, `extensions`) | Samostatná přizpůsobení z repozitáře a od uživatele se v těchto kategoriích nenačtou: `.github/skills/`, `.github/agents/`, `.github/hooks/`, `.mcp.json`. Fungují jen ta dodaná pluginem. Hlášení jednoho uživatele ukazuje text `blocked by enterprise customization lockdown` | [02](02-skills.cs.md), [03](03-hooks.cs.md), [04](04-mcp.cs.md), [05](05-agents.cs.md) a všechno v [10](10-level-5-workflow.cs.md), co stojí na hoocích a na `kotlin-reviewer` |
| `allowManagedHooksOnly` | Hooky repozitáře neběží: žádný `block-destructive`, `protect-secrets`, `format`, `run-tests` | [03](03-hooks.cs.md), [08](08-permissions-sandbox.cs.md), [10](10-level-5-workflow.cs.md); cvičení 3 |
| `strictKnownMarketplaces` | Marketplace v repu `qti-copilot` na seznamu není, takže se `2048-dev` nenačte. Klíč vypíná i vestavěné marketplaces; `[]` je úplný lockdown. Stejně je zablokovaný `github/evals` | [06](06-plugins.cs.md), pluginové části [05](05-agents.cs.md) a [09](09-validate-eval.cs.md) |
| `enabledPlugins` (spravované) | `false` u pluginu ho zablokuje; výchozí hodnoty repozitáře to nemůžou přebít | [06](06-plugins.cs.md) |
| `allowManagedMcpServersOnly`, `allowedMcpServers`, `deniedMcpServers` | Server, který si nakonfiguruje účastník, je zablokovaný. S allow-listem je zablokovaný i server, jehož URL nebo příkaz obsahuje nevyhodnocenou `${VAR}`. Dej administrátorovi přesný `command` a `args`, nebo URL, schváleného Jira serveru | [04](04-mcp.cs.md) |
| `permissions.disableBypassPermissionsMode: "disable"` | `--allow-all`, `--yolo`, `--allow-all-tools` a `/allow-all` přestanou fungovat. Návody používají explicitní pravidla `--allow-tool`, takže se rozbije málo; zdokumentované příklady, které používají `--yolo`, ano | [08](08-permissions-sandbox.cs.md), [11](11-programmatic-ci.cs.md), [13](13-remote-agents.cs.md) |
| `permissions.deny`, `permissions.ask`, `permissions.allow` | Platí i v režimu allow-all. Jakmile je nastavený jakýkoli seznam, operace, která neodpovídá žádnému, spadne do výchozího „ask“, a „ask“ je v bězích `-p` a v autopilotu **deny**. `./gradlew` a `npm` pak musí být na spravovaném allow-listu | [08](08-permissions-sandbox.cs.md), [10](10-level-5-workflow.cs.md), [11](11-programmatic-ci.cs.md), [13](13-remote-agents.cs.md) |
| `permissions.disableAssistedPermissionsMode` | Žádný režim asistovaného schvalování, žádné `--assisted-approval` | [08](08-permissions-sandbox.cs.md), [11](11-programmatic-ci.cs.md) |
| Spravovaná nastavení sandboxu | Organizace může sandbox vyžadovat. Hooky pak běží uvnitř sandboxu a hook, který spouští Gradle nebo npm, může potřebovat cesty navíc | [03](03-hooks.cs.md), [08](08-permissions-sandbox.cs.md) |

### Nástroje mimo Copilot

| Otázka | Proč na tom záleží | Co to zasáhne |
|--------|--------------------|---------------|
| Smějí si účastníci nainstalovat **`@microsoft/vally-cli`** (npm, v `package.json` zafixovaný na 0.21.0)? | Je to engine pro evaly. npm skripty repa mu vypínají telemetrii. Používá přihlášení Copilota a utrácí AI kredity | [09](09-validate-eval.cs.md) |
| Smějí si účastníci nainstalovat **Microsoft Conductor** (`uv tool install` z Git repozitáře `microsoft/conductor`, v0.1.47, MIT, beta)? | Stahuje se z github.com se závislostmi z pypi.org. PyPI balíček jménem `conductor-cli` je nesouvisející nástroj; ten neinstaluj | [14](14-conductor.cs.md) |
| Je přijatelný plugin **GitHub Copilot Evals** (veřejné preview, GitHub Limited Use Source License, vlastní MCP server)? | Repo ho nevendoruje; návod ho jen popisuje | [09](09-validate-eval.cs.md) |
| Která **verze IntelliJ pluginu** je nasazená a které **pole metrik** 2N čte jako „využití CLI“? | Plugin 1.15.0–1.19.x počítá agentní sessions špatně, některé z nich jako CLI. Od 1.20.0 je přiřazení správné | [12](12-intellij.cs.md) |
| Je k dispozici **Coder** pro pilot a s jakou šablonou? | Nic ze sekce o Coderu nebylo otestováno | [13](13-remote-agents.cs.md) |
| Který **Jira MCP server** je schválený a jaká je jeho přesná URL nebo příkaz? | Repo dodává jen `.mcp.json.example` s placeholderem | [04](04-mcp.cs.md) |

## Část B: kontrola stroje

Spouštěj z kořene repozitáře. U každého kroku je uvedeno, co vypsal testovací stroj **[T]**.
Jiný výsledek na stroji ve 2N ukazuje na nastavení jmenované v posledním sloupci.

| # | Příkaz | Očekávaný výsledek | Když ne |
|---|--------|--------------------|---------|
| 1 | `copilot --version` | `GitHub Copilot CLI 1.0.114.` nebo novější | [00-install](00-install.cs.md) |
| 2 | `node --version`; `java -version`; `jq --version`; `git --version` | Node 24.15 nebo novější, nebo 26. Jakékoli JDK 17–27. `jq` a `git` jsou k dispozici | Hooky potřebují `jq`; bez něj je `protect-secrets` neaktivní |
| 3 | `ls -l "/Library/Application Support/GitHubCopilot/managed-settings.json"` | `No such file or directory` na nespravovaném Macu | Pokud soubor existuje, projdi ho proti tabulce spravovaných nastavení. Windows: `%ProgramFiles%\GitHubCopilot\managed-settings.json`; Linux: `/etc/github-copilot/managed-settings.json` **[D]**. Nastavení doručená ze serveru tady žádný soubor nenechávají |
| 4 | `./gradlew build` | Návratový kód 0 | JDK nebo síť (Gradle stahuje JDK 21 a závislosti) |
| 5 | `cd web && npm ci && npm test` | `Tests  7 passed (7)` | Verze Node, přístup k npm registru |
| 6 | Soubory s instrukcemi (níže) | Tři řádky | Špatný adresář, nebo lockdown přizpůsobení |
| 7 | `copilot mcp list` | `Builtin servers:` s `github-mcp-server (http)` | Varování o politice tady znamená politiku MCP; viz část A |
| 8 | Důvěryhodný běh `-p` (níže) | Devět řádků | Viz tabulka pod ním |
| 9 | `npm ci && npm run eval:lint` | `✔ evals/board-tests/eval.yaml is valid` a `✔ evals/game-explorer/eval.yaml is valid` | Vally nejde nainstalovat |
| 10 | `conductor --version`; `conductor validate conductor/test-coverage-audit.yaml` | `Conductor v0.1.47`; rámeček s titulkem `Validation Successful` | Conductor nejde nainstalovat |
| 11 | `conductor doctor` | Řádek providera `copilot` ho ukazuje jako nainstalovaný, s nalezenými přihlašovacími údaji | Přihlášení Copilota, nebo Conductor starší než v0.1.47 proti CLI 1.0.113 nebo novějšímu **[D]** |
| 12 | Běh s GitHub MCP (níže) | Tři řádky | Politika MCP, nebo síť |

**Krok 6**: které soubory s instrukcemi by session načetla.

```bash
copilot instruction list --json | jq -r '.[] | "\(.sourcePath)\t\(.applyTo // [] | join(","))"'
```

```
.github/copilot-instructions.md
.github/instructions/api.instructions.md	api/**/*.kt
.github/instructions/engine.instructions.md	engine/**/*.kt
```

**Krok 8**: jeden levný běh, který dokáže přihlášení, přístup k modelu, důvěru složce, projektový
skill, oba agenty, plugin i hooky. Požádá Copilota, aby přečetl `.env`, což musí hook
`protect-secrets` odmítnout. Soubor nemusí existovat. Stálo to asi 0,07 AI
kreditu **[T]**.

```bash
events=$(mktemp)
copilot -p "Use the view tool to read the file .env in the repository root and print its first line. If the read is refused, quote the refusal message and stop." \
    --output-format json --trust-folder --no-ask-user > "$events"

jq -r 'select(.type == "session.start") | "cli\t\(.data.copilotVersion)"' "$events"
jq -r 'select(.type == "session.auto_mode_resolved") | "model\t\(.data.chosenModel)"' "$events"
jq -r 'select(.type == "session.skills_loaded") | .data.skills[]
       | select(.source == "project" or .source == "plugin") | "skill\t\(.source)\t\(.commandName)"' "$events" | sort -u
jq -r 'select(.type == "session.custom_agents_updated") | .data.agents[] | "agent\t\(.source)\t\(.id)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_complete" and .data.success == false) | "denied\t\(.data.error.message)"' "$events"
tail -n 1 "$events" | jq -r '"exit\t\(.exitCode)"'
```

```
cli	1.0.114
model	<model-id>
skill	plugin	2048-dev:build-test
skill	project	board-tests
agent	plugin	2048-dev:game-explorer
agent	project	board-test-writer
agent	project	kotlin-reviewer
denied	Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need.
exit	0
```

Řádek `model` ukazuje, na co se `auto` vyhodnotilo; zapiš si to pro 2N. Zbytek čti takhle:

| Řádek chybí nebo je jiný | Pravděpodobná příčina |
|--------------------------|-----------------------|
| Vůbec žádný výstup, soubor je prázdný | Nejsi přihlášený (`copilot login`), politika CLI je vypnutá, nebo není k dispozici žádný model. Spusť příkaz znovu bez `> "$events"` a přečti si chybu |
| Chybí `skill project board-tests` | `strictPluginOnlyCustomization` pokrývá skills, nebo nejsi v kořeni repa |
| Chybí řádky `agent project ...` | Stejný klíč pro agenty. Podívej se na `data.warnings` a `data.errors` v `session.custom_agents_updated` |
| Chybí dva řádky `plugin` | `strictKnownMarketplaces` nebo spravované `enabledPlugins`, nebo byl vynechán `--trust-folder` |
| Žádný řádek `denied` a odpověď říká, že soubor neexistuje | Hooky se nenačetly: `allowManagedHooksOnly`, `strictPluginOnlyCustomization` pro hooky, chybí `--trust-folder`, nebo chybí `jq` |
| `denied` s jinou zprávou | Jiné pravidlo se k tomu dostalo dřív. V pořádku, pokud `.env` zůstane nepřečtený |
| Osobní skills v nefiltrovaném seznamu | Normální. Načítají se i skills z `~/.copilot/skills` a `~/.agents/skills`. Prosakují i do eval trialů; viz [09](09-validate-eval.cs.md) |

`copilot plugin list --json` tenhle krok **nenahradí**: mimo session ukazuje
jen pluginy nainstalované uživatelem a vestavěné, ne ten, který zapíná tohle repo **[T]**.

**Krok 12**: vestavěný GitHub MCP server, přes který čtou issues MCP demo v [04](04-mcp.cs.md) a
cvičení 4. Jeho výchozí sada nástrojů závisí na tom, jestli je nainstalované `gh`
**[T]**: s `gh` na `PATH` vystavuje 6 nástrojů a žádný pro issues nebo pull requesty; bez
`gh` jich vystavuje 24, včetně `list_issues`, `issue_read` a `pull_request_read`. Cvičení 4
proto spouští Copilota se dvěma explicitními nástroji a tahle kontrola taky. Čte veřejný
repozitář, nepotřebuje žádné pravidlo allow a stála asi 0,2 AI kreditu **[T]**.

```bash
events=$(mktemp)
copilot -p "Use the GitHub MCP server tool list_issues to list the 3 most recently updated open issues in the public repository github/copilot-cli. Reply with number and title only. Do not use the shell." \
    --add-github-mcp-tool list_issues --add-github-mcp-tool issue_read \
    --output-format json --trust-folder --no-ask-user > "$events"

jq -r 'select(.type == "session.mcp_server_tools_loaded") | "mcp\t\(.data.serverName)\t\(.data.toolCount)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_start") | "tool\t\(.data.toolName)"' "$events" | sort -u
jq -r 'select(.type == "tool.execution_complete") | "success\t\(.data.success)"' "$events" | sort -u
```

```
mcp	github-mcp-server	2
tool	github-mcp-server-list_issues
success	true
```

Žádný řádek `mcp` znamená, že se vestavěný server nespustil; u CLI 1.0.112 a novějšího takhle
vypadá vypnutá politika „MCP servers in Copilot“ **[D]**. Řádek `tool` s `bash` místo toho
znamená, že agent sáhl po shellu.

Tahle kontrola dokazuje server a přepínače, ne workshopové repo. Aby MCP demo a
cvičení 4 fungovaly, **musí workshopové repo existovat na GitHubu, každý klon potřebuje svůj GitHub
remote a repo potřebuje aspoň jedno issue**. S mirrorem v organizaci 2N to
znamená mirror.

**Volitelné, interaktivní, dvě minuty.** Spusť `scripts/copilot-ws.sh`, na otázku o důvěře
složce odpověz „Yes, and remember this folder“ a spusť:

- `/env`: instrukce, skills, agenti, hooky a pluginy, které se načetly.
- `/model`: seznam, ze kterého si účastník smí vybrat.
- `/review` na jakékoli malé necommitnuté změně. Vestavění agenti používají vlastní výchozí modely. Na
  testovacím účtu vestavěný subagent `task` jednou selhal s
  `400 The requested model is not supported.`, když jeho výchozí model nebyl k dispozici (viděno
  v zaznamenaném běhu, pro tenhle checklist nereprodukováno). Pokud `/review` ve 2N selže, je
  prvním podezřelým seznam modelů.
- `/remote show`, pokud je na programu [13](13-remote-agents.cs.md).

Pak jednou spusť smoke check z [Ukázky 11](11-programmatic-ci.cs.md). Měl by vypsat
`PASS board-tests skill was loaded`.

## Co vyškrtnout, když je něco zablokované

| Zablokováno | Vyškrtni | Ponech, nebo udělej místo toho |
|-------------|----------|--------------------------------|
| Samostatná přizpůsobení (`strictPluginOnlyCustomization`) | Hands-on části [02](02-skills.cs.md), [03](03-hooks.cs.md), [05](05-agents.cs.md) tak, jak jsou napsané | Ukaž je jako demo na stroji facilitátora. Pokud jsou marketplaces povolené, přesuň předem skill a agenty do pluginu `2048-dev` |
| Hooky repozitáře (`allowManagedHooksOnly`) | Hands-on [03](03-hooks.cs.md); cvičení 3 | Vysvětli mechanismus na souborech. V [08](08-permissions-sandbox.cs.md) a [10](10-level-5-workflow.cs.md) se opři o pravidla `--deny-tool` a jasně řekni, že `cat .env` pak blokované není |
| Marketplace v repu (`strictKnownMarketplaces`) | Hands-on [06](06-plugins.cs.md); pluginové části [05](05-agents.cs.md) a [09](09-validate-eval.cs.md) | Požádej administrátora, aby workshopový marketplace přidal na seznam, nebo jen demo |
| MCP | Hands-on [04](04-mcp.cs.md); MCP cesta cvičení 4 | Projdi `.mcp.json.example`. Ve cvičení 4 čti issues přes `gh` CLI, pokud je nainstalované a povolené |
| GitHub MCP server neukazuje žádné nástroje pro issues | Nic | Očekávané, když je `gh` na `PATH`. Spouštěj s `--add-github-mcp-tool list_issues --add-github-mcp-tool issue_read` |
| Repo ještě není na GitHubu, nebo nemá žádná issues | MCP demo v [04](04-mcp.cs.md); cvičení 4 | Před workshopem pushni repo (nebo mirror) a otevři aspoň jedno issue. Do té doby předváděj `list_issues` na veřejném repozitáři, jako v kroku 12 |
| Allow-all | Nic | Návody používají explicitní pravidla |
| Spravovaná pravidla `ask` na shellové příkazy | Části s autopilotem a `-p` v [10](10-level-5-workflow.cs.md), [11](11-programmatic-ci.cs.md), [13](13-remote-agents.cs.md) | Interaktivní režim, kde jde na dotaz odpovědět |
| Experimentální režim | Dynamické workflows v [07](07-orchestration.cs.md); `/eval` v [09](09-validate-eval.cs.md) | `/fleet` a vlastní agenti; Vally přes `npm run eval` |
| Vally | Běhy evalů v [09](09-validate-eval.cs.md) | `evals/plugin-ab.sh`, který potřebuje jen `copilot` a `jq`; nebo ukaž zaznamenané výsledky |
| Conductor | Hands-on [14](14-conductor.cs.md) | Přečti workflow soubor a ukaž zaznamenaný běh |
| Cloud agent, remote control | `/delegate` a `/remote` v [13](13-remote-agents.cs.md) | Lokální session v autopilotu s limitem kreditů |
| Copilot CLI v Actions | Sekce o Actions v [11](11-programmatic-ci.cs.md) zůstane cvičením na čtení | Lokální smoke check |
| Přístup collaboratorů (spravovaní uživatelé) | Nic, pokud mirror vznikne včas | Zmirroruj repo do organizace 2N a issues pro cvičení 4 tam vytvoř znovu |
| Omezený seznam modelů | Vestavěné `/review`, pokud jeho model chybí | Agent `kotlin-reviewer`, který běží na modelu session |
| Nízký rozpočet kreditů | `npm run eval:ab`, `/fleet`, `conductor run` pro všechny | Spusť je jednou na stroji facilitátora. `vally experiment run <file> --dry-run` vypíše plán a neutratí nic |

---

Zpět na [přehled](README.cs.md). Návody začínají u [00-install](00-install.cs.md).

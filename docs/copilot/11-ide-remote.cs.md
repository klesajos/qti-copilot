> 🌍 Číst v jazyce: [English](11-ide-remote.md) | **Česky**

# 11 · IntelliJ IDEA a vzdálení agenti

> ⏱ 5 min (výklad: první tři tabulky; číslované seznamy, sekce o Coderu a srovnávací tabulka jsou k přečtení po workshopu) · Dokumentace: [Copilot in IDEs](https://docs.github.com/en/copilot/concepts/copilot-surfaces/copilot-in-ides) · [Usage metrics fields](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics) · [/delegate](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/delegate-tasks-to-cca) · [Remote control](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/steer-remotely) · [Coder](https://github.com/coder/coder) · Nic z toho se pro tohle repo nespouštělo: ani v IntelliJ IDEA, ani `/delegate`, ani `/remote`, ani na Coderu. Zdroje: [release notes pluginu](https://plugins.jetbrains.com/plugin/17718-github-copilot/versions) do 1.21.1, nápověda CLI 1.0.114, dokumentace GitHubu a Coderu

## Ve zkratce

**Potřebuješ:** IntelliJ IDEA s pluginem GitHub Copilot ve verzi 1.20.0 nebo novější. Pro `/delegate`: cloud agenta Copilotu zapnutého pro repo. Pro Coder: nasazený Coder a v něm workspace pro tebe.

**K čemu to je:** Stejný Copilot mimo terminál: v IDE, v cloudu na GitHubu, nebo na vzdáleném stroji, který pracuje dál, i když máš notebook zavřený.

**Tři nejužitečnější použití:**

1. Zůstaň u drobných úprav v IDEA a měj načtené instrukce a agenty tohoto repa.
2. Předej dlouhý úkol cloud agentovi přes `/delegate` a dostaň zpátky draft pull requestu.
3. Nech agenta běžet přes noc ve workspace v Coderu a ráno zkontroluj výsledek.

## Plugin pro IntelliJ IDEA

Chat agent pluginu pro IntelliJ IDEA čte většinu souborů tohohle repa, ale ne všechny stejným
způsobem, a nepočítá se jako používání CLI. Pro uživatele Android Studia a Xcode:
tahle sekce se týká jen IntelliJ IDEA; nástroj společný všem šesti stackům je terminálové CLI.

| Soubor v tomhle repu | V pluginu | Poznámka |
|----------------------|-----------|----------|
| `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | ✅ | `applyTo` potřebuje plugin 1.5.62 nebo novější |
| `.github/agents/*.agent.md` | ⚠️ | `strict-tools-list` a `include-custom-instructions` jsou zdokumentované jen pro CLI |
| `.github/skills/board-tests/` | ⚠️ | Skilly jsou podporované; žádný zdroj od JetBrains neuvádí, které projektové složky plugin čte |
| `.github/hooks/hooks.json` | ⚠️ | Zveřejněné události: `userPromptSubmitted`, `preToolUse`, `postToolUse`, `errorOccurred`. `sessionStart` a `agentStop` mezi nimi nejsou a matchery jsou napsané pro názvy nástrojů CLI. Nepředpokládej, že pojistky jsou aktivní |
| `.github/copilot/settings.json`, `plugins/2048-dev/` | ⚠️ | Počítej s tím, že nastavení z repa nedělá nic: IDE má vlastní úložiště pluginů. Přidej marketplace a nainstaluj `2048-dev` v Customizations |
| `.mcp.json` v kořenu (repo dodává `.mcp.json.example`) | ⚠️ | Jediný MCP soubor, který čtou oba klienti. V IDE se `${VAR}` posílá doslova a stdio servery startují v adresáři IDE |
| `scripts/copilot-ws.sh`, `evals/`, `conductor/` | ❌ | Terminálové nástroje. Spouštěj je v terminálu IDE |
| `.github/prompts/*.prompt.md` (v tomhle repu žádné nejsou) | ✅ | Jen IDE; CLI prompt files ignoruje. Když chceš sdílet workflow, napiš skill |

**CLI agent uvnitř IDE.** Od pluginu 1.20.0 je výchozí chat agent „Copilot“. Běží na CLI
runtimu přibaleném k pluginu, starším než tvoje terminálové CLI: plugin 1.21.0 obsahuje
1.0.103, workshop používá 1.0.114. `/ide` v terminálové session jde opačným směrem: předá
CLI výběr, diagnostiku a odkazy na soubory z IDE (preview od pluginu 1.17.0). IDE taky umí
spustit CLI jako svého agenta přes [`copilot --acp`](https://docs.github.com/en/copilot/reference/copilot-cli-reference/acp-server) (public preview).
Agentní práci dělej přes `scripts/copilot-ws.sh` v terminálu IDE: otestované hooky a pravidla,
aktuální runtime, počítá se jako CLI. Plugin si nech na doplňování a next edit suggestions.

> 🔷 **Jen Copilot:** `copilot --acp` je vestavěný režim ACP serveru; Claude Code žádný nemá a
> k ACP editorům se dostane jen přes adaptér třetí strany.

**Jak se používání připisuje v metrikách.** CLI má vlastní počítadla: `totals_by_cli`
(sessions, požadavky, prompty, tokeny) a denní příznak `used_cli` pro každého uživatele.¹

| Co spouštíš | Vykazuje se jako |
|-------------|------------------|
| `copilot` v terminálu, včetně terminálu IDE | ✅ CLI |
| Chat agent pluginu, doplňování, next edit suggestions | ❌ JetBrains (plugin 1.20.0 nebo novější) |
| Evaly ve Vally a Conductor (Copilot SDK), `/delegate` (cloud agent) | ⚠️ Dokud to administrátor nepotvrdí, počítej s tím, že to CLI není |

Plugin 1.15.0–1.19.x počítal některé agentní sessions z IDE jako aktivitu CLI
([opraveno v 1.20.0, zpětně nedoplněno](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/usage-metrics-coverage)):
plugin aktualizuj. Které pole čte tvoje organizace, ti řekne jen administrátor Copilotu ([pole](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics)).

¹ Stránka dokumentace si u `totals_by_feature` protiřečí: jedna sekce říká, že se tam používání
CLI neprojevuje, tabulka featur uvádí `copilot_cli`. Ptej se, ze kterého pole číslo pochází.

**Ověř si na své verzi pluginu** (jednou po každé aktualizaci pluginu):

1. Settings → Plugins: GitHub Copilot je 1.20.0 nebo novější a výchozí chat agent je „Copilot“.
2. Zeptej se *„Které soubory s instrukcemi jsi pro tenhle repozitář dostal? Vypiš jejich cesty.“*
   Čekej `.github/copilot-instructions.md`, a jakmile otevřeš `Board.kt`, i `engine.instructions.md`.
3. Výběr agentů nabízí `kotlin-reviewer`, `board-test-writer` a `workshop-tutor`. Zeptej se *„Jaké
   má tenhle projekt konvence pro testy desky?“*: odpověď zmíní názvy testů ve zpětných apostrofech a
   `boardOf(...)`.
4. Požádej agenta, ať přečte `.env` v checkoutu, kde žádný skutečný není. Když hook v IDE běží,
   dostaneš stejnou odpověď jako v CLI, `Denied by preToolUse hook: protect-secrets hook: ...`; když se
   agent o čtení pokusí, zapiš si, že pojistky v pluginu aktivní nejsou.
5. V terminálové session `copilot` spusť `/ide`. Když to funguje, IDE se nabídne a CLI z něj dostane
   výběr a diagnostiku; když ne, řekni lektorovi svou verzi pluginu (preview od 1.17.0).

## Vzdálená a noční práce

Když odejdeš, nikdo neodpovídá na dotazy (požadavek, který by vyvolal dotaz, se zamítne) ani si nevšimne
smyčky (nastav limit kreditů a kol) a review se přesouvá na konec: úroveň 8, nebo 9, když ho přeskočíš.

| Způsob | Kde agent běží | Co potřebuje | Použij, když |
|--------|----------------|--------------|--------------|
| `/delegate` | Na GitHubu, jako Copilot cloud agent | Politiky pro Copilot CLI a cloud agenta; repo na GitHubu | Úkol je dobře specifikovaný a notebook se může zavřít |
| `/remote on` | Na tvém stroji | Politiku „Store local sessions in the Cloud“ nastavenou na „View and control“; stroj zapnutý a online | Úkol potřebuje tvoje lokální prostředí nebo nepushnuté soubory |
| Coder Workspaces | Na vlastní infrastruktuře | Šablonu Coderu s Copilot CLI a přihlášení ke GitHubu ve workspace | Úloha trvá déle než jednu noc |

**`/delegate` na cloud agenta.** Napiš `/delegate <prompt>`, nebo začni prompt znakem `&`.
Copilot nabídne, že tvoje nestagované změny commitne jako checkpoint na novou branch. Cloud agent
otevře draft pull request, pracuje na pozadí a požádá tě o review. Pull request míří na tvou
aktuální branch; `/delegate --base <branch>` to změní.
[Přiřazení issue Copilotovi](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/overview) na GitHubu spustí téhož agenta.

> */delegate Oprav bug s tahem, který nic nezmění: GameService.move nesmí přidat dlaždici, když board.move vrátí false. Nejdřív napiš padající test, bez spoléhání na náhodné dlaždice. Neměň engine/. Spusť ./gradlew :api:test a počty uveď v popisu pull requestu.*

V úloze platí commitnuté soubory: instrukce, skilly, agenti, nastavení pluginů a
`hooks.json` (běží jen položky `bash` a `command`, z `ask` se stane deny, blok v `agentStop`
se počítá do časového limitu úlohy). Přepínače ze `scripts/copilot-ws.sh` neplatí. Runnery jsou
Ubuntu x64 nebo 64bitová Windows: žádný `xcodebuild`, takže práce na iOS zůstává lokálně. Co build
potřebuje (`jq` pro hooky, Android SDK), předinstaluj v [`copilot-setup-steps.yml`](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment).

> 🔷 **Jen Copilot:** `/delegate` otevře draft pull request sám a bere `--base` a issue jde
> přiřadit Copilotovi jako člověku; cloudové sessions Claude Code vytvářejí pull request
> z claude.ai/code a přiřazení agentovi si musíš postavit jako Actions workflow.

**`/remote`: řiď lokální session z jiného zařízení.** `/remote on` ukáže odkaz pro
GitHub.com a GitHub Mobile. Tam odpovídáš na žádosti o oprávnění a na otázky, schvaluješ plány
a posíláš prompty; slash příkazy dostupné nejsou. Session dál běží na tvém stroji
s tvými hooky a pravidly zadanými při spuštění. Jen interaktivní sessions, ne běhy s `-p`.

1. `scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)'`, pak `/new worktree`.
2. `/plan <spec>`, přečti si plán (`Ctrl+E` ho ukáže celý), zvol **Accept plan and continue in
   Autopilot execution mode**. Autopilot nic nepovoluje: co nepovolují pravidla zadaná při spuštění, se
   zamítne. Po 5 pokračováních se Autopilot pozastaví.
3. `/limits set max-ai-credits <n>`, `/keep-alive busy` (stroj neusne, dokud agent pracuje), `/remote on`.
4. Po návratu: přečti si, proč skončil, `git diff --stat`, sám spusť testy, přečti si diff každého
   testovacího souboru, který už existoval, a nech `kotlin-reviewer` zrevidovat branch.

**Coder Workspaces.** [Coder](https://github.com/coder/coder) je self-hosted platforma pro vzdálená vývojová
prostředí: administrátor napíše šablonu v Terraformu, každý vývojář dostane
[workspace](https://coder.com/docs/user-guides/workspace-access) z ní postavený a agent běží tam, ne na tvém notebooku.

- **Ve workspace spouštěj Copilot CLI**, ne [Coder Agents](https://coder.com/docs/ai-coder/agents):
  to je vlastní agent Coderu a jeho dokumentace Copilot nezmiňuje. `copilot` ve workspace je
  stejná binárka se stejnými soubory z repa. Přehled: [AI coding agents in Coder](https://coder.com/docs/ai-coder).
- **Modul z registru** [`registry.coder.com/coder-labs/copilot/coder`](https://github.com/coder/registry/blob/main/registry/coder-labs/modules/copilot/README.md)
  je komunitní modul (`verified: false`). Nainstaluje a nakonfiguruje CLI; `copilot` spouštíš
  sám. README připíná `1.0.1`, registr servíruje `1.0.0`.
- **Noční běh** je režim `-p` z [návodu 10](10-orchestration.cs.md) v terminálu workspace:

```bash
scripts/copilot-ws.sh --allow-tool='write' --deny-tool='shell(git push)' \
    --autopilot --max-autopilot-continues 20 --max-ai-credits 300 \
    --trust-folder --no-ask-user --share="$HOME/overnight-session.md" -p "<spec>"
```

Otevřené otázky pro pilot: JDK, Node a `jq` v image workspace; jak se přihlášení ke GitHubu dostane do
workspace; jestli se tyhle běhy počítají jako používání CLI; kdo se podívá, když se běh ve 2 ráno zastaví.

## Copilot vs Claude Code

| Copilot | Claude Code | V čem se liší |
|---------|-------------|---------------|
| `/delegate` | `claude --cloud "<task>"` | Claude Code: žádný automatický draft pull request, žádné `--base` |
| Přiřazení issue Copilotovi | Claude Code GitHub Action na události issue | Claude nemůže být assignee; trigger si stavíš sám |
| `/remote on` | Remote Control (`/remote-control`) | Ekvivalentní |
| Cloudová sandbox session (`/environments`, `--connect`) | Cloudové sessions, `--teleport` | Ekvivalentní |
| `/ide`, plugin pro JetBrains | `/ide`, plugin pro JetBrains | Plugin Clauda spouští CLI `claude` v terminálu IDE; plugin Copilota má vlastního chat agenta |
| `copilot --acp` | Nic vestavěného | Zed dodává adaptér pro Claude Code |
| `used_cli`, `totals_by_cli` | Analytics dashboard, Enterprise Analytics API | Žádný denní příznak CLI pro jednotlivé uživatele |

Dál: [12 · Copilot vs Claude Code](12-copilot-vs-claude.cs.md)

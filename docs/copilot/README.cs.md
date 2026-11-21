> 🌍 Číst v jazyce: [English](README.md) | **Česky**

# Ukázky rozšíření GitHub Copilot

Tohle repo zároveň slouží jako ukázka způsobů, jak rozšířit GitHub Copilot CLI
na úrovni **projektu**. „Na úrovni projektu“ znamená, že konfigurace žije
**přímo v repozitáři**: když si projekt naklonuješ přes `git clone`, dostaneš
s ním instrukce, skill, agenty, hooky i plugin. Nic se neinstaluje do domovského
adresáře. Jedinou věc ti klon nedá, a to souhlas: hooky a plugin se načtou až
poté, co odpovíš na dotaz na důvěru ke složce
([návod 00](00-install.cs.md)).

Návody 01–09 pokrývají každý jeden mechanismus, jsou samostatné a minimální.
Návody 10–14 jsou o tom, jak s nimi pracovat. Projdi je popořadě; jdou od
nejjednoduššího po nejpokročilejší:

| # | Ukázka | Co tě naučí | Kde žije |
|---|--------|-------------|----------|
| 0 | [Instalace a první session](00-install.cs.md) | Instalace Copilot CLI, přihlášení, důvěra ke složce, výběr modelu, AI Credits, spuštění aplikace 2048 | tvůj počítač |
| 1 | [Vlastní instrukce](01-custom-instructions.cs.md) | Trvalé pokyny pro repo: jeden soubor pro každou session, soubory vázané na cestu, které se načtou, až když se sáhne na odpovídající soubory, `AGENTS.md` | `.github/copilot-instructions.md` + `.github/instructions/` |
| 2 | [Projektový skill](02-skills.cs.md) | Znalosti o projektu, které si Copilot načte, jen když je úkol potřebuje | `.github/skills/board-tests/SKILL.md` |
| 3 | [Projektové hooky](03-hooks.cs.md) | Shellové skripty, které běží na události session: vložení git kontextu, blokování destruktivních příkazů, hlídání `.env`, formátování, spouštění testů | `.github/hooks/hooks.json` + `.github/hooks/scripts/` |
| 4 | [MCP připojení](04-mcp.cs.md) | Připojení Copilota k externím nástrojům, když organizace povoluje jen schválený seznam | `.mcp.json.example` |
| 5 | [Vlastní agenti a delegování](05-agents.cs.md) | Předání jednoho úkolu izolovanému kontextu s vlastními nástroji: reviewer, který nemůže editovat, a autor testů | `.github/agents/` |
| 6 | [Pluginy a marketplace v repozitáři](06-plugins.cs.md) | Zabalení skillů a agentů pro další repa; marketplace přímo v repu, zapnutý nastavením repozitáře | `plugins/2048-dev/` + `marketplace.json` + `.github/copilot/settings.json` |
| 7 | [Orchestrace](07-orchestration.cs.md) | Několik agentů na jednom úkolu: `/fleet`, režimy plan a autopilot, dynamické workflows | vestavěno v CLI; používá agenty z `.github/agents/` |
| 8 | [Oprávnění a sandbox](08-permissions-sandbox.cs.md) | Pravidla allow a deny jako přepínače při spuštění, hook jako commitnutá pojistka, lokální sandbox | `scripts/copilot-ws.sh` + `.github/hooks/scripts/protect-secrets.sh` |
| 9 | [Validace a evaly](09-validate-eval.cs.md) | Měření, jestli skill, agent nebo plugin vůbec něco mění: běhy s ním a bez něj, které bodují gradery | `evals/` + `package.json` |
| 10 | [Práce na úrovni 5 a výš](10-level-5-workflow.cs.md) | Pracovní smyčka, ve které kód píše Copilot a ty mu pořád celému rozumíš | celé repo |
| 11 | [Programatický režim a CI](11-programmatic-ci.cs.md) | `copilot -p`, JSONL výstup, oprávnění, když na dotaz nemá kdo odpovědět | `evals/plugin-ab.sh` jako hotový příklad |
| 12 | [Plugin pro IntelliJ IDEA](12-intellij.cs.md) | Co plugin od JetBrains z tohohle repa čte a kde se chová jinak než CLI | tytéž soubory v `.github/` |
| 13 | [Vzdálení a noční agenti](13-remote-agents.cs.md) | Předání práce agentovi, který běží jinde: cloud agent, Coder workspaces | v repu nic |
| 14 | [Microsoft Conductor](14-conductor.cs.md) | Multiagentní flow definované v YAML a spouštěné přes providera Copilot | `conductor/test-coverage-audit.yaml` |

Každý návod existuje ve dvou jazycích: `xx-name.md` je anglicky,
`xx-name.cs.md` česky. Obsah je stejný. Vedle návodů leží ještě tři soubory:

- [exercises.cs.md](exercises.cs.md): praktické úkoly, jeden nebo víc na každý
  mechanismus.
- [cheatsheet.cs.md](cheatsheet.cs.md): přepínače, slash příkazy a umístění
  souborů na jedné stránce.
- [preflight.cs.md](preflight.cs.md): kontroly, které si pustíš na vlastním
  počítači, v síti klienta, ještě před dnem workshopu. Nastavení spravované
  organizací umí vypnout skilly, hooky, pluginy nebo MCP, aniž by ti to někdo
  řekl; tady na to přijdeš.

## Než začneš

Potřebuješ:

1. **Copilot CLI 1.0.114 nebo novější, přihlášené** účtem, na kterém máš svůj
   seat Copilot Business. Viz [návod 00](00-install.cs.md).
2. **Naklonované tohle repo:** `git clone https://github.com/klesajos/qti-copilot`
3. **Terminál otevřený v kořenu repa** (složka, ve které je
   `settings.gradle.kts`). Všechny ukázky tenhle pracovní adresář předpokládají.
4. **JDK 17–27, Node.js 24.15+ nebo 26, `jq` a `git`.** Skripty hooků
   potřebují `jq`; bez něj se pojistky samy vypnou.
5. **Složku označenou jako důvěryhodnou**, až se Copilot zeptá. Jestli chceš
   vědět, s čím vlastně souhlasíš, přečti si nejdřív
   `.github/hooks/hooks.json`.

Žádný návod ani cvičení nepoužívá screenshot ani obrázek. Pro publikum, pro
které tenhle workshop vznikl, je obrazový vstup vypnutý, takže všechno je text.

**Jak číst „otestováno“.** Co návod označuje jako otestované nebo ověřené
naživo, běželo na Copilot CLI 1.0.114 dne 2026-11-21 v tomto repozitáři. Kde
návod říká „podle dokumentace“, pochází tvrzení z dokumentace GitHubu nebo
z changelogu a tady se nespouštělo. Návody 10, 11 a 13, tahák a předletová
kontrola značí tytéž dvě věci jako **[T]** a **[D]** a své značky vysvětlují
nahoře; v návodech 10 a 11 a v taháku pochází neoznačené tvrzení z vlastní
nápovědy CLI.

## Rychlé demo (5 minut)

Pro lektora, naživo. Každý krok používá něco, co v tomhle repu je a co běželo
na 1.0.114.

1. **Instrukce.** Ještě před startem session spusť
   `copilot instruction list`. Vypíše tři soubory s instrukcemi, které repo
   obsahuje; přidej `--json` a uvidíš globy `applyTo` u těch dvou vázaných na
   cestu.
2. **Hook, který přidává kontext.** Spusť `copilot` v kořenu repa a označ
   složku jako důvěryhodnou. Zeptej se:

   > *„Na které branchi jsem a které soubory nejsou commitnuté? Odpověz z toho, co už víš; nespouštěj žádný příkaz.“*

   Copilot odpoví bez volání nástroje. Hook `sessionStart`
   (`git-context.sh`) mu to vložil do kontextu ještě před tvým prvním promptem.
3. **Skill.** Zeptej se:

   > *„Přidej test pro posun řádku 4, 4, 8, 0“*

   Copilot zavolá nástroj `skill` s `board-tests` dřív, než cokoli napíše.
   Správný test očekává `8, 8, 0, 0` a selže, protože současný kód vrací
   `16, 0, 0, 0`. To je záměrný bug 1.
4. **Hook, který blokuje.** V jiném terminálu vytvoř soubor na jedno použití,
   `echo 'DEMO_KEY=not-a-secret' > .env` (git ho ignoruje). Pak se zeptej:

   > *„Vypiš obsah souboru .env“*

   Volání je odmítnuto s `Denied by preToolUse hook: protect-secrets hook: ...`.
   Hook kontroluje shellové příkazy stejně jako nástroj `view`. Samotné
   pravidlo `--deny-tool='read(.env)'` zastaví `view`, ale `cat .env` pořád
   projde. Soubor potom smaž.
5. **Skill z pluginu.** Napiš `/2048-dev:build-test`. Plugin nikdo ručně
   neinstaloval; zapnul ho soubor `.github/copilot/settings.json`, když jsi
   složku označil jako důvěryhodnou. Skill Copilotovi říká, ať projekt sestaví,
   pustí všechny sady testů a nahlásí výsledek, aniž by cokoli opravoval.
6. **Agent z pluginu.** Ve druhém terminálu:

   ```bash
   copilot --agent 2048-dev:game-explorer --trust-folder \
     -p "Trace how a keypress becomes a board move."
   ```

   Agent deklaruje `tools: ["read", "search"]`. V testovacím běhu použil jen
   `rg` a `view`.
7. **Eval, zadarmo.** `npm ci` v kořenu repa a pak `npm run eval:lint`. Obě
   specifikace evalů projdou validací; je to statická kontrola YAML. Placený
   běh, který za nimi stojí (`npm run eval:ab`), je důvod, proč se skill
   z kroku 3 vyplatí mít: bez skillu prošel pozitivní případ v 0 ze 4 trialů,
   s ním ve 3 ze 4 s opraveným graderem (ve 2 ze 4 při prvním hodnocení;
   [návod 09](09-validate-eval.cs.md)).

## Kde který mechanismus funguje

Copilot čte tenhle repozitář na třech místech a **ne všechno funguje ve
všech**. Každý návod má vlastní sekci „Kde to funguje“; shrnutí:

| Projektový mechanismus | CLI (terminál) | Plugin pro IntelliJ | Cloud agent |
|--------------------------|:--------------:|:---------------:|:-----------:|
| Vlastní instrukce (`.github/copilot-instructions.md`, `.github/instructions/`) | ✅ | ✅ | ✅ |
| Skilly (`.github/skills/`) | ✅ | ✅ | ✅ |
| Hooky (`.github/hooks/`) | ✅ | ⚠️ zveřejněné jsou jen `userPromptSubmitted`, `preToolUse`, `postToolUse` a `errorOccurred`; `sessionStart` ani `agentStop` nic nepotvrzuje | ⚠️ načítá tytéž soubory; z rozhodnutí `ask` se stane deny a blokování v `agentStop` se počítá do timeoutu jobu |
| MCP (`.mcp.json`) | ✅ po potvrzení důvěry ke složce, v mezích MCP politiky organizace | ⚠️ `.mcp.json` v kořenu se čte od pluginu 1.19.0; otevřené bugy s odkazy na proměnné prostředí a s pracovním adresářem | ⚠️ tenhle workshop ho nepokrývá; nepředpokládej, že čte tvůj lokální soubor |
| Vlastní agenti (`.github/agents/`) | ✅ | ✅ podporované klíče frontmatteru závisí na prostředí | ✅ |
| Plugin zapnutý nastavením repozitáře | ✅ | ⚠️ IDE má vlastní úložiště pluginů; plugin nainstaluj uvnitř IDE | ⚠️ čte `enabledPlugins` a `extraKnownMarketplaces` z `.github/copilot/settings.json`, takže commit ovlivní i cloudové běhy |
| Orchestrace (`/fleet`, plan, autopilot) | ✅ | ⚠️ má vlastní subagenty a agenta Plan; `/fleet` tam potvrzený není | sem posílá práci `/delegate` |
| Oprávnění a sandbox (`scripts/copilot-ws.sh`) | ✅ | ❌ přepínače při spuštění patří k příkazu v terminálu; společnou částí jsou hlídací hooky | ❌ běží na GitHubu, ne na tvém počítači |
| Evaly (`evals/`) | ✅ terminálový nástroj, který si spouští vlastní Copilot sessions | ❌ spouštěj je z terminálu | ❌ |

✅ funguje · ⚠️ funguje s omezeními, nebo není potvrzeno · ❌ není k dispozici.

Sloupec CLI byl otestován v tomhle repu, se třemi výjimkami, které návody
popisují z vlastní nápovědy CLI a z dokumentace bez zaznamenaného běhu: server
z workspace `.mcp.json` (běžel jen vestavěný GitHub MCP server), řádek
orchestrace (`/fleet`, režimy plan a autopilot) a sandbox. Zbylé dva sloupce
pocházejí z dokumentace GitHubu a z release notes pluginu JetBrains (plugin
1.21.1); nic z toho tady neběželo.

Proč se sloupce liší: terminálové CLI je referenční implementace. Plugin pro
IntelliJ používá agenta Copilot CLI jako výchozího agenta od verze pluginu
1.20.0, ale přibaluje si vlastní, starší CLI runtime, takže featura, která
přišla v nedávném vydání CLI, tam ještě být nemusí. Cloud agent běží na GitHubu
nad pushnutým repozitářem, ne na tvém počítači, takže tvoje lokální rozhodnutí
o důvěře, přepínače při spuštění ani nastavení v `~/.copilot` nehrají žádnou
roli. Podrobnosti jsou v [návodu 12](12-intellij.cs.md) a
[návodu 13](13-remote-agents.cs.md).

## Kdy použít který mechanismus?

- **Vlastní instrukce:** co platí pro každý úkol v repu (stack, struktura,
  konvence, příkazy). Načítají se do každé session, takže je drž krátké.
- **Instrukce vázané na cestu:** pravidla, na kterých záleží jen v jedné části
  stromu. Nestojí nic, dokud se nečte nebo needituje odpovídající soubor.
- **Skill:** když chceš, aby Copilot *věděl, jak* něco udělat (psát testy tak,
  jak se píšou v tomhle projektu, udělat release). Kdy ho načíst, rozhoduje
  model.
- **Hook:** když se něco musí stát *pokaždé*, ať si model myslí cokoli
  (formátování, zablokování příkazu, spuštění testů). Model do toho nemá co
  mluvit.
- **MCP:** když Copilot potřebuje *schopnost*, kterou nemá (přečíst issue
  z Jiry). Při omezené politice jen servery ze schváleného seznamu.
- **Vlastní agent:** když má *jeden* samostatný úkol běžet ve vlastním
  kontextu s vlastními nástroji (reviewer, který nemůže editovat, mapovač
  kódu).
- **Plugin:** když se má skill nebo agent *sdílet* mezi repy jako jeden
  verzovaný balíček. Dobrý materiál pro guildu.
- **`/fleet`:** když se práce rozpadá na části, které na sobě nezávisí. Každý
  subagent volá model sám za sebe, takže to stojí víc.
- **Přepínače při spuštění:** pro předschválení rutinních příkazů repa na
  jeden běh a pro zákaz toho, co se nesmí spustit nikdy.
- **Eval:** když potřebuješ důkaz, že skill, agent nebo plugin mění výsledek,
  dřív než o jeho zavedení požádáš celý tým.
- **Conductor:** když má stejné multiagentní flow běžet pokaždé stejně, mimo
  číkoli interaktivní session.

## Čím se to liší od workshopu Claude Code

Pro ty, kdo byli na workshopu postaveném na `dxc-ws`. Myšlenky se přenášejí;
názvy souborů a pár pravidel ne.

| Claude Code (`dxc-ws`) | Copilot CLI (tohle repo) | Co se mění |
|------------------------|-------------------------|--------------|
| `CLAUDE.md` | `.github/copilot-instructions.md` | Stejná role. `AGENTS.md` se čte taky a slučuje se, nepoužívá se jako záloha |
| `.claude/rules/*.md` s `paths:` | `.github/instructions/*.instructions.md` s `applyTo:` | Stejná myšlenka: doručí se, když se čte nebo edituje odpovídající soubor |
| `.claude/skills/` | `.github/skills/` | Stejný formát `SKILL.md`, kratší seznam polí frontmatteru |
| Hooky v `.claude/settings.json` | `.github/hooks/*.json` | Názvy událostí v camelCase; blokující stop hook odpovídá JSONem, ne návratovým kódem |
| `.claude/agents/*.md` | `.github/agents/*.agent.md` | Klíče frontmatteru v kebab-case; `tools` používá aliasy jako `read`, `search`, `execute` |
| `permissions` v `.claude/settings.json` | přepínače při spuštění (`--allow-tool`, `--deny-tool`) + hook `preToolUse` | Na úrovni repozitáře neexistuje commitnutý soubor s allow/deny |
| `.claude-plugin/marketplace.json` | `marketplace.json` + `plugins/2048-dev/plugin.json`, zapnuté v `.github/copilot/settings.json` | Skilly z pluginu se i tady volají `/plugin:skill` |
| `.claude/workflows/` | `/fleet`, dynamické workflows, Conductor | Žádný jeden ekvivalent. Dynamické workflows jsou public preview schované za experimentálním režimem (podle dokumentace) |
| Output styles | bez ekvivalentu | Pravidla pro tón a formát dej do instrukcí |
| `claude plugin eval` | Vally (`@microsoft/vally-cli`), GitHub Copilot Evals | CLI nemá vestavěný příkaz pro evaly. Copilot Evals je public preview a tady přibalený není |
| `.mcp.json` | `.mcp.json` | Stejný název souboru i klíč `mcpServers`. Tohle repo obsahuje jen `.mcp.json.example` |

**Pozor: Copilot CLI čte i soubory Claude Code.** V projektu načítá
`CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/`, `.claude/skills/`,
`.claude/agents/`, `.claude/commands/` a hooky z
`.claude/settings.json`, vedle všeho, co je pod `.github/`. Repozitář, který
má obě sady, dostane své instrukce dvakrát, ve dvou lehce odlišných zněních,
a jeho Claude hooky běží i pod Copilotem. Proto tohle repo **nemá adresář
`.claude/` ani soubor `CLAUDE.md`**. Tvůj osobní `~/.claude/` se nečte. Když
přidáváš Copilota do repa, které už slouží Claude Code, spusť nejdřív
`copilot instruction list` a `/env` a podívej se, co se doopravdy načítá
([návod 01](01-custom-instructions.cs.md)).

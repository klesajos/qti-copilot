> 🌍 Číst v jazyce: [English](06-agents.md) | **Česky**

# 06 · Vlastní agenti

> ⏱ 25 min (5 demo + 20 cvičení 5) · Dokumentace: [Custom agents](https://docs.github.com/en/copilot/concepts/customizations/custom-agents) · [Creating and using custom agents for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli) · Ověřeno na Copilot CLI 1.0.114

## Ve zkratce

**Potřebuješ:** CLI. Jeden soubor v Markdownu na agenta.

**K čemu to je:** Vlastní agent je specialista s vlastními instrukcemi, vlastním seznamem nástrojů a vlastním kontextovým oknem. Tvoje session mu předá úkol a dostane zpátky jen výsledek, ne šum kolem.

**Tři nejužitečnější použití:**

1. Reviewer jen pro čtení, který zkontroluje tvůj diff a nezmění ani jeden soubor.
2. Průzkumník, který najde, kde featura žije, a nezaplní ti session obsahem souborů.
3. Autor testů, který píše jen testy, takže oprava zůstane samostatný krok, který zkontroluješ.

## Co je vlastní agent?

Vlastní agent je Markdown soubor: frontmatter plus prompt. Tři věci má jen pro sebe:

- **Kontext.** Jako subagent pracuje v oddělené konverzaci a vrátí jen svůj závěr.
- **Nástroje.** O tom, co smí volat, rozhoduje seznam `tools`. Bez editačního nástroje žádné úpravy.
- **Prompt.** Tělo souboru je jeho systémový prompt: role, rozsah, formát hlášení.

Použij ho, když práce nadělá hodně šumu (průzkum, review), vystačí si s méně nástroji než tvoje
session nebo má hlásit výsledek v pevném formátu. Skill ([03](03-skills.cs.md)) přidává instrukce; agent úkol přebírá.

## Co dělá tahle ukázka

```
.github/agents/{board-test-writer,kotlin-reviewer,workshop-tutor}.agent.md   ← agent ID = file name
plugins/2048-dev/com.github.copilot/agents/game-explorer.agent.md            ← plugin agent (07)
```

| Agent | `tools` v souboru | Nástroje, které dostane | Úkol |
|-------|---------------------|---------------|-----|
| `board-test-writer` | `read`, `search`, `edit`, `execute` | sada reviewera plus `apply_patch` | Přidává testy desky, pouští `./gradlew :engine:test`, správnou padající aserci nechá a bug nahlásí |
| `kotlin-reviewer` | `read`, `search`, `execute` | `view`, `rg`, `glob`, `bash`, `skill`, `sql` | Dělá review necommitnutých změn. Bez editačního nástroje |
| `2048-dev:game-explorer` | `read`, `search` | `view`, `rg`, `glob`, `skill`, `sql` | Vystopuje featuru jako `file:function:line`. Bez shellu, bez editačního nástroje |

## Soubor řádek po řádku

Frontmatter souboru `.github/agents/kotlin-reviewer.agent.md`:

```yaml
name: kotlin-reviewer
description: Use to review uncommitted Kotlin or TypeScript changes in this repo for correctness and project conventions before a commit. Reads the diff and the surrounding code and reports severity-tagged findings. It has no edit tool; it reviews and never modifies.
tools: ["read", "search", "execute"]
strict-tools-list: true
include-custom-instructions: true
```

- `name` — to, co předáváš do `--agent` a vidíš v `/agent`. Výchozí hodnota je ID agenta.
- `description` — povinné. Hlavní agent podle něj rozhoduje, kdy delegovat. Nejdřív napiš
  spouštěč („Use to review uncommitted ... changes“), potom to, co se vrátí.
- `tools` — allow-list aliasů: `read`, `search`, `edit`, `execute` (shell), `agent`, `web`.
  Když klíč vynecháš, agent dostane všechny nástroje. `[]` mu nedá žádný.
- `strict-tools-list: true` — jen vyjmenované skupiny, bez obvyklých výchozích nástrojů. Na 1.0.114
  byla sada nástrojů stejná s ním i bez něj.
- `include-custom-instructions: true` — subagent dostane `copilot-instructions.md` a
  `AGENTS.md`, jen když je tohle nastavené; agent session je dostane vždy. Oba agenti, kteří
  posuzují kód, `board-test-writer` a `kotlin-reviewer`, to nastavené mají; `game-explorer` a `workshop-tutor` ne.

**Klíče jsou v kebab-case.** Tabulka v dokumentaci uvádí klíče v camelCase, například `modelPolicy`. Takový
zápis nedělá nic: `unknown fields ignored: modelPolicy, reasoningEffort, strictToolsList`.

**Co seznam nástrojů zaručuje.** Reviewer nemůže zavolat editační nástroj. Má ale `bash` a
shell zapisovat umí. Pravidlo používat shell jen pro `git status`, `git diff` a `git log` stojí
v těle, takže je to jen prosba k modelu. Vynucené vrstvy jsou oprávnění session, která subagenti
dědí a nemůžou rozšířit ([08](08-permissions-sandbox.cs.md)), a hooky `preToolUse` ([04](04-hooks.cs.md)).

## Jak funguje delegování a jak agenta zavolat

Hlavní agent deleguje nástrojem `task`; agenta určuje jeho argument `agent_type`. S
`--output-format json` uvidíš `tool.execution_start` s `toolName: "task"`, potom
`subagent.started` a `subagent.completed`. V session `/tasks` vypíše subagenty; `Enter` otevře přepis.

| Způsob | Příklad | Co se stane |
|-----|---------|--------------|
| Agent session | `/agent kotlin-reviewer` nebo `copilot --agent kotlin-reviewer` | Na celou session nahradí výchozího agenta. Samotné `/agent` otevře výběr: `Default`, `board-test-writer · project`, `game-explorer · plugin`, `kotlin-reviewer · project`, `workshop-tutor · project` |
| Jménem v promptu | *„Použij agenta kotlin-reviewer a zreviduj moje necommitnuté změny.“* | Hlavní agent zavolá `task` s `agent_type: "kotlin-reviewer"` |
| Automaticky | *„Vystopuj, jak se ze stisku klávesy stane tah na desce.“* | Hlavní agent vybere agenta podle `description`, vybere vestavěného, nebo práci udělá sám |

Agenti z pluginu potřebují celé ID: `2048-dev:game-explorer`. Vestavění agenti jsou `explore`, `task`,
`general-purpose`, `code-review`, `security-review`, `research` a `rubber-duck` ([seznam](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-agents)).
V `/agent` nejsou. Vlastní agent s některým z těchto jmen se nikdy nespustí: spustí se vestavěný.

## Vytvoř si vlastního, krok za krokem

1. Vytvoř `.github/agents/my-agent.agent.md`:
   ```markdown
   ---
   name: my-agent
   description: Use when <the situation that should trigger delegation>. <What it returns.>
   tools: ["read", "search"]
   strict-tools-list: true
   ---
   <Who the agent is, what it does, how it reports back.>
   ```
2. `execute` přidej, jen když má něco spouštět, `edit`, jen když má zapisovat, a
   `include-custom-instructions: true`, pokud posuzuje nebo píše kód.
3. Zkontroluj, že se načte. Očekávej `{"warnings":[],"errors":[]}`:
   ```bash
   copilot --agent my-agent -p "Reply with OK" --trust-folder --no-ask-user --output-format json \
     | jq -c 'select(.type == "session.custom_agents_updated") | .data | {warnings, errors}'
   ```
4. Otestuj hranici; `git status --short` potom neukáže žádný `probe.txt`:
   `copilot --agent my-agent -p "Create a file named probe.txt" --trust-folder --no-ask-user`
5. Běžící session si nový soubor v `.github/agents/` načte; upravený potřebuje novou session.
   Osobní agent v `~/.copilot/agents/` má přednost před projektovým agentem se stejným ID.

## Agent jako output style

Copilot CLI žádnou featuru output style nemá. Stejnou práci odvede agent session, jehož tělo jen
určuje tvar odpovědi. `.github/agents/workshop-tutor.agent.md` nemá klíč `tools`, takže mu zůstávají
všechny nástroje, a má `disable-model-invocation: true`, takže se nikdy nevybere jako subagent. Jeho
tělo dává každé odpovědi tvar **What I did** / **Why it works** / **Try it**.

```bash
copilot --agent workshop-tutor -p "What does Board.hasWon() return? Don't edit anything." \
  --trust-folder --no-ask-user
```

Odpověď jmenuje `Board.kt:174` (jeden běh uvedl `:177`), uvádí důvod a končí příkazem `./gradlew :engine:test` na vyzkoušení.
Model může první nadpis přejmenovat (`What I found`) nebo do něj důvod zahrnout. V session ho vybereš přes `/agent workshop-tutor`
(patička: `workshop-tutor · <model>`); `/agent` a pak Enter na `Default (deselect current agent)` ho zase vypne. `/agent default` selže. Omezení:

- Jen jeden agent session najednou: s `--agent kotlin-reviewer` ho nezkombinuješ. Na hlášení
  subagentů se tvar nevztahuje. Tvar je prosba: dokud v těle nestálo „always“, jeden běh nedal žádný příkaz.
- Trvale zapnutá alternativa je sekce „Response format“ v `.github/copilot-instructions.md`.
  Stojí to kontext v každé session a u každého.

## Vyzkoušej demo

1. Spusť `scripts/copilot-ws.sh` v kořenu repa a dej složce důvěru.
2. Prompt:
   > *„Použij agenta 2048-dev:game-explorer a vystopuj, jak se ze stisku klávesy stane tah na desce. Neměň žádný soubor.“*
3. Copilot deleguje na `game-explorer`; `/tasks` ho vypíše a `Enter` otevře jeho přepis (`f` zobrazí nebo skryje dokončené).
   Odpovědí je cesta `App.tsx` → `keys.ts` → `api.ts` → `GameController.kt` → `GameService.kt`
   → `Board.kt`. `git status` neukáže žádnou změnu. Náš běh: 20 volání nástrojů, asi 42 000 tokenů.

## Volitelné parametry

| Klíč | Co dělá |
|-----|--------------|
| `model`, `models` | Model, nebo modely v pořadí priority. Žádný agent ho tady nenastavuje: povolené modely se liší podle organizace (2N: všechny kromě Fable) a subagent dědí model session. Ignoruje se, když je model session Auto. Přepsání pro jednoho uživatele: `/subagents` |
| `model-policy` | `preferred` (výchozí), nebo `required`: delegování odmítne, místo aby použil jiný model |
| `reasoning-effort` | Úroveň úsilí při uvažování (reasoning effort) pro tohoto agenta |
| `mcp-servers` | MCP servery jen pro tohoto agenta. V `tools` se MCP nástroje píšou `server/tool` nebo `server/*` |
| `disable-model-invocation`, `user-invocable` | Vypnou automatické delegování, respektive ruční výběr |
| `skills` | Názvy skillů, jejichž text se načte do kontextu agenta při startu. Název, který se nenajde, vyvolá varování `skill_load` |

> 🔷 **Jen Copilot:** `model-policy: required` zamkne jednoho agenta na modely, které jmenuje jeho soubor. Claude Code zámek pro jednotlivého agenta nemá; `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` platí pro všechny subagenty.

Tělo je omezené na 30 000 znaků. Kompletní reference: [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration) · [pole frontmatteru v CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-agent-frontmatter-fields)

## Kde to funguje

| CLI | Plugin pro IntelliJ | Cloud agent |
|-----|-----------------|-------------|
| ✅ `.github/agents/`, `~/.copilot/agents/`, agenti z pluginů po udělení důvěry složce | ⚠️ Čte `.github/agents/` (obecně dostupné od pluginu 1.6.1); které klíče respektuje, není zdokumentováno. Agenti z pluginů potřebují plugin ve vlastním úložišti pluginů IDE ([11](11-ide-remote.cs.md)) | ✅ Čte `.github/agents/`; dostaneš se k němu přes `/delegate` ([11](11-ide-remote.cs.md)) |

## Copilot vs Claude Code

Claude Code tomu říká **subagenti**: `.claude/agents/*.md`, stejný vlastní kontext, nástroje a prompt.

- Claude Code vyjmenovává názvy nástrojů (`Read`, `Grep`, `Bash`). Oba přednačítají skilly seznamem
  `skills:` ve frontmatteru; `board-test-writer` místo toho jmenuje `board-tests` ve svém těle.
- Copilot CLI čte i projektové `.claude/agents/` a názvy nástrojů z Claude bere jako
  aliasy. `~/.claude/agents` nečte; osobní agenty přesuň do `~/.copilot/agents/`.
- Output styly existují jen v Claude Code. Tady je zastoupí agent session, s omezeními výše.

## Když něco nefunguje

- **`unknown fields ignored: ...`** → klíč v camelCase nebo s překlepem: použij zápis v kebab-case. `sidekick` z referenční dokumentace se na 1.0.114 taky ignoruje.
- **Spustil se jiný agent, nebo žádný** → jmenuj agenta v promptu; u agenta z pluginu použij celé ID.
- **Agent „jen pro čtení“ změnil soubor** → má `execute`, nebo nemá klíč `tools`. Odeber `execute`.
- **Běh `-p` skončí hláškou „Permission denied ...“** → schval nástroj předem: `--allow-tool='shell(git:*)'`.

Dál: [07 · Pluginy a sdílení na guildách](07-plugins.cs.md)

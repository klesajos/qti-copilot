> 🌍 Číst v jazyce: [English](00-llm-basics.md) | **Česky**

# 00 · Jak fungují LLM a kódovací agenti

> ⏱ 20 min (12 výklad + 8 praxe) · Dokumentace: [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) · [Choosing a model in Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/choose-a-model) · [Managing context](https://docs.github.com/en/copilot/concepts/prompting-and-context/context-management) · Ověřeno na Copilot CLI 1.0.114

## LLM v sedmi řádcích

| Vlastnost | Co to znamená v praxi |
|---|---|
| **Tokeny.** Text se krájí na tokeny o zhruba 4 znacích. Limity i ceny se počítají v tokenech. | `Board.kt` (187 řádků, 5,7 kB) je zhruba 1 400 tokenů pokaždé, když ho model čte. |
| **Predikce dalšího tokenu.** Model ohodnotí každý možný další token, jeden vybere, připojí ho a celý postup opakuje. | Pokračuje v textu. Nic nevyhledává a nic nespouští; na to jsou nástroje (další sekce). |
| **Kontextové okno.** Všechno, co model při jednom volání vidí: systémový prompt, definice nástrojů, instrukce, konverzace, výsledky nástrojů. | Co v okně není, neexistuje: soubor, který nečetl, konvence, kterou nikdo nesepsal. |
| **Bezstavový.** Mezi voláními se nic neuchovává. Každé volání posílá konverzaci znovu. Mezi sessions se nic nenaučí. | Nová session neví nic ze včerejška. Co má platit pokaždé, žije v souborech načítaných při startu. |
| **Uzávěrka tréninku (training cutoff).** Váhy jsou zmrazené k určitému datu. | Zná knihovny ve stavu k tomu datu. Proto instrukce tohoto repa říkají „This is Spring Boot **4**, not 3“. |
| **Vzorkovaný výstup.** Další token se losuje podle pravděpodobností. | Stejný prompt může dát jiný výsledek. Jeden povedený běh nic nedokazuje. |
| **Plynulý, ne ověřený.** Špatná odpověď se čte stejně dobře jako správná. | Posuzuj podle spuštění (kompilace, test, diff), nikdy podle toho, jak jistě text zní. |

## Od modelu k agentovi

Model vrací text. Agent je tentýž model ve smyčce s nástroji. Model sám nikdy nic nespouští:
vydá strukturovaný požadavek, CLI ho provede a výsledek připojí ke konverzaci.

```
 prompt ─► model call = system prompt + tool definitions + instructions + conversation so far
              ▼
           model answers ─► text only: the turn ends
              │
              └─► tool call (name + JSON arguments)
                     ▼
                  CLI checks permission, runs the tool, appends the result
                     ▼
                  next model call: everything above is sent again
```

Kolem modelu CLI přidává **nástroje** (čtení, editace, hledání, shell, MCP servery; jejich definice
se posílají s každým voláním), **oprávnění** (než nástroj poběží, rozhodneš ty, pravidlo, hook nebo
sandbox, [08](08-permissions-sandbox.cs.md)), **instrukce** (soubory vkládané do každého požadavku,
[02](02-custom-instructions.cs.md)) a **kompakci** (když se okno zaplní, historii nahradí shrnutí).

Změřeno: jednoslovný prompt v prázdném adresáři poslal **20 387 vstupních tokenů**; 10 668 z nich
tvořilo 31 definic nástrojů, zbytek systémový prompt a prostředí. Tahle režie se posílá znovu při
každém volání smyčky. Tvoje číslo se liší podle tvých skillů, MCP serverů a instrukcí.

## Modely, které máš k dispozici

Stav k 2026-11-21 ([podporované modely](https://docs.github.com/en/copilot/reference/ai-models/supported-models), [ceny](https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing)): modely v CLI na Copilot Business, USD za 1M tokenů,
výchozí tier. Několik cen je akčních a skončí. `/model` u každého modelu ukazuje kredity za 1M tokenů.

| Dodavatel | Modely | Kategorie | Na co se hodí (GitHub Docs) | Vstup / výstup |
|---|---|---|---|---|
| OpenAI | GPT-6 Luna, GPT-5.6 Luna | Lightweight | Rychlá pomoc s jednoduchými nebo opakujícími se úkoly | 0.10 / 0.50, 0.20 / 1.20 |
| OpenAI | GPT-6.1 Terra | Versatile | Obecné kódování a agentní úkoly | 1.00 / 5.00 |
| OpenAI | GPT-5.3-Codex, GPT-6 Sol, GPT-6.1 Sol, GPT-6.2 Sol, GPT-5.6 Sol | Powerful | Agentní a složité kódování; 5.6 Sol: hluboké uvažování a ladění | 1.75 / 14.00 (Codex), 2.00 / 10.00 (Sol), 4.00 / 20.00 (5.6 Sol) |
| OpenAI | GPT-6.2 Astra, GPT-6 Astra | Powerful | Autonomní kódování s dlouhým horizontem | 8.00 / 40.00, 10.00 / 50.00 |
| Anthropic | Claude Haiku 5.5, Claude Haiku 4.5 | Lightweight, Versatile | Rychlá pomoc s jednoduchými nebo opakujícími se úkoly | 0.10 / 0.50, 1.00 / 5.00 |
| Anthropic | Claude Sonnet 5, Claude Sonnet 5.5 | Versatile | Obecné kódování a agentní úkoly | 2.00 / 10.00 |
| Anthropic | Claude Opus 5.5, Claude Opus 4.8 (fast mode) | Powerful | Dlouho běžící agentní kódování; hluboké uvažování a ladění | 4.00 / 20.00, 10.00 / 50.00 |
| Anthropic | Claude Fable 5, 5.1, 5.2 | Powerful | Autonomní kódování s dlouhým horizontem. **Ve výchozím stavu vypnuto** | 8.00 / 40.00 až 10.00 / 50.00 |
| Google | Gemini 3.8 Flash, Gemini 4 Hydrogen, Gemini 4 Neon | Versatile | Rychlé jednoduché úkoly; agentní kódování a vícekrokové workflow | 0.75 / 3.75 až 3.00 / 15.00 |
| Google | Gemini 4 Argon, Gemini 4 Carbon | Powerful | Složité kódování a uvažování; Carbon: práce zaměřená na bezpečnost | 2.00 / 10.00 (Carbon 4.00 / 20.00 od 2026-12-01) |
| Microsoft | MAI Code 2 Flash, MAI-Code-1.1-Flash | Lightweight | Obecné kódování a psaní | 0.05 / 0.25, 0.20 / 1.20 |
| Microsoft | MAI Code 2 | Powerful | Hluboké uvažování a složité kódování | 0.50 / 2.50 |
| xAI | Grok 4.5, 4.6, 4.7 | Versatile | Obecné kódování a agentní úkoly | 2.00 / 6.00 |
| Moonshot AI | Kimi K3 | Powerful | Agentní kódování a práce s dlouhým kontextem. **Ve výchozím stavu vypnuto** | 3.00 / 15.00 |

- **Ve 2N:** Copilot Business spravovaný organizací `2n-labs`, všechny modely kromě rodiny Claude
  Fable (5, 5.1, 5.2). GitHub nechává Fable vypnutý, dokud vlastník organizace nepovolí každý model v
  Settings → Copilot → Models ([dokumentace](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-default-models)),
  protože se na něj nevztahuje dohoda GitHubu o uchovávání dat (Anthropic prompty a výstupy
  standardně uchovává, aby nad nimi pouštěl bezpečnostní klasifikátory). Auto na něj nikdy nesměruje.
- **Vyber si:** `/model` pro tuhle session, `copilot --model <model-id>` pro jeden běh, `/config model`
  jako výchozí. Výběr ukazuje i modely, které použít nemůžeš, a říká proč; přes přepínač takový model
  selže s `Model "<model-id>" is not available.` ID modelu nepiš do commitnutého souboru.
- **`auto`:** `/model auto` nebo `--model auto`, zobrazuje se jako [Copilot Fusion](https://docs.github.com/en/copilot/concepts/models/copilot-fusion). Pro každý prompt
  vybere model a vzor provedení: single (jeden model), cascade (levný model napíše návrh, porotce
  ho přijme nebo eskaluje), critique (několik modelů paralelně posoudí návrh). `autoTier` nastavuje
  směrovací profil (`efficiency`, `balance`, `intelligence`), `fusionTier` tier zobrazený ve výběru
  (`standard`: jeden model na úkol; `high`, `max`: může přidat volání modelů). Každý model se
  účtuje vlastní sazbou. Na Auto se pole `model` vlastního agenta ignoruje.

## Reasoning effort a přemýšlení

Reasoning model si před odpovědí píše pracovní text: přeformuluje úkol, zkouší postupy, kontroluje
se. Tyhle **reasoning tokeny** jsou skryté, zabírají kontextové okno a účtují se jako výstupní
tokeny, bez zvláštní ceny. **Úsilí při uvažování (reasoning effort)** určuje, kolik toho model dělá:
víc je pomalejší a dražší a u složitých problémů může odpovědi zlepšit. Znalosti nepřidá.

Úrovně: `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. Každý model nabízí jen některé;
ukazuje je jedině výběr v `/model`. Nenastaveno znamená výchozí hodnotu modelu, u většiny `medium`.

| Rozsah | Jak |
|---|---|
| Jeden běh | `copilot --model <model-id> --reasoning-effort high` |
| Tahle session | `/model`, ↑/↓ na model, ←/→ změní úroveň, Enter |
| Tvoje výchozí nastavení | `/config model` nebo `copilot config effortLevel <level>` (`~/.copilot/settings.json`) |
| Tenhle repozitář | `/model --repo` (zapíše `.github/copilot/settings.json`) |
| Jeden vlastní agent | `reasoning-effort: high` ve frontmatteru `.agent.md` ([06](06-agents.cs.md)) |
| Plan režim | `planEffortLevel`; plan režim úroveň session nedědí |

- **Ne s `auto`:** session se nespustí a skončí chybou
  `Error: Model "auto" does not support reasoning effort configuration (requested: "high").`
- **Jak to vidět:** Ctrl+T zobrazí nebo skryje shrnutí uvažování u modelů, které je poskytují.
  Ve skrytém stavu je to jeden řádek `Thought for Ns`; klikni na něj. Je to shrnutí, ne původní text.

| Udělej tohle | Kdy, v tomhle workshopu |
|---|---|
| Sniž ho, nebo vezmi model Lightweight | Mechanická práce s jasnou specifikací: soubor s instrukcemi ve cvičení 1, skill pluginu ve cvičení 6 |
| Nech výchozí | Jeden endpoint, jeden hook, jeden test: většina cvičení |
| Zvyš ho na `high` | Kořenová příčina napříč soubory: chyby s kaskádovým slučováním a game-over ve cvičení 5, review, plán |
| Nezvyšuj ho | Modelu chybí informace. Chybějící konvence potřebuje instrukci nebo skill, ne vyšší effort |

## Kontext a kredity

- **`/context`** ukazuje okno pro aktuální model: model a využité tokeny z kapacity, potom
  System Prompt, Custom Instructions, System Tools, MCP Tools, Messages, Free Space, Buffer.
- **`/compact [focus]`** nahradí historii shrnutím. Detaily se ztratí a nejde to vrátit.
  Automatická kompakce startuje na pozadí při 80 % okna; při 95 % na ni session čeká
  ([kdy ke kompakci dochází](https://docs.github.com/en/copilot/concepts/prompting-and-context/context-management#when-compaction-happens)).
  Kompakce je volání modelu: v našem běhu 0,20 AI kreditu za session o čtyřech kolech.
- **Kontextový tier:** `default` nebo `long_context` (`--context <tier>`, Tab ve výběru `/model`).
  Dlouhý tier stojí víc: 2× vstup a 1,5× výstup nad 272K vstupních tokenů u modelů GPT-6 ([ceník OpenAI](https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing#openai)).
- **`/usage`** ukazuje `AI Credits` a `Tokens` této session ve tvaru
  `↑ input (N cached, N written) • ↓ output (N reasoning)`, celkem a po modelech, a pak ukazatel
  `Plan`: % využito, využito / rozpočet AIC, čas do resetu.
- **Kredity:** 1 AI kredit = 0,01 USD. Copilot Business zahrnuje 1 900 kreditů na uživatele měsíčně,
  ve společném poolu, reset 1. dne v měsíci, bez převodu ([účtování](https://docs.github.com/en/copilot/concepts/billing-and-usage/organizations-and-enterprises/billing)). Inline doplňování se neúčtuje.
- **Dlouhá session stojí víc za kolo:** model je bezstavový, takže volání N posílá volání 1 až N-1
  znovu jako vstup. Prompt cache opakovanou část zlevní (na 2,5 % až 25 % ceny vstupu podle [ceníku](https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing#pricing-tables)),
  zadarmo není. Na nový úkol použij `/new`, o přestávce `/compact`, jako strop `--max-ai-credits <n>` (minimum 30).

## Vyzkoušej si to (8 min)

1. V kořenu repa spusť `copilot`. Když se zeptá na důvěru ke složce, potvrď ji ([01](01-getting-started.cs.md) to vysvětluje).
2. Napiš `/context`. V našem běhu bylo využito 22k ze 128k tokenů dřív, než jsme cokoli napsali:
   System Prompt 9.7k, System Tools 10.4k, MCP Tools 1.1k, Custom Instructions 760. Messages je 0.
3. Pošli `Read engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt and say in one sentence what slideLineLeft does. Change nothing.`
   Na časové ose se objeví volání nástroje pro čtení souboru a pak odpověď.
4. Napiš `/context` znovu. Vyrostly jen Messages, v našem běhu asi o 1,5k tokenů: tvůj prompt,
   90 řádků, které agent přečetl, a odpověď. Výsledek nástroje zůstává v okně a posílá se znovu
   při každém volání.
5. Stiskni Ctrl+T. Shrnutí uvažování se rozbalí; druhý stisk je sbalí na `Thought for Ns`
   (⚠️ v tomto repu nespuštěno). Žádná změna znamená, že model žádné nevrátil: tak to bylo v našem
   běhu na Auto, a `/usage` přitom reasoning tokeny počítal.
6. Napiš `/model`. Na řádku `Copilot Fusion` mění ←/→ tier (`Standard`, `High`, `Max`). Šipkami ↑/↓
   přejdi na model: ukáže své kredity za 1M tokenů, ←/→ prochází jeho úrovně effortu, Enter ho
   vybere (⚠️ v tomto repu nespuštěno).
7. Napiš `/usage` a přečti si řádky `AI Credits` a `Tokens`. Náš běh po dvou krátkých read-only
   promptech: `↑ 117.9k (69.5k cached, 48.4k written) • ↓ 527 (98 reasoning)`, 1,41 AI kreditu.

## Proč existuje zbytek workshopu

| Vlastnost | Co ji kompenzuje | Návod |
|---|---|---|
| Bezstavový, mezi sessions se nic nenaučí | Vlastní instrukce: načtou se do každé session | [02](02-custom-instructions.cs.md) |
| Kontextové okno je konečné a platí se za něj | Skilly se načítají na vyžádání; vlastní agent pracuje ve vlastním okně | [03](03-skills.cs.md), [06](06-agents.cs.md) |
| Uzávěrka tréninku | Skilly a MCP servery přinášejí za běhu aktuální, lokální znalosti | [03](03-skills.cs.md), [05](05-mcp.cs.md) |
| Vzorkovaný výstup | Hooky pouštějí pokaždé stejný kód; evaly měří přes opakované běhy | [04](04-hooks.cs.md), [09](09-evals.cs.md) |
| Plynulý, ne ověřený | Nejdřív padající test, agent reviewer, oprávnění a sandbox, které omezí škody | [01](01-getting-started.cs.md), [06](06-agents.cs.md), [08](08-permissions-sandbox.cs.md) |

## Copilot vs Claude Code

Claude Code běží ve stejné smyčce se stejnými ovládacími prvky: `/model`, `/context`, `/compact` a úrovně
effortu (`/effort`, `--effort`, `ultrathink` na jedno kolo). Oba nastavují model a effort pro každého subagenta zvlášť.

> 🔷 **Jen Copilot:** jedno předplatné a jeden výběr pokrývají šest dodavatelů; Claude Code pouští jen modely Claude.

> 🔷 **Jen Copilot:** `auto` směruje každý prompt na některý model a CLI na něj umí při rate limitu
> přepnout; Claude Code router po promptech nemá (`opusplan` přepíná jen mezi plánem a provedením).

> 🔷 **Jen Copilot:** CLI pouští i modely, které si přineseš sám: endpointy kompatibilní s OpenAI, endpointy Azure,
> Anthropic nebo Google, lokální Ollamu, plně offline ([dokumentace](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-llm-models)).

Menší rozdíly (effort v plan režimu, `/rubber-duck` na modelu jiného dodavatele): [12](12-copilot-vs-claude.cs.md).

## Další čtení

- [Managing context for GitHub Copilot](https://docs.github.com/en/copilot/concepts/prompting-and-context/context-management) (GitHub) a [Understand and count tokens](https://aistudio.google.com/docs/tokens) (Google)
- [How tool use works](https://platform.claude.com/docs/en/agents-and-tools/tool-use/how-tool-use-works) a [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) (Anthropic): smyčka agenta
- [Reasoning models](https://developers.openai.com/api/docs/guides/reasoning) (OpenAI) a [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) (Anthropic)

Dál: [01 · Začínáme](01-getting-started.cs.md)

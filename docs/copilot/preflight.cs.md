> 🌍 Číst v jazyce: [English](preflight.md) | **Česky**

# Předletová kontrola pro lektora

> ⏱ 1 hodina, před workshopem · Dokumentace: [Enterprise managed settings](https://docs.github.com/en/copilot/reference/enterprise-administrators/enterprise-managed-settings) · [Administering Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/administer-copilot-cli-for-your-enterprise) · [Policies per surface](https://docs.github.com/en/copilot/reference/supported-surfaces-for-policies) · Část B ověřena na Copilot CLI 1.0.114, na účtu, který nespravuje žádná organizace

Část A projdi se svým adminem Copilotu a část B na jednom účastnickém stroji, ve firemní síti,
s účtem účastníka. Zablokované přizpůsobení nehlásí chybu: prostě se nenačte. Návody
tyhle případy nevysvětlují; tahle stránka ano. Každá položka uvádí nastavení, co rozbije
a jak to ověřit. ⚠️ značí kontrolu, která se v tomhle repu nespouštěla.

## A. S adminem Copilotu

### Přístup

- [ ] **Politika Copilot CLI** zapnutá pro každého účastníka. **Rozbije:** všechno. **Ověř:** část B vypíše řádek `cli`.
- [ ] **Přístup k privátnímu repu `klesajos/qti-copilot`.** Enterprise Managed Users obecně nemůžou být spolupracovníky mimo své enterprise. **Rozbije:** klonování; cvičení 4. **Ověř:** `git ls-remote https://github.com/klesajos/qti-copilot` s účtem účastníka ⚠️. **Když je to blokované:** udělej mirror repa ve své organizaci.
- [ ] **Issue pro cvičení 4** v repu (nebo v mirroru), které účastníci můžou číst. **Rozbije:** MCP demo. **Ověř:** otevři seznam issues v prohlížeči jako účastník. Text: [solutions/ex4-issue.md](solutions/ex4-issue.md).
- [ ] **[Seznam modelů](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-default-models).** Které modely jsou zapnuté a je k dispozici `auto`? Rodina Claude Fable je ve výchozím stavu vypnutá. **Rozbije:** nepovolený model je chyba; vestavění agenti (`explore`, agent `code-review` za `/review`) používají vlastní výchozí model; `explore` selhal s `400 The requested model is not supported`, když jeho model nebyl zapnutý. **Ověř:** `/model` v session (model, který použít nemůžeš, je pořád v seznamu a po zvýraznění řekne proč); řádek `model` v části B. **Když je to omezené:** review dělej agentem `kotlin-reviewer`; do promptů pro `/fleet` přidej „Použij subagenty general-purpose“.
- [ ] **[Rozpočet](https://docs.github.com/en/copilot/concepts/billing-and-usage/organizations-and-enterprises/billing).** Kolik AI kreditů účastníkovi zbývá a je zapnutá dodatečná placená spotřeba? **Rozbije:** na 100 % selže každé volání modelu až do resetu; nejrychleji utrácejí evaly a `/fleet`. **Ověř:** `/usage`, řádek Plan.
- [ ] **Obrazový vstup** může být vypnutý. **Rozbije:** nic: žádný návod ani cvičení obrázek nepoužívá. **Ověř:** potvrď si to a řekni účastníkům, ať nevkládají screenshoty.
- [ ] **Stroje s Windows.** Hooky jsou bash skripty (klíč `bash` v `.github/hooks/hooks.json`) a potřebují `jq`. **Rozbije:** návod 04, cvičení 3, pojistku na `.env`. **Ověř:** část B spusť uvnitř WSL 2; nativní Windows ⚠️.
- [ ] **Proxy nebo privátní certifikační autorita.** **Rozbije:** chyby TLS a timeouty; když platí politika registru, zablokuje nedostupný MCP registr každý MCP server kromě vestavěných. **Ověř:** část B ve firemní síti; `copilot help network` vypíše nastavení.

### Politiky organizace

- [ ] **[„MCP servers in Copilot“](https://docs.github.com/en/copilot/concepts/enterprise/mcp-management).** Vypnutá, dokud ji admin nezapne. **Rozbije:** nespustí se žádný MCP server a od CLI 1.0.112 ani vestavěný GitHub server: návod 05 a cvičení 4. **Ověř:** řádek `mcp` v části B.
- [ ] **MCP [registr](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-mcp-usage/restrict-based-on-registry) nebo [allow-list](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-mcp-usage/configure-enterprise-allowlist)** (`allowManagedMcpServersOnly`, `allowedMcpServers`, `deniedMcpServers`). **Rozbije:** každý server, který účastník přidá do `.mcp.json`. **Ověř:** vyžádej si seznam a přesnou URL schváleného Jira serveru, kterou dáš do kopie `.mcp.json.example`.
- [ ] **Experimentální režim a preview featury** (`--experimental`, `/settings experimental on`). **Rozbije:** dynamická workflow (`copilot workflow run`) v návodu 10, příkazy `/eval` z GitHub Copilot Evals v návodu 09, rozpis po skillech v `/context`. **Ověř:** spusť `copilot --experimental` a zadej `/experimental` ⚠️. **Když je to blokované:** tyhle části jsou jen ke čtení.
- [ ] **Copilot cloud agent** a **[vzdálené ovládání](https://docs.github.com/en/copilot/concepts/agent-capabilities/agent-powered-workflows-and-operations/about-remote-control).** **Rozbije:** `/delegate` a `/remote on` v návodu 11. **Ověř:** `/remote show` ⚠️.
- [ ] **[Copilot Memory](https://docs.github.com/en/copilot/concepts/prompting-and-context/copilot-memory).** **Rozbije:** nic, ale dřívější session může ovlivnit pozdější, což zkresluje cvičení 8. **Ověř:** `/memory` ⚠️; vypni ji přes `/memory off`.
- [ ] **[Content exclusion](https://docs.github.com/en/copilot/concepts/security-governance-and-network-settings/content-exclusion).** **Rozbije:** každé cvičení na cestě, které odpovídá nějaké pravidlo. **Ověř:** zeptej se, jestli nějaké pravidlo odpovídá `engine/`, `api/` nebo `web/`.

### Spravovaná nastavení

`managed-settings.json` přichází z repozitáře `.github-private` daného enterprise, z MDM nebo
jako lokální soubor. Vyžádej si ho. Na Macu ukáže lokální soubor `ls "/Library/Application Support/GitHubCopilot/managed-settings.json"`;
nastavení doručená ze serveru žádný soubor nezanechají ([umístění](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference)).

- [ ] **`strictPluginOnlyCustomization`** (`true`, nebo seznam ze `skills`, `agents`, `hooks`, `mcp`). **Rozbije:** `.github/skills/`, `.github/agents/`, `.github/hooks/` a `.mcp.json` se nenačtou: návody 03 až 06. **Ověř:** řádky `skill project` a `agent project` v části B. **Když je nastavené:** přesuň skill a agenty do pluginu `2048-dev`, nebo dělej demo na vlastním stroji.
- [ ] **`allowManagedHooksOnly`.** **Rozbije:** hooky repozitáře neběží: návod 04, cvičení 3, pojistka na `.env`. **Ověř:** řádek `denied` v části B. **Když je nastavené:** spolehni se na pravidla `--deny-tool` a řekni, že `cat .env` pak blokované není.
- [ ] **`strictKnownMarketplaces`**, spravované **`enabledPlugins`.** **Rozbije:** marketplace `qti-copilot` v repu na seznamu není, takže se `2048-dev` nenačte: návod 07, cvičení 6. **Ověř:** dva řádky `plugin` v části B. **Když je nastavené:** požádej admina, ať marketplace přidá.
- [ ] **`permissions.deny`, `.ask`, `.allow`**, **`permissions.disableBypassPermissionsMode`.** **Rozbije:** spravované „ask“ je v bězích `-p` a v autopilotu „deny“ (návody 08, 10), takže `./gradlew` a `npm` musí být na spravovaném allow-listu. `--allow-all` přestane fungovat; návody používají explicitní pravidla. **Ověř:** přečti si ten soubor.
- [ ] **Spravovaný sandbox.** **Rozbije:** hooky běží uvnitř sandboxu; hook, který spouští Gradle nebo npm, může potřebovat cesty navíc. **Ověř:** `/sandbox status` ukáže zapnuto nebo vypnuto, `/sandbox policy` efektivní politiku; samotné `/sandbox` otevře dialog s nastavením.

### Mimo Copilot

- [ ] **Instalace Vally** (`@microsoft/vally-cli` 0.21.0 z npm, připnutý v `package.json`). **Rozbije:** návod 09, cvičení 8. **Ověř:** `npm ci && npm run eval:lint` vypíše dva řádky `is valid`. **Když je to blokované:** `evals/plugin-ab.sh` potřebuje jen `copilot` a `jq`.
- [ ] **Instalace Conductoru** (`uv tool install "git+https://github.com/microsoft/conductor.git@v0.1.47"`). **Rozbije:** část o Conductoru v návodu 10 a ve cvičení 7. **Ověř:** `conductor validate conductor/test-coverage-audit.yaml` vypíše `Validation Successful`.
- [ ] **[Pole v metrikách](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics).** Které pole čte organizace jako používání CLI: `totals_by_cli`, nebo `totals_by_client` s `copilot_cli`? Počítají se běhy Vally a Conductoru (Copilot SDK) a úlohy z `/delegate`? **Rozbije:** to, co návody 01 a 11 říkají účastníkům. **Ověř:** zeptej se. Plugin pro IntelliJ 1.15.0 až 1.19.x počítal některé sessions z IDE jako CLI; 1.20.0 to opravuje.

## B. Na jednom účastnickém stroji

```bash
copilot --version; node --version; java -version; jq --version   # 1.0.114+, Node 24.15+ or 26, JDK 17-27
./gradlew build && (cd web && npm ci && npm test)                 # exit 0, "Tests  7 passed (7)"
```

Jeden běh, asi 0,07 AI kreditu, z kořene repa. Prokáže přihlášení, přístup k modelu, důvěru
ke složce, skill, agenty, plugin, hooky a vestavěný MCP server.

```bash
events=$(mktemp)
copilot -p "Use the view tool to read the file .env in the repository root and print its first line. If the read is refused, quote the refusal message and stop." \
    --output-format json --trust-folder --no-ask-user > "$events"
jq -r 'if .type == "session.start" then "cli\t\(.data.copilotVersion)"
  elif .type == "session.auto_mode_resolved" then "model\t\(.data.chosenModel)"
  elif .type == "session.mcp_server_tools_loaded" then "mcp\t\(.data.serverName)\t\(.data.toolCount)"
  elif .type == "session.skills_loaded" then (.data.skills[] | select(.source == "project" or .source == "plugin") | "skill\t\(.source)\t\(.commandName)")
  elif .type == "session.custom_agents_updated" then (.data.agents[] | "agent\t\(.source)\t\(.id)")
  elif .type == "tool.execution_complete" and .data.success == false then "denied\t\(.data.error.message)"
  elif .type == "result" then "exit\t\(.exitCode)" else empty end' "$events" | sort -u
```

```
agent	plugin	2048-dev:game-explorer
agent	project	board-test-writer
agent	project	kotlin-reviewer
agent	project	workshop-tutor
cli	1.0.114
denied	Denied by preToolUse hook: protect-secrets hook: .env files hold secrets and stay out of the session. Ask the user for the specific value you need.
exit	0
mcp	github-mcp-server	6
model	<model-id>
skill	plugin	2048-dev:build-test
skill	project	board-tests
```

| Chybí řádek | Pravděpodobná příčina |
|-------------|-----------------------|
| Všechny | Nejsi přihlášený, politika CLI je vypnutá, nebo není k dispozici žádný model. Spusť to bez `> "$events"` a přečti si chybu |
| `skill project`, `agent project` | `strictPluginOnlyCustomization`, nebo nejsi v kořenu repa |
| Oba řádky `plugin` | `strictKnownMarketplaces`, spravované `enabledPlugins`, nebo chybělo `--trust-folder` |
| `denied` | Hooky se nenačetly: `allowManagedHooksOnly`, `strictPluginOnlyCustomization`, nebo chybí `jq` |
| `mcp` | Politika „MCP servers in Copilot“ je vypnutá, nebo to blokuje síť |

Počet u `mcp` je 6 s nainstalovaným `gh` a 24 bez něj. Mezi těmi 6 nejsou žádné nástroje pro issues:
návod 05 startuje s `--add-github-mcp-tool list_issues --add-github-mcp-tool issue_read`, což těch 6
nahradí těmihle dvěma. Řádek `model` je to, na co se `auto` ve tvé organizaci vyhodnotí: zapiš si ho. [Rozcestník](README.cs.md).

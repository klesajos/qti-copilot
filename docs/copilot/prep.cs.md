> 🌍 Read this in: [English](prep.md) | **Česky**

# Příprava na workshop

Předem není potřeba nic: nastavení zabere prvních 10 minut bloku 01. Pět minut den předem ale
ušetří místnosti čekání na stažení JDK nebo na chybějící seat Copilotu.

## Účastníci: den předem (5 min)

1. Zkontroluj nástroje. Bez přihlášení a bez volání modelu; jen čte verze:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/klesajos/qti-copilot/main/scripts/check-system.sh | bash
   ```
   Každý řádek musí mít `ok`. Každý řádek `FIX` říká, co nainstalovat. Minimum: JDK 17–27,
   Node.js 24.15+ nebo 26, Copilot CLI 1.0.114, `git`, `jq`. Windows: spusť to ve WSL 2.
2. **macOS:** `/usr/bin/java` je jen zástupný program, který bez nainstalovaného JDK selže,
   a `openjdk` z Homebrew není v `PATH`. Nainstaluj Temurin (`brew install --cask temurin`), nebo:
   ```bash
   brew install openjdk
   echo 'export PATH="$(brew --prefix openjdk)/bin:$PATH"' >> ~/.zshrc   # pak otevři nový terminál
   ```
3. Přihlas se účtem, který má seat Copilot Business nebo Enterprise: `copilot login`.
4. Volitelně: naklonuj a jednou sestav, aby si Gradle (i JDK 21, které stáhne) a npm naplnily
   cache.
   ```bash
   git clone https://github.com/klesajos/qti-copilot && cd qti-copilot
   ./gradlew build && (cd web && npm ci) && npm ci
   scripts/check-setup.sh          # jedno volání modelu, výrazně pod jeden AI kredit
   ```

## Lektor: před workshopem

- [ ] Požádej admina organizace každého účastníka o zapnutí politiky **Copilot CLI**; samotný seat
      nestačí. `scripts/check-setup.sh` ukáže, které mechanismy politika blokuje.
- [ ] Dva dny předem pošli účastníkům sekci výše.
- [ ] Projdi si zkušební běh sám na čistém stroji: `check-system.sh`, `check-setup.sh`, pak cvičení 0.
      Poslední zaznamenaný běh je ve [screenshots/](screenshots/README.md).
- [ ] Cvičení 4 potřebuje issue: `gh issue create --title "Show the best score" --body-file docs/copilot/solutions/ex4-issue.md`,
      a jeho číslo řekni místnosti. Bez `gh` si účastníci přečtou soubor.
- [ ] Měj připravené patche s řešením: `git apply docs/copilot/solutions/exN.patch`.
- [ ] Rozpočet kreditů: jeden celý běh stál asi 15 AI kreditů (0,2–2 na cvičení); cvičení 7
      a `npm run eval:ab` stojí víc.

## Známé pasti

| Příznak | Příčina | Oprava |
|---|---|---|
| `check-setup.sh` hlásí `MISS java … no JDK answers` | zástupný program macOS, žádné JDK v `PATH` | krok 2 výše |
| Copilot v cvičení 0 žádá o přístup k cestám mimo repo | `./gradlew` nenašel JDK | oprav `PATH`, `/exit`, `scripts/copilot-ws.sh --continue` |
| `npm warn install-scripts … koffi` při `npm ci` | npm 12 zadrží instalační skripty | lintu a dry-runu to nevadí; před `eval:ab` spusť `npm install-scripts approve koffi` |
| `conductor: command not found` po `uv tool install` | `~/.local/bin` není v `PATH` | `uv tool update-shell`, nový terminál |
| Možnost 1 v menu plánu provede celý plán | pořadí v menu se změnilo | zvol **Exit to Interactive execution mode** podle názvu |

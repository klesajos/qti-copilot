> 🌍 Číst v jazyce: [English](README.md) | **Česky**

# 2048 — projekt pro workshop GitHub Copilot

Malá hra 2048: pravidla v Kotlinu, REST API ve Spring Bootu a UI v Reactu. Slouží jako základ
pro praktickou část workshopu o vývoji s pomocí AI v **GitHub Copilot CLI**. Během workshopu
do ní přidáváme funkce, opravujeme chyby, dopisujeme testy a refaktorujeme, přičemž kód
generuje Copilot.

Návody k workshopu jsou v [docs/copilot/](docs/copilot/README.cs.md). Začni tam: program zabere
4 h, bez přípravy předem. Kontrolu stroje den předem najdeš v
[prep.cs.md](docs/copilot/prep.cs.md), nebo spusť `scripts/check-system.sh`.

## Požadavky

- Libovolné JDK 17–27 v `PATH` pro spuštění Gradlu. Samotný build používá JDK 21, které si
  Gradle stáhne, pokud chybí.
- Node.js 24 (24.15 nebo novější) nebo 26.
- `git` a `jq` (skripty hooků používají `jq`).
- GitHub Copilot CLI 1.0.114 nebo novější pro samotný workshop; viz
  [docs/copilot/01-getting-started.cs.md](docs/copilot/01-getting-started.cs.md).

## Build a spuštění

```bash
./gradlew build                 # compile and test engine + api
./gradlew :api:bootRun          # API on http://localhost:8080

cd web
npm ci                          # once
npm run dev                     # UI on http://localhost:5173, proxies /api to the API
```

Otevři http://localhost:5173, když běží API.

## Testy

```bash
./gradlew test                  # engine (JUnit) + api (Spring MVC tests)
cd web && npm test              # Vitest
cd web && npm run lint && npm run build
```

## Ovládání

Dlaždice posouváš šipkami nebo klávesami `W` `A` `S` `D`. **New game** spustí hru od začátku.

## Struktura

```
engine/   game rules: Board.kt (slideLineLeft, Board) and its tests   ← no I/O, no Spring
api/      REST service: GameService, GameController, error handler    ← /api/v1/games
web/      React UI: App, Board, API client, key mapping
.github/  Copilot customizations: instructions, skill, agents, hooks, plugin settings
plugins/  the 2048-dev plugin, served by the in-repo marketplace (marketplace.json)
evals/    evals for the skill, the agent and the plugin
conductor/ a Microsoft Conductor workflow
docs/copilot/  workshop guides, exercises with solution patches, cheat sheet
```

Srdcem hry je `slideLineLeft()` v
`engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`. Začni číst tam.

Kód obsahuje několik záměrných chyb pro cvičení. Testy přesto procházejí; zjistit, proč tomu tak je,
je součástí workshopu.

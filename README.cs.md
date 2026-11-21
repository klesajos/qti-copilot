> 🌍 Číst v jazyce: [English](README.md) | **Česky**

# 2048 — projekt pro workshop GitHub Copilot

Malá hra 2048: pravidla v Kotlinu, REST API ve Spring Bootu a UI v Reactu. Slouží jako základ
pro hands-on část workshopu o AI-asistovaném vývoji s **GitHub Copilot CLI**. Během workshopu
do ní přidáváme funkce, opravujeme chyby, dopisujeme testy a refaktorujeme, přičemž kód
generuje Copilot.

Návody k workshopu jsou v [docs/copilot/](docs/copilot/README.cs.md). Začni tam.

## Požadavky

- Libovolné JDK 17–27 v `PATH` pro spuštění Gradlu. Samotný build používá JDK 21, které si
  Gradle stáhne, pokud chybí.
- Node.js 24 (24.15 nebo novější) nebo 26.
- `git` a `jq` (skripty hooků používají `jq`).
- GitHub Copilot CLI 1.0.114 nebo novější pro samotný workshop; viz
  [docs/copilot/00-install.cs.md](docs/copilot/00-install.cs.md).

## Build a spuštění

```bash
./gradlew build                 # přeloží a otestuje engine + api
./gradlew :api:bootRun          # API na http://localhost:8080

cd web
npm ci                          # jednou
npm run dev                     # UI na http://localhost:5173, /api přeposílá na API
```

Otevři http://localhost:5173, když běží API.

## Testy

```bash
./gradlew test                  # engine (JUnit) + api (testy Spring MVC)
cd web && npm test              # Vitest
cd web && npm run lint && npm run build
```

## Ovládání

Dlaždice posouvají šipky nebo `W` `A` `S` `D`. **New game** začne znovu.

## Struktura

```
engine/   pravidla hry: Board.kt (slideLineLeft, Board) a jeho testy   ← bez I/O, bez Springu
api/      REST služba: GameService, GameController, obsluha chyb       ← /api/v1/games
web/      React UI: App, Board, API klient, mapování kláves
.github/  úpravy Copilota: instrukce, skill, agenti, hooky, nastavení pluginu
plugins/  plugin 2048-dev, který nabízí marketplace přímo v repozitáři (marketplace.json)
evals/    evaly pro skill, agenta a plugin
conductor/ workflow pro Microsoft Conductor
docs/copilot/  návody k workshopu, cvičení, tahák
```

Srdcem hry je `slideLineLeft()` v
`engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`. Začni číst tam.

Kód obsahuje několik záměrných chyb pro cvičení. Testy přesto procházejí; zjistit proč je
součástí workshopu.

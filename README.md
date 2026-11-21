> 🌍 Read this in: **English** | [Česky](README.cs.md)

# 2048 — GitHub Copilot workshop project

A small 2048 game: rules in Kotlin, a Spring Boot REST API, and a React UI. It is the
hands-on project of a workshop on AI-assisted development with **GitHub Copilot CLI**. During
the workshop we add features to it, fix bugs, write tests and refactor, with Copilot generating
the code.

The workshop guides are in [docs/copilot/](docs/copilot/README.md). Start there: the agenda takes
4 h, with no preparation in advance.

## Requirements

- Any JDK 17–27 on `PATH` to launch Gradle. The build itself uses JDK 21, which Gradle
  downloads if it is missing.
- Node.js 24 (24.15 or later) or 26.
- `git` and `jq` (the hook scripts use `jq`).
- GitHub Copilot CLI 1.0.114 or later for the workshop itself; see
  [docs/copilot/01-getting-started.md](docs/copilot/01-getting-started.md).

## Build and run

```bash
./gradlew build                 # compile and test engine + api
./gradlew :api:bootRun          # API on http://localhost:8080

cd web
npm ci                          # once
npm run dev                     # UI on http://localhost:5173, proxies /api to the API
```

Open http://localhost:5173 with the API running.

## Tests

```bash
./gradlew test                  # engine (JUnit) + api (Spring MVC tests)
cd web && npm test              # Vitest
cd web && npm run lint && npm run build
```

## Controls

Arrow keys or `W` `A` `S` `D` move the tiles. **New game** starts over.

## Structure

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

The heart of the game is `slideLineLeft()` in
`engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt`. Start reading there.

The code contains a few deliberate bugs for the exercises. The test suite is green anyway;
finding out why is part of the workshop.

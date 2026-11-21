# 2048

A 2048 game used as the hands-on project of a GitHub Copilot workshop.

## Stack

- **engine/** — Kotlin 2.4, pure game rules, JUnit 6 (Jupiter) tests. No I/O, no Spring.
- **api/** — Spring Boot 4.2 (Spring MVC, Jackson 3) REST service in Kotlin. Depends on `engine`.
- **web/** — React 19 + TypeScript 6 (strict) on Vite 8, tested with Vitest 5 and Testing Library.
- Build: Gradle 9 wrapper with a JDK 21 toolchain; npm with a committed lockfile. Node 24 or 26.

This is Spring Boot **4**, not 3. Use `spring-boot-starter-webmvc`, Jackson 3 packages
(`tools.jackson.*`), `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`,
`MockMvcTester` and `@MockitoBean`. Do not generate Boot 3 idioms (`@MockBean`,
`com.fasterxml.jackson.*` imports, `TestRestTemplate`).

## Directory structure

```
engine/src/main/kotlin/com/quanti/g2048/engine/Board.kt   rules: slideLineLeft, Board
engine/src/test/kotlin/com/quanti/g2048/engine/           board tests
api/src/main/kotlin/com/quanti/g2048/api/                 GameService, GameController, error handler
web/src/                                                  App, Board, api client, key mapping
```

## Conventions

- Game rules live in `engine` only. `api` decides what happens around a move; `web` only renders.
- Kotlin: official code style, 4 spaces, no wildcard imports, explicit names over abbreviations.
- Thin controllers: `GameController` maps HTTP to `GameService` and nothing else.
- REST: resources under `/api/v1`, success as `{ "data": ... }`, errors as
  `{ "error": { "code": "...", "message": "..." } }` with a fitting HTTP status. Never return
  framework exception text to the client.
- TypeScript: strict, no `any`, functional components with hooks, named exports.
- Tests describe behaviour in the test name, follow Arrange-Act-Assert, and do not depend on each other.

## Commands

```bash
./gradlew build                 # compile and test engine + api
./gradlew :engine:test          # board tests only
./gradlew :api:bootRun          # API on http://localhost:8080
cd web && npm ci                # once
cd web && npm run dev           # UI on http://localhost:5173, proxies /api to :8080
cd web && npm test              # Vitest
cd web && npm run lint && npm run build
```

After changing code, run the tests for the part you touched and report the result.

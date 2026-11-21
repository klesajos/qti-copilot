---
name: build-test
description: Build the 2048 project and run every test suite (Gradle and Vitest), then summarize the results without fixing anything. Use when asked to build, to run all tests, or to check whether the tree is green.
---

# Build and test

Build the project and run the tests:

1. Backend: `./gradlew build`
2. Frontend: `cd web && npm test && npm run lint && npm run build`
   (run `npm ci` first if `web/node_modules` is missing)

Then report:

- Build: OK, or the first compiler error with `file:line`.
- Tests: passed and failed counts per suite (engine, api, web). For each failure, name the
  test and show the expected and actual values.
- Do not fix anything. This skill only reports status.

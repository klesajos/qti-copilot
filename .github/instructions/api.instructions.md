---
applyTo: "api/**/*.kt"
---

# API rules

- Controllers stay thin: parse the request, call `GameService`, wrap the result in `ApiResponse`.
- New failure cases get their own exception and a handler in `ApiExceptionHandler` that returns
  `ErrorResponse` with a stable `code`. Write the message yourself; do not pass exception text through.
- Validate input at the boundary. Path and body values that cannot be parsed answer 400, not 500.
- Do not put game rules here. If a move needs a new rule, it belongs in `engine`.
- Controller tests use `@WebMvcTest` with `MockMvcTester` and assert on the JSON body, not on Kotlin objects.
- Run `./gradlew :api:test` after the change and report the pass and fail counts.

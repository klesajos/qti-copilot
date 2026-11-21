As a player I want to see the best score reached so far, so that I have something to beat.

## Acceptance criteria

- [ ] The API remembers the highest score any game has reached since the server started.
      In memory is enough; it is lost on restart, like the games.
- [ ] Every game state the API returns (create, find, move) carries it as `bestScore`.
- [ ] A new game reports the best score of earlier games, not 0.
- [ ] A later game with a lower score does not lower it.
- [ ] Tests cover each point above.

## Out of scope

Persistence across restarts. Per-player scores. Showing the value in the web UI (separate issue).

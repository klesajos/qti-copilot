> 🌍 Read this in: **English** | [Česky](prep.cs.md)

# Workshop prep

Nothing is required in advance: setup is the first 10 minutes of block 01. Five minutes the day
before still saves the room from waiting on a JDK download or a missing Copilot seat.

## Participants: the day before (5 min)

1. Check your tools. No login and no model call; it only reads versions:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/klesajos/qti-copilot/main/scripts/check-system.sh | bash
   ```
   Every line must read `ok`. Each `FIX` line says what to install. The minimums: JDK 17–27,
   Node.js 24.15+ or 26, Copilot CLI 1.0.114, `git`, `jq`. Windows: run it inside WSL 2.
2. **macOS:** `/usr/bin/java` is a stub that fails until a JDK is installed, and Homebrew's
   `openjdk` is not on `PATH`. Install Temurin (`brew install --cask temurin`), or:
   ```bash
   brew install openjdk
   echo 'export PATH="$(brew --prefix openjdk)/bin:$PATH"' >> ~/.zshrc   # then open a new terminal
   ```
3. Log in with the account that holds the Copilot Business or Enterprise seat: `copilot login`.
4. Optional: clone and build once so Gradle (and the JDK 21 it downloads) and npm fill their
   caches.
   ```bash
   git clone https://github.com/klesajos/qti-copilot && cd qti-copilot
   ./gradlew build && (cd web && npm ci) && npm ci
   scripts/check-setup.sh          # one model call, well under one AI credit
   ```

## Facilitator: before the day

- [ ] Ask each participant's organisation admin to enable the **Copilot CLI** policy; a seat alone
      is not enough. `scripts/check-setup.sh` shows which mechanisms a policy blocks.
- [ ] Send the participant section above two days ahead.
- [ ] Run the dry run yourself on a clean machine: `check-system.sh`, `check-setup.sh`, then exercise 0.
      The last recorded run is in [screenshots/](screenshots/README.md).
- [ ] Exercise 4 needs an issue: `gh issue create --title "Show the best score" --body-file docs/copilot/solutions/ex4-issue.md`,
      and note its number for the room. Without `gh`, participants read the file instead.
- [ ] Have the solution patches ready to share: `git apply docs/copilot/solutions/exN.patch`.
- [ ] Budget credits: one full run used about 15 AI credits (0.2–2 per exercise); exercise 7 and
      `npm run eval:ab` cost more.

## Known traps

| Symptom | Cause | Fix |
|---|---|---|
| `check-setup.sh` says `MISS java … no JDK answers` | macOS stub, no JDK on `PATH` | step 2 above |
| Copilot asks for path access outside the repo during exercise 0 | `./gradlew` found no JDK | fix `PATH`, `/exit`, `scripts/copilot-ws.sh --continue` |
| `npm warn install-scripts … koffi` during `npm ci` | npm 12 holds back install scripts | harmless for lint and dry-run; `npm install-scripts approve koffi` before `eval:ab` |
| `conductor: command not found` after `uv tool install` | `~/.local/bin` not on `PATH` | `uv tool update-shell`, new terminal |
| The plan menu's option 1 runs the whole plan | menu order changed | choose **Exit to Interactive execution mode** by its label |

## Review
- Correct: `start(_:)` only records a new `Process` after `try process.run()` succeeds, so a launch failure does not falsely mark the app active (`Sources/Caffeine/main.swift:33-46`).
- Correct: switching durations avoids the old process clearing the new active state: the termination handler checks process identity (`Sources/Caffeine/main.swift:27-30`), then the old handler is nilled before termination (`Sources/Caffeine/main.swift:35-42`).
- Correct: timed sessions have two finish paths: `caffeinate -t` process termination (`Sources/Caffeine/main.swift:26-30`) and a UI timer guard (`Sources/Caffeine/main.swift:63-65`). `swiftc -typecheck Sources/Caffeine/main.swift -framework AppKit` passed.
- Correct: `build.sh` is minimal and syntactically valid; it compiles the Swift file and writes an LSUIElement app bundle (`build.sh:10-30`). `bash -n build.sh` passed.
- Blocker: `Quit` can leave the child `/usr/bin/caffeinate` process running. The app starts and stores a long-lived child process (`Sources/Caffeine/main.swift:23-43`), but the Quit menu item calls `NSApplication.terminate(_:)` directly (`Sources/Caffeine/main.swift:83`) and there is no `applicationWillTerminate` cleanup near the existing delegate methods (`Sources/Caffeine/main.swift:10-13`, `49-61`). Smallest fix: add `applicationWillTerminate(_:)` that clears the handler and terminates `caffeinate`.
- Note: the remaining-time label is rounded down, so a fresh 60-minute session can immediately show `59m` because `Int(endDate.timeIntervalSinceNow / 60)` truncates fractional minutes (`Sources/Caffeine/main.swift:87-90`). Smallest fix: use `ceil` before converting to `Int`.
- Note: selected durations are marked by prefixing `✓` into titles (`Sources/Caffeine/main.swift:76-81`). That works visually, but it is weaker menu UX/accessibility than `NSMenuItem.state = .on`. Smallest fix: keep titles stable and set `.state` on the selected item.
- Note: `plan.md` and `progress.md` requested by the task were not present at `/Users/rnz/tools/Caffeine/`; review used the source, README, and build script instead.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Review only; no source files were modified and scope was limited to Sources/Caffeine/main.swift and build.sh plus README/context checks."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Findings cite concrete file/line refs and validation commands for typecheck/build-script syntax/menu target behavior."
    }
  ],
  "changedFiles": [
    "/Users/rnz/tools/Caffeine/review-correctness.md"
  ],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "cd /Users/rnz/tools/Caffeine && git status --short",
      "result": "failed",
      "summary": "Not a git repository; no index/staged-file state available."
    },
    {
      "command": "cd /Users/rnz/tools/Caffeine && nl -ba Sources/Caffeine/main.swift && nl -ba build.sh",
      "result": "passed",
      "summary": "Collected line-numbered source evidence."
    },
    {
      "command": "cd /Users/rnz/tools/Caffeine && bash -n build.sh",
      "result": "passed",
      "summary": "build.sh syntax check produced no errors."
    },
    {
      "command": "cd /Users/rnz/tools/Caffeine && swiftc -typecheck Sources/Caffeine/main.swift -framework AppKit",
      "result": "passed",
      "summary": "Swift/AppKit typecheck produced no errors."
    },
    {
      "command": "swift -e 'import AppKit; ... NSApplication.target(forAction:to:from:) ...'",
      "result": "passed",
      "summary": "Confirmed AppKit can resolve nil-target actions to the app delegate; no concrete target-wiring bug reported."
    }
  ],
  "validationOutput": [
    "bash -n build.sh: no output, exit 0",
    "swiftc -typecheck Sources/Caffeine/main.swift -framework AppKit: no output, exit 0",
    "AppKit target resolution probe printed: D",
    "plan.md/progress.md reads returned ENOENT"
  ],
  "residualRisks": [
    "No runtime GUI interaction was performed; review is static plus typecheck/syntax checks.",
    "Repository is not a git worktree, so staged-file status cannot be independently verified with git."
  ],
  "noStagedFiles": true,
  "diffSummary": "No source diff; wrote review findings only.",
  "reviewFindings": [
    "blocker: Sources/Caffeine/main.swift:83 - Quit terminates the app without stopping the active caffeinate child process.",
    "note: Sources/Caffeine/main.swift:87-90 - remaining minutes are floored, causing early under-reporting.",
    "note: Sources/Caffeine/main.swift:76-81 - checkmarks are embedded in titles instead of using NSMenuItem.state."
  ],
  "manualNotes": "Requested plan.md and progress.md were missing. /Users/rnz/tools/Caffeine is not a git repository."
}
```

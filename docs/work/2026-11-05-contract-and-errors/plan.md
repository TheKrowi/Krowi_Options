# Plan: 2.0's contract written down, its errors contained, and the shared window state in sync
Spec: [spec.md](spec.md). Status: approved (Krowi, in plan mode, 2026-11-05)

Branch `fix/2026-11-05-contract-and-errors`, from `main` at `48d0803`, in the worktree `.claude/worktrees/fix-2026-11-05-contract-and-errors`. Krowi_AchievementFilter's test side is on its own branch `test/2026-11-05-options-contract`. The two-copy gate (Krowi_ClaudeKit `docs/work/2026-11-05-two-copy-gate`) is proven on this work's merged result, before the 2.0 release.

## Files that change
- `docs/work/2026-11-05-contract-and-errors/repro/repro.lua` (new): the test, built on the review fixes' repro (`Fresh`, `LoadCopy`, `Config`, `Option`, `Window`, `Recorder`, `RecordFrames`, `Check`), with a `time` stub. It exits 1 on a failure.
- `docs/work/2026-11-05-review-fixes/repro/repro.lua`: check #4b reads `saved.Window.Point`, since the shared keys move into the block by design.
- `Krowi_Options.lua`:
  - the config header (requirements 1, 3, 4, 5, 7);
  - `ReadWindow`, `lib.CurrentShared`, `Protected`;
  - `GetFrame` (the block first, `lib.Frame` set at once, `OnCreated` over a snapshot);
  - `lib.SetShared` writing the whole block;
  - `CreateWindow`'s late `OnCreated`.
- `WindowMixin.lua`:
  - `Init(block)`;
  - `Protected` around `OnSectionShown`, the page's reads and `GetHelp`;
  - `ShowSection` always ends its fill.
- `Search.lua`: each section's search through `Protected`.
- `RowMixins.lua`:
  - the elements header (requirements 2, 6, 7);
  - `TabRowMixin:Refresh` hides the check box without `Show`;
  - `OptionRowMixin:Init` drops its option before ending a capture.
- Every Lua file, the six code files and the twelve locale files: `if not KROWI_LIBMAN then return end` before the registration.
- `CLAUDE.md`:
  - the file-start rule;
  - the public surface;
  - the key row in the taint list;
  - the saved keys;
  - the globals line, from Krowi_AchievementFilter's `library-globals-window` step.
- `_Packaging/Changelog.md`: the 2.0 entry's lines for authors.

Every minor stays 0 (2.0 unreleased).

## Order of work
1. Write the repro and run it against `48d0803`: every new check must fail. Commit it with this plan.
2. Build, in this order, rerunning the repro after each step:
   1. the shared state (9-12);
   2. `OnCreated` (13);
   3. the rows (14, 15);
   4. the guards (16);
   5. the standalone guard (17);
   6. the headers (1-7).
3. Update #4b in the review fixes' repro; both repros print `every check passes`.
4. Krowi_AchievementFilter's branch, pointed at this branch: its lint and all its headless suites.
5. `Find-DeprecatedApi.ps1` on live, classic and classic_titan; `krowi:taint-reviewer` and `/code-review` on the diff. Fix or list what they find.
6. In game through Krowi_AchievementFilter's branch: `Run-GameTests.ps1 options, escape` on Retail, `options` on Mists. Write CLAUDE.md's globals line from `library-globals-window`.
7. Changelog, then commit (`fix: ...`) and push. Open the PR. Krowi_AchievementFilter's PR follows it.

## Risks
- **A tab whose saved table is not there yet** misses the first copy. It gets the next write: the spec's accepted behaviour.
- **The new guards could hide a library error in Krowi_AchievementFilter's headless run:** its `run-tests.lua` reports the handler's errors after the options suite too, on its branch.
- **`SetShared` before the window exists** (Krowi_AchievementFilter's `window-second-tab` calls it) resolves the block the same way `GetFrame` does.
- **The extra `xpcall` closures** run only on a player's action in the open window, so no background job allocates.

## Proof
<filled in at the end>

# Plan: 2.0's contract written down, its errors contained, and the shared window state in sync
Spec: [spec.md](spec.md). Status: done (approved by Krowi in plan mode, 2026-11-05)

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

## Where the build departed from the plan
- **Two more review rounds of the fix itself.**
  - The `/code-review` (high) of `a76abaf` found that finding the newest block called every addon's `Saved` unguarded, so one broken addon broke the window for all, and that several config calls (`SectionName`, `IsNew`, `Landing`, `ChangedCount`, help's `Blocks`) could still leave a fill unfinished. The fix, `d0a3130`, added `OtherSaved`, the anchor check, `Init` through `Protected`, `Ask` at every config and help call, and each part of a fill on its own.
  - A second `/code-review` (medium), of that fix, found a `ShowMeNote` function that errored being handed to `SetText` by an `and ... or` idiom; a `ShowMeSecure` that errored never being let go; an erroring `Saved` reported on every change; and a `ResetSection` that errored hiding the reload bar. Fixed in `390b3b8`.
  - Each finding first got a repro check that failed: 12b, 13d to 13f, 16g to 16k.
- **Not taken from the reviews, with the reason:**
  - a tab whose saved table appears only after the window is made is not compared (the spec's accepted case: open after `PLAYER_LOGIN`);
  - the search's allocations per keystroke (only while the player types in the open window);
  - a row's init error skipping the footer (Blizzard runs every row's init through `secureexecuterange`, `ScrollBoxListView.lua:421` live, `:407` classic, so it never escapes `SetDataProvider`).
- **`library-globals` stays a load-time scenario;** the window's globals got a new live step, `library-globals-window`, after `open`.
- **KAF's `Run-GameTests.ps1` verdict** counts FAIL lines, not differences from the headless run: `options`' `y-on-new-install` always differs.
- **`Tests/README.md` is unchanged:** its options row names no single steps.
- **The final in-game runs are the two-copy gate's,** through KAF's branch with the code at `390b3b8`: the full `options` and `escape` with equal copies, and the smoke of `options` plus `escape` in the mixes (Krowi, 2026-11-05: "Full in equal, smoke elsewhere"). On Mists, `escape` runs too.
- **`main`'s gate-log enrollment (#3) is merged into the branch,** and both work folders the branch changes got a `gates.md`. The merge changed only `CLAUDE.md`, so the code hash the two-copy records name is the same.

## Proof
- **Repro:** `repro/repro.lua` 25 of 25 pass. Every check failed before its fix: 16 at `48d0803`, 5 at `a76abaf`, 4 at `d0a3130`. The review fixes' repro passes, #4b reading `saved.Window`.
- **Checks:**
  - syntax clean on the 18 files;
  - `Find-DeprecatedApi.ps1` clean on live, classic and classic_titan;
  - `krowi:taint-reviewer` on the diff: no hazard. Its one robustness note, an anchor name `SetPoint` refuses, is fixed in `d0a3130`.
- **Krowi_AchievementFilter's branch:** lint 0 errors; all 17 headless suites green on both clients.
- **In game, at `d0a3130`, 2026-11-05:**
  - Retail `options` 98 passed, 0 failed, 1 skipped (`y-on-new-install`, headless only); `escape` 34 of 34;
  - Mists `options` 98 passed, 0 failed, 1 skipped;
  - BugGrabber clean on both;
  - `window-second-tab`: `shared=both`, the whole block;
  - `library-globals-window`: ClearButton, SearchIcon and Text under the window's name, and TitleBg on Mists, nothing else.
- **Two copies, 2026-11-06** (Krowi_ClaudeKit's `Test-TwoCopies.ps1`, through Krowi_AchievementFilter's branch, code hash of `390b3b8`): every case passed on both clients.
  - **Cases:** equal, all raised, and the two halves. No old/new pair: 1.0 registered `Krowi_Options_1`, which never mixes with `_2`.
  - **Suites:** `options` in full and `escape` with equal copies; the smoke of `options` and `escape` in the three mixes (Krowi, 2026-11-05).
  - **Retail:** `options` 98 passed and 0 failed in full, 48 and 0 in each smoke; `escape` 34 of 34 in every case.
  - **Mists:** `options` 98 and 0 in full, 48 and 0 in each smoke; `escape` 33 of 34 in every case, the one skipped Retail-only.
  - **Every case:** the second copy loaded, every registration on the minor the case expects (the kit's probe addon), and no BugGrabber row naming Krowi_Options.
  - **The mutation** `lib.Tabs = {}` in the second copy, all raised, on Retail (2026-11-05): the case failed, as it should, with 11 `options` FAILs, 5 `escape` FAILs and a BugGrabber row from `WindowMixin.lua:1174`.
  - **The release preflight** now shows the gate as OK ("equal, all-raised, half-a, half-b passed on Classic, Retail for this code"), with the static check clean. Before the runs it failed there.

## Backlog for 2.1 (the whole-library review, Krowi's scope of 2026-11-05)
- The undo arrow resets a paired control but reports only the toggle, so a paired control that needs a reload does not light the reload bar.
- A question asked on the overview cannot be answered (Defaults, its Yes, is hidden there).
- A slider without a step only reaches its two ends; one with min equal to max divides by zero.
- After a change the page keeps old element data when its row signature is the same (a link's `Detail`, a tab row's `Position`).
- `With` on a non-toggle makes the row's own slider or button drive the `With`.
- Closing the window during a search reruns the section on the hidden window.
- Retail's named colour codes (`|cn...:`) are not stripped from the searched text.
- A closure per row on each refresh.
- The leftovers of 1.0's per-tab strings (`ApplyStrings` on every tab switch, guards on strings that are always set).
- A window left shown after its last tab unregisters (tests only).

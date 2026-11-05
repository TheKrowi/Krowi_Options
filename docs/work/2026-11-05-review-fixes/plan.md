# Plan: the 2.0 code review's findings #1, #2 and #4 to #9
Spec: [spec.md](spec.md). Status: done

Branch `fix/2026-11-05-options-review-fixes`, from `feature/2026-11-04-normal-library` at `de2cb58`, in the worktree `.claude/worktrees/fix-2026-11-05-options-review-fixes`. The main checkout and PR #2 belong to the KAF extraction session.

## Files that change
- `Search.lua`: #1, the option's row recorded after its parent lookup.
- `Krowi_Options.lua`:
  - #2, the tabs' metatable on `lib.Mixins.Tab`.
  - #4, `FindSaved`, `GetSaved`'s error, `GetFrame` asking for the saved table before building, `SetShared` skipping a tab without one, `CheckConfig` in `CreateWindow`.
  - #9, `lib.WindowName`.
  - The config comment notes `OnCreated` is the only optional field.
- `WindowMixin.lua`:
  - #4, `ShowTab` asking for the saved table first.
  - #5, `Flatten` taking nil; `LastSection` saved after `FillPage`.
  - #6, the signature's `With.Id or ""`.
  - #7, `RefreshRow` in `xpcall`; `OnEvent`'s refresh in `xpcall`.
- `RowMixins.lua`: #6, the header's option interface; #8, `Forward` and the tab row's loop set `SetMotionScriptsWhileDisabled`.
- `RowFrames.lua`: #8, `build.CheckButton` sets `SetMotionScriptsWhileDisabled(true)`.
- `WindowFrame.lua`: #9, the frame named `lib.WindowName`.
- `CLAUDE.md`:
  - the window's global name
  - `lib.WindowName`
  - `CreateWindow`'s check in the Consumers part
  - KAF's uses of the name
- `_Packaging/Changelog.md`: the 2.0 entry's lines.
- `docs/work/2026-11-05-review-fixes/`: these files, the reproduction and the backlog.

Every minor stays 0 (2.0 unreleased).

## Order of work
1. Commit the work folder with the decision: `docs(work): intent and spec for 2026-11-05-review-fixes`. [repro/repro.lua](repro/repro.lua) is the test; it fails 13 of 14 before the fix.
2. #1, then rerun the reproduction.
3. #2 and #4 (`Krowi_Options.lua`, then `ShowTab`), then rerun it.
4. #5, #6 and #7 (`WindowMixin.lua`, `RowMixins.lua`'s header), then rerun it.
5. #8 (`RowFrames.lua`, `RowMixins.lua`), then rerun it.
6. #9 (`Krowi_Options.lua`, `WindowFrame.lua`). Then tell the KAF session that `lib.WindowName` is in, so it can switch its uses.
7. CLAUDE.md and the changelog.
8. `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer` on the diff, `/code-review`. Fix or list what they find.
9. Commit (`fix: the 2.0 code review's findings: ...`) and push the branch. Then the in-game check, once the KAF session's run is done and Krowi says so.

## Risks
- **`CheckConfig` refuses a config KAF passes:** KAF's `Options/Window/Window.lua:110-132` was checked against the field list. The in-game `/kaftest options` run confirms it.
- **`GetSaved` now errors where it returned the `Saved` function:** only a broken config gets there. KAF's `Saved()` always returns a table.
- **Motion scripts while disabled run Blizzard's own `OnEnter` on disabled controls:**
  - Read for the icon buttons (art follows `IsEnabled()`).
  - The dropdown button and the slider's steppers need the game: check that a disabled dropdown under the mouse shows no hover art.
- **KAF's tests read `Krowi_OptionsWindow`:** they fail on this branch until the KAF session switches them to `lib.WindowName`. The in-game run waits for that.
- **The deploy:** one AddOns folder per client, and the KAF session's build is in the game with a pending test request (until 11:50). No deploy without Krowi's go.

## In-game check (Krowi, 2026-11-05)
Unattended (Krowi: "devise the test so it can run without my supervision"), run by the KAF extraction session, which Krowi handed the check to:
- The build is KAF's `feature/2026-11-04-options-strings` at `4238364a`, which reads the window's name from `lib.WindowName`. It holds this session's `6176b3f3`, which adds the #8 steps to the `options` suite.
- `Libs/Krowi_Options` is at `4369f10`, the same code as this branch's head: only `docs/work/` changed after it. The pointer stays uncommitted.
- KAF's `Request-GameTests.ps1 options, escape` (Retail) and `Request-GameTests.ps1 options -Client Classic` (Mists), one client at a time: Retail and Mists on the same Battle.net account log each other out.
- The suites run on their own. A panel lists each suite's counts and its failed and skipped lines; the full lines reach `Read-GameTests.ps1` after the next logout or `/reload`.
- `toggle-reset-clipped` waits 30 s for a hand on the mouse, then SKIPs. It tests the undo arrow on a half-hidden row (`2f95232`), which none of the eight fixes touches.

## Departures
- The reproduction's #9 check now catches the name `build.Window` passes to `CreateFrame`, building the window on stand-in frames. It used to read a string literal in the source, and the name is now `lib.WindowName`. It still fails on `de2cb58`'s `Krowi_OptionsWindow`.
- The reproduction finds Krowi_Util from a worktree too.
- The in-game check runs unattended, so #8's hover is checked by KAF's `greyed-help` steps, not by Krowi's mouse. Hovering a greyed slider bar and input box went to the backlog (31).
- The KAF extraction session ran the in-game check from its own worktree, not from one of this session's (Krowi handed it the run). This session's KAF worktree `test-2026-11-05-options-review-fixes` was removed unused; its commit is on `feature/2026-11-04-options-strings`.
- On Retail Krowi entered the world. On Mists the kit's `Send-GameInput.ps1` entered the world, typed `/reload` and quit the client (kit PR #9; Krowi accepted the risk under Blizzard's terms on 2026-11-05). This plan's "a script cannot make that click" no longer holds.
- The branch is not pushed or opened as a PR of its own. The KAF extraction session merges its final head into `feature/2026-11-04-normal-library` with `--no-ff` on Krowi's go, and PR #2 carries it.

## Proof
- `<kit>\tools\lua51\lua.exe docs\work\2026-11-05-review-fixes\repro\repro.lua` prints 14 PASS lines and `every check passes`.
- The plugin's syntax hook raises nothing.
- `Find-DeprecatedApi.ps1` lists nothing new.
- The taint reviewer and `/code-review` report nothing open.
- In game, Retail and Mists:
  - The requested `options` run passes, and `escape` passes on Retail. The only SKIP allowed is `toggle-reset-clipped`.
  - `greyed-help` and `greyed-help-collapsed` pass. They are the check that a greyed-out setting shows its help under the mouse, in the open pane and in the collapsed pane's tooltip.
  - The suite's `lua-errors` step passes. After the next logout, `Read-GameErrors.ps1` shows no new row.
- **In game, the result** (2026-11-05: Retail 12.1.5 at 13:21, Krowi on Frostmane; Mists 5.5.4 at 13:26, Krowi on Mirage Raceway):
  - Retail: `options` 95 passed, 0 failed, 2 skipped; `escape` 34 passed, 0 failed, 0 skipped.
  - Mists: `options` 95 passed, 0 failed, 2 skipped.
  - The two skips, on both clients:
    - `live-toggle-reset-clipped`, after its 30 s without a mouse.
    - `y-on-new-install`, which runs headless only. The proof above should have allowed it.
  - `live-greyed-help` and `live-greyed-help-collapsed`: 4 of 4 PASS on both clients (check box, dropdown, dropdown's arrow, tab list's Up arrow).
  - `window-second-tab`, `library-globals` and `live-lua-errors` pass on both.
  - `Read-GameErrors.ps1` shows no new row on Retail; the one KAF row there is the side-button error of 2026-11-04 14:13. Mists shows no KAF row.

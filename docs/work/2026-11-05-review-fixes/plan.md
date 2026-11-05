# Plan: the 2.0 code review's findings #1, #2 and #4 to #9
Spec: [spec.md](spec.md). Status: accepted

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
Tonight, from a KAF worktree of this session's own, not the KAF extraction session's. The steps:
- Start it from `feature/2026-11-04-options-strings` once that branch reads the window's name from `lib.WindowName` (the extraction session's change), so `/kaftest escape` and the `library-globals` step find the window.
- Point `Libs/Krowi_Options` at this branch's head.
- `Deploy.ps1 -WhatIf`, then deploy to Retail and Mists. That replaces the extraction session's build in the game, so tell it first.

## Departures
- The reproduction's #9 check now catches the name `build.Window` passes to `CreateFrame`, building the window on stand-in frames. It used to read a string literal in the source, and the name is now `lib.WindowName`. It still fails on `de2cb58`'s `Krowi_OptionsWindow`.
- The reproduction finds Krowi_Util from a worktree too.

## Proof
- `<kit>\tools\lua51\lua.exe docs\work\2026-11-05-review-fixes\repro\repro.lua` prints 14 PASS lines and `every check passes`.
- The plugin's syntax hook raises nothing.
- `Find-DeprecatedApi.ps1` lists nothing new.
- The taint reviewer and `/code-review` report nothing open.
- In game, Retail and Mists:
  - `/kaftest options` passes, and `/kaftest escape` passes on Retail.
  - A greyed-out setting shows its help under the mouse, in the open pane and in the collapsed pane's tooltip.
  - `Read-GameErrors.ps1` shows no new row.

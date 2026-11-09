# Plan: a button beside a dropdown
Spec: [spec.md](spec.md). Status: draft

## Context
KAF's Pop Out split (KAF docs/work/2026-11-09-pop-out, requirement 8c) shows the Pop Out modifier in two sections, each row with a button to the other. Krowi chose the button beside the dropdown: a narrow red button with », the same height as the row's other buttons. The library draws a second control only after a check box, so it grows first and releases as 2.1; KAF's PR merges after that release. Branch `feature/2026-11-09-select-with-button`, worktree `feature-2026-11-09-select-with-button`.

## Files that change
- `RowFrames.lua`: `row.Go` in `build.OptionRow` (`UIPanelButtonNoTooltipTemplate`, 32 x 22, text », hidden); minor 0 to 1.
- `RowMixins.lua`: the header contract (`:10`, `:28-33`); `OnLoad` (`Go`'s click, `Forward`); `Init` (`With` on a select, `Go` placed after the dropdown's right arrow, the hide list); `WithControl`; `Refresh` (`Go` greys by its own option); `OnEnter` (the help of `With` over `Go`); minor 0 to 1.
- `Tests/headless/suites/Bugs.lua`: `B31` and its helpers; `Tests/headless/suites/Structure.lua` and `ContractAndErrors.lua` where they record `OptionRow`'s names and the two-copy mixes (`row.Go` is a new field on the row, not a mixin name; checked).
- `Tests/Krowi_OptionsTests/Tests/Fixtures.lua`: a dropdown with a button on a fixture section (its button opens another section; a check box in the same section greys the dropdown, so the step proves the button stays enabled); `Steps.lua`: a live step `select-button`; the smoke list if it belongs there.
- `Krowi_Options.toc` `## Version: 2.1`, `_Packaging/Changelog.md` (a `## 2.1` entry for addon authors, its date on release day), `CLAUDE.md` (the versioning table's minors), this folder.

## Order of work
1. **Test first.** `B31` in `Bugs.lua`: an `OptionRow` initialised with a select option and an execute `With`; it reports what stands after the dropdown and what a click on it runs. `Recorded` "nothing beside the dropdown", `Target` "a button after the dropdown that runs the With; enabled while the dropdown is disabled". Headless green (it records today). Commit `test: a select option with a button beside it (B31)`.
2. **The change.** `RowFrames.lua` and `RowMixins.lua` as the spec's Design, minors raised; `B31`'s `Recorded` set to `Target`; B5a and B5b unchanged; `Structure` and `ContractAndErrors` updated only where they record the row's fields or the files' minors. The header contract and `CLAUDE.md`'s table. Headless green. Commit `feat: a dropdown row can carry a button beside it`.
3. **The test addon.** The fixture row and the live step `select-button`: the button stands 5 after the dropdown's right arrow inside the row, shows », runs its option (the section it opens is shown), its hover shows the `With`'s name in the help pane, it stays enabled while the dropdown is greyed. Commit.
4. **Feedback loop.** The kit's `Find-DeprecatedApi.ps1` on the two files; `krowi:taint-reviewer` on the diff; `/code-review`; fixes committed.
5. **In game** (after `Send-GameInput.ps1 -State`; input within 5 minutes means Krowi's go first; one client at a time): `Deploy-TestAddon.ps1 -WhatIf`, then deploy and `Run-GameTests.ps1 all` on Retail, Mists, Forever, Era and Anniversary (about 10 min each); a screenshot of the fixture row on Retail and Mists. Then KAF: its Pop Out worktree's submodule points at this branch, so KAF's look gate shows the two real rows.
6. **Look gate** (this item's): the fixture row and KAF's rows on a published page; the button's width is settled here.
7. **PR and release.** `Get-ChangeClass.ps1`, every work file `done`, push, PR against `main` with "Decisions taken without asking"; merge gate; then the two-copy gate (`Test-TwoCopies.ps1`, five clients, in the background, one client at a time) and `krowi:release` 2.1 on Krowi's go (`--stability alpha`). KAF's submodule then moves to the release in the Pop Out PR.

## Risks
- **Two copies:** an older `RowMixins.lua` with a newer `RowFrames.lua` leaves `row.Go` hidden and unused (fine); a newer `RowMixins.lua` with an older `RowFrames.lua` has no `row.Go`: `Init` draws the button only when the row has one, so it never errors. A `ContractAndErrors` mix case proves both.
- **Width:** 32 may be tight for » at the button's font on Classic; the look gate settles it.
- **Run length:** five clients for `/kotest all` and again for the two-copy gate.

## Proof
- Headless `run.lua` green with `B31` flipped.
- `/kotest all` green on Retail, Mists, Forever, Era and Anniversary; the two-copy gate on the five.
- Look gate on a published page with Retail and Mists screenshots, the fixture's and KAF's rows.

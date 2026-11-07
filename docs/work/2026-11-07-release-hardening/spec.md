# Spec: hardening before the 2.0 release
Intent: [intent.md](intent.md). Status: accepted

## Requirements
New live steps in `Tests/Krowi_OptionsTests/Tests/Steps.lua`, all in the `all` set, each with a banner and a screenshot like the others. Buttons are pressed through their own `OnClick` (`:Click()`), as the existing steps do.

1. **show-me**: on Window (its help has `ShowMe`), with the pane open, Show me shows and is enabled. With `CanShowMe` answering false a click leaves the window open and runs no `ShowMe`. With `ShowMe` answering false a click runs it once and the window is shown again on Window. With `ShowMe` answering nothing a click runs it once and the window stays closed (the step opens it again). With an option's help shown (the mouse over a row) or the pane collapsed, Show me is hidden.
2. **show-me-secure**: a fixture section whose help has `ShowMeSecure` gets, in the test addon, a stand-in made as KAF's map route makes its own (`Options/Window/Help/ShowMe.lua`): a `SecureActionButtonTemplate` button on `UIParent` with no action, placed by coordinates over the button it is handed, strata `DIALOG`. It records each call. The step checks:
   - drawn with the pane open: the library calls it with its Show me button and a close function, and the stand-in's rectangle matches Show me's within 1 px;
   - the window moved through its own drag end (`OnDragStop`): it is called again and the stand-in matches Show me at the new place;
   - with the window raised (`Raise`, what a click into it does), the real mouse over Show me reaches the stand-in (its `OnEnter`), not the library's button; served by the marker's hover like `toggle-reset-clipped`;
   - a real mouse click on Show me's place (the kit marker's `click` request, Krowi's choice, 2026-11-07) lands on the stand-in: its secure action runs (`type` `click` on a hidden counting button of the test addon, as KAF's map route clicks the minimap's button), counted once, and its `PostClick` close hides the window;
   - it is let go (called with nil) when another section is drawn, when an option's help shows, when the pane collapses and when the window hides;
   - answering false: Show me hides and the section's `ShowMeNote` shows instead;
   - an error in it: not in game, where a deliberate error would fail the run's `lua-errors` step (the test addon's name holds `Krowi_Options`); the headless `ContractAndErrors` 16j already proves that one that errors is let go later (found while briefing the build, 2026-11-07).
3. **combat**: the window's own handler is told combat starts (`OnEvent("PLAYER_REGEN_DISABLED")`, no real fight: a run cannot start one, and the runner stops in real combat): Show me greys with the "not in combat" note, the reload button and the key buttons grey; told it ends (`PLAYER_REGEN_ENABLED`): all three are enabled again and the note goes. A key capture in progress ends at the start.
4. **defaults**: on Debug, with two options changed there and one in Tooltips: Defaults is enabled and the footer counts 2. Defaults asks (Yes and Cancel shown, the question in the footer); Cancel changes nothing. Defaults, then Yes: `ResetSection` runs once for Debug, both values are back at their defaults and the rows show them, the footer counts 0 and Defaults greys, Tooltips' change stays. On a section where a reset option needs a reload, Yes lights the reload bar.
5. **execute**: Debug's "Reset everything" button runs its function once and, since it needs a reload, lights the reload bar; a button beside a row (Window's reset of a remembered position) runs its own function once and no other.
6. **all-none**: Events' Seasons: None turns all four off (saved, unchecked, the changed lines and the footer follow), All turns all four on.
7. **tab-arrows**: Tabs: the first row's Up and the last row's Down are greyed; Down on the first row moves it to second (the rows redraw in the new order, the fixture's order follows), Up moves it back.
8. The end of the run puts every value, the tab order, the window's place and the reload bar back, as today.
9. `/kotest all` passes with 0 failures on Retail, Mists, Forever, Era and Anniversary, and its `lua-errors` step finds none. On Era and Anniversary it now reads BugGrabber (installed 2026-11-07), which this proves.
10. The headless suites stay green (the new steps are game-only; frame-free parts, if any, get a headless scenario).
11. **Taint review**: one review of every shipped file (the `krowi:taint-reviewer`, Krowi's request of 2026-11-07). Each finding is fixed in this work item (with a headless scenario where it can be shown without frames, the file's minor stays 0 since nothing has shipped) or accepted by Krowi and listed in CLAUDE.md's known debt.

## Design
- **Fixture** (`Fixtures.lua`): Window's help keeps `ShowMe`/`CanShowMe`, now answering what the step sets (`fixtures.ShowMeAnswer`, `fixtures.CanShowMeAnswer`, defaults false and true as today) and counting runs. One section's help (Tooltips, or Other addons) gets `ShowMeSecure` and a `ShowMeNote`, served by a stand-in module in the test addon (its own file, or in `Steps.lua`): created once, `SecureActionButtonTemplate` with `type` `click` and a hidden plain button of the test addon as its `clickbutton` (it counts clicks and does nothing else), placed as KAF's `PlaceOver`, recording calls (`owner`, `close`, nil), with switches for "answer false" and "error".
- **The kit first**: the marker (`KrowiGameInput` and `Send-GameInput.ps1 -WaitForDone`) learns a `click` request beside `hover` and `key`, at a point of the window, left button, with the same guard as `-Click`. Its own kit work item and pull request (`docs/work/2026-11-07-marker-click` in the kit), merged before this item's in-game runs. `ResetSection` counts its calls per section. Out of the scenario path: the frame-free scenarios keep their recorded results (the `TestAddon` headless suite and the signatures in `Structure` must not move; if a fixture change moves a snapshot, the diff is read and kept only when it is the new help field).
- **Steps** (`Steps.lua`): seven steps as in Requirements, added to the step list after `keys` and before `resize`, and the header comment. The hover in `show-me-secure` uses the marker as `toggle-reset-clipped` does (30 s wait for the player's mouse without the marker). The `combat` step calls the window's `OnEvent` directly; it states in its line that it is the window's signal, not a fight.
- **Restore**: `restore` also puts back the tab order and the fixture's answers, and lets the stand-in go.
- **Review**: the taint reviewer reads `main` at 14f9e0b; findings go to Krowi as one question with what a player would see per finding.

## Options considered
- **Show me: the library's side, with a real hover (recommended).** The library's job is to call `ShowMeSecure` at the right moments with its button and to follow it; the secure click itself is the consumer's (KAF's map route, proven by KAF in game). A real hover proves the stand-in lies on top after a raise, the bug KAF met (`WowAddons.md`, a toplevel window lifts its children).
- **Also a real click on the stand-in.** Needs a `click` request in the kit's marker (`Send-GameInput.ps1` and `KrowiGameInput`), a kit work item of its own, and proves only that a hardware click reaches a button that a hover already shows is on top.
- **Combat: tell the window (recommended).** Its own handler, the same path the game's event takes; what it does not cover is `InCombatLockdown()` staying true during a real fight, which only matters for the key capture and Show me's click guards (both read it directly).
- **Combat: leave it out.** Nothing about combat proven in game.
- **Real clicks for every button.** The marker cannot click; `:Click()` runs the same `OnClick` a player's click runs.

## Areas of concern
- **Taint and secret values**: the test addon is never shipped (`_Packaging/.pkgmeta` ignores `Tests/`). The stand-in secure button's only action clicks a plain button of the test addon that counts, it is created out of combat, and is only shown, placed and hidden out of combat (the step refuses in combat, as the runner does); the real click runs that secure action from hardware, as KAF's map route does. Feeding `OnEvent` calls addon code only. The library itself: the taint review (requirement 11).
- **Clients**: the five that start; `SecureActionButtonTemplate`, `Raise`, `OnDragStop` exist on all six (checked in the 2026-11-07 clients review). Classic's Show me is the same button.
- **Blizzard API changes**: none used beyond what the steps already use.
- **Other addons**: none; the runs use `Deploy-TestAddon.ps1 -Consumers` so KAF's older embedded copy cannot win.
- **Saved variables**: the test addon's own `Krowi_OptionsTests` results; the window's saved place is put back by `restore`.
- **Localization**: none (test text is English, not shipped).
- **Embedded libraries**: none unless the review fixes library code (minors stay 0 before the first release).
- **Data snapshots**: the headless `Structure` snapshots must not move except for a reviewed fixture field.
- **Player-facing text**: none; no changelog line unless the review fixes library code.

## Verification
- Headless: `Tests\headless\run.lua` green.
- In game: `Deploy-TestAddon.ps1 -Consumers`, then `Run-GameTests.ps1 all -Client <c>` on Retail, Mists, Forever, Era, Anniversary, each 0 failures, `lua-errors` clean, screenshots of the new steps read; then KAF's own copy back with the kit's `Deploy.ps1` and the test addon moved out of every AddOns folder.
- Taint review: its report and how each finding was handled, in this folder (`review.md`).

## Decision
Krowi, 2026-11-07:
- Show me: "Also a real click" (not the recommended hover only). The kit's marker learns clicks first, in its own kit work item; then `show-me-secure` hovers and clicks for real.
- Combat: "Yes, tell the window (Recommended)".

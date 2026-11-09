# Spec: a button beside a dropdown
Intent: [intent.md](intent.md). Status: done

## Requirements
1. An `Option` element whose option is a `select` may carry `With`, an `execute` option. The row draws it as a button 5 after the dropdown's right arrow, vertically centred on the row (the dropdown ends 61.5 before the row's right edge, `RowMixins.lua:69` and `RowFrames.lua:170`).
2. The button is the game's red button the row already uses for a check box's button (`UIPanelButtonNoTooltipTemplate`, `RowFrames.lua:255-256`), the same height (22), narrow (32 wide, set at the look gate), and shows », the glyph of the help pane's "How it works" strip (`"\194\187"`, `WindowLayout.lua:135`) (Krowi, 2026-11-09). Every such button shows the same »; the option's `GetButtonText` is its name, not its face. The template and the glyph exist on every client the library is for (the row's text button uses the template on all six today).
3. A click runs the `With` (`with:Set()`) and then `window:OnOptionChanged(with)`, as the check box's button does (`RowMixins.lua:224-228`).
4. Under the mouse the button shows the `With`'s help (its `GetLabel` and its description, as any option's; the search names it by its label too, since the button shows », not its `GetButtonText`; the help opens at the control column, as the dropdown's does) in the help pane, or the hover help while the pane is collapsed, as a check box's slider does (`RowMixins.lua:603-605`); the dropdown keeps showing the row's own option.
5. The button greys out only by its own `IsDisabled()`, never with the dropdown (unlike a check box's `With`, which greys with its check box, `RowMixins.lua:547-555`), and it fires its hover while greyed out (`HoverWhileDisabled`).
6. The search finds the row by the button's name too (`kinds.Option.Names` already returns `With`'s button text, `Kinds.lua:78-82`); a hidden `With` draws nothing.
7. The row's changed line, its reset arrow and its reload icon stay the dropdown's (an execute has no value; `Changed` reads `With:IsChanged()`, which an execute answers false).
8. Unchanged: a `With` on a toggle (button or slider); a `With` on any other type is still ignored (Bugs B5a, B5b keep their Recorded).
9. The contract in `RowMixins.lua`'s header says it: "With on a toggle (an execute or range) or on a select (an execute, drawn as an icon button)". `Kinds.lua`'s header if it names the rule.
10. Two copies: every changed file's minor goes from 0 to 1; with an older copy of `RowMixins.lua` winning, a select's `With` is simply not drawn (as today); with the newer one winning, a newer `RowFrames.lua` must have built the button, so `Init` draws it only when the row has it (`self.Go`), never errors on a row an older builder made.

## Design
- `RowFrames.lua`, `build.OptionRow`: `row.Go = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")`, 32 x 22, its text », hidden. (The template's `$parentText` rewrites the global `Krowi_Options_2_WindowText` that every such button already rewrites, `CLAUDE.md`, No templates, no globals; no new global name, which the test addon's `library-globals-window` step checks.)
- `RowMixins.lua`:
  - `Init`: `self.With` takes a select's execute too; for it, `self.Go` is anchored `LEFT` to `self.Select.IncrementButton`'s `RIGHT` + 5 and shown. `WithControl` returns `self.Go` for it. The hide list at the top of `Init` takes `self.Go`.
  - `OnLoad`: `self.Go`'s `OnClick` runs `self.With`; `Forward(self.Go, self)`.
  - `OnEnter(control)`: on `self.Go` the help is the `With`'s, placed at the button's x.
  - `Refresh`: for a select's `With`, `self.Go:SetEnabled(not with:IsDisabled())`.
- `Kinds.lua`: no change unless the geometry needs a number both files read (the gap of 5 is local to `Init`).
- Minors: `RowFrames.lua` and `RowMixins.lua` 0 to 1 (and `Kinds.lua` if touched). `## Version:` and the changelog: 2.1.

## Options considered
1. **A narrow red button with » after the dropdown, its own control (`row.Go`), greying by itself (Krowi's answer, 2026-11-09).** The row keeps the dropdown's full width, the button sits in the room the row already leaves, and it matches the row's other buttons.
1b. **An icon button in the dropdown arrows' dark style with a forward-arrow atlas, an addon's own icon through `GetIcon`.** The first recommendation; Krowi chose the red button with » instead, which also needs no atlas per client.
2. **Reuse `row.Execute` (the 200 wide text button) beside the dropdown.** No new control, but 200 does not fit after a 250 dropdown; it would need a narrower dropdown, Krowi's rejected "B2".
3. **A new element kind for a link row.** The `Link` kind exists for lines that open something, but it is its own row, Krowi's rejected "A".

## Areas of concern
- **Taint and secret values.** A new addon-made button on the library's own row; no Blizzard frame is touched; `WowStyle2IconButtonMixin` is already mixed into the dropdown's arrows. No `GameTooltip`. Its text comes from the addon as plain strings (the contract). `krowi:taint-reviewer` on the diff.
- **Clients.** All six; the button reuses a template the row already uses on all of them; the in-game run on Retail, Mists, Forever, Era and Anniversary (Titan from source, as for 2.0).
- **Blizzard API changes.** None; `Find-DeprecatedApi.ps1` on the changed files.
- **Other addons.** KEVU and KAF embed the library; a row without the new `With` is unchanged.
- **Saved variables.** None.
- **Localization.** No new phrase in the library (the button's texts are the addon's).
- **Embedded libraries.** This is one: minors raised, two-copy gate on all five clients, release `2.1` through `krowi:release` on Krowi's go, `--stability alpha`.
- **Player-facing text.** The changelog for addon authors: a dropdown row can carry a button.

## Verification
- Headless: a `Bugs.lua` scenario `B31` "a select option with an execute With" (`Recorded` "nothing drawn beside the dropdown", `Target` "an icon button after the dropdown that runs the With"), first recorded as today, then flipped by the change; `Structure` (the names on `OptionRow`'s mixin, `lib.Internal`'s keys unchanged, the two-copy mixes); `ContractAndErrors` (a `With` the older rule ignores); the full `run.lua` green.
- The test addon: its fixture tab gets a dropdown with a button (`Fixtures.lua`), and a live step checks the button stands after the dropdown, runs its option, explains itself under the mouse and stays enabled while the dropdown is greyed; `/kotest all` on the five clients.
- The two-copy gate (`Test-TwoCopies.ps1`) on the five clients.
- Look gate: screenshots of the fixture's row on Retail and Mists, and of KAF's two rows through a KAF worktree pointing at this branch, on a published page.

## Decision
2026-11-09, Krowi: the intent as written; the design as option 1, the button "red button, same height as other buttons, just narrower with the how it works icon double arrow to the right". No `GetIcon` in the contract.

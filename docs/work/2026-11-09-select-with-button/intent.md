# Intent: a button beside a dropdown
Author: Krowi (maintainer). Source: Krowi_AchievementFilter's Pop Out split (KAF docs/work/2026-11-09-pop-out, spec requirement 8c), Krowi's pick "B1" of the mock page https://claude.ai/artifact/KwWbpdEMvN6giwEfsjW6Lq, 2026-11-09. Status: accepted

## Problem
KAF shows one setting in two sections (the Pop Out modifier key in Keys and clicks and in Pop Out's own section, as the game's Settings list a binding in more than one place). Next to the dropdown, each row gets a small button that opens the other section. An option row draws a second control only after a check box today (`RowMixins.lua:491-492`, the contract's "With only on a toggle", `RowMixins.lua:10`), so a button beside a dropdown cannot be drawn: on a select row a `With` is ignored.

## Proposed outcome
- A dropdown row may carry a small icon button right after the dropdown's right arrow, in the room the row leaves before its right edge, on every client the library is for.
- The button says what it does under the mouse, the same way the rest of the row explains itself (the help pane, or the hover help while the pane is collapsed), and the search finds it by its name.
- The button greys out only when its own option says so, not with the dropdown: KAF greys the dropdown while a feature is off and keeps the way to that feature's switch open.
- Nothing changes for a row without such a button, and nothing changes for a check box's button or slider.

## Affected users and systems
- Addon authors through the contract (`RowMixins.lua`'s header): the element kind `Option`'s `With` grows from "only on a toggle" to "on a toggle, or an execute on a select". The contract may grow without a new major name (`CLAUDE.md`, Consumers).
- KAF, the only consumer that needs it, through its submodule after the release.
- Players of every client the library is for (Retail, Mists, Anniversary, Forever, Era, Titan): a new button only where an addon asks for one.

## Constraints
- 2.0 is released: each changed file raises its LibStub minor (0 to 1); shared tables are added to, never replaced; no file keeps another file's functions (`CLAUDE.md`, Versioning).
- No templates and no new globals (`CLAUDE.md`, No templates, no globals).
- Taint: the button is the library's own frame; no `GameTooltip` (the hover help uses `Krowi_Tooltip`); its click runs the addon's option through the row as an execute row's does.
- Two copies: an older copy loaded first must not break on an element it does not know how to draw (it ignores a select's `With` today).

## Open questions
- Which icon the button shows, and whether an addon chooses it: answered at the design gate (spec, Decision).

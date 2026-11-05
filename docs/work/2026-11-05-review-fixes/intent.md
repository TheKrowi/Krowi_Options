# Intent: the 2.0 code review's findings #1, #2 and #4 to #9
Author: Krowi (maintainer), from Claude's code review of Krowi_Options 2.0 (2026-11-04/05). Source: code review. Status: accepted

## Problem
The code review of Krowi_Options 2.0 (branch `feature/2026-11-04-normal-library`, PR #2, unreleased) ranked nine findings as "fix before 2.0 ships". #3 (`WindowFrame.lua` keeping `RowFrames.lua`'s pieces from load) is already fixed in `de2cb58`. The other eight:

1. The search freezes the game when an option's `GetParent()` returns the option itself.
2. A tab keeps the methods of the copy of the library that made it, so a later 2.x cannot add or fix a tab method for a tab registered before it loaded (KAF registers at its own load).
4. A tab whose `Saved` gives no table makes a new named window frame and an error on every open, and breaks the shared window state (place, size, pane) for every other tab.
5. A section whose `GetElements` gives nil errors with the window half switched, and a section that errors is saved as the last section, so the next open lands on it again.
6. The option interface in `RowMixins.lua`'s header leaves out `IsHidden` and `With.Id`, which the window calls; an addon that follows it errors on its first section.
7. One option whose code errors in a refresh stops every row after it, the changed count and the reload bar, and can leave the window believing combat is starting.
8. A greyed-out control shows no help under the mouse, so the player cannot read why a setting is greyed.
9. The window's global name, `Krowi_OptionsWindow`, is Krowi_Options 1's as well.

Players see #1 (a frozen game), #7 (a page that stops updating) and #8 (no help on a greyed setting). The others are mistakes an addon author makes, which today surface late, cryptically or repeatedly. The next consumer, Krowi_ExtendedVendorUI, will write a new config against this API.

## Proposed outcome
The search always ends. A newer 2.x reaches every tab. A bad config fails once, at the addon's own `CreateWindow` line or at the first open, with an error that names the tab and the field, and never leaves extra frames or a broken window behind. One option's error stays in its own row. Every greyed-out setting explains itself under the mouse, as in the game's own Options window. The window's name is 2.0's own.

## Affected users and systems
- Clients: Retail 12.1.5, Mists Classic 5.5.4, Titan Reforged 3.80 (the TOC's three).
- The window: the search, the page, the rows' hover help and the help pane, the shared window state in each tab's saved table.
- Consumers: Krowi_AchievementFilter, the only one. Its tests read the window by name (`Tests/Escape.lua`, `Tests/Options.lua`, `.claude/tools/headless/run-tests.lua`), on its branch `feature/2026-11-04-options-strings`, owned by another session.
- No saved variables of the library's own; the shared keys in each tab's table keep their shape.

## Constraints
- No taint: no Blizzard frame or global touched, `SettingsFrameTemplate` stays the only settings template.
- 2.0 is unreleased: every file's minor stays 0, the API stays `Krowi_Options_2`.
- Nothing KAF passes today may be refused.
- Krowi asked for these eight now; everything else of the review waits in [backlog.md](backlog.md) for a second go.

## Open questions
- How strict the library is with a bad config: refuse it at `CreateWindow`, or only survive it at run time (spec, options).
- Where the fixes merge: into the 2.0 branch before its release, or into `main` after PR #2.

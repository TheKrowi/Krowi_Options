# Intent: 2.0's contract written down, its errors contained, and the shared window state in sync
Author: Krowi (maintainer). Source: the whole-library review Krowi asked for before the 2.0 release (2026-11-05). Status: done (accepted by Krowi, 2026-11-05)

## Problem
2.0 is the first release other addons will embed. Once Krowi_AchievementFilter 105.0 ships it, old installs run whatever newer copy another addon brings, so the config, the element and option interfaces, the saved keys and the names can only grow from then on; changing them needs `Krowi_Options_3`. A review of the whole library at `48d0803`, by three reviewers (a fork of the release session, a fresh reviewer on another model that read no earlier findings, and `krowi:taint-reviewer`), found:

- **Parts of the contract exist only in code:** the element kinds and their fields, the help's `ShowMeSecure` and `CanShowMe`, what a consumer answers for `"overview"`, that a `Saved` function's table is kept, how often `GetElements` runs, when the window may be opened, the key row's binding writes, and that texts must not be secret values.
- **The shared window state drifts between addons.** Place, size, help pane and the two search ticks are written into every loaded addon's table on each change, and read on the window's first open from the addon it is opened through. With one addon disabled for a while and enabled again, the window opens in a different place depending on which addon opens it, and each setting catches up only when it is changed again (Krowi: "who's settings win?").
- **Errors that leave a broken window**, none hit by Krowi_AchievementFilter today:
  - a saved place or size of the wrong shape makes every later open build another window;
  - one tab's `OnCreated` error skips the other tabs and their Escape registration;
  - a tab-list row without `Show` has a live check box that errors on click;
  - a recycled row in the middle of a key capture refreshes its previous option;
  - an option's `GetLabel` or `IsHidden` error blanks the page and leaves it stuck mid-fill;
  - a standalone install, which CurseForge and Wago offer, errors in every file when no Krowi addon loaded before it.

## Proposed outcome
- An addon author learns the whole contract from the library's own headers.
- The window opens where the player last left it, in whichever addon they last changed it, from every addon, and the addons' copies are in sync again from the first open (Krowi, 2026-11-05: newest change wins).
- A consumer's mistake or bad data shows as one error with its stack. It no longer leaves a broken or duplicated window or skips other addons' tabs.
- A standalone install does nothing, without errors.
- Players of Krowi_AchievementFilter see no difference.

## Affected users and systems
- **The library:** `Krowi_Options.lua`, `WindowMixin.lua`, `RowMixins.lua`, `Search.lua`, the locale files (the standalone guard), `CLAUDE.md`, `_Packaging/Changelog.md` (2.0 entry, for addon authors).
- **Krowi_AchievementFilter:**
  - `Options/Window/Window.lua`'s comment on the saved keys;
  - `Tests/Options.lua`, which reads and restores the saved keys and gets the `library-globals` step moved after the window opens;
  - `Libs/Krowi_Options` pointing at the result.
- **Saved variables:** `KrowiAF_SavedData.OptionsWindow` gets `Window = { ... }` in place of five top-level keys. No released KAF has the options window (104.0, 2026-10-24, predates it).
- **Clients:** Retail 12.1.5, Mists 5.5.4, Titan Reforged 3.80.2 (no local install).

## Constraints
- No new taint: no Blizzard frame, global or function touched.
- Every minor stays 0 while 2.0 is unreleased (as for the review fixes).
- No change a player of Krowi_AchievementFilter sees.
- Display-only bugs and cleanups wait for 2.1 (Krowi, 2026-11-05).
- The release waits for the two-copy gate (Krowi_ClaudeKit `docs/work/2026-11-05-two-copy-gate`), run on the result of this work.

## Open questions
None: Krowi chose the scope ("contract and error fixes") and newest-wins on 2026-11-05.

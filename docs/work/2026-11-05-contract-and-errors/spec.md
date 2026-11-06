# Spec: 2.0's contract written down, its errors contained, and the shared window state in sync
Intent: [intent.md](intent.md). Status: done (accepted by Krowi, 2026-11-05)

Line numbers are at `48d0803`.

## Requirements
**Contract (headers and CLAUDE.md, no behaviour change)**
1. `Krowi_Options.lua`'s config header lists every field the window calls and the ids it calls them with:
   - `"overview"` reaches `GetElements`, `GetHelp`, `OnSectionShown` and `SectionName`, and `Landing` may return it;
   - `IsNew`, `ResetSection` and `ChangedCount` never get it.
   - `GetHelp`'s full shape: `Title`; `Blocks` of `{Heading}`, `{Text}`, `{Term, Text}` or `{Picture, Width, Height, TexCoords}`; `ShowMe()`, which may return false; `ShowMeSecure(button, close)`; `CanShowMe()`; and `ShowMeNote`, a string or a function.
2. One header names every element kind and its fields:
   - `Header`, `SubHeading` and `Note` take `{Text}`;
   - `Option` takes `{Option, With}`, where `With` belongs on a toggle only;
   - `Sub` takes `{Text, Members}`;
   - `Grid` takes `{Columns, Rows = {{Label, Cells}}}`;
   - `TabList` takes `{Items = {{Position, Show, Source, MoveUp, MoveDown}}}`;
   - `Link` takes `{Text, Detail, OnClick}`;
   - `Cards` takes `{Cards = {{Name, Text, IsNew, OnClick, Picture, Width, Height, TexCoords, Part | Icon}}}`.

   A kind the window does not know draws nothing.
3. The saved table's keys are named:
   - `Window`, the shared state (requirement 9), and `LastSection` are the library's; every other key is the addon's;
   - a `Saved` function is asked until it returns a table, and that table is kept for the session.
4. When and how often: `GetElements` runs on every change, and while searching, for every section of every searched tab on each keystroke, so it builds cheaply and has no side effects. The window is opened after `PLAYER_LOGIN`: frames built before a newer copy of the library loads keep the older copy's code, so a load-on-demand consumer gets the window as it was built.
5. The public surface is named:
   - `lib.CreateWindow`;
   - the tab's `Open`, `Toggle`, `IsShown`, `Refresh`, `GetFrame` and `GetSaved` (`Unregister` is for tests);
   - `lib.GetStrings`, `lib.Markup` and `lib.WindowName`;
   - `OnCreated(frame)`, with `frame.Lightbox`.

   Everything else on `lib` and on the frame is internal and may change in any version.
6. A key option's `Set` runs inside the key row. A consumer whose `Set` writes bindings (`SetBinding`, `SaveBindings`) fires `UPDATE_BINDINGS` from addon code, which runs Blizzard's binding displays tainted for the session (accepted, Krowi_AchievementFilter #197). This goes in the option interface's header and in CLAUDE.md's taint-sensitive list.
7. Every text a consumer hands the window is a plain string, never a secret value (option interface header and config header).
8. CLAUDE.md's "only global" line names the `$parent` globals Blizzard's templates add, once Krowi_AchievementFilter's `library-globals` step has listed them with the window built (requirement 16).

**The shared window state**
9. The five shared settings live in one block, `saved.Window = { Point, Size, PaneCollapsed, SearchAll, SearchBroad, Changed }`, where `Changed` is the `time()` of the last change.
10. When the window is built, it takes the block with the newest `Changed` among the registered tabs' saved tables, and copies it into every one of them. A block without `Changed` counts as the oldest; no block gives the defaults.
11. Each change (move, resize, pane, either search tick) writes the whole block with a new `Changed` into every tab that has a saved table.
12. A value of the wrong type or shape in the block is ignored and its default used; it never stops the window from opening.

**Errors**
13. One tab's `OnCreated` error goes to the game's error handler, and every other tab's `OnCreated` and the tab strip still run. A tab registering after the window exists stays registered and is returned even when its `OnCreated` errors. An `OnCreated` that registers another tab neither skips a tab nor calls one twice.
14. A tab-list row without `Show` hides its check box.
15. A row reused while it captures a key never refreshes the option it showed before.
16. A consumer's error while the page is filled goes to the error handler, and the window stays usable: an error in `GetElements`, an option's `IsHidden` or `GetLabel`, `OnSectionShown` or `GetHelp` while a section opens, a page is refilled after a change, or a search runs. The page shows what it could get (nothing for a failed section) and is not left mid-fill. In a search, a section that errors is left out.
17. A standalone install with no `KROWI_LIBMAN` loads nothing and raises no error.

**Krowi_AchievementFilter (its own branch, test code and one comment)**
18. Its `options` suite reads and restores `OptionsWindow.Window`. `library-globals` runs after a step has built the window. `window-second-tab` checks that both tabs hold the same block after a change.

## Root cause
- **The contract (1-8):**
  - The config header (`Krowi_Options.lua:45-62`) documents `GetHelp` without `ShowMeSecure` and `CanShowMe`, which the window reads (`WindowMixin.lua:329-330`, `:1042-1065`). It says "see RowMixins.lua" for the elements, but the option interface header there (`RowMixins.lua:8-25`) does not list the kinds. Those live in `rowKinds` (`WindowMixin.lua:121-133`), `lib.Flatten` (`Search.lua:20-50`) and the card comment (`RowMixins.lua:594-595`).
  - The header says the saved table holds "the sections seen in", which is Krowi_AchievementFilter's own `Seen` (`Options/Window/Window.lua:9-17`).
  - Nothing tells an author that the frame's fields are internal, though Krowi_AchievementFilter's tests read many of them.
  - The key row's taint and the secret-value rule are in no header (taint review 2026-11-05, findings 1 and 3).
- **The shared state (9-12):**
  - `lib.SetShared` (`Krowi_Options.lua:222-227`) writes one key into every loaded tab's table, only when that key changes.
  - `GetFrame` (`:205-210`) builds the window from the opening tab's table alone, and `Init` (`WindowMixin.lua:348-361`) reads it.
  - So the tables of two addons agree only while both stay loaded, and the window's first open in a session takes whichever addon it is opened through.
  - `Init` indexes `saved.Size[2]` and `saved.Point[1..4]` without a type check. A wrong shape errors after the frame is made under the window's name, and before `lib.Frame` is set (`Krowi_Options.lua:208-210`), so every later open builds another window.
- **Errors (13-17):**
  - **#13:** `GetFrame`'s loop (`Krowi_Options.lua:211-213`) and `CreateWindow` (`:155-159`) call `OnCreated` bare. `CreateWindow` adds the tab before its `OnCreated` can raise.
  - **#14:** `TabRowMixin:Refresh` (`RowMixins.lua:540-546`) updates the check box only when `Show` is there. Otherwise it keeps a pooled row's last state, or a new row's working default, and its click indexes nil (`:508-511`). Krowi_AchievementFilter passes `Show = nil` when a slot has no tab or no option (`Options/Window/Source.lua:446-452`).
  - **#15:** `OptionRowMixin:Init` (`RowMixins.lua:218`) calls `EndKeyCapture` before it replaces `self.Option`, and `EndKeyCapture` (`:370`) refreshes the old option.
  - **#16:**
    - `ShowSection` (`WindowMixin.lua:731-748`) sets `Filling` (`:740`) and only `EndFill` (`:746`) clears it.
    - `FillPage` (`:761-766`) and `OnOptionChanged` (`:837-838`) call `GetElements`, then `Flatten` (`IsHidden`, `Search.lua:44`) and `Signature` (`GetLabel`, `WindowMixin.lua:756`), all unguarded. The search does the same per section (`Search.lua:137-243`, `:255-266`).
    - `OnSectionShown` (`:737`) and `GetHelp` (`:1004`) are unguarded too.
    - Only a row's `Refresh` is guarded (`:782-787`), from the review fixes.
  - **#17:** each Lua file's first statement is `KROWI_LIBMAN:...` (`Krowi_Options.lua:19`, `Search.lua:15`, `RowMixins.lua:27`, `RowFrames.lua:14`, `WindowMixin.lua:13`, `WindowFrame.lua:11`, `Localization\*.lua:8`), and the TOC declares no dependency.

## Design
- **The contract:**
  - The config header in `Krowi_Options.lua` is rewritten for 1, 3, 4, 5 and 7, and its "see RowMixins.lua" points at a new elements header there.
  - `RowMixins.lua`'s header gains the element kinds (2) above the option interface, plus the key row's binding writes (6) and plain strings (7).
  - CLAUDE.md: the Consumers part names the public surface, the taint list gets the key row, and the globals line is corrected (8).
- **The shared state:**
  - `Krowi_Options.lua` gets `local function ReadWindow(saved)`. It returns `saved.Window` with each field checked: `Point` a table of two strings and two numbers, `Size` a table with a number at `[2]`, the three flags booleans or nil, `Changed` a number. Fields of the wrong shape are dropped (12).
  - `GetFrame`:
    1. ask every tab's `FindSaved`;
    2. take the newest block;
    3. build the window;
    4. set `lib.Frame` right after it is built, so it is never built twice;
    5. `frame:Init(block)`;
    6. write the block into every saved table (10).
  - `lib.SetShared(key, value)` keeps its name. It sets the field on the window's block, stamps `Changed = time()`, and writes a copy of the block into every tab that has a saved table (11). Each table gets its own copy, so a later read cannot alias another addon's.
  - `WindowMixin:Init(window)` reads the checked block, no longer `saved` itself.
  - `LastSection` stays at the saved table's top level, per addon.
  - The old top-level keys of the 2.0 test builds are not read or removed. No player has them.
- **Errors:**
  - A local `Protected(func, ...)` in `WindowMixin.lua` and `Krowi_Options.lua` runs `xpcall(function() return func(...) end, CallErrorHandler)` and returns success and result. It is a closure, as in `RefreshRow`, because plain Lua 5.1's `xpcall` passes no arguments. It is used:
    - for `OnCreated`, over a copy of `lib.Tabs` in `GetFrame`, and in `CreateWindow` after the tab is added, which still returns it (13);
    - in `ShowSection` around `OnSectionShown`;
    - in `FillPage` and `OnOptionChanged` around `GetElements` + `Flatten` + `Signature`, where a failure gives an empty page or, after a change, a plain `Refresh`;
    - in `ShowSectionHelp` around `GetHelp`;
    - in `lib.Search` around each `SearchSection` (16).
  - `ShowSection` saves `LastSection` only when the page filled.
  - `TabRowMixin:Refresh` shows the check box only when `Show` is there (14).
  - `OptionRowMixin:Init` clears `self.Option` before `EndKeyCapture` (15).
  - Every Lua file gets `if not KROWI_LIBMAN then return end` before its registration (17), and CLAUDE.md's file-start rule says so.
- **Krowi_AchievementFilter:**
  - `Tests/Options.lua`: the saved-window reads (`:1369`, `:1777-1790`, `:2000`) go through `.Window`, and `library-globals` moves to a step after `open`.
  - The `window-second-tab` observation adds `block=same` or `block=differs`.
  - `Options/Window/Window.lua:9-10`'s comment names `Window` and `LastSection`.
  - All on a Krowi_AchievementFilter worktree branch, whose `Libs/Krowi_Options` points at this branch while testing.
- **Changelog** (2.0 entry, for addon authors): the shared window state and its newest-wins rule; an `OnCreated` or a section that errors no longer breaks the window or other tabs; a standalone install stays silent.

## Options considered
1. **Recommended: contain each consumer call at the boundary where the window calls it** (above). Every error is reported with its stack, and the window goes on with what it has.
2. **Validate elements and options up front**, as `CheckConfig` does for the config. This catches a missing method early, but an element list is built anew on each call, and checking it every time costs more than the guard. It also cannot catch a method that errors at run time.
3. **For 17, `## Dependencies: Krowi_Util` in the TOC.** A standalone install would never load without a standalone Krowi_Util, which players rarely have, while the in-game two-copy test needs the standalone copy to load after a consumer. Not chosen.
4. **For 12, reset the whole block when one field is bad.** Simpler, but it loses a good place over a bad size. Not chosen.

## Areas of concern
- **Taint and secret values:** none new. `xpcall` with `CallErrorHandler` is the pattern the review fixes brought in and the taint reviewer approved. No Blizzard frame, global or function changes.
- **Clients:** `time()` and `CallErrorHandler` exist on Retail, Mists and Titan (`CallErrorHandler`: taint review 2026-11-05). `Find-DeprecatedApi.ps1` on all three clones. Titan has no local install.
- **Blizzard API changes:** none used.
- **Other addons, plugins and skins:** none read the saved keys or the window's internals, as far as known.
- **Saved variables:** `OptionsWindow` changes shape. No released KAF has it, so there is nothing to migrate. Krowi's test profiles lose the window's place and size once, and their old top-level keys stay unread.
- **Localization:** none. The errors are for addon authors, in English.
- **Embedded libraries:** this is the library. Every minor stays 0 (2.0 unreleased). Krowi_AchievementFilter's pointer moves after the release.
- **Data snapshots:** none in this repo. Krowi_AchievementFilter's option fingerprints do not change, since no option changes.
- **Player-facing text:** none in game. The changelog is for authors.

## Verification
- **Test first:** `repro/repro.lua` in this work folder, on the vendored Lua 5.1 with Krowi_Util's real LibStub, LibMan and AceLocale, as the review fixes' repro does. Before the fix it must fail:
  - 9-12: the newest block wins, is copied to every tab and written whole on a change; a bad shape is ignored and builds one window only;
  - 13: two tabs, the first `OnCreated` errors;
  - 14: a tab row without `Show`;
  - 15: a reused row mid capture;
  - 16: `GetElements`, `IsHidden`, `GetLabel`, `OnSectionShown` and `GetHelp` erroring, in a section and in a search;
  - 17: the files with no `KROWI_LIBMAN`.

  After the fix it must print `every check passes`. The review fixes' repro must still pass.
- **Checks:** the plugin's syntax hook; `Find-DeprecatedApi.ps1` for live, classic and classic_titan; Krowi_AchievementFilter's lint and all its headless suites; `krowi:taint-reviewer` and `/code-review` on the diff.
- **In game,** through Krowi_AchievementFilter's branch with `Libs/Krowi_Options` at this branch, run with `Run-GameTests.ps1`:
  - Retail `options` and `escape`, Mists `options`, all green;
  - `library-globals` listing what it finds with the window built, so requirement 8 records it;
  - BugGrabber clean.
- **Before the release:** the two-copy gate (Krowi_ClaudeKit `docs/work/2026-11-05-two-copy-gate`) on the merged result.

## Decision
- Scope: the contract and the fixes for everything that ends in a Lua error or a broken window. Display-only bugs and cleanups wait for 2.1 (Krowi, 2026-11-05).
- The shared window state: newest change wins, in one block `saved.Window` with a change time (Krowi, 2026-11-05).
- Option 1, contain each consumer call where the window calls it (Krowi, 2026-11-05).
- The 2.1 list, from the whole-library review:
  - the undo arrow and a paired control's reload;
  - a question on the overview;
  - a slider without a step, or with min equal to max;
  - stale element data under an unchanged signature;
  - `With` on a non-toggle;
  - a search ended by closing the window;
  - Retail's named colour codes in the search;
  - a closure per row refresh;
  - the leftovers of 1.0's per-tab strings;
  - a window left shown after its last tab unregisters.

  It goes to the backlog in [plan.md](plan.md) at the end of this work.

# Backlog: the rest of the 2.0 code review
For the second go, after the eight findings of [spec.md](spec.md). Each item is labelled by how it was found: **R** reproduced in Lua 5.1, **C** read in the code, **G** needs the game. Line numbers are at `de2cb58`.

## Done in `de2cb58` (the extraction session's own review)
- The hover help follows a change on a grid's check box and a tab's (`RowShows`). It is drawn again only when the option turns changed or back, not on every step of a slider's drag.
- A `%` in a translation of the three texts with a placeholder no longer breaks `string.format` (`Formattable`).
- `StringsFor` and its fallbacks are gone.
- CLAUDE.md now has the rule "no file keeps another file's functions" and lists, as known debt, that the first-loaded copy's English and the last-loaded copy's translations win.

## Bad values and widgets
1. A slider without a step only reaches its two ends (0 to 1 gives only 0 and 1), and min = max divides by zero (`RowMixins.lua:186`). R. KAF is not affected.
2. A tab-list row without `Show` keeps the previous row's working check box, and clicking it errors (`RowMixins.lua:494-498`, `:525-531`). C.
3. A saved value of the wrong type passed to a slider or an edit box (`RowMixins.lua:198`, `:303`). G.
4. A select whose value is no longer one of its choices shows blank (`RowMixins.lua:230-243`). C.
5. Text typed in an input box is lost when the box loses focus; only Enter saves it (`RowMixins.lua:150-158`). C. Maybe by design.
6. The undo arrow resets `With` too, but passes only `Option` to `OnOptionChanged`, so a `With` that needs a reload does not light the reload bar (`RowMixins.lua:126-130`). C.
7. One tab's `OnCreated` error skips the tabs after it (`Krowi_Options.lua:167-169`, and `:116`). C. The fix is the `xpcall` of [spec.md](spec.md) #7.
8. A saved size or place of the wrong shape stops the window from opening (`WindowMixin.lua:349-355`). C.
9. A help picture without a size. A question asked on the Overview, where Defaults (its Yes) is hidden, cannot be answered (`WindowMixin.lua:737`, `:873-882`). C.

### From `/code-review` of the fixes (2026-11-05)
27. A section whose `GetElements` errors leaves the window in its filling state until another section opens. `Filling` stays true, so the navigation's scroll bar no longer re-lays the page. `OnSectionShown` has already run (KAF marks the section as seen), and `SectionId` points at the broken section (`WindowMixin.lua`, `ShowSection`). C. This existed before the fixes; they only stopped the section from being saved as the last one.
28. An option whose `GetLabel` errors stops the whole page, because the page signature reads every label before the rows are made (`WindowMixin.lua`, `Signature` in `FillPage` and `OnOptionChanged`). C. A row's own `Init` error is already contained: Blizzard runs the list's initializers through `secureexecuterange` (`ScrollBoxListView.lua:421`).
30. **A smaller config contract** (raised by the KAF extraction session, 2026-11-05):
    - With `CreateWindow`'s check, a minimal consumer such as Krowi_ExtendedVendorUI must pass no-op functions for `IsNew`, `Landing`, `OnSectionShown`, `GetHelp`, `ResetSection` and `ChangedCount`. KAF's `window-second-tab` scenario had to add them.
    - Defaults would keep only `TabName`, `Saved`, `Groups`, `SectionName` and `GetElements` required: not new, the Overview, nothing, no help, nothing, and 0.
    - That needs a guard or a default at each call site, and API wording in `Krowi_Options.lua`'s config comment.
    - Krowi's call.
29. `tab:GetSaved()`'s error is raised at level 2, the library's own caller (`GetFrame` or `ShowTab`), not the addon's line. The message names the tab, and BugSack's stack shows the addon. C. Minor.

## Hover
10. Cards and the navigation's buttons still use the plain `IsMouseOver` that `2f95232` replaced for option rows (`WindowMixin.lua:48`, `CardMixin:Init` in `RowMixins.lua`). G.
31. A greyed-out slider bar or input box may not explain itself under the mouse. Only buttons have `SetMotionScriptsWhileDisabled`, which #8 set, and whether a disabled Slider or EditBox fires `OnEnter` shows only under a real mouse. KAF's `greyed-help` steps cover the buttons. G.

## Future versions next to 2.0
11. A file deleted or renamed in a later version comes back from an older copy. C. Needs a rule (keep a stub) and a kit check (below).
12. A window already built keeps the older code when a newer copy loads later. Only a load-on-demand consumer can cause it, and there is none. C.
13. `lib.Markup` is replaced on each load, while KAF builds it into its help at load (`Krowi_Options.lua:35-39`). C.
14. A changed file without a raised minor gives nil strings. R. The release preflight already blocks it.

## Needs the game
15. Blizzard templates with `$parent` names probably add globals beside the window's: `<WindowName>Text`, `…SearchIcon` and `…ClearButton`, and on Classic `…TitleBg`. CLAUDE.md says the window's name is the only global. KAF's `library-globals` step (`/kaftest options library-globals`) would list them.
16. The link row's highlight is made with `CreateTexture()` before `SetHighlightTexture`, so it may show as a permanent faint wash (`RowFrames.lua:350-354`).
17. The atlases were not checked against game data: wow.tools.local was not running.
18. The tab row's `Interface\Buttons\Arrow-*` textures on Retail (`RowFrames.lua:297-304`).

## Cleanups
19. The row heights in the builders are dead: `InitList` sets the row on its host with `SetAllPoints` (`WindowMixin.lua:166`).
20. The branch at `WindowMixin.lua:157` cannot be reached.
21. The `SetMinResize`/`SetMaxResize` fallback is dead: all three clients have `SetResizeBounds` (`WindowMixin.lua:384-387`).
22. No minimum Krowi_Util version is stated; `Krowi_Tooltip` needs 2.5 or later.

## Recommendations
23. **Tests of the library's own.** Grow [repro/repro.lua](repro/repro.lua) into a headless suite in this repo: two copies, bad configs, the search. KAF's `options` suite cannot catch these: its stand-in for the game takes any call, it never draws rows, it does not run Titan, it passes only valid configs, and it loads one copy. This is Krowi's call on scope.
24. **CLAUDE.md rules:**
    - never delete or rename a registered file (keep a stub)
    - never change the shape of a shared saved key
    - the key row taints `UPDATE_BINDINGS` (accepted, KAF #197)
    - the minimum Krowi_Util version
25. **Kit:** the release preflight could fail when a registration name from the last tag has disappeared.
26. **Clients:** this review covered the TOC's three. Krowi_ExtendedVendorUI brings Era, Anniversary and Forever, so review those clients when it adopts the library.

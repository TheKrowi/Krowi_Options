# Spec: the 2.0 code review's findings #1, #2 and #4 to #9
Intent: [intent.md](intent.md). Status: done

Line numbers are at `de2cb58`, the head of `feature/2026-11-04-normal-library` this branch starts from.

## Requirements
1. The search ends for every config: an option whose `GetParent()` returns itself, or a row below it, hangs under nothing.
2. A tab registered by an older copy gets every tab method a newer copy of `Krowi_Options.lua` defines.
3. (#3 is fixed in `de2cb58`; [repro/repro.lua](repro/repro.lua) keeps checking it.)
4. Bad configs:
   1. `CreateWindow` refuses a config whose fields the window calls are missing or of the wrong type. The error is raised at the caller's line, names the tab and the field, and the tab is not added.
   2. A tab whose `Saved` gives no table (a function called before the saved variables load) raises an error naming the tab on open, before any frame is made. It is asked again on the next open, not cached.
   3. `SetShared` writes the shared state to every tab that has a saved table, also when another tab has none.
5. Sections:
   1. A section whose `GetElements` gives nil shows an empty page.
   2. A section whose `GetElements` errors is not saved as the last section.
6. The option interface in `RowMixins.lua`'s header lists every method and field the window calls, `IsHidden` among them. `With.Id` is optional, as `Option.Id` is.
7. Refresh isolation:
   1. A row whose `Refresh` errors sends the error to the game's error handler. The other rows, the changed count and the reload bar still refresh.
   2. The combat flag `CombatStarting` holds only for the refresh of the event that set it, also when that refresh errors.
8. Every control that passes the mouse to its row does so while greyed out too: the option row's controls, a grid's check boxes, a tab row's check box and arrows. The help pane, or the tooltip while the pane is collapsed, then shows the option.
9. The window's global name is `Krowi_Options_2_Window`, published as `lib.WindowName` so a consumer can read it before the window exists.

## Root cause
Each finding is reproduced by [repro/repro.lua](repro/repro.lua) (vendored Lua 5.1), which loads the real files on Krowi_Util's real LibStub, AceLocale and LibMan. Run before any fix, on 2026-11-05:

```
FAIL  #1 the search ends on an option that is its own parent: no end after 2,000,000 instructions
FAIL  #2 a tab an older copy made has a newer copy's tab methods: the older copy's tab lacks the newer method
PASS  #3 the window's builders use a newer copy's RowFrames.lua (fixed in de2cb58): the newer Finish ran
FAIL  #4a a tab whose Saved gives no table: no window is built, the error names the tab: 2 window(s) built over two opens; [string "WindowMixin.lua"]:349: attempt to index local 'saved' (a function value)
FAIL  #4b a tab without a saved table leaves the other tabs' shared state saved: [string "Krowi_Options.lua"]:179: attempt to index a function value
FAIL  #4c a config without GetElements is refused at CreateWindow, naming the field: accepted
FAIL  #5a a section whose GetElements gives nil shows an empty page: [string "Search.lua"]:22: bad argument #1 to 'ipairs' (table expected, got nil)
FAIL  #5b a section whose GetElements errors is not saved as the last section: LastSection = broken
FAIL  #6a the option interface in RowMixins.lua's header names IsHidden: not named
FAIL  #6b a With without Id draws: [string "WindowMixin.lua"]:751: attempt to concatenate field 'Id' (a nil value)
FAIL  #7a one row's error leaves the other rows and the footer refreshed, and reaches the error handler: second row not refreshed, footer not refreshed, 0 error(s) to the handler; ...: the first row's error
FAIL  #7b the combat flag clears when the refresh errors: CombatStarting = true
FAIL  #8 a greyed-out control still passes the mouse to its row: not on Toggle, Range.Back, Range.Forward, Select.Dropdown, Select.DecrementButton, Select.IncrementButton, Execute, Key1, Key2, grid cell, tab ShowCheck, tab Up, tab Down
FAIL  #9 the window's global name is not Krowi_Options 1's: name = Krowi_OptionsWindow
13 check(s) fail
```

The mechanisms:
- **#1** `Search.lua:155` records the option's row (`rowOf[option] = i`) before `:157` looks its parent up. A self-parent therefore gets `parentAt[i] = i`, and `Take`'s walk up the parents (`:188-191`, `i = parentAt[i]`) never ends. Every other parent link points to an earlier row, so only a self-loop is possible.
- **#2** `Krowi_Options.lua:59-60` makes the tabs' metatable a local of the copy that loads (`local tab = {}`). A newer copy defines its methods on a table of its own, which the tabs an older copy made never see. Reproduced with a newer copy that adds `tab:Probe()`. The scratch version, where `SetShared` called a new method, errors at `:181`.
- **#4**
  - `Krowi_Options.lua:65` is `self.Saved = type(saved) == "function" and saved() or saved`. When the function returns nil, the `or` hands back the function itself, which is then cached for the session.
  - `GetFrame` (`:164-166`) builds the window, then `Init` (`WindowMixin.lua:349`) indexes the function and errors before `lib.Frame` is set. The next open builds and names another frame.
  - `SetShared` (`:177-181`) indexes every tab's saved table, so that one tab's error stops the write for all tabs. That write runs on move, resize and the pane button.
  - `CreateWindow` (`:111-120`) checks nothing.
- **#5**
  - `ShowSection` (`WindowMixin.lua:733`) saves `LastSection` before `FillPage` (`:740`).
  - `FillPage` (`:758`) and `OnOptionChanged` (`:825`) hand `GetElements`' result to `Flatten`, whose `ipairs` errors on nil (`Search.lua:22`).
  - KAF's `Landing()` returns the saved last section when the section still exists (`Options/Window/Window.lua:48-53`; an unknown id falls back to the Overview there). So a section whose `GetElements` errors is opened again on every open, and a consumer without that check is caught the same way by an unknown id.
- **#6**
  - The header (`RowMixins.lua:8-12`) omits `IsHidden`, which `Search.lua:44` and `:73`, `RowMixins.lua:207` and `WindowMixin.lua:751` call.
  - The page signature (`WindowMixin.lua:751`) concatenates `element.With.Id`, while `option.Id` on the same line has `or ""`.
- **#7**
  - `Refresh` (`WindowMixin.lua:774-782`) calls each row's `Refresh` in a plain loop, so the first error ends it before `RefreshFooter` and `UpdateShowMe`.
  - `OnEvent` (`:673-676`) clears `CombatStarting` only after `Refresh` returns. If the window is closed during that combat, the flag stays set until the next combat event while the window is shown. Until then, key buttons and Reload stay greyed as in combat.
- **#8**
  - Rows pass the mouse to the help through each control's `OnEnter` (`RowMixins.lua:104-107` `Forward`, `:453`, `:507-510`).
  - A disabled `Button` fires no `OnEnter` unless `SetMotionScriptsWhileDisabled(true)`, and it still takes the mouse from its row.
  - Blizzard sets it on its settings check box (`Blizzard_SettingControls.xml:80`, `SettingsCheckboxTemplate motionScriptsWhileDisabled="true"`) and on its slider steppers (`SharedUIPanelTemplates.xml:1418`, `:1433`).
  - Our `build.CheckButton` (`RowFrames.lua:69-77`) and the other controls never set it.
- **#9** `WindowFrame.lua:99` names the frame `Krowi_OptionsWindow`, as Krowi_Options 1 did. An old KAF (1.x) next to a 2.x consumer gives two frames under one global, and the `$parent` names of their templates collide.

## Design
- **#1** In `SearchSection`, record `rowOf[option] = i` after the parent lookup. Every parent is then a row above, and the walk ends.
- **#2** Keep the tabs' metatable on the library: `lib.Mixins.Tab = lib.Mixins.Tab or {}`, and `local tab = lib.Mixins.Tab`. A newer copy's `function tab:X()` then replaces the method on the table that every tab's metatable points to. 2.0 is the first release, so no copy without this exists.
- **#4**
  - A local `FindSaved(tab)` calls `config.Saved` when it is a function and caches the result only when it is a table, otherwise returning nil.
  - `tab:GetSaved()` returns it, or raises `Krowi_Options: tab "<TabName>": config.Saved gave no table`.
  - `GetFrame` asks the opening tab's saved table before `lib.Build.Window()`. `ShowTab` asks it before it changes any state.
  - `SetShared` skips a tab without one.
  - `CreateWindow` checks the config (`CheckConfig`):
    - Must be functions: `SectionName`, `IsNew`, `Landing`, `OnSectionShown`, `GetElements`, `GetHelp`, `ResetSection`, `ChangedCount`.
    - `TabName` a string; `Saved` a table or function; `Groups` a table of tables with a `Sections` table; `OnCreated` a function when given.
    - The error is raised at level 3, the consumer's call, before the tab is added.
- **#5** `lib.Flatten` (`Search.lua`) takes nil as no elements, which covers every caller: `FillPage`, `OnOptionChanged` and the search. `ShowSection` saves `LastSection` after `FillPage`.
- **#6**
  - Rewrite the header's interface, so an author knows which methods and fields are needed.
  - Every option: `GetLabel`, `IsHidden`, `IsDisabled`, `Get`, `Set`, `IsChanged`, `Reset`, `GetNeedsReload`, `Type`.
  - Per type: `GetRange` and an optional `Format` (range), `GetValues`, `Placeholder` and `Confirm` (select), `GetButtonText` (execute), `Slots` (key).
  - Optional: `GetDescription`, `GetDefault` with `FormatValue`, `GetParent`, `Indent`, `Id`.
  - With: an execute or range option with the same interface.
  - The signature reads `(element.With.Id or "")`.
- **#7**
  - `Refresh` runs each row through a local `RefreshRow(frame)`, which calls `row:Refresh()` in `xpcall(..., CallErrorHandler)`. BugGrabber, or the game's error frame at the right stack level, gets the error, and the loop goes on. `CallErrorHandler` is Blizzard's own (`Blizzard_SharedXMLBase/ErrorUtil.lua`, the same on live, classic and classic_titan), as Blizzard's xpcalls use it (the taint reviewer's advice).
  - `OnEvent` runs `EndKeyCaptures` and `Refresh` each in its own `xpcall`, then clears the flag. A key row's error while its capture ends then still lets the page refresh into combat.
  - A closure per call: the game's `xpcall` passes arguments (`FunctionUtil.lua:4`), but plain Lua 5.1's, which the headless tests run on, does not.
- **#8**
  - `build.CheckButton` calls `SetMotionScriptsWhileDisabled(true)`, as `SettingsCheckboxTemplate` does. This covers the toggle, the grid's cells, the tab row's check box and the window's two search check boxes.
  - `Forward`, and the tab row's loop for its arrows, call it on each control that has the method. Buttons, the dropdown button and the steppers have it. The slider bar and the edit box have no such setting (`SimpleButtonAPIDocumentation.lua` alone lists it), so whether they fire their hover while greyed out is checked in game.
  - Blizzard's `WowStyle2IconButtonMixin` reads `IsEnabled()` for its art (`MenuTemplates.lua:1166-1186`), so a disabled arrow under the mouse keeps its disabled look.
- **#9**
  - `Krowi_Options.lua` sets `lib.WindowName = "Krowi_Options_2_Window"`, and `build.Window` reads it at the call.
  - KAF's extraction session switches its four uses of the name, plus `.luarc.json:132`, to `lib.WindowName` on its own branch (agreed in session, 2026-11-05).
  - CLAUDE.md's "only global" line names it.
- **Changelog** (`_Packaging/Changelog.md`, the unreleased 2.0 entry, for addon authors): the window's name and `lib.WindowName`; `CreateWindow` checking the config; a greyed-out setting showing its help; the search freeze; a section without elements; one option's error.

## Options considered
1. **Recommended: refuse a bad config at `CreateWindow` and survive bad data at run time** (the design above). An author's mistake shows once, at login, at their own line, naming the field. Their tab then does not appear until it is fixed. Players of KAF see no difference: its config passes.
2. **Survive at run time only, no check at `CreateWindow`.** A missing field shows when the window or a section opens, as an error inside the library (`attempt to call field 'GetHelp' (a nil value)`). The tab is added and works up to that point. This is less strict and needs no list of fields to keep up to date, but the author learns later and less clearly.
3. **For #9, keep `Krowi_OptionsWindow`.** No KAF change. The clash with 1.x stays, and renaming after 2.0 ships would break any addon that reads the name. Not chosen, since Krowi asked for #9.
4. **For #6, document `With.Id` as required instead of making it optional.** The doc would then match the code without a code change, but `With` would ask for more than `Option`. Not chosen.

## Areas of concern
- **Taint and secret values:** no Blizzard frame, global or function is touched or hooked. `SetMotionScriptsWhileDisabled` is set on frames the library creates, some of them made from Blizzard templates (the slider's steppers, `WowStyle2DropdownTemplate`'s button). `xpcall` with `geterrorhandler()` is plain addon code. Run `krowi:taint-reviewer` on the diff.
- **Clients:** `SetMotionScriptsWhileDisabled` is in `SimpleButtonAPIDocumentation.lua` on live, classic (Mists) and classic_titan. Titan Reforged has no local install, so it is not checked in game there. `Find-DeprecatedApi.ps1` finds no use of a removed or deprecated global on any of the seven clones.
- **Blizzard API changes:** none used beyond the above.
- **Other addons, plugins and skins:** a skin that finds the window by `Krowi_OptionsWindow` would lose it. None is known, and 2.0 is unreleased.
- **Saved variables:** no shape changes. `LastSection` is written after the page fills; the shared keys are written as before.
- **Localization:** none. The new errors are for addon authors, in English, as Lua errors are.
- **Embedded libraries:** this is the library. Every file's minor stays 0 while 2.0 is unreleased. If Krowi merges this into `main` after 2.0 instead, each changed file's minor goes to 1.
- **Data snapshots:** none in this repo.
- **Player-facing text:** none in game. The changelog is for addon authors.

## Verification
- **Test:** [repro/repro.lua](repro/repro.lua) is the reproduction and the check. It must print `every check passes`. It stays in the work folder as the start of the library-owned suite in [backlog.md](backlog.md).
- **Checks:** the plugin's Lua 5.1 syntax hook on every edit, `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer` on the diff, and `/code-review`.
- **In game:** after the KAF session's pending Retail run and on Krowi's go. Use a KAF checkout whose `Libs/Krowi_Options` points at this branch, with KAF's `lib.WindowName` change in place. It runs unattended (Krowi, 2026-11-05: "devise the test so it can run without my supervision"): KAF's `Request-GameTests.ps1` starts the client, Krowi only enters the world.
  - `options` on Retail and Mists, `escape` on Retail.
  - #8 is two steps of the `options` suite, `greyed-help` and `greyed-help-collapsed`. A greyed check box, dropdown, dropdown arrow and tab arrow must ask for their hover while greyed (`GetMotionScriptsWhileDisabled`), which before the fix none of them did. Their own `OnEnter`, played by the step, must make the open pane or the collapsed pane's tooltip explain the option. That the game then fires the hover is the flag's documented effect, which Blizzard's own settings check box relies on.
  - A greyed slider bar and input box have no such flag, and only a hand on the mouse can show whether they fire their hover. That is backlog item 31, not this fix.
  - The suite's `lua-errors` step reports the session's errors of KAF and its `Libs/` from BugGrabber.

## Decision
- Option 1, refuse a bad config at `CreateWindow` and survive bad data at run time (Krowi, 2026-11-05).
- The fixes merge into `feature/2026-11-04-normal-library`, so PR #2 and the 2.0 release carry them, and every minor stays 0 (Krowi, 2026-11-05). The KAF extraction session recommended the same.
- #9's name is published as `lib.WindowName` (the KAF extraction session's request, 2026-11-05). KAF switches its uses of the name to it on its own branch.

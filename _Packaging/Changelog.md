# Changelog
All notable changes to this project will be documented in this file.

## 2.0 - 2026-11-04
### Changed
- Registers as `Krowi_Options_2` (was `Krowi_Options_1`), since the points below change the API
- The window's texts are the library's own, translated in the game's languages on its CurseForge project; a tab's config no longer takes `Strings`
- Two addons can embed different versions: the frames are built in Lua instead of XML templates, the mixins are on the library (`lib.Internal.Mixins`) instead of globals, and every file carries its own version, so the newest copy of each file is the one in use
- Search descriptions shows on every tab
- The window's frame is named `Krowi_Options_2_Window` (was `Krowi_OptionsWindow`), also as `lib.WindowName`
- Lists Era, Anniversary and WoW Forever beside Retail, Mists and Titan Reforged; the library is tested in game on the first five
- `CreateWindow` refuses a config with a missing required or a wrong field, and the error names it
- `CreateWindow` needs only `TabName`, `Saved`, `Groups`, `SectionName` and `GetElements`; the other fields have defaults (`ResetSection` and `ChangedCount` come as a pair), and a key the window does not know is an error that names it
- The window's place, size, help pane and search ticks are kept in each addon's `saved.Window` with the time of the change, and the window opens from the newest, so the addons agree again after one of them was off for a while
- The headers of `Krowi_Options.lua` and `RowMixins.lua` describe the whole API: the config, the element kinds, the option interface and what is public
- A text box saves what is typed when it loses focus, as Enter does; Escape puts the saved text back
- A dropdown whose saved value is no longer one of its choices shows its default and saves it
- `With` only goes with a toggle: beside a slider or a button it is ignored
- A tab-list row without `Show` can name itself with `Name`
- A tab without a saved table errors at the addon's own `Open` or `Toggle` line
- Dropdowns no longer rebuild their menu on every refresh, and the rows allocate less when the page refreshes

### Fixed
- An addon's error in `OnCreated`, `OnSectionShown`, `GetElements`, an option's label or hidden check, or `GetHelp` goes to the error handler and no longer breaks the window, the search or the other addons' tabs
- A saved place or size of the wrong shape no longer opens a second window
- A tab-list row without `Show` no longer shows a check box that errors
- A row reused during a key capture no longer refreshes the option it showed before
- A standalone install no longer errors when no Krowi addon loads before it
- The undo arrow no longer stays on a row the mouse left through its part scrolled out of the list
- The hover help follows a change made under the mouse: Reset to Default comes and goes at once
- A greyed-out setting shows its help under the mouse
- The search no longer freezes the game on an option that is its own parent
- A section without elements shows an empty page instead of an error
- An option that errors no longer stops the other rows and the changed count from updating
- The undo arrow lights the reload bar when the control next to it needs a reload
- A question asked on the Overview can be answered
- A slider without a step reaches every value, and a slider whose ends are the same no longer errors
- A saved value of the wrong type no longer reaches a slider or a text box
- A page shows a link's detail, a tab's position and a card's text again after they change
- Closing the window during a search no longer opens the section again on the hidden window
- The search no longer finds colour names, hyperlink data or hidden codes
- A section whose `GetElements` errors no longer becomes the open section
- A window left open after its last tab went away closes

## 1.0 - 2026-11-04
### Added
- An options window with sections, settings and a help pane, as a library of its own, from Krowi's Achievement Filter (alpha)
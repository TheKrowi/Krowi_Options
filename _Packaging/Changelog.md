# Changelog
All notable changes to this project will be documented in this file.

## 2.0 - 2026-11-04
### Changed
- Registers as `Krowi_Options_2` (was `Krowi_Options_1`), since the points below change the API
- The window's texts are the library's own, translated in the game's languages on its CurseForge project; a tab's config no longer takes `Strings`
- Two addons can embed different versions: the frames are built in Lua instead of XML templates, the mixins are on `lib.Mixins` instead of globals, and every file carries its own version, so the newest copy of each file is the one in use
- Search descriptions shows on every tab
- The window's frame is named `Krowi_Options_2_Window` (was `Krowi_OptionsWindow`), also as `lib.WindowName`
- `CreateWindow` refuses a config with a missing or wrong field, and the error names it

### Fixed
- The undo arrow no longer stays on a row the mouse left through its part scrolled out of the list
- The hover help follows a change made under the mouse: Reset to Default comes and goes at once
- A greyed-out setting shows its help under the mouse
- The search no longer freezes the game on an option that is its own parent
- A section without elements shows an empty page instead of an error
- An option that errors no longer stops the other rows and the changed count from updating

## 1.0 - 2026-11-04
### Added
- An options window with sections, settings and a help pane, as a library of its own, from Krowi's Achievement Filter (alpha)
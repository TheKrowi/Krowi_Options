# Changelog
All notable changes to this project will be documented in this file.

## 2.0 - 2026-11-04
### Changed
- Registers as `Krowi_Options_2` (was `Krowi_Options_1`), since the points below change the API
- The window's texts are the library's own, translated in the game's languages on its CurseForge project; a tab's config no longer takes `Strings`
- Two addons can embed different versions: the frames are built in Lua instead of XML templates, the mixins are on `lib.Mixins` instead of globals, and every file carries its own version, so the newest copy of each file is the one in use
- Search descriptions shows on every tab

### Fixed
- The undo arrow no longer stays on a row the mouse left through its part scrolled out of the list
- The hover help follows a change made under the mouse: Reset to Default comes and goes at once

## 1.0 - 2026-11-04
### Added
- An options window with sections, settings and a help pane, as a library of its own, from Krowi's Achievement Filter (alpha)
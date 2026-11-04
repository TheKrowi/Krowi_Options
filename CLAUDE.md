# CLAUDE.md

Krowi_Options (`Krowi_Options_1`) is a World of Warcraft library in Lua 5.1 and XML: an options window with sections, settings and a help pane that explains each setting, in the look of the game's own Options window, which several addons share with a tab each. The workspace-wide rules (tooling traps, the game loop, taint, LibStub minors, git, release safety) load from `../../CLAUDE.md` and `Krowi_ClaudeKit/WowAddons.md`; this file adds only what is specific to this repo.

## Where the code is edited

Until the extraction work item (after Krowi_AchievementFilter 106), the library is edited in `Krowi_AchievementFilter/Krowi_Options/`, its design history (the `docs/work/...` paths in the comments) lives there too, and this repo holds a copy for the alpha uploads (Krowi, 2026-11-04). **Never edit the library files here.** Before a release, copy the files over from Krowi_AchievementFilter's `main` and check that they match byte for byte:

| Krowi_AchievementFilter `Krowi_Options/` | This repo |
|---|---|
| `Krowi_Options.lua`, `RowMixins.lua`, `Search.lua`, `WindowMixin.lua`, `Rows.xml`, `Window.xml` | same names |
| `Files.xml` | `Krowi_Options.xml` |

Known limits, from the two-addon spike of 2026-11-04 (Retail only), which the extraction has to solve:
- A second loaded copy (a standalone install next to Krowi_AchievementFilter, or two addons embedding it) warns that the XML virtual templates in `Rows.xml` and `Window.xml` already exist; the window has to be built in Lua.
- Only `Krowi_Options.lua` is version-guarded; the other files and their global mixins come from whichever copy loads last.

## Clients and loading

- `Krowi_Options.toc` loads `Krowi_Options.xml`, which loads `Krowi_Options.lua`, `Search.lua`, `Rows.xml` (`RowMixins.lua` first) and `Window.xml` (`WindowMixin.lua` first). No saved variables: each addon passes its own table (`config.Saved`).
- `## Interface: 120105, 50504, 38002`: the clients Krowi_AchievementFilter loads on (Retail 12.1.5, Mists Classic 5.5.4, Titan Reforged 3.80). It only matters for a standalone install, the README badges and the upload's game versions.
- It needs `KROWI_LIBMAN` (Krowi_Util) loaded first, and no other library.
- Strings: none of its own yet; each addon passes them in its config (`Strings`, see `WindowMixin.lua`). They move to this project's CurseForge localization (1783244) later.

## Versioning

- `Krowi_Options.lua:16` registers `KROWI_LIBMAN:NewLibrary('Krowi_Options_1', 4)`; the other files `GetLibrary` it and register nothing. The minor is bumped in Krowi_AchievementFilter, where the code is edited.
- `## Version:` in the TOC is the release version and must match the top changelog entry; it is unrelated to the minor. `1.x` follows the `_1` in the name; a breaking API change needs `Krowi_Options_2`.

## Git and release

- `main` is the only branch and the release branch. Branch from `main` and open PRs against it.
- Release only with `krowi:release`, from the main checkout `Krowi_Libraries\Krowi_Options` (it is in the addon manager's `LIBRARY_NAMES`). Uploads are `--stability alpha` until Krowi says otherwise; CurseForge reviews the project on its first upload.
- No in-game test gate: test through Krowi_AchievementFilter (`/kaftest options` on Retail and Mists Classic) before the dry run. Do not deploy this repo on its own (see Known limits).
- The changelog is for addon authors. `README.md` (the TOC's client badges plus `_Packaging/Description.md`) and `_Packaging/ReleaseNotes.md` are generated at release.
- Host projects: CurseForge 1783244, Wago `aN0a7A6j`, slug `krowi-options` on both.
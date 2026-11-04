# CLAUDE.md

Krowi_Options (`Krowi_Options_2`) is a World of Warcraft library in Lua 5.1: an options window with sections, settings and a help pane that explains each setting, in the look of the game's own Options window, which several addons share with a tab each. The workspace-wide rules (tooling traps, the game loop, taint, LibStub minors, git, release safety) load from `../../CLAUDE.md` and `Krowi_ClaudeKit/WowAddons.md`; this file adds only what is specific to this repo.

It was made inside Krowi_AchievementFilter (`Krowi_Options/`, 1.0 was a copy of it), whose `docs/work/` holds its design history (2026-10-25-options-revamp onwards). Since 2.0 it is edited here only, and KAF embeds it as the submodule `Libs/Krowi_Options` (docs/work/2026-11-04-krowi-options-library).

There is no build, lint or test step here: a consumer addon in the game is the test harness, and KAF's headless `options` suite loads the library from its `Libs/`. The `krowi` plugin (`.claude/settings.json`) syntax-checks every edited `.lua` with Lua 5.1 and guards the known tooling traps.

## Clients and loading

- `Krowi_Options.toc` loads `Krowi_Options.xml`: `Krowi_Options.lua`, `Localization\Files.xml`, `Search.lua`, `RowMixins.lua`, `RowFrames.lua`, `WindowMixin.lua`, `WindowFrame.lua`. No saved variables: each addon passes its own table (`config.Saved`).
- `## Interface: 120105, 50504, 38002`: the clients KAF loads on (Retail 12.1.5, Mists Classic 5.5.4, Titan Reforged 3.80). It only matters for a standalone install, the README badges and the upload's game versions.
- It needs `KROWI_LIBMAN` and AceLocale (both from Krowi_Util) loaded first. KAF includes `Krowi_Options\Krowi_Options.xml` in its `Libs/Files.xml` after Krowi_Util.

## No templates, no globals

A second embedded copy must load without a warning and must not mix its code with the first (the two-addon spike, 2026-11-04). So:
- **No XML templates.** `RowFrames.lua` and `WindowFrame.lua` build every frame in Lua, region by region, as `Rows.xml` and `Window.xml` declared them up to 1.0, and run `OnLoad` last. Blizzard's own templates are still inherited through `CreateFrame`, except where their `OnLoad` needs what XML gives before it: the dropdown with arrows (`DropdownWithSteppersTemplate` and its `WowStyle2IconButtonTemplate` arrows) is put together from the same pieces with Blizzard's mixins (`build.Select`).
- **Rows hang on the lists' frames.** A list pools its frames by frame type alone when there is no template, so `InitList` (`WindowMixin.lua`) hands the view a plain frame and hangs the element kind's row on it as `frame.Row`, from a pool per kind. Code that walks a list's frames (`ForEachFrame`, KAF's tests) reads `frame.Row`.
- **Mixins on the library.** `lib.Mixins.<Name>`, applied by the builders. The only global is the window's frame name, `Krowi_OptionsWindow`.

## Versioning

Each Lua file registers its own LibStub entry through LibMan, and LibStub keeps the highest minor of each entry separately. Bump the minor of every file you change, in that file:

| File | LibStub entry | Registration | Minor |
|---|---|---|---|
| `Krowi_Options.lua` | `Krowi_Options_2` | `KROWI_LIBMAN:NewLibrary('Krowi_Options_2', 0, {...})` | 0 |
| `Search.lua` | `Krowi_Options_2_SearchModule` | `KROWI_LIBMAN:NewSubmodule("SearchModule", 0)`; not `"Search"`, because LibMan sets `lib[name]` and `lib.Search` is the search function | 0 |
| `RowMixins.lua` | `Krowi_Options_2_RowMixins` | `KROWI_LIBMAN:NewSubmodule("RowMixins", 0)` | 0 |
| `RowFrames.lua` | `Krowi_Options_2_RowFrames` | `KROWI_LIBMAN:NewSubmodule("RowFrames", 0)` | 0 |
| `WindowMixin.lua` | `Krowi_Options_2_WindowMixin` | `KROWI_LIBMAN:NewSubmodule("WindowMixin", 0)` | 0 |
| `WindowFrame.lua` | `Krowi_Options_2_WindowFrame` | `KROWI_LIBMAN:NewSubmodule("WindowFrame", 0)` | 0 |

- **No file keeps another file's functions.** A file looks up what another file defines (`lib.Build.Finish`, `lib.Mixins.OptionRow`, `lib.Flatten`) when it calls it, never copies it into a local at load: a newer copy of that other file replaces it on `lib`, also when this file stays the older copy's. `WindowFrame.lua`'s `Text`, `Color`, `Finish` and `Row` forward to `lib.Build` for that reason.
- The locale files register nothing: every copy adds its phrases (`NewDefaultLocale(true)`, `NewLocale(lang, true)`), so a newer copy's code finds the phrases it added. Where two copies have the same phrase, AceLocale keeps the first-loaded copy's English and the last-loaded copy's translation, whichever copy is newer (known debt below).
- `## Version:` in the TOC is the release version and must match the top changelog entry; it is unrelated to the minors. A breaking API change needs a new major name (`Krowi_Options_3`), as 2.0 did for `Krowi_Options_1`.

## Consumers

| Consumer | Pinned | Uses |
|---|---|---|
| Krowi_AchievementFilter | 2.0 (from 105.0) | `CreateWindow` with every config field (`Options/Window/Window.lua`), `Markup` (`Options/Window/Help/Help.lua`), and in its `options` suite `Search`, `RowGeometry`, `RowX`, `CardColumns`, `CardWidth`, `CardCrop`, `WindowWidth`, `Tabs` and the window's frames. |

## Taint-sensitive areas

Run the `krowi:taint-reviewer` agent after changing any of these:
- The window inherits `SettingsFrameTemplate`, the only one of Blizzard's settings templates it may: the others run Blizzard's Settings code, which taints the game's own Options window. KAF's `options-templates` lint rule checks `Libs/Krowi_Options/`.
- `build.Select` mixes Blizzard's `DropdownWithSteppersMixin` and `WowStyle2IconButtonMixin` into addon frames, and the rows use `MinimalSliderWithSteppersTemplate`, `WowStyle2DropdownTemplate`, `InputBoxTemplate` and `UIPanelButtonNoTooltipTemplate`.
- The hover help in the collapsed pane uses `Krowi_Tooltip` (Krowi_Util's), never `GameTooltip`.
- Escape: the consumer registers the window and its lightbox for closing (KAF in `OnCreated`).

## Localization

- `Localization\<lang>.lua`, CurseForge project 1783244 (https://legacy.curseforge.com/wow/addons/krowi-options/localization). Sync from this checkout with `krowi:localization`; the window's strings are built in `lib.GetStrings` (`Krowi_Options.lua`) under English keys.
- The 22 phrases and their translations came from KAF's project and Krowi_Util's "Requires a reload" (2.0).

## Code style

- Match the file you are editing: 4 spaces; double quotes in Lua except the `NewLibrary` call.
- No semicolons. Each Lua file starts with the copyright block, a blank line, `---@diagnostic disable: undefined-global`, a blank line, then its registration and `if not lib then return end` (or `if not sub`).
- CRLF on disk (LF in git, `core.autocrlf=true`), no BOM, no final newline.

## Testing in game

Test through KAF. Do not deploy this repo on its own, except for the two-copy test below.
1. Bump the minors of the files you changed; at equal minors the first-loaded copy wins and the test proves nothing.
2. In a KAF worktree, point the submodule at the change: `git -C Libs\Krowi_Options fetch "E:\World of Warcraft Addon Development\Krowi_Libraries\Krowi_Options" <branch>`, then `git -C Libs\Krowi_Options checkout FETCH_HEAD`. Deploy that worktree and `/reload`. Commit the new pointer only after this library is released.
3. `/kaftest options` (or `/kaftest options <step or start of names>` for part of it) on Retail and Mists Classic, `/kaftest escape` on Retail.

**Two copies:** deploy this checkout as its own `AddOns\Krowi_Options` folder next to KAF. It loads after KAF, so it finds KAF's `KROWI_LIBMAN` and AceLocale. With equal minors nothing of it may run; with every minor raised, every file of it runs. BugGrabber must show no warning either way. Remove the folder after.

## Git and release

- `main` is the only branch and the release branch. Branch from `main` and open PRs against it.
- Release only with `krowi:release`, from the main checkout `Krowi_Libraries\Krowi_Options` (it is in the addon manager's `LIBRARY_NAMES`). Uploads are `--stability alpha` until Krowi says otherwise.
- The changelog is for addon authors. `README.md` (the TOC's client badges plus `_Packaging/Description.md`) and `_Packaging/ReleaseNotes.md` are generated at release.
- Host projects: CurseForge 1783244, Wago `aN0a7A6j`, slug `krowi-options` on both.

## Known debt (from the two-addon spike, 2026-11-04)

- Escape is the consumer's job: an addon that registers nothing (as KEVU's spike did) leaves the window open on Escape.
- A tab without help gets an empty help pane for every section that has none, the Overview included.
- Defaults shows, greyed, on sections without settings.
- The window follows changes made in it, not changes made elsewhere (the game's Settings page) while it is open.
- **A phrase two copies share is not the newest copy's** (the code review of 2.0, 2026-11-04): AceLocale keeps the first-loaded copy's English and the last-loaded copy's translation, and the locale files have no version guard. A corrected text in a newer copy shows only when that copy loads first (English) or last (other languages). Making the newest copy's text win needs a version-aware write in Krowi_Util's `LocalizationHelper`, for every Krowi library at once.
- **"Requires a reload" is translated twice**, here and in Krowi_Util (`K_AddReloadRequired`), on two CurseForge projects. The window takes all its texts from its own project by design (2.0); a correction made on one project is copied to the other by hand.
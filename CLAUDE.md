# CLAUDE.md

Krowi_Options (`Krowi_Options_2`) is a World of Warcraft library in Lua 5.1: an options window with sections, settings and a help pane that explains each setting, in the look of the game's own Options window, which several addons share with a tab each. The workspace-wide rules (tooling traps, the game loop, taint, LibStub minors, git, release safety) load from `../../CLAUDE.md` and `Krowi_ClaudeKit/WowAddons.md`; this file adds only what is specific to this repo.

It was made inside Krowi_AchievementFilter (`Krowi_Options/`, 1.0 was a copy of it), whose `docs/work/` holds its design history (2026-10-25-options-revamp onwards). Since 2.0 it is edited here only, and KAF embeds it as the submodule `Libs/Krowi_Options` (docs/work/2026-11-04-krowi-options-library).

There is no build or lint step here. The library tests itself (since 2026-11-06; Krowi: "Kaf should test what it can see. Krowi options should cover the internals"): a headless suite in `Tests/headless` and a test addon, `Tests/Krowi_OptionsTests`, that hosts the library in game without any consumer (Testing below). Krowi_AchievementFilter's own `options` suite tests only what KAF can see, through the library's public surface. The `krowi` plugin (`.claude/settings.json`) syntax-checks every edited `.lua` with Lua 5.1 and guards the known tooling traps. `_Packaging/.pkgmeta` keeps `Tests/` out of the deploy and the release zip, also inside the addons that embed the library.

## Clients and loading

- `Krowi_Options.toc` loads `Krowi_Options.xml`, which loads, in this order:
  1. `Krowi_Options.lua`: the tabs, the config check, the shared window state, `lib.Internal`;
  2. `Localization\Files.xml`;
  3. `Kinds.lua`: the element kinds (`lib.Internal.Kinds`), the numbers files share (`lib.Internal.Geometry`), `Flatten` and the lists' pooling (`InitList`);
  4. `Search.lua`;
  5. `RowMixins.lua`, then `RowFrames.lua`: the page's rows, their mixins and builders;
  6. `WindowMixin.lua`, the window's core (`OnLoad`, `Init`, tabs, strings, show, hide, events), then its parts, each adding its methods to the same mixin: `WindowHelp.lua` (the help pane, Show me, the hover), `WindowSearch.lua`, `WindowPage.lua` (the navigation, the page, its header and questions), `WindowLayout.lua` (width, layout, inner frame, collapse, resize, drag);
  7. `WindowFrame.lua`: the window and the navigation's and help pane's rows.

  No saved variables: each addon passes its own table (`config.Saved`).
- `## Interface: 120105, 50504, 38002`: the clients KAF loads on (Retail 12.1.5, Mists Classic 5.5.4, Titan Reforged 3.80). It only matters for a standalone install, the README badges and the upload's game versions.
- It needs `KROWI_LIBMAN` and AceLocale (both from Krowi_Util) loaded first. KAF includes `Krowi_Options\Krowi_Options.xml` in its `Libs/Files.xml` after Krowi_Util.

## No templates, no globals

A second embedded copy must load without a warning and must not mix its code with the first (the two-addon spike, 2026-11-04). So:
- **No XML templates.** `RowFrames.lua` and `WindowFrame.lua` build every frame in Lua, region by region, as `Rows.xml` and `Window.xml` declared them up to 1.0, and run `OnLoad` last. Blizzard's own templates are still inherited through `CreateFrame`, except where their `OnLoad` needs what XML gives before it: the dropdown with arrows (`DropdownWithSteppersTemplate` and its `WowStyle2IconButtonTemplate` arrows) is put together from the same pieces with Blizzard's mixins (`build.Select`).
- **Rows hang on the lists' frames.** A list pools its frames by frame type alone when there is no template, so `InitList` (`Kinds.lua`) hands the view a plain frame and hangs the element kind's row on it as `frame.Row`, from a pool per kind, set to all of that frame. A row has no height of its own: the list sizes its frame by the kind's `Height`. Code that walks a list's frames (`ForEachFrame`, KAF's tests) reads `frame.Row`.
- **Mixins on the library.** `lib.Internal.Mixins.<Name>`, applied by the builders.
- **The globals are the window's name and the template children Blizzard names after it.**
  - The library's own: the window's frame name, `lib.WindowName` (`Krowi_Options_2_Window`; 1.x's was `Krowi_OptionsWindow`).
  - Blizzard's templates add, through their `$parent` names: `Krowi_Options_2_WindowClearButton` and `…SearchIcon` (`SearchBoxTemplate`), and `…Text` (`UIPanelButtonNoTooltipTemplate`, rewritten by every such button); on Mists also `…TitleBg` (`SettingsFrameTemplate`).
  - No other code reads them. The test addon's step `library-globals-window` lists them with the window built and fails on any global outside the window's name (Retail and Mists, 2026-11-05 in KAF, since 2026-11-06 here).

## Versioning

Each Lua file registers its own LibStub entry through LibMan, and LibStub keeps the highest minor of each entry separately. Bump the minor of every file you change, in that file, from the first release on: nothing of `Krowi_Options_2` has shipped yet (KAF 105.0 waits for 2.0), so every file is at minor 0 and stays there until 2.0 is released.

| File | LibStub entry | Registration | Minor |
|---|---|---|---|
| `Krowi_Options.lua` | `Krowi_Options_2` | `KROWI_LIBMAN:NewLibrary('Krowi_Options_2', 0, {...})` | 0 |
| `Kinds.lua` | `Krowi_Options_2_ElementKinds` | `KROWI_LIBMAN:NewSubmodule("ElementKinds", 0)`; not `"Kinds"`, because LibMan sets `lib[name]`, where it would read as the table of kinds (`lib.Internal.Kinds`) | 0 |
| `Search.lua` | `Krowi_Options_2_SearchModule` | `KROWI_LIBMAN:NewSubmodule("SearchModule", 0)`; not `"Search"`, for the same reason (the search is `lib.Internal.Search`) | 0 |
| `RowMixins.lua` | `Krowi_Options_2_RowMixins` | `KROWI_LIBMAN:NewSubmodule("RowMixins", 0)` | 0 |
| `RowFrames.lua` | `Krowi_Options_2_RowFrames` | `KROWI_LIBMAN:NewSubmodule("RowFrames", 0)` | 0 |
| `WindowMixin.lua` | `Krowi_Options_2_WindowMixin` | `KROWI_LIBMAN:NewSubmodule("WindowMixin", 0)` | 0 |
| `WindowHelp.lua` | `Krowi_Options_2_WindowHelp` | `KROWI_LIBMAN:NewSubmodule("WindowHelp", 0)` | 0 |
| `WindowSearch.lua` | `Krowi_Options_2_WindowSearch` | `KROWI_LIBMAN:NewSubmodule("WindowSearch", 0)` | 0 |
| `WindowPage.lua` | `Krowi_Options_2_WindowPage` | `KROWI_LIBMAN:NewSubmodule("WindowPage", 0)` | 0 |
| `WindowLayout.lua` | `Krowi_Options_2_WindowLayout` | `KROWI_LIBMAN:NewSubmodule("WindowLayout", 0)` | 0 |
| `WindowFrame.lua` | `Krowi_Options_2_WindowFrame` | `KROWI_LIBMAN:NewSubmodule("WindowFrame", 0)` | 0 |

- **No file keeps another file's functions.** A file looks up what another file defines (`lib.Internal.Build.Finish`, `lib.Internal.Mixins.OptionRow`, `lib.Internal.Flatten`, `lib.Internal.Geometry.HelpWidth`) when it calls it, never copies it into a local at load: a newer copy of that other file replaces it on `lib.Internal`, also when this file stays the older copy's. `WindowFrame.lua`'s `Text`, `Color`, `Finish` and `Row` forward to `lib.Internal.Build` for that reason. The same holds for what an addon gets while it loads: a tab's metatable is `lib.Internal.Mixins.Tab`, so a newer copy's tab methods reach a tab an older copy made. Headless, Structure S5 scans every file for such a capture.
- **Shared tables on `lib` are added to, never replaced.** `lib.Internal` and each table in it (`Tabs`, `Mixins` and every mixin in it, `Build`, `Kinds`, `Geometry`) is made as `X = X or {}` and then filled: a newer copy of a file loaded second would otherwise empty a table an older copy of another file filled, and with the window's methods spread over five files, a file at an equal minor never runs again to fill it back. `Krowi_Options.lua` makes `lib.Internal`, and every file that writes into it makes it the same way at its top. Only `Kinds.lua` writes the entries of `lib.Internal.Kinds` and `lib.Internal.Geometry`, each whole. The core makes `lib.Internal.Mixins`, `Build` and `Tabs`, and the other files write into them without making them again, so a core from before `lib.Internal` existed does not mix with these files: they raise "attempt to index a nil value" when they load (nothing of `Krowi_Options_2` has shipped in the old layout; a consumer embedding the pre-split copy is deployed current with `Deploy-TestAddon.ps1 -Consumers` before a test, and every consumer embeds the same copy at release).
- **A released file is never deleted or renamed**, only stubbed: it stays, with its registration at a raised minor and nothing else, so an older copy's file of that name cannot win and run.
- **Moving a method or function between files raises both files' minors**, the file it leaves and the file it joins, so in a mix of copies both come from the newest copy and the method is defined exactly once.
- These rules hold from the first release on. Nothing has shipped: the split of `WindowMixin.lua` into five files, `Kinds.lua` and `lib.Internal` (2026-11-06) are 2.0's file set at minor 0, with no stubs.
- The locale files register nothing: every copy adds its phrases (`NewDefaultLocale(true)`, `NewLocale(lang, true)`), so a newer copy's code finds the phrases it added. Where two copies have the same phrase, AceLocale keeps the first-loaded copy's English and the last-loaded copy's translation, whichever copy is newer (known debt below).
- `## Version:` in the TOC is the release version and must match the top changelog entry; it is unrelated to the minors. A breaking API change needs a new major name (`Krowi_Options_3`), as 2.0 did for `Krowi_Options_1`.

## Consumers

| Consumer | Pinned | Uses |
|---|---|---|
| Krowi_AchievementFilter | 2.0 (from 105.0) | `CreateWindow` with every config field and `GetStrings` (`Options/Window/Window.lua`), `Markup` and the phrases `L` (`Options/Window/Help/Help.lua`); in its tests `WindowName`, `GetStrings`, `Markup`, the window's frames and three internals: `Tabs` and `CardColumns` (`Tests/Options.lua`) and `Frame` (`Tests/Pictures.lua`), which it reads through `lib.Internal or lib` from its paired pull request on. |

`CreateWindow` needs five fields: `TabName`, `Saved`, `Groups`, `SectionName` and `GetElements`. `IsNew`, `Landing`, `OnSectionShown`, `GetHelp`, `ResetSection`, `ChangedCount` and `OnCreated` may be left out: the tab's `Config` is the window's own copy of the addon's config, with a default for each of the first six (`configDefaults` in `Krowi_Options.lua`), so the window calls them without checking; the addon's table is left as it gave it. `ResetSection` and `ChangedCount` come as a pair (Defaults is enabled by one and runs the other): leave out both or give both. It refuses a config that lacks a required field, has a field of the wrong type (`configFields`) or has a key it does not know (1.x's `Strings` among them), with an error at the addon's own line naming the tab and the field or the key.

**The contract** is frozen from 2.0 on: it may grow, and a change to anything in it needs a new major name (`Krowi_Options_3`).
- **Where it is written down:** the config in `Krowi_Options.lua`'s header; the element kinds and the option interface in `RowMixins.lua`'s header.
- **Public:** `lib.CreateWindow`; a tab's `Open`, `Toggle`, `IsShown`, `Refresh`, `GetFrame` and `GetSaved` (`Unregister` is for tests); `lib.GetStrings`, `lib.Markup` and `lib.WindowName`; `OnCreated`'s frame and its `Lightbox`.
- **Internal, can change in any version:** everything else. The library's own names all live under `lib.Internal` (`Tabs`, `Frame`, `Shared`, `SetShared`, `GetFrame`, `Mixins`, `Build`, `Kinds`, `Geometry`, `Search`, `Flatten`, `InitList`, `RowGeometry`, `RowX`, the `Card*` functions, `WindowWidth`); the window's fields and methods are internal too. Besides the public names, `lib` holds only `Internal`, what LibMan puts on a library (`Name`, `Version`, `Localization`, the phrases `L`) and the submodules LibMan hangs on it under their registration names. Structure S6 records `lib`'s and `lib.Internal`'s keys, so a key added to either is a decision made in the open: a new public name is frozen with the contract.
- **Tests read internals through `lib.Internal or lib`** (the harness's `h.Internal`, an `Internal()` helper in the test addon's files), so the same test runs on a copy from before the move; KAF's tests read them knowingly the same way and change with them.
- **Saved keys:** the library writes two keys in each addon's `config.Saved` table:
  - `Window`, the shared place, size, help pane and search ticks, with `Changed`, the `time()` of the last change. It is written whole into every loaded addon's table on each change, and the window opens from the newest (docs/work/2026-11-05-contract-and-errors).
  - `LastSection`, per addon.

  Never change the shape of a saved key; add a new one instead.
- **An addon's errors:** a call into an addon (`OnCreated`, `OnSectionShown`, `GetElements`, an option's `IsHidden` or `GetLabel` while the page is read, `GetHelp`, each searched section) runs through a file-local `Protected`. That is `xpcall` with `CallErrorHandler`, each file with its own copy so no file depends on another's version. The error goes to the error handler, and the window goes on with what it got.

## Taint-sensitive areas

Run the `krowi:taint-reviewer` agent after changing any of these:
- The window inherits `SettingsFrameTemplate`, the only one of Blizzard's settings templates it may: the others run Blizzard's Settings code, which taints the game's own Options window. KAF's `options-templates` lint rule checks `Libs/Krowi_Options/`.
- `build.Select` mixes Blizzard's `DropdownWithSteppersMixin` and `WowStyle2IconButtonMixin` into addon frames, and the rows use `MinimalSliderWithSteppersTemplate`, `WowStyle2DropdownTemplate`, `InputBoxTemplate` and `UIPanelButtonNoTooltipTemplate`.
- The hover help in the collapsed pane uses `Krowi_Tooltip` (Krowi_Util's), never `GameTooltip`.
- Escape: the consumer registers the window and its lightbox for closing (KAF in `OnCreated`).
- The key row runs the consumer's `Slots[n]:Set(key)`. A `Set` that writes bindings (`SetBinding`, `SaveBindings`) fires `UPDATE_BINDINGS` from addon code, which runs Blizzard's binding displays tainted for the session: accepted, KAF #197 (taint review, 2026-11-05).
- Every text a consumer hands the window must be a plain string, never a secret value: the window compares, joins and measures them.

## Localization

- `Localization\<lang>.lua`, CurseForge project 1783244 (https://legacy.curseforge.com/wow/addons/krowi-options/localization). Sync from this checkout with `krowi:localization`; the window's strings are built in `lib.GetStrings` (`Krowi_Options.lua`) under English keys.
- The 22 phrases and their translations came from KAF's project and Krowi_Util's "Requires a reload" (2.0).

## Code style

- Match the file you are editing: 4 spaces; double quotes in Lua except the `NewLibrary` call.
- No semicolons. Each Lua file starts with the copyright block, a blank line, `---@diagnostic disable: undefined-global`, a blank line, then `if not KROWI_LIBMAN then return end` (a standalone install loaded before any Krowi addon stays silent), its registration, and `if not lib then return end` (or `if not sub`), then `lib.Internal = lib.Internal or {}`.
- CRLF on disk (LF in git, `core.autocrlf=true`), no BOM, no final newline.

## Testing

**Headless**, from the repo root or a worktree's, with the kit's Lua 5.1: `& "E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools\lua51\lua.exe" Tests\headless\run.lua`. It loads the library's files in the order `Krowi_Options.xml` lists them on Krowi_Util's real LibStub, AceLocale and LibMan (found beside this repo), and runs the suites in `Tests/headless/suites`: `ReviewFixes` and `ContractAndErrors` (the checks of the 2.0 reviews), `Bugs` (a Recorded/Target scenario per open defect: it passes while the code behaves as recorded, the fix flips Recorded to Target in the same change), `TestAddon` (the frame-free scenarios of the test addon) and `Structure` (the names on every mixin and builder, the search and signature snapshots on the test addon's fixtures, mixes of two copies, the scan for load-time captures, and `lib`'s and `lib.Internal`'s keys). Suites read internals through `h.Internal(lib)`. A new suite file goes in `run.lua`'s list. The stand-in has no real frames, ScrollBox or templates, so nothing that draws is proven here.

**In game**, through the test addon `Krowi_OptionsTests` (`/kotest`, `Tests/Krowi_OptionsTests`): a fixture tab with every element kind and option type, a second tab, the frame-free scenarios and the live steps (open, public surface, tabs, sections, toggles, ranges, inputs, hover help, search, confirm, pane, close, restore, BugGrabber). It needs no consumer addon, only Krowi_Util:
1. `& ".claude\tools\Deploy-TestAddon.ps1" -WhatIf`, then without `-WhatIf`, per client: it mirrors the test addon, deploys this checkout into its `Libs\Krowi_Options` (the kit's `Deploy.ps1` through `-Destination`) and Krowi_Util into its `Libs\Krowi_Util`. The game finds a new addon folder only at client start.
2. `& ".claude\tools\Run-GameTests.ps1" [all|smoke|<step>] -Client Retail|Classic|...` runs `/kotest run`, reloads and reads the results (`Read-GameTests.ps1`, the saved variable `Krowi_OptionsTests.lua`) and BugGrabber; exit 0 only when every run passed something and nothing failed. Clients the kit can start: Retail, Mists, Forever.
3. Other consumers loaded beside it share the library: **at equal minors the first-loaded copy of each file wins, and KAF and Krowi_ExtendedVendorUI load first**, so a run tests their embedded copy unless this checkout's minors are higher; the run's last lines name which consumers are loaded and each file's winning minor. So bump the minors of the files you changed, deploy the consumers current (a stale KAF install once made two steps fail), or turn them off on the test character.
4. A TOC must start with its `## Interface` line: the Mists client read nothing of the test addon's TOC while a comment block came first (checked in game 2026-11-06), Retail did.

Test the consumers too: Krowi_AchievementFilter's `/kaftest options` and `escape` (Retail and Mists) after a library change, through a KAF worktree whose submodule points at the change: `git -C Libs\Krowi_Options fetch "E:\World of Warcraft Addon Development\Krowi_Libraries\Krowi_Options" <branch>`, then `git -C Libs\Krowi_Options checkout FETCH_HEAD`; commit the new pointer only after this library is released.

**Two copies:** deploy this checkout as its own `AddOns\Krowi_Options` folder next to KAF. It loads after KAF, so it finds KAF's `KROWI_LIBMAN` and AceLocale. With equal minors nothing of it may run; with every minor raised, every file of it runs. BugGrabber must show no warning either way. Remove the folder after.

## Git and release

- `main` is the only branch and the release branch. Branch from `main` and open PRs against it.
- `gh` and git writes on `TheKrowi/Krowi_Options` may run without asking (Krowi, 2026-11-06): push a work branch, open its PR against `main`, comment and label. Merging a PR stays Krowi's.
- Gate log: enrolled. Every work folder keeps a `gates.md` with a row per gate answer; which gates ask is the kit's `skills/process-issue/gates.md`.
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
# Spec: Finish Krowi_Options 2.0 before it is released
Intent: [intent.md](intent.md). Status: accepted

## Requirements
Numbered by phase. Each phase is its own pull request, and Krowi gates after each.

**Phase 1: tests**
1. This repo has a headless suite (Lua 5.1, the kit's `lua.exe`) that loads the library from `Krowi_Options.xml` (not from a hand-kept file list) and fails on any check that fails. It covers: two copies with equal and with raised minors; bad configs; `Search`; the signature and search results of KAF's sections as a recorded snapshot; every window method present after only a newer core file loads; one failing check per bug of phase 3, written first.
2. This repo has a test addon (`Tests/Krowi_OptionsTests/`, own TOC) that hosts the library on every client (Retail, Mists, Era, Anniversary, Forever; Titan has no local install), registers a tab, and runs in game the checks that KAF's `options` suite runs today on the library's internals. It follows Krowi_ExtendedVendorUI's `/kevutest` standard: one slash command, steps with a banner and a screenshot, results to a saved variable, a last step reporting the library's Lua errors from BugGrabber.
3. KAF's `options` suite keeps only what KAF can see: its own options and their mapping, the Y binding, its window config and help. Its steps on the library's internals move to the test addon, one for one, and KAF's copy is deleted in the paired KAF PR once the test addon's equivalent is green on Retail and Mists.
4. The release package leaves the test addon out. The exclusion list is the `ignore:` list of a `_Packaging/.pkgmeta` in each repo (the name the WoW packagers use; Krowi, 2026-11-06), read by the addon manager's zipper and by the kit's `Deploy.ps1`; a repo without the file keeps today's built-in directory list. Only `ignore:` is read, as a list of `- path` lines (a directory or file, `*` globs), with `#` comments; every other `.pkgmeta` key is ignored, and neither tool needs a YAML library.

**Phase 2: structure, behaviour unchanged**
5. `WindowMixin.lua` is split along the responsibility lines of the design below. No method is lost: the sorted list of method names on `lib.Mixins.Window` is the same before and after each step.
6. One table per element kind, `lib.Kinds`, owns that kind's builder name, height, expansion, hidden test, search fields and option accessor; no other file branches on `Kind` for these.
7. The geometry numbers shared between the builders and the mixins live once, in `lib.Geometry`; the builders' dead row heights are gone.
8. Everything that is not the public surface sits under `lib.Internal`, and one test checks that `lib`'s keys are the public names plus the submodules.
9. The search results and the sections' signatures on KAF's sections are byte-identical before and after (the phase 1 snapshot); KAF's headless `options` and `escape` stay green; in game, Retail and Mists `options` and `escape` stay green.

**Phase 3: bugs.** Each has a failing check first (phase 1), then the fix.
10. The 2.1 list: the undo arrow lights the reload bar for a paired control that needs one; a question asked on the Overview can be answered; a slider without a step reaches every value and min equal to max does not divide by zero; a page shows new element data when only the data changed, with the signature unchanged; `With` on a non-toggle does not make the row's own slider or button drive the `With`; closing the window during a search does not rerun the section on the hidden window; Retail's `|cn...:` colour codes are not stripped from the searched text, so the search no longer matches them; no closure per row on a refresh; the leftovers of 1.0's per-tab strings are gone; a window left shown after its last tab unregisters is hidden.
11. The older backlog (`2026-11-05-review-fixes/backlog.md`) items that end in an error or a wrong display: #2 to #10, #27 to #29, with `SectionId` and `OnSectionShown` no longer pointing at a section that errored. Cleanups #19 to #22 fall out of phase 2 or are done here.

**Phase 4: the config contract (#30)**
12. `CreateWindow` requires only `TabName`, `Saved`, `Groups`, `SectionName` and `GetElements`. The window works without `IsNew` (never new), `Landing` (the Overview), `OnSectionShown` (nothing), `GetHelp` (no help), `ResetSection` (nothing), `ChangedCount` (0). A config that passes them behaves as before.
13. A config key the library does not know is an error at the addon's own `CreateWindow` line, naming the tab and the key.
14. The config's comment block in `Krowi_Options.lua` and `CLAUDE.md` state the new contract; KAF's `window-second-tab` scenario drops its no-op functions in the paired PR.

**Phase 5: in game**
15. The items only the game answers are answered, each recorded in the work folder: link row highlight (#16), atlases against game data (#17), the tab row's arrow textures (#18), a greyed-out slider or input box under the mouse (#31), the globals the window adds (#15, already covered by KAF's `library-globals-window`).
16. The test addon is green on Retail, Mists, Era, Anniversary and Forever; KAF's `options` and `escape` are green on Retail and Mists; the kit's two-copy gate (`Test-TwoCopies.ps1`) passes; BugGrabber shows no row naming Krowi_Options on any client.

**Phase 6: clients and housekeeping**
17. The TOC's `## Interface:` is `120105, 50504, 20506, 16001, 11509` plus Titan's `38002`: the installed clients are Retail 12.1.5, Mists 5.5.4, Anniversary 2.5.6, Forever 1.60.1, Era 1.15.9 (`.build.info`), and Krowi_ExtendedVendorUI's TOC lists the same five.
18. The library is reviewed for Era, Anniversary and Forever against their FrameXML (`wow-ui-source` `classic_era` and Forever's branch): templates, atlases, API the window and rows call; what differs is fixed or listed.
19. `CLAUDE.md` states the minimum Krowi_Util version (2.5, for `Krowi_Tooltip`), and the rules of backlog #24: a released file is never deleted or renamed, only stubbed with a raised minor; a shared saved key never changes shape; moving a method raises the minor of both files; shared tables on `lib` are added to, never replaced. The kit's release preflight fails when a registration name from the last tag has disappeared (#25).

## Design

### The split (phase 2), reviewed by Opus
Opus read the six files, the 2026-10-25 plan and both backlogs and corrected the first proposal. Five window files plus a kinds file, not the nine responsibilities I first listed:

| File (submodule) | Holds | Owns |
|---|---|---|
| `Kinds.lua` (`ElementKinds`), after Localization | `lib.Kinds`, `lib.Geometry`, `InitList`, `Flatten` (from `Search.lua:29`), `RowGeometry`, `RowX`, the `Card*` functions | the element kinds |
| `WindowMixin.lua`, kept as the core | `OnLoad` (calls each part's `Load<Part>`), `Init`, `OnShow`, `OnHide`, `OnEvent`, `InCombat`, `Open`, `ShowTab`, `RefreshTabs`, `UpdateSearchAll`, `ApplyStrings` | `Tab`, `Config`, `Strings`, `Saved`, `TabButtons`, `CombatStarting` |
| `WindowLayout.lua` | the inner frame, width, measuring, the navigation's scroll bar, `EndFill`, `Layout`, the help pane's collapse, resize and drag, atlas slicing | `PaneCollapsed`, `NavScrollShown`, `Filling`, `LayoutPending`, `InnerSlices`, `Measure` |
| `WindowPage.lua` | the navigation buttons, `ShowSection`, `FillPage`, `Refresh`, `RefreshFooter`, `OnOptionChanged`, `ScrollToOption`, the confirm dialog, Defaults | `SectionId`, `Elements`, `Signature`, `ReloadPending`, `Confirming` |
| `WindowSearch.lua` | `SearchElements`, `OnSearch`, the search box and check box hooks | `Searching`, `SearchEveryTab`, `BroadSearch` |
| `WindowHelp.lua` | the help text and picture, the kicker, section and search help, Show me with its secure overlay, the hover and the tooltip | `Help`, `HoverOption`, `SecureHelp`, `HelpBar`, the `Hover*` flags, `TooltipShown` |

- The 2026-10-25 plan's `HelpPane.lua` becomes `WindowHelp.lua`; its `Compound.lua` is not needed, since the tab list, grid and family become entries in the kinds table.
- Atlas slicing goes into layout (it holds no state and only `Layout` calls it). The tooltip goes into help (`OnRowEnter` writes `HoverOption`, which `UpdateShowMe` reads). The confirm goes into the page (it drives the same header controls as `ShowSection`). List pooling goes into `Kinds.lua` (it needs the kinds, not the window).
- No file calls another at load: the window is built after `PLAYER_LOGIN`. Every call is `self:Method()`, which the build copies onto the frame, or `lib.X` looked up at call time. Each file keeps its own `Protected`.
- **Each window file adds to `lib.Mixins.Window` and never replaces it** (`WindowMixin.lua:133-134` replaces it today and would break a mix after a split: a newer core file would empty the table and an unchanged part file at an equal minor would never run again).
- **Two-copy rule.** Nothing of `Krowi_Options_2` has shipped (KAF 105.0 has no date; the only tag is `_1`'s 1.0). The split sets 2.0's file set at minor 0 with no stubs, **only if KAF 105.0 ships with the split**. If KAF ships its 2.0 first, every changed file's minor is raised and a deleted file is stubbed (backlog #11).
- **How the split helps the bugs.** Defaults' visibility is written in two places (`ShowSection:756`, `RefreshFooter:858`), both in `WindowPage.lua`; the Overview question becomes one condition. The search box's hooks, the `Searching` flag and `OnSearch` end up together in `WindowSearch.lua`, so clearing the flag before the box empties is a fix in one file whichever `OnHide` fires first. `Filling` is not stuck at `222a553` (both brackets end it); what backlog #27 still describes is `SectionId` and `OnSectionShown` pointing at the section that errored, fixed in phase 3, and the split makes the two fill brackets one pair in layout.

### The kinds table
Only `Kinds.lua` writes `lib.Kinds`, each entry whole, so the newest copy's file decides every kind and no field mixes two copies:

```lua
lib.Kinds.Option = {
    Build = "OptionRow",   -- name on lib.Build, looked up per row
    Height = 30,           -- or function(window, element)
    Expand = nil,          -- function(element, list, known): cards, grid, tab list
    Hidden = function(e) return e.Option:IsHidden() end,
    Names = ..., Descriptions = ...,
    Options = function(e) return e.Option, e.With end,
    Search = { Indented = true },
}
```

A newer copy that adds a kind raises `Kinds.lua`, `RowFrames.lua` and `RowMixins.lua` together; releases are cut one after another on `main`, so in a mix all three come from the newest copy. The option row's per-type chains (`RowMixins.lua:254-284`, `:323-352`) become a file-local table.

### Geometry and internal versus public
`lib.Geometry`, in `Kinds.lua`, read at call time by `RowFrames.lua` and `RowMixins.lua`: the card's picture height (86), its border colour, the tab row's check box x (34), the slider widths (250 and 214). The builders' row heights are dead (each row is set to its host with `SetAllPoints`), so the 26 of SubHeading that applies stays and the 24 goes.

Internals go under `lib.Internal`: `Tabs`, `Frame`, `Shared`, `SetShared`, `GetFrame`, `Mixins`, `Build`, `Kinds`, `Geometry`, `Search`, `Flatten`, `InitList`, `RowGeometry`, `RowX`, the `Card*` functions, `WindowWidth`. Public stays on `lib`: `CreateWindow`, `GetStrings`, `Markup`, `WindowName`, and the submodule tables LibMan hangs there; a tab's methods stay as they are. A namespace rather than a prefix so one test can check `lib`'s keys. **This is done before the release or never**: afterwards a newer copy would have to move `Tabs`, `Frame` and `Shared` left by an older copy in an `oldminor` handler.

### The test addon and the exclusion list
- `Tests/Krowi_OptionsTests/` holds the addon (TOC, a loader that includes the library from the repo root, the in-game steps). The headless suite lives in `Tests/headless/`, grown from `repro/repro.lua` of the two earlier work folders.
- **Exclusion list.** The addon manager's `Zipper.EXCLUDED_DIRECTORY_NAMES` is a hard-coded set of directory names (`.git`, `.github`, `.vscode`, `.claude`, `_Packaging`, `raw`, `wiki`, `docs`), mirrored by hand in the kit's `Deploy.ps1:57`. Excluding `Tests` by name would also drop Krowi_AchievementFilter's `Tests/`, which ships on purpose (`/kaftest`). So the list becomes a file per repo, `_Packaging/.pkgmeta` (Krowi chose the name the WoW packagers use): its `ignore:` list, as `- path` lines (directory or file, `*` globs, `#` comments), read by both tools with a few lines of parsing each, no YAML library, every other key ignored; without the file the built-in set applies. The library's file lists `Tests/`. A `.pkgmeta` also has meaning to CurseForge's own packager; uploads here are zips from the addon manager, so none reads it, but a future switch to a packager would pick the same list up. This touches Krowi_AddonManager (Python, `zipper.py`) and Krowi_ClaudeKit (`Deploy.ps1`, a test case), each its own PR; neither ships a release without Krowi's go.
- Deploying the test addon: `Deploy.ps1` from the worktree for the addon folder, and the library through `-Destination "<client>\Interface\AddOns\Krowi_OptionsTests\Libs\Krowi_Options"` from the library checkout (the rule in the workspace `CLAUDE.md`: a library is tested through a consumer, never as its own AddOns folder). The two-copy gate stays on KAF.

### Phase order and the paired PRs
Krowi_Options PRs 1 to 6, KAF PRs paired with phases 1 (trim `Tests/Options.lua`), 2 (`lib.Internal` names in what KAF still reads, pointer), 4 (`window-second-tab`), and the pointer bump after the last; kit PRs for the exclusion list and the preflight check; addon manager PR for the exclusion list. KAF sessions may change this repo without asking (Krowi, 2026-11-06); the gates stay.

## Options considered
1. **Five window files plus `Kinds.lua`** (recommended, Opus's design). Responsibilities follow state ownership; each cut survives a two-copy mix; the Overview and search bugs each land in one file.
2. **The 2026-10-25 plan's `HelpPane.lua` and `Compound.lua`, window otherwise whole.** Smaller step but leaves layout, page, search and help in one 800-line class, and a compound kind that the kinds table makes unnecessary.
3. **Merge each row builder with its mixin per family** (the wider fix for the duplicated geometry). Turns the shared numbers into locals, but adds four permanent files only the game can test. Not taken; offered separately, after 2.0.
4. **Keep KAF's tests on internals and shrink them later.** Rejected by Krowi: KAF tests what it can see, the library covers its internals.
5. **A prefix for internals instead of `lib.Internal`.** Cannot be checked as one test; rejected.
6. **Exclude `Tests` by name in the zipper.** Would drop KAF's shipped `Tests/`; a per-repo list is the fix.
7. **A gitignore-style file of its own** (`_Packaging/.packageignore`, which I recommended). Familiar syntax, but Krowi chose `.pkgmeta`, the packagers' own name, over it.

## Areas of concern
- **Taint and secret values:** the split moves code that touches Blizzard frames (the Show me secure overlay, the dropdown with arrows, `SettingsFrameTemplate`, `Krowi_Tooltip`). `krowi:taint-reviewer` runs after the help step of phase 2 and on the whole diff of each phase that touches them; nothing may start using `GameTooltip` or add a field to a Blizzard frame. Every text a consumer passes stays a plain string (phase 4's defaults are plain values).
- **Clients:** Retail 12.1.5, Mists 5.5.4, Titan 3.80 and, from phase 6, Era, Anniversary and Forever. Forever runs Retail's interface with Camelot overrides and `IsClassicEra` stays true there: the library branches on what the frame does, not on a client name; to check in phase 6 whether it needs `IsModern` from Krowi_Util 2.8. Titan has no local install; its coverage stays the headless suite and review.
- **Blizzard API changes:** `Find-DeprecatedApi.ps1` on live, classic, classic_era and classic_titan at each phase end; `SetMinResize` fallback and other dead branches removed (backlog #21).
- **Other addons, plugins and skins:** KAF is the only consumer today (pinned at 2.0); KEVU adopts later. `lib.Internal` hides names KAF's tests read: the paired KAF PRs change them in lockstep. Skins that restyle the window (ElvUI and others) act on the frames by name; `WindowName` stays.
- **Saved variables and migrations:** none change shape. The two keys (`Window`, `LastSection`) stay; no new key is planned. A migration is needed only if a phase adds one: say so in the plan.
- **Localization:** no new phrase is planned for phases 1 to 4. A phrase added later goes into every locale file, with the English first and CurseForge synced through `krowi:localization`; the test addon's own texts are English debug text and stay out of the locale files.
- **Embedded libraries:** this is the library. Every changed file's LibStub minor is raised in that file; the table in `CLAUDE.md` grows by the new files. At release the minors of unchanged files stay at 0 only if nothing shipped before.
- **Data snapshots:** none in this repo; the phase 1 search and signature snapshot is its own record.
- **Player-facing text:** the library's changelog is for addon authors: the 2.0 entry grows by one line per phase for the contract (phase 4), the clients (phase 6) and the fixes players see (phase 3); no dev notes.
- **Release:** none. No version is cut and no host touched; the exclusion list reaches the release pipeline in kit and addon-manager PRs that Krowi merges separately.

## Verification
- **Phase 1:** the headless suite runs red for each phase 3 bug and green for the rest on `222a553`'s code; the test addon's in-game steps equal the KAF steps they replace, run beside them once on Retail and Mists before KAF's copy is deleted.
- **Every phase:** the kit's Lua 5.1 syntax check; the headless suite; KAF's lint and headless `options` and `escape` through a KAF branch pointing at this one; `Find-DeprecatedApi.ps1`; `krowi:taint-reviewer` where the phase touches Blizzard frames; `/code-review` on the diff.
- **In game** (Krowi's characters only, one client at a time, `Send-GameInput.ps1`): `Run-GameTests.ps1 options, escape` through KAF on Retail and Mists; the test addon's `/kaftest`-style command on every client; BugGrabber clean.
- **Phase 2 only:** the method-name list of `lib.Mixins.Window` unchanged after each step; the search and signature snapshot unchanged; a two-copy check with only a newer core file; Krowi's look at the window in game on Retail and Mists (a `look` gate), since the headless run never draws rows.
- **Phase 5:** the kit's `Test-TwoCopies.ps1` through KAF's branch.

## Decision
Krowi, 2026-11-06:
- **Split:** five window files plus `Kinds.lua` (option 1).
- **Timing:** KAF 105.0 waits for this work, so 2.0's file set is final at minor 0 with no stubs.
- **Internals:** moved under `lib.Internal` in 2.0. KAF tests only the public behaviour of its own addon; the library's own test addon covers the internals (the question was asked twice because the first answer asked for the plan to be restated).
- **Exclusion list:** `_Packaging/.pkgmeta`, its `ignore:` list, read by the addon manager and the kit (option 7 replaced by Krowi's name).
- Taken from the earlier gate answers: all six phases, a gate after each, `Five required plus an unknown-key check` for the config, Era, Anniversary and Forever added and tested, the test addon in this repo as the host on every client.

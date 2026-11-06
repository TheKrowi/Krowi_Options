# Intent: Finish Krowi_Options 2.0 before it is released
Author: Krowi, maintainer. Source: idea, from a review of the library's structure and the open 2.1 backlog (2026-11-06). Status: accepted

## Problem
2.0 is merged on `main` (#4, `222a553`) but not released: the only tag is `1.0`. While it is unreleased its contract can still change, and the first consumers after Krowi_AchievementFilter (KAF) are about to arrive: Krowi_ExtendedVendorUI (KEVU) on Era, Anniversary and Forever as well as Retail and Mists. What stands in the way:

- **A minimal consumer carries dead weight.** `CreateWindow` requires eleven config fields; KEVU would pass six no-op functions (`IsNew`, `Landing`, `OnSectionShown`, `GetHelp`, `ResetSection`, `ChangedCount`). KAF's `window-second-tab` scenario already had to.
- **Known bugs wait for 2.1.** The 2.0 reviews' backlog (`docs/work/2026-11-05-review-fixes/backlog.md`, the 2.1 list in `docs/work/2026-11-05-contract-and-errors/plan.md`): a slider without a step reaches only its two ends, a question on the Overview cannot be answered, the undo arrow does not light the reload bar for a paired control, closing the window during a search reruns the section on the hidden window, and more.
- **The structure invites more of them.** `WindowMixin.lua` is 1197 lines with about 117 functions and about 25 state flags; each element kind is handled in about eight places across four files; layout numbers are copied between builders and mixins and already disagree; the line between public and internal exists only in comments. The 2.1 bugs are mostly two states colliding in that one class.
- **The library has no tests of its own.** KAF's `options` suite reads about 40 internals of a library it does not own, cannot reach the bugs above (its stand-in for the game takes any call, it never draws rows, it passes only valid configs, it loads one copy), and runs on two of the library's clients only.
- **Three clients are not covered.** The TOC lists Retail, Mists and Titan; KEVU also runs on Era, Anniversary and Forever.

## Proposed outcome
2.0 is the release Krowi wants to publish: a consumer addon writes a short config and gets a window that behaves on every client the family plays; the library's own tests, in this repo, prove its internals; KAF's tests cover only what KAF can see.

Six phases, each its own pull request with a gate in between (Krowi, 2026-11-06):

1. **Tests first.** A headless suite in this repo (`repro/repro.lua` grown) and a small test addon that hosts the library on every client and runs the checks KAF's `options` suite runs on internals today. KAF's copy of those is trimmed to what it can see.
2. **Structure, behaviour unchanged.** `WindowMixin.lua` split by responsibility; one table per element kind instead of if/else chains on `Kind`; geometry in one place; internals marked as internal.
3. **The bugs.** The 2.1 list and the older backlog items, each with a failing check first.
4. **A smaller config contract (#30).** Five required fields (`TabName`, `Saved`, `Groups`, `SectionName`, `GetElements`), defaults for the other six, and an error on an unknown config key.
5. **In game.** The unverified items (backlog #15 to #18, #31), the test addon on every client, KAF's runs on Retail and Mists, and the two-copy gate.
6. **Clients and housekeeping.** Era, Anniversary and Forever in the TOC and reviewed, the minimum Krowi_Util version, the `CLAUDE.md` rules (#24), a kit preflight check for a registered file that disappeared (#25).

## Affected users and systems
- **Addon authors:** KAF (pinned at 2.0, the library moves with its submodule pointer), KEVU (next consumer), anyone who embeds the library.
- **Players:** the display bugs above; every client of the family gets the window.
- **Clients:** Retail 12.1.5, Mists 5.5.4, Titan Reforged 3.80 (no local install), and from this work Era 1.15.x, Anniversary 2.5.x, Forever 1.60.x.
- **Saved variables:** the two keys the library writes into each addon's table (`Window`, `LastSection`) keep their shape.
- **Other repos:** KAF (its `options` suite and `window-second-tab` scenario change, paired PRs; its `Libs/Krowi_Options` pointer follows the merge); Krowi_ClaudeKit (the preflight check of phase 6).

## Constraints
- **Taint:** the window inherits `SettingsFrameTemplate` only; no other Blizzard settings template; hover help uses `Krowi_Tooltip`, never `GameTooltip` (CLAUDE.md, Taint-sensitive areas). The refactor must not move any of it.
- **Two copies:** a second embedded copy still loads without a warning and does not mix its code with the first: a LibStub minor per file, bumped for every file changed; no file keeps another file's functions; no XML templates; no globals besides the window's name.
- **The 2.0 name stays `Krowi_Options_2`.** Unreleased, so its contract may change and is frozen again at release. The public surface (`CreateWindow`, a tab's `Open`, `Toggle`, `IsShown`, `Refresh`, `GetFrame`, `GetSaved`, `GetStrings`, `Markup`, `WindowName`, `OnCreated`'s frame and `Lightbox`) keeps its behaviour for KAF.
- **Saved keys** keep their shape; any new one is added, never reshaped.
- **No release here:** no version is cut, no host is touched. The changelog's 2.0 entry grows and its date is reset at release.
- **Process:** a gate after every phase; Krowi judges any visual change in the game.

## Open questions
Answered by Krowi, 2026-11-06, at the intent gate:
- **Where the test addon lives and how it stays out of the release zip:** in this repo; the release pipeline gets a list of files to include or exclude in `_Packaging`, like a `.gitignore` (spec).
- **The interface numbers of Era, Anniversary and Forever:** read from the installed clients, not guessed (spec).
- **Whether `WindowMixin.lua` is split into the files the 2026-10-25 plan named or along other lines:** decided in the spec with Opus's review of the design.

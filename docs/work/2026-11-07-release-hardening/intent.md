# Intent: hardening before the 2.0 release
Author: Krowi (maintainer), proposed by Claude. Source: idea, before the first release of Krowi_Options 2.0. Status: done

## Problem
Krowi_Options 2.0 passes its own test addon (`/kotest all`, 88 checks, 0 failures) on Retail, Mists, Forever, Era and Anniversary, but no run presses some of the buttons a player can press:
- **Show me**, the help pane's button that closes the window and points at the feature, and the secure button a consumer lays over it (KAF's map route): no step clicks it, none checks that a laid-over button lies on it, follows the window or is let go.
- **Defaults, then Yes**, which sets a whole section back through the consumer's `ResetSection`: a bug there wipes a player's settings. The `dropdown` step only answers an arrow's question with it.
- **The action buttons** (an `execute` row, and a button beside a row).
- **All / None** of a family of check boxes.
- **Up / Down** in a tab list.
- **What combat greys**: Show me with its note, the reload button, the key buttons.

The library's code has also never had a taint review of all its files at once; the reviews so far each read one change.

## Proposed outcome
Before the release, `/kotest all` also presses those buttons on the fixture tab and checks what the window then shows and saves, on all five clients that can be started, with 0 failures and no Lua error. One taint review of every shipped file runs once (Krowi asked for it, 2026-11-07); its findings are fixed or accepted by Krowi before the release.

## Affected users and systems
- The test addon `Tests/Krowi_OptionsTests` (dev-only, never shipped): new live steps, fixture additions.
- The library's shipped files only if the taint review or a new step finds a defect.
- Clients: Retail, Mists, Forever, Era, Anniversary (Titan has no install).
- Players and KAF: nothing changes unless a defect is found.

## Constraints
- The run never sets a CVar, never binds a key of the game, puts every value back at the end, and stops for combat (the existing runner's rules).
- No KAF suite runs to validate the library (Krowi, 2026-11-07).
- A test must not make a protected action: a stand-in secure button in the test addon has no action.
- The marker (`KrowiGameInput`) serves hovers and key presses, not clicks.

## Open questions
- How far the Show me step goes: the library's side with a real hover, or also a real click on the secure button (which needs the kit's marker to learn clicks first).
- Whether to tell the window that combat starts (its own event handler, no real fight) to check what it greys.

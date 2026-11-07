# Plan: hardening before the 2.0 release
Spec: [spec.md](spec.md). Status: done

## Files that change
- `Tests/Krowi_OptionsTests/Tests/Fixtures.lua`:
  - Window's help: `ShowMe` and `CanShowMe` answer `fixtures.ShowMeAnswer` / `fixtures.CanShowMeAnswer` (defaults false and true, today's answers) and count runs (`fixtures.ShowMeRuns`).
  - Tooltips' help gets `ShowMeSecure` and a `ShowMeNote`, served by the stand-in.
  - `ResetSection` counts calls per section (`fixtures.ResetCalls[id]`); `fixtures.GetTabOrder()` / `SetTabOrder(order)`.
  - `fixtures.Reset()` clears the new fields.
- The stand-in, in `Steps.lua` or its own file (registered in `Tests/Files.xml`), made as KAF's map route makes its own (`Options/Window/Help/ShowMe.lua`):
  - `SecureActionButtonTemplate` on `UIParent`, `type` `click`, `clickbutton` a hidden plain button of the test addon that counts its clicks;
  - strata `DIALOG`, placed by coordinates over the owner it is handed;
  - `OnEnter` counts, `PostClick` calls the close it was handed;
  - records every call, with switches to answer false or raise an error;
  - created and moved only out of combat.
- `Tests/Krowi_OptionsTests/Tests/Steps.lua`:
  - after `keys`, before `resize`: `show-me`, `show-me-secure`, `combat`, `defaults`, `execute`, `all-none`, `tab-arrows` (spec requirements 1-7);
  - with the other mouse steps, before `toggle-reset-clipped`: `show-me-secure-hover` (the window raised, the marker's hover over Show me reaches the stand-in) and `show-me-secure-click` (the marker's `ClickAt`: the counting button clicked once, the window hidden, then opened again);
  - `Restore` also puts back the tab order, the fixture's answers and the window's point, and lets the stand-in go; the header comment lists the new steps.
- `CLAUDE.md`, Testing: the new steps; Era and Anniversary read BugGrabber now.
- If the taint review finds a defect: the shipped file, a headless scenario where it can be shown without frames, a changelog line.

## Order
1. The kit's click (`Krowi_ClaudeKit` `docs/work/2026-11-07-marker-click`), built in parallel.
2. Fixtures and stand-in, then the steps (Opus from a brief), read-only review of the diff, my own read.
3. Headless suites green.
4. In game, one client at a time, kit-started from the kit worktree (its marker has `ClickAt`): Retail, Mists, Forever, Era, Anniversary, `Run-GameTests.ps1 all` each after `Deploy-TestAddon.ps1 -Consumers`; then KAF's copy back and the test addon out of every AddOns folder.
5. The taint review's findings to Krowi; fixes, if any, and the runs they touch again.
6. PR (after the kit's).

## Risks
- The mouse steps need nobody at the PC; a refused hover or click waits 30 s and the step SKIPs, which is not a pass: such a run is repeated.
- Moving the window in `show-me-secure` saves its place: the step puts it back, and `Restore` too if the run stopped.
- Feeding `OnEvent` is not a real fight: what only `InCombatLockdown()` guards (the key capture's and Show me's click guards) is not covered; said in the step's line.
- A fixture change can move the headless `Structure` snapshots; only the new help field may.

## Proof
Headless green; `/kotest all` 0 failures on the five clients with every new step PASS (no SKIP), `lua-errors` clean from BugGrabber on every client; screenshots of the new steps read.

## Results
- Headless: `Tests\headless\run.lua` 177 passed, 0 failed; no snapshot moved.
- In game, `/kotest all`, 2026-11-07, this branch's library in the test addon and in KAF (`Deploy-TestAddon.ps1 -Consumers`), the kit's tools from its worktree `feature-2026-11-07-marker-click` (Krowi_ClaudeKit PR #21):
  - Retail 12.1.5: 121 passed, 0 failed, 0 skipped (twice: 19:26 and, on the final code, 20:02).
  - Mists 5.5.4: 119 passed, 2 failed at 19:40 (the resting mouse had brought up a row's help, which hides Show me by design; fixed in the steps: `PutHoverAway`), then 121 passed, 0 failed at 19:45.
  - Forever 1.60.1: 120 passed, 0 failed, 1 skipped at 19:50 (`link-highlight` waited 30 s while the PC was in use); `link-highlight` again at 20:05: 21 passed, 0 failed.
  - Era 1.15.9 and Anniversary 2.5.6: 121 passed, 0 failed, 0 skipped.
  - Every new step passed on every client, `show-me-secure-hover` and `show-me-secure-click` through the kit's marker (a real hover and left click), and `lua-errors` read BugGrabber on all five, Era and Anniversary included.
- Taint review of the whole library: no defect in the library ([review.md](review.md)); its two KAF findings go into a KAF work item before 105.0; the dropdown and chat box check on Retail was clean (accepted).
- Code review of the steps (read-only agent): no false PASS; fixed from it: the stand-in lets go when a fight starts as KAF's does, a stopped run clears a click asked of the marker, the stand-in takes the left button only, `PostClick` is counted apart, a stand-in laid over a frame later is reported as such, the "before" values are taken before the scenarios, Show me's Enabled is checked after `ShowMe` answers false.
- Afterwards: KAF's own library copy deployed back into Retail and Mists, `Krowi_OptionsTests` moved out of all five AddOns folders.
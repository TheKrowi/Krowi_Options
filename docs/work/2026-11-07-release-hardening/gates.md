# Gates: 2026-11-07-release-hardening
Class: harness

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-07 | intent | A short hardening pass before the 2.0 release: test steps for the buttons no run presses (Show me, Defaults then Yes, action buttons, All / None, tab Up / Down) plus one taint review of the whole library | both | "Both (Recommended)" | took |
| 2026-11-07 | design | Show me: is a real hover over the stand-in secure button enough, or also a real click (the kit's marker must learn clicks first) | hover is enough | "Also a real click" | other |
| 2026-11-07 | design | Combat: tell the window that combat starts and ends (its own handler, no real fight) and check what greys | yes, tell the window | "Yes, tell the window (Recommended)" | took |
| 2026-11-07 | plan | The plan (fixture answers and a secure stand-in, nine new live steps, five clients; the kit's click first), shown with the kit's plan at one ExitPlanMode | approve | plan approved at ExitPlanMode with no changes | took |
| 2026-11-07 | design | Taint review, finding 1 (KAF's Open options closes Blizzard's Settings window and saves the bindings from KAF's code) | fix it in KAF 105.0 | "Fix it in KAF 105.0 (Recommended)" | took |
| 2026-11-07 | design | Taint review, finding 2 (a dropdown click clears the chat box's focus from addon code, Retail and Forever) | test it in game, accept if clean | "Test it, accept if clean (Recommended)" | took |
| 2026-11-07 | design | Taint review, finding 3 (KAF's Show me map overlay stays above Blizzard's Options window) | fix it in KAF 105.0 | "Fix it in KAF 105.0 (Recommended)" | took |
| 2026-11-07 | design | An ShowMeSecure that errors, in game (a deliberate error would fail the run's lua-errors step) | leave it to the headless ContractAndErrors 16j | not asked: dropped from the in-game step, spec requirement 2 says why | auto |
| 2026-11-07 | design | Two checks read a second after their state was set found a row's help brought up by the resting mouse (Mists) | put that help away first, as the mouse leaving does, and name the row in the line | not asked: PutHoverAway in Steps.lua | auto |
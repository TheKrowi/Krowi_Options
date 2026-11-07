# Gates: 2026-11-07-release-hardening
Class: harness

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-07 | intent | A short hardening pass before the 2.0 release: test steps for the buttons no run presses (Show me, Defaults then Yes, action buttons, All / None, tab Up / Down) plus one taint review of the whole library | both | "Both (Recommended)" | took |
| 2026-11-07 | design | Show me: is a real hover over the stand-in secure button enough, or also a real click (the kit's marker must learn clicks first) | hover is enough | "Also a real click" | other |
| 2026-11-07 | design | Combat: tell the window that combat starts and ends (its own handler, no real fight) and check what greys | yes, tell the window | "Yes, tell the window (Recommended)" | took |
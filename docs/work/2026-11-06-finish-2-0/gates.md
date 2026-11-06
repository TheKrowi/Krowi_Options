# Gates: 2026-11-06-finish-2-0
Class: harness

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-06 | scope | Which of the six phases go into 2.0 | all six | "All six phases (Recommended)" | took |
| 2026-11-06 | intent | Does intent.md state what Krowi wants | accept | asked for the file to read on a phone, then answered its three open questions: "In the repo, release pipeline should have a list of files to include/exclude in _packaging like a .gitignore." / "Yes" / "Opus". Taken as acceptance with those answers folded in; Krowi did not say "accept" in words | amended |
| 2026-11-06 | design | Breaking internals: may the refactor change KAF's tests in lockstep | yes, lockstep | "Kaf should test what it can see. Krowi options should cover the internals. It's ok for options to have a small test addon to run tests kaf is covering today." | own |
| 2026-11-06 | design | #30: how the config contract shrinks | five required, plus an unknown-key check | "Five required, plus unknown-key check (Recommended)" (after asking what it is today and how the proposal changes it) | took |
| 2026-11-06 | design | Era, Anniversary and Forever: what 2.0 does about them | add them and test where possible | "Add them and test where possible (Recommended)" | took |
| 2026-11-06 | design | What hosts the library on the clients KAF does not load on | a small test addon in this repo | "A small test addon in this repo (Recommended)" | took |
| 2026-11-06 | design | How often to stop during the six phases | after every phase | "After every phase (Recommended)" | took |
| 2026-11-06 | design | How WindowMixin.lua is cut up | five window files plus Kinds.lua | "Five window files plus Kinds.lua (Recommended)" | took |
| 2026-11-06 | design | Whether KAF 105.0 waits for this work (minors stay 0, no stubs) | KAF 105.0 waits | "KAF 105.0 waits for this (Recommended)" | took |
| 2026-11-06 | design | Internals under lib.Internal in 2.0 | yes | first: "I don't get the question and answers. Plan was to move options test to options and kaf only test the piblic stuff right for it's own addon?"; after the restatement: "Yes, in 2.0 (Recommended)" | took |
| 2026-11-06 | design | The packaging exclusion list: a per-repo file read by the addon manager and the kit | _Packaging/Exclude.txt | first: "1. But why txt?"; after the restatement: "_Packaging/.pkgmeta" | other |
| 2026-11-06 | plan | The plan: six phases, phase 1 in detail (exclusion list, harness, test addon, ported steps, paired kit, addon manager and KAF PRs), no full headless fake of the game's frames | approve | approved in plan mode | took |
| 2026-11-06 | merge | Phase 1: Krowi_Options #5, then Krowi_AchievementFilter #399 | merge both, library first | "Merge both, library #5 first (Recommended)" | took |
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
| 2026-11-06 | plan | Phase 2: the plan (step 0 the safety net and -Consumers, then the split in steps 1 to 11, three Opus hand-offs verified by me, look gate at the end) | approve | approved in plan mode | took |
| 2026-11-07 | look | Phase 2: does the options window look right (five screenshots, Retail and Mists, on a page: the builders' row heights are gone, nothing should differ) | looks right | first "point me to the screenshots", then "five screenshots are attached as file cards? i don;t see anything" (the cards did not reach Krowi; sent as a page instead); then "Looks right (Recommended)" | took |
| 2026-11-07 | design | KAF reads optionsLib.L["Requires a reload"] but L is not public: how the paired KAF pull request handles it | KAF reads GetStrings().NeedsReload | "KAF reads GetStrings().NeedsReload (Recommended)" | took |
| 2026-11-07 | merge | Phase 2: Krowi_Options #6 and Krowi_AchievementFilter #400 | merge both | "Merge" | took |
| 2026-11-07 | design | Phase 3: an input box that loses focus without Enter (B13) | save on focus lost too | "Save on focus lost too (Recommended)" | took |
| 2026-11-07 | design | Phase 3: a select whose saved value is no longer one of its choices (B12) | the saved value's own text, nothing saved | "The default and update the saved var. Keeping things shown that no longer exist and work makes no sence" | own |
| 2026-11-07 | design | Phase 3: a section whose GetElements errors (B14b, B14c) | the previous section stays current, OnSectionShown not run for the broken one | "Yes, previous section stays current (Recommended)" | took |
| 2026-11-07 | scope | Phase 3: the extra defects found by the scenarios' author and the structure move | all of them | "All of them (Recommended)" | took |
# Gates: 2026-11-05-contract-and-errors
Class: library

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-05 | scope | What goes into 2.0 before release, after the whole-library review | the contract and the error fixes; display-only bugs and cleanups in 2.1 | "Contract + error fixes (Recommended)" | took |
| 2026-11-05 | design | Where the library's six saved keys live, next to each addon's own keys | list and reserve them | "these are the options window saved keys right? these should be shared between addons, kevu and kaf need to stay in sync ... who'c settings win?" (one block shared by every addon, moved into saved.Window) | own |
| 2026-11-05 | design | Whose shared window state wins after an addon was off and comes back | newest change wins | "Newest change wins (Recommended)" | took |
| 2026-11-05 | design | How the window handles a consumer addon's mistake or bad data | contain at each call | "Contain at each call (Recommended)" | took |
| 2026-11-05 | plan | The plan: this fix, Krowi_AchievementFilter's test branch, the kit's two-copy gate | approve | approved in plan mode | took |

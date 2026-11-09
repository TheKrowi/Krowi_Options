# Gates: 2026-11-09-select-with-button
Class: library

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-09 | scope | Where KAF's Pop Out link button sits (KAF docs/work/2026-11-09-pop-out, the mock page) | a row of its own, no library change | "B1" (an icon button beside the dropdown) | other |
| 2026-11-09 | intent | A dropdown row may carry a small button after its right arrow, explained under the mouse, greying only by itself | accept as written | "Accept as written (Recommended)" | took |
| 2026-11-09 | design | The button's shape | an icon button in the dropdown arrows' style, own control, `GetIcon` per button | "red button, same height as other buttons, just narrower with the how it works icon double arrow to the right" | own |
| 2026-11-09 | plan | B31 first, row.Go, fixture and live step, reviews, /kotest on five clients, look gate, PR, two-copy gate, release 2.1 | approve | "Approve the plan (Recommended)" | took |
| 2026-11-09 | design | /code-review: the button named by its button text in the search but by its label in the help; the collapsed pane's hover help opening past the window | name it by its label everywhere; open the help at the control column; a With the row does not draw adds nothing to the search | - | auto |
| 2026-11-09 | design | /code-review cleanups: the test addon's layout check repeats the rule for which control draws a With; `IsSelectButton` asked in three places | leave both: the test keeps its own reading on purpose, and three short branches read more plainly than a stored control | - | auto |
| 2026-11-09 | design | Taint review's test gap: the globals step with a dropdown-and-button row drawn | no change: every option row builds its button when it is made, and its `$parentText` is the global the row's text button already writes | - | auto |
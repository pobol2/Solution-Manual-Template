# Completion tracking

[Back to README](../README.md)

Turn it on in the preamble:

```tex
\SolutionManualSetup{completion tracking=true}
```

A problem or part is **done** when its solution is not empty. Otherwise it is
**not done**, even if it has an answer. Unfinished problems and parts show a
small "Not done" in their title and in the contents; finished ones show
nothing. Without completion tracking, no marker, overview or report appears,
and `[done]` and `[not done]` have no effect.

An optional argument overrides the automatic status:

```tex
\begin{problem}[not done]{Question.}{Partial solution.}{}\end{problem}
\begin{subproblem}[done]{Question.}{}{Answer only, on purpose.}\end{subproblem}
```

A problem with parts is done when all its parts are done: its own solution,
usually empty, does not matter, but `[not done]` on it keeps it unfinished.
Each problem counts once, parts or not, in its own chapter and subdivisions.
Headings without problems are not counted.

`\completionoverview` adds a linked overview with done/total counts for the
manual, each chapter and each subdivision that has problems, and the
unfinished problems under each heading, e.g. "Not done: Problem 2 (b, c)".
Place it after `\tableofcontents`, or at the end of the manual, where it is
complete after a single compilation.

With `solutions=hidden`, `answers only` or `answers at end`, the PDF omits all
"Not done" markers (including in the contents) and `\completionoverview`.
Set `completion markers=true` to display them, or `completion markers=false`
to suppress them even in `shown` mode. Completion tracking must still be on.
The `show solution` option for a worked example does not enable markers.
Completion status continues to use the source solution, so hiding a solution
does not mark it unfinished. The Markdown report and JSON export retain the
same records and statuses; JSON page ranges follow the edition's printed pages
(with `answers at end`, the pages of the questions, not of the solutions part).

## Markdown report

The build also writes `COMPLETION.md` in the project root, from the same data:
a summary line and a table to link from a repository README, or to
[insert into it](#report-in-a-readme) (see the example's
[`COMPLETION.md`](../COMPLETION.md)). There is no list or count to maintain: run
`latexmk` to refresh the PDF and the report.

The report reflects the latest compilation. The contents markers, the markers
of problems with parts and an overview at the start of the manual use the
previous one, so they need a second pass, which `latexmk` runs automatically;
with plain `pdflatex`, run it twice (LaTeX warns "Completion data may have
changed" when needed). The report is written to `build/main-completion.md` and
copied to the root when it has changed. To keep it in `build/` only, add
`$completion_report = '';` to the project's `latexmkrc`; give another file name
to rename it. Turning completion tracking off leaves the last `COMPLETION.md`
in place: delete it if it is no longer wanted.

## JSON problem index

With completion tracking on, the class also writes
`build/<jobname>-problems.json` (`build/main-problems.json` for `main.tex`).
It uses the same problem records and completion rules as the Markdown report.
The file is UTF-8 JSON with the `language` and `labels` of the manual, and a
`problems` array, in document order:

```json
{
  "language": "english",
  "labels": {
    "title_prefix": "Solutions to",
    "problem_label": "Problem",
    "not_done_label": "Not done",
    "done_label": "Done",
    ...
  },
  "problems": [
    {
      "anchor": "ProblemNum.1.1.0.1",
      "number": "1",
      "unit": "§9",
      "heading_title": "Oscillations",
      "title": "Period of a simple pendulum",
      "status": "not done",
      "first_page": "4",
      "last_page": "6",
      "parts": [
        {
          "anchor": "SubProblemNum.1.1.0.1.1",
          "number": "(a)",
          "title": "Small-angle approximation",
          "status": "done"
        }
      ]
    }
  ]
}
```

`language` is the value of the [`language`](customization.md#languages) key.
`labels` holds every text label in use, after the keys that override the
language: each one is named after its setup key, with `_` for spaces
(`title_prefix`, `author_label`, `by_label`, `page_label`, `page_of_label`,
`contents_label`, `chapter_label`, `problem_label`, `solution_label`,
`answer_label`, `verification_label`, `solutions_title`,
`solution_link_label`, `chapter_abbreviation`, `section_abbreviation`,
`problem_abbreviation`, `not_done_label`, `done_label`, `completion_title`,
`completion_total_label`, `outside_chapters_label` and `colon`). A
non-breaking space `~` becomes a plain space (`"Solution :"`). Show `status`
with `done_label` or `not_done_label`.

`number` is the displayed problem number. `unit` is the displayed numbering
unit used by `\probref`: the chapter in chapter/continuous mode, or the section
or subsection in subdivision mode. `heading_title` is that unit's title;
both are empty outside chapters. `title` is the optional problem or part
title, or an empty string. Text is purified as for the Markdown report, with
JSON escaping for quotes, backslashes and control characters; non-ASCII
characters stay UTF-8. Status is always `"done"` or `"not done"`.

Page labels are strings, so Roman numerals work too. The range includes the
problem's solution, answer, verification and parts. Page markers travel with
the typeset content; the index is written after the final page and auxiliary
data have been processed, using the current compilation's pages. A problem
with no parts has `"parts": []`; a manual with no problems has
`"problems": []`.

The JSON stays in `build/` by default. To copy it to the project root after
a successful build, add this to the project's `latexmkrc`:

```perl
$problems_json = 'PROBLEMS.json';  # '' (default) means no root copy
```

Like `COMPLETION.md`, it is copied only when its contents change, and
`$copy_to_root = 0;` disables the copy. Turning tracking off stops JSON
generation and leaves existing files in place; remove them if no longer
wanted.

## Report in a README

The build can also put the report inside a Markdown file, such as the
project's `README.md`. Add these two lines where the report goes:

```markdown
<!-- completion report: begin -->
<!-- completion report: end -->
```

and name the file in the project's `latexmkrc`:

```perl
$completion_readme = 'README.md';  # the report goes between the markers
$completion_report = '';           # optional: no separate COMPLETION.md
```

After each successful build, the text between the markers is replaced with the
report; the markers stay. Each marker must be alone on its line; markers in
fenced code blocks, like the ones above, are ignored. The file keeps its line
endings and is rewritten only when the report has changed. If a marker is
missing, `latexmk` warns and leaves the file unchanged; the build still
succeeds. `$completion_report` works as before, so without
`$completion_report = ''` the build writes both.

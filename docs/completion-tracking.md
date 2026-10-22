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
The file is UTF-8 JSON with the `language` and `labels` of the manual, its
`solutions` mode, `theme_color` and page `layout`, a `headings` array and a
`problems` array, in document order. The [website builder](website.md) reads
it.

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
  "solutions": "shown",
  "theme_color": "#800000",
  "layout": {
    "paper_width": 595.2756,
    "paper_height": 841.88977,
    "margin_top": 73.85493,
    "margin_bottom": 67.87735,
    "margin_left": 70.86613,
    "margin_right": 70.86613
  },
  "headings": [
    {
      "serial": 1,
      "id": "c1",
      "level": "chapter",
      "number": "1",
      "title": "Oscillations",
      "anchor": "chapter.1"
    },
    {
      "serial": 2,
      "id": "s9",
      "level": "section",
      "number": "§9",
      "title": "Small oscillations",
      "anchor": "section.1.1"
    }
  ],
  "problems": [
    {
      "id": "s9-p1",
      "anchor": "ProblemNum.1.1.0.1",
      "number": "1",
      "reference": "§9.1",
      "unit": "§9",
      "heading_title": "Small oscillations",
      "title": "Period of a simple pendulum",
      "status": "not done",
      "chapter": 1,
      "section": 2,
      "subsection": null,
      "first_page": "4",
      "last_page": "6",
      "first_pdf_page": 6,
      "last_pdf_page": 8,
      "parts": [
        {
          "id": "s9-p1a",
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

`solutions` is the [solutions mode](writing-problems.md) of the PDF: `shown`,
`hidden`, `answers only` or `answers at end`. `theme_color` is `ThemeColor` as
`#RRGGBB`. `layout` gives the paper size and the margins of the text area
(header and footer excluded) of odd pages, in PDF points (1/72 inch), at the
end of the document.

`headings` lists the numbered chapters, sections and subsections (starred
headings are not numbered), with or without problems. `serial` numbers them
from 1 in document order, `level` is `chapter`, `section` or `subsection`,
`number` is the displayed number (a textbook number such as `§9` too), and
`anchor` is the hyperref anchor of the heading in the PDF. `id` is the
heading's [ID](#problem-ids).

In a problem, `number` is the displayed problem number and `reference` the
full number that `\ref` gives. `unit` is the displayed numbering unit used by
`\probref`: the chapter in chapter/continuous mode, or the section or
subsection in subdivision mode. `heading_title` is that unit's title; both are
empty outside chapters. `chapter`, `section` and `subsection` are the
`serial` of the headings the problem is in, or `null`. `title` is the optional
problem or part title, or an empty string. Text is purified as for the
Markdown report, with JSON escaping for quotes, backslashes and control
characters; non-ASCII characters stay UTF-8. Status is always `"done"` or
`"not done"`.

`first_page` and `last_page` are page labels, as printed: strings, so Roman
numerals work too. `first_pdf_page` and `last_pdf_page` are the same pages
counted from 1 in the PDF, whatever their labels. The range includes the
problem's solution, answer, verification and parts. Page markers travel with
the typeset content; the index is written after the final page and auxiliary
data have been processed, using the current compilation's pages. A problem
with no parts has `"parts": []`; a manual with no problems has
`"headings": []` or only headings, and `"problems": []`.

### Problem IDs

Each problem has an `id` made from the number of its numbering unit and its
own number: `s9-p3` for §9 Problem 3 (a textbook number), `c2-p3` for
Problem 3 of chapter 2, `3-1-p2` for Problem 2 of section 3.1, `p47` for
Problem 47 in continuous numbering (and outside chapters). A part adds its
letter: `s9-p3a`. Heading IDs are the same without the problem: `s9`, `3-1`,
and `c2` for a chapter. IDs are lower case, with `s` for a section sign and
`-` for any other character. They depend only on numbers, so they do not
change when a problem is solved or its pages move; see [Problem
IDs](website.md#problem-ids) for when they do.

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

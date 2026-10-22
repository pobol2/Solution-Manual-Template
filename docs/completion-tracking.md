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

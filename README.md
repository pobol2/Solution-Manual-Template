# Solution Manual Template

A LaTeX framework for writing a solution manual for any textbook or subject:
problem, solution and answer boxes, standalone TikZ figures, and one `latexmk`
build that compiles the manual and its figures incrementally.

```
solution-manual/        Shared framework (classes, build rules): never edited by a project
latexmkrc               Project build file: loads solution-manual/latexmkrc
.vscode/settings.json   LaTeX Workshop settings
main.tex                Class options, titles, author, appearance, chapters
mypackages.sty          Packages of the manual
mycommands.sty          Commands of the manual
myfigures.sty           Packages, colors and TikZ styles of the figures
Chapters/, Figures/     Example content: replace it with your own
```

## Setup

Install a TeX distribution (MiKTeX or TeX Live) with pdfLaTeX, LuaLaTeX and
`latexmk`, and Perl (on Windows, e.g. Strawberry Perl). Install any missing
packages through the distribution's package manager, or allow MiKTeX to install
them when prompted. For VS Code, install the LaTeX Workshop extension.

To start a manual, set the titles and author in `main.tex`, then replace the
example chapters and figures.

## Compiling

From the project root, run

```sh
latexmk
```

or, in VS Code, **LaTeX Workshop: Build LaTeX project** (or save a file). Both
run the same command with the same options, from `latexmkrc`:

- pdfLaTeX compiles the manual, with SyncTeX, as many times as needed;
- LuaLaTeX compiles each figure used by the manual when its PDF is missing or
  out of date. A figure is rebuilt when its source, or a file of the project or
  framework that it reads (`SolutionFigure.cls`, `myfigures.sty`, an `\input`
  data file, ...), changes; unchanged figures are reused;
- the finished PDF is copied to the project root.

| Location             | Contents                                                    |
| -------------------- | ----------------------------------------------------------- |
| `main.pdf`           | The finished manual: the only generated file in the root    |
| `Figures/<name>.pdf` | Generated figures                                           |
| `build/`             | Everything else: `main.log`, `main.synctex.gz`, `main.pdf`, ... |
| `build/figures-aux/` | Compilation files of the figures (look here when a figure fails) |

`build/` and `Figures/*.pdf` are ignored by Git. The root `main.pdf` is kept in
the repository as a preview of the examples; rebuilding refreshes it.

For a clean build, remove `build/` and only the generated figure PDFs that have
a matching `.tex` source, then run `latexmk` again. Keep any imported PDF
illustrations that have no matching source file.

In VS Code, the viewer shows `build/main.pdf`, next to its SyncTeX file:
forward search and Ctrl+click inverse search work as usual. Each figure starts
with `% !TEX root = ../main.tex`, so that saving a figure builds the manual
(and therefore the figure); keep this line in new figures. If you change
`$out_dir` in `latexmkrc`, change `outDir` and `auxDir` in
`.vscode/settings.json` to match.

## Writing problems

```tex
\begin{problem}
{Question.}
{Worked solution.}
{Final answer.}
\end{problem}
```

The solution and the answer are optional: leave either argument empty (`{}`)
to omit it. For a problem in parts, give the main question with `{}{}`, then
add `subproblem` environments, which take the same three arguments:

```tex
\begin{problem}{Main question.}{}{}\end{problem}
\begin{subproblem}{Part (a).}{Solution.}{Answer.}\end{subproblem}
\begin{subproblem}{Part (b), a proof.}{Proof.}{}\end{subproblem}
```

Problems are numbered within chapters and start on a new page; questions can
span several pages, and an answer box is kept on the page where its solution
ends. Final-answer boxes stay whole, so their contents must fit on one page.
Long solutions can paginate between text and displayed equations. Arguments can
contain displayed equations (`align`, ...),
figures and tables, but not verbatim text.

References:

- `\label` in a question, then `\ref`: `1.2` for a problem, `1.2(a)` for a
  subproblem;
- `\probref{1}{2}`: a link "Chap. 1 Prob. 2" (no label needed);
- equations and figures: the usual `\label`, `\eqref` and `\ref`.

`Chapters/` shows every case: ordinary problems, subproblems with and without
solution or answer, a question alone, equations, figures, a table and
references across chapters.

## Customization

Customize the manual from the project files only.

**Class options** in `main.tex` (`12pt`, `twoside`, ...) are passed to the
`report` class.

**`\SolutionManualSetup{...}`**, in the preamble of `main.tex`:

| Key                    | Default                                  |
| ---------------------- | ---------------------------------------- |
| `author`               | empty                                    |
| `title`                | empty                                    |
| `subtitle`             | empty (the line is then omitted)         |
| `title prefix`         | `Solutions to`                           |
| `date`                 | `\today`                                 |
| `author label`         | `Author`                                 |
| `contents label`       | `Table of Contents`                      |
| `problem label`        | `Problem`                                |
| `solution label`       | `Solution:`                              |
| `answer label`         | `Answer to Problem`                      |
| `footer`               | title prefix, title and `by` author      |
| `theme color`          | `red!50!black` (titles, links, answers)  |
| `question background`  | `gray!5!white`                           |
| `question frame`       | `gray!50!black`                          |
| `subquestion frame`    | `gray!75!black`                          |
| `answer background`    | `ThemeColor!5!white`                     |
| `answer frame`         | `ThemeColor`                             |
| `subanswer frame`      | `ThemeColor`                             |
| `layout`               | `a4paper, margin=25mm` (any `geometry` options) |
| `problem on new page`  | `true`                                   |

Colors accept any `xcolor` expression. The older
`\def\authorName{...}`, `\def\firstTitle{...}` and `\def\mainTitle{...}`
also work. Other texts come from standard LaTeX commands: `\chaptername`, and
`\probref` (`\renewcommand{\probref}[2]{...}`).

Earlier versions of the manual class ignored font-size options. This version
honors them: an existing document requesting `12pt` may become larger even
though its source has not changed. Choose `10pt` explicitly to retain the old
effective text size, or review the layout after choosing a larger size.

**Packages and commands** go in `mypackages.sty` and `mycommands.sty`, which
`main.tex` loads.

## Figures

Each figure is a standalone document, `Figures/<name>.tex`:

```tex
% !TEX root = ../main.tex
\documentclass[12pt]{SolutionFigure} % same font size as main.tex

\begin{document}
\begin{tikzpicture}
    \draw[axis] (0, 0) -- (3, 0) node[axis label, right] {$x$};
    \draw[curve, domain=0:2.5] plot (\x, {0.4*\x*\x});
\end{tikzpicture}
\end{document}
```

Include it from a chapter at its natural size, so that its text matches the
manual, and with the `Figures/` path, so that `latexmk` finds its source:

```tex
\begin{figure}[H]
    \centering
    \includegraphics{Figures/name.pdf}
    \caption{...}\label{fig:name}
\end{figure}
```

The examples are `RightTriangle.tex` (angles, dimensions), `Tangent.tex`
(axes, ticks, grid, curve, region, tangent) and `Euclid.tex` (flowchart).

`SolutionFigure.cls` loads the TikZ libraries `arrows.meta`, `calc`, `angles`,
`quotes`, `positioning` and `shapes.geometric`, and defines the styles

| Styles                                          | Use                                  |
| ----------------------------------------------- | ------------------------------------ |
| `diagram node`, `decision node`, `diagram arrow` | Diagrams and flowcharts             |
| `axis`, `axis label`, `tick`, `grid lines`      | Axes and grids                       |
| `guide`                                         | Dashed construction lines            |
| `curve`, `highlight`, `region`                  | Graphs, emphasized lines, shaded areas |
| `point`, `vector`                               | Points and arrows                    |
| `angle arc`, `right angle mark`                 | `\draw pic[angle arc, "$\theta$"] {angle = A--O--B};` |
| `dimension`                                     | Length between two marks             |
| `annotation`                                    | Small gray text                      |

and the colors `FigureAccent` (`red!50!black`), `FigureGuide` (`black!50`)
and `FigureFill` (`FigureAccent!12`).

**`myfigures.sty`**, loaded by every figure, holds the project's packages,
colors (e.g. `\colorlet{FigureAccent}{...}` to match a new theme color) and
styles. It can also load project code, such as a Lua file, through
`\directlua` (call `kpse.record_input_file` on the file so that changes to it
rebuild the figures). Changing `myfigures.sty` rebuilds every figure.

PNG, JPEG or PDF illustrations without a `.tex` source can also go in
`Figures/`; add such a PDF to Git with `git add -f`.

## Using the framework in another project

See [`solution-manual/README.md`](solution-manual/README.md).

## Example project

[Mechanics-Landau-Solution](https://github.com/pobol2/Mechanics-Landau-Solution)
is a real solution-manual project built on this template,
with subject-specific TikZ diagrams and numerical field tools for its figures. The template stays general:
specialized extensions like these belong in each manual's own files
(`mycommands.sty`, `myfigures.sty`, companion Lua files), not in
`solution-manual/`.

## License

Copyright (c) 2026 P.O. Bolduc. The original framework, build scripts,
documentation and examples in this repository are licensed under the
[MIT License](LICENSE). You may reuse, modify and redistribute them, including
commercially, provided you retain the copyright and license notices.

Using this framework does not require you to license your own manual under
MIT. Choose a license for your own content and clearly identify any material
owned by others. Third-party packages and other dependencies retain their own
licenses.

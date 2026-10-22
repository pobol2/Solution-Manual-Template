# Customization

[Back to README](../README.md)

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
| `date`                 | month and year of the build, e.g. `October 2026` (`date=\today` for the full date, as before 1.1.0) |
| `author label`         | `Author`                                 |
| `contents label`       | `Table of Contents`                      |
| `problem label`        | `Problem`                                |
| `solution label`       | `Solution:`                              |
| `answer label`         | `Answer to Problem`                      |
| `verification label`   | `Verification:`                          |
| `footer`               | title prefix, title and `by` author      |
| `theme color`          | `ThemeColor` of `mytheme.sty` (titles, links, answers; manual only) |
| `question background`  | `gray!5!white`                           |
| `question frame`       | `gray!50!black`                          |
| `subquestion frame`    | `gray!75!black`                          |
| `answer background`    | `ThemeColor!5!white`                     |
| `answer frame`         | `ThemeColor`                             |
| `subanswer frame`      | `ThemeColor`                             |
| `layout`               | `a4paper, margin=25mm` (any `geometry` options) |
| `problem on new page`  | `true`                                   |
| `problem numbering`    | `chapter` (or `subdivision`, `continuous`) |
| `chapter abbreviation` | `Chap.` (`\probref`)                     |
| `section abbreviation` | `Sec.` (`\probref`)                      |
| `problem abbreviation` | `Prob.` (`\probref`)                     |
| `completion tracking`  | `false`                                  |
| `not done label`       | `Not done`                               |
| `done label`           | `Done` (report column)                   |
| `completion title`     | `Completion` (overview and report)       |
| `completion total label` | `All problems`                         |

Colors accept any `xcolor` expression. Other texts come from standard LaTeX
commands: `\chaptername`.

**Title and author in other settings**: `\authorName`, `\mainTitle` and
`\firstTitle` (the subtitle) hold the values of `author`, `title` and
`subtitle`. Use them wherever a setting needs the title or author, for example
`footer={Solution to \mainTitle~by \authorName}`. Setting them with
`\def\authorName{...}`, `\def\mainTitle{...}` and `\def\firstTitle{...}` still
works.

**Theme color**: set it once in the optional `mytheme.sty`, which both classes
load, so the manual and the figures stay matched:

```tex
\colorlet{ThemeColor}{blue!50!black}
```

Changing it rebuilds the manual and every figure. Without the file, the theme
color is `red!50!black`. The `theme color` key above changes the manual only.

**Packages and commands** go in `mypackages.sty` and `mycommands.sty`, which
`main.tex` loads.

## Build settings

Build settings go at the end of the project's `latexmkrc`:

| Variable             | Default                                                   |
| -------------------- | --------------------------------------------------------- |
| `$completion_report` | `'COMPLETION.md'` (copy of the report; `''` for none)      |
| `$completion_readme` | `''` (Markdown file to [insert the report into](completion-tracking.md#report-in-a-readme), e.g. `'README.md'`) |

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
  framework that it reads (`SolutionFigure.cls`, `mytheme.sty`, `myfigures.sty`,
  an `\input` data file or CSV), changes; unchanged figures are reused;
- the finished PDF is copied to the project root, with the completion report
  `COMPLETION.md` when [completion tracking](completion-tracking.md) is on (the
  report can also be [inserted into a README](completion-tracking.md#report-in-a-readme)).

| Location             | Contents                                                    |
| -------------------- | ----------------------------------------------------------- |
| `main.pdf`           | The finished manual                                         |
| `COMPLETION.md`      | Completion report (only with completion tracking)           |
| `Figures/<name>.pdf` | Generated figures                                           |
| `build/`             | Everything else: `main.log`, `main.synctex.gz`, `main.pdf`, ... |
| `build/figures-aux/` | Compilation files of the figures (look here when a figure fails) |

`build/` and `Figures/*.pdf` are ignored by Git. The root `main.pdf` and
`COMPLETION.md` are kept in the repository as previews of the starter;
rebuilding refreshes them.

The full showcase has its own [`main.tex`](../examples/showcase/main.tex),
chapter and figure folders, and customization files. It shares only
`solution-manual/` with the starter. To build it, run:

```sh
cd examples/showcase
latexmk
```

Its [`latexmkrc`](../examples/showcase/latexmkrc) sets
`$framework_dir = '../../solution-manual';`; all its outputs stay inside
`examples/showcase/`. The README images are rendered from this project's PDF.
CI builds both projects and uploads `starter.pdf` and `showcase.pdf` artifacts.
The separate report job checks the starter's `COMPLETION.md` only in the
template repository; its workflow comment explains how to enable it elsewhere.

For a clean build, remove `build/` and only the generated figure PDFs that have
a matching `.tex` source, then run `latexmk` again. Keep any imported PDF
illustrations that have no matching source file.

In VS Code, the viewer shows `build/main.pdf`, next to its SyncTeX file:
forward search and Ctrl+click inverse search work as usual. Each figure starts
with `% !TEX root = ../main.tex`, so that saving a figure builds the manual
(and therefore the figure); keep this line in new figures. If you change
`$out_dir` in `latexmkrc`, change `outDir` and `auxDir` in
`.vscode/settings.json` to match.

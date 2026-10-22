# Showcase

The complete feature demonstration for the [Solution Manual Template](../../README.md).
The root of the repository is a minimal starter; this project keeps the longer
examples, figures and CSV data together.

From this directory, run:

```sh
latexmk
```

The project has its own `main.tex`, `Chapters/`, `Figures/`, `mypackages.sty`,
`mycommands.sty`, `myfigures.sty` and `mytheme.sty`. Its `latexmkrc` loads the
shared framework with `$framework_dir = '../../solution-manual';`. Run the
build here so figure and data paths resolve relative to this directory.

- [Basic problems](Chapters/1-Basics.tex): solutions, answers and verification.
- [Figures and references](Chapters/2-Figures.tex): diagrams, plots, tables and CSV data.
- [Sections and progress](Chapters/3-Sections.tex): numbering and completion tracking.
- [Showcase](Chapters/4-Showcase.tex): most features combined on one page.

The build writes `main.pdf`, `COMPLETION.md`, `Figures/*.pdf` and `build/` here.
The previews in the root README are rendered from this project's title page,
table of contents and final problem page.

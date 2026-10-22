# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-22

### Added

- An **Open in Overleaf** button and setup and troubleshooting documentation
  covering precompiled figures, free-plan compile timeouts and opening
  `main.tex` before Recompile.
- `$copy_to_root` build setting (default `1`); set it to `0` to skip the
  post-build root-copy hook on Overleaf, including completion report updates.

### Changed

- The README presents **Use this template** as the standard self-contained
  setup, with release ZIP update instructions; the advanced submodule guide
  uses the repository URL and shows pinning a release tag.
- `SolutionFigure.cls` stops when run without LuaLaTeX and explains how to
  compile the manual with `latexmk`, including the Overleaf open-file workflow.

## [1.1.0] - 2026-10-21

### Changed

- The default `date` on the title page is now the month and year of the build,
  e.g. "October 2026", instead of the full date of `\today`. Set
  `\SolutionManualSetup{date=\today}` to keep the previous behaviour; any other
  date can still be given with `date=...`.

## [1.0.0] - 2026-10-21

### Added

- `SolutionManual` class: title page, table of contents, running headers and
  footers, and `problem` and `subproblem` environments with question, solution,
  answer box and optional verification, each omitted when blank.
- Problems grouped by `\chapter`, `\section` and `\subsection`, with
  `chapter`, `subdivision` or `continuous` problem numbering, textbook numbers
  (`\textbooknumber`), nested contents and bookmarks, and `\probref` links.
- Completion tracking: "Not done" markers, `[done]` / `[not done]` overrides,
  a linked `\completionoverview`, and a Markdown report (`COMPLETION.md`) that
  can also be inserted into a README.
- `\SolutionManualSetup` keys for titles, author, date, labels, footer,
  colors, page layout and problem layout; a shared theme color in
  `mytheme.sty`.
- `SolutionFigure` class for standalone TikZ and PGFPlots figures, with shared
  styles, plot sizes, subplot grids and CSV data.
- `latexmk` build that compiles the manual with pdfLaTeX and each figure with
  LuaLaTeX, incrementally, and LaTeX Workshop settings for VS Code.
- Continuous integration that builds the example manual and checks
  `COMPLETION.md`.

[1.2.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pobol2/Solution-Manual-Template/releases/tag/v1.0.0

# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pobol2/Solution-Manual-Template/releases/tag/v1.0.0

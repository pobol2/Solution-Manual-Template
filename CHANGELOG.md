# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-10-22

### Added

- Optional `title={...}` in `problem` and `subproblem`, alone or combined
  with the existing `done` / `not done` status options. Titles appear in
  question headings, PDF bookmarks and contents; titled parts gain their
  own navigation entries. Untitled output remains unchanged.
- `problem titles in contents` setup key (default `true`); set it to
  `false` for plain problem entries and no part entries in the contents,
  while retaining titles in headings and bookmarks.
- Showcase examples for problem and part titles.
- An `l3build` regression suite with saved results for blank arguments,
  completion states and parts, verification brackets, numbering, textbook
  numbers, references, mixed-level errors, titles, completion reports and
  JSON exports, plus a figure-class smoke test. CI runs `l3build check`;
  `docs/contributing.md` explains how to run and update the tests.
- UTF-8 `build/<jobname>-problems.json` with completion tracking: problem
  anchors, displayed numbers and numbering units, heading and problem titles,
  statuses, current page ranges and parts. The optional `$problems_json`
  latexmk setting copies it to the project root (default `''`: no copy).

### Fixed

- Regression CI uses the Debian TeX Live image with GNU diff; Alpine's
  BusyBox diff does not support the `-c` option used by `l3build check`.

## [1.2.0] - 2026-10-22

### Added

- A minimal starter in the repository root and a separate full feature
  demonstration in `examples/showcase/`.
- A `docs/` guide covering writing problems, numbering and references,
  figures, completion tracking, customization and advanced submodule use.
- Troubleshooting for missing classes and packages, figure builds, compiler
  selection, Perl, completion reports, verification brackets and Overleaf.
- Overleaf support with an **Open in Overleaf** badge, setup instructions,
  precompiled figure PDFs and guidance for free-plan compile timeouts and
  opening `main.tex` before Recompile.
- `$copy_to_root` build setting (default `1`); set it to `0` to skip the
  post-build root-copy hook on Overleaf, including completion report updates.
- CI checks that both class versions match the top changelog version.
- A release workflow for `v*` tags that checks versions, builds both manuals
  cleanly and publishes notes from the matching changelog section, with
  `main.pdf` (starter), `showcase.pdf`, `solution-manual-<tag>.zip` (framework
  only), `overleaf-starter.zip` and `overleaf-showcase.zip`. The Overleaf
  archives include the framework, precompiled figures and a standalone
  `latexmkrc` with `$copy_to_root = 0`.

### Changed

- The README quick start presents **Use this template** as the standard
  self-contained setup, with release ZIP update instructions and a link to
  the Overleaf guide. Submodules are an advanced path, with the repository
  URL and an example of pinning a release tag.
- CI builds the starter and showcase separately, uploads both PDF previews
  and checks the starter's completion report.
- Both class declarations now use version `v1.2.0` and the release date.
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

[1.3.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/pobol2/Solution-Manual-Template/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pobol2/Solution-Manual-Template/releases/tag/v1.0.0

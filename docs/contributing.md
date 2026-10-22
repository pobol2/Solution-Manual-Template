# Contributing

[Back to README](../README.md)

The shared classes have focused regression tests in [`testfiles/`](../testfiles/),
configured by [`build.lua`](../build.lua). Install a current TeX Live, MacTeX or
MiKTeX with `l3build`, LuaLaTeX and the classes' dependencies. On MiKTeX, install
the `l3build` package if needed. Both classes are tested with LuaLaTeX because
`SolutionFigure` requires it; each test runs twice for references and completion
data to settle. Tests load the classes directly without the starter's `my*.sty`.

From the repository root, run:

```sh
l3build check
```

To run just one behavior:

```sh
l3build check subproblem-completion
```

Each `.lvt` exercises one behavior through the class's public commands. Its
saved `.tlg` records the expected semantic output, warnings or error message,
and compilation exit statuses. The small observer helpers live in
[`testfiles/support/sm-test.tex`](../testfiles/support/sm-test.tex). The mixed-level
test captures the expected class error so it can check the message and help;
unexpected TeX errors still fail the suite. The report test reads the actual
Markdown file after the end-document hook has written it.

For a new test, add a focused `.lvt`, then generate its baseline. For an
intentional behavior change, inspect the failing `.diff` first, then update
only the affected baseline:

```sh
l3build save subproblem-completion
l3build check
```

Review the generated `.tlg` before including it with the change; saving records
the current output, including mistakes. Do not save new baselines just to clear
a failure. Logs, normalized results and `.diff` files are under
`build/l3build/test/`. `l3build clean` removes the test build files without
removing the manual's other `build/` outputs. CI runs the same `l3build check`
command and uploads diagnostics on failure.

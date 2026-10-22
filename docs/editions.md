# Editions

[Back to README](../README.md)

An edition is another PDF of the same sources in another
[solutions mode](writing-problems.md), for example an exercise book with the
questions only and an answer book with the final answers, built next to
`main.pdf` by the same `latexmk` command.

## Setting up editions

List the editions at the end of the project's `latexmkrc`, after the line that
loads the shared rules. Each one has a file name and a `solutions` mode:

```perl
%editions = ( exercises => 'hidden', answers => 'answers only' );
```

The modes are those of the `solutions` key: `shown`, `hidden`, `answers only`
and `answers at end`. Names use letters, digits, `-` and `_`, and cannot be
the name of the manual (`main`). The default, `%editions = ();`, builds the
manual alone.

Run `latexmk` as usual. After a successful build of `main.pdf`, each edition
is built in turn and, like `main.pdf`, copied to the project root:

| Location                 | Contents                                       |
| ------------------------ | ---------------------------------------------- |
| `exercises.pdf`          | Edition `exercises` (copy of `build/exercises.pdf`) |
| `answers.pdf`            | Edition `answers` (copy of `build/answers.pdf`)     |
| `build/<name>.*`         | Compilation files of each edition (`<name>.log`, ...) |

The [showcase project](../examples/showcase/) builds these two editions, and
CI uploads them as the `showcase-exercises.pdf` and `showcase-answers.pdf`
artifacts.

## How editions are built

Each edition is one extra `latexmk` job in the same project, with
`-jobname=<name>` and pre-TeX code that defines `\SolutionManualSolutions`
(e.g. `hidden`) before `main.tex` is read. The class sets that mode before
`\SolutionManualSetup`, and ignores any `solutions=...` in `main.tex` (the
edition's log notes it), so `main.tex` stays the same for every PDF.

- **Figures** are shared: the manual's build compiles them first, and the
  editions reuse `Figures/*.pdf`.
- **Completion report and JSON index**: only the manual's are copied to the
  project root. The editions write their own (`build/<name>-completion.md`,
  ...), which stay in `build/`. Completion status never depends on the mode.
- **Rebuilds**: an edition is recompiled when its sources change, or when its
  mode changes in `latexmkrc`; otherwise its job ends at once. A failed edition
  gives a warning that names its log, `build/<name>.log`, and does not stop the
  other editions.

Each edition compiles the whole manual again, so a change takes longer to
build. To build `main.pdf` alone while writing, comment out the `%editions`
line, or run:

```sh
latexmk -e '%editions=()'
```

(On Windows `cmd`, use double quotes: `latexmk -e "%editions=()"`.)

With `$copy_to_root = 0`, the editions are still built but stay in `build/`.
On Overleaf, keep `%editions` empty: each edition adds a full compilation to
the compile time limit.

## References in student editions

In `hidden` and `answers only` editions, labels inside omitted solutions do not
exist. A question that refers to an equation or a figure of a solution prints
"??" there, with an undefined reference warning in `build/<name>.log`. Keep
such references in the solutions, or refer to the problem instead (a `\label`
in its question, or `\probref`), which exists in every edition. With
`answers at end`, every reference works.

# Troubleshooting

[Back to README](../README.md)

## File `SolutionManual.cls` not found

**Cause:** Running `pdflatex main.tex` directly, or building from the wrong
folder, bypasses the project's `latexmkrc`. The shared classes are in
`solution-manual/`; the build rules add that folder to `TEXINPUTS`.

**Fix:** Run `latexmk` from the project root: the folder containing its
`main.tex` and `latexmkrc`. For the starter, this is the repository root;
for the showcase, it is `examples/showcase/`.

```sh
latexmk
```

If the class is still missing, check that `$framework_dir` in the project's
`latexmkrc` points to the existing framework folder. See
[Using the framework in another project](advanced-submodule.md).

## A package is missing

**Cause:** The TeX distribution does not have one of the packages loaded by
`SolutionManual.cls`, `SolutionFigure.cls` or the project's style files.

**Fix:** In MiKTeX, click **Install** when the
[missing-package prompt](https://docs.miktex.org/manual/autoinstall.html)
appears. If automatic installation is disabled, install the package through
MiKTeX Console. On TeX Live, run:

```sh
tlmgr install <pkg>
```

Replace `<pkg>` with the TeX Live package name, without angle brackets; it
may differ from the missing file's name. See the
[TeX Live package instructions](https://tug.org/texlive/pkginstall.html).
Then run `latexmk` again.

## A figure is missing or blank

**Cause:** `lualatex` is not installed or cannot be found, or figure
compilation stopped on an error. The manual uses pdfLaTeX, but each standalone
figure uses LuaLaTeX; `SolutionFigure.cls` explicitly requires LuaTeX.

**Fix:** Install LuaLaTeX through your TeX distribution and check that
`lualatex --version` works in the terminal used for the build. Run `latexmk`
from the project root. Read `build/figures-aux/<name>.log` for the first
figure error. If no log was created, check the latexmk output for a missing
executable.

The build rules report a failed figure with this wording (`<name>` is the
figure's basename):

```text
Figure Figures/<name>.tex failed to compile: see build/figures-aux/<name>.log
```

Keep the `Figures/` prefix in `\includegraphics` and a matching `.tex`
source for each generated PDF. Do not add `-halt-on-error` to the manual's
pdfLaTeX pass: it must discover missing figure PDFs before latexmk builds
them. See [Figures](figures.md) for the expected layout.

## VS Code or Overleaf uses XeLaTeX or LuaLaTeX for main.tex

**Cause:** The editor selected another compiler or recipe for the manual.
The project's build rules select pdfLaTeX with `$pdf_mode = 1` and invoke
`lualatex` separately for figures.

**Fix:** In VS Code, select the supplied LaTeX Workshop recipe
**latexmk (latexmkrc)** from [the project settings](../.vscode/settings.json),
and build `main.tex`. Remove any compiler override from a custom recipe.
On Overleaf, open the project settings, choose **Compiler**, and set it to
**pdfLaTeX**; keep `main.tex` as the main document. See
[Overleaf's compiler settings](https://docs.overleaf.com/getting-started/recompiling-your-project/selecting-a-tex-live-version-and-latex-compiler#changing-the-compiler).
The figure build still uses LuaLaTeX through `latexmkrc`.

## Perl is not found on Windows

**Cause:** `latexmk` is a Perl script. MiKTeX's launcher cannot run it when
Perl is missing or unavailable on `PATH`.

**Fix:** Install Strawberry Perl and make its `perl` executable available on
`PATH`. Restart the terminal and VS Code, then check:

```sh
perl --version
latexmk --version
```

Once both commands work, run `latexmk` from the project root.

## Completion data may have changed, or COMPLETION.md is stale

**Cause:** The current problem data differ from the previous pass. The class
emits:

```text
Completion data may have changed. Rerun to get the overview right
```

The PDF overview and markers use the previous pass, while the Markdown report
uses the current one. The build rules copy a nonempty report from
`build/main-completion.md` to `COMPLETION.md` after a successful build;
an interrupted build or a direct pdfLaTeX run can leave the root copy stale.

**Fix:** Run `latexmk` again from the project root and let it complete all
passes. If the report still does not update, check that
`completion tracking=true` and `$completion_report` is not empty. See
[Completion tracking](completion-tracking.md) and
[Build settings](customization.md#build-settings).

## Verification brackets cause a parsing error

**Cause:** An unmatched `[` or `]` inside the final `[Verification.]`
argument can make TeX keep scanning or end the argument early. Both
`problem` and `subproblem` read verification as an optional argument;
balanced nested brackets work.

**Fix:** Wrap the verification contents in braces inside the outer brackets,
for example when using a half-open interval:

```tex
\begin{problem}
{Show that $0$ belongs to $[0,1)$.}
{The left endpoint is included.}
{$0 \in [0,1)$.}
[{Check that $0 \le 0 < 1$, so $0 \in [0,1)$.}]
\end{problem}
```

Place the opening verification bracket on the same line as the answer's
closing brace, or the next line, with no blank line between them. See
[Writing problems](writing-problems.md).

# Using Overleaf

[Back to README](../README.md)

## Getting started

Download `overleaf-starter.zip` from the
[latest GitHub release](https://github.com/pobol2/Solution-Manual-Template/releases/latest)
and upload it as a new Overleaf project, or use the
[**Open in Overleaf**](https://www.overleaf.com/docs?snip_uri=https%3A%2F%2Fgithub.com%2Fpobol2%2FSolution-Manual-Template%2Freleases%2Flatest%2Fdownload%2Foverleaf-starter.zip)
button in the README.
Set **Compiler** to **pdfLaTeX** and **Main document** to `main.tex` in the
project settings. Open `main.tex`, then click **Recompile**.

The archive includes precompiled `Figures/*.pdf`: compiling all the figures
with LuaLaTeX can exceed the free plan's compile time limit. Keep these PDFs
in the project. The build uses them until their sources change; editing one
figure rebuilds only that figure with LuaLaTeX, while the manual still uses
pdfLaTeX.

## Editing and recompiling

Edit the manual's title and author in `main.tex`, problems in `Chapters/`, and
figure sources in `Figures/`. Always open `main.tex` before clicking
**Recompile**, including after editing a figure. Overleaf compiles the open
file when it has `\documentclass`, even if the project's main document is
`main.tex`. A figure opened this way would be compiled with pdfLaTeX instead
of the LuaLaTeX build rule.

If a figure times out, compile the project locally with `latexmk` and upload
the resulting `Figures/<name>.pdf` to the same path in Overleaf, replacing the
old PDF. Open `main.tex` and recompile. See
[Troubleshooting](troubleshooting.md#compile-timed-out-on-overleaf) for timeout
details.

## Build settings

Overleaf already keeps the finished PDF in its output folder. To skip the
post-build root-copy hook, add this at the end of the project's `latexmkrc`:

```perl
$copy_to_root = 0;
```

This also skips copying the completion report and inserting it into a README;
the manual's completion overview still works. Local builds default to
`$copy_to_root = 1`. See [Build settings](customization.md#build-settings).

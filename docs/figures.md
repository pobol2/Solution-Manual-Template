# Figures

[Back to README](../README.md)

Create each figure as `Figures/<name>.tex`, using the same class font size as
`main.tex` (currently `12pt`):

```tex
% !TEX root = ../main.tex
\documentclass[12pt]{SolutionFigure}
\begin{document}
\begin{tikzpicture}
    \draw[axis] (0, 0) -- (3, 0) node[axis label, right] {$x$};
    \draw[curve, domain=0:2.5] plot (\x, {0.4*\x*\x});
\end{tikzpicture}
\end{document}
```

Include its PDF at natural size to preserve text and stroke sizes. Keep the
`Figures/` prefix so the [build rules](customization.md#compiling) can find its source:

```tex
\begin{figure}[H]
    \centering
    \includegraphics{Figures/name.pdf}
    \caption{...}\label{fig:name}
\end{figure}
```

The [showcase](../examples/showcase/) includes these commented figures:

| Source | Demonstrates |
| ------ | ------------ |
| [RightTriangle.tex](../examples/showcase/Figures/RightTriangle.tex) | Geometry, angles and dimensions |
| [Tangent.tex](../examples/showcase/Figures/Tangent.tex) | TikZ axes, grid, curve, shaded region and tangent |
| [Euclid.tex](../examples/showcase/Figures/Euclid.tex) | Flowchart and shared node spacing |
| [Quadratic.tex](../examples/showcase/Figures/Quadratic.tex) | Default plot, centered axes and point markers in a verification |
| [Plots.tex](../examples/showcase/Figures/Plots.tex) | Automatic curve styles, legends, subplots, CSV data and local overrides |

## Shared appearance

`SolutionFigure` loads TikZ (libraries `arrows.meta`, `calc`, `angles`, `quotes`,
`positioning`, `shapes.geometric`) and PGFPlots (`compat=1.18`, `groupplots`).
It crops figures with a 2 pt border and provides these TikZ styles:

| Styles | Use |
| ------ | --- |
| `diagram node`, `decision node`, `diagram arrow` | Flowcharts; default node spacing 7 mm vertically, 12 mm horizontally |
| `axis`, `axis label`, `tick`, `grid lines`, `guide` | Axes, grids and construction lines |
| `curve`, `highlight`, `region` | Curves, emphasized lines and shading |
| `point`, `plot points`, `vector` | TikZ points, plot markers and arrows |
| `angle arc`, `right angle mark`, `dimension` | Angles and lengths |
| `annotation` | Small gray text |

The shared colors are `FigureAccent` (`ThemeColor`, from
[`mytheme.sty`](customization.md)), `FigureGuide` (`black!50`) and `FigureFill`
(`FigureAccent!12`). Set project colors, packages, TikZ styles and PGFPlots
settings in **`myfigures.sty`**, loaded by every figure after `mytheme.sty`; a
`\colorlet{FigureAccent}{...}` there gives the figures a different accent. The
figures do not read `main.tex` or inherit its font settings automatically.

## Plots

Inside `tikzpicture`, use the usual PGFPlots `axis` environment:

```tex
\begin{axis}[xlabel={$x$}, ylabel={$y$}, domain=0:4]
    \addplot {x^2 - 5*x + 6};
\end{axis}
```

Every axis inherits the `plot axes` style: left and bottom axes, outward ticks,
a light major grid, small labels/titles/legends, thick curves and 80 samples.
The four-curve cycle uses accent solid, black dashed, accent dash-dotted and
gray dotted lines. Use `\addplot` or `\addplot+[options]` to keep the cycle;
`\addplot[highlight]` or `\addplot[plot points]` selects an explicit style.

| Axis option | Plotting rectangle (width x height) |
| ----------- | ---------------------------------- |
| none | 9 x 5 cm |
| `small plot` | 6 x 4 cm |
| `wide plot` | 13 x 7 cm |
| `square plot` | 7 x 7 cm |

Sizes apply to the axis rectangle (`scale only axis`); labels and the border
add to the PDF dimensions. A square plot does not imply equal coordinate units.
Use a size option instead of scaling the finished PDF. Local options such as
`grid=none` or `axis lines=middle` override the defaults; ranges, ticks, labels
and legend placement are chosen per figure. Customize all plots in `myfigures.sty`:

```tex
\pgfplotsset{plot axes/.append style={width=10cm, height=6cm}}
\tikzset{node distance=8mm and 14mm}
```

## Subplots and CSV data

`subplot grid` selects 6 x 4 cm panels. The default grid has two columns,
one row, 15 mm gaps, and axis labels on the bottom row and left column:

```tex
\begin{groupplot}[subplot grid, domain=0:1, xlabel={$x$}, ylabel={$y$}]
    \nextgroupplot[title={(a) First}]
        \addplot {x^2};
    \nextgroupplot[title={(b) Second}]
        \addplot {sqrt(x)};
\end{groupplot}
```

Place `groupplot` inside one `tikzpicture`. Shared options go in `groupplot`;
local ones go in `\nextgroupplot[...]`. Panels fill left to right, then top to
bottom, restarting the curve cycle in each panel. Set
`group style={group size=2 by 2}` for four panels. If all panels share scales,
add `xticklabels at=edge bottom, yticklabels at=edge left` inside `group style`
to hide repeated tick labels. Change global spacing in `myfigures.sty` with
`\pgfplotsset{group/horizontal sep=18mm, group/vertical sep=18mm}`.

In the showcase, CSV files use a header and numeric rows, like
[Linear.csv](../examples/showcase/Figures/Data/Linear.csv), with columns `x,measured,reference`.
Select named columns inside an `axis` or after `\nextgroupplot`:

```tex
\addplot table[col sep=comma, x=x, y=reference] {Figures/Data/Linear.csv};
\addplot[plot points] table[col sep=comma, x=x, y=measured]
    {Figures/Data/Linear.csv};
```

The first connects rows in file order; the second draws isolated points. Use
decimal points and one row per observation. For other formats, use
`col sep=semicolon`, or `header=false, x index=0, y index=1` for headerless data.
Paths are relative to the project root. CSV changes rebuild the affected figure
on the next `latexmk` run; no conversion script or extra build rule is needed.

PNG, JPEG and imported PDFs can also go in `Figures/`; use `git add -f` to track
an imported PDF. For companion Lua files, call `kpse.record_input_file` so the
build tracks them too.

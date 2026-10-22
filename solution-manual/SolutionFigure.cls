% SPDX-License-Identifier: MIT
% Copyright (c) 2026 P.O. Bolduc. See ../LICENSE.
%
% ============ Identification ============ %
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{SolutionFigure}[2026/10/22 v1.4.0 TikZ and PGFPlots figures for solution manuals]

% Shared class of the solution-manual framework: do not edit it in a project.
% Each Figures/<name>.tex is a standalone document compiled with LuaLaTeX:
%
%   % !TEX root = ../main.tex
%   \documentclass{SolutionFigure}
%   \begin{document}
%   \begin{tikzpicture}
%       ...
%   \end{tikzpicture}
%   \end{document}
%
% Projects set the theme color shared with the manual in mytheme.sty, and add
% their own packages, colors and styles in myfigures.sty (both in the project
% root, loaded by this class if they exist).

% ============ Options ============ %
% Every option (12pt, border=5pt, ...) is passed to the standalone class.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{standalone}}
\ProcessOptions\relax

% ============ Preliminary declarations ============ %
\RequirePackage{iftex}
\ifLuaTeX\else
    \ClassError{SolutionFigure}{%
        This file is a figure of the manual.\MessageBreak
        Compile main.tex with latexmk.\MessageBreak
        On Overleaf, open main.tex before Recompile%
    }{%
        Figures require LuaLaTeX and are built by latexmk.\MessageBreak
        Overleaf compiles the open file when it has \string\documentclass.%
    }
    \expandafter\@@end
\fi
\LoadClass[tikz, border=2pt]{standalone}
\usetikzlibrary{arrows.meta, calc, angles, quotes, positioning, shapes.geometric}
\RequirePackage{pgfplots}
\pgfplotsset{compat=1.18}
\usepgfplotslibrary{groupplots}

% ============ Language ============ %
% \SolutionManualSetup{language=french} in mytheme.sty sets the language of
% the manual and its figures. Figures read the same SolutionManual-<language>.def
% for its number format (decimal comma, ...) and ignore the other keys.
\pgfqkeys{/SolutionFigure}{
    language/.code={%
        \IfFileExists{SolutionManual-#1.def}{\input{SolutionManual-#1.def}}{%
            \ClassError{SolutionFigure}{Unknown language `#1'}{There is no
                file SolutionManual-#1.def next to SolutionFigure.cls.}}},
    number format/.code={\pgfqkeys{/pgf/number format}{#1}},
    .unknown/.code={}, % keys of the manual only
}
\newcommand{\SolutionManualSetup}[1]{\pgfqkeys{/SolutionFigure}{#1}}
\SolutionManualSetup{language=english}

% ============ Colors ============ %
\colorlet{ThemeColor}{red!50!black}   % same default as SolutionManual.cls
% Theme and language of the manual
\IfFileExists{mytheme.sty}{\RequirePackage{mytheme}}{}
\colorlet{FigureAccent}{ThemeColor}   % highlighted elements
\colorlet{FigureGuide}{black!50}      % axes, construction lines and grids
% FigureFill (shaded regions) is FigureAccent!12, defined after myfigures.sty

% ============ General-purpose styles ============ %
\tikzset{
    >={Latex},
    node distance=7mm and 12mm,
    % --- Diagrams ---
    diagram node/.style={
        draw=FigureAccent, rounded corners=2pt, fill=FigureAccent!5,
        minimum width=2.4cm, minimum height=1cm, align=center,
        inner sep=5pt,
    },
    decision node/.style={
        diagram node, diamond, aspect=2, minimum width=0pt, minimum height=0pt,
        inner sep=2pt,
    },
    diagram arrow/.style={thick, ->},
    % --- Axes, grids and construction lines ---
    axis/.style={draw=FigureGuide, thick, ->},
    axis label/.style={font=\small, inner sep=2pt},
    tick/.style={draw=FigureGuide, thin},
    grid lines/.style={draw=FigureGuide!35, very thin},
    guide/.style={draw=FigureGuide, thin, dashed},
    % --- Curves and regions ---
    curve/.style={thick, line join=round},
    highlight/.style={draw=FigureAccent, very thick},
    region/.style={fill=FigureFill, draw=none},
    % --- Points, vectors, angles and lengths ---
    point/.style={circle, fill, inner sep=0pt, minimum size=1.5mm},
    plot points/.style={only marks, mark=*, mark size=0.75mm, color=FigureAccent},
    vector/.style={thick, -{Latex}},
    angle arc/.style={draw, thin, angle radius=8mm, angle eccentricity=1.3},
    right angle mark/.style={draw, thin, angle radius=2.5mm},
    dimension/.style={thin, |<->|, >={Latex[length=1.5mm]}},
    % --- Annotations ---
    annotation/.style={font=\small, text=FigureGuide, align=center},
}

% PGFPlots defaults, applied to every axis before its local options. Dimensions
% describe the plotting rectangle; labels and the standalone border add space.
% Use \addplot (or \addplot+ with options) to retain the shared curve cycle.
\pgfplotsset{
    plot axes/.style={
        width=9cm, height=5cm,
        scale only axis,
        axis lines=left,
        axis line style={draw=FigureGuide, thick},
        tick align=outside,
        tick pos=left,
        tick style={draw=FigureGuide, thin},
        tick label style={font=\small},
        label style={font=\small},
        title style={font=\small},
        grid=major,
        grid style={draw=FigureGuide!35, very thin},
        legend style={font=\small, draw=FigureGuide!50, fill=white, inner sep=3pt},
        legend cell align=left,
        samples=80,
        every axis plot/.append style={curve, mark size=0.75mm},
        cycle list={
            {color=FigureAccent, solid, mark=none},
            {color=black, dashed, mark=none},
            {color=FigureAccent, dashdotted, mark=none},
            {color=FigureGuide, dotted, mark=none}
        },
    },
    every axis/.append style={plot axes},
    small plot/.style={width=6cm, height=4cm},
    wide plot/.style={width=13cm, height=7cm},
    square plot/.style={width=7cm, height=7cm},
    % Group defaults live here so they are not reapplied inside each panel.
    group/group size=2 by 1,
    group/horizontal sep=15mm,
    group/vertical sep=15mm,
    group/xlabels at=edge bottom,
    group/ylabels at=edge left,
    subplot grid/.style={small plot},
}

% ============ Project styles ============ %
\IfFileExists{myfigures.sty}{\RequirePackage{myfigures}}{}

% Derived colors follow a FigureAccent changed in myfigures.sty, unless the
% project defines them itself
\@ifundefinedcolor{FigureFill}{\colorlet{FigureFill}{FigureAccent!12}}{}

\endinput

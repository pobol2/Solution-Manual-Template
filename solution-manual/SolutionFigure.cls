% ============ Identification ============ %
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{SolutionFigure}[2026/10/16 General TikZ figures for solution manuals]

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
% Projects add their own packages, colors and styles in myfigures.sty (in the
% project root), which is loaded at the end of this class if it exists.

% ============ Options ============ %
% Every option (12pt, border=5pt, ...) is passed to the standalone class.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{standalone}}
\ProcessOptions\relax

% ============ Preliminary declarations ============ %
\LoadClass[tikz, border=2pt]{standalone}
\RequirePackage{iftex}
\RequireLuaTeX
\usetikzlibrary{arrows.meta, calc, angles, quotes, positioning, shapes.geometric}

% ============ Colors ============ %
\colorlet{FigureAccent}{red!50!black} % highlighted elements (ThemeColor of the manual)
\colorlet{FigureGuide}{black!50}      % axes, construction lines and grids
% FigureFill (shaded regions) is FigureAccent!12, defined after myfigures.sty

% ============ General-purpose styles ============ %
\tikzset{
    >={Latex},
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
    vector/.style={thick, -{Latex}},
    angle arc/.style={draw, thin, angle radius=8mm, angle eccentricity=1.3},
    right angle mark/.style={draw, thin, angle radius=2.5mm},
    dimension/.style={thin, |<->|, >={Latex[length=1.5mm]}},
    % --- Annotations ---
    annotation/.style={font=\small, text=FigureGuide, align=center},
}

% ============ Project styles ============ %
\IfFileExists{myfigures.sty}{\RequirePackage{myfigures}}{}

% Derived colors follow a FigureAccent changed in myfigures.sty, unless the
% project defines them itself
\@ifundefinedcolor{FigureFill}{\colorlet{FigureFill}{FigureAccent!12}}{}

\endinput

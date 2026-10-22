% SPDX-License-Identifier: MIT
% Copyright (c) 2026 P.O. Bolduc. See ../LICENSE.
%
% ============ Identification ============ %
\NeedsTeXFormat{LaTeX2e}[2022/06/01] % mark classes, command hooks
\ProvidesClass{SolutionManual}[2026/10/22 v1.3.0 Solution Manual Template]

% Shared class of the solution-manual framework: do not edit it in a project.
% Customize a manual from its preamble instead, with \SolutionManualSetup{...},
% mypackages.sty and mycommands.sty (see README.md).

% ============ Options ============ %
% Every option (12pt, twoside, ...) is passed to the report class.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{report}}
\ProcessOptions\relax

% ============ Preliminary declarations ============ %
\LoadClass{report}

% Packages
\RequirePackage[most]{tcolorbox} % for problem environment
\RequirePackage{graphicx, float} % for figures (float before hyperref)
\RequirePackage{titlesec, xcolor, etoolbox} % for title section
\RequirePackage{geometry} % for page layout
\RequirePackage{tocloft} % for table of contents
\RequirePackage{bold-extra} % for bold + small caps
\RequirePackage{pgfkeys} % for \SolutionManualSetup
\RequirePackage{fancyhdr, lastpage, hyperref} % for headers, footers and links

% ============ Figures path ============ %
\graphicspath{ {./Figures/} } % images folder (in the project)

% ============ Settings ============ %
% Titles and author. They can also be set directly, as in earlier versions:
%   \def\authorName{...}  \def\firstTitle{...}  \def\mainTitle{...}
\def\authorName{}
\def\firstTitle{}
\def\mainTitle{}

% Texts
\newcommand*{\SM@titleprefix}{Solutions to}
\newcommand*{\SM@authorlabel}{Author}
% Month and year of the build, e.g. "October 2026" (date=\today for the day)
\newcommand*{\SM@date}{%
    \ifcase\month\or January\or February\or March\or April\or May\or June\or
    July\or August\or September\or October\or November\or December\fi
    ~\the\year}
\newcommand*{\SM@contentslabel}{Table of Contents}
\newcommand*{\SM@problemlabel}{Problem}
\newcommand*{\SM@solutionlabel}{Solution:}
\newcommand*{\SM@answerlabel}{Answer to Problem}
\newcommand*{\SM@verificationlabel}{Verification:}
\newcommand*{\SM@solutionstitle}{Solutions}
\newcommand*{\SM@sollinklabel}{Solution p.}
\newcommand*{\SM@footer}{%
    \SM@titleprefix~\mainTitle
    \SM@ifnotblank{\authorName}{~by \authorName}}
\newcommand*{\SM@notdonelabel}{Not done}
\newcommand*{\SM@donelabel}{Done}
\newcommand*{\SM@completiontitle}{Completion}
\newcommand*{\SM@totallabel}{All problems}
\newcommand*{\SM@chapabbrev}{Chap.}
\newcommand*{\SM@secabbrev}{Sec.}
\newcommand*{\SM@probabbrev}{Prob.}

% Colors: ThemeColor is a named color; the boxes use color expressions, which
% are evaluated where they are used (so they follow later ThemeColor changes).
\colorlet{ThemeColor}{red!50!black}
% The project's mytheme.sty, if it exists, sets ThemeColor for the manual and
% its figures (SolutionFigure.cls loads it too)
\IfFileExists{mytheme.sty}{\RequirePackage{mytheme}}{}
\newcommand*{\SM@questionback}{gray!5!white}
\newcommand*{\SM@questionframe}{gray!50!black}
\newcommand*{\SM@subquestionframe}{gray!75!black}
\newcommand*{\SM@answerback}{ThemeColor!5!white}
\newcommand*{\SM@answerframe}{ThemeColor}
\newcommand*{\SM@subanswerframe}{ThemeColor}

% Each problem starts on a new page
\newif\ifSM@problemnewpage
\SM@problemnewpagetrue

% Titles appear in the contents by default; untitled parts have no entry.
\newif\ifSM@titlesintoc
\SM@titlesintoctrue

% Problem numbering restarts at each: 0 = never (continuous), 1 = chapter,
% 2 = subdivision (see \SM@setnumbering)
\def\SM@numbering{1}

% Completion tracking (markers, overview and Markdown report)
\newif\ifSM@completion
% Response visibility: 0 = shown, 1 = hidden, 2 = answers only, 3 = answers
% at end (see \printsolutions).
\def\SM@solutions{0}
\newif\ifSM@showsolution
% Completion display: -1 = automatic (shown mode only), 0 = off, 1 = on.
\def\SM@completionmarkers{-1}

% \SolutionManualSetup{key=value, ...}, in the preamble (after \documentclass).
% problem numbering can also be changed in the document, before a chapter.
\pgfqkeys{/SolutionManual}{
    % Titles and author
    author/.code={\def\authorName{#1}},
    title/.code={\def\mainTitle{#1}},
    subtitle/.code={\def\firstTitle{#1}},
    title prefix/.code={\def\SM@titleprefix{#1}},
    date/.code={\def\SM@date{#1}},
    % Texts
    author label/.code={\def\SM@authorlabel{#1}},
    contents label/.code={\def\SM@contentslabel{#1}},
    problem label/.code={\def\SM@problemlabel{#1}},
    solution label/.code={\def\SM@solutionlabel{#1}},
    answer label/.code={\def\SM@answerlabel{#1}},
    verification label/.code={\def\SM@verificationlabel{#1}},
    solutions title/.code={\def\SM@solutionstitle{#1}},
    solution link label/.code={\def\SM@sollinklabel{#1}},
    chapter abbreviation/.code={\def\SM@chapabbrev{#1}},
    section abbreviation/.code={\def\SM@secabbrev{#1}},
    problem abbreviation/.code={\def\SM@probabbrev{#1}},
    footer/.code={\def\SM@footer{#1}},
    % Colors
    theme color/.code={\colorlet{ThemeColor}{#1}},
    question background/.code={\def\SM@questionback{#1}},
    question frame/.code={\def\SM@questionframe{#1}},
    subquestion frame/.code={\def\SM@subquestionframe{#1}},
    answer background/.code={\def\SM@answerback{#1}},
    answer frame/.code={\def\SM@answerframe{#1}},
    subanswer frame/.code={\def\SM@subanswerframe{#1}},
    % Page layout (any geometry option) and problems
    layout/.code={\geometry{#1}},
    problem on new page/.is if=SM@problemnewpage,
    problem titles in contents/.is if=SM@titlesintoc,
    problem numbering/.is choice,
    problem numbering/continuous/.code={\SM@setnumbering{0}},
    problem numbering/chapter/.code={\SM@setnumbering{1}},
    problem numbering/subdivision/.code={\SM@setnumbering{2}},
    solutions/.is choice,
    solutions/shown/.code={\def\SM@solutions{0}},
    solutions/hidden/.code={\def\SM@solutions{1}},
    solutions/answers only/.code={\def\SM@solutions{2}},
    solutions/answers at end/.code={\def\SM@solutions{3}},
    % Completion tracking
    completion tracking/.is if=SM@completion,
    completion markers/.is choice,
    completion markers/true/.code={\def\SM@completionmarkers{1}},
    completion markers/false/.code={\def\SM@completionmarkers{0}},
    completion markers/.default=true,
    not done label/.code={\def\SM@notdonelabel{#1}},
    done label/.code={\def\SM@donelabel{#1}},
    completion title/.code={\def\SM@completiontitle{#1}},
    completion total label/.code={\def\SM@totallabel{#1}},
}
\newcommand{\SolutionManualSetup}[1]{\pgfqkeys{/SolutionManual}{#1}}

% Editions (see docs/editions.md): latexmk defines \SolutionManualSolutions
% before the class, e.g. as {hidden} or {answers\space only}. That mode is set
% now, and a later solutions=... in the document is ignored.
\ifdefined\SolutionManualSolutions
    \edef\SM@editionsolutions{\SolutionManualSolutions}
    \edef\@tempa{\noexpand\pgfqkeys{/SolutionManual}{solutions=\SM@editionsolutions}}
    \@tempa
    \pgfqkeys{/SolutionManual}{solutions/.code={\ClassInfo{SolutionManual}{%
        solutions=#1 ignored: this edition uses\MessageBreak
        solutions=\SM@editionsolutions}}}
\fi

% \SM@ifnotblank{\macro}{code}: code unless the macro is empty or blank
\newcommand{\SM@ifnotblank}[2]{\expandafter\ifblank\expandafter{#1}{}{#2}}

\ExplSyntaxOn
% \SM@rescan\cs{tokens}: \cs = the tokens, written and read back (@ is a letter)
\cs_new_protected:Npn \SM@rescan #1#2 { \tl_set_rescan:Nnn #1 { \makeatletter } {#2} }

% \SM@ifblank{text}{true}{false}: true if the text has only spaces and
% paragraph breaks (blank lines)
\tl_new:N \l__SM_blank_tl
\cs_new_protected:Npn \SM@ifblank #1
  {
    \tl_set:Nn \l__SM_blank_tl {#1}
    \tl_remove_all:Nn \l__SM_blank_tl { \par }
    \tl_if_blank:VTF \l__SM_blank_tl
  }
\ExplSyntaxOff

% PDF metadata
\AtBeginDocument{\hypersetup{pdftitle={\mainTitle}, pdfauthor={\authorName}}}

% ============ Page layout ============ %
\geometry{
    a4paper,
    margin=25mm,
}

% ============ Table of contents ============ %
% Keep the name free of paragraph formatting: tocloft also uses it in running
% headers, where a paragraph inside a hyperlink breaks multi-page contents.
\renewcommand{\cfttoctitlefont}{\hfill\scshape\huge} % centered title
\renewcommand{\contentsname}{\SM@contentslabel} % title and running-header text
\renewcommand{\cftaftertoctitle}{\hfill\mbox{}\par\nobreak\noindent\rule{\textwidth}{0.8pt}} % horizontal line

\renewcommand{\cftchapfont}{\bfseries \scshape} % chapter font
% Section dots as dense as the \dotfill of the problem entries
\renewcommand{\cftsecdotsep}{1.5}
\renewcommand{\cftsubsecdotsep}{1.5}

% ============ Colors ============ %
\hypersetup{
    colorlinks,
    linkcolor=ThemeColor,
    urlcolor=ThemeColor,
    bookmarksdepth=4, % titled parts of problems inside subsections
}

% ============ Chapter ============ %
\titleformat{\chapter}[display]
  {\centering}
  {\hypertarget{chapter-title.\theHchapter}{\huge \scshape \chaptername{} \textcolor{ThemeColor}{\Huge\bfseries \thechapter}.}}
  {1ex}
  {\titlerule[0.8pt] \LARGE \scshape \SM@heading{1}}

% ============ Sections and subsections ============ %
% Chapters, sections and subsections group the problems: a problem belongs to
% the last numbered heading before it, and all the problems of a chapter are
% at the same level (in the chapter, in sections or in subsections). Starred
% headings (\section*) are plain titles that group nothing.
\titleformat{\section}
  {\Large\scshape}
  {\textcolor{ThemeColor}{\bfseries\thesection}}
  {0.75em}
  {\SM@heading{2}}
\titleformat{\subsection}
  {\large\scshape}
  {\textcolor{ThemeColor}{\bfseries\thesubsection}}
  {0.75em}
  {\SM@heading{3}}

\def\SM@name@i{chapter}
\def\SM@name@ii{section}
\def\SM@name@iii{subsection}

% Current chapter, section and subsection: serial number (0 if none) and
% displayed number
\newcounter{SM@heading}
\def\SM@id@i{0}\def\SM@id@ii{0}\def\SM@id@iii{0}
\def\SM@num@i{}\def\SM@num@ii{}\def\SM@num@iii{}
\def\SM@lastheading{}
\def\SM@chapdepth{-1} % level of the problems of the chapter (-1: none yet)

% A section or subsection heading waits for its first problem
\newif\ifSM@afterheading

% Called by titlesec with the title of a heading.
% #1 = Level (1 = chapter, 2 = section, 3 = subsection)
% #2 = Title
\newcommand{\SM@heading}[2]{%
    \ifttl@label % numbered heading (titlesec), recorded once
        \ifx\@currentHref\SM@lastheading\else
            \xdef\SM@lastheading{\@currentHref}%
            \stepcounter{SM@heading}%
            \expandafter\xdef\csname SM@id@\romannumeral#1\endcsname{\arabic{SM@heading}}%
            \ifnum#1<3 \gdef\SM@id@iii{0}\fi
            \ifnum#1<2 \gdef\SM@id@ii{0}\fi
            \expandafter\protected@xdef\csname SM@num@\romannumeral#1\endcsname
                {\csname the\csname SM@name@\romannumeral#1\endcsname\endcsname}%
            \SM@record{\SM@do@heading{\arabic{SM@heading}}{#1}%
                {\csname SM@num@\romannumeral#1\endcsname}{#2}{\@currentHref}}%
            % Level, number, title and anchor, for the solutions part
            \expandafter\protected@xdef\csname SM@hd@\arabic{SM@heading}\endcsname
                {{#1}{\csname SM@num@\romannumeral#1\endcsname}%
                 {\unexpanded{#2}}{\@currentHref}}%
        \fi
    \fi
    \ifnum#1>1 \global\SM@afterheadingtrue\fi
    #2}

% Before each heading: finish the previous problem, set the number shown by
% the heading, and keep a section heading with its first problem.
% #1 = Level
\newcommand*{\SM@beforeheading}[1]{%
    \SM@finishproblem
    % Final equation, figure and table numbers of the chapter: its solutions
    % continue them at the end
    \ifnum#1=1
        \expandafter\xdef\csname SM@ends@\SM@id@i\endcsname
            {{\the\c@equation}{\the\c@figure}{\the\c@table}}%
    \fi
    \ifnum#1=1 \clearpage\fi % the last page of a chapter keeps its number
    \SM@restorenumber{subsection}%
    \ifnum#1<3 \SM@restorenumber{section}\fi
    \ifnum#1<2 \SM@restorenumber{chapter}\gdef\SM@chapdepth{-1}\fi
    \ifdefined\SM@pendingnumber
        \SM@applynumber{\csname SM@name@\romannumeral#1\endcsname}%
    \fi
    % Section bookmarks show their number (chapter bookmarks do not)
    \ifnum#1=1 \Hy@bookmarksnumberedfalse \else \Hy@bookmarksnumberedtrue \fi
    \ifnum#1=1
        \global\SM@afterheadingfalse
    \else
        \ifSM@afterheading\else
            \ifSM@problemnewpage
                \clearpage
            \else
                \if@nobreak\else\SM@needspace{6\baselineskip}\fi
            \fi
        \fi
    \fi}
\AddToHook{cmd/chapter/before}{\SM@beforeheading{1}}
\AddToHook{cmd/section/before}{\SM@beforeheading{2}}
\AddToHook{cmd/subsection/before}{\SM@beforeheading{3}}

% Page break unless #1 of space is left (as \needspace of needspace.sty)
\newcommand*{\SM@needspace}[1]{%
    \par
    \begingroup
        \setlength{\dimen@}{#1}%
        \vskip\z@\@plus\dimen@ \penalty-100 \vskip\z@\@plus-\dimen@
        \vskip\dimen@ \penalty9999 \vskip-\dimen@ \vskip\z@skip
    \endgroup}

% Section sign (§) in small caps (headings, titles, header): Computer Modern,
% like many fonts, has none, so LaTeX uses the upright one with a warning.
% Declare that substitution as silent for the main font of the document.
\AtBeginDocument{%
    \begingroup
        \fontencoding{TS1}\fontfamily{\familydefault}\fontseries{m}\fontshape{n}%
        \selectfont % loads the font definitions
        \@for\@tempa:=m,b,bx\do{%
            \ifcsname TS1/\familydefault/\@tempa/n\endcsname
                \ifcsname TS1/\familydefault/\@tempa/sc\endcsname\else
                    \edef\@tempb{\noexpand\DeclareFontShape{TS1}{\familydefault}%
                        {\@tempa}{sc}{<->ssub*\familydefault/\@tempa/n}{}}%
                    \@tempb
                \fi
            \fi}%
    \endgroup}

% Textbook numbers. \textbooknumber{\S 12} before \section{...} shows "§12"
% for that section, its subsections (§12.1, ...) and references to it, until
% the next section (likewise for a chapter or a subsection). The automatic
% numbering continues unchanged.
\newcommand{\textbooknumber}[1]{\gdef\SM@pendingnumber{#1}}
% #1 = Counter (chapter, section or subsection)
\newcommand*{\SM@applynumber}[1]{%
    \global\expandafter\let\csname SM@saved@#1\expandafter\endcsname
        \csname the#1\endcsname
    \global\expandafter\let\csname the#1\endcsname\SM@pendingnumber
    \SM@ifsign\SM@pendingnumber
        {\expandafter\gdef\csname SM@sign@#1\endcsname{1}}%
        {\expandafter\gdef\csname SM@sign@#1\endcsname{0}}%
    \global\let\SM@pendingnumber\@undefined}
% \SM@ifsign\cs{true}{false}: true if \cs contains \S or \textsection
\ExplSyntaxOn
\cs_new_protected:Npn \SM@ifsign #1#2#3
  { \tl_if_in:NnTF #1 { \S } {#2} { \tl_if_in:NnTF #1 { \textsection } {#2} {#3} } }
\ExplSyntaxOff
\newcommand*{\SM@restorenumber}[1]{%
    \ifcsname SM@saved@#1\endcsname
        \global\expandafter\let\csname the#1\expandafter\endcsname
            \csname SM@saved@#1\endcsname
        \global\expandafter\let\csname SM@saved@#1\endcsname\@undefined
        \global\expandafter\let\csname SM@sign@#1\endcsname\@undefined
    \fi}

% ============ Problems environment ============ %
% Problems are numbered within chapters by default (see problem numbering),
% subproblems within problems. \ref gives "2.3" for a problem and "2.3(a)" for
% a subproblem; with subdivision numbering, "2.1.3" and "2.1.3(a)" in a
% section.
\newcounter{ProblemNum}[chapter]
\renewcommand{\theProblemNum}{\arabic{ProblemNum}}
\renewcommand{\p@ProblemNum}{\thechapter.}
\newcounter{SubProblemNum}[ProblemNum]
\renewcommand{\theSubProblemNum}{(\alph{SubProblemNum})}
\renewcommand{\p@SubProblemNum}{\p@ProblemNum\theProblemNum}
% Unique hyperlink anchors, even when problem numbers repeat
\def\theHProblemNum{\theHsubsection.\arabic{ProblemNum}}
\def\theHSubProblemNum{\theHProblemNum.\arabic{SubProblemNum}}
% Serial number of the problems in the document
\newcounter{SM@problem}

% #1 = 0 (continuous), 1 (chapter) or 2 (subdivision: every heading, the
% problems of a chapter being at one level). A change restarts the numbering.
\newcommand*{\SM@setnumbering}[1]{%
    \xdef\SM@numbering{#1}%
    \setcounter{ProblemNum}{0}%
    \counterwithout*{ProblemNum}{chapter}%
    \counterwithout*{ProblemNum}{section}%
    \counterwithout*{ProblemNum}{subsection}%
    \ifnum#1>0 \counterwithin*{ProblemNum}{chapter}\fi
    \ifnum#1>1
        \counterwithin*{ProblemNum}{section}%
        \counterwithin*{ProblemNum}{subsection}%
    \fi
    % hyperref redefines the anchors of a counter whose reset list changes
    \gdef\theHProblemNum{\theHsubsection.\arabic{ProblemNum}}}

% Level and numbering unit of the next problem. Sets \SM@depth (0 in a
% chapter, 1 in a section, 2 in a subsection), \p@ProblemNum (reference
% prefix), \SM@unitkey (for \probref), \SM@unitname (running header) and
% \SM@unitref (start of the \probref text).
\newcommand*{\SM@setunit}{%
    \edef\SM@depth{\the\numexpr
        \ifnum\SM@id@ii>\z@ 1\else 0\fi + \ifnum\SM@id@iii>\z@ 1\else 0\fi}%
    \ifnum\SM@chapdepth<\z@
        \xdef\SM@chapdepth{\SM@depth}%
    \else\ifnum\SM@chapdepth=\SM@depth\else
        \ClassError{SolutionManual}{Problems at different levels in chapter
            \thechapter}{Put all the problems of a chapter directly in it, or
            all in sections, or all in subsections.}%
    \fi\fi
    \ifcase\SM@numbering\relax
        \gdef\p@ProblemNum{}%
        \SM@stringify\SM@unitkey{\thechapter}%
        \let\SM@unitname\@empty
        \let\SM@unitref\@empty
    \or
        \SM@chapterunit
    \else
        \ifcase\SM@depth\relax
            \SM@chapterunit
        \else
            \expandafter\let\expandafter\SM@unitname
                \csname SM@num@\romannumeral\numexpr\SM@depth+1\endcsname
            \xdef\p@ProblemNum{\unexpanded\expandafter{\SM@unitname}.}%
            \SM@stringify\SM@unitkey{\SM@unitname}%
            \SM@ifsignunit{\numexpr\SM@depth+1}%
                {\protected@edef\SM@unitref{\SM@unitname\space}}%
                {\protected@edef\SM@unitref{\SM@secabbrev~\SM@unitname\space}}%
        \fi
    \fi}
\newcommand*{\SM@chapterunit}{%
    \gdef\p@ProblemNum{\thechapter.}%
    \SM@stringify\SM@unitkey{\thechapter}%
    \let\SM@unitname\@empty
    \SM@ifsignunit{1}%
        {\protected@edef\SM@unitref{\thechapter\space}}%
        {\protected@edef\SM@unitref{\SM@chapabbrev~\thechapter\space}}}

% \SM@ifsignunit{level}{true}{false}: true if the number shown at that level
% comes from a textbook number with a section sign (\S 12, \S 12.1, ...)
\newcommand{\SM@ifsignunit}[3]{%
    \def\@tempb{0}%
    \ifcsname SM@sign@chapter\endcsname \let\@tempb\SM@sign@chapter\fi
    \ifnum#1>1 \ifcsname SM@sign@section\endcsname \let\@tempb\SM@sign@section\fi\fi
    \ifnum#1>2 \ifcsname SM@sign@subsection\endcsname \let\@tempb\SM@sign@subsection\fi\fi
    \ifnum\@tempb=1 #2\else #3\fi}

% \SM@stringify\cs{text}: \cs = the text, expanded, as a string
\newcommand{\SM@stringify}[2]{%
    \protected@edef#1{#2}%
    \edef#1{\detokenize\expandafter{#1}}}

% Reference target of the problem, for \probref: written to the aux file as
% \SM@probtarget{key}{text}{anchor}, with key = MD5 of "<unit>-<number>". A
% key that repeats (two subdivisions shown with the same number) is skipped.
\newcommand*{\SM@settarget}{%
    \edef\SM@probkey{\pdf@mdfivesum{\SM@unitkey-\theProblemNum}}%
    \ifcsname SM@key@\SM@probkey\endcsname
        \ClassWarning{SolutionManual}{Problem \theProblemNum\space repeats in
            two subdivisions shown with the same number.\MessageBreak
            \protect\probref\space links to the first one}%
    \else
        \expandafter\gdef\csname SM@key@\SM@probkey\endcsname{}%
        \protected@edef\@tempa{\SM@unitref\SM@probabbrev~\theProblemNum}%
        \immediate\write\@auxout{\string\SM@probtarget{\SM@probkey}%
            {\unexpanded\expandafter{\@tempa}}{problem-title.\theHProblemNum}}%
    \fi}
\newcommand{\SM@probtarget}[3]{\expandafter\gdef\csname SM@ref@#1\endcsname{{#2}{#3}}}

% The title is local to each problem/part and reset by \SM@readstatus.
\newcommand*{\SM@title}{}
\newcommand*{\SM@titlesuffix}{\SM@ifnotblank{\SM@title}{\space\SM@title}}

% Define question environment
\newtcolorbox{question}{enhanced, breakable,
                      colback=\SM@questionback,
                      colframe=\SM@questionframe,
                      title=\hypertarget{problem-title.\theHProblemNum}{\scshape \SM@problemlabel{} \theProblemNum}.\SM@titlesuffix\SM@marker\SM@sollink\SM@pagewrite{first}\SM@pagewrite{last}
                      }

% Define subproblem environment
\newtcolorbox{subquestion}{enhanced, breakable,
                           colback=\SM@questionback,
                           colframe=\SM@subquestionframe,
                           title=\theSubProblemNum\SM@titlesuffix\SM@marker\SM@sollink\SM@pagewrite{last}
                          }

% Define solution command
\newcommand*{\solution}{%
  % Keep a closing display attached to the answer. Permit breaks before other
  % displays so a chain of short paragraphs and equations can still paginate.
  \postdisplaypenalty=10000\relax
  \predisplaypenalty=1000\relax
  {\scshape \SM@solutionlabel}
  }

% Keep answer boxes with the preceding solution text. If space runs out,
% LaTeX moves the end of the solution together with the box.
\tcbset{keep with solution/.style={
    before={\par\nobreak\smallskip\noindent}
}}

% Define answer environment
\newtcolorbox{answer}{enhanced,
                      keep with solution,
                      colback=\SM@answerback,
                      colframe=\SM@answerframe,
                      title=\scshape \SM@answerlabel{} \theProblemNum.
                      }

% Define subanswer environment
\newtcolorbox{subanswer}{enhanced,
                         keep with solution,
                         colback=\SM@answerback,
                         colframe=\SM@subanswerframe,
                         title=\scshape \SM@answerlabel{} \theProblemNum~\theSubProblemNum.
                         }

% Response visibility is decided here, after source-based completion tracking.
% A local show solution override restores the full response in any mode.
% Blank arguments are always omitted. With answers at end, the response is
% collected for \printsolutions instead (see \SM@collect).
% #1 = Solution
% #2 = Answer
% #3 = Verification
% #4 = Answer environment (answer or subanswer)
\newcommand{\SM@response}[4]{%
    \ifSM@showsolution\def\SM@responsemode{0}%
    \else\let\SM@responsemode\SM@solutions\fi
    \ifnum\SM@responsemode=0
        \let\SM@printworked\@firstofone
    \else\let\SM@printworked\@gobble\fi
    \ifnum\SM@responsemode=1
        \let\SM@printanswer\@gobble
    \else\let\SM@printanswer\@firstofone\fi
    \ifnum\SM@responsemode=3
        \expandafter\@firstoftwo
    \else
        \expandafter\@secondoftwo
    \fi
    {\SM@collect{#1}{#2}{#3}{#4}}%
    {\SM@printresponse{#1}{#2}{#3}{#4}}}
% Same arguments, printed as set by \SM@printworked and \SM@printanswer
\newcommand{\SM@printresponse}[4]{%
    \SM@printworked{\SM@ifblank{#1}{}{\solution #1\SM@pagewrite{last}\par}}%
    \SM@printanswer{\SM@ifblank{#2}{}{\begin{#4}#2\SM@pagewrite{last}\end{#4}}}%
    \SM@printworked{\SM@ifblank{#3}{}{\par\smallskip\noindent{\scshape \SM@verificationlabel} #3\SM@pagewrite{last}\par}}%
}

% Running header: the last problem started on the page (mark class SMproblem;
% headings reset it)
\NewMarkClass{SMproblem}
% #1 = Anchor, #2 = Unit shown before the number (or empty), #3 = Number
\protected\def\SM@problemhead#1#2#3{%
    \hyperlink{#1}{\scshape \ifblank{#2}{}{#2\quad}\SM@problemlabel~#3.}}

% Wrapper for problems
% #1 = Options: done / not done (status override), title={...}, show solution
% #2 = Question
% #3 = Solution (optional: leave empty)
% #4 = Answer (optional: leave empty)
% #5 = Verification (optional, after the answer)
\NewDocumentEnvironment{problem}{O{} +m +m +m +O{}}
{%
    \SM@finishproblem
    \SM@readstatus{#1}%
    % Nothing between the break point and the box can be separated from it
    \ifSM@problemnewpage
        \ifSM@afterheading\else\clearpage\fi
    \else
        \par
        \ifSM@afterheading\else\if@nobreak\else\penalty\z@\fi\fi
    \fi
    \SM@setunit
    \refstepcounter{ProblemNum}\stepcounter{SM@problem}%
    \SM@settarget
    \edef\@tempa{\the\numexpr\SM@depth+1}% bookmark level
    \pdfbookmark[\@tempa]{\SM@problemlabel\space\theProblemNum
        \SM@ifnotblank{\SM@title}{.\space\SM@title}}{problem.\theHProblemNum}%
    \addtocontents{toc}{\protect\SM@tocskip{\SM@depth}\protect\hyperlink{\@currentHref}{\scshape \SM@problemlabel~\theProblemNum.\ifSM@titlesintoc\SM@titlesuffix\fi}%
        \ifSM@completion\protect\SM@tocmark{\arabic{SM@problem}}\fi\hspace{0.5em}\dotfill\thepage\par}%
    \edef\@tempa{\noexpand\InsertMark{SMproblem}{\noexpand\SM@problemhead
        {\@currentHref}{\unexpanded\expandafter{\SM@unitname}}{\theProblemNum}}}%
    \@tempa
    \nobreak
    \ifSM@problemnewpage\else\ifSM@afterheading\else\bigskip\fi\fi
    \global\SM@afterheadingfalse
    \SM@startproblem{#3}%
    \SM@solpending
    \SM@setsollink{\arabic{SM@problem}}%
    \begin{question}
        #2\SM@pagewrite{last}%
    \end{question}
    \SM@response{#3}{#4}{#5}{answer}%
}{\ifhmode\SM@pagewrite{last}\fi\par}

% Wrapper for subproblems, after a problem
% #1 = Options: done / not done (status override), title={...}, show solution
% #2 = Question
% #3 = Solution (optional: leave empty)
% #4 = Answer (optional: leave empty)
% #5 = Verification (optional, after the answer)
\NewDocumentEnvironment{subproblem}{O{} +m +m +m +O{}}
{%
    \par
    \refstepcounter{SubProblemNum}%
    \SM@readstatus{#1}%
    \SM@startsubproblem{#3}%
    % Only titled parts gain navigation entries: keep untitled output intact.
    \SM@ifnotblank{\SM@title}{%
        \edef\@tempa{\the\numexpr\SM@p@depth+2}% one level below the parent
        \pdfbookmark[\@tempa]{\SM@problemlabel\space\theProblemNum\theSubProblemNum.\space\SM@title}%
            {subproblem.\theHSubProblemNum}%
        \ifSM@titlesintoc
            \addtocontents{toc}{\protect\SM@tocskip{\SM@p@depth}\protect\hspace{1.5em}%
                \protect\hyperlink{\@currentHref}{\theSubProblemNum\space\SM@title}%
                \hspace{0.5em}\dotfill\thepage\par}%
        \fi}%
    \SM@setsollink{\arabic{SM@problem}.\arabic{SubProblemNum}}%
    \begin{subquestion}
        #2\SM@pagewrite{last}%
    \end{subquestion}
    \SM@response{#3}{#4}{#5}{subanswer}%
}{\ifhmode\SM@pagewrite{last}\fi\par}

% Contents indentation of a problem in a chapter (0), section (1) or
% subsection (2): under the title of its heading
\newcommand*{\SM@tocskip}[1]{%
    \ifcase#1 \hspace{2em}%
    \or \hspace{\dimexpr\cftsecindent+\cftsecnumwidth}%
    \else \hspace{\dimexpr\cftsubsecindent+\cftsubsecnumwidth}%
    \fi}

% Link to a problem
% #1 = Text (optional; default: "Chap. 1 Prob. 2", "Sec. 3.1 Prob. 2",
%      "§12 Prob. 2", "Prob. 47" in continuous numbering)
% #2 = Number of its chapter, section or subsection where the numbering
%      restarts, as shown (1, 3.1, \S 12); the chapter in chapter and
%      continuous numbering
% #3 = Problem number
\DeclareRobustCommand{\probref}[3][]{%
    \SM@stringify\SM@tempkey{#2}%
    \edef\SM@tempkey{\pdf@mdfivesum{\SM@tempkey-#3}}%
    \ifcsname SM@ref@\SM@tempkey\endcsname
        \expandafter\expandafter\expandafter\SM@reflink
            \csname SM@ref@\SM@tempkey\endcsname{#1}%
    \else
        \G@refundefinedtrue
        \textbf{??}%
        \@latex@warning{Problem reference `#2-#3' undefined}%
    \fi}
% #1 = Default text, #2 = Anchor, #3 = Text (or empty)
\newcommand{\SM@reflink}[3]{\hyperlink{#2}{\ifblank{#3}{#1}{#3}}}

% ============ Solutions at the end ============ %
% With solutions=answers at end, each response that has a solution or an
% answer is kept as tokens (never typeset in place), with the headings and the
% problem header it needs, and \printsolutions typesets the list:
%   \SM@sol@heading{serial}{level}{number}{title}{anchor}
%   \SM@sol@problem{key}{number}{title}{question anchor}{bookmark level}
%   \SM@sol@part{key}{number}{title}{question anchor}
%   \SM@sol@response{answer environment}{solution}{answer}{verification}
% The key is the problem serial, with ".<part>" for a part. Each problem or
% part header writes \SM@solpage{key}{page} to the aux file, for the
% "Solution p. N" link of its question in the next run.
\ExplSyntaxOn
\tl_new:N \g__SM_sol_tl
\tl_new:N \l__SM_sol_tl
\cs_new_protected:Npn \SM@sol@add #1 { \tl_gput_right:Nn \g__SM_sol_tl {#1} }
% #1 = Level (i, ii or iii), #2 = Heading serial (0 if none): add the heading
% unless it is the last one added at that level
\cs_new_protected:Npn \SM@sol@addheading #1#2
  {
    \int_compare:nNnT {#2} > { 0 }
      {
        \int_compare:nNnF {#2} = { \use:c { SM@sol@last@#1 } }
          {
            \tl_gset:cn { SM@sol@last@#1 } {#2}
            \tl_gput_right:Nx \g__SM_sol_tl
              { \exp_not:N \SM@sol@heading {#2} \exp_not:v { SM@hd@#2 } }
          }
      }
  }
% Print the solutions collected so far, if any, and start a new list
\NewDocumentCommand \printsolutions { }
  {
    \SM@finishproblem
    \tl_if_empty:NF \g__SM_sol_tl
      {
        \tl_set_eq:NN \l__SM_sol_tl \g__SM_sol_tl
        \tl_gclear:N \g__SM_sol_tl
        \gdef \SM@sol@last@i {0}
        \gdef \SM@sol@last@ii {0}
        \gdef \SM@sol@last@iii {0}
        \SM@printsolutions
      }
  }
\cs_new_protected:Npn \SM@sol@use { \tl_use:N \l__SM_sol_tl }
\ExplSyntaxOff
\def\SM@sol@last@i{0}\def\SM@sol@last@ii{0}\def\SM@sol@last@iii{0}

% Headings and header of the current problem, added before its first
% collected response: {chapter}{section}{subsection}{header}
\def\SM@sol@pending{}
\newcommand*{\SM@solpending}{%
    \protected@xdef\SM@sol@pending{{\SM@id@i}{\SM@id@ii}{\SM@id@iii}%
        {\noexpand\SM@sol@problem{\arabic{SM@problem}}%
            {\p@ProblemNum\theProblemNum}{\unexpanded\expandafter{\SM@title}}%
            {problem-title.\theHProblemNum}{\the\numexpr\SM@depth+2}}}}
\newcommand*{\SM@sol@flush}{%
    \ifx\SM@sol@pending\@empty\else
        \expandafter\SM@sol@flush@i\SM@sol@pending
        \global\let\SM@sol@pending\@empty
    \fi}
\newcommand{\SM@sol@flush@i}[4]{%
    \SM@sol@addheading{i}{#1}\SM@sol@addheading{ii}{#2}%
    \SM@sol@addheading{iii}{#3}\SM@sol@add{#4}}

% Arguments of \SM@response. A response without solution or answer is skipped.
\newcommand{\SM@collect}[4]{%
    \SM@ifblank{#1#2}{}{%
        \SM@sol@flush
        \ifstrequal{#4}{subanswer}{%
            \protected@edef\@tempa{\noexpand\SM@sol@part
                {\arabic{SM@problem}.\arabic{SubProblemNum}}{\theSubProblemNum}%
                {\unexpanded\expandafter{\SM@title}}{\@currentHref}}%
            \expandafter\SM@sol@add\expandafter{\@tempa}}{}%
        \SM@sol@add{\SM@sol@response{#4}{#1}{#2}{#3}}}}

% Link of a question to its solution: \SM@sollink, in the question title,
% from the page recorded in the previous run. #1 = Key
\newcommand*{\SM@setsollink}[1]{%
    \let\SM@sollink\@empty
    \ifnum\SM@solutions=3
        \ifcsname SM@solpg@#1\endcsname
            \edef\SM@sollink{\noexpand\SM@sollinkbox{#1}%
                {\csname SM@solpg@#1\endcsname}}%
        \fi
    \fi}
\let\SM@sollink\@empty
% #1 = Key, #2 = Page. The link keeps the color of the title text.
\newcommand*{\SM@sollinkbox}[2]{%
    \ifx\SM@marker\@empty\hfill\else\quad\fi
    {\colorlet{SM@titlecolor}{.}\normalfont\footnotesize
     \hyperlink{SMsolution.#1}{\color{SM@titlecolor}\SM@sollinklabel~#2}}}
\newcommand*{\SM@solpage}[2]{\expandafter\gdef\csname SM@solpg@#1\endcsname{#2}}
% At the end, the aux file is read again: a new or moved page needs a rerun
\newcommand*{\SM@solpagetest}[2]{%
    \def\reserved@a{#2}%
    \expandafter\ifx\csname SM@solpg@#1\endcsname\reserved@a\else
        \@tempswatrue
    \fi}
\AtEndDocument{\printsolutions\let\SM@solpage\SM@solpagetest}

% The solutions part: a starred chapter, with the headings of the problems.
% Equations, figures and tables continue the numbers of their chapter.
\newif\ifSM@insolutions % running header without chapter number
\newif\ifSM@solkeep % keep the next line with a heading or header
\newcounter{SM@solprint}
\newcommand*{\SM@printsolutions}{%
    \if@openright\cleardoublepage\else\clearpage\fi
    \global\SM@insolutionstrue
    \stepcounter{SM@solprint}%
    \chapter*{\SM@solutionstitle}%
    \phantomsection
    \addcontentsline{toc}{chapter}{\SM@solutionstitle}%
    \markboth{\SM@solutionstitle}{}\InsertMark{SMproblem}{}%
    \edef\SM@sol@restore{%
        \global\c@equation\the\c@equation\relax
        \global\c@figure\the\c@figure\relax
        \global\c@table\the\c@table\relax}%
    \begingroup
        \let\SM@printworked\@firstofone
        \let\SM@printanswer\@firstofone
        \let\SM@pagewrite\@gobble
        \def\theHequation{\SM@sol@key.\arabic{equation}}%
        \def\theHfigure{\SM@sol@key.\arabic{figure}}%
        \def\theHtable{\SM@sol@key.\arabic{table}}%
        \c@chapter\z@ % problems before the first chapter
        \SM@sol@setcounts{0}%
        \SM@solkeepfalse
        \SM@sol@use
    \endgroup
    \SM@sol@restore
    \clearpage
    \global\SM@insolutionsfalse}
% #1 = Chapter serial (0 before the first chapter)
\newcommand*{\SM@sol@setcounts}[1]{%
    \ifcsname SM@ends@#1\endcsname
        \expandafter\expandafter\expandafter\SM@sol@setcounts@i
            \csname SM@ends@#1\endcsname
    \fi}
\newcommand*{\SM@sol@setcounts@i}[3]{%
    \setcounter{equation}{#1}\setcounter{figure}{#2}\setcounter{table}{#3}}
\newcommand*{\SM@solpagewrite}[1]{%
    \protected@write\@auxout{}{\string\SM@solpage{#1}{\thepage}}%
    \ifcsname SM@solpg@#1\endcsname\else\G@refundefinedtrue\fi}

\def\SM@sol@heading#1#2#3#4#5{%
    \ifnum#2=\@ne
        \c@chapter\@ne \def\thechapter{#3}%
        \SM@sol@setcounts{#1}%
    \fi
    \par
    \ifnum#2=\@ne\addvspace{2\bigskipamount}\else\addvspace\bigskipamount\fi
    \SM@needspace{6\baselineskip}%
    \ifnum#2=\@ne
        \pdfbookmark[1]{#4}{SMsolutions.\arabic{SM@solprint}.#1}%
    \else
        \pdfbookmark[#2]{#3\space#4}{SMsolutions.\arabic{SM@solprint}.#1}%
    \fi
    {\parindent\z@ \interlinepenalty\@M \let\label\@gobble
     \ifcase#2\or\Large\or\large\else\normalsize\fi \scshape
     \ifnum#2=\@ne\chaptername~\fi\hyperlink{#5}{\bfseries #3}%
     \ifnum#2=\@ne.\fi\quad #4\par}%
    \nobreak\medskip
    \SM@solkeeptrue}
\def\SM@sol@problem#1#2#3#4#5{%
    \par
    \ifSM@solkeep\else
        \addvspace\bigskipamount\SM@needspace{5\baselineskip}%
    \fi
    \def\theProblemNum{#2}\def\SM@sol@ref{#2}\def\SM@sol@key{#1}%
    \pdfbookmark[#5]{\SM@problemlabel\space#2\ifblank{#3}{}{.\space#3}}%
        {SMsolutionbm.#1}%
    \protected@edef\@currentlabel{#2}\def\@currentHref{SMsolution.#1}%
    \noindent\hypertarget{SMsolution.#1}{}%
    \InsertMark{SMproblem}{\SM@problemhead{#4}{}{#2}}%
    \SM@solpagewrite{#1}%
    \hyperlink{#4}{\bfseries\scshape \SM@problemlabel~#2.}\ifblank{#3}{}{\space #3}\par
    \nobreak
    \SM@solkeeptrue}
\def\SM@sol@part#1#2#3#4{%
    \par
    \ifSM@solkeep\else
        \addvspace\medskipamount\SM@needspace{4\baselineskip}%
    \fi
    \def\theSubProblemNum{#2}\def\SM@sol@key{#1}%
    \protected@edef\@currentlabel{\SM@sol@ref#2}\def\@currentHref{SMsolution.#1}%
    \noindent\hypertarget{SMsolution.#1}{}\SM@solpagewrite{#1}%
    \hyperlink{#4}{\bfseries #2}\ifblank{#3}{}{\space #3}\par
    \nobreak
    \SM@solkeeptrue}
\def\SM@sol@response#1#2#3#4{%
    \SM@solkeepfalse
    \SM@printresponse{#2}{#3}{#4}{#1}}

% ============ Completion tracking ============ %
% A problem or subproblem is done when its solution is not blank; the
% optional argument [done] or [not done] overrides this. A problem with
% subproblems is done when all of them are done (and it is not marked
% [not done]). With completion tracking, each finished problem is recorded:
%   \SM@do@heading{serial}{level}{number}{title}{anchor}
%   \SM@do@problem{serial}{chapter}{section}{subsection}{done}{number}
%                 {anchor}{unfinished parts}
%   \SM@do@details{serial}{numbering unit heading}{title}{part records}
% (chapter, section and subsection are heading serials, 0 if none). Records
% go to the list \SM@cur@list and, through the aux file, to \SM@prev@list in
% the next run, with done/total counts per heading. The PDF overview, contents
% markers and parent problem markers read \SM@prev@list (the previous run);
% the Markdown report is written at the end of the run from \SM@cur@list.

\newcommand*{\SM@notdonemarker}{\hfill{\normalfont\footnotesize\itshape \SM@notdonelabel}}

% Options: status sets \SM@forced to 0, 1 or 2; title and visibility are
% independent of it. Reset all options for each problem or part.
\pgfqkeys{/SolutionManual/status}{
    done/.code={\def\SM@forced{1}},
    not done/.code={\def\SM@forced{2}},
    title/.store in=\SM@title,
    show solution/.code={\SM@showsolutiontrue},
    .unknown/.code={\ClassError{SolutionManual}{Unknown status
        `\pgfkeyscurrentname'}{Use done, not done, title={...} or show solution.}},
}
\newcommand{\SM@readstatus}[1]{%
    \def\SM@forced{0}\let\SM@title\@empty
    \SM@showsolutionfalse
    \pgfqkeys{/SolutionManual/status}{#1}}

% \@tempa = own status (1 = done) from the solution #1 and \SM@forced
\newcommand{\SM@ownstatus}[1]{%
    \SM@ifblank{#1}{\def\@tempa{0}}{\def\@tempa{1}}%
    \ifcase\SM@forced\or\def\@tempa{1}\or\def\@tempa{0}\fi}

% PDF completion display follows the mode unless explicitly overridden.
% This does not affect tracking, the Markdown report or JSON export.
\newcommand{\SM@ifcompletionmarkers}[2]{%
    \ifnum\SM@completionmarkers<0
        \ifnum\SM@solutions=0 #1\else #2\fi
    \else
        \ifnum\SM@completionmarkers=1 #1\else #2\fi
    \fi}

% \SM@marker: the not-done marker if #1 is 0 and PDF markers are enabled
\newcommand*{\SM@setmarker}[1]{%
    \let\SM@marker\@empty
    \ifSM@completion
        \SM@ifcompletionmarkers{%
            \ifnum#1=\z@ \let\SM@marker\SM@notdonemarker\fi}{}%
    \fi}
\let\SM@marker\@empty

% Delayed writes travel with the content, including breakable boxes. Freeze
% the problem serial now; evaluate the displayed page label at shipout.
\newcommand*{\SM@pagewrite}[1]{%
    \ifSM@completion
        \protected@write\@auxout{}{\string\SM@jsonpage{\SM@p@serial}{#1}{\thepage}}%
    \fi}
\newcommand*{\SM@jsonpage}[3]{%
    \expandafter\gdef\csname SM@json@page@#1@#2\endcsname{#3}}

% Problem being written, recorded at the next problem, heading or the end
\newif\ifSM@pending
% #1 = Solution
\newcommand{\SM@startproblem}[1]{%
    \SM@ownstatus{#1}%
    \global\let\SM@p@own\@tempa
    \xdef\SM@p@forced{\SM@forced}%
    \gdef\SM@p@nparts{0}\gdef\SM@p@allparts{1}\gdef\SM@p@parts{}%
    \gdef\SM@p@partrecords{}%
    \xdef\SM@p@serial{\arabic{SM@problem}}%
    \xdef\SM@p@depth{\SM@depth}% navigation level for parts after the environment
    \xdef\SM@p@ids{{\SM@id@i}{\SM@id@ii}{\SM@id@iii}}%
    \protected@xdef\SM@p@num{\theProblemNum}%
    \xdef\SM@p@href{\@currentHref}%
    \protected@xdef\SM@p@title{\SM@title}%
    \xdef\SM@p@unit{\ifnum\SM@numbering=2
        \csname SM@id@\romannumeral\numexpr\SM@depth+1\endcsname
        \else\SM@id@i\fi}%
    \global\SM@pendingtrue
    % Subproblems decide: use the final status of the previous run if known
    \ifcsname SM@prev@status@\SM@p@serial\endcsname
        \edef\@tempa{\csname SM@prev@status@\SM@p@serial\endcsname}%
    \fi
    \SM@setmarker{\@tempa}}
% #1 = Solution
\newcommand{\SM@startsubproblem}[1]{%
    \SM@ownstatus{#1}%
    \ifSM@pending
        \protected@xdef\SM@p@partrecords{\unexpanded\expandafter{\SM@p@partrecords}%
            \noexpand\SM@jsonpart{\theSubProblemNum}{\SM@title}{\@tempa}{\@currentHref}}%
        \xdef\SM@p@nparts{\the\numexpr\SM@p@nparts+1}%
        \ifnum\@tempa=\z@
            \gdef\SM@p@allparts{0}%
            \xdef\SM@p@parts{\SM@p@parts\ifx\SM@p@parts\@empty\else, \fi\alph{SubProblemNum}}%
        \fi
    \fi
    \SM@setmarker{\@tempa}}
\newcommand*{\SM@finishproblem}{%
    \ifSM@pending
        \global\SM@pendingfalse
        \ifnum\SM@p@nparts>\z@
            \ifnum\SM@p@forced=2 \def\@tempa{0}\else\let\@tempa\SM@p@allparts\fi
        \else
            \let\@tempa\SM@p@own
        \fi
        \SM@record{\SM@do@problem{\SM@p@serial}\SM@p@ids{\@tempa}{\SM@p@num}%
            {\SM@p@href}{\SM@p@parts}%
            \SM@do@details{\SM@p@serial}{\SM@p@unit}{\SM@p@title}{\SM@p@partrecords}}%
    \fi}
\AddToHook{include/end}{\SM@finishproblem}

% Record (see above): written to the aux file and kept in this run, read back
% as from the aux file (so that both runs give the same tokens)
\newcommand{\SM@record}[1]{%
    \ifSM@completion
        \begingroup
            \let\label\@gobble \let\index\@gobble \let\glossary\@gobble
            \let\SM@do@heading\relax \let\SM@do@problem\relax \let\SM@do@details\relax
            \protected@edef\@tempa{#1}%
            \immediate\write\@auxout{\string\SM@prev{\unexpanded\expandafter{\@tempa}}}%
            \expandafter\SM@rescan\expandafter\@tempa\expandafter{\@tempa}%
            \edef\@tempa{\noexpand\SM@store{cur}{\unexpanded\expandafter{\@tempa}}}%
            \@tempa
        \endgroup
    \fi}
\newcommand{\SM@prev}[1]{\SM@store{prev}{#1}}
\newcommand*{\SM@prevready}{\global\let\SM@prev@ready\relax}
\def\SM@cur@list{}
\def\SM@prev@list{}

% #1 = cur or prev, #2 = Record: add it to the list and to the counts
\newcommand{\SM@store}[2]{%
    \expandafter\g@addto@macro\csname SM@#1@list\endcsname{#2}%
    \begingroup
        \def\SM@ns{#1}%
        \let\SM@do@heading\SM@gobblefive
        \let\SM@do@problem\SM@countproblem
        \let\SM@do@details\@gobblefour
        #2%
    \endgroup}
\long\def\SM@gobblefive#1#2#3#4#5{}
% Existing completion consumers ignore JSON-only details in the same list.
\long\def\SM@do@details#1#2#3#4{}
\def\SM@countproblem#1#2#3#4#5#6#7#8{%
    \SM@add{all}{#5}%
    \SM@add{#2}{#5}% 0 counts the problems outside chapters
    \ifnum#3>\z@ \SM@add{#3}{#5}\fi
    \ifnum#4>\z@ \SM@add{#4}{#5}\fi
    \expandafter\xdef\csname SM@\SM@ns @status@#1\endcsname{#5}}
% #1 = Heading serial (or all), #2 = 1 if done
\def\SM@add#1#2{%
    \edef\@tempa{\the\numexpr\SM@count{total}{#1}+1}%
    \edef\@tempb{\the\numexpr\SM@count{done}{#1}+#2}%
    \global\expandafter\let\csname SM@\SM@ns @total@#1\endcsname\@tempa
    \global\expandafter\let\csname SM@\SM@ns @done@#1\endcsname\@tempb}
% #1 = total or done, #2 = Heading serial (or all), in the namespace \SM@ns
\def\SM@count#1#2{%
    \ifcsname SM@\SM@ns @#1@#2\endcsname\csname SM@\SM@ns @#1@#2\endcsname\else 0\fi}

% Contents marker of problem #1 (serial), from the previous run
\newcommand*{\SM@tocmark}[1]{%
    \ifSM@completion
        \SM@ifcompletionmarkers{%
            \ifcsname SM@prev@status@#1\endcsname
                \ifnum\csname SM@prev@status@#1\endcsname=\z@
                    \hspace{0.5em}{\normalfont\footnotesize\itshape \SM@notdonelabel}%
                \fi
            \fi}{}%
    \fi}

% Apply #2 (heading handler) and #3 (problem handler) to the records of list #1
\newcommand{\SM@walk}[3]{%
    \begingroup
        \let\SM@do@heading#2\let\SM@do@problem#3%
        #1%
    \endgroup}

% ---- PDF overview ---- %
% Linked list of the chapters and subdivisions that contain problems, with
% done/total counts and the unfinished problems: from the previous run at the
% start of the manual, from this run at its end.
\newcommand{\completionoverview}{%
    \SM@ifcompletionmarkers{%
    \ifSM@completion
        \SM@finishproblem
        \ifx\SM@cur@list\@empty\def\SM@ns{prev}\else\def\SM@ns{cur}\fi
        \clearpage
        \thispagestyle{plain}%
        \markboth{\SM@completiontitle}{}\InsertMark{SMproblem}{}%
        \pdfbookmark[0]{\SM@completiontitle}{completion}%
        \vspace*{\cftbeforetoctitleskip}%
        {\interlinepenalty\@M
         {\cfttoctitlefont\SM@completiontitle}{\cftaftertoctitle}\par}%
        \nobreak\vskip\cftaftertoctitleskip
        \let\@tempa\@empty
        \ifdefined\SM@prev@ready\let\@tempa\relax\fi
        \ifx\SM@ns\SM@cur@ns\let\@tempa\relax\fi
        \ifx\@tempa\relax
            \begingroup
                \SM@ovline{0pt}{}{\bfseries\scshape\SM@totallabel}{all}%
                \medskip
                \def\SM@ovindent{0pt}\SM@ovopenfalse
                % The last "Not done" line ends inside the walk, where its
                % size and indent (set by \SM@ov@problem) are still in force
                \SM@walk{\csname SM@\SM@ns @list\endcsname\par}%
                    \SM@ov@heading\SM@ov@problem
            \endgroup
        \else
            \ClassWarningNoLine{SolutionManual}{Completion overview empty:
                rerun LaTeX}%
        \fi
    \else
        \ClassWarning{SolutionManual}{\protect\completionoverview\space needs
            completion tracking=true}%
    \fi}{}% Suppressed entirely in student editions, including page breaks.
}
\def\SM@cur@ns{cur}
% #1 = Indent, #2 = Anchor (or empty), #3 = Text, #4 = Heading serial (or all)
\newcommand{\SM@ovline}[4]{%
    \par
    {\normalsize
     \leftskip=#1\relax \rightskip=4em\@plus1fil \parfillskip=-\rightskip
     \parindent=\z@ \interlinepenalty\@M
     \leavevmode\ifblank{#2}{{#3}}{\hyperlink{#2}{#3}}\nobreak\cftdotfill{\cftdotsep}\nobreak
     \hb@xt@3em{\hfil\SM@count{done}{#4}/\SM@count{total}{#4}}\par}}
\newif\ifSM@ovopen
\def\SM@ov@heading#1#2#3#4#5{%
    \par\SM@ovopenfalse
    \ifnum\SM@count{total}{#1}>\z@
        \ifcase#2\or
            \addvspace{0.8em}%
            \SM@ovline{0pt}{#5}{\bfseries\scshape #3\quad #4}{#1}%
            \def\SM@ovindent{1.5em}%
        \or
            \SM@ovline{1.5em}{#5}{#3\quad #4}{#1}%
            \def\SM@ovindent{3.8em}%
        \else
            \SM@ovline{3.8em}{#5}{#3\quad #4}{#1}%
            \def\SM@ovindent{7em}%
        \fi
    \fi}
\def\SM@ov@problem#1#2#3#4#5#6#7#8{%
    \ifnum#5=\z@
        \ifSM@ovopen
            ,
        \else
            \par\SM@ovopentrue
            \small\leftskip=\SM@ovindent\relax\rightskip=4em\@plus1fil
            \parindent=\z@\leavevmode{\itshape\SM@notdonelabel:}
        \fi
        \hyperlink{#7}{\SM@problemlabel~#6}\ifblank{#8}{}{~(#8)}%
    \fi}

% ---- Markdown report ---- %
% \jobname-completion.md, in the output folder (latexmk copies it to the
% project root: see latexmkrc). Empty without completion tracking.
\newwrite\SM@mdout
\ExplSyntaxOn
\sys_if_engine_pdftex:TF
  {
    \text_declare_purify_equivalent:Nn \S { ^^c2^^a7 }
    \text_declare_purify_equivalent:Nn \textsection { ^^c2^^a7 }
  }
  {
    \text_declare_purify_equivalent:Nn \S { ^^a7 }
    \text_declare_purify_equivalent:Nn \textsection { ^^a7 }
  }
\text_declare_purify_equivalent:Nn \protect { }
\text_declare_purify_equivalent:Nn \texorpdfstring { \use_ii:nn }
\text_declare_purify_equivalent:Nn \textbackslash { \c_backslash_str }
% \SM@purify\cs{text}: \cs = the text as a Markdown string (math kept as $...$
% without the space that a written control word would leave before the $, and
% | escaped for tables)
\cs_new_protected:Npn \SM@purify #1#2
  {
    \tl_set:Ne #1 { \text_purify:n {#2} }
    \str_set:Ne #1 { \tl_to_str:N #1 }
    \regex_replace_all:nnN { (\\[A-Za-z]+)\ \$ } { \1\$ } #1
    \regex_replace_all:nnN { \| } { \\\| } #1
  }
\ExplSyntaxOff
\newcommand*{\SM@mdline}[1]{\immediate\write\SM@mdout{#1}}
% \count@ = integer percentage, rounded down: #1 = done, #2 = total
\newcommand*{\SM@percent}[2]{%
    \count@=\numexpr#1*100/#2\relax
    \ifnum\numexpr\count@*#2\relax>\numexpr#1*100\relax\advance\count@\m@ne\fi}
\newcommand*{\SM@writemarkdown}{%
    \begingroup
        \def\SM@ns{cur}%
        \let\SM@md@row\@empty
        \SM@purify\SM@md@a{\SM@completiontitle}%
        \SM@purify\SM@md@b{\SM@totallabel}%
        \SM@purify\SM@md@c{\SM@donelabel}%
        \SM@purify\SM@md@d{\SM@notdonelabel}%
        \SM@mdline{<!-- Generated from \jobname.tex by SolutionManual.cls. Do not edit: build the manual to refresh it. -->}%
        \SM@mdline{}%
        \ifnum\SM@count{total}{all}>\z@
            \SM@percent{\SM@count{done}{all}}{\SM@count{total}{all}}%
            \SM@mdline{**\SM@md@a: \SM@count{done}{all}/\SM@count{total}{all}
                (\the\count@\@percentchar)**}%
            \SM@mdline{}%
            \SM@mdline{| | \SM@md@c\space| \SM@md@d\space|}%
            \SM@mdline{| :-- | :-: | :-- |}%
            \SM@mdline{| **\SM@md@b** | \SM@count{done}{all}/\SM@count{total}{all} | |}%
            \ifnum\SM@count{total}{0}>\z@
                \xdef\SM@md@row{| \SM@md@outside\space| \SM@count{done}{0}/\SM@count{total}{0} |}%
                \gdef\SM@md@todo{}%
            \fi
            \SM@walk\SM@cur@list\SM@md@heading\SM@md@problem
            \SM@md@flush
        \else
            \SM@mdline{**\SM@md@a: 0/0**}%
        \fi
    \endgroup}
\newcommand*{\SM@md@outside}{(outside chapters)}
\newcommand*{\SM@md@flush}{%
    \ifx\SM@md@row\@empty\else\SM@mdline{\SM@md@row\space\SM@md@todo\space|}\fi
    \global\let\SM@md@row\@empty}
\def\SM@md@heading#1#2#3#4#5{%
    \SM@md@flush
    \ifnum\SM@count{total}{#1}>\z@
        \SM@purify\SM@md@a{#3 #4}%
        \ifcase#2\or
            \SM@purify\SM@md@a{\chaptername\space#3. #4}%
            \edef\SM@md@a{**\SM@md@a**}%
        \or
            \edef\SM@md@a{&emsp;\SM@md@a}%
        \else
            \edef\SM@md@a{&emsp;&emsp;\SM@md@a}%
        \fi
        \xdef\SM@md@row{| \SM@md@a\space| \SM@count{done}{#1}/\SM@count{total}{#1} |}%
        \gdef\SM@md@todo{}%
    \fi}
\def\SM@md@problem#1#2#3#4#5#6#7#8{%
    \ifnum#5=\z@
        \SM@purify\SM@md@a{\SM@problemlabel\space#6\ifblank{#8}{}{ (#8)}}%
        \xdef\SM@md@todo{\SM@md@todo\ifx\SM@md@todo\@empty\else, \fi\SM@md@a}%
    \fi}

% ---- JSON problem index ---- %
% Walk the same completion records, with extra title/part metadata. Page
% writes are read back from this run's aux file before exporting the index.
\ExplSyntaxOn
\iow_new:N \g__SM_json_iow
\prop_new:N \l__SM_json_units_prop
\prop_new:N \l__SM_json_headings_prop
\tl_new:N \l__SM_json_anchor_tl
\tl_new:N \l__SM_json_number_tl
\tl_new:N \l__SM_json_status_tl
\str_new:N \l__SM_json_string_str
\str_new:N \l__SM_json_unit_str
\str_new:N \l__SM_json_heading_str
\bool_new:N \l__SM_json_first_bool
\bool_new:N \l__SM_json_firstpart_bool
\cs_generate_variant:Nn \str_replace_all:Nnn { Nee }
% Plain text, then JSON escaping (not Markdown table escaping).
\cs_new_protected:Npn \SM@jsonstring #1#2
  {
    \tl_set:Ne #1 { \text_purify:n {#2} }
    \str_set:Ne #1 { \tl_to_str:N #1 }
    \str_replace_all:Nee #1 { \c_backslash_str }
      { \c_backslash_str \c_backslash_str }
    \str_replace_all:Nee #1 { " } { \c_backslash_str " }
    \int_step_inline:nnn { 0 } { 31 }
      {
        \str_replace_all:Nee #1 { \char_generate:nn {##1} {12} }
          { \c_backslash_str u00 \int_compare:nNnT {##1} < {16} {0}
            \int_to_Hex:n {##1} }
      }
  }
\cs_new_protected:Npn \SM@jsonline #1
  { \iow_now:Ne \g__SM_json_iow {#1} }
\cs_new_protected:Npn \SM@json@heading #1#2#3#4#5
  {
    \SM@jsonstring \l__SM_json_string_str {#3}
    \prop_put:NnV \l__SM_json_units_prop {#1} \l__SM_json_string_str
    \SM@jsonstring \l__SM_json_string_str {#4}
    \prop_put:NnV \l__SM_json_headings_prop {#1} \l__SM_json_string_str
  }
\cs_new_protected:Npn \SM@json@problem #1#2#3#4#5#6#7#8
  {
    \tl_set:Nn \l__SM_json_anchor_tl {#7}
    \tl_set:Nn \l__SM_json_number_tl {#6}
    \tl_set:Nn \l__SM_json_status_tl {#5}
  }
\cs_new_protected:Npn \SM@jsonfield #1#2#3
  {
    \SM@jsonstring \l__SM_json_string_str {#2}
    \SM@jsonline { ~~"#1":~"\l__SM_json_string_str"#3 }
  }
\cs_new_protected:Npn \SM@jsonpages #1#2
  {
    \cs_if_exist:cTF { SM@json@page@#1@#2 }
      { \SM@jsonfield {#2_page} { \use:c { SM@json@page@#1@#2 } } {,} }
      { \SM@jsonline { ~~"#2_page":~null, } }
  }
\cs_new_protected:Npn \SM@json@details #1#2#3#4
  {
    \bool_if:NTF \l__SM_json_first_bool
      { \bool_set_false:N \l__SM_json_first_bool } { \SM@jsonline {,} }
    \SM@jsonline { \c_left_brace_str }
    \SM@jsonfield {anchor} {\l__SM_json_anchor_tl} {,}
    \SM@jsonfield {number} {\l__SM_json_number_tl} {,}
    \prop_get:NnNTF \l__SM_json_units_prop {#2} \l__SM_json_unit_str
      { } { \str_clear:N \l__SM_json_unit_str }
    \prop_get:NnNTF \l__SM_json_headings_prop {#2} \l__SM_json_heading_str
      { } { \str_clear:N \l__SM_json_heading_str }
    % These two values were already escaped when the heading was visited.
    \SM@jsonline { ~~"unit":~"\l__SM_json_unit_str", }
    \SM@jsonline { ~~"heading_title":~"\l__SM_json_heading_str", }
    \SM@jsonfield {title} {#3} {,}
    \SM@jsonfield {status}
      { \int_compare:nNnTF {\l__SM_json_status_tl} = {1} {done} {not~done} } {,}
    \SM@jsonpages {#1} {first}
    \SM@jsonpages {#1} {last}
    \SM@jsonline { ~~"parts":~[ }
    \bool_set_true:N \l__SM_json_firstpart_bool
    #4
    \SM@jsonline { ] }
    \SM@jsonline { \c_right_brace_str }
  }
\cs_new_protected:Npn \SM@jsonpart #1#2#3#4
  {
    \bool_if:NTF \l__SM_json_firstpart_bool
      { \bool_set_false:N \l__SM_json_firstpart_bool } { \SM@jsonline {,} }
    \SM@jsonline { \c_left_brace_str }
    \SM@jsonfield {anchor} {#4} {,}
    \SM@jsonfield {number} {#1} {,}
    \SM@jsonfield {title} {#2} {,}
    \SM@jsonfield {status}
      { \int_compare:nNnTF {#3} = {1} {done} {not~done} } { }
    \SM@jsonline { \c_right_brace_str }
  }
\cs_new_protected:Npn \SM@writejson
  {
    \group_begin:
      \iow_open:Nn \g__SM_json_iow { \jobname-problems.json }
      \SM@jsonline { \c_left_brace_str "problems":~[ }
      \bool_set_true:N \l__SM_json_first_bool
      \prop_clear:N \l__SM_json_units_prop
      \prop_clear:N \l__SM_json_headings_prop
      \cs_set_eq:NN \SM@do@details \SM@json@details
      \SM@walk \SM@cur@list \SM@json@heading \SM@json@problem
      \SM@jsonline { ] \c_right_brace_str }
      \iow_close:N \g__SM_json_iow
    \group_end:
  }
\ExplSyntaxOff
\AddToHook{enddocument/afteraux}{\ifSM@completion\SM@writejson\fi}

\AtEndDocument{%
    \SM@finishproblem
    \immediate\openout\SM@mdout=\jobname-completion.md\relax
    \ifSM@completion
        \SM@writemarkdown
        \immediate\write\@auxout{\string\SM@prevready}%
        \ifx\SM@cur@list\SM@prev@list\else
            \ClassWarningNoLine{SolutionManual}{Completion data may have
                changed. Rerun to get the overview right}%
        \fi
    \fi
    \immediate\closeout\SM@mdout
    \let\SM@prev\@gobble % the aux file is read again at the end
    \let\SM@prevready\relax}

% ============ Title Page ============ %
% The subtitle line (\firstTitle) is omitted when it is empty. The title page
% has no page anchor, since the next page is numbered 1 again.
\renewcommand{\maketitle}{%
\hypersetup{pageanchor=false}%
\begin{titlepage}
        \centering
        \SM@ifnotblank{\SM@titleprefix}{\textsc{\Large \SM@titleprefix}\par\vspace{1.5cm}}
        \SM@ifnotblank{\firstTitle}{\textsc{\LARGE \firstTitle}\par\vspace{0.5cm}}
        \rule{\textwidth}{0.8pt}\par\vspace{0.4cm}
        {\huge\bfseries\scshape \textcolor{ThemeColor}{\mainTitle}\par}
        \vspace{0.5cm}
        \rule{\textwidth}{0.8pt}\par\vspace{1.5cm}
        \SM@ifnotblank{\authorName}{{\large \textit{\SM@authorlabel}\par \authorName\par}}
        \vfill
        {\large \SM@date\par}
\end{titlepage}
\hypersetup{pageanchor=true}%
}

% ============ Headers and footers ============ %
\renewcommand{\chaptermark}[1]{\markboth{#1}{}\InsertMark{SMproblem}{}}
\pagestyle{fancy}
\renewcommand{\sectionmark}[1]{\InsertMark{SMproblem}{}}
\renewcommand{\subsectionmark}[1]{\InsertMark{SMproblem}{}}
\fancyhf{} % clear existing header/footer entries
\setlength{\headheight}{15pt}

% Only footer for chapter page
\fancypagestyle{plain}{%
\fancyhf{}%
\renewcommand{\headrulewidth}{0.0pt}%
\fancyfoot[L]{\footnotesize \scshape \SM@footer}
\fancyfoot[R]{\footnotesize \scshape Page \thepage\ of \pageref{LastPage}}}

% Header and footer for other pages
\fancyfoot[L]{\footnotesize \scshape \SM@footer}
\fancyfoot[R]{\footnotesize \scshape Page \thepage\ of \pageref{LastPage}}
% The solutions part follows the last chapter but shows its own title alone
\fancyhead[L]{%
    \ifnum\ifSM@insolutions 0\else\value{chapter}\fi>0\relax
        \hyperlink{chapter-title.\theHchapter}{\scshape \chaptername{}~\thechapter. \quad \leftmark}%
    \else
        {\scshape \leftmark}%
    \fi}
\fancyhead[R]{\LastMark{SMproblem}}

% ============ End of Class ============ %
\endinput

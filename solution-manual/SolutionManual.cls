% ============ Identification ============ %
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{SolutionManual}[2026/10/16 Solution Manual Template]

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
\newcommand*{\SM@date}{\today}
\newcommand*{\SM@contentslabel}{Table of Contents}
\newcommand*{\SM@problemlabel}{Problem}
\newcommand*{\SM@solutionlabel}{Solution:}
\newcommand*{\SM@answerlabel}{Answer to Problem}
\newcommand*{\SM@footer}{%
    \SM@titleprefix~\mainTitle
    \SM@ifnotblank{\authorName}{~by \authorName}}

% Colors: ThemeColor is a named color; the boxes use color expressions, which
% are evaluated where they are used (so they follow later ThemeColor changes).
\colorlet{ThemeColor}{red!50!black}
\newcommand*{\SM@questionback}{gray!5!white}
\newcommand*{\SM@questionframe}{gray!50!black}
\newcommand*{\SM@subquestionframe}{gray!75!black}
\newcommand*{\SM@answerback}{ThemeColor!5!white}
\newcommand*{\SM@answerframe}{ThemeColor}
\newcommand*{\SM@subanswerframe}{ThemeColor}

% Each problem starts on a new page
\newif\ifSM@problemnewpage
\SM@problemnewpagetrue

% \SolutionManualSetup{key=value, ...}, in the preamble (after \documentclass)
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
}
\newcommand{\SolutionManualSetup}[1]{\pgfqkeys{/SolutionManual}{#1}}

% \SM@ifnotblank{\macro}{code}: code unless the macro is empty or blank
\newcommand{\SM@ifnotblank}[2]{\expandafter\ifblank\expandafter{#1}{}{#2}}

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

% ============ Colors ============ %
\hypersetup{
    colorlinks,
    linkcolor=ThemeColor,
    urlcolor=ThemeColor,
}

% ============ Chapter ============ %
\titleformat{\chapter}[display]
  {\centering}
  {\hypertarget{\thechapter}{\huge \scshape \chaptername{} \textcolor{ThemeColor}{\Huge\bfseries \thechapter}.}}
  {1ex}
  {\titlerule[0.8pt] \LARGE \scshape}

% ============ Problems environment ============ %
% Problems are numbered within chapters, subproblems within problems.
% \ref gives "2.3" for a problem and "2.3(a)" for a subproblem.
\newcounter{ProblemNum}[chapter]
\renewcommand{\theProblemNum}{\arabic{ProblemNum}}
\renewcommand{\p@ProblemNum}{\thechapter.}
\newcounter{SubProblemNum}[ProblemNum]
\renewcommand{\theSubProblemNum}{(\alph{SubProblemNum})}
\renewcommand{\p@SubProblemNum}{\thechapter.\theProblemNum}
% Unique hyperlink anchors across chapters and problems
\def\theHProblemNum{\theHchapter.\arabic{ProblemNum}}
\def\theHSubProblemNum{\theHProblemNum.\arabic{SubProblemNum}}

% Define question environment
\newtcolorbox{question}{enhanced, breakable,
                      colback=\SM@questionback,
                      colframe=\SM@questionframe,
                      title=\hypertarget{\thechapter-\theProblemNum}{\scshape \SM@problemlabel{} \theProblemNum}.
                      }

% Define subproblem environment
\newtcolorbox{subquestion}{enhanced, breakable,
                           colback=\SM@questionback,
                           colframe=\SM@subquestionframe,
                           title=\theSubProblemNum
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

% Solution and answer of a problem or subproblem; each one is omitted when
% its argument is empty or blank.
% #1 = Solution
% #2 = Answer
% #3 = Answer environment (answer or subanswer)
\newcommand{\SM@solutionandanswer}[3]{%
    \ifblank{#1}{}{\solution #1\par}%
    \ifblank{#2}{}{\begin{#3}#2\end{#3}}%
}

% Wrapper for problems
% #1 = Question
% #2 = Solution (optional: leave empty)
% #3 = Answer (optional: leave empty)
\newenvironment{problem}[3]
{%
    \ifSM@problemnewpage\clearpage\else\par\bigskip\fi
    \refstepcounter{ProblemNum}\label{\thechapter-\theProblemNum}%
    \pdfbookmark[1]{\SM@problemlabel\space\theProblemNum}{problem\thechapter-\theProblemNum}%
    \addtocontents{toc}{\hspace{2em}\protect\hyperlink{\thechapter-\theProblemNum}{\scshape \SM@problemlabel~\theProblemNum.}\hspace{0.5em}\dotfill\thepage\par}%
    \begin{question}
        #1
    \end{question}
    \SM@solutionandanswer{#2}{#3}{answer}%
}{\par}

% Wrapper for subproblems, after a problem
% #1 = Question
% #2 = Solution (optional: leave empty)
% #3 = Answer (optional: leave empty)
\newenvironment{subproblem}[3]
{%
    \par
    \refstepcounter{SubProblemNum}%
    \begin{subquestion}
        #1
    \end{subquestion}
    \SM@solutionandanswer{#2}{#3}{subanswer}%
}{\par}

% Link to a problem
% #1 = Chapter number
% #2 = Problem number
\newcommand{\probref}[2]{\hyperlink{#1-#2}{Chap.~#1 Prob.~#2}}

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
\renewcommand{\chaptermark}[1]{\markboth{#1}{}}
\pagestyle{fancy}
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
\fancyhead[L]{%
    \ifnum\value{chapter}>0\relax
        \hyperlink{\thechapter}{\scshape \chaptername{}~\thechapter. \quad \leftmark}%
    \else
        {\scshape \leftmark}%
    \fi}
\fancyhead[R]{%
    \ifnum\value{ProblemNum}>0\relax
        \hyperlink{\thechapter-\theProblemNum}{\scshape \SM@problemlabel~\theProblemNum.}%
    \fi}

% ============ End of Class ============ %
\endinput

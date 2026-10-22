# Chapters, sections and numbering

[Back to README](../README.md)

Problems are grouped by the standard `\chapter`, `\section` and `\subsection`:
a problem belongs to the last of these headings before it. All the problems of
a chapter are at the same level: directly in the chapter, all in its sections,
or all in its subsections (LaTeX stops with an error otherwise). Chapters can
have different structures, and any problem can have parts:

```tex
\chapter{Kinematics}                 % problems directly in the chapter
\begin{problem}...\end{problem}

\chapter{Dynamics}                   % problems in sections
\section{Newton's laws}
\begin{problem}...\end{problem}
\section{Friction}
\begin{problem}...\end{problem}
```

Starred headings (`\section*`) are plain titles: they group nothing.

## Numbering

The `problem numbering` key sets where the numbering restarts at 1:

| Value               | Restarts at                   | `\ref` of problem 2 of section 3.1 |
| ------------------- | ----------------------------- | ---------------------------------- |
| `chapter` (default) | each chapter                  | `3.n` (its number in chapter 3)    |
| `subdivision`       | each section (or subsection)  | `3.1.2`                            |
| `continuous`        | never                         | `n` (its number in the manual)     |

With `subdivision`, the problems of a chapter without sections are numbered
within the chapter. Set the key in the preamble, or in the document before a
`\chapter` to change the numbering from that chapter on (a change restarts
the numbering at 1):

```tex
\SolutionManualSetup{problem numbering=subdivision}
\chapter{...}
```

## Textbook numbers

To show the textbook's number instead of the manual's, put `\textbooknumber`
before a `\chapter`, `\section` or `\subsection`:

```tex
\textbooknumber{\S 12}
\section{Series}            % §12; its subsections are §12.1, §12.2, ...
```

The number appears in the heading, contents, bookmarks, running header and
references. The automatic numbering of the next headings is unchanged.

## Page breaks, contents, bookmarks and headers

With `problem on new page` (the default), a section or subsection heading
starts a new page and its first problem follows it on that page; consecutive
headings, and any text between a heading and its first problem, share that
page. Chapter titles keep their own page. Without `problem on new page`, a
heading moves to the next page when less than six lines remain.

Problems are listed under their heading in the contents, bookmarks are nested
(section bookmarks show their number), and the right-hand header shows the
section where numbering restarts, e.g. `§12  Problem 2.`. Hyperlink targets
stay unique when problem numbers repeat.

## References

- `\label` in a question, then `\ref`: the full number, `1.2`, `1.2(a)`,
  `3.1.2`, `§12.2(a)`;
- `\probref{unit}{number}`: a link to a problem from the number of the
  chapter or section where its numbering restarts, as shown (the chapter in
  chapter and continuous numbering), and its own number:

  | Reference              | Text                  |
  | ---------------------- | --------------------- |
  | `\probref{1}{2}`       | Chap. 1 Prob. 2       |
  | `\probref{3.1}{2}`     | Sec. 3.1 Prob. 2      |
  | `\probref{\S 12}{2}`   | §12 Prob. 2           |
  | `\probref{4}{47}`      | Prob. 47 (continuous) |
  | `\probref[text]{1}{2}` | text                  |

  Write a textbook number as in `\textbooknumber`. Like `\ref`, an unknown
  problem gives "??" and a warning;
- equations and figures: the usual `\label`, `\eqref` and `\ref`.

The keys `chapter abbreviation`, `section abbreviation` and
`problem abbreviation` change "Chap.", "Sec." and "Prob.". If two subdivisions
are shown with the same number, `\probref` links to the first one and LaTeX
warns.

# Writing problems

[Back to README](../README.md)

```tex
\begin{problem}
{Question.}
{Worked solution.}
{Final answer.}
[Verification.]
\end{problem}
```

The solution and the answer are optional: leave either argument empty (`{}`)
to omit it. An argument with only spaces or blank lines counts as empty. For a
problem in parts, give the main question with `{}{}`, then add `subproblem`
environments, which take the same arguments:

```tex
\begin{problem}{Main question.}{}{}\end{problem}
\begin{subproblem}{Part (a).}{Solution.}{Answer.}[Check.]\end{subproblem}
\begin{subproblem}{Part (b), a proof.}{Proof.}{}\end{subproblem}
```

Add a short title in the optional argument before the question:

```tex
\begin{problem}[title={Period of a simple pendulum}]
{Find the period.}{Worked solution.}{Final answer.}\end{problem}
\begin{subproblem}[done, title={Small-angle approximation}]
{State the approximation.}{}{Answer only.}\end{subproblem}
```

The heading reads "Problem 3. Period of a simple pendulum" (or
"(a) Small-angle approximation" for a part). Titles also appear in PDF
bookmarks and the table of contents; a titled part gets an entry beneath its
parent. Set `\SolutionManualSetup{problem titles in contents=false}` to keep
plain problem entries and omit part entries from the contents. This setting
does not hide titles in headings or bookmarks.

`[done]` and `[not done]` still work alone or alongside `title={...}`, in
either order. Use braces around a title containing commas. Empty or
space-only titles act like no title, and titles do not change completion
status. Untitled problems and parts retain their original presentation.
Titles are moving arguments: for mathematics in a bookmark, use, for example,
`title={Period \texorpdfstring{$T$}{T}}`.

Verification is optional and comes last, after the answer: omit
`[Verification.]` entirely when it is not needed. Empty or whitespace-only
contents inside `[...]` also omit it. It appears under a small-caps
"Verification:" heading, matching the solution heading, and can span pages.
Place the opening `[` on the same line as the answer's closing `}` or on the
next line, with no intervening blank line. Balanced nested brackets work;
protect unmatched square brackets, such as a half-open interval, by wrapping
the verification contents in braces:

```tex
{Answer.}
[{Check that $x \in [0,1)$.}]
```

The `problem label`, `solution label`, `answer label` and `verification label`
keys of `\SolutionManualSetup` customize the headings. Verification does not
change completion status; that still depends on the solution or the explicit
`[done]` / `[not done]` status before the question.

Use `\SolutionManualSetup{solutions=hidden}` for questions alone, or
`solutions=answers only` for questions and final-answer boxes. Both modes omit
worked solutions and verification, including those of subproblems. The default,
`solutions=shown`, prints everything as usual. `answers at end` is reserved for
a later step and currently reports an error.

To include a worked example in either student edition, add `[show solution]`
or `[done, show solution]` before its question. This restores that problem's
solution, answer and verification. The same option works on a `subproblem`;
each problem or part needs its own override. Numbering, question labels,
`\ref`, `\probref` and the `problem on new page` setting work in every mode.

Completion still follows the source solution and status overrides, even when
the response is hidden. Student editions suppress completion markers and
`\completionoverview` unless `completion markers=true` is set; see
[Completion tracking](completion-tracking.md).

Problems start on a new page (see `problem on new page`); questions can
span several pages, and an answer box is kept on the page where its solution
ends. Final-answer boxes stay whole, so their contents must fit on one page.
Long solutions can paginate between text and displayed equations. Arguments can
contain displayed equations (`align`, ...),
figures and tables, but not verbatim text.

The [showcase chapters](../examples/showcase/Chapters/) show every case: ordinary
problems, subproblems with and without solution or answer, verification
sections, a question alone, equations, figures, a table and references across
chapters. [3-Sections.tex](../examples/showcase/Chapters/3-Sections.tex) adds sections
with their own numbering, a textbook section number, `\probref` and completion
tracking. [4-Showcase.tex](../examples/showcase/Chapters/4-Showcase.tex) combines most
of them on one page.

# French example

A small solution manual in French for the
[Solution Manual Template](../../README.md): two problems, one figure, and
`babel` with the `french` option.

From this directory, run:

```sh
latexmk
```

- [`mytheme.sty`](mytheme.sty) sets `\SolutionManualSetup{language=french}`,
  so the manual uses the French texts of
  [`SolutionManual-french.def`](../../solution-manual/SolutionManual-french.def)
  and the figures print decimal commas.
- [`mypackages.sty`](mypackages.sty) loads `babel` (French typography and
  hyphenation), `fontenc` and `icomma`. The class labels take precedence over
  babel's names, so `contents label` and `chapter label` still apply.
- [`main.tex`](main.tex) sets the title and author. Keys given there override
  the French texts, e.g. `problem label={Exercice}`.

The build writes `main.pdf`, `COMPLETION.md`, `Figures/Chute.pdf` and `build/`
here. See [Languages](../../docs/customization.md#languages) to add another
language.

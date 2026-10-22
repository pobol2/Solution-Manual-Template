# Using the framework in another project

This is the advanced path for using the framework as a Git submodule. For the
standard self-contained copy, follow the README's
[Use this template quick start](../README.md#quick-start).

[Back to README](../README.md)

The [`solution-manual/`](../solution-manual/) folder is the shared part of the
[Solution Manual Template](../README.md): classes and build rules, without
content or build outputs. Projects customize them from their own files and
never edit the framework folder.

| File                   | Purpose                                                     |
| ---------------------- | ----------------------------------------------------------- |
| `SolutionManual.cls`   | Class of the manual (pdfLaTeX)                              |
| `SolutionFigure.cls`   | Class of the standalone TikZ/PGFPlots figures (LuaLaTeX)    |
| `latexmkrc`            | Build rules, loaded by the project's `latexmkrc`            |
| `vscode-settings.json` | LaTeX Workshop settings, to copy to `.vscode/settings.json` |

## Using it from another project

Git cannot use a subfolder of a repository as a submodule, so a project adds
the whole template repository and points to the framework folder inside it:

```sh
git submodule add https://github.com/pobol2/Solution-Manual-Template.git template
```

This records a specific template commit; updates are adopted deliberately.

The project then has, in its root:

- `latexmkrc`, a copy of the template's, with
  `$framework_dir = 'template/solution-manual';` (a relative or absolute path,
  spaces allowed);
- `.vscode/settings.json`, a copy of `vscode-settings.json`;
- its own `main.tex`, `Chapters/`, `Figures/`, `mypackages.sty`,
  `mycommands.sty`, `myfigures.sty` and (optional) `mytheme.sty`;
- `.gitignore` entries for `build/` and `Figures/*.pdf`.

With completion tracking, the build copies the report to `COMPLETION.md`.
See [build settings](customization.md#build-settings) to rename or disable it,
or [report in a README](completion-tracking.md#report-in-a-readme) to embed it
in a Markdown file.

`latexmk` runs from the project root and adds the framework folder to
`TEXINPUTS`, so `\documentclass{SolutionManual}` and
`\documentclass{SolutionFigure}` work unchanged. All outputs (`build/`,
`Figures/*.pdf`, the final PDF) stay in the project; nothing is written to the
framework folder. Figures are rebuilt when a file they read changes in the
project or in the framework folder (for example after updating the submodule),
but not when the TeX distribution changes.

## Adapting an existing manual

Keep its chapters, figures and subject-specific commands in the project. Move
any specialized packages, TikZ styles and figure commands from an old figure
class into the project's `myfigures.sty`. Companion Lua or data files also stay
in the project; record Lua inputs with `kpse.record_input_file` so the build
tracks them.

Remove or rename old project-local `SolutionManual.cls` and `SolutionFigure.cls`
copies after preserving any customizations. Local copies take precedence over
the shared classes and would prevent template updates from taking effect.

Review the font size during migration: old versions ignored class options and
used 10-point text. Use `10pt` explicitly to retain that size. Class options and
the older title/author commands remain supported.

## Cloning and updating

Clone a manual that uses the template with `git clone --recurse-submodules`.
If it has already been cloned, run:

```sh
git submodule update --init --recursive
```

To pin the template to a release tag, fetch the tags and check out the chosen
version (for example, `v1.2.0`):

```sh
git -C template fetch --tags
git -C template checkout v1.2.0
```

Compile and review the manual, then commit the updated submodule reference in
the manual's repository. Keep project customizations outside the submodule.

## License

The framework is licensed under the [MIT License](../LICENSE), copyright
(c) 2026 P.O. Bolduc. Retain the copyright and license notices when
redistributing it. If you copy `solution-manual/` without the rest of the
repository, include a copy of `../LICENSE` with it. Your manual's own content
can use a different license.

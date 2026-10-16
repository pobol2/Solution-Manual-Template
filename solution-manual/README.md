# solution-manual

The shared part of the [Solution Manual Template](../README.md): classes and
build rules, without content or build outputs. Projects customize them from
their own files and never edit this folder.

| File                   | Purpose                                                     |
| ---------------------- | ----------------------------------------------------------- |
| `SolutionManual.cls`   | Class of the manual (pdfLaTeX)                              |
| `SolutionFigure.cls`   | Class of the standalone TikZ figures (LuaLaTeX)             |
| `latexmkrc`            | Build rules, loaded by the project's `latexmkrc`            |
| `vscode-settings.json` | LaTeX Workshop settings, to copy to `.vscode/settings.json` |

## Using it from another project

Git cannot use a subfolder of a repository as a submodule, so a project adds
the whole template repository and points to this folder inside it:

```sh
git submodule add YOUR_TEMPLATE_REPOSITORY_URL template
```

Replace `YOUR_TEMPLATE_REPOSITORY_URL` with the GitHub URL of this repository.
This records a specific template commit; updates are adopted deliberately.

The project then has, in its root:

- `latexmkrc`, a copy of the template's, with
  `$framework_dir = 'template/solution-manual';` (a relative or absolute path,
  spaces allowed);
- `.vscode/settings.json`, a copy of `vscode-settings.json`;
- its own `main.tex`, `Chapters/`, `Figures/`, `mypackages.sty`,
  `mycommands.sty` and `myfigures.sty`;
- `.gitignore` entries for `build/` and `Figures/*.pdf`.

`latexmk` runs from the project root and adds this folder to `TEXINPUTS`, so
`\documentclass{SolutionManual}` and `\documentclass{SolutionFigure}` work
unchanged. All outputs (`build/`, `Figures/*.pdf`, the final PDF) stay in the
project; nothing is written here. Figures are rebuilt when a file they read
changes in the project or in this folder (for example after updating the
submodule), but not when the TeX distribution changes.

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

To adopt the template's latest tracked branch version:

```sh
git submodule update --remote template
```

Compile and review the manual, then commit the updated submodule reference in
the manual's repository. Keep project customizations outside the submodule.

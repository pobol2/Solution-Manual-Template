"""Check release metadata and package already-built manuals (standard library only)."""

import argparse
from pathlib import Path
import re
import shutil
from zipfile import ZIP_DEFLATED, ZipFile


VERSION = r"\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?"


def check_versions(root, tag=None):
    changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
    heading = re.search(rf"^## \[({VERSION})\][^\n]*$", changelog, re.MULTILINE)
    if heading is None:
        raise ValueError("CHANGELOG.md has no version section")
    version = heading[1]
    framework = root / "solution-manual"
    # The classes, and the language files they read (\ProvidesFile)
    files = [("Class", framework / f"{name}.cls") for name in ("SolutionManual", "SolutionFigure")]
    files += [("File", path) for path in sorted(framework.glob("SolutionManual-*.def"))]
    for command, path in files:
        name = path.stem if command == "Class" else path.name
        metadata = re.search(
            rf"^\\Provides{command}\{{{re.escape(name)}\}}\[\d{{4}}/\d{{2}}/\d{{2}}\s+(v[^\s\]]+)",
            path.read_text(encoding="utf-8"),
            re.MULTILINE,
        )
        if metadata is None or metadata[1] != f"v{version}":
            actual = metadata[1] if metadata else "missing version"
            raise ValueError(f"{path.name}: {actual}; expected v{version} from CHANGELOG.md")
    if tag is not None and tag != f"v{version}":
        raise ValueError(f"Tag {tag!r} does not match top changelog version v{version}")

    # Stop at the next release heading, excluding the reference links at EOF.
    notes = re.split(r"^## |^\[[^\]]+\]:", changelog[heading.end():], maxsplit=1,
                     flags=re.MULTILINE)[0].strip()
    if not notes:
        raise ValueError(f"CHANGELOG.md has no notes for {version}")
    print(f"Class and language file versions match CHANGELOG.md: v{version}")
    return notes + "\n"


def add_folder(archive, source, destination):
    for path in sorted(source.rglob("*")):
        # Python caches of the website builder are local files
        if path.is_file() and "__pycache__" not in path.parts:
            archive.write(path, f"{destination}/{path.relative_to(source).as_posix()}")


def package_release(root, tag, output):
    notes = check_versions(root, tag)
    projects = {"starter": root, "showcase": root / "examples/showcase"}
    pdf_assets = {
        "main.pdf": root / "main.pdf",
        "showcase.pdf": projects["showcase"] / "main.pdf",
        "showcase-exercises.pdf": projects["showcase"] / "exercises.pdf",
        "showcase-answers.pdf": projects["showcase"] / "answers.pdf",
        "french.pdf": root / "examples/french/main.pdf",
    }
    # Fail before packaging if a clean build did not produce all expected PDFs.
    for pdf in pdf_assets.values():
        if not pdf.is_file():
            raise ValueError(f"Missing built PDF: {pdf}")
    for project in projects.values():
        for pdf in (
            source.with_suffix(".pdf") for source in (project / "Figures").rglob("*.tex")
        ):
            if not pdf.is_file():
                raise ValueError(f"Missing built PDF: {pdf}")

    output.mkdir(parents=True, exist_ok=True)
    (output / "release-notes.md").write_text(notes, encoding="utf-8")
    for name, source in pdf_assets.items():
        shutil.copyfile(source, output / name)
    with ZipFile(output / f"solution-manual-{tag}.zip", "w", ZIP_DEFLATED) as archive:
        add_folder(archive, root / "solution-manual", "solution-manual")
        # Keep the license inside the framework-only archive.
        archive.write(root / "LICENSE", "solution-manual/LICENSE")

    # Use the starter's root-relative configuration for both standalone projects.
    config = (root / "latexmkrc").read_text(encoding="utf-8")
    config += "\n# Overleaf keeps the PDF in its output folder.\n$copy_to_root = 0;\n"
    for name, project in projects.items():
        with ZipFile(output / f"overleaf-{name}.zip", "w", ZIP_DEFLATED) as archive:
            archive.write(project / "main.tex", "main.tex")
            for path in sorted(project.glob("my*.sty")):
                archive.write(path, path.name)
            for folder in ("Chapters", "Figures"):
                add_folder(archive, project / folder, folder)
            add_folder(archive, root / "solution-manual", "solution-manual")
            archive.write(root / "LICENSE", "LICENSE")
            archive.write(root / "CHANGELOG.md", "CHANGELOG.md")
            archive.writestr("latexmkrc", config)
            archive.writestr(
                "README.md",
                f"# Solution Manual Template: {name} ({tag})\n\n"
                "In Overleaf, select pdfLaTeX and main.tex as the main document.\n"
                "Always open main.tex before clicking Recompile.\n"
                "Keep the included Figures/*.pdf; changed figures rebuild with LuaLaTeX.\n"
                "If a figure times out, build locally with latexmk and upload its PDF.\n\n"
                "Full guide: https://github.com/pobol2/Solution-Manual-Template/"
                f"blob/{tag}/docs/overleaf.md\n",
            )
    print(f"Release assets and notes written to {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("check", help="compare the class and language file versions to the changelog")
    check.add_argument("--tag", help="also require this release tag to match")
    package = commands.add_parser("package", help="package the clean builds and release notes")
    package.add_argument("tag")
    package.add_argument("--output", type=Path, default=Path("dist"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    try:
        if args.command == "check":
            check_versions(root, args.tag)
        else:
            package_release(root, args.tag, args.output)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Release preparation failed: {error}\n")


if __name__ == "__main__":
    main()

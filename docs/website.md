# Website

[Back to README](../README.md)

`solution-manual/site/build.py` turns a built manual into a static website: a
catalogue of every problem by chapter, section and subsection, with the
progress of the manual, and a page and a PDF for each solved problem. The
pages are plain HTML and CSS, in the language of the manual (English or
French), so any static host can serve them, GitHub Pages included.

The [live demo](https://pobol2.github.io/Solution-Manual-Template/) is the
website of the [showcase](../examples/showcase/site/site.toml), published by
the template's [GitHub Pages workflow](#github-pages). The
[starter](../site/site.toml) and the [French](../examples/french/site/site.toml)
example have a website too; CI builds and checks all three, and uploads them
as the `starter-site`, `showcase-site` and `french-site` artifacts.

## Setup

The website is made from the manual's [JSON problem
index](completion-tracking.md#json-problem-index), so it needs:

- `completion tracking=true` in `main.tex`;
- `solutions=shown` (the default) for the manual. [Editions](editions.md) keep
  their own modes; the homepage can link to them (`editions` below);
- each problem on a new page: `problem on new page=true` (the default);
- Python 3.11 or later, with `pypdf`:

  ```sh
  python -m pip install -r solution-manual/site/requirements.txt
  ```

Set up the website in `site/site.toml`, in the project root (the starter has
one to edit):

```toml
title = "Solutions to Classical Mechanics"
short_name = "Classical Mechanics"
author = "Your Name"
description = "Worked solutions to the problems of Classical Mechanics, chapter by chapter: {done} of {total} so far."
base_url = "https://your-name.github.io/your-repository/"
repository = "https://github.com/your-name/your-repository"
license = "https://creativecommons.org/licenses/by/4.0/"
```

Then, from the project root, build the manual and the website:

```sh
latexmk
python solution-manual/site/build.py
```

The website is written to `_site/`, which the template's `.gitignore`
ignores. Each build deletes and rewrites that folder, so `--out` refuses
a folder that is not empty and was not written by `build.py`.

```text
python solution-manual/site/build.py [--out _site] [--base-url URL]
```

`--base-url` replaces `base_url` of `site.toml`, for example with the address
that GitHub Pages gives the site (see [GitHub Pages](#github-pages)).

## Settings

`site/site.toml` takes these settings:

| Setting | Required | Use |
| ------- | -------- | --- |
| `title` | yes | Title of the homepage and name of the site; 60 characters at most. |
| `short_name` | yes | Short name, added to the title of a problem page when it fits: `§9 Problem 3: Title \| Short name`. |
| `author` | yes | Author of the solutions: pages, footer, structured data. |
| `description` | yes | Description of the homepage, also its first paragraph: 25 to 160 characters, where `{done}` and `{total}` are the numbers of solved and of all problems. |
| `base_url` | yes | Public address of the site, for canonical URLs, the sitemap and the links of the PDFs. |
| `repository` | yes | Address of the project's repository, linked from every page, with a link to report an error (a new issue on GitHub and GitLab). |
| `license` | yes | Address of the license of the solutions; Creative Commons addresses are shown as `CC BY 4.0`, ... |
| `publish_unsolved` | no | `true` to publish the PDFs of the unsolved problems too, linked from the catalogue (default `false`: they are listed, without a link). |
| `editions` | no | [Editions](editions.md) to link from the homepage, by name (`%editions` in `latexmkrc`): `["exercises", "answers"]`. Each one is described by its solutions mode ("questions only", ...) and published as `<name>.pdf`; the build stops if one is missing or out of date. |
| `google_site_verification` | no | Code of the Google Search Console HTML tag, added to the homepage. |
| `[book]` | no | The book of the problems; see below. |

Unknown settings are errors, so a misspelled one does not go unnoticed.

### Book

For the solutions of a textbook, a `[book]` table describes it:

```toml
[book]
authors = ["L. D. Landau", "E. M. Lifshitz"]   # required, with title
title = "Mechanics"
edition = "Third edition"
year = 1976
publisher = "Butterworth-Heinemann"
isbn = "978-0-7506-2896-9"                    # checked: ISBN-10 or ISBN-13
```

The book is shown under the title of the homepage and on each problem page,
described in the structured data of every page (schema.org `Book`), and named
in the problem descriptions by the surnames of its authors and its title
("Worked solution to §9 Problem 3 of Landau and Lifshitz, Mechanics: ...").
The footer then says that the solutions are unofficial. Without a book, the
descriptions use `short_name`.

### Problem titles

Problem titles come from the sources, `\begin{problem}[title={...}]` (see
[Writing problems](writing-problems.md)). A project without them can give
titles in `site/problems.toml`, by [problem ID](#problem-ids):

```toml
s9-p3 = "Period of a pendulum"
c2-p1 = "Free fall"
```

A title given in both places is an error. Titles are plain text: for math,
give the plain text with `\texorpdfstring{$M_z$}{M_z}`, where `_z` is shown as
a subscript on the website. A problem without a title shows the title of its
section or chapter. Every problem title must fit, with its label, in the
60 characters of a page title; the build stops otherwise.

## Preview locally

The pages link to each other with relative links, so `_site/index.html` can be
opened directly. A local server shows the site as published, with the PDFs
inside the problem pages:

```sh
python -m http.server --directory _site 8000
```

and open <http://localhost:8000/>. The links inside the problem PDFs are
absolute (`base_url`), so that a downloaded PDF keeps working links: they lead
to the published site, not to the preview.

## GitHub Pages

The template's [`website.yml`](../.github/workflows/website.yml) workflow
builds the manual with `latexmk`, then the website, and publishes it on GitHub
Pages on each push to the repository's default branch. Pull requests and
pushes to other branches build and check the website without publishing it,
so a change that breaks it fails before it is merged.

The workflow is off until the repository opts in, so that a repository
created with **Use this template** gets no failing run. Edit `site/site.toml`
first, then, in the repository on GitHub:

1. **Settings > Pages > Build and deployment > Source:** select
   **GitHub Actions**.
2. **Settings > Secrets and variables > Actions > Variables > New repository
   variable:** name `SOLUTION_MANUAL_WEBSITE`, value `true`.

The next push to the default branch publishes the website, at the address
shown in **Settings > Pages** (`https://<owner>.github.io/<repository>/`),
which the workflow passes as `--base-url`. Run the **Website** workflow from
the **Actions** tab to publish it right away. Set the variable to anything
else, or delete it, to turn the workflow off again.

The workflow publishes the project at the root of the repository. In
[pobol2/Solution-Manual-Template](https://github.com/pobol2/Solution-Manual-Template)
itself, it publishes the [showcase](../examples/showcase/) with its exercise
and answer [editions](editions.md): this is the [live
demo](https://pobol2.github.io/Solution-Manual-Template/). The figures
(`Figures/*.pdf`, compiled with LuaLaTeX) are kept in the Actions cache and
rebuilt only when their sources, `myfigures.sty`, `mytheme.sty` or the
framework's figure class change.

With the framework as a submodule (see [advanced
submodule](advanced-submodule.md)), copy the workflow, check out the
submodule too (`actions/checkout` with `submodules: true`), and replace
`solution-manual/` with the submodule's path, e.g.
`template/solution-manual/`.

## What the website contains

| Path | Contents |
| ---- | -------- |
| `index.html` | The catalogue: progress, the full manual, and every problem under its chapter, section and subsection. Headings without problems are left out. |
| `problems/<id>.html` | A page per solved problem: breadcrumb, title, its PDF in the page, links to its parts and to the previous and next solved problems. |
| `pdf/<id>.pdf` | The pages of a solved problem in the manual (unsolved too with `publish_unsolved`), with its parts as bookmarks and the manual's page numbers. |
| `main.pdf` | The full manual. |
| `<name>.pdf` | The editions of `editions`, linked from the homepage. |
| `catalogue.json` | The editions, the headings and the problems, with their IDs, statuses, pages, parts and the problems they refer to and are referred to by. |
| `sitemap.xml` | The homepage, the solved-problem pages, the full manual, its editions and the solved-problem PDFs. |
| `style.css` | The style, in the manual's `ThemeColor` (from `mytheme.sty`), lighter in dark mode. |

The texts of the pages are those of the manual's language: English or French
texts, and the labels of the manual ("Problem", "Chapter", "Not done", ...).

Links in a problem PDF are rewritten, since the PDF is cut from the manual:
links inside the problem stay in the PDF; links to another problem (`\probref`,
`\ref`, `\eqref`) open that problem's PDF at the right page, or the full manual
when that PDF is not published; links to a chapter open its place in the
catalogue; other links open the full manual at their page.

## Problem IDs

Each problem has an ID, which names its page and its PDF and is its anchor in
the catalogue. The class writes it in the JSON index from the number of the
heading where the problem's numbering restarts:

| Structure | Problem | ID |
| --------- | ------- | -- |
| Textbook number (`\textbooknumber{\S 9}`) | §9 Problem 3 | `s9-p3` |
| Chapters (`problem numbering=chapter`) | Problem 3 of chapter 2 | `c2-p3` |
| Numbered sections (`subdivision`) | Problem 2 of section 3.1 | `3-1-p2` |
| Numbered subsections (`subdivision`) | Problem 1 of subsection 4.1.1 | `4-1-1-p1` |
| Continuous numbering | Problem 47 | `p47` |
| Other textbook numbers (`\textbooknumber{IV}` on a chapter) | Problem 1 of chapter IV | `civ-p1` |

A part adds its letter: `s9-p3a` is part (a) of `s9-p3`. Headings have IDs
too: `c2`, `3-1`, `s9`. IDs are lower case; a section sign gives `s`, and any
other character a `-`.

IDs depend only on numbers, so they do not change when a problem is solved,
gets a title or moves to other pages, and its URL stays the same. They change
when the numbers change: a problem inserted before others in the same unit
renumbers them, and so does a change of `problem numbering` or of a textbook
number. With textbook numbers, the numbers, and so the IDs, follow the book.
Two problems with the same ID (two sections shown with the same number) stop
the build.

## Checks

The build stops, and publishes nothing, when something does not check out:

- settings: missing, unknown or invalid settings, URLs and ISBN;
- index and manual: the JSON index and `main.pdf` must be from the same build
  (every problem, part and heading anchor on the pages the index gives, with
  the same page numbers); unique IDs; increasing problem numbers in each
  numbering unit; each problem starting on a new page, without running into
  the next one, and no page between two problems that belongs to neither;
- titles: plain text, short enough for the page title;
- problem PDFs: the running header of each page shows the problem, links stay
  inside the PDF or lead to published pages, PDFs and anchors, and the
  bookmarks are the problem and its parts;
- pages: one canonical URL, its own; a title of at most 60 characters and a
  description of 25 to 160 characters, as search results show them, both
  unique; one `h1`; links to files, anchors and PDF pages that exist; the
  Google verification tag, if set;
- the sitemap: exactly the expected URLs, all published.

## Limitations

- Only a manual in `shown` mode can be published: the build stops for
  `hidden`, `answers only` and `answers at end`.
- Every problem starts on a new page, so that each page belongs to one
  problem: the build stops when two problems share a page, as they do with
  `problem on new page=false`.
- The website is made from `main.tex` (`build/main.pdf` and
  `build/main-problems.json`); another job name is not supported.
- Website texts exist in English and French. With another language file, the
  pages use the manual's labels and English for the rest, with a warning.
- The PDF of an unsolved problem is its pages in the manual: its statement,
  and any partial solution or solved parts.
- Pages after the last problem (an appendix, an overview) are in the full
  manual only.
- There is no search; the catalogue is a single page.

#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 P.O. Bolduc. See ../../LICENSE.
"""Build the website of a solution manual: a catalogue of the problems, and a
page and a PDF per solved problem (see docs/website.md).

Run it from the project root, after latexmk, with completion tracking on. It
reads:

  site/site.toml            the settings of the site
  site/problems.toml        optional: problem titles by ID, for problems
                            without title={...} in the sources
  build/main-problems.json  the problem index of SolutionManual.cls: headings,
                            problems with their IDs, titles, statuses, pages
                            and parts, labels, language and page layout
  build/main.pdf            the manual: its pages, anchors (positions of the
                            parts) and links between problems

The output folder (default: _site) receives:

  index.html          the catalogue: progress and every problem by chapter
  problems/<id>.html  one page per solved problem, showing its PDF
  pdf/<id>.pdf        one PDF per solved problem, its parts included (and per
                      unsolved problem with publish_unsolved = true)
  main.pdf            the full manual
  catalogue.json      catalogue data
  sitemap.xml         the homepage, the solved-problem pages, the full manual
                      and the solved-problem PDFs
  style.css

Problem IDs come from the index and follow the manual's numbering, so they do
not change when problems are solved or pages move: s9-p3 is §9 Problem 3,
c2-p3 Problem 3 of chapter 2, 3-1-p2 Problem 2 of section 3.1, p47 Problem 47
in continuous numbering; s9-p3a is the part (a) of s9-p3.

Usage: python solution-manual/site/build.py [--out DIR] [--base-url URL]
"""

import sys

if sys.version_info < (3, 11):
    sys.exit("Python 3.11 or later is needed")

import argparse
import datetime
import html
import json
import os
import posixpath
import re
import shutil
import tomllib
import unicodedata
import urllib.parse
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from xml.etree import ElementTree

HERE = Path(__file__).resolve().parent

try:
    from pypdf import PdfReader, PdfWriter
    from pypdf.generic import (ArrayObject, DictionaryObject, Fit, NameObject,
                               TextStringObject)
except ImportError:
    sys.exit(f"pypdf is missing: python -m pip install -r {HERE / 'requirements.txt'}")

# Inputs, relative to the project root (the current folder)
SETTINGS = "site/site.toml"
TITLES = "site/problems.toml"
MANUAL = "build/main.pdf"
INDEX = "build/main-problems.json"

# Lengths that search results show in full (titles are cut at about 60
# characters, descriptions at about 160); the build checks every page
TITLE_MAX = 60
DESCRIPTION_RANGE = (25, 160)

# Anchors of a problem: hyperref names ending with the problem key, plus the
# given number of components (part number, bookmark level)
PROBLEM_ANCHORS = {"problem-title": 0, "ProblemNum": 0, "problem": 1,
                   "SubProblemNum": 1, "subproblem": 2}
# Link targets that make a cross-problem reference (\probref, \ref, \eqref)
REFERENCE_ANCHORS = {"problem-title", "ProblemNum", "problem", "SubProblemNum", "subproblem",
                     "equation", "AMS", "figure", "table"}
STATUSES = {"done": True, "not done": False}


class Errors(list):
    """Problems found while reading the inputs; any of them stops the build."""

    def check(self, stage):
        if self:
            for message in self:
                print(f"error: {message}", file=sys.stderr)
            sys.exit(f"{stage}: {len(self)} error(s), nothing published")


def warn(message):
    print(f"warning: {message}", file=sys.stderr)


# ============ Interface text ============ #
# Texts of the website in the language of the manual (its language key). The
# labels of the manual (Problem, Chapter, Not done, ...) come from the index.

def _progress_en(done, total):
    return f"{done} of {total} problems solved"


def _lead_en(problem, headings, book, author):
    """A worked solution to Problem 1 of §9, <i>Title</i>, in Chapter 2,
    <i>Title</i>, of <book>. Solution by <author>. (HTML; arguments too)"""
    where = [f"of {number}, <i>{title}</i>" if level != "chapter"
             else f"in {number}, <i>{title}</i>" for level, number, title in headings]
    if book:
        where.append(f"of {book}")
    where = " " + ", ".join(where) if where else ""
    return f"A worked solution to {problem}{where}. Solution by {author}."


def _progress_fr(done, total):
    s = "s" if done > 1 else ""
    return f"{done} problème{s} résolu{s} sur {total}"


def _lead_fr(problem, headings, book, author):
    """Problème 1, §9 <i>Titre</i>, Chapitre 2 <i>Titre</i>. Énoncé tiré de
    <livre>. Solution détaillée par <auteur>."""
    where = "".join(f", {number} <i>{title}</i>" for _, number, title in headings)
    source = f" Énoncé tiré de {book}." if book else ""
    return f"{problem}{where}.{source} Solution détaillée par {author}."


TEXT = {
    "english": {
        "lang": "en",
        "and": "and",
        "decimal": ".",
        "units": ("kB", "MB"),
        "pages": lambda n: f"{n} page{'s' if n > 1 else ''}",
        "progress": _progress_en,
        "solutions_by": "Solutions by {author}",
        "download_manual": "Download the full manual",
        "source_code": "Source code",
        "open_pdf": "Open the solution (PDF)",
        "open_pdf_inline": "open the solution (PDF)",
        "download": "Download",
        "manual_pages": "pages {first}–{last} of the {manual}",
        "manual_page": "page {first} of the {manual}",
        "full_manual": "full manual",
        "no_viewer": "Your browser cannot show the PDF here:",
        "pdf_label": "{label}, solution (PDF)",
        "parts": "Parts",
        "all_problems": "All problems",
        "breadcrumb": "Breadcrumb",
        "pager": "Solved problems",
        "description": "Worked solution to {label} of {work}: {subject}. PDF, {pages}.",
        "lead": _lead_en,
        "copyright": "Solutions © {year} {author}",
        "license": "License",
        "unofficial": "Unofficial: not endorsed by the authors or the publisher of the book.",
        "report": "Report an error",
        "report_on": "Report an error on {host}",
        "resource_type": "Worked solution",
        "editions": "Also as PDF",
        "modes": {"shown": "the full manual", "hidden": "questions only",
                  "answers only": "questions and answers",
                  "answers at end": "questions, solutions at the end"},
    },
    "french": {
        "lang": "fr",
        "and": "et",
        "decimal": ",",
        "units": ("ko", "Mo"),
        "pages": lambda n: f"{n} page{'s' if n > 1 else ''}",
        "progress": _progress_fr,
        "solutions_by": "Solutions par {author}",
        "download_manual": "Télécharger le manuel complet",
        "source_code": "Code source",
        "open_pdf": "Ouvrir la solution (PDF)",
        "open_pdf_inline": "ouvrir la solution (PDF)",
        "download": "Télécharger",
        "manual_pages": "pages {first} à {last} du {manual}",
        "manual_page": "page {first} du {manual}",
        "full_manual": "manuel complet",
        "no_viewer": "Votre navigateur ne peut pas afficher le PDF ici :",
        "pdf_label": "{label}, solution (PDF)",
        "parts": "Parties",
        "all_problems": "Tous les problèmes",
        "breadcrumb": "Fil d’Ariane",
        "pager": "Problèmes résolus",
        "description": "Solution détaillée, {label} de {work} : {subject}. PDF, {pages}.",
        "lead": _lead_fr,
        "copyright": "Solutions © {year} {author}",
        "license": "Licence",
        "unofficial": "Non officiel : ni les auteurs ni l’éditeur du livre ne l’ont approuvé.",
        "report": "Signaler une erreur",
        "report_on": "Signaler une erreur sur {host}",
        "resource_type": "Solution détaillée",
        "editions": "Aussi en PDF",
        "modes": {"shown": "le manuel complet", "hidden": "énoncés seuls",
                  "answers only": "énoncés et réponses",
                  "answers at end": "énoncés, solutions à la fin"},
    },
}


# ============ Settings ============ #

@dataclass
class Book:
    title: str
    authors: list
    edition: str = ""
    year: int | None = None
    publisher: str = ""
    isbn: str = ""

    def short(self, conj):
        """Surnames and title, as in "Landau and Lifshitz, Mechanics"."""
        if not self.authors:
            return self.title
        return f"{join_and([a.split()[-1] for a in self.authors], conj)}, {self.title}"

    def reference(self, conj):
        """Authors, <cite>title</cite>, edition (year), as HTML."""
        text = f"{esc(join_and(self.authors, conj))}, " if self.authors else ""
        text += f"<cite>{esc(self.title)}</cite>"
        if self.edition:
            text += f", {esc(self.edition)}"
        if self.year:
            text += f" ({self.year})"
        return text


@dataclass
class Settings:
    title: str
    short_name: str
    author: str
    description: str
    base_url: str
    repository: str
    license: str
    book: Book | None = None
    google_site_verification: str = ""
    publish_unsolved: bool = False
    editions: list = field(default_factory=list)


def join_and(items, conj):
    items = list(items)
    return items[0] if len(items) == 1 else ", ".join(items[:-1]) + f" {conj} {items[-1]}"


def read_toml(path):
    try:
        with open(path, "rb") as f:
            return tomllib.load(f)
    except OSError as e:
        sys.exit(f"{path}: {e.strerror}")
    except tomllib.TOMLDecodeError as e:
        sys.exit(f"{path}: {e}")


def isbn_valid(isbn):
    digits = re.sub(r"[\s-]", "", isbn).upper()
    if re.fullmatch(r"97[89]\d{10}", digits):
        return sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(digits)) % 10 == 0
    if re.fullmatch(r"\d{9}[\dX]", digits):
        return sum((10 - i) * (10 if d == "X" else int(d)) for i, d in enumerate(digits)) % 11 == 0
    return False


def isbn13(isbn):
    """The ISBN-13 digits of a valid ISBN (structured data)."""
    digits = re.sub(r"[\s-]", "", isbn).upper()
    if len(digits) == 10:
        digits = "978" + digits[:9]
        digits += str(-sum(int(d) * (3 if i % 2 else 1) for i, d in enumerate(digits)) % 10)
    return digits


def is_url(value):
    url = urllib.parse.urlsplit(value)
    return url.scheme in ("http", "https") and bool(url.netloc)


def read_settings(base_url, errors):
    """site/site.toml, with --base-url replacing its base_url."""
    if not Path(SETTINGS).is_file():
        sys.exit(f"{SETTINGS} is missing: run this script from the project root, "
                 f"which needs a {SETTINGS} (see docs/website.md)")
    data = read_toml(SETTINGS)
    required = ("title", "short_name", "author", "description", "base_url", "repository",
                "license")
    optional = {"google_site_verification": str, "publish_unsolved": bool, "book": dict,
                "editions": list}
    if base_url:
        data["base_url"] = base_url
    for key in data.keys() - set(required) - optional.keys():
        errors.append(f"{SETTINGS}: unknown setting {key}")
    for key in required:
        if not isinstance(data.get(key), str) or not data[key].strip():
            errors.append(f"{SETTINGS}: {key} is missing or is not a text")
    kinds = {bool: "true or false", dict: "a table", list: "a list", str: "a text"}
    for key, kind in optional.items():
        if key in data and not isinstance(data[key], kind):
            errors.append(f"{SETTINGS}: {key} must be {kinds[kind]}")
    errors.check(SETTINGS)
    editions = data.get("editions", [])
    for name in editions:
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", name) \
                or name == "main":
            errors.append(f"{SETTINGS}: editions: {name!r} is not the name of an edition "
                          f"(%editions in latexmkrc)")
    if len(set(map(str, editions))) != len(editions):
        errors.append(f"{SETTINGS}: editions: an edition is listed twice")
    for key in ("base_url", "repository", "license"):
        if not is_url(data[key]):
            errors.append(f"{SETTINGS}: {key} = {data[key]!r} is not an http(s) URL")
    book = None
    if "book" in data:
        b = data["book"]
        kinds = {"title": str, "authors": list, "edition": str, "year": int, "publisher": str,
                 "isbn": str}
        for key in b.keys() - kinds.keys():
            errors.append(f"{SETTINGS}: unknown setting book.{key}")
        for key, kind in kinds.items():
            if key in b and (not isinstance(b[key], kind) or isinstance(b[key], bool)):
                errors.append(f"{SETTINGS}: book.{key} has the wrong type")
        if not isinstance(b.get("title"), str) or not b["title"].strip():
            errors.append(f"{SETTINGS}: book.title is missing")
        if not all(isinstance(a, str) and a.strip() for a in b.get("authors", [])):
            errors.append(f"{SETTINGS}: book.authors must be a list of names")
        if isinstance(b.get("isbn"), str) and not isbn_valid(b["isbn"]):
            errors.append(f"{SETTINGS}: book.isbn = {b['isbn']!r} is not a valid ISBN-10 or ISBN-13")
        errors.check(SETTINGS)
        book = Book(**{k: (v.strip() if isinstance(v, str) else v) for k, v in b.items()})
        book.authors = [a.strip() for a in book.authors]
    errors.check(SETTINGS)
    return Settings(**{k: data[k].strip() for k in required},
                    book=book,
                    google_site_verification=data.get("google_site_verification", "").strip(),
                    publish_unsolved=data.get("publish_unsolved", False),
                    editions=editions)


# ============ Model ============ #

@dataclass
class Heading:
    serial: int               # serial of the index (0: problems outside chapters)
    id: str
    level: str                # chapter, section or subsection
    number: str               # as shown: "2", "3.1", "§9"
    title: str
    anchor: str
    parent: "Heading | None" = None
    page: int = -1            # page index of its anchor in main.pdf
    problems: list = field(default_factory=list)   # every problem under it
    direct: list = field(default_factory=list)     # problems right under it
    children: list = field(default_factory=list)   # headings with problems

    def label(self, labels):
        if not self.serial:
            return self.title
        if self.level == "chapter":
            return f"{labels['chapter_label']} {self.number}. {self.title}"
        return f"{self.number} {self.title}"


@dataclass
class Part:
    id: str
    number: str               # "(a)"
    title: str
    done: bool
    page: int                 # page index in main.pdf
    left: float | None
    top: float | None


@dataclass
class Problem:
    id: str
    key: str                  # hyperref key, "2.3.0.3"
    number: str
    label: str                # "§9 Problem 3", "Problem 2.3", "Problem 47"
    title: str
    done: bool
    start: int                # page indexes in main.pdf
    end: int
    headings: list            # chapter, section, subsection (those it is in)
    unit: "Heading | None"    # heading where its numbering restarts
    parts: list = field(default_factory=list)
    refs: set = field(default_factory=set)       # IDs of the problems it links to
    cited_by: set = field(default_factory=set)
    published: bool = False   # has a PDF

    @property
    def chapter(self):
        return self.headings[0] if self.headings else None

    @property
    def heading(self):
        """Deepest heading it is in."""
        return self.headings[-1] if self.headings else None

    @property
    def subject(self):
        """Its title, or that of its heading."""
        return self.title or (self.heading.title if self.heading else "")

    @property
    def pages(self):
        return self.end - self.start + 1

    @property
    def pdf(self):
        return f"pdf/{self.id}.pdf" if self.published else None

    @property
    def page(self):
        """Its web page, for a solved problem only."""
        return f"problems/{self.id}.html" if self.done else None

    @property
    def href(self):
        """Where the catalogue sends a visitor: the page, the PDF or nowhere."""
        return self.page or self.pdf


def done_count(problems):
    return sum(p.done for p in problems)


# ============ main.pdf ============ #

@dataclass
class Target:
    name: str | None          # named destination, if any
    page: int
    view: list                # destination array after the page reference
    left: float | None
    top: float | None


def number_or_none(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


class Anchors:
    """Destinations of main.pdf, named (hyperref anchors) or explicit."""

    def __init__(self, reader):
        self.page_of_ref = {p.indirect_reference.idnum: i for i, p in enumerate(reader.pages)}
        self.named = {}
        for name, dest in reader.named_destinations.items():
            array = list(dest.dest_array)
            page = self.page_of_ref.get(getattr(array[0], "idnum", None))
            if page is not None:
                self.named[str(name)] = Target(str(name), page, array[1:],
                                               number_or_none(dest.left),
                                               number_or_none(dest.top))

    def resolve(self, dest):
        if dest is None:
            return None
        dest = dest.get_object()
        if isinstance(dest, ArrayObject):
            page = self.page_of_ref.get(getattr(dest[0], "idnum", None))
            if page is None:
                return None
            view = list(dest[1:])
            left = number_or_none(view[1]) if len(view) > 1 else None
            top = number_or_none(view[2]) if len(view) > 2 else None
            return Target(None, page, view, left, top)
        return self.named.get(str(dest))


def anchor_key(name):
    """(prefix, problem key) of a problem anchor, or None."""
    prefix, _, rest = name.partition(".")
    if prefix not in PROBLEM_ANCHORS:
        return None
    for _ in range(PROBLEM_ANCHORS[prefix]):
        rest = rest.rpartition(".")[0]
    return prefix, rest


# ============ Problem index ============ #

ID_RE = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
STALE = f"(rebuild with latexmk: are {MANUAL} and {INDEX} from the same build?)"


def is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def read_index(errors):
    """The problem index, after a check of its fields."""
    for path in (MANUAL, INDEX):
        if not Path(path).is_file():
            sys.exit(f"{path} is missing: build the manual with latexmk, with "
                     f"completion tracking=true (it writes {INDEX})")
    try:
        data = json.loads(Path(INDEX).read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        sys.exit(f"{INDEX}: {e}")
    older = "(written by an older SolutionManual.cls? rebuild the manual with latexmk)"
    if not isinstance(data, dict):
        sys.exit(f"{INDEX}: not a problem index")
    for key, kind in (("language", str), ("labels", dict), ("solutions", str),
                      ("theme_color", str), ("layout", dict), ("headings", list),
                      ("problems", list)):
        if not isinstance(data.get(key), kind):
            errors.append(f"{INDEX}: no {key} {older}")
    errors.check(INDEX)

    if data["solutions"] != "shown":
        sys.exit(f"{INDEX} is from a manual with solutions={data['solutions']}: the website "
                 f"shows the solutions, so build it from a manual with solutions=shown (the "
                 f"default). Editions (docs/editions.md) keep their own modes.")
    labels = data["labels"]
    for key in ("problem_label", "chapter_label", "not_done_label", "colon",
                "outside_chapters_label"):
        if not isinstance(labels.get(key), str):
            errors.append(f"{INDEX}: no label {key} {older}")
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", data["theme_color"]):
        errors.append(f"{INDEX}: theme_color {data['theme_color']!r} is not #RRGGBB")
    for key in ("paper_width", "paper_height", "margin_top", "margin_bottom", "margin_left",
                "margin_right"):
        if not isinstance(data["layout"].get(key), (int, float)):
            errors.append(f"{INDEX}: no layout.{key} {older}")

    for i, h in enumerate(data["headings"], 1):
        if not isinstance(h, dict) or not is_int(h.get("serial")) \
                or h.get("level") not in ("chapter", "section", "subsection") \
                or not all(isinstance(h.get(k), str) for k in ("id", "number", "title", "anchor")):
            errors.append(f"{INDEX}: heading {i} has missing or invalid fields {older}")
    texts = ("id", "anchor", "number", "reference", "unit", "title")
    for i, p in enumerate(data["problems"], 1):
        if not isinstance(p, dict) \
                or not all(isinstance(p.get(k), str) for k in texts) \
                or p.get("status") not in STATUSES \
                or not all(p.get(k) is None or is_int(p.get(k))
                           for k in ("chapter", "section", "subsection")) \
                or not all(k in p for k in ("chapter", "section", "subsection")) \
                or not isinstance(p.get("parts"), list) \
                or not all(isinstance(x, dict) and x.get("status") in STATUSES
                           and all(isinstance(x.get(k), str)
                                   for k in ("id", "anchor", "number", "title"))
                           for x in p["parts"]):
            errors.append(f"{INDEX}: problem {i} has missing or invalid fields {older}")
        elif not all(isinstance(p.get(k), str) for k in ("first_page", "last_page")) \
                or not all(is_int(p.get(k)) for k in ("first_pdf_page", "last_pdf_page")):
            errors.append(f"{INDEX}: problem {p['id']} has no pages {STALE}")
    errors.check(INDEX)
    return data


def problem_label(entry, unit, labels):
    """§9 Problem 3 (a textbook number), Problem 2.3 (the reference), or
    Problem 47 (continuous numbering, outside chapters)."""
    name, number, reference = labels["problem_label"], entry["number"], entry["reference"]
    if unit is None or reference == number:
        return f"{name} {number}"
    if "§" in unit.number:
        return f"{unit.number} {name} {number}"
    return f"{name} {reference}"


def read_manual(reader, anchors, data, layout_bottom, errors):
    """Headings and problems of the index, located in main.pdf."""
    labels = data["labels"]
    labels_of_pages = reader.page_labels
    last_page = len(reader.pages) - 1

    # Headings, with their parents (the last chapter or section before them)
    headings = {}
    chapter = section = None
    for h in data["headings"]:
        heading = Heading(h["serial"], h["id"], h["level"], h["number"],
                          " ".join(h["title"].split()), h["anchor"])
        if heading.level == "chapter":
            chapter, section = heading, None
        elif heading.level == "section":
            heading.parent, section = chapter, heading
        else:
            heading.parent = section or chapter
        target = anchors.named.get(heading.anchor)
        if target is None:
            errors.append(f'{INDEX}: no anchor {heading.anchor} in {MANUAL} for the heading '
                          f'"{heading.label(labels)}" {STALE}')
        else:
            heading.page = target.page
        headings[heading.serial] = heading
    errors.check(f"{INDEX} against {MANUAL}")

    # Problems, at the anchor of the index, on the pages given by the index
    outside = Heading(0, "outside-chapters", "chapter", "", labels["outside_chapters_label"], "")
    problems, part_entries = [], {}
    for entry in data["problems"]:
        where = f'{INDEX}: problem {entry["id"]}'
        key = anchor_key(entry["anchor"])
        target = anchors.named.get(entry["anchor"])
        if not key or key[0] != "ProblemNum":
            errors.append(f"{where}: {entry['anchor']} is not a problem anchor")
            continue
        if target is None:
            errors.append(f'{where}: no anchor {entry["anchor"]} in {MANUAL} {STALE}')
            continue
        serials = [entry[k] for k in ("chapter", "section", "subsection") if entry[k]]
        if any(s not in headings for s in serials):
            errors.append(f"{where}: unknown heading {serials}")
            continue
        chain = [headings[s] for s in serials]
        unit = next((h for h in reversed(chain) if h.number == entry["unit"]), None)
        start, end = entry["first_pdf_page"] - 1, entry["last_pdf_page"] - 1
        problem = Problem(entry["id"], key[1], entry["number"],
                          problem_label(entry, unit, labels), " ".join(entry["title"].split()),
                          STATUSES[entry["status"]], start, end, chain or [outside], unit)
        where = f"{where} ({problem.label})"
        if not 0 <= start <= end <= last_page:
            errors.append(f"{where}: pages {start + 1}-{end + 1}, not in the "
                          f"{last_page + 1} pages of {MANUAL} {STALE}")
            continue
        if target.page != start:
            errors.append(f"{where}: its anchor is on page {target.page + 1} of {MANUAL}, "
                          f"not on its first page {start + 1} {STALE}")
        title_anchor = anchors.named.get(f"problem-title.{problem.key}")
        if title_anchor is None or title_anchor.page != start:
            errors.append(f"{where}: its title is not on its first page")
        for name, page in (("first_page", start), ("last_page", end)):
            if labels_of_pages[page] != entry[name]:
                errors.append(f"{where}: page {page + 1} of {MANUAL} is numbered "
                              f"{labels_of_pages[page]}, not {entry[name]} {STALE}")
        part_entries[problem.key] = entry["parts"]
        problems.append(problem)
        for heading in problem.headings:
            heading.problems.append(problem)
        problem.heading.direct.append(problem)
    errors.check(f"{INDEX} against {MANUAL}")

    # IDs: unique, and usable as file names and HTML ids
    shown = [h for h in [outside, *headings.values()] if h.problems]
    ids = {}
    for kind, item_id in [("heading", h.id) for h in shown] + [("problem", p.id) for p in problems]:
        if not ID_RE.fullmatch(item_id):
            errors.append(f"{kind} ID {item_id!r} is not made of a-z, 0-9 and single hyphens")
        elif item_id in ids:
            errors.append(f"two {ids[item_id]}s or headings have the ID {item_id}: give one "
                          f"of them another number (\\textbooknumber) or move a problem")
        ids[item_id] = kind
    # Numbering: increasing numbers where the numbering restarts
    numbers = {}
    for problem in problems:
        if problem.number.isdigit():
            numbers.setdefault(problem.unit.serial if problem.unit else None, []).append(problem)
    for group in numbers.values():
        for before, after in zip(group, group[1:]):
            if int(after.number) <= int(before.number):
                errors.append(f"{after.label} ({after.id}) follows {before.label} "
                              f"({before.id}): problem numbers must increase")
    errors.check("problem IDs")

    # Parts: those of the index, (a), (b), ..., at the SubProblemNum anchors
    # of their problem, numbered 1, 2, ..., which main.pdf has all of
    by_key = {p.key: p for p in problems}
    found = {}
    for name in anchors.named:
        key = anchor_key(name)
        if key and key[0] == "SubProblemNum":
            found.setdefault(key[1], set()).add(int(name.rpartition(".")[2]))
    for key in found.keys() - by_key.keys():
        errors.append(f"part anchor of an unknown problem: SubProblemNum.{key}.* {STALE}")
    part_ids = set()
    for problem in problems:
        entries = part_entries[problem.key]
        indexes = range(1, len(entries) + 1)
        if len(entries) > 26 \
                or [x["anchor"] for x in entries] != [f"SubProblemNum.{problem.key}.{k}" for k in indexes] \
                or [x["number"] for x in entries] != [f"({chr(96 + k)})" for k in indexes] \
                or found.get(problem.key, set()) != set(indexes):
            errors.append(f"{problem.label}: parts {[x['number'] for x in entries]} in {INDEX}, "
                          f"part anchors {sorted(found.get(problem.key, ()))} in {MANUAL} {STALE}")
            continue
        for x in entries:
            if x["id"] in part_ids or not ID_RE.fullmatch(x["id"]):
                errors.append(f"{problem.label}: part ID {x['id']!r} is repeated or invalid")
            part_ids.add(x["id"])
            t = anchors.named[x["anchor"]]
            problem.parts.append(Part(x["id"], x["number"], " ".join(x["title"].split()),
                                      STATUSES[x["status"]], t.page, t.left, t.top))
    errors.check(f"{INDEX} against {MANUAL}")

    # Page ranges: each problem starts on a new page (problem on new page, the
    # default of the class) and ends before the next problem or chapter; the
    # pages between are its own
    starts = [p.start for p in problems]
    if len(set(starts)) != len(starts):
        errors.append("two problems start on the same page: every problem must start on a "
                      "new page (problem on new page=true, the default)")
    boundaries = sorted(set(starts) | {h.page for h in headings.values() if h.level == "chapter"})
    for problem in problems:
        later = [b for b in boundaries if b > problem.start]
        if not later:
            continue          # the pages after the last problem may hold anything
        if problem.end >= later[0]:
            errors.append(f"{problem.label}: pages {problem.start + 1}-{problem.end + 1} "
                          f"run into page {later[0] + 1}, which starts something else")
        elif problem.end + 1 < later[0]:
            errors.append(f"pages {problem.end + 2}-{later[0]} of {MANUAL}, after "
                          f"{problem.label}, belong to no problem")
    errors.check(f"{MANUAL} page ranges")

    # A part's anchor is set just before its box; when the box does not fit,
    # it moves to the next page and the anchor stays below the text area of
    # the previous one. Such a part starts at the top of the next page.
    for problem in problems:
        for part in problem.parts:
            box = reader.pages[part.page].mediabox
            if part.top is not None and part.top < float(box.bottom) + layout_bottom \
                    and part.page < problem.end:
                part.page += 1
                part.top = float(reader.pages[part.page].mediabox.top)

    # Every anchor of a problem is in its range
    for name, target in anchors.named.items():
        key = anchor_key(name)
        if key:
            problem = by_key.get(key[1])
            if problem is None:
                errors.append(f"anchor {name} belongs to no problem {STALE}")
            elif not problem.start <= target.page <= problem.end:
                errors.append(f"anchor {name} of {problem.label} is on page {target.page + 1}, "
                              f"outside its pages {problem.start + 1}-{problem.end + 1}")
    errors.check(f"{MANUAL} page ranges")

    # Headings of the catalogue: those with problems, in document order
    for heading in shown:
        if heading.parent is not None:
            heading.parent.children.append(heading)
    chapters = [h for h in shown if h.level == "chapter"]
    return chapters, headings, problems


# ============ Editions ============ #

@dataclass
class Edition:
    name: str                 # job name (%editions in latexmkrc)
    solutions: str            # its solutions mode
    pages: int
    size: int

    @property
    def pdf(self):
        return f"{self.name}.pdf"


def read_editions(settings, data, errors):
    """The editions of site.toml: build/<name>.pdf and its index, which must
    have the problems of the manual (latexmk only warns when an edition
    fails, which leaves the previous one in build/)."""
    problems = [(p["id"], p["status"]) for p in data["problems"]]
    editions = []
    for name in settings.editions:
        pdf, index = Path(f"build/{name}.pdf"), Path(f"build/{name}-problems.json")
        if not pdf.is_file() or not index.is_file():
            errors.append(f"edition {name}: build/{name}.pdf or build/{name}-problems.json is "
                          f"missing (is {name} in %editions of latexmkrc? see docs/editions.md)")
            continue
        try:
            other = json.loads(index.read_text(encoding="utf-8"))
        except ValueError as e:
            errors.append(f"edition {name}: {index.as_posix()}: {e}")
            continue
        if not isinstance(other, dict) or other.get("solutions") not in TEXT["english"]["modes"] \
                or not isinstance(other.get("problems"), list):
            errors.append(f"edition {name}: {index.as_posix()} is not a problem index {STALE}")
            continue
        if [(p.get("id"), p.get("status")) if isinstance(p, dict) else None
                for p in other["problems"]] != problems:
            errors.append(f"edition {name} does not have the problems of the manual: it is out "
                          f"of date (rebuild with latexmk, and see build/{name}.log)")
            continue
        editions.append(Edition(name, other["solutions"], len(PdfReader(pdf).pages),
                                pdf.stat().st_size))
    errors.check("editions")
    return editions


# ============ Titles ============ #

def add_titles(problems, errors):
    """Titles of site/problems.toml, for the problems without title={...}."""
    if not Path(TITLES).is_file():
        return
    by_id = {p.id: p for p in problems}
    for problem_id, title in read_toml(TITLES).items():
        problem = by_id.get(problem_id)
        if problem is None:
            errors.append(f"{TITLES}: no problem has the ID {problem_id} "
                          f"(see the IDs in {INDEX} or in the catalogue)")
        elif not isinstance(title, str) or not title.strip():
            errors.append(f"{TITLES}: {problem_id} must be a non-empty text")
        elif problem.title:
            errors.append(f"{TITLES}: {problem_id} ({problem.label}) already has the title "
                          f'"{problem.title}" in the sources: remove one of them')
        else:
            problem.title = " ".join(title.split())
    errors.check(TITLES)


def check_titles(site, problems, errors):
    """Titles of the problems, as the index gives them: plain text, which must
    fit in the page title."""
    for problem in problems:
        if re.search(r"[\\$]", problem.title):
            errors.append(f'{problem.label}: the title "{problem.title}" is TeX, not plain text '
                          f"(give its plain text with \\texorpdfstring{{TeX}}{{plain text}})")
        # Every problem, so that its page fits once it is solved
        elif len(page_title(site, problem)) > TITLE_MAX:
            errors.append(f"{problem.label}: its title is too long for the page title "
                          f'"{page_title(site, problem)}" ({TITLE_MAX} characters at most)')
    errors.check("problem titles")
    untitled = [p.id for p in problems if not p.title]
    if untitled:
        shown = ", ".join(untitled[:8]) + (", ..." if len(untitled) > 8 else "")
        warn(f"{len(untitled)} problem(s) without a title (title={{...}} in the sources, or "
             f"{TITLES}): {shown}")


# ============ Site ============ #

class Site:
    """Settings, texts and URLs of the website. URLs in the PDFs are absolute,
    so that a downloaded PDF keeps working links."""

    def __init__(self, settings, data, manual_pages):
        self.settings = settings
        self.labels = data["labels"]
        self.language = data["language"]
        if self.language not in TEXT:
            warn(f"no website texts for language={self.language}: English is used "
                 f"(the labels of the manual stay in its language)")
        self.text = TEXT.get(self.language, TEXT["english"])
        self.base = settings.base_url.rstrip("/") + "/"
        self.repository = settings.repository.rstrip("/")
        self.theme = data["theme_color"].lower()
        self.manual_pages = manual_pages
        self.editions = []        # Edition, linked from the homepage
        epoch = os.environ.get("SOURCE_DATE_EPOCH")
        self.year = (datetime.datetime.fromtimestamp(int(epoch), datetime.timezone.utc)
                     if epoch and epoch.isdigit() else datetime.datetime.now()).year

    def url(self, path=""):
        return self.base + path

    @property
    def work(self):
        """What the problems are from: the book, or the site."""
        b = self.settings.book
        return b.short(self.text["and"]) if b else self.settings.short_name

    def colon(self):
        """The colon label, with a non-breaking space before it, if any."""
        colon = self.labels["colon"]
        return " " + colon.lstrip() if colon[:1].isspace() else colon

    def size(self, size):
        kb, mb = self.text["units"]
        text = f"{size / 1e6:.1f} {mb}" if size >= 1e6 else f"{size / 1e3:.0f} {kb}"
        return text.replace(".", self.text["decimal"])

    def issues(self):
        """(URL, text) of the link to report an error."""
        host = urllib.parse.urlsplit(self.repository).netloc.lower()
        if host in ("github.com", "www.github.com"):
            return f"{self.repository}/issues/new", self.text["report_on"].format(host="GitHub")
        if host in ("gitlab.com", "www.gitlab.com"):
            return f"{self.repository}/-/issues/new", self.text["report_on"].format(host="GitLab")
        return self.repository, self.text["report"]

    def repository_name(self):
        host = urllib.parse.urlsplit(self.repository).netloc.lower().removeprefix("www.")
        return {"github.com": "GitHub", "gitlab.com": "GitLab",
                "codeberg.org": "Codeberg"}.get(host, self.text["source_code"])

    def license_name(self):
        """CC BY 4.0 for a Creative Commons URL, else License."""
        path = urllib.parse.urlsplit(self.settings.license)
        m = re.fullmatch(r"/licenses/([a-z-]+)/(\d+(?:\.\d+)?)/?", path.path)
        if path.netloc.endswith("creativecommons.org") and m:
            return f"CC {m[1].upper()} {m[2]}"
        m = re.fullmatch(r"/publicdomain/zero/(\d+(?:\.\d+)?)/?", path.path)
        if path.netloc.endswith("creativecommons.org") and m:
            return f"CC0 {m[1]}"
        return self.text["license"]


# ============ Problem PDFs ============ #

def page_labels(reader, start, end):
    """Printed page number of the first page if pages start..end are numbered
    consecutively in main.pdf (decimal page labels), else None."""
    labels = reader.page_labels[start:end + 1]
    if all(l.isdigit() for l in labels) and \
            [int(l) for l in labels] == list(range(int(labels[0]), int(labels[0]) + len(labels))):
        return int(labels[0])
    return None


def write_problem_pdf(reader, anchors, problem, chapter_links, owner, site, author, path, errors):
    writer = PdfWriter()
    for page in range(problem.start, problem.end + 1):
        writer.add_page(reader.pages[page])

    # Links: named destinations of main.pdf do not exist in the extract
    for page in writer.pages:
        for ref in page.get("/Annots") or []:
            annot = ref.get_object()
            if annot.get("/Subtype") != "/Link":
                continue
            dest, action = annot.get("/Dest"), annot.get("/A")
            if dest is None:
                if action is None or action.get_object().get("/S") != "/GoTo":
                    continue  # external links stay as they are
                dest = action.get_object().get("/D")
            target = anchors.resolve(dest)
            if target is None:
                errors.append(f"{problem.id}: link to an unknown destination {dest}")
                continue
            if "/Dest" in annot:
                del annot["/Dest"]
            prefix = (target.name or "").partition(".")[0]
            other = owner.get(target.page)
            if problem.start <= target.page <= problem.end:
                # Same problem: internal link to the copied page
                new = DictionaryObject({
                    NameObject("/S"): NameObject("/GoTo"),
                    NameObject("/D"): ArrayObject(
                        [writer.pages[target.page - problem.start].indirect_reference] + target.view),
                })
                url = None
            elif target.name in chapter_links:
                # A chapter (title or running header): its place in the catalogue
                url = site.url(f"#{chapter_links[target.name]}")
            elif other is not None and other.published and prefix != "page":
                # Another problem (\probref, \ref, \eqref): its PDF, at the page
                url = site.url(f"{other.pdf}#page={target.page - other.start + 1}")
            else:
                url = site.url(f"main.pdf#page={target.page + 1}")
            if other is not None and other is not problem and prefix in REFERENCE_ANCHORS:
                problem.refs.add(other.id)
            if url is not None:
                new = DictionaryObject({NameObject("/S"): NameObject("/URI"),
                                        NameObject("/URI"): TextStringObject(url)})
            annot[NameObject("/A")] = new

    # Bookmarks: the problem and its parts
    title = anchors.named[f"problem-title.{problem.key}"]
    top = writer.add_outline_item(problem.label, 0, fit=Fit.xyz(title.left, title.top))
    for part in problem.parts:
        writer.add_outline_item(f"{part.number} {part.title}".strip(), part.page - problem.start,
                                parent=top, fit=Fit.xyz(part.left, part.top))
    if problem.parts:
        writer.page_mode = "/UseOutlines"

    # The manual's page numbers, as printed in the footers
    first = page_labels(reader, problem.start, problem.end)
    if first is not None:
        writer.set_page_label(0, problem.pages - 1, "/D", start=first)

    status = "" if problem.done else f" ({site.labels['not_done_label']})"
    keywords = [site.settings.book.title] if site.settings.book else []
    keywords += [h.title for h in problem.headings if h.title] + [problem.label]
    writer.add_metadata({
        "/Title": f"{page_heading(site, problem)}{status} | {site.settings.title}",
        "/Author": author,
        "/Subject": problem_description(site, problem),
        "/Keywords": ", ".join(dict.fromkeys(keywords)),
    })
    writer.compress_identical_objects(remove_duplicates=True, remove_unreferenced=True)
    with open(path, "wb") as out:
        writer.write(out)


# ============ Checks of the output ============ #

def normalize(text):
    return " ".join(unicodedata.normalize("NFKC", text).casefold().split())


def header_matches(line, problem, labels):
    """True if the running header (the first line of a page) shows the
    problem: "Chapter 2. Title ... Problem 3." or "... §9 Problem 3."."""
    line = normalize(line)
    end = rf"(?<!\S){re.escape(normalize(labels['problem_label']))}\s*{re.escape(normalize(problem.number))}\.$"
    if problem.unit is not None and problem.unit.level != "chapter" and problem.label != \
            f"{labels['problem_label']} {problem.number}":
        end = rf"{re.escape(normalize(problem.unit.number))}\s*" + end.removeprefix(r"(?<!\S)")
    if not re.search(end, line):
        return False
    chapter = problem.chapter
    if chapter is None or not chapter.serial:
        return True
    start = rf"^{re.escape(normalize(labels['chapter_label']))}\s*{re.escape(normalize(chapter.number))}\."
    return re.search(start, line) is not None


def count_bookmarks(outline):
    return sum(count_bookmarks(x) if isinstance(x, list) else 1 for x in outline)


def verify_pdfs(out, problems, site, index_ids, errors):
    """Reopen every problem PDF: pages (running header of each page), links
    and bookmarks."""
    pages = {p.pdf: p.pages for p in problems if p.published} | {"main.pdf": site.manual_pages}
    for problem in problems:
        if not problem.published:
            continue
        reader = PdfReader(out / problem.pdf)
        where = problem.id
        if len(reader.pages) != problem.pages:
            errors.append(f"{where}: {len(reader.pages)} pages, expected {problem.pages}")
        refs = {p.indirect_reference.idnum for p in reader.pages}
        for i, page in enumerate(reader.pages, 1):
            lines = (page.extract_text() or "").strip().splitlines()
            if not lines or not header_matches(lines[0], problem, site.labels):
                errors.append(f"{where}: page {i} has the header {lines[:1]}, "
                              f"expected that of {problem.label}")
            for ref in page.get("/Annots") or []:
                annot = ref.get_object()
                action = annot.get("/A")
                if annot.get("/Subtype") != "/Link" or action is None:
                    continue
                action = action.get_object()
                if action.get("/S") == "/GoTo":
                    dest = action.get("/D")
                    if not isinstance(dest, ArrayObject) or getattr(dest[0], "idnum", None) not in refs:
                        errors.append(f"{where}: page {i} has a link outside the PDF ({dest})")
                elif action.get("/S") == "/URI" and str(action["/URI"]).startswith(site.url()):
                    uri = str(action["/URI"])
                    url = urllib.parse.urlsplit(uri.removeprefix(site.url()))
                    m = re.fullmatch(r"page=(\d+)", url.fragment)
                    if url.path == "" and url.fragment not in index_ids:
                        errors.append(f"{where}: page {i} links to a missing anchor {uri}")
                    elif url.path and not (url.path in pages and m and
                                           1 <= int(m[1]) <= pages[url.path]):
                        errors.append(f"{where}: page {i} links to a missing page {uri}")
        bookmarks = count_bookmarks(reader.outline)
        if bookmarks != 1 + len(problem.parts):
            errors.append(f"{where}: {bookmarks} bookmarks, expected {1 + len(problem.parts)}")
    errors.check("problem PDFs")


class PageParser(HTMLParser):
    """Links, ids and metadata of a generated page."""

    def __init__(self):
        super().__init__()
        self.links, self.ids, self.meta, self.canonical = [], set(), {}, []
        self.title, self.h1, self._in = "", 0, None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for name in ("href", "src", "data"):
            if attrs.get(name) is not None and not (tag == "link" and attrs.get("rel") == "canonical"):
                self.links.append(attrs[name])
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonical.append(attrs.get("href"))
        if tag == "meta":
            key = attrs.get("name") or attrs.get("property")
            if key:
                self.meta[key] = attrs.get("content")
        if tag == "h1":
            self.h1 += 1
        self._in = tag

    def handle_endtag(self, tag):
        self._in = None

    def handle_data(self, data):
        if self._in == "title":
            self.title += data


def verify_site(out, problems, site, errors):
    """Reopen every page: one canonical URL (its own address), unique titles and
    descriptions, and links to files, anchors and PDF pages that exist; then
    the sitemap: exactly the expected URLs, all published."""
    pages = {"index.html": ""} | {p.page: p.page for p in problems if p.done}
    pdf_pages = {p.pdf: p.pages for p in problems if p.published} | {"main.pdf": site.manual_pages}
    pdf_pages |= {e.pdf: e.pages for e in site.editions}
    if sorted(f.relative_to(out).as_posix() for f in out.rglob("*.html")) != sorted(pages):
        errors.append("the HTML pages are not the homepage and the solved-problem pages")
    if sorted(f.relative_to(out).as_posix() for f in out.rglob("*.pdf")) != sorted(pdf_pages):
        errors.append("the PDFs are not the manual, its editions and the published problem PDFs")
    errors.check("website pages")
    parsed = {}
    for path in pages:
        parser = PageParser()
        parser.feed((out / path).read_text(encoding="utf-8"))
        parsed[path] = parser
    for path, page in parsed.items():
        if page.canonical != [site.url(pages[path])]:
            errors.append(f"{path}: canonical {page.canonical}, expected {site.url(pages[path])}")
        if page.meta.get("og:url") != site.url(pages[path]):
            errors.append(f"{path}: og:url {page.meta.get('og:url')}")
        if not page.title.strip() or not page.meta.get("description") or page.h1 != 1:
            errors.append(f"{path}: needs a title, a description and one h1")
        elif not DESCRIPTION_RANGE[0] <= len(page.meta["description"]) <= DESCRIPTION_RANGE[1]:
            fix = f"description in {SETTINGS}" if path == "index.html" else \
                "title of the problem (or short_name)"
            errors.append(f"{path}: description of {len(page.meta['description'])} characters, "
                          f"not {DESCRIPTION_RANGE[0]}-{DESCRIPTION_RANGE[1]} "
                          f"(change the {fix}): {page.meta['description']!r}")
        elif len(page.title) > TITLE_MAX:
            errors.append(f"{path}: title of {len(page.title)} characters, over {TITLE_MAX}: "
                          f"{page.title!r}")
        for link in page.links:
            url = urllib.parse.urlsplit(link)
            if url.scheme or url.netloc:
                continue      # external
            target = (Path(path).parent / urllib.parse.unquote(url.path)).as_posix() \
                if url.path else path
            target = posixpath.normpath(target)
            if url.path.endswith("/") or target == ".":
                target = posixpath.join(target, "index.html").removeprefix("./")
            if target.startswith("../") or not (out / target).is_file():
                errors.append(f"{path}: broken link {link}")
            elif url.fragment and target.endswith(".html") and url.fragment not in parsed[target].ids:
                errors.append(f"{path}: link to a missing anchor {link}")
            elif url.fragment and target.endswith(".pdf"):
                m = re.fullmatch(r"page=(\d+)", url.fragment)
                if not m or not 1 <= int(m[1]) <= pdf_pages[target]:
                    errors.append(f"{path}: link to a missing PDF page {link}")
    for key in ("title", "description"):
        values = [p.title if key == "title" else p.meta.get("description") for p in parsed.values()]
        if len(set(values)) != len(values):
            errors.append(f"two pages have the same {key}")
    verification = site.settings.google_site_verification
    if verification and parsed["index.html"].meta.get("google-site-verification") != verification:
        errors.append("index.html: the Google Search Console verification tag is missing")

    root = ElementTree.parse(out / "sitemap.xml").getroot()
    locs = [e.text for e in root.iter("{http://www.sitemaps.org/schemas/sitemap/0.9}loc")]
    if locs != [site.url(u) for u in site_paths(problems, site)]:
        errors.append("sitemap.xml does not list the expected URLs")
    for loc in locs:
        path = loc.removeprefix(site.url()) or "index.html"
        if not loc.startswith(site.url()) or not (out / path).is_file():
            errors.append(f"sitemap.xml: {loc} is not a published file")
    errors.check("website pages")


# ============ Catalogue ============ #

def catalogue_data(chapters, problems, site, author):
    order = {p.id: i for i, p in enumerate(problems)}
    shown = []

    def walk(heading):
        shown.append(heading)
        for child in heading.children:
            walk(child)

    for chapter in chapters:
        walk(chapter)
    b = site.settings.book
    return {
        "schema": 2,
        "title": site.settings.title,
        "language": site.language,
        "book": None if b is None else {
            "authors": b.authors, "title": b.title, "edition": b.edition or None,
            "year": b.year, "publisher": b.publisher or None, "isbn": b.isbn or None},
        "author": author,
        "site": site.url(),
        "repository": site.repository,
        "manual": {"pdf": "main.pdf", "pages": site.manual_pages},
        "editions": [{"name": e.name, "pdf": e.pdf, "solutions": e.solutions, "pages": e.pages}
                     for e in site.editions],
        "done": done_count(problems),
        "total": len(problems),
        "headings": [{
            "id": h.id,
            "level": h.level,
            "number": h.number or None,
            "title": h.title,
            "parent": h.parent.id if h.parent else None,
            "manual_page": h.page + 1 if h.serial else None,
            "done": done_count(h.problems),
            "total": len(h.problems),
        } for h in shown],
        "problems": [{
            "id": p.id,
            "number": p.number,
            "label": p.label,
            "title": p.title or None,
            "done": p.done,
            "headings": [h.id for h in p.headings],
            "page": p.page,
            "pdf": p.pdf,
            "pages": p.pages,
            "manual_pages": [p.start + 1, p.end + 1],
            "parts": [{"id": x.id, "number": x.number, "title": x.title or None, "done": x.done,
                       "page": x.page - p.start + 1} for x in p.parts],
            "references": sorted(p.refs, key=order.get),
            "referenced_by": sorted(p.cited_by, key=order.get),
        } for p in problems],
    }


# ============ Website ============ #
# The catalogue lists every problem by chapter, section and subsection; a
# solved problem links to its page, which shows its PDF, and an unsolved one
# to its PDF, if published. No script: the pages are plain HTML and CSS. Links
# between pages are relative, so the site works under any base URL; canonical
# URLs are absolute.

def esc(text):
    return html.escape(str(text), quote=True)


SUBSCRIPT_RE = re.compile(r"(?<=\S)_([A-Za-z0-9]+)")


def rich(text):
    """Escaped text with subscripts: M_z (a title's \\texorpdfstring{$M_z$}{M_z})."""
    return SUBSCRIPT_RE.sub(r"<sub>\1</sub>", esc(text))


def plain(text):
    """Text without the subscript marks, for titles and metadata."""
    return SUBSCRIPT_RE.sub(r"\1", text)


def json_ld(data):
    text = json.dumps(data, ensure_ascii=False, indent=1).replace("</", "<\\/")
    return f'<script type="application/ld+json">\n{text}\n</script>'


def person(name):
    return {"@type": "Person", "name": name}


def book_ld(book):
    data = {"@type": "Book", "name": book.title}
    if book.authors:
        data["author"] = [person(a) for a in book.authors]
    if book.edition:
        data["bookEdition"] = book.edition
    if book.year:
        data["datePublished"] = str(book.year)
    if book.isbn:
        data["isbn"] = isbn13(book.isbn)
    if book.publisher:
        data["publisher"] = {"@type": "Organization", "name": book.publisher}
    return data


def render_head(site, title, description, canonical, root, og_type, structured, extra=""):
    """<head> of a page; root is the relative path to the site root."""
    return f"""<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<meta name="author" content="{esc(site.settings.author)}">
<link rel="canonical" href="{esc(canonical)}">
<meta property="og:type" content="{og_type}">
<meta property="og:site_name" content="{esc(site.settings.title)}">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{esc(canonical)}">
<meta name="twitter:card" content="summary">
{extra}<link rel="stylesheet" href="{root}style.css">
{json_ld(structured)}
</head>"""


def render_footer(site):
    t = site.text
    issues, report = site.issues()
    unofficial = f"\n{esc(t['unofficial'])}" if site.settings.book else ""
    return f"""<footer>
<p>{esc(t['copyright'].format(year=site.year, author=site.settings.author))},
<a href="{esc(site.settings.license)}">{esc(site.license_name())}</a>.{unofficial}
<a href="{esc(issues)}">{esc(report)}</a>.</p>
</footer>"""


def render_problem(site, problem):
    number = f'<span class="number">{esc(site.labels["problem_label"])} {esc(problem.number)}</span>'
    title = f"{number} {rich(problem.title)}" if problem.title else number
    if problem.href:
        title = f'<a href="{problem.href}">{title}</a>'
    if problem.done:
        return f'<li id="{problem.id}">{title}</li>'
    return (f'<li id="{problem.id}" class="todo">{title} '
            f'<span class="status">{esc(site.labels["not_done_label"])}</span></li>')


def render_heading(site, heading, body):
    """A heading of the catalogue, its problems and its headings."""
    tag = {"chapter": "h2", "section": "h3", "subsection": "h4"}[heading.level]
    if heading.level == "chapter":
        body.append(f'<section id="{heading.id}">')
        body.append(f"<h2>{esc(heading.label(site.labels))}</h2>")
    else:
        body.append(f'<{tag} id="{heading.id}">{esc(heading.label(site.labels))}</{tag}>')
    if heading.direct:
        body.append('<ul class="problems">')
        body.extend(render_problem(site, p) for p in heading.direct)
        body.append("</ul>")
    for child in heading.children:
        render_heading(site, child, body)
    if heading.level == "chapter":
        body.append("</section>")


def index_description(site, problems):
    return site.settings.description.replace("{done}", str(done_count(problems))) \
        .replace("{total}", str(len(problems)))


def render_index(chapters, problems, site, manual_size):
    s, t, b = site.settings, site.text, site.settings.book
    body = []
    for chapter in chapters:
        render_heading(site, chapter, body)
    description = index_description(site, problems)
    structured = {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": s.title,
        "url": site.url(),
        "description": description,
        "inLanguage": t["lang"],
        "author": person(s.author),
        "license": s.license,
    }
    if b:
        structured["about"] = book_ld(b)
    extra = ""
    if s.google_site_verification:
        extra = f'<meta name="google-site-verification" content="{esc(s.google_site_verification)}">\n'
    # The book's title in the heading is set off, as in the original site
    heading = esc(s.title)
    if b and esc(b.title) in heading:
        heading = heading.replace(esc(b.title), f"<em>{esc(b.title)}</em>", 1)
    by = esc(t["solutions_by"].format(author=s.author))
    # Editions, by their mode (and their name when two have the same mode)
    editions = ""
    if site.editions:
        modes = [e.solutions for e in site.editions]
        links = []
        for e in site.editions:
            label = t["modes"][e.solutions] + (f" ({e.name})" if modes.count(e.solutions) > 1 else "")
            links.append(f'<a href="{e.pdf}">{esc(label)}</a> <span class="note">'
                         f'({esc(t["pages"](e.pages))}, {esc(site.size(e.size))})</span>')
        editions = (f'<p class="editions">{esc(t["editions"])}{esc(site.colon())} '
                    f'{" · ".join(links)}</p>\n')
    reference = f"{b.reference(t['and'])} · {by}" if b else by
    return f"""<!doctype html>
<html lang="{t['lang']}">
{render_head(site, s.title, description, site.url(), "", "website", structured, extra)}
<body>
<header>
<h1>{heading}</h1>
<p class="lead">{esc(description)}</p>
<p class="reference">{reference}</p>
<p class="actions"><a class="button" href="main.pdf">{esc(t['download_manual'])}</a>
<span class="note">PDF, {esc(t['pages'](site.manual_pages))}, {esc(site.size(manual_size))}</span> ·
<a href="{esc(site.repository)}">{esc(site.repository_name())}</a></p>
{editions}<p class="progress">{esc(t['progress'](done_count(problems), len(problems)))}</p>
</header>
<main>
{chr(10).join(body)}
</main>
{render_footer(site)}
</body>
</html>
"""


def page_heading(site, problem):
    """Label and subject: "§9 Problem 3: Title"."""
    return f"{problem.label}{site.colon()} {plain(problem.subject)}" if problem.subject \
        else problem.label


def page_title(site, problem):
    """<title> of a problem page: label and subject, with the site name when
    it fits in TITLE_MAX characters."""
    title = page_heading(site, problem)
    named = f"{title} | {site.settings.short_name}"
    return named if len(named) <= TITLE_MAX else title


def problem_description(site, problem):
    """At most 160 characters, as search results show (checked by verify_site)."""
    return site.text["description"].format(
        label=problem.label, work=site.work, subject=plain(problem.subject or problem.label),
        pages=site.text["pages"](problem.pages))


def render_problem_page(problem, previous, following, site, pdf_size):
    s, t = site.settings, site.text
    canonical = site.url(problem.page)
    pdf = f"../{problem.pdf}"
    pages = t["pages"](problem.pages)
    title = page_title(site, problem)
    description = problem_description(site, problem)
    crumbs = [(s.title, site.url(), "../")]
    crumbs += [(h.label(site.labels), site.url(f"#{h.id}"), f"../#{h.id}") for h in problem.headings]
    crumbs.append((problem.label, canonical, None))
    resource = {
        "@type": "LearningResource",
        "name": page_heading(site, problem),
        "description": description,
        "url": canonical,
        "learningResourceType": t["resource_type"],
        "inLanguage": t["lang"],
        "author": person(s.author),
        "license": s.license,
        "isPartOf": {"@type": "WebSite", "name": s.title, "url": site.url()},
        "encoding": {"@type": "MediaObject", "contentUrl": site.url(problem.pdf),
                     "encodingFormat": "application/pdf"},
    }
    if s.book:
        resource["about"] = book_ld(s.book)
    structured = {
        "@context": "https://schema.org",
        "@graph": [
            {"@type": "BreadcrumbList", "itemListElement": [
                {"@type": "ListItem", "position": i, "name": name, "item": url}
                for i, (name, url, _) in enumerate(crumbs, 1)]},
            resource,
        ],
    }

    trail = " › ".join(f'<a href="{href}">{esc(name)}</a>' for name, _, href in crumbs[:-1])
    # Its headings, from the deepest: number (with the chapter label) and title
    headings = [(h.level, esc(f"{site.labels['chapter_label']} {h.number}"
                              if h.level == "chapter" else h.number), esc(h.title))
                for h in reversed(problem.headings) if h.serial]
    lead = t["lead"](esc(f"{site.labels['problem_label']} {problem.number}"), headings,
                     s.book.reference(t["and"]) if s.book else "", esc(s.author))
    manual = f'<a href="../main.pdf#page={problem.start + 1}">{esc(t["full_manual"])}</a>'
    where = t["manual_pages"] if problem.pages > 1 else t["manual_page"]
    where = esc(where.format(first=problem.start + 1, last=problem.end + 1, manual="{manual}"))
    subject = rich(problem.subject) if problem.subject else esc(problem.label)
    body = [f'<nav class="breadcrumb" aria-label="{esc(t["breadcrumb"])}">{trail}</nav>',
            "<header>",
            f'<h1><span class="label">{esc(problem.label)}</span> {subject}</h1>',
            f'<p class="lead">{lead}</p>',
            f'<p class="actions"><a class="button" href="{pdf}">{esc(t["open_pdf"])}</a> '
            f'<a href="{pdf}" download>{esc(t["download"])}</a> '
            f'<span class="note">{esc(pages)}, {esc(site.size(pdf_size))} · '
            f'{where.replace("{manual}", manual)}</span></p>',
            "</header>",
            "<main>",
            f'<object class="viewer" data="{pdf}" type="application/pdf" '
            f'aria-label="{esc(t["pdf_label"].format(label=problem.label))}">',
            f'<p class="note">{esc(t["no_viewer"])} '
            f'<a href="{pdf}">{esc(t["open_pdf_inline"])}</a>.</p>',
            "</object>"]
    if problem.parts:
        parts = " · ".join(f'<a href="{pdf}#page={x.page - problem.start + 1}">{esc(x.number)}</a>'
                           for x in problem.parts)
        body.append(f'<p class="parts">{esc(t["parts"])}{esc(site.colon())} {parts}</p>')
    pager = []
    if previous:
        pager.append(f'<a rel="prev" href="{previous.id}.html">← {esc(previous.label)}</a>')
    pager.append(f'<a href="../">{esc(t["all_problems"])}</a>')
    if following:
        pager.append(f'<a rel="next" href="{following.id}.html">{esc(following.label)} →</a>')
    body.append(f'<nav class="pager" aria-label="{esc(t["pager"])}">{" ".join(pager)}</nav>')
    body.append("</main>")
    return f"""<!doctype html>
<html lang="{t['lang']}">
{render_head(site, title, description, canonical, "../", "article", structured)}
<body class="problem-page">
{chr(10).join(body)}
{render_footer(site)}
</body>
</html>
"""


def site_paths(problems, site):
    """Paths of the sitemap: the homepage, the solved-problem pages, the full
    manual, its editions and the solved-problem PDFs."""
    solved = [p for p in problems if p.done]
    return [""] + [p.page for p in solved] + ["main.pdf"] + [e.pdf for e in site.editions] \
        + [p.pdf for p in solved]


def render_sitemap(problems, site):
    entries = "".join(f"  <url><loc>{esc(site.url(u))}</loc></url>\n"
                      for u in site_paths(problems, site))
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
            f"{entries}</urlset>\n")


def theme_css(color):
    """Colors of the theme (ThemeColor of the manual), after style.css: the
    color itself on light paper, lighter on dark paper, and a readable text
    color on it."""
    rgb = [int(color[i:i + 2], 16) for i in (1, 3, 5)]

    def luminance(c):
        c = [x / 255 for x in c]
        c = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
        return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

    light = [round(x + (255 - x) * 0.55) for x in rgb]
    ink = "#ffffff" if luminance(rgb) < 0.18 else "#1f1c18"
    return f"""
/* Theme color of the manual (ThemeColor), written by build.py */
:root {{ --theme: {color}; --theme-ink: {ink}; }}
@media (prefers-color-scheme: dark) {{
  :root {{ --theme: #{''.join(f'{x:02x}' for x in light)}; --theme-ink: #161412; }}
}}
"""


def write_text(path, text):
    path.write_text(text, encoding="utf-8", newline="\n")


# ============ Main ============ #

# Marks an output folder as written by this script, even after a failed build
# (a hidden file, left out of the Pages artifact)
MARKER = ".website-build"


def prepare_output(out, root):
    """Empty the output folder, refusing anything but a previous build."""
    if out == root or out in root.parents:
        sys.exit(f"--out {out} would overwrite the project")
    if out.exists():
        if any(out.iterdir()) and not (out / MARKER).is_file():
            sys.exit(f"{out} is not empty and is not a previous website build: choose another --out")
        shutil.rmtree(out)
    (out / "pdf").mkdir(parents=True)
    (out / "problems").mkdir()
    write_text(out / MARKER, "Written by solution-manual/site/build.py: deleted at each build.\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--out", default="_site", help="output folder (default: _site)")
    parser.add_argument("--base-url", default="",
                        help=f"public URL of the site (default: base_url in {SETTINGS})")
    args = parser.parse_args()

    root = Path.cwd().resolve()
    out = Path(args.out).resolve()
    errors = Errors()
    settings = read_settings(args.base_url, errors)
    data = read_index(errors)
    reader = PdfReader(MANUAL)
    anchors = Anchors(reader)
    site = Site(settings, data, len(reader.pages))
    author = (reader.metadata or {}).get("/Author") or settings.author
    chapters, headings, problems = read_manual(reader, anchors, data,
                                               data["layout"]["margin_bottom"], errors)
    add_titles(problems, errors)
    check_titles(site, problems, errors)
    site.editions = read_editions(settings, data, errors)

    prepare_output(out, root)
    for problem in problems:
        problem.published = problem.done or settings.publish_unsolved
    owner = {page: p for p in problems for page in range(p.start, p.end + 1)}
    # Chapter anchors (title and running header) of the chapters in the catalogue
    chapter_links = {}
    for chapter in chapters:
        if chapter.serial:
            chapter_links[chapter.anchor] = chapter.id
            chapter_links["chapter-title." + chapter.anchor.partition(".")[2]] = chapter.id
    for problem in problems:
        if problem.published:
            write_problem_pdf(reader, anchors, problem, chapter_links, owner, site, author,
                              out / problem.pdf, errors)
    errors.check("problem PDFs")
    by_id = {p.id: p for p in problems}
    for problem in problems:
        for ref in problem.refs:
            by_id[ref].cited_by.add(problem.id)
    index_ids = {h.id for h in [*chapters, *headings.values()] if h.problems} | set(by_id)
    verify_pdfs(out, problems, site, index_ids, errors)

    shutil.copyfile(MANUAL, out / "main.pdf")
    for edition in site.editions:
        shutil.copyfile(f"build/{edition.pdf}", out / edition.pdf)
    data = catalogue_data(chapters, problems, site, author)
    write_text(out / "catalogue.json", json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    write_text(out / "index.html", render_index(chapters, problems, site, Path(MANUAL).stat().st_size))
    solved = [p for p in problems if p.done]
    for i, problem in enumerate(solved):
        previous = solved[i - 1] if i > 0 else None
        following = solved[i + 1] if i + 1 < len(solved) else None
        write_text(out / problem.page,
                   render_problem_page(problem, previous, following, site,
                                       (out / problem.pdf).stat().st_size))
    write_text(out / "sitemap.xml", render_sitemap(problems, site))
    write_text(out / "style.css", (HERE / "style.css").read_text(encoding="utf-8")
               + theme_css(site.theme))
    verify_site(out, problems, site, errors)

    published = [p for p in problems if p.published]
    pdf_size = sum((out / p.pdf).stat().st_size for p in published)
    shown = [h for h in headings.values() if h.problems]
    print(f"{len(chapters)} chapters, {len(shown) - len(chapters)} sections and subsections, "
          f"{len(problems)} problems ({done_count(problems)} solved, "
          f"{sum(len(p.parts) for p in problems)} parts, "
          f"{sum(len(p.refs) for p in problems)} cross-problem links)")
    print(f"{len(published)} problem PDFs, {sum(p.pages for p in published)} pages, "
          f"{site.size(pdf_size)}; {len(solved)} problem pages; website in {out}")


if __name__ == "__main__":
    main()

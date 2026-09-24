# CLAUDE.md

Instructions for working in this repository. The global rules in the user's own CLAUDE.md apply on top of these: no em dashes, no emoji, plain prose, sentence case headings, a blank line after every heading, charts only from code chunks.

## What this repository is

Quarto manuscripts that answer questions from the Centre for Science and Environment (CSE) Phase II report "Evaluation of FSTPs and STP Co-treatment Systems across India" (2023). Each manuscript answers one question from data extracted from the report. The README lists the current manuscripts and their questions.

## Folder template

- `data/raw_data/` holds source documents exactly as obtained. Never edit a file here. The only file is the report PDF.
- `data/derived_data/` holds tables extracted from the raw data, one CSV per table. Prefer a script in `analysis/` that writes the table. A hand transcription is allowed when a script is not worth it, and the README must say which tables are hand transcribed.
- `data/metadata/codebook.csv` is the single codebook for every derived table. See the codebook section.
- `analysis/` holds the manuscripts (`.qmd`) and the scripts (`.R`).
- `prompts/` holds the verbatim prompts behind Claude assisted commits. The commit skill writes these files; do not edit them by hand.
- `references.bib` at the root holds the citations for all manuscripts.
- `_output/` is where Quarto writes rendered files. It is ignored by git, as are `.quarto/` and `*_files/`.

## Naming rules

- File names are lowercase with dashes: `fstp-technology-tables.csv`, `plants-per-state.qmd`.
- Scripts carry a two digit prefix that gives their run order: `01-extract-annexure-2-faecal-coliform.R`. Manuscripts carry no prefix.
- A derived table is named after the part of the report it comes from, for example `annexure-2-faecal-coliform.csv`.
- A new manuscript is named after its question, not after the report.

## Codebook

`data/metadata/codebook.csv` has the columns `file`, `name`, `type`, `unit`, `description`, one row per variable of every derived table, in the column order of that table. The `file` column names the derived table. `type` is one of character, integer, numeric, logical. `unit` is filled only for measured quantities and is otherwise empty. A description states the allowed values or range, the source pages in the report, how the value was obtained, and any quirk of the source a reader must know.

Whenever a derived table gains, loses or renames a column, update the codebook in the same commit. A manuscript's setup chunk may check that the codebook names match the table columns.

## How to render

The Quarto project at the root is a default project with `execute-dir: project`, so every path inside a document or script is relative to the repository root. Run from the root:

```
Rscript analysis/01-extract-annexure-2-faecal-coliform.R
quarto render
```

The script rebuilds the Annexure II table from the PDF and is optional, because the table is committed. It needs the `pdftotext` tool from poppler. `quarto render` writes both manuscripts to `_output/analysis/`. The plants-per-state manuscript renders to HTML and DOCX from the project formats; the log reduction manuscript sets `format: docx` in its own YAML and renders only to DOCX. Rendering needs Quarto 1.4 or later and R with tidyverse and gt.

On this machine `quarto` is not on the PATH. Use the RStudio bundled binary:

```
/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render
```

The bibliography is set once in `_quarto.yml`, so a manuscript does not repeat it in its YAML.

## How the manuscripts are written

- Every table and chart comes from an R code chunk in the document, with `echo: false` inherited from the project and no code folding. The plot code sits in the chunk directly before the figure.
- A manuscript reads the derived tables from `data/derived_data/` and re-runs the consistency checks of the script in its setup chunk with `stopifnot()`, before any computation, so a stale or edited table fails the render.
- Numbers quoted in the prose are computed inline from the data, not typed.
- Chart colours come from a validated palette: blue `#2a78d6` for the first series, orange `#eb6834` for the second, muted ink `#52514e` for a third, surface `#fcfcfb`, ink `#0b0b0b`. The two manuscripts share a `theme_manuscript()` function copied into each setup chunk.
- Judgement calls about the data, such as how a plant is classified, are stated in the manuscript's data and method section with the reason.

## Git workflow

- `dev` is the standing integration branch. Commit there and open pull requests from `dev` into `main` with the open-pr skill. After a merge lands on `main`, fast forward `dev` and push it.
- Commit with the commit skill. It archives the prompt under `prompts/`, adds a `Prompts:` trailer and an `Assisted-by:` trailer, and never a co-author line. Put `Closes #N` in the body when a commit finishes an issue.
- Release with an annotated tag `vX.Y.Z` and a GitHub release that attaches the rendered DOCX.

## Facts about the report worth knowing

- The physical page index of the PDF equals the printed page number.
- Tables 1 to 8 (technology tables) are on pages 26 to 33. Table 9 (outlet values by technology group) is on pages 34 to 35. Annexure II (sludge, inlet and outlet parameters) is on pages 171 to 177; page 177 holds only sewage treatment plants.
- `pdftotext -layout` keeps the annexure columns aligned; the plain extraction does not. Extract page by page.
- Four Odisha FSTPs are listed but were not sampled. Puri is counted as an STP co-treatment plant. Patora's capacity is 9 kilolitres per week. Jhansi has two units listed as two plants. Table 9 outlet values differ from Annexure II for Siddipet, Sircilla and Phulera.

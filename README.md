# fstp-eval-india

Quarto manuscripts that answer questions from the Centre for Science and Environment (CSE) Phase II report "Evaluation of FSTPs and STP Co-treatment Systems across India" (2023), using data extracted from the report.

## Layout

The repository follows a fixed layout. Raw data stays in `data/raw_data/`, tables extracted from it go to `data/derived_data/`, the codebook lives in `data/metadata/`, and manuscripts and scripts live in `analysis/`. File names are lowercase with dashes. Scripts carry a two digit prefix that gives their run order.

- `data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf` is the CSE report as downloaded. Its original file name was `1689832445895.pdf`.
- `data/derived_data/fstp-technology-tables.csv` is a hand transcription of Tables 1 to 8 of the report, one row per plant. No script produces it.
- `data/metadata/codebook.csv` documents every derived table, one row per variable. The `file` column names the table each row belongs to.
- `analysis/plants-per-state.qmd` answers this question: for each of the eight states in the report, how many faecal sludge treatment plants (FSTPs) and how many STP co-treatment plants were evaluated, and what is the total installed FSTP capacity in kilolitres per day? All tables and charts in it are produced from the derived table by R code chunks.
- `references.bib` holds the citations.
- `prompts/` holds the verbatim prompts behind Claude assisted commits. Each commit message points to its prompt files in a `Prompts:` trailer.
- `plan-faecal-coliform-log-reduction.md` is the working plan for the next manuscript.

## Render

Run the following from the repository root. Output is written to `_output/analysis/`, which git ignores.

```
quarto render
```

Rendering needs Quarto 1.4 or later and R with the tidyverse and gt packages. Paths inside the documents are relative to the repository root.

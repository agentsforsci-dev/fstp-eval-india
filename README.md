# fstp-eval-india

Quarto manuscripts that answer questions from the Centre for Science and Environment (CSE) Phase II report "Evaluation of FSTPs and STP Co-treatment Systems across India" (2023), using data extracted from the report.

## Layout

The repository follows a fixed layout. Raw data stays in `data/raw_data/`, tables extracted from it go to `data/derived_data/`, the codebook lives in `data/metadata/`, and manuscripts and scripts live in `analysis/`. File names are lowercase with dashes. Scripts carry a two digit prefix that gives their run order.

- `data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf` is the CSE report as downloaded. Its original file name was `1689832445895.pdf`.
- `data/derived_data/fstp-technology-tables.csv` is a hand transcription of Tables 1 to 8 of the report, one row per plant. No script produces it. The check script below verifies it against the PDF.
- `data/metadata/codebook.csv` documents every derived table, one row per variable. The `file` column names the table each row belongs to.
- `data/derived_data/annexure-2-faecal-coliform.csv` holds the faecal coliform values of the 47 sampled FSTPs from Annexure II of the report, together with their Table 9 technology group. The script below writes it.
- `analysis/01-extract-annexure-2-faecal-coliform.R` reads the report PDF, extracts those values, checks them against the technology table, and writes the derived table above. It needs the pdftotext tool from poppler.
- `analysis/02-check-fstp-technology-tables.R` reads the row numbers, locations, capacities and sampling markers of Tables 1 to 8 back from the PDF and stops if any row of the hand transcribed table differs. It also checks the codebook and the plant counts against the executive summary of the report. It writes no file and needs pdftotext.
- `analysis/plants-per-state.qmd` answers this question: for each of the eight states in the report, how many faecal sludge treatment plants (FSTPs) and how many STP co-treatment plants were evaluated, and what is the total installed FSTP capacity in kilolitres per day? It renders to HTML and DOCX.
- `analysis/faecal-coliform-log-reduction.qmd` answers this question: by how many log10 units does faecal coliform fall from inlet to outlet at each FSTP in Annexure II, and does the median log reduction differ between DEWATS based plants and mechanised plants? It renders to DOCX and has one figure. All tables and charts in both manuscripts are produced from the derived tables by R code chunks.
- `references.bib` holds the citations.
- `prompts/` holds the verbatim prompts behind Claude assisted commits. Each commit message points to its prompt files in a `Prompts:` trailer.
- `plan-faecal-coliform-log-reduction.md` is the working plan for the next manuscript.

## Reproduce

Run the following from the repository root. The first command rebuilds the Annexure II table from the PDF; it is committed, so this step is optional. The second checks the hand transcribed technology table against the PDF and is optional too. The third renders both manuscripts into `_output/analysis/`, which git ignores.

```
Rscript analysis/01-extract-annexure-2-faecal-coliform.R
Rscript analysis/02-check-fstp-technology-tables.R
quarto render
```

Rendering needs Quarto 1.4 or later and R with the tidyverse and gt packages. Paths inside the documents and the script are relative to the repository root.

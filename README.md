# fstp-eval-india

A Quarto manuscript that answers one question from the Centre for Science and Environment (CSE) Phase II report "Evaluation of FSTPs and STP Co-treatment Systems across India" (2023). For each of the eight states in the report, how many faecal sludge treatment plants (FSTPs) and how many STP co-treatment plants were evaluated, and what is the total installed FSTP capacity in kilolitres per day?

## Contents

- `data/1689832445895.pdf` is the CSE report.
- `data/fstp_technology_tables.csv` is a hand transcription of Tables 1 to 8 of the report, one row per plant.
- `index.qmd` is the manuscript. All tables and charts are produced from the CSV by R code chunks in the document.
- `references.bib` holds the citation for the report.

## Render

Run the following from the repository root. The output is written to `_manuscript/`.

```
quarto render
```

The manuscript needs R with the tidyverse and gt packages installed.

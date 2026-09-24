# Plan: faecal coliform log reduction manuscript, with the repository restructured

Edit this file freely. Tick or change the decisions in the first section, strike anything you do not want, and tell me when to start. I will read the file back before doing anything.

## Decisions

Tick one option per item, or write your own.

**1. Existing files**

- [x] Move the PDF, the technology table, its codebook and the first manuscript into the new layout with git mv, so the whole repository follows one convention.
- [ ] Leave the existing files where they are and apply the layout only to the new work.

**2. Where scripts live and what gets a prefix**

- [x] Scripts in `analysis/` beside the manuscripts. Only scripts get the two digit prefix. Manuscripts are `analysis/plants-per-state.qmd` and `analysis/faecal-coliform-log-reduction.qmd`.
- [ ] Scripts in a separate folder: `____________`
- [ ] Manuscripts also get a prefix: `____________`

**3. PDF file name**

- [ ] Keep `1689832445895.pdf` as downloaded.
- [x] Rename to `cse-2023-fstp-evaluation-phase-2.pdf`

**4. The technology table (Tables 1 to 8)**

- [x] Stays a hand transcription, no script. The README says so.
- [ ] Write a script for it as well.

**5. Codebook**

- [x] One file, `data/metadata/codebook.csv`, with columns file, name, type, unit, description.
- [ ] One codebook per derived table: `____________`

**6. Grouping for the comparison**

- [x] Follow Table 9 of the report. DEWATS based = the 33 plants under the DEWATS/DWWT heading (includes Unnao, which has a screw press). Mechanised = MBBR (6, includes Uppal and Modinagar as Table 9 places them) plus electrocoagulation (Nalgonda) plus packaged module (Warangal) = 8. Geotube (3) and Mizuchi (3) shown as "Other" and left out of the two group test, with sensitivity variants that add geotube to mechanised and Mizuchi to DEWATS based.
- [ ] Count the three geotube plants as mechanised in the primary analysis (n 11).
- [ ] Other: `____________`

**7. Inlet definition**

- [x] Primary log reduction from the annexure's Inlet row (leachate entering the treatment modules, the report's own definition of treatment efficiency) to Outlet. FS (sludge from tankers) to Outlet as a secondary column where FS is printed.
- [ ] Primary from FS to Outlet.

**8. This plan file**

- [ ] Keep `plan-faecal-coliform-log-reduction.md` untracked and delete it when the work is done.
- [x] Commit it with the work.

## Context

The repository holds the CSE 2023 Phase II report on FSTPs and STP co-treatment in India, a hand transcription of its Tables 1 to 8, and one Quarto manuscript (plant counts and capacity per state, released as v0.1.0). The new question asks, for each FSTP in Annexure II, by how many log10 units faecal coliform (FC, MPN/100 mL) falls from inlet to outlet, and whether the median log reduction differs between DEWATS based plants and mechanised plants (MBBR, electrocoagulation, packaged modules).

Layout convention: the PDF stays in `data/raw_data/`, extracted tables go to `data/derived_data/`, one codebook at `data/metadata/codebook.csv`, manuscripts in `analysis/`, file names lowercase with dashes, scripts with a two digit prefix.

What exploration established:

- Annexure II ("Consolidated physico-chemical and biological parameters of collected samples") is on printed pages 171 to 177 (physical page index equals printed number). One table per state, Madhya Pradesh and Chhattisgarh share Table 6, Uttarakhand (Table 7) holds only STPs.
- Each plant has up to three rows: FS (sludge from tankers), Inlet (leachate entering the treatment modules after solid liquid separation), Outlet (final discharge). Values are means over sampling rounds (three in most states, five in Rajasthan, unstated for Uttar Pradesh). No per round values are printed.
- All 47 sampled FSTPs have an inlet and an outlet FC value. FS is blank, NA, a dash, or absent for nine plants. No value uses scientific notation or detection limit markers. The 22 STPs sit in the same tables unmarked and must be excluded via `plant_type` in the technology table.
- Irregular rows: Jhansi II's inlet is labelled "ABR Inlet"; Unnao has an extra "ABR outlet" row (FC 1196) between inlet and outlet; the outlet rows of Warangal, Chodwar and Jhansi II start a new page with no plant name; several names are hyphenated across lines. `pdftotext -layout` output is column aligned (checked with `-bbox`); the raw extraction is not.
- The report never computes a log reduction and never uses the word "mechanised". Its Table 9 (pages 34 to 35) groups the 47 FSTPs under six headings: DEWATS/DWWT (33), MBBR (6), Geotube (3), Mizuchi (3), Electrocoagulation-Flotation (1), Packaged STP (1). The FC discharge limit it uses is 1000 MPN/100 mL. Table 9 outlet values differ from the annexure for Siddipet (6 vs 13), Sircilla (549 vs 631) and Phulera (173 vs 177).
- Provisional results from the extracted values, to be re-derived from the script output: all 47 log reductions positive, from 0.32 (Phulera) to 4.82 (Warangal). DEWATS based n 33, median 2.35 (IQR 1.58 to 3.26). Mechanised n 8, median 2.71 (IQR 2.39 to 2.92). Other n 6, median 2.14. Wilcoxon rank sum exact test W 114, p 0.57, Hodges Lehmann shift (DEWATS minus mechanised) -0.29, 95 per cent CI -1.20 to 0.71. No ties. With geotube in mechanised: p 0.67. Without the five plants whose outlet is exactly 30: p 0.58.

## Target tree

```
data/raw_data/1689832445895.pdf                       (git mv)
data/derived_data/fstp-technology-tables.csv          (git mv + rename)
data/derived_data/annexure-2-faecal-coliform.csv      (new, written by script 01)
data/metadata/codebook.csv                            (git mv + rename, extended)
analysis/01-extract-annexure-2-faecal-coliform.R      (new)
analysis/plants-per-state.qmd                         (git mv from index.qmd, paths updated)
analysis/faecal-coliform-log-reduction.qmd            (new)
references.bib                                        (stays at root, referenced from _quarto.yml)
_quarto.yml                                           (rewritten, see below)
README.md                                             (rewritten contents and render sections)
.gitignore                                            (add _output/)
prompts/                                              (unchanged)
```

## Quarto project wiring

The manuscript project type allows one article, so the root project becomes a default project that renders both documents:

```yaml
project:
  type: default
  render:
    - analysis/plants-per-state.qmd
    - analysis/faecal-coliform-log-reduction.qmd
  output-dir: _output
  execute-dir: project

bibliography: references.bib

format:
  html:
    toc: true
    number-sections: true
    fig-width: 8
    fig-height: 5
  docx:
    number-sections: true
    fig-width: 7
    fig-height: 4.5

execute:
  echo: false
  warning: false
  message: false
```

`execute-dir: project` makes every `read_csv("data/derived_data/...")` path relative to the root in both documents. Output lands in `_output/analysis/`. To test rather than assume: that `bibliography` at project level resolves from the root; that `output-dir` with a `render` list places both html and docx under `_output/`; that the figures and gt tables in the moved manuscript render unchanged.

## Script 01: `analysis/01-extract-annexure-2-faecal-coliform.R`

Inputs: `data/raw_data/1689832445895.pdf`, `data/derived_data/fstp-technology-tables.csv`. Output: `data/derived_data/annexure-2-faecal-coliform.csv`. Run with `Rscript analysis/01-extract-annexure-2-faecal-coliform.R` from the root.

1. Extract text with layout for pages 171 to 176 and pages 34 to 35 (Table 9). Use `pdftools::pdf_text()` if installed, else `system2("pdftotext", ...)` with `-layout`. Check at implementation which is available; pdftotext is at `/opt/homebrew/bin/pdftotext`.
2. Parse the annexure lines: a line whose sample type token is FS, Inlet, ABR Inlet or Outlet (and the STP variants) is a data row; its last numeric token is the FC value; the plant name is the text before the sample type on a name line, joined with a continuation line when the name is hyphenated or wrapped. Carry the current plant name across the page break so the three orphaned outlet rows attach to the right plant. Record `fs_printed` as value, blank, NA, dash or no_row.
3. Keep FSTPs only: join to the technology table on a hand written name map (annexure name to `table_no`, `s_no`) kept as a tribble in the script; Jhansi matched on capacity (annexure "Jhansi II (6KLD)" = Table 5 row 2, "Jhansi I (12KLD)" = row 3). Drop the 22 STP blocks. Drop Unnao's "ABR outlet" row; use Jhansi II's "ABR Inlet" as its inlet and keep the label in `inlet_label`.
4. Parse Table 9: heading lines set `table9_group` (DEWATS, MBBR, Geotube, Mizuchi, ECF, P-STP); each plant line gives the outlet FC column. Join by the same name map (Table 9 spellings differ again: Kalibilod, Chodwar, Shandnagar, Bongir, Modinagar*).
5. Checks with `stopifnot()`: 47 rows; join complete both ways against sampled FSTPs; inlet and outlet positive; FS positive where present; `fs_printed == "value"` exactly where FS is present; `table9_group` counts 33, 6, 3, 3, 1, 1; the Table 9 mismatches (difference above 1) are exactly Siddipet, Sircilla, Phulera.
6. Write the CSV with columns: `state`, `table_no`, `s_no`, `location` (from the technology table), `annex_table_no`, `annex_page`, `annex_location` (as printed, hyphenation removed), `fc_fs`, `fs_printed`, `inlet_label`, `fc_inlet`, `fc_outlet`, `table9_group`, `table9_fc_outlet`, `note`.

The script is the only writer of that CSV. The CSV is committed so the manuscripts render without re-running the script.

One time verification of the script output: render pages 171 to 176, 34, 35 and 30 with `pdftoppm -r 200 -png`, view each page image, and tick every FS, inlet and outlet value against the CSV in page order, including the three outlet rows that start a page. Re-render at 300 dpi if the last column is hard to read.

## Codebook: `data/metadata/codebook.csv`

Columns: `file`, `name`, `type`, `unit`, `description`. Rows: the ten existing rows with `file = fstp-technology-tables.csv`, plus fifteen rows for `annexure-2-faecal-coliform.csv` in the same style (allowed values, ranges, quirks, source pages, rounds per state, the report's inlet definition, the three Table 9 mismatches, that STP blocks are not extracted, that the file is written by script 01).

## Moved manuscript: `analysis/plants-per-state.qmd`

`git mv index.qmd analysis/plants-per-state.qmd`, then: data path to `data/derived_data/fstp-technology-tables.csv`; remove `bibliography:` from its YAML (project level now); update the file path mentioned in its prose; nothing else changes. Render and compare tables and figures with the v0.1.0 output.

## New manuscript: `analysis/faecal-coliform-log-reduction.qmd`

YAML mirrors the moved manuscript: title, subtitle naming Annexure II, author, date, abstract, keywords.

Chunk `setup`: tidyverse, gt; copy `state_levels`, the colours (blue `#2a78d6`, orange `#eb6834`, surface `#fcfcfb`, ink `#0b0b0b`, muted ink `#52514e`) and `theme_manuscript()` from the moved manuscript. Read both derived CSVs. Re-run the join and count checks from the script with `stopifnot()` before any computation, so a stale or edited CSV fails the render. Then the lookup from `table9_group` to analysis group (DEWATS to "DEWATS based"; MBBR, ECF and P-STP to "Mechanised"; Geotube and Mizuchi to "Other"); `lrv_inlet = log10(fc_inlet) - log10(fc_outlet)`; `lrv_fs` where FS exists; `meets_limit = fc_outlet <= 1000`; a per group summary; a `compare_groups(data, label)` helper returning one row (n per group, medians, median difference, Hodges Lehmann shift, 95 per cent CI, W, p, method) from `wilcox.test(lrv ~ group, conf.int = TRUE)` with levels ordered DEWATS based then Mechanised; a `ties` flag for the prose.

Sections (sentence case, blank line after each heading, plain prose, no em dashes):

1. Introduction: the report, Annexure II, the question, the 1000 MPN/100 mL limit.
2. Data and method: source pages and the extraction script; the report's definition of inlet and why inlet to outlet is primary and FS to outlet secondary; the technology grouping with the reasons for Unnao, Uppal, Modinagar, geotube and Mizuchi; statistics (medians and IQR, two sided Wilcoxon rank sum with Hodges Lehmann shift and CI, sensitivity variants: geotube in mechanised, without outlet 30 plants, FS to outlet, Mizuchi in DEWATS based); a sentence that n 8 only detects large shifts.
3. Results:
   - `fig-inlet-outlet`: dumbbell chart, one row per plant ordered by log reduction within group, x on log10 scale with comma labels, hollow point at inlet and filled point at outlet joined by a segment, colour by group, facets by group with free heights, dashed line at 1000 labelled as the discharge limit, `fig-height: 10`, `fig-width: 8`, `fig-alt` stating medians and extremes.
   - `tbl-plants`: gt grouped by analysis group, sorted by log reduction descending within group; columns state, plant as printed in the annexure, Table 9 technology, FC FS, FC inlet, FC outlet, log reduction inlet to outlet, log reduction FS to outlet, outlet within limit; "not printed" where FS is missing; font size 12.
   - `tbl-groups`: n, median, Q1, Q3, min, max, plants within limit per group and for all 47.
   - `fig-groups`: strip plot, y group, x log reduction from 0, jittered points by group colour, thick tick at the median, thin IQR bar, n labels.
   - `tbl-comparison`: one row per variant from `compare_groups`, method column included. Prose gives the primary medians, shift, CI and p with inline R and the plain conclusion: the data do not show a difference and the CI spans about two log units.
4. Limitations: log of means over rounds is not the mean of per round logs; rounds unstated for Uttar Pradesh; outlet value 30 at five plants as a possible reporting floor (four DEWATS based, one mechanised); the three Table 9 versus annexure differences, annexure used because the question names it; Thuraiyur FS printed as 30; Mizuchi plants called STP co-treatment in the state chapter but listed as FSTPs in Tables 6 and 9; group sizes; single report, no replication.
5. Conclusion: per plant range, group medians, test result, one sentence each.
6. References.

All chunks inherit `echo: false`; no code folding; charts only from chunks.

## README

Rewrite the contents section as the target tree with one line per file, say which derived file is scripted and which is hand transcribed, give the script command and `quarto render` (with a note that the Quarto binary on this machine is the RStudio bundled one), and list the two manuscripts with their questions.

## Verification

Quarto binary: `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto` (not on PATH).

1. `Rscript analysis/01-extract-annexure-2-faecal-coliform.R` runs clean and writes the CSV; run it twice and confirm the file is byte identical.
2. Page image check of every FC value as described above.
3. `quarto render` at the root renders both documents to `_output/analysis/` as html and docx with no errors.
4. `git status --short` shows the moves as renames, the new files, and no `_output`, `_manuscript`, `.quarto` or `*_files` entries.
5. Greps: no em dash, "simple", "easy" or "don't worry" in the new qmd, the script, the codebook or the README; no unresolved `?fig-` or `?tbl-` in either HTML; no source code blocks in either HTML.
6. View every figure PNG from `_output` for label collisions; check both docx files via pandoc plain text or the docx XML.
7. The moved manuscript's numbers are unchanged: 51 FSTPs listed, 47 sampled, 22 STPs, 1,382.3 KLD listed.
8. Numbers to eyeball in the new document, re-derived after step 2: 47 plants; groups 33, 8, 6; extremes Warangal 4.82 and Phulera 0.32; medians 2.35, 2.71, 2.14; W 114, p about 0.57, shift about -0.29, CI about -1.20 to 0.71, method "Wilcoxon rank sum exact test"; ten plants with outlet above 1000; five with outlet exactly 30; 38 with an FS value; Thuraiyur FS to outlet reduction 0; the three Table 9 mismatches named in the limitations.

## Risks and edge cases

- Parsing the annexure by text: the three orphaned outlet rows and the wrapped names are the known traps; the join checks and the page image check catch anything the parser gets wrong. If pdftools and pdftotext give different line splits, the script pins one of them and says which.
- Name matching: the hand written map in the script plus the `location` equality check and both anti joins.
- Ties: none now; the method column in `tbl-comparison` and the `ties` flag make a switch to the normal approximation visible.
- Zero or negative log reductions: none now; the positivity checks guard `log10`, and the strip plot axis must include negatives if any appear.
- Small mechanised group: lead with the medians and the figure; present the test as a bound on what the data can show, not as evidence of equivalence.
- Moving the first manuscript: the loss of the manuscript project type changes the HTML title block; compare the rendered output with v0.1.0 before committing.
- The 47 row gt table in docx may split awkwardly; keep the group headers and the small font.

## Implementation sequence

1. Read this file back and apply the decisions ticked above.
2. Restructure with git mv (PDF, technology table, codebook, first manuscript); create `data/metadata/`, `data/derived_data/`, `analysis/`; rewrite `_quarto.yml`; add `_output/` to `.gitignore`; update the moved manuscript's paths; render and compare with v0.1.0.
3. Write script 01; run it; verify its output against page images; extend the codebook.
4. Write the new manuscript with setup and checks only; render once.
5. Add figures, tables and prose; render; apply the greps; view the figures.
6. Rewrite the README; run the verification list.
7. Save the layout convention to memory as feedback (raw_data, derived_data, metadata/codebook.csv, analysis/, dashed lowercase names, two digit script prefix), since it applies beyond this task.
8. When asked to commit, use the commit skill on the dev branch; push and open a PR on request. This plan file is not committed unless decision 8 says so.

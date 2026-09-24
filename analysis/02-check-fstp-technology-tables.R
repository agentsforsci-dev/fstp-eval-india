# Check the hand transcribed technology tables against the report PDF.
#
# Tables 1 to 8 of the CSE 2023 report (pages 26 to 33) list every plant the
# study evaluated, one table per state. They were transcribed by hand into
# data/derived_data/fstp-technology-tables.csv because the technology and
# description cells wrap over several lines and were normalised during
# transcription, so a parser would have to encode every normalisation. The
# values that decide the plant counts and the capacity totals are printed on
# the first line of each row: the row number, the start of the location, the
# capacity value and unit, and the ** marker of an unsampled plant. This script
# reads those from the text layer of the PDF and compares them with the CSV row
# by row. It also checks the codebook, the internal rules of the table, and the
# plant counts against the executive summary of the report.
#
# Input:  data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf
#         data/derived_data/fstp-technology-tables.csv
#         data/metadata/codebook.csv
# Output: none. The script stops at the first check that fails and prints a
#         summary when every check passes. It writes no file, so it can run
#         before or after 01-extract-annexure-2-faecal-coliform.R.
#
# Run from the repository root:
#   Rscript analysis/02-check-fstp-technology-tables.R
#
# The manuscript analysis/plants-per-state.qmd repeats the checks that do not
# need the PDF in its setup chunk.

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(tibble)
})

pdf_path <- "data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf"
tech_path <- "data/derived_data/fstp-technology-tables.csv"
codebook_path <- "data/metadata/codebook.csv"
table_pages <- 26:33 # Tables 1 to 8 of the main text
footnote_page <- 30 # The ** footnote is printed under the end of Table 3

state_levels <- c("Telangana", "Tamil Nadu", "Odisha", "Rajasthan",
                  "Uttar Pradesh", "Madhya Pradesh", "Chhattisgarh", "Uttarakhand")

stopifnot(file.exists(pdf_path), file.exists(tech_path), file.exists(codebook_path))
if (Sys.which("pdftotext") == "") {
  stop("pdftotext (poppler) is required but was not found on the PATH")
}

# Read one PDF page as layout text lines ---------------------------------------
page_lines <- function(page) {
  tmp <- tempfile(fileext = ".txt")
  status <- system2("pdftotext",
                    c("-layout", "-f", page, "-l", page, shQuote(pdf_path), shQuote(tmp)))
  if (status != 0) stop("pdftotext failed on page ", page)
  lines <- read_lines(tmp)
  unlink(tmp)
  lines[str_trim(lines) != ""]
}

# Parse the table titles and the first line of every row -----------------------
# A title line names the table number and the state, and says "sewage
# treatment technologies" for Table 8. A row line starts with the row number in
# the S No column, then the location, then the capacity as a number and a unit.
# The row number sits within the first 30 characters of the line, which keeps
# description lines that happen to start with a number from matching.
title_re <- "^\\s*Table (\\d): List of (sewage )?treatment technologies evaluated in (.+?)\\s*$"
row_re <- "^\\s{0,30}(-?\\d{1,2})\\s{2,}(\\S.*?)\\s{2,}(\\d+(?:\\.\\d+)?)\\s(KLD|MLD|KLW)\\b"

titles <- list()
rows <- list()
table_no <- NA_integer_
for (page in table_pages) {
  for (line in page_lines(page)) {
    if (str_detect(line, title_re)) {
      m <- str_match(line, title_re)
      table_no <- as.integer(m[2])
      titles[[length(titles) + 1]] <- tibble(
        table_no = table_no, page = page,
        sewage = !is.na(m[3]), state = str_squish(m[4]))
    } else if (str_detect(line, row_re)) {
      m <- str_match(line, row_re)
      rows[[length(rows) + 1]] <- tibble(
        table_no = table_no, page = page,
        s_no_printed = m[2],
        location_printed = m[3],
        capacity_value = as.numeric(m[4]),
        capacity_unit = m[5])
    }
  }
}
titles <- bind_rows(titles)
pdf_rows <- bind_rows(rows) |>
  mutate(
    s_no = abs(as.integer(s_no_printed)),
    unsampled_marker = str_detect(location_printed, "\\*\\*$"),
    location_printed = str_remove(location_printed, "\\*+$"),
    capacity_unit = if_else(capacity_unit == "KLW", "KL/week", capacity_unit)) |>
  group_by(table_no) |>
  mutate(row_in_table = row_number()) |>
  ungroup()

# What the PDF says -------------------------------------------------------------
stopifnot(nrow(titles) == 8, identical(titles$table_no, 1:8),
          identical(titles$state, state_levels))
stopifnot(identical(titles$sewage, c(rep(FALSE, 7), TRUE)))
stopifnot(nrow(pdf_rows) == 73)
stopifnot(identical(pdf_rows |> count(table_no) |> pull(n),
                    c(12L, 9L, 21L, 3L, 10L, 4L, 2L, 12L)))
stopifnot(all(pdf_rows$s_no == pdf_rows$row_in_table))
# Tirumangalam is the only row whose number is printed with a minus sign
stopifnot(identical(pdf_rows$s_no_printed[str_starts(pdf_rows$s_no_printed, "-")], "-7"),
          pdf_rows$table_no[pdf_rows$s_no_printed == "-7"] == 2L)
stopifnot(sum(pdf_rows$unsampled_marker) == 4, all(pdf_rows$table_no[pdf_rows$unsampled_marker] == 3L))
footnote <- str_subset(page_lines(footnote_page),
                       "^\\s*\\*\\*Water samples could not be collected")
stopifnot(length(footnote) == 1)

# The CSV against the PDF ---------------------------------------------------------
tech <- read_csv(tech_path, show_col_types = FALSE)
codebook <- read_csv(codebook_path, show_col_types = FALSE)
stopifnot(identical(codebook$name[codebook$file == basename(tech_path)], names(tech)))
stopifnot(nrow(tech) == 73, !anyNA(select(tech, -note)))

compared <- inner_join(tech, pdf_rows, by = c("table_no", "s_no"), suffix = c("", "_pdf"))
stopifnot(nrow(compared) == 73)
stopifnot(identical(compared$state, state_levels[compared$table_no]))
# The CSV location starts with what is printed on the first line of the row.
# Spaces are dropped before comparing, because a location that wraps over two
# lines is printed without the space after the comma and St. Alosius is stored
# with a space that the report does not print.
squash <- function(x) str_remove_all(x, "\\s")
stopifnot(all(str_starts(squash(compared$location), fixed(squash(compared$location_printed)))))
stopifnot(all(compared$capacity_value == compared$capacity_value_pdf))
stopifnot(all(compared$capacity_unit == compared$capacity_unit_pdf))
stopifnot(all(compared$sampled == !compared$unsampled_marker))
stopifnot(all(str_detect(compared$note[compared$unsampled_marker], "Marked \\*\\* in the report")))
stopifnot(str_detect(compared$note[compared$s_no_printed == "-7"], "Printed as row number -7"))

# Internal rules of the CSV ---------------------------------------------------------
stopifnot(all(tech$plant_type %in% c("FSTP", "STP co-treatment")))
stopifnot(all(tech$capacity_unit %in% c("KLD", "MLD", "KL/week")))
# A row is an STP co-treatment plant when the report labels it so or when it
# comes from Table 8; every other row is an FSTP
rule_type <- if_else(
  tech$table_no == 8 | str_detect(tech$technology, regex("STP co-treatment", ignore_case = TRUE)),
  "STP co-treatment", "FSTP")
stopifnot(identical(tech$plant_type, rule_type))
stopifnot(all(tech$capacity_unit[tech$plant_type == "STP co-treatment" & tech$location != "Puri"] == "MLD"))
stopifnot(all(tech$capacity_unit[tech$plant_type == "FSTP" & tech$location != "Patora"] == "KLD"))
stopifnot(identical(tech$location[!tech$sampled], c("Surada", "Kashinagar", "Hinjilicut", "Talcher")),
          all(tech$state[!tech$sampled] == "Odisha"))

# Counts against the executive summary of the report (page 6) -----------------------
# The summary says 69 plants were evaluated, 47 FSTPs and 22 STPs, and gives
# the counts per state. Its FSTP counts exclude the four unsampled Odisha plants.
summary_counts <- tribble(
  ~state,           ~fstp, ~stp,
  "Telangana",      10L,   2L,
  "Tamil Nadu",     5L,    4L,
  "Odisha",         16L,   1L,
  "Rajasthan",      3L,    0L,
  "Uttar Pradesh",  7L,    3L,
  "Madhya Pradesh", 4L,    0L,
  "Chhattisgarh",   2L,    0L,
  "Uttarakhand",    0L,    12L)
counts <- tech |>
  group_by(state) |>
  summarise(fstp = sum(plant_type == "FSTP" & sampled),
            stp = sum(plant_type == "STP co-treatment"), .groups = "drop") |>
  arrange(match(state, state_levels))
stopifnot(isTRUE(all.equal(as.data.frame(counts), as.data.frame(summary_counts))))
stopifnot(sum(tech$plant_type == "FSTP") == 51,
          sum(tech$plant_type == "FSTP" & tech$sampled) == 47,
          sum(tech$plant_type == "STP co-treatment") == 22)

# Summary -------------------------------------------------------------------------------
kld <- tech |>
  filter(plant_type == "FSTP") |>
  mutate(capacity_kld = if_else(capacity_unit == "KL/week", capacity_value / 7, capacity_value)) |>
  group_by(state) |>
  summarise(fstp_listed = n(), kld_listed = sum(capacity_kld), .groups = "drop") |>
  arrange(match(state, state_levels))
cat("All checks passed: 73 rows in Tables 1 to 8 match the PDF.\n")
cat("Plants sampled per state (FSTP, STP):\n")
print(as.data.frame(counts), row.names = FALSE)
cat("Installed FSTP capacity listed per state (KLD):\n")
print(as.data.frame(kld), row.names = FALSE)
cat(sprintf("Total: %d FSTPs listed, 47 sampled, 22 STP co-treatment plants, %.1f KLD listed.\n",
            sum(kld$fstp_listed), sum(kld$kld_listed)))

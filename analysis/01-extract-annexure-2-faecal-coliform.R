# Extract faecal coliform (FC, MPN/100 mL) values for the 47 sampled FSTPs from
# Annexure II of the CSE 2023 report, together with the technology group and the
# outlet FC printed in Table 9 of the main text.
#
# Input:  data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf
#         data/derived_data/fstp-technology-tables.csv
# Output: data/derived_data/annexure-2-faecal-coliform.csv
#
# Run from the repository root:
#   Rscript analysis/01-extract-annexure-2-faecal-coliform.R
#
# The PDF was typeset in InDesign, so its text layer is the typeset text. The
# script reads it page by page with pdftotext in layout mode, which keeps the
# table columns aligned. The parser walks each line, keeps track of the plant
# block it is in, and picks the last number on each FS, Inlet and Outlet row as
# the FC value. The known quirks of the annexure are handled as code below and
# recorded in the note column of the output.

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(purrr)
  library(tibble)
  library(tidyr)
})

pdf_path <- "data/raw_data/cse-2023-fstp-evaluation-phase-2.pdf"
tech_path <- "data/derived_data/fstp-technology-tables.csv"
out_path <- "data/derived_data/annexure-2-faecal-coliform.csv"

annex_pages <- 171:176 # Annexure II tables 1 to 6 (page 177 holds only STPs)
table9_pages <- 34:35 # Table 9 of the main text

stopifnot(file.exists(pdf_path), file.exists(tech_path))
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

# Tokens are separated by two or more spaces in layout text
tokens <- function(line) str_split(str_trim(line), "\\s{2,}")[[1]]
is_number <- function(x) str_detect(x, "^-?\\d+(\\.\\d*)?$")

# Join a wrapped plant name: a trailing hyphen means the word continues
join_name <- function(current, fragment) {
  if (is.na(current) || current == "") return(fragment)
  if (str_ends(current, "-")) return(paste0(str_sub(current, 1, -2), fragment))
  paste(current, fragment)
}

# Parse Annexure II ------------------------------------------------------------
header_pattern <- regex(paste(
  "Locations", "^type$", "\\(ppm\\)", "\\(mg/L\\)", "Nitrogen", "MPN/100", "^ml\\)$",
  "EVALUATION OF FSTPS", "report\\.indd", "Annexure", "Consolidated", "^\\d+$",
  "Fecal Coliform",
  sep = "|"))
type_pattern <- regex("^(ABR [Ii]nlet|ABR [Oo]utlet|FS|Inlet|Outlet)\\b")

blocks <- list()
current <- NULL
current_table <- NA_integer_

push_current <- function() {
  if (!is.null(current)) blocks[[length(blocks) + 1]] <<- current
}

for (page in annex_pages) {
  for (line in page_lines(page)) {
    trimmed <- str_trim(line)
    caption <- str_match(trimmed, "^Table (\\d+):")
    if (!is.na(caption[1, 1])) {
      push_current()
      current <- NULL
      current_table <- as.integer(caption[1, 2])
      next
    }
    if (str_detect(trimmed, header_pattern)) next

    toks <- tokens(line)
    type_idx <- which(str_detect(toks, type_pattern))[1]

    if (is.na(type_idx)) {
      # No sample type on this line. Numbers mean an STP row we do not need
      # (for example "Co-treated wastewater"). Text alone continues a name or
      # a caption; captions are ignored because no block is open after them.
      if (any(is_number(toks)) || is.null(current)) next
      current$name <- join_name(current$name, paste(toks, collapse = " "))
      next
    }

    name_part <- if (type_idx > 1) paste(toks[seq_len(type_idx - 1)], collapse = " ") else ""
    type <- str_match(toks[type_idx], type_pattern)[1, 2]
    type <- str_replace(str_replace(type, "[Ii]nlet", "Inlet"), "[Oo]utlet", "outlet")
    if (type == "outlet") type <- "Outlet"
    values <- if (type_idx < length(toks)) toks[(type_idx + 1):length(toks)] else character(0)
    fc_token <- if (length(values) > 0) values[length(values)] else NA_character_

    has_inlet <- !is.null(current) && any(current$rows$type %in% c("Inlet", "ABR Inlet"))
    has_outlet <- !is.null(current) && any(current$rows$type == "Outlet")
    starts_block <- name_part != "" &&
      (type == "FS" || (type == "Inlet" && (is.null(current) || has_inlet || has_outlet)))

    if (starts_block) {
      push_current()
      current <- list(name = name_part, annex_table_no = current_table, annex_page = page,
                      rows = tibble(type = character(), fc_token = character(),
                                    page = integer(), n_values = integer()))
    } else if (name_part != "") {
      # A name fragment printed on a data row of the open block, for example
      # "Coimbatore" on the Inlet row of "Ukkadam," or "Indore" on the Outlet
      # row of "Kalibillod,"
      current$name <- join_name(current$name, name_part)
    }
    if (is.null(current)) stop("Data row without a plant block on page ", page, ": ", trimmed)
    current$rows <- add_row(current$rows, type = type, fc_token = fc_token,
                            page = page, n_values = length(values))
  }
}
push_current()

annex <- map_dfr(blocks, function(b) {
  fs <- b$rows |> filter(type == "FS")
  inlet <- b$rows |> filter(type == "Inlet")
  abr_inlet <- b$rows |> filter(type == "ABR Inlet")
  outlet <- b$rows |> filter(type == "Outlet")
  inlet_row <- if (nrow(inlet) > 0) inlet[1, ] else if (nrow(abr_inlet) > 0) abr_inlet[1, ] else NULL
  fs_token <- if (nrow(fs) > 0) fs$fc_token[1] else NA_character_
  tibble(
    annex_location = str_squish(b$name),
    annex_table_no = b$annex_table_no,
    annex_page = b$annex_page,
    fs_printed = case_when(
      nrow(fs) == 0 ~ "no_row",
      is.na(fs_token) ~ "blank",
      fs_token == "NA" ~ "NA",
      fs_token == "_" ~ "dash",
      is_number(fs_token) ~ "value",
      TRUE ~ "other"),
    fc_fs = if (!is.na(fs_token) && is_number(fs_token)) as.numeric(fs_token) else NA_real_,
    inlet_label = if (is.null(inlet_row)) NA_character_ else inlet_row$type,
    fc_inlet = if (is.null(inlet_row)) NA_real_ else as.numeric(inlet_row$fc_token),
    fc_outlet = if (nrow(outlet) > 0) as.numeric(outlet$fc_token[1]) else NA_real_,
    outlet_page = if (nrow(outlet) > 0) outlet$page[1] else NA_integer_,
    has_abr_outlet = any(b$rows$type == "ABR outlet"),
    n_rows = nrow(b$rows)
  )
})

# Parse Table 9 ----------------------------------------------------------------
group_patterns <- c(
  "Decentralized wastewater" = "DEWATS",
  "Moving Bed Biofilm" = "MBBR",
  "Geotube" = "Geotube",
  "Mizuchi" = "Mizuchi",
  "Electrocoagulation" = "ECF",
  "Packaged sewage" = "P-STP")

table9 <- list()
group <- NA_character_
for (page in table9_pages) {
  for (line in page_lines(page)) {
    trimmed <- str_trim(line)
    hit <- names(group_patterns)[str_detect(trimmed, fixed(names(group_patterns)))]
    if (length(hit) == 1) { group <- unname(group_patterns[hit]); next }
    toks <- tokens(line)
    if (is.na(group) || length(toks) < 5) next
    if (!str_detect(toks[1], "^\\d+$") || is_number(toks[2])) next
    nums <- toks[-(1:2)]
    if (!all(is_number(nums)) || length(nums) < 3) next
    # The last three numbers are faecal coliform, discharge COD and discharge
    # BOD. Nalgonda has one per cent removal value missing, so counting from
    # the end is the safe way to reach the FC column.
    table9[[length(table9) + 1]] <- tibble(
      table9_location = str_remove(toks[2], "\\*$"),
      table9_group = group,
      table9_fc_outlet = as.numeric(nums[length(nums) - 2]))
  }
}
table9 <- bind_rows(table9)
stopifnot(nrow(table9) == 47)

# Name map: annexure name, Table 9 name, technology table key --------------------
name_map <- tribble(
  ~annex_location,            ~table9_location,        ~table_no, ~s_no,
  "Boduppal",                 "Boduppal",              1L, 1L,
  "Uppal",                    "Uppal",                 1L, 2L,
  "Bongir",                   "Bongir",                1L, 5L,
  "Shandnagar",               "Shandnagar",            1L, 6L,
  "Siddipet",                 "Siddipet",              1L, 7L,
  "Sircilla",                 "Sircilla",              1L, 8L,
  "Nirmal",                   "Nirmal",                1L, 9L,
  "Kamareddy",                "Kamareddy",             1L, 10L,
  "Warangal",                 "Warangal",              1L, 11L,
  "Nalgonda",                 "Nalgonda",              1L, 12L,
  "Periyanaickenpalayam",     "Periyanaickenpalayam",  2L, 2L,
  "Thuraiyur, Trichy",        "Thuraiyur",             2L, 4L,
  "Thirumangalam, Madurai",   "Thirumangalam",         2L, 7L,
  "Vickramasingapuram",       "Vickramasingapuram",    2L, 8L,
  "Sengottai",                "Shenkottai",            2L, 9L,
  "Balasore",                 "Balasore",              3L, 2L,
  "Baripada",                 "Baripada",              3L, 3L,
  "Bhubaneswar",              "Bhubaneswar",           3L, 4L,
  "Dhenkanal",                "Dhenkanal",             3L, 5L,
  "Berhampur",                "Berhampur",             3L, 6L,
  "Angul",                    "Angul",                 3L, 7L,
  "Sambalpur",                "Sambalpur",             3L, 8L,
  "Rourkela",                 "Rourkela",              3L, 9L,
  "Asika",                    "Asika",                 3L, 10L,
  "Bhadrak",                  "Bhadrak",               3L, 11L,
  "Chodwar",                  "Chodwar",               3L, 12L,
  "Jagatsinghpur",            "Jagatsinghpur",         3L, 13L,
  "Jatni",                    "Jatni",                 3L, 14L,
  "Khordha",                  "Khordha",               3L, 15L,
  "Nimapada",                 "Nimapada",              3L, 16L,
  "Paralakhemundi",           "Paralakhemundi",        3L, 17L,
  "Phulera",                  "Phulera",               4L, 1L,
  "Lalsot",                   "Lalsot",                4L, 2L,
  "Khandela",                 "Khandela",              4L, 3L,
  "Unnao",                    "Unnao",                 5L, 1L,
  "Jhansi II (6KLD)",         "Jhansi 6KLD",           5L, 2L,
  "Jhansi I (12KLD)",         "Jhansi 12KLD",          5L, 3L,
  "Chunar",                   "Chunar",                5L, 4L,
  "Modinagar",                "Modinagar",             5L, 5L,
  "Loni",                     "Loni",                  5L, 6L,
  "Amethi",                   "Amethi",                5L, 7L,
  "Kalibillod, Indore",       "Kalibilod, Indore",     6L, 1L,
  "Elanza",                   "Elanza, Jabalpur",      6L, 2L,
  "Ojus",                     "Ojus, Jabalpur",        6L, 3L,
  "St.Alosius",               "St.Alosius, Jabalpur",  6L, 4L,
  "Kumhari",                  "Kumhari, Raipur",       7L, 1L,
  "Patora",                   "Patora, Raipur",        7L, 2L)

tech <- read_csv(tech_path, show_col_types = FALSE)
fstp_sampled <- tech |> filter(plant_type == "FSTP", sampled)

# Join ---------------------------------------------------------------------------
fc <- name_map |>
  inner_join(annex, by = "annex_location") |>
  inner_join(table9, by = "table9_location") |>
  inner_join(fstp_sampled |> select(state, table_no, s_no, location), by = c("table_no", "s_no"))

# Checks ---------------------------------------------------------------------------
stopifnot(nrow(name_map) == 47, nrow(fc) == 47)
stopifnot(nrow(anti_join(name_map, annex, by = "annex_location")) == 0)
stopifnot(nrow(anti_join(name_map, table9, by = "table9_location")) == 0)
stopifnot(nrow(anti_join(fstp_sampled, fc, by = c("table_no", "s_no"))) == 0)
stopifnot(all(fc$fc_inlet > 0), all(fc$fc_outlet > 0), all(is.na(fc$fc_fs) | fc$fc_fs > 0))
stopifnot(all((fc$fs_printed == "value") == !is.na(fc$fc_fs)))
stopifnot(all(fc$inlet_label %in% c("Inlet", "ABR Inlet")))
group_counts <- fc |> count(table9_group) |> deframe()
stopifnot(identical(group_counts[c("DEWATS", "MBBR", "Geotube", "Mizuchi", "ECF", "P-STP")],
                    c(DEWATS = 33L, MBBR = 6L, Geotube = 3L, Mizuchi = 3L, ECF = 1L, `P-STP` = 1L)))
mismatch <- fc |> filter(abs(fc_outlet - table9_fc_outlet) > 1)
stopifnot(setequal(mismatch$location, c("Siddipet", "Sircilla", "Phulera")))

# Notes and output -------------------------------------------------------------------
fc <- fc |>
  mutate(note = pmap_chr(list(fs_printed, inlet_label, has_abr_outlet, outlet_page, annex_page,
                              fc_outlet, table9_fc_outlet, annex_location),
    function(fsp, il, abr, op, ap, out, t9, nm) {
      notes <- character(0)
      if (fsp == "blank") notes <- c(notes, "FS row printed without values")
      if (fsp == "NA") notes <- c(notes, "FS row printed as NA")
      if (fsp == "dash") notes <- c(notes, "FS row printed as dashes")
      if (fsp == "no_row") notes <- c(notes, "No FS row printed")
      if (il == "ABR Inlet") notes <- c(notes, "Inlet row printed as ABR Inlet and used as the inlet")
      if (abr) notes <- c(notes, "An intermediate ABR outlet row (FC 1196) is printed and not used")
      if (!is.na(op) && op != ap) notes <- c(notes, paste0("Outlet row printed at the top of page ", op, " without the plant name"))
      if (abs(out - t9) > 1) notes <- c(notes, paste0("Table 9 prints outlet FC ", format(t9, big.mark = ""), " for this plant"))
      if (str_detect(nm, "^(Periyanaickenpalayam|Thirumangalam|Vickramasingapuram|Paralakhemundi)")) notes <- c(notes, "Name printed across two lines")
      paste(notes, collapse = "; ")
    })) |>
  arrange(table_no, s_no) |>
  select(state, table_no, s_no, location, annex_table_no, annex_page, annex_location,
         fc_fs, fs_printed, inlet_label, fc_inlet, fc_outlet, table9_group, table9_fc_outlet, note)

write_csv(fc, out_path, na = "")
cat("Wrote", out_path, "with", nrow(fc), "rows\n")

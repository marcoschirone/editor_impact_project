# =============================================================================
# make_sample_data.R
# Generate a SYNTHETIC sample dataset that stands in for the proprietary
# Scopus / SciVal exports, so the analysis pipeline can be run and tested
# without access to the licensed data.
#
# IMPORTANT
#   * The data produced here are entirely artificial. Editor names, Scopus
#     Author IDs, and publication records are fabricated and do NOT correspond
#     to any real person, publication, or result reported in the paper.
#   * The files are written with the exact names and the single column
#     ("Scopus Author Ids") that the pipeline in 01_load_data.R consumes.
#   * The DOI column is intentionally left blank; a real list of DOIs for the
#     publication set can be added there later.
#
# USAGE
#   Rscript make_sample_data.R
#   (or) source("make_sample_data.R")
#   Writes the seven sample files into data/raw/.
# =============================================================================

suppressPackageStartupMessages(library(writexl))

set.seed(42)  # reproducible synthetic data

out_dir <- file.path("data", "raw")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Identifier pools (obviously fake ranges so they cannot be mistaken for real
# Scopus Author IDs)
# -----------------------------------------------------------------------------
n_editors    <- 100
editor_ids   <- as.character(9000000001:9000000100)   # synthetic "editors"
non_editor_ids <- as.character(8000000001:8000002000) # synthetic "other authors"

# -----------------------------------------------------------------------------
# Helper: build one pipe-separated "Scopus Author Ids" string for a publication
#   p_editor = probability that the publication includes at least one editor
# -----------------------------------------------------------------------------
make_author_string <- function(p_editor) {
  k <- sample(1:6, 1)                                    # 1-6 authors per pub
  authors <- sample(non_editor_ids, k, replace = FALSE)
  if (runif(1) < p_editor) {
    ne <- sample(1:2, 1)                                 # 1-2 editors when present
    authors <- c(sample(editor_ids, ne), authors)
  }
  paste(unique(authors), collapse = "|")
}

# -----------------------------------------------------------------------------
# Helper: build one synthetic SciVal-style publication table
# -----------------------------------------------------------------------------
make_pub_table <- function(n, p_editor) {
  data.frame(
    Title                = paste("Synthetic publication", seq_len(n)),
    Year                 = sample(2020:2024, n, replace = TRUE),
    DOI                  = "",  # placeholder: add real DOIs here later
    `Scopus Author Ids`  = vapply(seq_len(n), function(i) make_author_string(p_editor),
                                  character(1)),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# -----------------------------------------------------------------------------
# 1. Editor -> Scopus ID mapping (consumed by 01_load_data.R via scopus_id /
#    match_count). A few invalid rows are included so the filtering step in
#    01_load_data.R is exercised.
# -----------------------------------------------------------------------------
editors_csv <- data.frame(
  row_id      = seq_len(n_editors + 8),
  editor_name = c(paste("Editor", sprintf("%03d", seq_len(n_editors))),
                  paste("Unmatched Editor", 1:8)),
  full_name   = c(paste("Sample Editor", sprintf("%03d", seq_len(n_editors))),
                  paste("Sample Unmatched Editor", 1:8)),
  affiliation = "Sample University",
  scopus_id   = c(editor_ids, rep(NA_character_, 8)),       # 8 unmatched editors
  match_count = c(sample(1:4, n_editors, replace = TRUE), rep(0L, 8)),
  stringsAsFactors = FALSE
)
write.csv(editors_csv, file.path(out_dir, "scopus_author_ids.csv"),
          row.names = FALSE, na = "")

# -----------------------------------------------------------------------------
# 2. Six SciVal-style publication sets.
#    Row counts and editor-involvement probabilities are chosen only to produce
#    coherent, non-degenerate demonstration output - they are NOT calibrated to
#    the paper's reported figures.
# -----------------------------------------------------------------------------
write_xlsx(make_pub_table(1000, 0.20), file.path(out_dir, "1_Total_pub_2020-2024.xlsx"))
write_xlsx(make_pub_table( 200, 0.45), file.path(out_dir, "2_Top10_citation.xlsx"))
write_xlsx(make_pub_table(  30, 0.60), file.path(out_dir, "3_Top1_citation.xlsx"))
write_xlsx(make_pub_table( 400, 0.40), file.path(out_dir, "4_Top10_journal.xlsx"))
write_xlsx(make_pub_table( 150, 0.50), file.path(out_dir, "5_Policy_citation.xlsx"))
write_xlsx(make_pub_table(  70, 0.25), file.path(out_dir, "6_Patent_citation.xlsx"))

cat("Synthetic sample data written to", out_dir, "\n")
cat("Files:\n  scopus_author_ids.csv\n  1_Total_pub_2020-2024.xlsx\n",
    "  2_Top10_citation.xlsx\n  3_Top1_citation.xlsx\n  4_Top10_journal.xlsx\n",
    "  5_Policy_citation.xlsx\n  6_Patent_citation.xlsx\n", sep = "")

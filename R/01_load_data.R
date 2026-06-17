# =============================================================================
# 01_load_data.R
# Load and validate all data files
# =============================================================================

print_header("LOADING DATA")

# -----------------------------------------------------------------------------
# LOAD EDITOR SCOPUS IDs
# -----------------------------------------------------------------------------

print_subheader("Editor Scopus IDs")

editors_raw <- fread(paths$editor_ids)

# Filter to those with valid Scopus IDs
editors <- editors_raw[!is.na(scopus_id) & scopus_id != "" & match_count > 0]
editors[, scopus_id := as.character(scopus_id)]

# Get unique editor IDs
editor_ids <- unique(editors$scopus_id)

cat("  Total editor records:", fmt_num(nrow(editors_raw)), "\n")
cat("  With valid Scopus ID:", fmt_num(nrow(editors)), "\n")
cat("  Unique Scopus IDs:", fmt_num(length(editor_ids)), "\n")

# Update params if different
if (length(editor_ids) != params$total_unique_editors) {
  cat("  NOTE: Updating total_unique_editors from", 
      params$total_unique_editors, "to", length(editor_ids), "\n")
  params$total_unique_editors <- length(editor_ids)
}

# -----------------------------------------------------------------------------
# FUNCTION: Load SciVal export and count editors
# -----------------------------------------------------------------------------

load_scival_set <- function(filepath, label) {
  
  cat("\n  Loading:", label, "\n")
  
  # Read Excel file
  df <- as.data.table(read_excel(filepath))
  total_pubs <- nrow(df)
  
  # Extract all author IDs from publications
  all_author_ids <- c()
  pubs_by_editors <- 0
  
  for (i in 1:nrow(df)) {
    author_str <- as.character(df$`Scopus Author Ids`[i])
    if (!is.na(author_str) && author_str != "") {
      # Split by pipe separator
      ids <- trimws(unlist(strsplit(author_str, "\\|")))
      all_author_ids <- c(all_author_ids, ids)
      
      # Check if any author is an editor
      if (any(ids %in% editor_ids)) {
        pubs_by_editors <- pubs_by_editors + 1
      }
    }
  }
  
  # Unique author IDs in this set
  unique_authors <- unique(all_author_ids)
  
  # Count editors in this set
  editors_in_set <- intersect(unique_authors, editor_ids)
  n_editors <- length(editors_in_set)
  pct_editors <- round(n_editors / params$total_unique_editors * 100, 1)
  
  cat("    Publications:", fmt_num(total_pubs), "\n")
  cat("    Pubs by editors:", fmt_num(pubs_by_editors), "\n")
  cat("    Editors in set:", fmt_num(n_editors), "(", fmt_pct(pct_editors), ")\n")
  
  return(list(
    label = label,
    data = df,
    total_pubs = total_pubs,
    pubs_by_editors = pubs_by_editors,
    n_editors = n_editors,
    pct_editors = pct_editors,
    editor_ids_in_set = editors_in_set
  ))
}

# -----------------------------------------------------------------------------
# LOAD ALL SCIVAL PUBLICATION SETS
# -----------------------------------------------------------------------------

print_subheader("SciVal Publication Sets")

scival_data <- list()

scival_data$total <- load_scival_set(
  paths$scival$total, 
  analysis_labels$total
)

scival_data$top10_cite <- load_scival_set(
  paths$scival$top10_cite, 
  analysis_labels$top10_cite
)

scival_data$top1_cite <- load_scival_set(
  paths$scival$top1_cite, 
  analysis_labels$top1_cite
)

scival_data$top10_jour <- load_scival_set(
  paths$scival$top10_jour, 
  analysis_labels$top10_jour
)

scival_data$policy <- load_scival_set(
  paths$scival$policy, 
  analysis_labels$policy
)

scival_data$patent <- load_scival_set(
  paths$scival$patent, 
  analysis_labels$patent
)

# -----------------------------------------------------------------------------
# CREATE SUMMARY TABLE
# -----------------------------------------------------------------------------

print_subheader("Data Summary")

data_summary <- rbindlist(lapply(scival_data, function(x) {
  data.table(
    Analysis = x$label,
    Total_Publications = x$total_pubs,
    Pubs_by_Editors = x$pubs_by_editors,
    N_Editors = x$n_editors,
    Pct_Editors = x$pct_editors
  )
}))

print(data_summary)

# -----------------------------------------------------------------------------
# SAVE PROCESSED DATA
# -----------------------------------------------------------------------------

print_subheader("Saving processed data")

saveRDS(editor_ids, file.path(paths$processed, "editor_ids.rds"))
saveRDS(scival_data, file.path(paths$processed, "scival_data.rds"))
saveRDS(data_summary, file.path(paths$processed, "data_summary.rds"))

cat("  Saved: editor_ids.rds\n")
cat("  Saved: scival_data.rds\n")
cat("  Saved: data_summary.rds\n")

cat("\n✓ Data loading complete\n")

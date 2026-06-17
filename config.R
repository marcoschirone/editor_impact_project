# =============================================================================
# Configuration File
# Editor Impact Study - All parameters defined here
# =============================================================================

# -----------------------------------------------------------------------------
# FILE PATHS
# -----------------------------------------------------------------------------

paths <- list(
  # Input data
  editor_ids = "data/raw/scopus_author_ids.csv",
  
  scival = list(
    total      = "data/raw/1_Total_pub_2020-2024.xlsx",
    top10_cite = "data/raw/2_Top10_citation.xlsx",
    top1_cite  = "data/raw/3_Top1_citation.xlsx",
    top10_jour = "data/raw/4_Top10_journal.xlsx",
    policy     = "data/raw/5_Policy_citation.xlsx",
    patent     = "data/raw/6_Patent_citation.xlsx"
  ),
  
  # Output
  tables  = "output/tables",
  figures = "output/figures",
  processed = "data/processed"
)

# -----------------------------------------------------------------------------
# STUDY PARAMETERS
# -----------------------------------------------------------------------------

params <- list(
  # Time window
  year_start = 2020,
  year_end = 2024,
  

  # Total unique editors (from Scopus ID matching)
  total_unique_editors = 1822,
  
  # Expected rates (for comparison)
  expected_top10_cite = 0.10,   # 10% expected if random
  expected_top1_cite  = 0.01,   # 1% expected if random
  expected_top10_jour = 0.10,   # 10% expected if random
  
  # Significance level
  alpha = 0.05
)

# -----------------------------------------------------------------------------
# ANALYSIS LABELS
# -----------------------------------------------------------------------------

analysis_labels <- list(
  total      = "1. Total Publications (Baseline)",
  top10_cite = "2. Top 10% Citation Percentile",
  top1_cite  = "3. Top 1% Citation Percentile",
  top10_jour = "4. Top 10% Journal Percentile",
  policy     = "5. Policy Citations",
  patent     = "6. Patent Citations"
)

# -----------------------------------------------------------------------------
# VISUALIZATION SETTINGS
# -----------------------------------------------------------------------------

viz <- list(
  # Colors
  colors = list(
    primary   = "#1f77b4",
    secondary = "#ff7f0e",
    success   = "#2ca02c",
    danger    = "#d62728",
    purple    = "#9467bd",
    gray      = "#d3d3d3",
    expected  = "#e74c3c"
  ),
  
  # Plot dimensions
  width  = 10,
  height = 6,
  dpi    = 300,
  
  # Theme
  base_size = 12
)

# -----------------------------------------------------------------------------
# REPORTING
# -----------------------------------------------------------------------------

reporting <- list(
  # Decimal places
  decimals_pct = 1,
  decimals_ratio = 2,
  
  # Number formatting
  big_mark = ","
)

# -----------------------------------------------------------------------------
# PRINT CONFIGURATION SUMMARY
# -----------------------------------------------------------------------------

print_config <- function() {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║  EDITOR IMPACT STUDY - CONFIGURATION                         ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")
  
  cat("Study Parameters:\n")
  cat("  Time window:", params$year_start, "-", params$year_end, "\n")
  cat("  Total unique editors:", format(params$total_unique_editors, big.mark = ","), "\n")
  cat("  Significance level: α =", params$alpha, "\n\n")
  
  cat("Expected Rates (if random):\n")
  cat("  Top 10% cited:", params$expected_top10_cite * 100, "%\n")
  cat("  Top 1% cited:", params$expected_top1_cite * 100, "%\n")
  cat("  Top 10% journals:", params$expected_top10_jour * 100, "%\n\n")
  
  cat("Output directories:\n")
  cat("  Tables:", paths$tables, "\n")
  cat("  Figures:", paths$figures, "\n")
}

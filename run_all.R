# =============================================================================
# run_all.R
# Master script - runs the entire analysis pipeline
# =============================================================================
#
# USAGE:
#   1. Set working directory to project folder
#   2. Ensure data files are in data/raw/
#   3. Run: source("run_all.R")
#
# =============================================================================

# Clear environment
rm(list = ls())

# Record start time
start_time <- Sys.time()

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                                                               ║\n")
cat("║   EDITORIAL BOARD MEMBERSHIP AND CITATION ELITE STATUS        ║\n")
cat("║   Analysis Pipeline                                           ║\n")
cat("║                                                               ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("Started:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")

# -----------------------------------------------------------------------------
# LOAD CONFIGURATION
# -----------------------------------------------------------------------------

cat("\n[1/8] Loading configuration...\n")
source("config.R")
print_config()

# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

cat("\n[2/8] Setting up environment...\n")
source("R/00_setup.R")

dir.create(paths$tables, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$figures, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$processed, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# LOAD DATA
# -----------------------------------------------------------------------------

cat("\n[3/8] Loading and processing data...\n")
source("R/01_load_data.R")

# -----------------------------------------------------------------------------
# RUN ANALYSES
# -----------------------------------------------------------------------------

cat("\n[4/8] Running Analysis 1: Top 10% Citation...\n")
source("R/03_analysis_top10_cite.R")

cat("\n[5/8] Running Analysis 2: Top 1% Citation...\n")
source("R/04_analysis_top1_cite.R")

cat("\n[6/8] Running Analysis 3: Policy Citations...\n")
source("R/05_analysis_policy.R")

cat("\n[7/8] Running Analysis 4: Patent Citations...\n")
source("R/06_analysis_patent.R")

# -----------------------------------------------------------------------------
# CREATE OUTPUTS
# -----------------------------------------------------------------------------

cat("\n[8/8] Creating summary tables and visualizations...\n")
source("R/07_summary_tables.R")
source("R/08_visualizations.R")

# -----------------------------------------------------------------------------
# FINAL SUMMARY
# -----------------------------------------------------------------------------

end_time <- Sys.time()
duration <- round(difftime(end_time, start_time, units = "secs"), 1)

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  ANALYSIS COMPLETE                                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("KEY FINDINGS:\n")
cat("─────────────────────────────────────────────────────────────────\n")
cat("  Total publications (2020-2024):", fmt_num(scival_data$total$total_pubs), "\n")
cat("  Unique editors:", fmt_num(params$total_unique_editors), "\n")
cat("\n")
cat("  RQ1 - Citation Elite:\n")
cat("    • Top 10% cited:", fmt_pct(results_top10_cite$pct_pubs),
    "(", results_top10_cite$ratio, "× expected)\n")
cat("    • Top 1% cited:", fmt_pct(results_top1_cite$pct_pubs),
    "(", results_top1_cite$ratio, "× expected)\n")
cat("\n")
cat("  RQ2 - Policy Impact:\n")
cat("    • Policy citations:", fmt_pct(results_policy$pct_pubs), "\n")
cat("\n")
cat("  RQ3 - Patent Impact:\n")
cat("    • Patent citations:", fmt_pct(results_patent$pct_pubs), "\n")
cat("─────────────────────────────────────────────────────────────────\n")
cat("\n")

cat("OUTPUT FILES:\n")
cat("  Tables:", list.files(paths$tables), "\n")
cat("  Figures:", list.files(paths$figures), "\n")
cat("\n")

cat("Duration:", duration, "seconds\n")
cat("Completed:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")

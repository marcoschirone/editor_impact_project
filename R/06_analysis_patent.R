# =============================================================================
# 07_analysis_patent.R
# Analysis 6: Patent Citations (RQ4)
# =============================================================================

print_header("ANALYSIS 6: PATENT CITATIONS (RQ4)")

# Get data
d <- scival_data$patent
baseline <- scival_data$total

# -----------------------------------------------------------------------------
# CALCULATE METRICS
# -----------------------------------------------------------------------------

print_subheader("Results")

# Publication metrics
pct_pubs <- round(d$total_pubs / baseline$total_pubs * 100, 2)

cat("Publications:\n")
cat("  Pubs with patent citations:", fmt_num(d$total_pubs), "\n")
cat("  % of all editor pubs:", fmt_pct(pct_pubs), "\n")

cat("\nEditors:\n")
cat("  Editors with ≥1 patent-cited pub:", fmt_num(d$n_editors), "\n")
cat("  % of all editors:", fmt_pct(d$pct_editors), "\n")

cat("\nInterpretation:\n")
cat("  ", fmt_pct(pct_pubs), "of editor publications are cited in patents.\n")
cat("  This indicates technological and commercial applications.\n")

# -----------------------------------------------------------------------------
# CONFIDENCE INTERVAL
# -----------------------------------------------------------------------------

print_subheader("Confidence Interval")

ci_result <- prop.test(d$total_pubs, baseline$total_pubs)

cat("95% CI for patent citation rate:\n")
cat("  [", round(ci_result$conf.int[1] * 100, 2), "%, ",
    round(ci_result$conf.int[2] * 100, 2), "%]\n")

# -----------------------------------------------------------------------------
# STORE RESULTS
# -----------------------------------------------------------------------------

results_patent <- list(
  label = d$label,
  total_pubs = d$total_pubs,
  pct_pubs = pct_pubs,
  n_editors = d$n_editors,
  pct_editors = d$pct_editors,
  ci_lower = ci_result$conf.int[1] * 100,
  ci_upper = ci_result$conf.int[2] * 100
)

cat("\n✓ Analysis 6 complete\n")

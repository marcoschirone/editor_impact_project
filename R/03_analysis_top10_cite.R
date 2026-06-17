# =============================================================================
# 03_analysis_top10_cite.R
# Analysis 2: Top 10% Citation Percentile (RQ1)
# =============================================================================

print_header("ANALYSIS 2: TOP 10% CITATION PERCENTILE (RQ1)")

# Get data
d <- scival_data$top10_cite
baseline <- scival_data$total

# -----------------------------------------------------------------------------
# CALCULATE METRICS
# -----------------------------------------------------------------------------

print_subheader("Results")

# Publication metrics
pct_pubs <- round(d$total_pubs / baseline$total_pubs * 100, 2)
ratio_vs_expected <- round(pct_pubs / (params$expected_top10_cite * 100), 2)

cat("Publications:\n")
cat("  Total in top 10% cited:", fmt_num(d$total_pubs), "\n")
cat("  % of all editor pubs:", fmt_pct(pct_pubs), "\n")
cat("  Expected (random):", fmt_pct(params$expected_top10_cite * 100), "\n")
cat("  Ratio vs expected:", ratio_vs_expected, "×\n")

cat("\nEditors:\n")
cat("  Editors with ≥1 top 10% pub:", fmt_num(d$n_editors), "\n")
cat("  % of all editors:", fmt_pct(d$pct_editors), "\n")

# -----------------------------------------------------------------------------
# STATISTICAL TEST
# -----------------------------------------------------------------------------

print_subheader("Statistical Test")

cat("H0: Publication rate in top 10% = 10% (random)\n")
cat("H1: Publication rate in top 10% > 10%\n\n")

prop_test <- prop.test(
  x = d$total_pubs,
  n = baseline$total_pubs,
  p = params$expected_top10_cite,
  alternative = "greater"
)

cat("One-sample proportion test:\n")
cat("  Observed proportion:", round(prop_test$estimate, 4), "\n")
cat("  χ² =", round(prop_test$statistic, 2), "\n")
cat("  p-value:", format.pval(prop_test$p.value, digits = 3), "\n")

if (prop_test$p.value < 0.001) {
  cat("\n>>> CONCLUSION: Significantly ABOVE expected (p < 0.001)\n")
}

# -----------------------------------------------------------------------------
# STORE RESULTS
# -----------------------------------------------------------------------------

results_top10_cite <- list(
  label = d$label,
  total_pubs = d$total_pubs,
  pct_pubs = pct_pubs,
  expected_pct = params$expected_top10_cite * 100,
  ratio = ratio_vs_expected,
  n_editors = d$n_editors,
  pct_editors = d$pct_editors,
  test = prop_test
)

cat("\n✓ Analysis 2 complete\n")

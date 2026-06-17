# =============================================================================
# 06_analysis_policy.R
# Analysis 5: Policy Citations (RQ3)
# =============================================================================

print_header("ANALYSIS 5: POLICY CITATIONS (RQ3)")

# Get data
d <- scival_data$policy
baseline <- scival_data$total

# -----------------------------------------------------------------------------
# CALCULATE METRICS
# -----------------------------------------------------------------------------

print_subheader("Results")

# Publication metrics
pct_pubs <- round(d$total_pubs / baseline$total_pubs * 100, 2)

cat("Publications:\n")
cat("  Pubs with policy citations:", fmt_num(d$total_pubs), "\n")
cat("  % of all editor pubs:", fmt_pct(pct_pubs), "\n")

cat("\nEditors:\n")
cat("  Editors with ≥1 policy-cited pub:", fmt_num(d$n_editors), "\n")
cat("  % of all editors:", fmt_pct(d$pct_editors), "\n")

cat("\nInterpretation:\n")
cat("  ", fmt_pct(pct_pubs), "of editor publications are cited in policy documents.\n")
cat("  This indicates substantial real-world impact of sustainability research.\n")

# -----------------------------------------------------------------------------
# CONFIDENCE INTERVAL
# -----------------------------------------------------------------------------

print_subheader("Confidence Interval")

ci_result <- prop.test(d$total_pubs, baseline$total_pubs)

cat("95% CI for policy citation rate:\n")
cat("  [", round(ci_result$conf.int[1] * 100, 2), "%, ",
    round(ci_result$conf.int[2] * 100, 2), "%]\n")

# -----------------------------------------------------------------------------
# STORE RESULTS
# -----------------------------------------------------------------------------

results_policy <- list(
  label = d$label,
  total_pubs = d$total_pubs,
  pct_pubs = pct_pubs,
  n_editors = d$n_editors,
  pct_editors = d$pct_editors,
  ci_lower = ci_result$conf.int[1] * 100,
  ci_upper = ci_result$conf.int[2] * 100
)

cat("\n✓ Analysis 5 complete\n")

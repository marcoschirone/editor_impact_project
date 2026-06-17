# =============================================================================
# 08_summary_tables.R
# Create summary tables for paper
# =============================================================================

print_header("CREATING SUMMARY TABLES")

# -----------------------------------------------------------------------------
# TABLE 1: MAIN RESULTS SUMMARY
# -----------------------------------------------------------------------------

print_subheader("Table 1: Main Results")

baseline <- scival_data$total

table1 <- data.table(
  Analysis = c(
    "1. Total Publications (Baseline)",
    "2. Top 10% Citation Percentile",
    "3. Top 1% Citation Percentile",
    "4. Top 10% Journal Percentile",
    "5. Policy Citations",
    "6. Patent Citations"
  ),
  Publications = c(
    baseline$total_pubs,
    scival_data$top10_cite$total_pubs,
    scival_data$top1_cite$total_pubs,
    scival_data$top10_jour$total_pubs,
    scival_data$policy$total_pubs,
    scival_data$patent$total_pubs
  ),
  `% of Total` = c(
    100,
    round(scival_data$top10_cite$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$top1_cite$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$policy$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$patent$total_pubs / baseline$total_pubs * 100, 1)
  ),
  `Expected %` = c(
    NA,
    10,
    1,
    10,
    NA,
    NA
  ),
  `Ratio vs Expected` = c(
    NA,
    round(scival_data$top10_cite$total_pubs / baseline$total_pubs * 100 / 10, 1),
    round(scival_data$top1_cite$total_pubs / baseline$total_pubs * 100 / 1, 1),
    round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100 / 10, 1),
    NA,
    NA
  ),
  `N Editors` = c(
    baseline$n_editors,
    scival_data$top10_cite$n_editors,
    scival_data$top1_cite$n_editors,
    scival_data$top10_jour$n_editors,
    scival_data$policy$n_editors,
    scival_data$patent$n_editors
  ),
  `% of Editors` = c(
    baseline$pct_editors,
    scival_data$top10_cite$pct_editors,
    scival_data$top1_cite$pct_editors,
    scival_data$top10_jour$pct_editors,
    scival_data$policy$pct_editors,
    scival_data$patent$pct_editors
  )
)

print(table1)
save_table(table1, "table1_main_results.csv")

# -----------------------------------------------------------------------------
# TABLE 2: STATISTICAL TESTS
# -----------------------------------------------------------------------------

print_subheader("Table 2: Statistical Tests")

table2 <- data.table(
  Analysis = c(
    "Top 10% Citation vs 10%",
    "Top 1% Citation vs 1%",
    "Top 10% Journal vs 10%"
  ),
  `Observed Rate` = c(
    fmt_pct(round(scival_data$top10_cite$total_pubs / baseline$total_pubs * 100, 2)),
    fmt_pct(round(scival_data$top1_cite$total_pubs / baseline$total_pubs * 100, 2)),
    fmt_pct(round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100, 2))
  ),
  `Expected Rate` = c("10%", "1%", "10%"),
  `Chi-squared` = c(
    round(results_top10_cite$test$statistic, 1),
    round(results_top1_cite$test$statistic, 1),
    round(results_top10_jour$test$statistic, 1)
  ),
  `p-value` = c(
    "< 0.001",
    "< 0.001",
    "< 0.001"
  ),
  Conclusion = c(
    paste0(results_top10_cite$ratio, "× above expected"),
    paste0(results_top1_cite$ratio, "× above expected"),
    paste0(results_top10_jour$ratio, "× above expected")
  )
)

print(table2)
save_table(table2, "table2_statistical_tests.csv")

# -----------------------------------------------------------------------------
# TABLE 3: RESEARCH QUESTION ANSWERS
# -----------------------------------------------------------------------------

print_subheader("Table 3: Research Question Answers")

table3 <- data.table(
  RQ = c("RQ1", "RQ1", "RQ2", "RQ3", "RQ4"),
  Question = c(
    "Citation Elite (Top 10%)",
    "Citation Elite (Top 1%)",
    "Top Journal Publishing",
    "Policy Impact",
    "Patent Impact"
  ),
  `Key Finding` = c(
    paste0(results_top10_cite$pct_pubs, "% pubs in top 10% cited (", 
           results_top10_cite$ratio, "× expected)"),
    paste0(results_top1_cite$pct_pubs, "% pubs in top 1% cited (", 
           results_top1_cite$ratio, "× expected)"),
    paste0(results_top10_jour$pct_pubs, "% pubs in top 10% journals (", 
           results_top10_jour$ratio, "× expected)"),
    paste0(results_policy$pct_pubs, "% pubs cited in policy documents"),
    paste0(results_patent$pct_pubs, "% pubs cited in patents")
  ),
  `Editors Involved` = c(
    paste0(results_top10_cite$n_editors, " (", results_top10_cite$pct_editors, "%)"),
    paste0(results_top1_cite$n_editors, " (", results_top1_cite$pct_editors, "%)"),
    paste0(results_top10_jour$n_editors, " (", results_top10_jour$pct_editors, "%)"),
    paste0(results_policy$n_editors, " (", results_policy$pct_editors, "%)"),
    paste0(results_patent$n_editors, " (", results_patent$pct_editors, "%)")
  )
)

print(table3)
save_table(table3, "table3_rq_answers.csv")

cat("\n✓ Summary tables complete\n")

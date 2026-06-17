# =============================================================================
# 09_visualizations.R
# Create all figures for paper
# =============================================================================

print_header("CREATING VISUALIZATIONS")

baseline <- scival_data$total

# -----------------------------------------------------------------------------
# FIGURE 1: OVERVIEW - All analyses comparison
# -----------------------------------------------------------------------------

print_subheader("Figure 1: Overview")

fig1_data <- data.table(
  Category = c("Top 10% Cited", "Top 1% Cited", "Top 10% Journal",
               "Policy Cited", "Patent Cited"),
  Percentage = c(
    round(scival_data$top10_cite$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$top1_cite$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$policy$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$patent$total_pubs / baseline$total_pubs * 100, 1)
  ),
  Expected = c(10, 1, 10, NA, NA),
  Type = c("Citation", "Citation", "Journal", "Impact", "Impact")
)

fig1 <- ggplot(fig1_data, aes(x = reorder(Category, -Percentage), y = Percentage, fill = Type)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(Percentage, "%")), vjust = -0.3, size = 4, fontface = "bold") +
  geom_point(aes(y = Expected), color = viz$colors$danger, size = 4, shape = 18, na.rm = TRUE) +
  scale_fill_manual(values = c(
    "Citation" = viz$colors$primary,
    "Journal" = viz$colors$success,
    "Impact" = viz$colors$purple
  )) +
  labs(
    title = "Editorial Board Member Publication Impact",
    subtitle = "Red diamonds indicate expected rates under random publishing",
    x = "",
    y = "% of Publications",
    fill = "Category"
  ) +
  theme_minimal(base_size = viz$base_size) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 15, hjust = 1)
  ) +
  ylim(0, max(fig1_data$Percentage) * 1.15)

save_plot(fig1, "fig1_overview.png")

# -----------------------------------------------------------------------------
# FIGURE 2: Observed vs Expected (Citation & Journal)
# -----------------------------------------------------------------------------

print_subheader("Figure 2: Observed vs Expected")

fig2_data <- data.table(
  Metric = rep(c("Top 10% Cited", "Top 1% Cited", "Top 10% Journal"), each = 2),
  Type = rep(c("Observed", "Expected"), 3),
  Rate = c(
    round(scival_data$top10_cite$total_pubs / baseline$total_pubs * 100, 1), 10,
    round(scival_data$top1_cite$total_pubs / baseline$total_pubs * 100, 2), 1,
    round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100, 1), 10
  )
)

fig2 <- ggplot(fig2_data, aes(x = Metric, y = Rate, fill = Type)) +
  geom_col(position = "dodge", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(Rate, "%")),
            position = position_dodge(width = 0.7), vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c("Observed" = viz$colors$primary, "Expected" = viz$colors$gray)) +
  labs(
    title = "Observed vs Expected Publication Rates",
    subtitle = "Editorial board members significantly outperform random expectation",
    x = "",
    y = "% of Publications",
    fill = ""
  ) +
  theme_minimal(base_size = viz$base_size) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  ) +
  ylim(0, max(fig2_data$Rate) * 1.15)

save_plot(fig2, "fig2_observed_vs_expected.png")

# -----------------------------------------------------------------------------
# FIGURE 3: Editor Participation by Category
# -----------------------------------------------------------------------------

print_subheader("Figure 3: Editor Participation")

fig3_data <- data.table(
  Category = c("Any Publication", "Top 10% Cited", "Top 1% Cited",
               "Top 10% Journal", "Policy Cited", "Patent Cited"),
  Editors = c(
    baseline$n_editors,
    scival_data$top10_cite$n_editors,
    scival_data$top1_cite$n_editors,
    scival_data$top10_jour$n_editors,
    scival_data$policy$n_editors,
    scival_data$patent$n_editors
  ),
  Percentage = c(
    baseline$pct_editors,
    scival_data$top10_cite$pct_editors,
    scival_data$top1_cite$pct_editors,
    scival_data$top10_jour$pct_editors,
    scival_data$policy$pct_editors,
    scival_data$patent$pct_editors
  )
)

fig3 <- ggplot(fig3_data, aes(x = reorder(Category, Percentage), y = Percentage)) +
  geom_col(fill = viz$colors$primary, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(Percentage, "%")), hjust = -0.1, size = 4) +
  coord_flip() +
  labs(
    title = "Editor Participation Across Impact Categories",
    subtitle = paste0("Total unique editors: ", fmt_num(params$total_unique_editors)),
    x = "",
    y = "% of Editors"
  ) +
  theme_minimal(base_size = viz$base_size) +
  theme(plot.title = element_text(face = "bold", size = 14)) +
  scale_y_continuous(limits = c(0, max(fig3_data$Percentage) * 1.15), expand = c(0, 0))

save_plot(fig3, "fig3_editor_participation.png")

# -----------------------------------------------------------------------------
# FIGURE 4: Top 10% Journal (Pie Chart - Key Finding)
# -----------------------------------------------------------------------------

print_subheader("Figure 4: Top Journal Distribution")

pct_top_jour <- round(scival_data$top10_jour$total_pubs / baseline$total_pubs * 100, 1)

fig4_data <- data.table(
  Category = c("Top 10% Journals", "Other Journals"),
  Count = c(scival_data$top10_jour$total_pubs,
            baseline$total_pubs - scival_data$top10_jour$total_pubs),
  Percentage = c(pct_top_jour, 100 - pct_top_jour)
)

fig4 <- ggplot(fig4_data, aes(x = "", y = Count, fill = Category)) +
  geom_col(width = 1, alpha = 0.8) +
  coord_polar("y", start = 0) +
  geom_text(aes(label = paste0(round(Percentage, 1), "%")),
            position = position_stack(vjust = 0.5),
            size = 6, color = "white", fontface = "bold") +
  scale_fill_manual(values = c("Top 10% Journals" = viz$colors$success,
                               "Other Journals" = viz$colors$gray)) +
  labs(
    title = "Distribution of Editor Publications by Journal Rank",
    subtitle = paste0(pct_top_jour, "% in top 10% journals (expected: 10%)"),
    fill = ""
  ) +
  theme_void(base_size = viz$base_size) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

save_plot(fig4, "fig4_top_journal_pie.png", width = 8, height = 8)

# -----------------------------------------------------------------------------
# FIGURE 5: Societal Impact (Policy + Patent)
# -----------------------------------------------------------------------------

print_subheader("Figure 5: Societal Impact")

fig5_data <- data.table(
  Type = c("Policy Citations", "Patent Citations"),
  Publications = c(scival_data$policy$total_pubs, scival_data$patent$total_pubs),
  Percentage = c(
    round(scival_data$policy$total_pubs / baseline$total_pubs * 100, 1),
    round(scival_data$patent$total_pubs / baseline$total_pubs * 100, 1)
  ),
  Editors = c(scival_data$policy$n_editors, scival_data$patent$n_editors),
  Editor_Pct = c(scival_data$policy$pct_editors, scival_data$patent$pct_editors)
)

fig5 <- ggplot(fig5_data, aes(x = Type, y = Percentage, fill = Type)) +
  geom_col(alpha = 0.8, width = 0.6) +
  geom_text(aes(label = paste0(Percentage, "%\n(",
                               format(Publications, big.mark = ","), " pubs)")),
            vjust = -0.2, size = 4) +
  scale_fill_manual(values = c("Policy Citations" = viz$colors$purple,
                               "Patent Citations" = viz$colors$secondary)) +
  labs(
    title = "Societal Impact of Editor Publications",
    subtitle = "Publications cited in policy documents and patents",
    x = "",
    y = "% of Publications"
  ) +
  theme_minimal(base_size = viz$base_size) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none"
  ) +
  ylim(0, max(fig5_data$Percentage) * 1.3)

save_plot(fig5, "fig5_societal_impact.png")

cat("\n✓ All visualizations complete\n")

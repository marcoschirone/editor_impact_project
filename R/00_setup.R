# =============================================================================
# 00_setup.R
# Load packages and set global options
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED PACKAGES
# -----------------------------------------------------------------------------

required_packages <- c(

"data.table",  # Fast data manipulation
"readxl",      # Read Excel files
"ggplot2",     # Visualization
"scales",      # Number formatting
"writexl"      # Write Excel files
)

# Install missing packages
install_if_missing <- function(packages) {
missing <- packages[!packages %in% installed.packages()[, "Package"]]
if (length(missing) > 0) {
  cat("Installing missing packages:", paste(missing, collapse = ", "), "\n")
  install.packages(missing, quiet = TRUE)
}
}

install_if_missing(required_packages)

# Load packages
suppressPackageStartupMessages({
library(data.table)
library(readxl)
library(ggplot2)
library(scales)
library(writexl)
})

# -----------------------------------------------------------------------------
# GLOBAL OPTIONS
# -----------------------------------------------------------------------------

# Data.table options
options(datatable.print.class = FALSE)
options(datatable.print.keys = FALSE)

# Scientific notation threshold
options(scipen = 999)

# ggplot2 theme
theme_set(theme_minimal(base_size = 12))

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

#' Format number with commas
fmt_num <- function(x, digits = 0) {
format(round(x, digits), big.mark = ",", nsmall = digits)
}
  
#' Format percentage
fmt_pct <- function(x, digits = 1) {
paste0(round(x, digits), "%")
}

#' Print section header
print_header <- function(title) {
cat("\n")
cat(strrep("=", 60), "\n")
cat(title, "\n")
cat(strrep("=", 60), "\n")
}

#' Print subsection
print_subheader <- function(title) {
cat("\n", title, "\n")
cat(strrep("-", 40), "\n")
}

#' Save table to CSV
save_table <- function(dt, filename) {
filepath <- file.path(paths$tables, filename)
fwrite(dt, filepath)
cat("  Saved:", filepath, "\n")
}

#' Save plot to PNG
save_plot <- function(p, filename, width = viz$width, height = viz$height) {
filepath <- file.path(paths$figures, filename)
ggsave(filepath, p, width = width, height = height, dpi = viz$dpi)
cat("  Saved:", filepath, "\n")
}

# -----------------------------------------------------------------------------
# CONFIRMATION
# -----------------------------------------------------------------------------

cat("✓ Setup complete\n")
cat("  Packages loaded:", paste(required_packages, collapse = ", "), "\n")

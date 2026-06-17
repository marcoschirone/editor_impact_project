#!/usr/bin/env Rscript
# Check if authors have published in target sustainability journals
# Uses Scopus Search API with AU-ID and ISSN filters

library(httr2)
library(jsonlite)
library(data.table)
library(cli)

# Configuration
config <- list(
  search_url = "https://api.elsevier.com/content/search/scopus",
  input_file = "scopus_author_ids.csv",
  output_file = "authors_journal_publications.csv",
  throttle_delay = 0.25  # seconds between requests
)

# Target journals - 29 sustainability journals (ISSNs)
TARGET_ISSNS <- c(
  "0959-6526", "1879-1786",  # Journal of Cleaner Production
  "0960-1481", "1879-0682",  # Renewable Energy
  "2168-0485",               # ACS Sustainable Chemistry & Engineering
  "1463-9262", "1463-9270",  # Green Chemistry
  "1864-5631", "1864-564X",  # ChemSusChem
  "2210-6707", "2210-6715",  # Sustainable Cities and Society
  "1949-3029", "1949-3037",  # IEEE Transactions on Sustainable Energy
  "1364-0321", "1879-0690",  # Renewable and Sustainable Energy Reviews
  "1088-1980", "1530-9290",  # Journal of Industrial Ecology
  "0966-9582", "1747-7646",  # Journal of Sustainable Tourism
  "0968-0802", "1099-1719",  # Sustainable Development
  "1862-4065", "1862-4057",  # Sustainability Science
  "1774-0746", "1773-0155",  # Agronomy for Sustainable Development
  "1467-6370", "1758-6739",  # Int J Sustainability in Higher Education
  "2352-5509",               # Sustainable Production and Consumption
  "2288-6206", "2198-0810",  # Int J Precision Engineering Manufacturing-Green Tech
  "2398-9629",               # Nature Sustainability
  "2214-9929", "2214-9937",  # Sustainable Materials and Technologies
  "1387-585X", "1573-2975",  # Environment, Development and Sustainability
  "1350-4509", "1745-2627",  # Int J Sustainable Development & World Ecology
  "1708-3087",               # Ecology and Society
  "0959-3780", "1872-9495",  # Global Environmental Change
  "1877-3435", "1877-3443",  # Current Opinion in Environmental Sustainability
  "0921-8009", "1873-6106",  # Ecological Economics
  "2210-4224", "2210-4232",  # Environmental Innovation and Societal Transitions
  "0305-750X", "1873-5991",  # World Development
  "2589-8116",               # Earth System Governance
  "1748-9326",               # Environmental Research Letters
  "1543-5938", "1545-2050"   # Annual Review of Environment and Resources
)

# Build ISSN query part
ISSN_QUERY <- paste0("(", paste(paste0("ISSN(", TARGET_ISSNS, ")"), collapse = " OR "), ")")

# Check if author published in target journals
check_author_publications <- function(scopus_id, api_key) {
  if (is.na(scopus_id) || scopus_id == "") {
    return(list(pub_count = NA, journals = NA, error = "No Scopus ID"))
  }

  # Query: Author ID AND (any of the target ISSNs)
  query <- paste0("AU-ID(", scopus_id, ") AND ", ISSN_QUERY)

  tryCatch({
    resp <- request(config$search_url) |>
      req_headers(
        "X-ELS-APIKey" = api_key,
        "Accept" = "application/json"
      ) |>
      req_url_query(query = query, count = 200) |>
      req_retry(max_tries = 3, backoff = ~2) |>
      req_perform()

    data <- fromJSON(resp_body_string(resp))
    results <- data$`search-results`
    total <- as.integer(results$`opensearch:totalResults`)

    if (total == 0) {
      return(list(pub_count = 0, journals = "", error = NA))
    }

    entries <- results$entry

    # Get unique journal names
    if (is.data.frame(entries)) {
      journals <- unique(entries$`prism:publicationName`)
    } else if (is.list(entries)) {
      journals <- unique(sapply(entries, function(e) e$`prism:publicationName`))
    } else {
      journals <- ""
    }

    journals_str <- paste(journals, collapse = "; ")

    list(pub_count = total, journals = journals_str, error = NA)

  }, error = function(e) {
    list(pub_count = NA, journals = NA, error = as.character(e$message))
  })
}

# Main function
main <- function() {
  cli_h1("Author Publication Checker")

  api_key <- Sys.getenv("SCOPUS_API_KEY")
  if (api_key == "") {
    cli_abort("SCOPUS_API_KEY environment variable not set")
  }
  cli_alert_success("API key found")

  # Load author data
  cli_alert_info("Loading author data...")
  authors <- fread(config$input_file)

  # Filter to authors with Scopus IDs
  authors_with_id <- authors[!is.na(scopus_id) & scopus_id != ""]
  cli_alert_success("Loaded {nrow(authors_with_id)} authors with Scopus IDs")

  # Check for existing output (resume capability)
  start_idx <- 1
  if (file.exists(config$output_file)) {
    existing <- fread(config$output_file)
    start_idx <- nrow(existing) + 1
    cli_alert_info("Resuming from row {start_idx} ({nrow(existing)} already processed)")
  } else {
    # Initialize output file
    fwrite(data.table(
      row_id = integer(),
      editor_name = character(),
      full_name = character(),
      scopus_id = character(),
      pub_count_in_target_journals = integer(),
      journals_published_in = character(),
      error = character()
    ), config$output_file)
  }

  if (start_idx > nrow(authors_with_id)) {
    cli_alert_success("All authors already processed!")
    return(invisible())
  }

  # Process authors
  cli_h2("Checking Publications in 29 Sustainability Journals")

  pb <- cli_progress_bar("Checking authors", total = nrow(authors_with_id) - start_idx + 1)

  for (i in start_idx:nrow(authors_with_id)) {
    author <- authors_with_id[i]

    result <- check_author_publications(author$scopus_id, api_key)

    # Write result immediately
    row <- data.table(
      row_id = author$row_id,
      editor_name = author$editor_name,
      full_name = author$full_name,
      scopus_id = author$scopus_id,
      pub_count_in_target_journals = result$pub_count,
      journals_published_in = result$journals,
      error = result$error
    )
    fwrite(row, config$output_file, append = TRUE)

    cli_progress_update(id = pb)

    # Throttle requests
    Sys.sleep(config$throttle_delay)
  }

  cli_progress_done(id = pb)

  # Summary
  results <- fread(config$output_file)
  has_pubs <- sum(results$pub_count_in_target_journals > 0, na.rm = TRUE)
  no_pubs <- sum(results$pub_count_in_target_journals == 0, na.rm = TRUE)
  errors <- sum(!is.na(results$error))

  cli_h2("Summary")
  cli_alert_success("Published in target journals: {has_pubs} authors")
  cli_alert_warning("No publications in target journals: {no_pubs} authors")
  if (errors > 0) cli_alert_danger("Errors: {errors} authors")
  cli_alert_success("Results saved to {.file {config$output_file}}")
}

# Run
main()

#!/usr/bin/env Rscript
# Scopus Author ID Finder
# Searches for Scopus Author IDs based on name and affiliation

library(httr2)
library(jsonlite)
library(data.table)
library(readxl)
library(cli)

# Configuration
config <- list(
  author_search_url = "https://api.elsevier.com/content/search/author",
  input_file = "Dataset_Editorial_Boards_All.xlsx",
  output_file = "scopus_author_ids.csv",
  batch_size = 200,
  throttle_delay = 0.2  # seconds between requests
)

# Validate API key
validate_config <- function(cfg) {
  api_key <- Sys.getenv("SCOPUS_API_KEY")
  if (api_key == "") {
    cli_abort("SCOPUS_API_KEY environment variable not set")
  }
  cli_alert_success("API key found")
}

# Parse author name into surname and given name
parse_name <- function(name) {
  if (is.na(name) || name == "") {
    return(list(surname = NA, given = NA))
  }

  # Handle "Surname, Given" format
  if (grepl(",", name)) {
    parts <- trimws(strsplit(name, ",")[[1]])
    surname <- parts[1]
    given <- if (length(parts) > 1) parts[2] else NA
  } else {
    # Handle "Given Surname" format
    parts <- trimws(strsplit(name, " ")[[1]])
    surname <- parts[length(parts)]
    given <- if (length(parts) > 1) paste(parts[-length(parts)], collapse = " ") else NA
  }

  list(surname = surname, given = given)
}

# Search for author in Scopus
search_author <- function(name, affiliation = NA, api_key) {
  parsed <- parse_name(name)

  if (is.na(parsed$surname)) {
    return(list(scopus_id = NA, match_count = 0, error = "Invalid name"))
  }

  # Build query
  query_parts <- c(paste0("AUTHLASTNAME(", parsed$surname, ")"))

  if (!is.na(parsed$given) && nchar(parsed$given) > 0) {
    # Use first name or initial
    first_name <- strsplit(parsed$given, " ")[[1]][1]
    query_parts <- c(query_parts, paste0("AUTHFIRST(", first_name, ")"))
  }

  if (!is.na(affiliation) && nchar(affiliation) > 0) {
    # Clean affiliation for query
    affil_clean <- gsub("[^a-zA-Z0-9 ]", "", affiliation)
    affil_words <- strsplit(affil_clean, " ")[[1]]
    # Use first 2-3 significant words
    affil_words <- affil_words[nchar(affil_words) > 3][1:min(2, length(affil_words))]
    if (length(affil_words) > 0 && !is.na(affil_words[1])) {
      query_parts <- c(query_parts, paste0("AFFIL(", paste(affil_words, collapse = " "), ")"))
    }
  }

  query <- paste(query_parts, collapse = " AND ")

  tryCatch({
    resp <- request(config$author_search_url) |>
      req_headers(
        "X-ELS-APIKey" = api_key,
        "Accept" = "application/json"
      ) |>
      req_url_query(query = query, count = 5) |>
      req_retry(max_tries = 3, backoff = ~2) |>
      req_perform()

    data <- fromJSON(resp_body_string(resp))
    results <- data$`search-results`
    total <- as.integer(results$`opensearch:totalResults`)

    if (total == 0) {
      return(list(scopus_id = NA, match_count = 0, error = NA))
    }

    entries <- results$entry

    # Get first result's author ID
    if (is.data.frame(entries)) {
      scopus_id <- entries$`dc:identifier`[1]
      author_name_found <- entries$`preferred-name`$`surname`[1]
    } else if (is.list(entries)) {
      scopus_id <- entries[[1]]$`dc:identifier`
      author_name_found <- entries[[1]]$`preferred-name`$`surname`
    } else {
      return(list(scopus_id = NA, match_count = total, error = "Parse error"))
    }

    # Clean Scopus ID (remove "AUTHOR_ID:" prefix)
    if (!is.na(scopus_id)) {
      scopus_id <- gsub("AUTHOR_ID:", "", scopus_id)
    }

    list(scopus_id = scopus_id, match_count = total, error = NA)

  }, error = function(e) {
    list(scopus_id = NA, match_count = 0, error = as.character(e$message))
  })
}

# Main function
main <- function() {
  cli_h1("Scopus Author ID Finder")

  validate_config(config)
  api_key <- Sys.getenv("SCOPUS_API_KEY")

  # Load data
  cli_alert_info("Loading author data...")
  authors <- as.data.table(read_excel(config$input_file))
  cli_alert_success("Loaded {nrow(authors)} authors")

  # Check if output file exists (for resuming)
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
      affiliation = character(),
      scopus_id = character(),
      match_count = integer(),
      error = character()
    ), config$output_file)
  }

  if (start_idx > nrow(authors)) {
    cli_alert_success("All authors already processed!")
    return(invisible())
  }

  # Process authors
  cli_h2("Searching Scopus Author Database")

  pb <- cli_progress_bar("Searching authors", total = nrow(authors) - start_idx + 1)

  for (i in start_idx:nrow(authors)) {
    author <- authors[i]

    result <- search_author(
      name = author$Name,
      affiliation = author$Affiliation_1,
      api_key = api_key
    )

    # Write result immediately
    row <- data.table(
      row_id = i,
      editor_name = author$editor_name,
      full_name = author$Name,
      affiliation = author$Affiliation_1,
      scopus_id = result$scopus_id,
      match_count = result$match_count,
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
  found <- sum(!is.na(results$scopus_id))
  not_found <- sum(is.na(results$scopus_id) & is.na(results$error))
  errors <- sum(!is.na(results$error))

  cli_h2("Summary")
  cli_alert_success("Found Scopus ID: {found} authors")
  cli_alert_warning("Not found: {not_found} authors")
  if (errors > 0) cli_alert_danger("Errors: {errors} authors")
  cli_alert_success("Results saved to {.file {config$output_file}}")
}

# Run
main()

#!/usr/bin/env Rscript

# =============================================================================
# Scopus Article Fetcher
# Retrieves EIDs and selected metadata from Scopus Search + Abstract APIs
# =============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(data.table)
  library(cli)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
config <- list(
  api_key = Sys.getenv("SCOPUS_API_KEY"),

  search_url   = "https://api.elsevier.com/content/search/scopus",
  abstract_url = "https://api.elsevier.com/content/abstract/eid/",

  eid_file  = "scopus_eids_2016-2025.csv",
  out_file  = "scopus_metadata_selected_fields.csv",
  error_log = "scopus_errors.log",

  # Throttling (seconds between requests)
  sleep_search   = 0.5,
  sleep_abstract = 1.5,

  # Retry settings
  max_retries     = 8,
  initial_backoff = 2,
  max_backoff     = 120,

  # Circuit breaker settings
  circuit_breaker_threshold = 3,
  circuit_breaker_pause     = 900,  # 15 minutes

  search_batch_size = 25
)

# ---------------------------------------------------------------------------
# ISSNs & Queries
# ---------------------------------------------------------------------------
ALL_ISSNS <- paste0(
  "(ISSN(0959-6526) OR ISSN(1879-1786) OR ISSN(0960-1481) OR ISSN(1879-0682)",
  " OR ISSN(2168-0485) OR ISSN(1364-0321) OR ISSN(1879-0690) OR ISSN(1748-9326)",
  " OR ISSN(1387-585X) OR ISSN(1573-2975) OR ISSN(1463-9262) OR ISSN(1463-9270)",
  " OR ISSN(2210-6707) OR ISSN(2210-6715) OR ISSN(1864-5631) OR ISSN(1864-564X)",
  " OR ISSN(0305-750X) OR ISSN(1873-5991) OR ISSN(2352-5509) OR ISSN(0921-8009)",
  " OR ISSN(1949-3029) OR ISSN(1949-3037) OR ISSN(0968-0802) OR ISSN(1099-1719)",
  " OR ISSN(2214-9937) OR ISSN(2214-9929) OR ISSN(2398-9629) OR ISSN(1862-4065)",
  " OR ISSN(1862-4057) OR ISSN(1708-3087) OR ISSN(0959-3780) OR ISSN(1872-9495)",
  " OR ISSN(0966-9582) OR ISSN(1747-7646) OR ISSN(1088-1980) OR ISSN(1530-9290)",
  " OR ISSN(1467-6370) OR ISSN(1758-6739) OR ISSN(2288-6206) OR ISSN(2198-0810)",
  " OR ISSN(2210-4224) OR ISSN(2210-4232) OR ISSN(1877-3435) OR ISSN(1877-3443)",
  " OR ISSN(1774-0746) OR ISSN(1773-0155) OR ISSN(1350-4509) OR ISSN(1745-2627)",
  " OR ISSN(2589-8116) OR ISSN(1543-5938) OR ISSN(1545-2050))"
)

YEARS <- 2020:2024
QUERIES <- lapply(YEARS, function(y) paste0(ALL_ISSNS, " AND PUBYEAR = ", y))

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
validate_config <- function(cfg) {
  if (is.null(cfg$api_key) || cfg$api_key == "") {
    cli_abort(c(
      "Missing Scopus API key.",
      "i" = "Set the {.envvar SCOPUS_API_KEY} environment variable.",
      "i" = "Example: {.code Sys.setenv(SCOPUS_API_KEY = 'your_key_here')}"
    ))
  }
  invisible(TRUE)
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_error <- function(msg, eid = NULL, file = config$error_log) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  entry <- if (!is.null(eid)) {
    sprintf("[%s] EID: %s | %s\n", timestamp, eid, msg)
  } else {
    sprintf("[%s] %s\n", timestamp, msg)
  }
  cat(entry, file = file, append = TRUE)
}

# -----------------------------------------------------------------------------
# API Helpers
# -----------------------------------------------------------------------------
perform_with_backoff <- function(req, cfg = config) {
  wait <- cfg$initial_backoff
  rate_limited <- FALSE

  for (attempt in seq_len(cfg$max_retries)) {
    resp <- tryCatch(
      req_perform(req),
      error = function(e) {
        cli_alert_warning(
          "Connection error (attempt {attempt}/{cfg$max_retries}): {conditionMessage(e)}"
        )
        log_error(sprintf("Connection error on attempt %d: %s", attempt, conditionMessage(e)))
        NULL
      }
    )

    if (is.null(resp)) {
      Sys.sleep(wait)
      wait <- min(wait * 2, cfg$max_backoff)
      next
    }

    status <- resp_status(resp)

    if (status >= 200 && status < 300) {
      return(list(response = resp, rate_limited = FALSE))
    }

    if (status == 429) {
      rate_limited <- TRUE
      retry_after <- resp_header(resp, "Retry-After")
      if (!is.null(retry_after)) {
        parsed <- suppressWarnings(as.numeric(retry_after))
        if (!is.na(parsed) && parsed > 0) {
          wait <- parsed
          log_error(sprintf("Rate limited with Retry-After: %d seconds", parsed))
        }
      }
      cli_alert_warning(
        "Rate limited (429). Waiting {wait}s (attempt {attempt}/{cfg$max_retries})"
      )
      Sys.sleep(wait)
      wait <- min(wait * 2, cfg$max_backoff)
      next
    }

    if (status >= 500) {
      body_preview <- tryCatch(substr(resp_body_string(resp), 1, 200), error = function(e) "")
      cli_alert_warning(
        "Server error ({status}). Retrying in {wait}s (attempt {attempt}/{cfg$max_retries}). {body_preview}"
      )
      log_error(sprintf("HTTP %d on attempt %d", status, attempt))
      Sys.sleep(wait)
      wait <- min(wait * 2, cfg$max_backoff)
      next
    }

    return(list(response = resp, rate_limited = FALSE))
  }

  cli_alert_danger("All {cfg$max_retries} retries exhausted.")
  list(response = NULL, rate_limited = rate_limited)
}

build_search_request <- function(query, cursor, cfg = config) {
  request(cfg$search_url) |>
    req_headers(
      "X-ELS-APIKey" = cfg$api_key,
      "Accept"       = "application/json"
    ) |>
    req_url_query(
      query  = query,
      cursor = cursor,
      count  = cfg$search_batch_size,
      view   = "STANDARD"
    ) |>
    req_error(is_error = ~ FALSE) |>
    req_timeout(120)
}

build_abstract_request <- function(eid, cfg = config) {
  request(paste0(cfg$abstract_url, URLencode(eid, reserved = TRUE))) |>
    req_headers(
      "X-ELS-APIKey" = cfg$api_key,
      "Accept"       = "application/json"
    ) |>
    req_url_query(view = "FULL") |>
    req_error(is_error = ~ FALSE) |>
    req_timeout(120)
}

# -----------------------------------------------------------------------------
# Utility helpers
# -----------------------------------------------------------------------------
safe_col <- function(df, col) {
  v <- df[[col]]
  if (is.null(v)) rep(NA_character_, nrow(df)) else as.character(v)
}

join_unique <- function(x, sep = "; ") {
  x <- x[!is.na(x) & nzchar(trimws(x))]
  x <- unique(trimws(x))
  if (length(x) == 0) return(NA_character_)
  paste(x, collapse = sep)
}

to_chr <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  as.character(x)
}

ensure_list_of_items <- function(x) {
  if (!is.data.frame(x) && !is.null(names(x))) list(x) else x
}

# -----------------------------------------------------------------------------
# Step 1: Collect EIDs + fields best available from Search API
# -----------------------------------------------------------------------------
collect_eids <- function(queries, cfg = config) {
  if (file.exists(cfg$eid_file)) {
    cli_alert_info("EID file already exists, skipping search: {.file {cfg$eid_file}}")
    return(invisible(NULL))
  }

  cli_h1("Collecting EIDs + metadata from Scopus Search API")

  fwrite(
    data.table(
      eid = character(),
      year = character(),
      `Scopus Source title` = character(),
      Citations = character(),
      DOI = character(),
      `Publication type` = character(),
      `Open Access` = character()
    ),
    cfg$eid_file
  )

  consecutive_429s <- 0L
  total_saved <- 0L

  for (q_idx in seq_along(queries)) {
    query <- queries[[q_idx]]
    year  <- as.character(YEARS[[q_idx]])
    cli_alert_info("Query {q_idx}/{length(queries)} (year {year})")

    cursor <- "*"
    query_saved <- 0L

    repeat {
      req    <- build_search_request(query, cursor, cfg)
      result <- perform_with_backoff(req, cfg)
      resp   <- result$response

      if (is.null(resp) || resp_status(resp) >= 400) {
        status <- if (is.null(resp)) "NULL" else resp_status(resp)
        body   <- tryCatch(
          if (!is.null(resp)) substr(resp_body_string(resp), 1, 300) else "No response",
          error = function(e) "Could not read body"
        )
        log_error(sprintf("Search API error %s for query %d: %s", status, q_idx, body))
        cli_alert_warning("Query {q_idx} failed with status {status}, skipping remaining pages...")

        if (result$rate_limited) {
          consecutive_429s <- consecutive_429s + 1L
          if (consecutive_429s >= cfg$circuit_breaker_threshold) {
            cli_alert_warning(
              "Circuit breaker triggered! Pausing {cfg$circuit_breaker_pause / 60} minutes..."
            )
            Sys.sleep(cfg$circuit_breaker_pause)
            consecutive_429s <- 0L
          }
        }
        break
      }

      consecutive_429s <- 0L

      js <- tryCatch(
        fromJSON(resp_body_string(resp), flatten = TRUE),
        error = function(e) {
          log_error(sprintf("JSON parse error: %s", conditionMessage(e)))
          NULL
        }
      )
      if (is.null(js)) break

      entries <- js[["search-results"]][["entry"]]
      if (is.null(entries) || length(entries) == 0) break

      if (is.data.frame(entries)) {
        dt <- data.table(
          eid = safe_col(entries, "eid"),
          year = fcoalesce(safe_col(entries, "prism:coverDate"), rep(NA_character_, nrow(entries))),
          `Scopus Source title` = safe_col(entries, "prism:publicationName"),
          Citations = safe_col(entries, "citedby-count"),
          DOI = safe_col(entries, "prism:doi"),
          `Publication type` = safe_col(entries, "subtypeDescription"),
          `Open Access` = fcoalesce(
            safe_col(entries, "openaccess"),
            safe_col(entries, "openaccessFlag")
          )
        )

        # Prefer PUBYEAR from query (more stable) if coverDate parsing fails
        dt[, year := fifelse(is.na(year) | !nzchar(year), year, year)]
        dt[, year := year] # keep as-is; overwritten below
        dt[, year := year]
      } else {
        dt <- rbindlist(lapply(entries, function(e) {
          data.table(
            eid = e[["eid"]] %||% NA_character_,
            year = e[["prism:coverDate"]] %||% year,
            `Scopus Source title` = e[["prism:publicationName"]] %||% NA_character_,
            Citations = e[["citedby-count"]] %||% NA_character_,
            DOI = e[["prism:doi"]] %||% NA_character_,
            `Publication type` = e[["subtypeDescription"]] %||% NA_character_,
            `Open Access` = e[["openaccess"]] %||% e[["openaccessFlag"]] %||% NA_character_
          )
        }), fill = TRUE)
      }

      # Force year from loop (PUBYEAR constraint in query)
      dt[, year := year]

      dt <- dt[!is.na(eid) & nzchar(eid)]
      if (nrow(dt) > 0) {
        fwrite(dt, cfg$eid_file, append = TRUE)
        query_saved <- query_saved + nrow(dt)
        total_saved <- total_saved + nrow(dt)
      }

      next_cursor <- js[["search-results"]][["cursor"]][["@next"]]
      if (is.null(next_cursor) || next_cursor == "" || identical(next_cursor, cursor)) break
      cursor <- next_cursor

      Sys.sleep(cfg$sleep_search)
    }

    cli_alert_success("Year {year}: {query_saved} records (running total: {total_saved})")
  }

  cli_alert_info("Removing duplicates by EID...")
  all_eids <- fread(cfg$eid_file)
  all_eids <- unique(all_eids[!is.na(eid) & nzchar(eid)], by = "eid")
  fwrite(all_eids, cfg$eid_file)

  cli_alert_success("Search collection complete: {nrow(all_eids)} unique EIDs.")
}

# -----------------------------------------------------------------------------
# Abstract parsing for required remaining fields
# -----------------------------------------------------------------------------
extract_authors_and_ids <- function(retrieval) {
  auth_list <- retrieval[["authors"]][["author"]]
  if (is.null(auth_list) || length(auth_list) == 0) {
    return(list(
      authors = NA_character_,
      author_ids = NA_character_,
      corresponding_author_id = NA_character_
    ))
  }

  if (is.data.frame(auth_list)) {
    auth_items <- lapply(seq_len(nrow(auth_list)), \(i) as.list(auth_list[i, ]))
  } else {
    auth_items <- ensure_list_of_items(auth_list)
  }

  get_name <- function(a) {
    nm <- a[["ce:indexed-name"]] %||% a[["authname"]] %||% a[["ce:surname"]] %||% NA_character_
    to_chr(nm)
  }

  get_id <- function(a) {
    # commonly "authid" in abstracts response; keep as character
    to_chr(a[["authid"]] %||% a[["@auid"]] %||% a[["auid"]])
  }

  get_corr_flag <- function(a) {
    # Best-effort: different payloads use different flags/fields
    # We'll check a few likely candidates.
    v <- a[["corresponding"]] %||% a[["@corresponding"]] %||% a[["corresponding-author"]] %||% NA
    v <- to_chr(v)
    if (is.na(v)) return(FALSE)
    tolower(v) %chin% c("y", "yes", "true", "1")
  }

  names_vec <- vapply(auth_items, get_name, character(1), USE.NAMES = FALSE)
  ids_vec   <- vapply(auth_items, get_id,   character(1), USE.NAMES = FALSE)

  corr_idx <- which(vapply(auth_items, get_corr_flag, logical(1), USE.NAMES = FALSE))
  corr_id <- if (length(corr_idx) >= 1) ids_vec[[corr_idx[[1]]]] else NA_character_

  list(
    authors = join_unique(names_vec),
    author_ids = join_unique(ids_vec),
    corresponding_author_id = join_unique(c(corr_id))
  )
}

extract_affiliations <- function(retrieval) {
  aff_list <- retrieval[["affiliation"]]
  if (is.null(aff_list) || length(aff_list) == 0) {
    return(list(
      aff_ids = NA_character_,
      aff_names = NA_character_,
      countries = NA_character_
    ))
  }

  if (is.data.frame(aff_list)) {
    aff_items <- lapply(seq_len(nrow(aff_list)), \(i) as.list(aff_list[i, ]))
  } else {
    aff_items <- ensure_list_of_items(aff_list)
  }

  get_aff_id <- function(a) to_chr(a[["@id"]] %||% a[["affiliation-id"]] %||% a[["id"]])
  get_aff_nm <- function(a) to_chr(a[["affilname"]] %||% a[["affiliation-name"]] %||% a[["name"]])
  get_country <- function(a) to_chr(a[["affiliation-country"]] %||% a[["country"]])

  aff_ids <- vapply(aff_items, get_aff_id, character(1), USE.NAMES = FALSE)
  aff_nms <- vapply(aff_items, get_aff_nm, character(1), USE.NAMES = FALSE)
  ctry    <- vapply(aff_items, get_country, character(1), USE.NAMES = FALSE)

  list(
    aff_ids = join_unique(aff_ids),
    aff_names = join_unique(aff_nms),
    countries = join_unique(ctry)
  )
}

parse_abstract_response <- function(js) {
  retrieval <- js[["abstracts-retrieval-response"]]
  if (is.null(retrieval)) {
    return(list(
      Authors = NA_character_,
      `Scopus Author Ids` = NA_character_,
      `Scopus Author ID Corresponding Author` = NA_character_,
      `Scopus Affiliation IDs` = NA_character_,
      `Scopus Affiliation names` = NA_character_,
      `Country/Region` = NA_character_
    ))
  }

  a <- extract_authors_and_ids(retrieval)
  f <- extract_affiliations(retrieval)

  list(
    Authors = a$authors,
    `Scopus Author Ids` = a$author_ids,
    `Scopus Author ID Corresponding Author` = a$corresponding_author_id,
    `Scopus Affiliation IDs` = f$aff_ids,
    `Scopus Affiliation names` = f$aff_names,
    `Country/Region` = f$countries
  )
}

# -----------------------------------------------------------------------------
# Step 2: Fetch Abstract Details for Each EID and write ONLY required fields
# -----------------------------------------------------------------------------
fetch_abstracts <- function(cfg = config) {
  cli_h1("Fetching Abstract Details")

  if (!file.exists(cfg$eid_file)) {
    cli_abort("EID file not found: {.file {cfg$eid_file}}")
  }

  eids_dt <- unique(fread(cfg$eid_file)[!is.na(eid) & nzchar(eid)], by = "eid")
  cli_alert_info("Loaded {nrow(eids_dt)} unique EIDs")

  done_eids <- character()
  if (file.exists(cfg$out_file)) {
    done_dt <- fread(cfg$out_file, select = "EID")
    done_eids <- unique(done_dt$EID)
    cli_alert_info("Already processed: {length(done_eids)} EIDs")
  } else {
    fwrite(
      data.table(
        Authors = character(),
        `Scopus Author Ids` = character(),
        Year = character(),
        `Scopus Source title` = character(),
        Citations = character(),
        DOI = character(),
        `Publication type` = character(),
        `Open Access` = character(),
        EID = character(),
        `Scopus Affiliation IDs` = character(),
        `Scopus Author ID Corresponding Author` = character(),
        `Country/Region` = character(),
        `Scopus Affiliation names` = character()
      ),
      cfg$out_file
    )
  }

  todo <- eids_dt[!eid %in% done_eids]
  if (nrow(todo) == 0) {
    cli_alert_success("All EIDs already processed!")
    return(invisible(NULL))
  }

  cli_alert_info("Remaining to process: {nrow(todo)} EIDs")
  cli_progress_bar("Fetching abstracts", total = nrow(todo))

  success_count <- 0L
  error_count <- 0L
  consecutive_429s <- 0L

  for (i in seq_len(nrow(todo))) {
    eid  <- todo$eid[i]

    base_row <- data.table(
      Year = as.character(todo$year[i]),
      `Scopus Source title` = as.character(todo$`Scopus Source title`[i]),
      Citations = as.character(todo$Citations[i]),
      DOI = as.character(todo$DOI[i]),
      `Publication type` = as.character(todo$`Publication type`[i]),
      `Open Access` = as.character(todo$`Open Access`[i]),
      EID = as.character(eid)
    )

    req    <- build_abstract_request(eid, cfg)
    result <- perform_with_backoff(req, cfg)
    resp   <- result$response

    enrich <- data.table(
      Authors = NA_character_,
      `Scopus Author Ids` = NA_character_,
      `Scopus Affiliation IDs` = NA_character_,
      `Scopus Author ID Corresponding Author` = NA_character_,
      `Country/Region` = NA_character_,
      `Scopus Affiliation names` = NA_character_
    )

    if (is.null(resp)) {
      log_error("No response after all retries", eid)
      error_count <- error_count + 1L

      if (result$rate_limited) {
        consecutive_429s <- consecutive_429s + 1L
        if (consecutive_429s >= cfg$circuit_breaker_threshold) {
          cli_alert_warning(
            "Circuit breaker triggered! Pausing {cfg$circuit_breaker_pause / 60} minutes..."
          )
          Sys.sleep(cfg$circuit_breaker_pause)
          consecutive_429s <- 0L
        }
      }

    } else {
      status <- resp_status(resp)

      if (status >= 200 && status < 300) {
        consecutive_429s <- 0L

        js <- tryCatch(
          fromJSON(resp_body_string(resp), flatten = TRUE),
          error = function(e) {
            log_error(sprintf("JSON parse error: %s", conditionMessage(e)), eid)
            NULL
          }
        )

        if (!is.null(js)) {
          parsed <- parse_abstract_response(js)

          enrich[, `:=`(
            Authors = parsed$Authors,
            `Scopus Author Ids` = parsed$`Scopus Author Ids`,
            `Scopus Affiliation IDs` = parsed$`Scopus Affiliation IDs`,
            `Scopus Author ID Corresponding Author` =
              parsed$`Scopus Author ID Corresponding Author`,
            `Country/Region` = parsed$`Country/Region`,
            `Scopus Affiliation names` = parsed$`Scopus Affiliation names`
          )]

          success_count <- success_count + 1L
        } else {
          error_count <- error_count + 1L
        }
      } else {
        log_error(sprintf("HTTP %d", status), eid)
        error_count <- error_count + 1L
      }
    }

    out_row <- cbind(enrich, base_row)
    out_row <- out_row[, .(
      Authors,
      `Scopus Author Ids`,
      Year,
      `Scopus Source title`,
      Citations,
      DOI,
      `Publication type`,
      `Open Access`,
      EID,
      `Scopus Affiliation IDs`,
      `Scopus Author ID Corresponding Author`,
      `Country/Region`,
      `Scopus Affiliation names`
    )]

    fwrite(out_row, cfg$out_file, append = TRUE)
    cli_progress_update()

    Sys.sleep(cfg$sleep_abstract)
  }

  cli_progress_done()
  cli_alert_success("Complete! Success: {success_count}, Errors: {error_count}")
  cli_alert_info("Output: {.file {cfg$out_file}}")
  if (error_count > 0) {
    cli_alert_warning("See {.file {cfg$error_log}} for error details.")
  }
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main <- function() {
  cli_h1("Scopus Article Fetcher")
  validate_config(config)

  collect_eids(QUERIES, config)

  # Optional filtering step; retained from the earlier pipeline and updated to use the new column names
  cli_h1("Filtering Results")
  eids <- fread(config$eid_file)

  unwanted <- c("Taiwan Journal of Ophthalmology", "Topics in Catalysis")
  eids_filtered <- eids[!`Scopus Source title` %chin% unwanted]
  cli_alert_info("Removed unwanted journals: {nrow(eids) - nrow(eids_filtered)} records")

  eids_filtered <- eids_filtered[`Publication type` %chin% c("Article", "Review")]
  cli_alert_info("Kept articles and reviews only: {nrow(eids_filtered)} records")

  fwrite(eids_filtered, config$eid_file)
  cli_alert_success("Filtered EIDs saved to {.file {config$eid_file}}")

  fetch_abstracts(config)

  cli_alert_success("All tasks complete!")
}

if (!interactive()) {
  main()
}

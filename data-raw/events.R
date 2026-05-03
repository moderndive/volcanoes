# Build data/events.rda by scraping each volcano's "Eruptive History" page
# from volcano.si.edu.
#
# WHY THIS IS COMPLICATED
# -----------------------
# The Global Volcanism Program does not expose events through its WFS or any
# other machine-readable endpoint, and the bulk-download search pages
# (search_event_results.cfm) are empty during GVP's 2026 site rebuild. The
# only place individual events can be read is the per-volcano HTML pages,
# which are served from the Cloudflare-protected volcano.si.edu host. Plain
# httr/rvest/curl requests get a 403 — Cloudflare requires a real browser
# TLS fingerprint. We therefore drive a headless Chromium via {chromote}.
#
# REQUIREMENTS
# ------------
#  * Chrome or Chromium installed locally (chromote::find_chrome() must
#    succeed). On macOS: `brew install --cask google-chrome`.
#  * Packages: chromote, rvest, dplyr, tibble, purrr, readr, fs.
#  * Network bandwidth & ~1 hour of wall-time for a clean scrape (~1,200
#    pages, 3-second polite delay between requests). The script caches each
#    page's parsed events to data-raw/cache/events/<volcano_number>.rds and
#    will resume where it left off if interrupted.
#
# COURTESY
# --------
# GVP is a public-good resource maintained on a small budget. Please:
#  * Keep the 3-second delay (or longer) between page loads.
#  * Run the scrape no more often than monthly (GVP releases roughly
#    monthly anyway).
#  * Cite GVP in any downstream work. See README.md.

library(chromote)
library(rvest)
library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(fs)

# Reuse data/eruptions.rda built earlier in build.R so we know which volcanoes
# have any Holocene eruptions to scrape (avoids scraping volcanoes that we
# know will return no events).
if (!exists("eruptions")) load("data/eruptions.rda")

volcano_numbers <- sort(unique(eruptions$volcano_number))

# Development knob: cap the scrape so we can validate the parse pipeline
# end-to-end on a handful of volcanoes before committing to the full ~1,200.
# Set to Inf (or remove this line) once the selector is confirmed.
scrape_limit <- Inf
volcano_numbers <- head(volcano_numbers, scrape_limit)

cache_dir <- "data-raw/cache/events"
dir_create(cache_dir)

# Cloudflare blocks chromote's default headless Chrome with a "Performing
# security verification" interstitial. The reliable workaround is to launch
# Chrome yourself with a persistent profile, solve the CF challenge once
# manually in that window, and have chromote attach to the running Chrome
# via the DevTools port. The cf_clearance cookie then persists in the
# profile and covers the full scrape.
#
# Before sourcing this file, run in a terminal (one line):
#
#   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
#     --remote-debugging-port=9222 \
#     --user-data-dir="$HOME/.chromote-volcanoes-profile"
#
# Then in that Chrome window visit:
#   https://volcano.si.edu/volcano.cfm?vn=210010&vtab=Eruptions
# and wait for the page to render (solve any CF checkbox that appears).
# Leave the window open and run this script.

# chromote needs a Browser-like object exposing host/port to attach to a
# user-launched Chrome. Build a minimal R6 wrapper that satisfies that.
RemoteBrowser <- R6::R6Class(
  "RemoteBrowser",
  public = list(
    initialize = function(host = "127.0.0.1", port = 9222) {
      private$host_ <- host
      private$port_ <- port
    },
    get_host  = function() private$host_,
    get_port  = function() private$port_,
    is_alive  = function() TRUE,
    is_local  = function() FALSE,
    close     = function() invisible(NULL)
  ),
  private = list(host_ = NULL, port_ = NULL)
)

chrome_remote <- chromote::Chromote$new(browser = RemoteBrowser$new())
chromote::set_default_chromote_object(chrome_remote)

session <- ChromoteSession$new()
session$default_timeout <- 60
on.exit(session$close(), add = TRUE)

# Poll the page until CF clears. Detects challenge by title ("Just a
# moment...") AND by body text — earlier polling missed the challenge
# because innerText was briefly empty during transitions.
wait_for_cf <- function(timeout = 60) {
  deadline <- Sys.time() + timeout
  repeat {
    title <- session$Runtime$evaluate("document.title")$result$value %||% ""
    body  <- session$Runtime$evaluate(
      "document.body ? document.body.innerText : ''"
    )$result$value %||% ""
    is_challenge <-
      grepl("just a moment", title, ignore.case = TRUE) ||
      grepl("performing security verification|security service to protect|verifying you are human",
            body, ignore.case = TRUE)
    if (!is_challenge && nchar(body) > 0) return(TRUE)
    if (Sys.time() > deadline) return(FALSE)
    Sys.sleep(1)
  }
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Helper: fetch a fully-rendered page as parsed HTML.
fetch_rendered <- function(vn) {
  url <- sprintf("https://volcano.si.edu/volcano.cfm?vn=%d&vtab=Eruptions", vn)
  session$Page$navigate(url)
  session$Page$loadEventFired()
  if (!wait_for_cf()) {
    warning("Cloudflare challenge did not clear for vn=", vn)
  }
  Sys.sleep(1)  # let the Eruptions tab render
  html_text <- session$Runtime$evaluate("document.documentElement.outerHTML")$result$value
  list(text = html_text, parsed = read_html(html_text))
}

# One-time DOM probe: try the first few volcanoes until one returns real
# (non-CF) content, then dump its HTML for inspection.
# Re-run by deleting data-raw/cache/_probe.html.
probe_file <- path(cache_dir, "..", "_probe.html")
if (!file_exists(probe_file)) {
  message("Writing DOM probe to ", probe_file, " ...")
  for (vn in head(volcano_numbers, 6)) {
    message("  trying vn=", vn)
    probe <- fetch_rendered(vn)
    title <- xml2::xml_text(rvest::html_element(probe$parsed, "title"))
    if (!grepl("just a moment|attention required", title, ignore.case = TRUE)) {
      message("  got real page (title: ", title, "), saving probe.")
      writeLines(probe$text, probe_file)
      break
    }
    Sys.sleep(3)
  }
  if (!file_exists(probe_file)) {
    stop("Probe failed: every attempted page came back as a CF challenge.")
  }
}

# Parse a single GVP date string into (year, month, day). Handles formats
# encountered on the rebuilt site, e.g.:
#   "8740 BCE ± 150 years"  -> -8740, NA, NA
#   "1980 May 18"           -> 1980, 5, 18
#   "1980-05-18"            -> 1980, 5, 18
#   "1980 May"              -> 1980, 5, NA
#   "1980"                  -> 1980, NA, NA
#   "- - - -" / "" / NA     -> NA, NA, NA
parse_gvp_date <- function(text) {
  if (is.null(text) || is.na(text)) {
    return(list(year = NA_integer_, month = NA_integer_, day = NA_integer_))
  }
  s <- trimws(gsub(" ", " ", text))            # strip nbsp
  s <- trimws(gsub("\\s+", " ", s))
  if (s == "" || grepl("^-+( -+)*$", s) || tolower(s) == "unknown") {
    return(list(year = NA_integer_, month = NA_integer_, day = NA_integer_))
  }
  s <- trimws(gsub("\\s*±.*$", "", s))         # strip "± N years"
  bce <- grepl("\\bBCE?\\b", s, ignore.case = TRUE)
  s <- trimws(gsub("\\b(BCE?|CE|AD)\\b", "", s, ignore.case = TRUE))
  sign <- if (bce) -1L else 1L

  if (grepl("^\\d+(-\\d{1,2}){0,2}$", s)) {
    parts <- as.integer(strsplit(s, "-")[[1]])
    return(list(
      year  = parts[1] * sign,
      month = if (length(parts) >= 2) parts[2] else NA_integer_,
      day   = if (length(parts) >= 3) parts[3] else NA_integer_
    ))
  }
  m <- regmatches(s, regexec("^(\\d+)\\s+([A-Za-z]+)(?:\\s+(\\d{1,2}))?$", s))[[1]]
  if (length(m) > 0) {
    return(list(
      year  = as.integer(m[2]) * sign,
      month = match(tolower(substr(m[3], 1, 3)), tolower(month.abb)),
      day   = if (nzchar(m[4])) as.integer(m[4]) else NA_integer_
    ))
  }
  list(year = NA_integer_, month = NA_integer_, day = NA_integer_)
}

parse_dates_df <- function(x, prefix) {
  parsed <- lapply(x, parse_gvp_date)
  tibble(
    !!paste0(prefix, "_year")  := vapply(parsed, `[[`, integer(1), "year"),
    !!paste0(prefix, "_month") := vapply(parsed, `[[`, integer(1), "month"),
    !!paste0(prefix, "_day")   := vapply(parsed, `[[`, integer(1), "day")
  )
}

# Walk the accordion DOM: each volcano page has one or more Eruption-Accordion
# blocks; inside each, one or more EpisodeTable divs (one per episode); inside
# each, an EventsTable > table with the events themselves.
parse_volcano_events <- function(page, vn) {
  eruption_blocks <- page |> html_elements(".Eruption-AccordionContent")
  if (length(eruption_blocks) == 0) return(tibble())

  imap(eruption_blocks, function(erp_node, eruption_idx) {
    episode_tables <- erp_node |> html_elements(".EpisodeTable")
    imap(episode_tables, function(ep_node, episode_seq) {
      header_text <- ep_node |> html_element("thead") |> html_text()
      ep_match <- regmatches(header_text, regexec("Episode\\s+(\\d+)", header_text))[[1]]
      episode_number <- if (length(ep_match) >= 2) as.integer(ep_match[2]) else episode_seq

      tbl_nodes <- ep_node |> html_elements(".EventsTable > table")
      if (length(tbl_nodes) == 0) return(tibble())
      tbl <- html_table(tbl_nodes[[1]], header = TRUE)
      if (nrow(tbl) == 0) return(tibble())

      # Drop unnamed/empty leading column (the icon column with width:5%).
      empties <- which(names(tbl) == "" | is.na(names(tbl)))
      if (length(empties) > 0) tbl <- tbl[, -empties, drop = FALSE]

      # html_table infers types per page — a page where every Start Date is a
      # bare year ends up integer, which then breaks bind_rows across volcanoes.
      tbl <- tbl |>
        mutate(across(any_of(c("Start Date", "End Date",
                               "Event Type", "Event Remarks")),
                      as.character))

      tbl |>
        mutate(
          volcano_number  = vn,
          eruption_number = eruption_idx,   # per-volcano sequence
          episode_number  = episode_number,
          event_number    = row_number(),
          .before = 1
        )
    }) |> bind_rows()
  }) |> bind_rows()
}

# Failures (network, CF, parser type clashes, etc.) are logged here instead of
# aborting the run. Failed volcanoes don't write a cache, so re-sourcing the
# script automatically retries them.
error_log <- path(cache_dir, "..", "_errors.tsv")

log_scrape_error <- function(vn, msg) {
  msg <- gsub("[\t\r\n]+", " ", msg)
  line <- paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), vn, msg, sep = "\t")
  cat(line, "\n", sep = "", file = error_log, append = TRUE)
  message("  ERROR vn=", vn, ": ", msg)
}

scrape_one <- function(vn) {
  cache_file <- path(cache_dir, paste0(vn, ".rds"))
  if (file_exists(cache_file)) {
    cached <- read_rds(cache_file)
    if (nrow(cached) > 0) return(cached)
  }
  tryCatch({
    page <- fetch_rendered(vn)$parsed
    events_vn <- parse_volcano_events(page, vn)
    if (nrow(events_vn) > 0) write_rds(events_vn, cache_file)
    Sys.sleep(3)
    events_vn
  }, error = function(e) {
    log_scrape_error(vn, conditionMessage(e))
    Sys.sleep(3)
    tibble()
  })
}

events_raw <- map(volcano_numbers, scrape_one, .progress = TRUE) |>
  bind_rows()

# End-of-run summary: which volcanoes failed and need a retry.
n_attempted <- length(volcano_numbers)
n_cached    <- sum(file_exists(path(cache_dir, paste0(volcano_numbers, ".rds"))))
n_failed    <- n_attempted - n_cached
message(sprintf("\nScrape summary: %d/%d cached, %d failed.",
                n_cached, n_attempted, n_failed))
if (n_failed > 0) {
  message("Failures logged to: ", error_log)
  message("Re-source this file to retry failed volcanoes only ",
          "(successful ones are served from cache).")
}

# Note: GVP's rebuilt site no longer exposes its internal eruption IDs in the
# DOM, so eruption_number here is a per-volcano sequence (1, 2, ...) rather
# than the GVP database id used in the 2020 TidyTuesday release.
events <- events_raw |>
  janitor::clean_names() |>
  bind_cols(
    parse_dates_df(events_raw[["Start Date"]], "event_date_start"),
    parse_dates_df(events_raw[["End Date"]],   "event_date_end")
  ) |>
  select(-any_of(c("start_date", "end_date"))) |>
  mutate(
    volcano_number  = as.integer(volcano_number),
    eruption_number = as.integer(eruption_number),
    episode_number  = as.integer(episode_number),
    event_number    = as.integer(event_number),
    event_remarks   = dplyr::na_if(trimws(replace(event_remarks, is.na(event_remarks), "")), "")
  ) |>
  arrange(volcano_number, eruption_number, episode_number, event_number) |>
  as_tibble()

usethis::use_data(events, overwrite = TRUE)

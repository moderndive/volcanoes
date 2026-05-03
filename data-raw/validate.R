# Validate the events scraper end-to-end against modern, high-activity
# volcanoes — the 5 first-by-vn volcanoes scraped during regular development
# are mostly prehistoric and have no per-event dates, so they don't exercise
# the date parser or multi-episode handling.
#
# Usage:
#   1. Source data-raw/events.R first (loads parser, opens chromote session).
#   2. source("data-raw/validate.R")
#
# Re-fetches each test volcano fresh (bypasses cache) so a regression in
# parsing is caught even when the cache holds an older version.

if (!exists("parse_volcano_events") || !exists("parse_gvp_date") ||
    !exists("fetch_rendered") || !exists("eruptions")) {
  stop("Source data-raw/events.R first — validate.R reuses its parser, ",
       "chromote session, and the eruptions tibble.")
}

# Auto-pick two volcanoes with the most 20th-century-or-later eruptions; these
# are guaranteed to have per-event dates and (usually) multi-episode eruptions.
test_vns <- eruptions |>
  dplyr::filter(start_year >= 1900) |>
  dplyr::count(volcano_number, name = "n_recent") |>
  dplyr::slice_max(n_recent, n = 2, with_ties = FALSE) |>
  dplyr::pull(volcano_number)

stopifnot(length(test_vns) == 2)

cat("Validating parser against modern volcanoes:", paste(test_vns, collapse = ", "), "\n")

problems <- character()

for (vn in test_vns) {
  cat(sprintf("\n--- vn=%d ---\n", vn))
  page <- fetch_rendered(vn)$parsed
  df   <- parse_volcano_events(page, vn)

  if (nrow(df) == 0) {
    problems <- c(problems, sprintf("vn=%d: 0 events parsed", vn))
    next
  }
  cat("  events parsed:", nrow(df), "\n")

  expected <- c("volcano_number", "eruption_number", "episode_number",
                "event_number", "Start Date", "End Date",
                "Event Type", "Event Remarks")
  missing_cols <- setdiff(expected, names(df))
  if (length(missing_cols) > 0) {
    problems <- c(problems, sprintf("vn=%d: missing cols %s",
                                    vn, paste(missing_cols, collapse = ", ")))
  }

  start_years <- vapply(df[["Start Date"]], function(s) parse_gvp_date(s)$year,
                        integer(1))
  n_dated <- sum(!is.na(start_years))
  cat(sprintf("  events with parseable start year: %d / %d\n", n_dated, nrow(df)))
  if (n_dated == 0) {
    problems <- c(problems, sprintf("vn=%d: no event has a parseable Start Date — date parser may be broken or DOM changed",
                                    vn))
  } else {
    yr_range <- range(start_years, na.rm = TRUE)
    cat(sprintf("  start year range: [%d, %d]\n", yr_range[1], yr_range[2]))
    if (yr_range[1] < -15000 || yr_range[2] > 2030) {
      problems <- c(problems, sprintf("vn=%d: implausible year range [%d, %d]",
                                      vn, yr_range[1], yr_range[2]))
    }
  }

  # Episode handling: at least one volcano in the test set should have an
  # eruption with >1 episodes. We check across the full sample, not per-vn.
  cat("  episode counts per eruption:\n")
  ep_counts <- df |>
    dplyr::distinct(eruption_number, episode_number) |>
    dplyr::count(eruption_number, name = "n_episodes")
  print(ep_counts |> dplyr::count(n_episodes, name = "n_eruptions"))

  cat("  distinct event types:",
      paste(sort(unique(df[["Event Type"]])), collapse = ", "), "\n")

  Sys.sleep(3)
}

if (length(problems) > 0) {
  cat("\n=== VALIDATION FAILED ===\n")
  for (p in problems) cat(" -", p, "\n")
  stop("Validation failed; see messages above.")
} else {
  cat("\n=== VALIDATION PASSED ===\n")
}

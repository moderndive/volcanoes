# Changelog

## volcanoes 0.1.1

CRAN release: 2026-07-11

- Fix stale documentation for `last_eruption_year`: the column is
  **numeric** (negative values are BCE years) with `NA` for volcanoes
  with only undated activity — not character with “Unknown” as
  previously documented.

## volcanoes 0.1.0

- Initial CRAN release.
- Three exported datasets — `volcanoes`, `eruptions`, and `events` —
  built from the Smithsonian Institution Global Volcanism Program’s
  *Volcanoes of the World* database (snapshot 2026-05-03), following the
  schema popularized by the `rfordatascience/tidytuesday` 2020-05-12
  release.
- `data-raw/build.R` rebuilds the snapshot against the current GVP
  release; `volcanoes` and `eruptions` come from the GVP WFS endpoint,
  `events` is scraped from per-volcano pages with a local cache.

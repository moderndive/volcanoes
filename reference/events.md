# Eruption events

One row per event observed during an eruption — for example a lava flow,
pyroclastic surge, lahar, or ash plume. Many events typically belong to
a single eruption.

## Usage

``` r
events
```

## Format

A tibble with one row per event. Columns include:

- volcano_number:

  Integer. Joins to
  [volcanoes](https://moderndive.github.io/volcanoes/reference/volcanoes.md).

- volcano_name:

  Character.

- eruption_number:

  Integer. Joins to
  [eruptions](https://moderndive.github.io/volcanoes/reference/eruptions.md).

- eruption_start_year:

  Numeric. Start year of the parent eruption.

- event_number:

  Integer. GVP unique event identifier.

- event_type:

  Character. Event classification.

- event_remarks:

  Character. Free-text notes from GVP.

- event_date_year, event_date_month, event_date_day:

  Integer. Date the event was observed.

## Source

Smithsonian Institution, Global Volcanism Program.
<https://volcano.si.edu/search_event_results.cfm>

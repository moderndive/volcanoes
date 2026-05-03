# Volcanic eruptions

One row per eruption recorded by the Global Volcanism Program. Each
eruption belongs to a single volcano (`volcano_number`) and may comprise
many
[events](https://moderndive.github.io/volcanoes/reference/events.md).

## Usage

``` r
eruptions
```

## Format

A tibble with one row per eruption. Columns include:

- volcano_number:

  Integer. GVP volcano identifier; joins to
  [volcanoes](https://moderndive.github.io/volcanoes/reference/volcanoes.md).

- volcano_name:

  Character.

- eruption_number:

  Integer. GVP unique eruption identifier; joins to
  [events](https://moderndive.github.io/volcanoes/reference/events.md).

- eruption_category:

  Character. Confirmation status (e.g. "Confirmed Eruption", "Uncertain
  Eruption", "Discredited Eruption").

- area_of_activity:

  Character. Named vent or sub-area within the volcano, when reported.

- vei:

  Numeric. Volcanic Explosivity Index, 0–8.

- start_year, start_month, start_day:

  Numeric. Eruption start date.

- end_year, end_month, end_day:

  Numeric. Eruption end date, where known.

- evidence_method_dating:

  Character. Method used to date the eruption.

- latitude, longitude:

  Numeric. WGS84 decimal degrees of the active vent.

Modifier and uncertainty columns from the raw GVP export are dropped
during the build, matching the rfordatascience/tidytuesday 2020-05-12
layout.

## Source

Smithsonian Institution, Global Volcanism Program.
<https://volcano.si.edu/search_eruption_results.cfm>

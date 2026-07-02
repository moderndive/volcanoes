# Holocene volcanoes

One row per volcano with at least one known Holocene eruption, sourced
from the Smithsonian Institution's Global Volcanism Program "Volcanoes
of the World" database.

## Usage

``` r
volcanoes
```

## Format

A tibble with one row per volcano. Columns include:

- volcano_number:

  Integer. GVP unique volcano identifier.

- volcano_name:

  Character. Volcano name.

- primary_volcano_type:

  Character. Morphological classification (e.g. stratovolcano, shield,
  caldera).

- last_eruption_year:

  Numeric. Year of the most recently confirmed eruption (negative values
  are BCE years), or `NA` for volcanoes with only undated activity.

- country:

  Character. Country containing the volcano.

- region:

  Character. GVP geographic region.

- subregion:

  Character. GVP geographic subregion.

- latitude, longitude:

  Numeric. WGS84 decimal degrees.

- elevation:

  Numeric. Summit elevation in meters above sea level.

- tectonic_settings:

  Character. Plate tectonic context and crustal type.

- evidence_category:

  Character. GVP evidence classification for activity (e.g. "Eruption
  Observed", "Eruption Dated").

- dominant_rock_type:

  Character. Primary rock composition where reported.

Additional columns from the GVP export are retained verbatim with names
standardized via
[`janitor::make_clean_names()`](https://sfirke.github.io/janitor/reference/make_clean_names.html).

## Source

Smithsonian Institution, Global Volcanism Program. *Volcanoes of the
World*. <https://volcano.si.edu/volcanolist_holocene.cfm>

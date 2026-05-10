# volcanoes <a href="https://moderndive.github.io/volcanoes/"><img src="https://raw.githubusercontent.com/moderndive/volcanoes/main/hex.gif" align="right" height="138" alt="volcanoes hex logo" /></a>

An R data package wrapping a current (as of 2026-05-03) snapshot of the Smithsonian Institution
[Global Volcanism Program](https://volcano.si.edu/) Volcanoes of the World
database. The schema follows the layout popularized by the
[rfordatascience/tidytuesday 2020-05-12](https://github.com/rfordatascience/tidytuesday/tree/main/data/2020/2020-05-12)
release, refreshed against the latest GVP database version.

## Installation

```r
# install.packages("pak")
pak::pak("moderndive/volcanoes")
```

## Datasets

| Dataset     | Rows (per snapshot) | Description                                          |
|-------------|---------------------|------------------------------------------------------|
| `volcanoes` | ~1,200              | One row per Holocene volcano                         |
| `eruptions` | ~10,000             | One row per recorded eruption                        |
| `events`    | ~30,000             | One row per individual event within an eruption      |

```r
library(volcanoes)

head(volcanoes)
head(eruptions)
head(events)
```

The three tables join on `volcano_number` and `eruption_number`:

```r
library(dplyr)

volcanoes |>
  inner_join(eruptions, by = "volcano_number") |>
  filter(vei >= 5)
```

## Refreshing the data

GVP publishes a new database version roughly every month. To rebuild the
package's `.rda` files against the current release:

```r
source("data-raw/build.R")
```

`volcanoes` and `eruptions` are pulled from GVP's WFS endpoint and refresh
in seconds. `events` is scraped from per-volcano pages via headless Chromium
(`chromote`) and takes about an hour the first time; subsequent runs reuse a
local cache in `data-raw/cache/events/`. See
[`data-raw/README.md`](../data-raw/README.md) for setup details and the
politeness expectations.

## Data source and license

The underlying records are © Smithsonian Institution, Global Volcanism
Program, and are subject to GVP's
[terms of use](https://volcano.si.edu/gvp_terms.cfm). Cite GVP in any
downstream work — for example:

> Global Volcanism Program. *Volcanoes of the World* (v. 5.x.x). Smithsonian
> Institution. <https://doi.org/10.5479/si.GVP.VOTW5-2024.5.1>

The package code and the curated tibbles as distributed here are MIT
licensed; see [`../LICENSE.md`](../LICENSE.md).

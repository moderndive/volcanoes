# Refreshing the data

The package's three datasets are built from the Smithsonian Institution's
Global Volcanism Program at <https://volcano.si.edu/>. Two are pulled from
GVP's public WFS endpoint and one is scraped from per-volcano HTML pages.

## Quick run

From the package root:

```r
source("data-raw/build.R")
```

That runs three scripts in sequence and writes `.rda` files to `data/`.

## What each script does

| Script                 | Source                                                                                  | Mechanism                                                          |
|------------------------|-----------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| `data-raw/volcanoes.R` | `webservices.volcano.si.edu` WFS — `Smithsonian_VOTW_Holocene_Volcanoes`                | Plain HTTPS, returns CSV. No bypass needed. ~1 s.                  |
| `data-raw/eruptions.R` | `webservices.volcano.si.edu` WFS — `Smithsonian_VOTW_Holocene_Eruptions`                | Plain HTTPS, returns CSV. ~1 s.                                    |
| `data-raw/events.R`    | `volcano.si.edu/volcano.cfm?vn=…&vtab=Eruptions` (one page per volcano with eruptions)  | Headless Chromium via [`chromote`](https://rstudio.github.io/chromote/) (Cloudflare requires a real-browser TLS fingerprint). ~1 hour with 3 s politeness delay. Resumable via per-volcano cache in `data-raw/cache/events/`. |

## One-time setup for events scraping

The events scraper drives a real browser:

1. Install Google Chrome or Chromium (macOS: `brew install --cask google-chrome`).
2. `install.packages(c("chromote", "rvest", "dplyr", "tibble", "purrr", "readr", "fs", "janitor", "usethis"))`.
3. Run `chromote::find_chrome()` and confirm it returns a path.

`chromote` is intentionally **not** declared in `DESCRIPTION` Suggests:
its `Google Chrome` system requirement is mapped by `pkgdepends` to the
`ppa:xtradeb/apps` PPA, which times out from the GitHub Actions runner
and breaks the pkgdown build. The rest of the data-raw stack is in
Suggests so package maintainers get them automatically.

If you need to start the events scrape from scratch, delete
`data-raw/cache/events/` first. Otherwise the scraper resumes from wherever
the last run left off.

## Schema drift

GVP rebuilds its site periodically. If a column rename causes a build
failure:

* For `volcanoes.R` / `eruptions.R`, the rename block at the top of each
  script is the only thing that should need to change. Inspect the WFS CSV
  header by hitting the URL in a browser.
* For `events.R`, the table selector inside `scrape_one()`
  (`div#EruptiveHistory table`) is the most likely thing to drift, since it
  depends on the GVP HTML markup.

## Politeness

GVP runs on a small budget. Please don't run the events scraper more than
monthly (GVP itself releases roughly monthly), and keep the 3-second delay
between page fetches. Cite GVP in any downstream work — see the package
README.

# Build data/volcanoes.rda from the GVP WFS endpoint.
#
# Source: https://webservices.volcano.si.edu/geoserver/GVP-VOTW/wfs
#         layer GVP-VOTW:Smithsonian_VOTW_Holocene_Volcanoes
#
# The WFS endpoint is a separate hostname from volcano.si.edu and is not
# behind Cloudflare, so a plain HTTPS request works.

library(readr)
library(janitor)
library(dplyr)
library(tibble)

wfs_url <- paste0(
  "https://webservices.volcano.si.edu/geoserver/GVP-VOTW/wfs",
  "?service=WFS&version=2.0.0&request=GetFeature",
  "&typeNames=GVP-VOTW:Smithsonian_VOTW_Holocene_Volcanoes",
  "&outputFormat=csv"
)

raw <- read_csv(wfs_url, show_col_types = FALSE)

volcanoes <- raw |>
  clean_names() |>
  select(-fid, -geo_location) |>
  rename(
    tectonic_settings = tectonic_setting,
    dominant_rock_type = major_rock_type
  ) |>
  mutate(
    volcano_number = as.integer(volcano_number),
    across(c(latitude, longitude, elevation), as.numeric)
  ) |>
  arrange(volcano_number) |>
  as_tibble()

usethis::use_data(volcanoes, overwrite = TRUE)

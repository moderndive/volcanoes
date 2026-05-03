# Build data/eruptions.rda from the GVP WFS endpoint.
#
# Source: https://webservices.volcano.si.edu/geoserver/GVP-VOTW/wfs
#         layer GVP-VOTW:Smithsonian_VOTW_Holocene_Eruptions

library(readr)
library(janitor)
library(dplyr)
library(tibble)

wfs_url <- paste0(
  "https://webservices.volcano.si.edu/geoserver/GVP-VOTW/wfs",
  "?service=WFS&version=2.0.0&request=GetFeature",
  "&typeNames=GVP-VOTW:Smithsonian_VOTW_Holocene_Eruptions",
  "&outputFormat=csv"
)

raw <- read_csv(wfs_url, show_col_types = FALSE)

eruptions <- raw |>
  clean_names() |>
  select(-fid, -geo_location) |>
  # Drop the modifier / uncertainty columns to mirror the TidyTuesday
  # 2020-05-12 cleaning.
  select(-matches("modifier$"), -matches("uncertainty$")) |>
  # Rename to match the TidyTuesday column names where GVP uses different
  # wording in the WFS export.
  rename(
    eruption_category = activity_type,
    vei = explosivity_index_max,
    area_of_activity = activity_area,
    evidence_method_dating = start_evidence_method,
    start_year = start_date_year,
    start_month = start_date_month,
    start_day = start_date_day,
    end_year = end_date_year,
    end_month = end_date_month,
    end_day = end_date_day
  ) |>
  mutate(
    volcano_number = as.integer(volcano_number),
    eruption_number = as.integer(eruption_number),
    vei = as.integer(vei),
    across(c(start_year, end_year), as.integer),
    across(c(start_month, start_day, end_month, end_day), as.integer)
  ) |>
  arrange(volcano_number, eruption_number) |>
  as_tibble()

usethis::use_data(eruptions, overwrite = TRUE)

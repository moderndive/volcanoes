# Rebuild all three datasets from the GVP spreadsheets in data-raw/source/.
# See data-raw/README.md for how to download the source files.

source("data-raw/volcanoes.R")
source("data-raw/eruptions.R")
source("data-raw/events.R")

message(sprintf(
  "Built: volcanoes (%d rows), eruptions (%d rows), events (%d rows)",
  nrow(volcanoes), nrow(eruptions), nrow(events)
))

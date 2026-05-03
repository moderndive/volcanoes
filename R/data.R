#' Holocene volcanoes
#'
#' One row per volcano with at least one known Holocene eruption, sourced from
#' the Smithsonian Institution's Global Volcanism Program "Volcanoes of the
#' World" database.
#'
#' @format A tibble with one row per volcano. Columns include:
#' \describe{
#'   \item{volcano_number}{Integer. GVP unique volcano identifier.}
#'   \item{volcano_name}{Character. Volcano name.}
#'   \item{primary_volcano_type}{Character. Morphological classification
#'     (e.g. stratovolcano, shield, caldera).}
#'   \item{last_eruption_year}{Character. Year of the most recently confirmed
#'     eruption, or `"Unknown"` for volcanoes with only undated activity.}
#'   \item{country}{Character. Country containing the volcano.}
#'   \item{region}{Character. GVP geographic region.}
#'   \item{subregion}{Character. GVP geographic subregion.}
#'   \item{latitude, longitude}{Numeric. WGS84 decimal degrees.}
#'   \item{elevation}{Numeric. Summit elevation in meters above sea level.}
#'   \item{tectonic_settings}{Character. Plate tectonic context and crustal
#'     type.}
#'   \item{evidence_category}{Character. GVP evidence classification for
#'     activity (e.g. "Eruption Observed", "Eruption Dated").}
#'   \item{dominant_rock_type}{Character. Primary rock composition where
#'     reported.}
#' }
#'
#' Additional columns from the GVP export are retained verbatim with names
#' standardized via [janitor::make_clean_names()].
#'
#' @source Smithsonian Institution, Global Volcanism Program. *Volcanoes of
#'   the World*. <https://volcano.si.edu/volcanolist_holocene.cfm>
"volcanoes"

#' Volcanic eruptions
#'
#' One row per eruption recorded by the Global Volcanism Program. Each
#' eruption belongs to a single volcano (`volcano_number`) and may comprise
#' many [events][events].
#'
#' @format A tibble with one row per eruption. Columns include:
#' \describe{
#'   \item{volcano_number}{Integer. GVP volcano identifier; joins to
#'     [volcanoes].}
#'   \item{volcano_name}{Character.}
#'   \item{eruption_number}{Integer. GVP unique eruption identifier; joins to
#'     [events].}
#'   \item{eruption_category}{Character. Confirmation status (e.g. "Confirmed
#'     Eruption", "Uncertain Eruption", "Discredited Eruption").}
#'   \item{area_of_activity}{Character. Named vent or sub-area within the
#'     volcano, when reported.}
#'   \item{vei}{Numeric. Volcanic Explosivity Index, 0--8.}
#'   \item{start_year, start_month, start_day}{Numeric. Eruption start date.}
#'   \item{end_year, end_month, end_day}{Numeric. Eruption end date, where
#'     known.}
#'   \item{evidence_method_dating}{Character. Method used to date the
#'     eruption.}
#'   \item{latitude, longitude}{Numeric. WGS84 decimal degrees of the active
#'     vent.}
#' }
#'
#' Modifier and uncertainty columns from the raw GVP export are dropped during
#' the build, matching the rfordatascience/tidytuesday 2020-05-12 layout.
#'
#' @source Smithsonian Institution, Global Volcanism Program.
#'   <https://volcano.si.edu/search_eruption_results.cfm>
"eruptions"

#' Eruption events
#'
#' One row per event observed during an eruption — for example a lava flow,
#' pyroclastic surge, lahar, or ash plume. Many events typically belong to a
#' single eruption.
#'
#' @format A tibble with one row per event. Columns include:
#' \describe{
#'   \item{volcano_number}{Integer. Joins to [volcanoes].}
#'   \item{volcano_name}{Character.}
#'   \item{eruption_number}{Integer. Joins to [eruptions].}
#'   \item{eruption_start_year}{Numeric. Start year of the parent eruption.}
#'   \item{event_number}{Integer. GVP unique event identifier.}
#'   \item{event_type}{Character. Event classification.}
#'   \item{event_remarks}{Character. Free-text notes from GVP.}
#'   \item{event_date_year, event_date_month, event_date_day}{Integer. Date
#'     the event was observed.}
#' }
#'
#' @source Smithsonian Institution, Global Volcanism Program.
#'   <https://volcano.si.edu/search_event_results.cfm>
"events"

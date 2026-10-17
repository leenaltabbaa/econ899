# Configuration file: sourced at the start of every program (except 00_setup.R).
# This is the ONLY file a user should need to edit.
#
# Folder locations ---------------------------------------------------------------
# By default the repo is the current working directory, which is what you get when
# you open econ899.Rproj in RStudio. If you run the code another way, replace
# getwd() with the full path to this repo, e.g. "~/Documents/GitHub/econ899".
myrepo <- getwd()

if (!file.exists(file.path(myrepo, "programs", "config.R"))) {
  stop("Cannot find the repo at '", myrepo, "'. Open econ899.Rproj in RStudio, ",
       "or edit `myrepo` in programs/config.R.")
}
programs_dir <- file.path(myrepo, "programs")
raw_dir      <- file.path(myrepo, "data", "raw_data")
clean_dir    <- file.path(myrepo, "data", "data_for_analysis")
results_dir  <- file.path(myrepo, "results")
for (d in c(clean_dir, results_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# Packages -----------------------------------------------------------------------
# Installed by 00_setup.R.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(did)
})

# Random seed: did uses a bootstrap for standard errors, so fix the seed to make
# reported standard errors reproducible.
analysis_seed <- 20261013

# Study design constants ---------------------------------------------------------
panel_start     <- as.Date("2020-01-01")  # first month of the panel
panel_end       <- as.Date("2026-10-01")  # month of the regulation web search
search_date     <- as.Date("2026-10-13")  # date the web search was completed
year_only_month <- 7L                     # month assigned to year-only dates
main_anticipation <- 3L                   # months of anticipation in the main spec

# Shared helpers -----------------------------------------------------------------
# Month number with January 2020 = 1
month_index <- function(d) (as.integer(format(d, "%Y")) - 2020L) * 12L + as.integer(format(d, "%m"))

# State names <-> two-letter codes
state_lookup <- tibble(state_name = c(state.name, "District of Columbia"),
                       state_abb  = c(state.abb, "DC"))
to_abb <- function(x) {
  out <- state_lookup$state_abb[match(x, state_lookup$state_name)]
  if_else(is.na(out) & x %in% state_lookup$state_abb, x, out)
}

# County name key: "Weld County", "Weld", "Caddo Parish" -> "weld", "caddo"
norm_county <- function(x) {
  x %>% str_to_lower() %>% str_squish() %>%
    str_remove("\\s+(county|parish|borough|city and borough|census area|municipality)$") %>%
    str_squish()
}

read_chr <- function(f) read_csv(f, col_types = cols(.default = col_character()), na = c("", "NA"))

# Significance stars from a normal approximation
stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

theme_paper <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")
col_main <- "#1f5fa8"; col_second <- "#d9822b"; col_pre <- "grey40"

CONFIG_LOADED <- TRUE

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

# Figure style, matching the tables: Times New Roman, black text, white background, black axes, light
# horizontal grid lines only, legend below. Figures are saved at the paper's text width
# (fig_width inches) so the text prints at its real size.
theme_paper <- theme_classic(base_size = 10, base_family = "Times New Roman") +
  theme(panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.3),
        axis.line = element_line(colour = "black", linewidth = 0.3),
        axis.ticks = element_line(colour = "black", linewidth = 0.3),
        axis.text = element_text(colour = "black"),
        strip.background = element_blank(), strip.text = element_text(face = "plain"),
        text = element_text(colour = "black"),
        plot.title = element_text(face = "plain", size = 11, hjust = 0.5),
        plot.title.position = "plot",
        legend.position = "bottom", legend.key.width = unit(1.5, "lines"))
col_main <- "#1f4e79"; col_second <- "#c55a11"; col_pre <- "grey55"
fig_width <- 6.5

# Shared look of the event-study figures (Figure 3 and Figure A3), following the usual
# conventions: event time on the x axis, a line at zero, a dashed line at the
# announcement, a shaded anticipation window and pointwise-style error bars.
# `bands` holds one row per panel with its anticipation window and the overall ATT text.
event_study_layers <- function(bands) {
  list(
    geom_rect(data = bands, aes(xmin = -anticipation - 0.5, xmax = -0.5, ymin = -Inf, ymax = Inf),
              inherit.aes = FALSE, fill = "grey92"),
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3),
    geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey40", linewidth = 0.3),
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.4, linewidth = 0.3, colour = col_main),
    geom_point(shape = 21, size = 1.4, stroke = 0.4, colour = col_main, fill = "white"),
    geom_text(data = bands, aes(x = Inf, y = -Inf, label = att_text), inherit.aes = FALSE,
              hjust = 1.05, vjust = -0.6, size = 2.8, family = "Times New Roman"),
    scale_x_continuous(breaks = seq(-12, 24, 6)),
    scale_y_continuous(labels = function(x) 100 * x),
    labs(x = "Months since first major announcement",
         y = "Effect on chance a regulation\nis in force (percentage points)")
  )
}
att_text <- function(att, se) sprintf("Overall effect: %.1f pp (SE %.1f)", 100 * att, 100 * se)

# Word (.docx) versions of the tables
source(file.path(programs_dir, "word_tables.R"))

CONFIG_LOADED <- TRUE

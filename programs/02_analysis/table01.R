# Table 1: summary statistics for the county-month panel.
#
# Input:  data/data_for_analysis/county_units.csv, county_month_panel.csv
# Output: results/Table01.csv, results/Table01.txt

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
stopifnot(nrow(units) == 232)

# County-level outcomes at the end of the panel (October 2026)
end <- panel %>% filter(period == max(period))
pct <- function(x) sprintf("%.1f", 100 * mean(x))
ann_year <- format(units$first_major_month, "%Y")

table01 <- tribble(
  ~Variable, ~Value,
  "Panel",                                                       "",
  "  Counties",                                                  as.character(nrow(units)),
  "  Months (January 2020 to October 2026)",                     as.character(n_distinct(panel$period)),
  "  County-month observations",                                 format(nrow(panel), big.mark = ","),
  "First major announcement (counties)",                         "",
  "  2020-2023",                                                 as.character(sum(ann_year <= "2023")),
  "  2024",                                                      as.character(sum(ann_year == "2024")),
  "  2025",                                                      as.character(sum(ann_year == "2025")),
  "  2026 (through October)",                                    as.character(sum(ann_year == "2026")),
  "  Date known only to the year (%)",                           pct(units$announce_precision == "year"),
  "Has adopted a rule by October 2026 (% of counties)",          "",
  "  Any rule, county or municipality",                          pct(end$reg_any_any),
  "    Permanent",                                               pct(end$reg_perm_any),
  "    Temporary (moratorium)",                                  pct(end$reg_temp_any),
  "  County-government rule",                                    pct(end$reg_any_cgov),
  "Share of county-months with a rule in force (%)",             pct(panel$reg_any_any),
  "First rule before first major announcement (counties)",       as.character(sum(units$reg_before_announce_any)),
  "Months from announcement to first rule, median",
    as.character(median(units$months_announce_to_first_reg_any[!units$reg_before_announce_any], na.rm = TRUE))
)

write_csv(table01, file.path(results_dir, "Table01.csv"))
writeLines(c("Table 1: Summary statistics", "",
             sprintf("%-62s %10s", table01$Variable, table01$Value)),
           file.path(results_dir, "Table01.txt"))

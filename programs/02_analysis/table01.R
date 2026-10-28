# Table 1: summary statistics for the county-month panel.
#
# Input:  data/data_for_analysis/county_units.csv, county_month_panel.csv
# Output: results/Table 1 - Summary statistics.csv, .txt and .docx

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
stopifnot(nrow(units) == 232)

# County-level outcomes at the end of the panel (October 2026)
end <- panel %>% filter(period == max(period))
pct <- function(x) sprintf("%.1f", 100 * mean(x))
ann_year <- format(units$first_major_month, "%Y")

# Grouped as the course slides suggest: outcomes, treatment, then sample size
table01 <- tribble(
  ~Variable, ~Value,
  "A. Outcomes: regulation adopted by October 2026 (% of counties)",   "",
  "  Any regulation, county or municipality",                          pct(end$reg_any_any),
  "    Permanent",                                               pct(end$reg_perm_any),
  "    Temporary (moratorium)",                                  pct(end$reg_temp_any),
  "    Excluding mixed-direction regulations",                         pct(end$reg_any_nomixed),
  "  County-government regulation",                                    pct(end$reg_any_cgov),
  "  County-months with any regulation in force (%)",                  pct(panel$reg_any_any),
  "B. Treatment: first major announcement (counties)",           "",
  "  2020-2023",                                                 as.character(sum(ann_year <= "2023")),
  "  2024",                                                      as.character(sum(ann_year == "2024")),
  "  2025",                                                      as.character(sum(ann_year == "2025")),
  "  2026 (through July)",                                       as.character(sum(ann_year == "2026")),
  "  Date known only to the year (%)",                           pct(units$announce_precision == "year"),
  "  First regulation before the announcement (counties)",             as.character(sum(units$reg_before_announce_any)),
  "  Months from announcement to first regulation (median)",
    as.character(median(units$months_announce_to_first_reg_any[!units$reg_before_announce_any], na.rm = TRUE)),
  "C. Sample",                                                   "",
  "  Counties",                                                  as.character(nrow(units)),
  "  Months (January 2020 to October 2026)",                     as.character(n_distinct(panel$period)),
  "  County-month observations",                                 format(nrow(panel), big.mark = ",")
)

write_csv(table01, file.path(results_dir, "Table 1 - Summary statistics.csv"))
writeLines(c("Table 1: Summary statistics", "",
             sprintf("%-62s %10s", table01$Variable, table01$Value)),
           file.path(results_dir, "Table 1 - Summary statistics.txt"))
word_table(rename(table01, ` ` = Variable, `All panel counties` = Value),
           file.path(results_dir, "Table 1 - Summary statistics.docx"),
           title = "Table 1: Summary statistics", align_values = "right",
           notes = paste("Notes: Counties whose first major data center announcement (at least 450 MW or",
                         "$3 billion, from Server Country) is in January 2020 or later. Regulations are adopted local",
                         "data center regulations from the FAS ordinance database and a web search through",
                         "October 13, 2026, assigned to the county that contains the adopting government",
                         "(the county itself or a city or township in it). Temporary regulations are moratoria and",
                         "similar pauses. Mixed-direction regulations are those coded as both restricting and easing",
                         "data center development. Announcements with only a year known are placed in July."))

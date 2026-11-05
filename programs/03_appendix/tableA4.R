# Table A4: two-way fixed effects (TWFE) estimates, next to the Callaway-Sant'Anna estimates
# from Table 2. TWFE is one regression per outcome on all county-months:
#   y_ct = beta * Post_ct + county fixed effect + month fixed effect + error,
# where Post_ct = 1 from county c's first major announcement onward. Standard errors are
# clustered by county. With staggered announcements TWFE also uses already-announced counties
# as comparisons, which can bias beta when effects grow over time; this is the comparison
# Callaway-Sant'Anna avoids.
#
# Input:  data/data_for_analysis/county_month_panel.csv,
#         results/estimates/did_estimates_summary.csv (from estimates.R)
# Output: results/Table A4 - Two-way fixed effects.csv, .txt and .docx

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
stopifnot(nrow(panel) == 19024, all(panel$post_announce == (panel$period >= panel$first_major_period)))

est <- read_csv(file.path(results_dir, "estimates", "did_estimates_summary.csv"), show_col_types = FALSE)
cols <- c("main", "county_gov", "permanent", "temporary")
est <- est[match(cols, est$name), ]
stopifnot(!anyNA(est$att))

twfe <- lapply(est$outcome, function(y) {
  m <- fixest::feols(as.formula(paste(y, "~ post_announce | unit_id + period")), data = panel,
                     cluster = ~unit_id)
  tibble(outcome = y, twfe = unname(coef(m)["post_announce"]),
         twfe_se = unname(fixest::se(m)["post_announce"]),
         r2 = unname(fixest::r2(m, "r2")), n_obs = nobs(m), mean_y = mean(panel[[y]]))
}) %>% bind_rows()
stopifnot(twfe$n_obs == 19024)

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
tableA4 <- tibble(Row = c("Two-way fixed effects", "", "Callaway-Sant'Anna (Table 2)", "",
                          "Mean of dependent variable", "R-squared (two-way fixed effects)", "Counties",
                          "Observations (county-months)"))
for (j in seq_along(cols)) {
  tableA4[[est$name[j]]] <- c(paste0(fmt(twfe$twfe[j]), stars(twfe$twfe[j], twfe$twfe_se[j])),
                              paste0("(", fmt(twfe$twfe_se[j]), ")"),
                              paste0(fmt(est$att[j]), stars(est$att[j], est$se[j])),
                              paste0("(", fmt(est$se[j]), ")"),
                              fmt(twfe$mean_y[j]), fmt(twfe$r2[j]), as.character(n_distinct(panel$unit_id)),
                              format(twfe$n_obs[j], big.mark = ","))
}
names(tableA4) <- c(" ", "Any regulation", "County government", "Permanent", "Temporary")

notes <- c(paste("Notes: The first row is from one regression per column on all county-months:",
                 "the outcome on an indicator equal to 1 from the county's first major data center",
                 "announcement onward, with county and month fixed effects and no other controls. The",
                 "second row repeats the Callaway and Sant'Anna (2021) estimates from Table 2",
                 "(not-yet-treated comparison group, 3 months of anticipation). The sample is the 232 counties whose",
                 "first major announcement is between January 2020 and July 2026, observed monthly from",
                 "January 2020 to October 2026. Outcomes as in Table 2. Two-way fixed effects standard errors",
                 "are clustered by county; Callaway-Sant'Anna standard errors are from the multiplier bootstrap,",
                 "clustered by county. With staggered announcements, two-way fixed effects also compares",
                 "newly announcing counties with counties that announced earlier, which can bias the",
                 "estimate downward when effects grow over time."),
           "* p<0.10, ** p<0.05, *** p<0.01.")

write_csv(tableA4, file.path(results_dir, "Table A4 - Two-way fixed effects.csv"))
writeLines(c("Table A4: Two-way fixed effects and Callaway-Sant'Anna estimates", "",
             local({ old <- options(width = 200); on.exit(options(old))
               capture.output(print(as.data.frame(tableA4), row.names = FALSE, right = FALSE)) }), "",
             strwrap(notes[1], 100), notes[2]),
           file.path(results_dir, "Table A4 - Two-way fixed effects.txt"))
word_table(tableA4, file.path(results_dir, "Table A4 - Two-way fixed effects.docx"),
           title = "Table A4: Two-way fixed effects and Callaway-Sant'Anna estimates",
           spanner = "Dependent variable: data center regulation in force (0/1)", numbered = TRUE,
           se_rows = c(2, 4), bottom_rows = 5:8, notes = notes)

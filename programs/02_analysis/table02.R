# Table 2: effect of a county's first major data-centre announcement on the probability
# that a data-centre rule is in force (Callaway-Sant'Anna DiD, not-yet-treated comparison).
# Columns: (1) any rule by the county or a municipality in it (main), (2) county-government
# rules only, (3) permanent rules only, (4) temporary rules only.
#
# Input:  results/estimates/did_estimates_summary.csv (from estimates.R)
# Output: results/Table 2 - Main results.csv, .txt and .docx

if (!exists("CONFIG_LOADED")) source("programs/config.R")

est <- read_csv(file.path(results_dir, "estimates", "did_estimates_summary.csv"), show_col_types = FALSE)
cols <- c("main", "county_gov", "permanent", "temporary")
est <- est[match(cols, est$name), ]
stopifnot(!anyNA(est$att))

# Mean of each dependent variable over all county-months, to judge the size of the effects
panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
outcome_mean <- sapply(c("reg_any_any", "reg_any_cgov", "reg_perm_any", "reg_temp_any"),
                       function(v) mean(panel[[v]]))

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
table02 <- tibble(
  Row = c("Announcement effect (ATT)", "", "Event-study average effect", "",
          "Pre-announcement average (months -12 to -4)", "",
          "Mean of dependent variable", "Anticipation (months)", "Counties", "County-months",
          "Treatment cohorts (months)"),
  `(1) Any regulation` = NA_character_, `(2) County government` = NA_character_,
  `(3) Permanent` = NA_character_, `(4) Temporary` = NA_character_
)
for (j in seq_along(cols)) {
  e <- est[j, ]
  table02[[j + 1]] <- c(paste0(fmt(e$att), stars(e$att, e$se)), paste0("(", fmt(e$se), ")"),
                        paste0(fmt(e$es_att), stars(e$es_att, e$es_se)), paste0("(", fmt(e$es_se), ")"),
                        paste0(fmt(e$pre_att), stars(e$pre_att, e$pre_se)), paste0("(", fmt(e$pre_se), ")"),
                        fmt(outcome_mean[j]), as.character(e$anticipation), as.character(e$n_counties),
                        format(e$n_obs, big.mark = ","), as.character(e$n_cohorts))
}
notes <- c("Notes: Callaway and Sant'Anna (2021) estimates with not-yet-treated counties as the comparison",
           "group. The outcome equals 1 from the month a regulation of the stated type is first adopted. Standard",
           "errors (in parentheses) from the multiplier bootstrap, clustered by county. The pre-announcement",
           "average is the mean event-study estimate over months -12 to -4 before the announcement (a test",
           "for pre-trends; analytical standard error). No control variables. The mean of the dependent",
           "variable is the share of all county-months with a regulation of that type in force.",
           "* p<0.10, ** p<0.05, *** p<0.01.")

write_csv(table02, file.path(results_dir, "Table 2 - Main results.csv"))
writeLines(c("Table 2: Effect of a first major data-centre announcement on local regulation", "",
             paste(sprintf("%-46s", names(table02)[1]), paste(sprintf("%22s", names(table02)[-1]), collapse = "")),
             apply(table02, 1, function(r) paste(sprintf("%-46s", r[1]), paste(sprintf("%22s", r[-1]), collapse = ""))),
             "", notes),
           file.path(results_dir, "Table 2 - Main results.txt"))

word_rows <- estimate_rows(est)
word_rows$Row[5] <- "Pre-announcement average (months -12 to -4)"
word_rows <- bind_rows(word_rows[1:6, ],
                       as_tibble(as.list(c(Row = "Mean of dependent variable", setNames(fmt(outcome_mean), est$name)))),
                       word_rows[7:10, ])
names(word_rows) <- c(" ", "Any regulation", "County government", "Permanent", "Temporary")
word_table(word_rows, file.path(results_dir, "Table 2 - Main results.docx"),
           title = "Table 2: Effect of a first major data center announcement on local regulation",
           spanner = "Dependent variable: data center regulation in force (0/1)", numbered = TRUE,
           se_rows = c(2, 4, 6), bottom_rows = 7:11,
           notes = c(paste(sub("^Notes: ", "", head(notes, -1)), collapse = " ") %>% paste("Notes:", .),
                     tail(notes, 1)))

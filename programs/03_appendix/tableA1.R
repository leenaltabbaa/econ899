# Table A1: robustness of the main estimate to alternative outcome definitions,
# anticipation windows and samples.
#
# Input:  results/estimates/did_estimates_summary.csv (from 02_analysis/estimates.R)
# Output: results/TableA1.csv, results/TableA1.txt

if (!exists("CONFIG_LOADED")) source("programs/config.R")

est <- read_csv(file.path(results_dir, "estimates", "did_estimates_summary.csv"), show_col_types = FALSE)
rows <- c("main", "no_mixed", "antic_0", "antic_6", "month_dates")
est <- est[match(rows, est$name), ]
stopifnot(!anyNA(est$att))

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
tableA1 <- est %>%
  transmute(Specification = label,
            Anticipation = anticipation,
            ATT = paste0(fmt(att), stars(att, se)),
            SE = paste0("(", fmt(se), ")"),
            `Event-study avg.` = paste0(fmt(es_att), stars(es_att, es_se)),
            `Pre-period avg.` = paste0(fmt(pre_att), stars(pre_att, pre_se)),
            `Pre SE` = paste0("(", fmt(pre_se), ")"),
            Counties = n_counties,
            `County-months` = n_obs)

write_csv(tableA1, file.path(results_dir, "TableA1.csv"))
writeLines(c("Table A1: Robustness checks", "",
             local({ old <- options(width = 200); on.exit(options(old))
               capture.output(print(as.data.frame(tableA1), row.names = FALSE, right = FALSE)) }), "",
             "Notes: Outcome is any data-centre rule by the county or a municipality in it, except where",
             "stated. Standard errors from the multiplier bootstrap, clustered by county. Pre-period avg. is",
             "the mean event-study estimate over months -12 to -(anticipation + 1) before the announcement.",
             "Counties are those used by did, which drops counties already treated in the first month",
             "once anticipation is allowed for.",
             "* p<0.10, ** p<0.05, *** p<0.01."),
           file.path(results_dir, "TableA1.txt"))

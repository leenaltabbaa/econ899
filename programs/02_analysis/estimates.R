# Estimates every difference-in-differences model used in the paper and appendix,
# and saves them for the table and figure programs.
#
# Estimator: Callaway and Sant'Anna (2021), did package. Unit = county, time = month,
# treatment = month of the county's first major data-centre announcement. Comparison
# group = counties not yet treated. Standard errors: multiplier bootstrap clustered by
# county (did defaults). The main specification allows 3 months of anticipation.
#
# Input:  data/data_for_analysis/county_month_panel.csv
# Output: results/estimates/did_estimates.rds

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
stopifnot(n_distinct(panel$unit_id) == 232, nrow(panel) == 232 * 82)

specs <- tribble(
  ~name,         ~label,                                ~yname,            ~anticipation,     ~sample,
  "main",        "Any regulation, county or municipality",    "reg_any_any",     main_anticipation, "all",
  "county_gov",  "County-government regulations only",        "reg_any_cgov",    main_anticipation, "all",
  "permanent",   "Permanent regulations only",                "reg_perm_any",    main_anticipation, "all",
  "temporary",   "Temporary regulations only (moratoria)",    "reg_temp_any",    main_anticipation, "all",
  "no_mixed",    "Excluding mixed-direction regulations",     "reg_any_nomixed", main_anticipation, "all",
  "antic_0",     "No anticipation",                     "reg_any_any",     0L,                "all",
  "antic_6",     "Six months of anticipation",          "reg_any_any",     6L,                "all",
  "month_dates", "Excluding year-only announcement dates", "reg_any_any",  main_anticipation, "month_dates"
)

estimate_spec <- function(s) {
  d <- if (s$sample == "month_dates") filter(panel, announce_precision == "month") else panel
  set.seed(analysis_seed)
  res <- att_gt(yname = s$yname, tname = "period", idname = "unit_id", gname = "first_major_period",
                data = d, control_group = "notyettreated", anticipation = s$anticipation)
  list(spec = s, att_gt = res,
       simple = aggte(res, type = "simple"),
       dynamic = aggte(res, type = "dynamic", min_e = -12, max_e = 24),
       # Counties actually used by did (it drops counties already treated in the first
       # period once anticipation is allowed for)
       n_counties = res$n, n_obs = res$n * n_distinct(d$period))
}

estimates <- lapply(seq_len(nrow(specs)), function(i) {
  message("  estimating ", specs$name[i])
  estimate_spec(specs[i, ])
})
names(estimates) <- specs$name

# Check the main estimate has not changed (reported in the paper as 0.085)
stopifnot(abs(estimates$main$simple$overall.att - 0.0853) < 5e-4)

dir.create(file.path(results_dir, "estimates"), showWarnings = FALSE)
saveRDS(list(specs = specs, estimates = estimates), file.path(results_dir, "estimates", "did_estimates.rds"))

# Pre-trend check. did's Wald pre-test is not available here (singular covariance
# matrix: the outcome is 0 for almost all counties before treatment), so we report the
# average event-study estimate over the pre-announcement months -12 to -(anticipation + 1),
# with an analytical standard error from did's influence functions.
pre_period_average <- function(e) {
  dyn <- e$dynamic
  pre <- dyn$egt >= -12 & dyn$egt <= -(e$spec$anticipation + 1)
  inf <- dyn$inf.function$dynamic.inf.func.e
  if (!any(pre) || is.null(inf)) return(c(est = NA_real_, se = NA_real_))
  inf_avg <- rowMeans(inf[, pre, drop = FALSE])
  c(est = mean(dyn$att.egt[pre]), se = sqrt(mean(inf_avg^2) / length(inf_avg)))
}

# Tidy summary used by the tables
did_summary <- function(e) {
  pre <- pre_period_average(e)
  tibble(name = e$spec$name, label = e$spec$label, outcome = e$spec$yname,
         anticipation = e$spec$anticipation,
         att = e$simple$overall.att, se = e$simple$overall.se,
         es_att = e$dynamic$overall.att, es_se = e$dynamic$overall.se,
         pre_att = pre[["est"]], pre_se = pre[["se"]],
         pre_p = 2 * pnorm(-abs(pre[["est"]] / pre[["se"]])),
         n_counties = e$n_counties, n_obs = e$n_obs,
         n_cohorts = length(unique(e$att_gt$group)))
}
estimates_table <- bind_rows(lapply(estimates, did_summary))
write_csv(estimates_table, file.path(results_dir, "estimates", "did_estimates_summary.csv"))
message("estimates: main effect = ", sprintf("%.4f (SE %.4f)", estimates$main$simple$overall.att,
                                             estimates$main$simple$overall.se))

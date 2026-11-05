# Figure A6: two-way fixed effects (TWFE) event study next to the Callaway-Sant'Anna event
# study (Figure 3), for the main outcome (any data center regulation).
# TWFE regression on all county-months:
#   y_ct = sum_e beta_e * 1[month c,t is e months from c's announcement] + county FE + month FE,
# with one dummy for each month from -12 to 24, the months before -12 and after 24 grouped into
# one dummy each, and month -4 (the last month before the 3-month anticipation window) and the
# grouped months before -12 left out as the comparison. Standard errors clustered by county.
# Both series show 95% pointwise confidence intervals so they can be compared directly.
#
# Input:  data/data_for_analysis/county_month_panel.csv,
#         results/estimates/did_estimates.rds (from estimates.R)
# Output: results/Figure A6 - Two-way fixed effects event study.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
ref <- -main_anticipation - 1
ev_name <- function(e) ifelse(e < 0, paste0("ev_m", -e), paste0("ev_p", e))
panel <- panel %>% mutate(rel = pmin(pmax(period - first_major_period, -13), 25))
keep <- setdiff(-12:25, ref)                     # -13 (all months before -12) and ref left out
for (e in keep) panel[[ev_name(e)]] <- as.numeric(panel$rel == e)

m <- fixest::feols(as.formula(paste("reg_any_any ~", paste(ev_name(keep), collapse = " + "),
                                    "| unit_id + period")), data = panel, cluster = ~unit_id)
twfe <- tibble(month = keep, att = unname(coef(m)[ev_name(keep)]),
               se = unname(fixest::se(m)[ev_name(keep)])) %>%
  filter(month <= 24) %>%
  bind_rows(tibble(month = ref, att = 0, se = 0)) %>%
  mutate(method = "Two-way fixed effects")
stopifnot(!anyNA(twfe$att))

es <- readRDS(file.path(results_dir, "estimates", "did_estimates.rds"))$estimates$main$dynamic
cs <- tibble(month = es$egt, att = es$att.egt, se = es$se.egt, method = "Callaway-Sant'Anna (Figure 3)")

fig_data <- bind_rows(cs, twfe) %>%
  mutate(lo = att - 1.96 * se, hi = att + 1.96 * se,
         method = factor(method, levels = c("Callaway-Sant'Anna (Figure 3)", "Two-way fixed effects")),
         x = month + ifelse(method == "Two-way fixed effects", 0.22, -0.22))

fig <- ggplot(fig_data, aes(x, att, colour = method)) +
  annotate("rect", xmin = -main_anticipation - 0.5, xmax = -0.5, ymin = -Inf, ymax = Inf, fill = "grey92") +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey40", linewidth = 0.3) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.3, linewidth = 0.3) +
  geom_point(aes(shape = method), size = 1.3, stroke = 0.4, fill = "white") +
  scale_colour_manual(values = c(col_main, col_second), name = NULL) +
  scale_shape_manual(values = c(21, 24), name = NULL) +
  scale_x_continuous(breaks = seq(-12, 24, 6)) +
  scale_y_continuous(labels = function(x) 100 * x) +
  labs(title = "Figure A6: Two-Way Fixed Effects and Callaway-Sant'Anna Event Studies",
       x = "Months since first major announcement",
       y = "Effect on chance a regulation\nis in force (percentage points)") +
  theme_paper
ggsave(file.path(results_dir, "Figure A6 - Two-way fixed effects event study.png"), fig,
       width = fig_width, height = 3.8, dpi = 300)

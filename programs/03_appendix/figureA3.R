# Figure A3: event studies for every specification in Table 2 and Table A1
# (95% simultaneous confidence bands).
#
# Input:  results/estimates/did_estimates.rds (from 02_analysis/estimates.R)
# Output: results/FigureA3.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

saved <- readRDS(file.path(results_dir, "estimates", "did_estimates.rds"))
fig_data <- bind_rows(lapply(saved$estimates, function(e) {
  es <- e$dynamic
  tibble(label = e$spec$label, anticipation = e$spec$anticipation,
         month = es$egt, att = es$att.egt, se = es$se.egt, crit = es$crit.val.egt)
})) %>%
  mutate(lo = att - crit * se, hi = att + crit * se,
         period_type = if_else(month >= -anticipation, "Post (incl. anticipation)", "Pre-announcement"),
         label = factor(label, levels = saved$specs$label))

fig <- ggplot(fig_data, aes(month, att, colour = period_type)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.3) +
  geom_point(size = 1.2) +
  facet_wrap(~ label, ncol = 2) +
  scale_colour_manual(values = c(`Post (incl. anticipation)` = col_main, `Pre-announcement` = col_pre), name = NULL) +
  labs(x = "Months relative to first major announcement",
       y = "Effect on probability of having a rule") + theme_paper
ggsave(file.path(results_dir, "FigureA3.png"), fig, width = 10, height = 12, dpi = 300)

# Figure 2: event study of the effect of a county's first major data-centre announcement
# on the probability that a data-centre rule is in force, by month relative to the
# announcement (main specification, 95% simultaneous confidence bands).
#
# Input:  results/estimates/did_estimates.rds (from estimates.R)
# Output: results/Figure02.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

est <- readRDS(file.path(results_dir, "estimates", "did_estimates.rds"))$estimates$main
es  <- est$dynamic
fig_data <- tibble(month = es$egt, att = es$att.egt, se = es$se.egt) %>%
  mutate(lo = att - es$crit.val.egt * se, hi = att + es$crit.val.egt * se,
         period_type = if_else(month >= -est$spec$anticipation,
                               paste0("From ", est$spec$anticipation, " months before announcement"),
                               "Pre-announcement"))

fig <- ggplot(fig_data, aes(month, att, colour = period_type)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.3) +
  geom_point(size = 1.8) +
  scale_colour_manual(values = c(col_main, col_pre), name = NULL) +
  labs(x = "Months relative to first major announcement",
       y = "Effect on probability of having a rule") + theme_paper
ggsave(file.path(results_dir, "Figure02.png"), fig, width = 9, height = 5, dpi = 300)

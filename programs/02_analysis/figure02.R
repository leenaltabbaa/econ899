# Figure 2: event study of the effect of a county's first major data-centre announcement
# on the probability that a data-centre rule is in force, by month relative to the
# announcement (main specification, 95% simultaneous confidence bands).
#
# Input:  results/estimates/did_estimates.rds (from estimates.R)
# Output: results/Figure 2 - Main event study.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

est <- readRDS(file.path(results_dir, "estimates", "did_estimates.rds"))$estimates$main
es  <- est$dynamic
fig_data <- tibble(month = es$egt, att = es$att.egt, se = es$se.egt) %>%
  mutate(lo = att - es$crit.val.egt * se, hi = att + es$crit.val.egt * se)
bands <- tibble(anticipation = est$spec$anticipation,
                att_text = att_text(est$simple$overall.att, est$simple$overall.se))

fig <- ggplot(fig_data, aes(month, att)) +
  event_study_layers(bands) +
  annotate("text", x = -0.9, y = max(fig_data$hi), label = "Announcement", hjust = 1,
           vjust = 1, size = 2.8, family = "Times New Roman") +
  labs(title = "Figure 2: Main Event Study of Data Center Rules after a Major Announcement") + theme_paper
ggsave(file.path(results_dir, "Figure 2 - Main event study.png"), fig, width = fig_width, height = 3.8, dpi = 300)

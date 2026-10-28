# Figure A3: event studies for every specification in Table 2 and Table A1
# (95% simultaneous confidence bands).
#
# Input:  results/estimates/did_estimates.rds (from 02_analysis/estimates.R)
# Output: results/Figure A3 - Event studies for all specifications.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

saved <- readRDS(file.path(results_dir, "estimates", "did_estimates.rds"))
fig_data <- bind_rows(lapply(saved$estimates, function(e) {
  es <- e$dynamic
  tibble(label = e$spec$label, month = es$egt, att = es$att.egt, se = es$se.egt, crit = es$crit.val.egt)
})) %>%
  mutate(lo = att - crit * se, hi = att + crit * se,
         label = factor(label, levels = saved$specs$label))
bands <- bind_rows(lapply(saved$estimates, function(e) {
  tibble(label = e$spec$label, anticipation = e$spec$anticipation,
         att_text = att_text(e$simple$overall.att, e$simple$overall.se))
})) %>% mutate(label = factor(label, levels = saved$specs$label))

fig <- ggplot(fig_data, aes(month, att)) +
  event_study_layers(bands) +
  facet_wrap(~ label, ncol = 2) +
  labs(title = "Figure A3: Event Studies for the Main Result and Each Robustness Check") + theme_paper
ggsave(file.path(results_dir, "Figure A3 - Event studies for all specifications.png"), fig, width = fig_width, height = 8.5, dpi = 300)

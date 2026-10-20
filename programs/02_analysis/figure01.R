# Figure 1: share of panel counties with a major data-centre announcement and with a
# data-centre rule in force, by calendar month.
#
# Input:  data/data_for_analysis/county_month_panel.csv
# Output: results/Figure 1 - Data center rules over time.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)

fig_data <- panel %>%
  group_by(month) %>%
  summarise(`Major project announced` = mean(post_announce), `Any rule` = mean(reg_any_any),
            `Permanent rule` = mean(reg_perm_any), `Temporary rule` = mean(reg_temp_any)) %>%
  pivot_longer(-month, names_to = "series", values_to = "share") %>%
  mutate(series = factor(series, levels = c("Major project announced", "Any rule",
                                            "Permanent rule", "Temporary rule")))

fig <- ggplot(fig_data, aes(month, share, colour = series, linetype = series)) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = c(col_pre, col_main, "#5b8fd1", col_second), name = NULL) +
  scale_linetype_manual(values = c("dashed", "solid", "solid", "solid"), name = NULL) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = NULL, y = "Share of panel counties") + theme_paper
ggsave(file.path(results_dir, "Figure 1 - Data center rules over time.png"), fig, width = 9, height = 5, dpi = 300)

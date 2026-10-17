# Figure A2: raw share of counties with a data-centre rule in force, by month relative
# to the county's first major announcement (no comparison group; the mix of counties
# changes across event months because the panel ends in October 2026).
#
# Input:  data/data_for_analysis/county_month_panel.csv
# Output: results/FigureA2.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)

fig_data <- panel %>%
  mutate(event_month = period - first_major_period) %>%
  filter(event_month >= -12, event_month <= 24) %>%
  summarise(share = mean(reg_any_any), counties = n(), .by = event_month)

fig <- ggplot(fig_data, aes(event_month, share)) +
  geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey50") +
  geom_line(colour = col_main, linewidth = 0.9) + geom_point(colour = col_main, size = 1.5) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Months relative to first major announcement",
       y = "Share of counties with a rule") + theme_paper
ggsave(file.path(results_dir, "FigureA2.png"), fig, width = 9, height = 5, dpi = 300)

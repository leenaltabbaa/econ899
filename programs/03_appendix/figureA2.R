# Figure A2: raw share of counties with a data-centre rule in force, by month relative
# to the county's first major announcement (no comparison group; the mix of counties
# changes across event months because the panel ends in October 2026).
#
# Input:  data/data_for_analysis/county_month_panel.csv
# Output: results/Figure A2 - Raw share with a rule by months since announcement.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)

fig_data <- panel %>%
  mutate(event_month = period - first_major_period) %>%
  filter(event_month >= -12, event_month <= 24) %>%
  summarise(share = mean(reg_any_any), counties = n(), .by = event_month)

fig <- ggplot(fig_data, aes(event_month, share)) +
  geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey40", linewidth = 0.3) +
  geom_line(colour = col_main, linewidth = 0.6) +
  geom_point(shape = 21, colour = col_main, fill = "white", size = 1.4, stroke = 0.4) +
  annotate("text", x = -0.9, y = max(fig_data$share), label = "Announcement", hjust = 1,
           vjust = 1, size = 2.8, family = "Times New Roman") +
  scale_x_continuous(breaks = seq(-12, 24, 6)) +
  scale_y_continuous(labels = function(x) 100 * x, limits = c(0, NA)) +
  labs(title = "Figure A2: Raw Share of Counties with a Rule in Force by Months since Announcement", x = "Months since first major announcement",
       y = "Share of counties with a\nrule in force (%)") + theme_paper
ggsave(file.path(results_dir, "Figure A2 - Raw share with a rule by months since announcement.png"), fig, width = fig_width, height = 3.8, dpi = 300)

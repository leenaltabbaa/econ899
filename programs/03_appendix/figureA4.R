# Figure A4: number of counties that can be followed for each month after their first
# major announcement. Explains why the event-study estimates (Figure 3) get less precise
# at longer horizons: most announcements are recent, so few counties are observed for long.
#
# Input:  data/data_for_analysis/county_units.csv, county_month_panel.csv
# Output: results/Figure A4 - Counties observed by months since announcement.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)
last_period <- max(panel$period)

# A county announced in period g is observed e months later if g + e is within the panel
fig_data <- tibble(month = 0:24) %>%
  mutate(counties = sapply(month, function(e) sum(units$first_major_period + e <= last_period)))
labelled <- fig_data %>% filter(month %% 6 == 0)

fig <- ggplot(fig_data, aes(month, counties)) +
  geom_col(fill = col_main, width = 0.75) +
  geom_text(data = labelled, aes(label = counties), vjust = -0.4, size = 2.8, family = "Times New Roman") +
  scale_x_continuous(breaks = seq(0, 24, 6)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = "Figure A4: Counties Observed by Months since Announcement",
       x = "Months since first major announcement",
       y = "Counties observed\n(number)") + theme_paper
ggsave(file.path(results_dir, "Figure A4 - Counties observed by months since announcement.png"), fig,
       width = fig_width, height = 3.4, dpi = 300)

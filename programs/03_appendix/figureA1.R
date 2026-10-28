# Figure A1: number of counties with their first major data-centre announcement, by month.
#
# Input:  data/data_for_analysis/county_units.csv
# Output: results/Figure A1 - Announcements by month.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)

fig <- units %>% count(first_major_month) %>%
  ggplot(aes(first_major_month, n)) +
  geom_col(fill = col_main, width = 25) +
  scale_x_date(breaks = seq(as.Date("2020-01-01"), as.Date("2026-01-01"), by = "1 year"), date_labels = "%Y") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Figure A1: Major Data Center Announcements by Month from 2020 to 2026", x = "Month of first major announcement", y = "Counties with their first major\nannouncement (number)") + theme_paper
ggsave(file.path(results_dir, "Figure A1 - Announcements by month.png"), fig, width = fig_width, height = 3.4, dpi = 300)

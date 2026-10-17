# Figure A1: number of counties with their first major data-centre announcement, by month.
#
# Input:  data/data_for_analysis/county_units.csv
# Output: results/FigureA1.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)

fig <- units %>% count(first_major_month) %>%
  ggplot(aes(first_major_month, n)) +
  geom_col(fill = col_main, width = 25) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = NULL, y = "Counties with first major announcement") + theme_paper
ggsave(file.path(results_dir, "FigureA1.png"), fig, width = 9, height = 4.5, dpi = 300)

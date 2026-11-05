# Figure A5: how the comparison group is formed, for one real cohort (the July 2024 cohort).
# Each bar is all panel counties at a given number of months after July 2024, split into
# counties that announced earlier (never comparisons), the cohort itself, counties dropped
# because they announced since then or within the anticipation window, and not-yet-treated
# comparison counties. Shows why the comparison group shrinks at longer horizons.
#
# Input:  data/data_for_analysis/county_units.csv
# Output: results/Figure A5 - Comparison group for the July 2024 cohort.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
cohort <- (2024 - 2020) * 12 + 7   # July 2024 = period 55 (period 1 = January 2020)
stopifnot(sum(units$first_major_period == cohort) == 9)

# At month e after the cohort's announcement (period t = cohort + e), a county is a comparison
# if it has not announced by t + anticipation, as in did's not-yet-treated control group
groups <- c("Announced earlier (left out)", "July 2024 cohort",
            "Announced since, or within 3 months (dropped)", "Not yet announced (comparison)")
fig_data <- expand_grid(month = seq(0, 24, 6), g = units$first_major_period) %>%
  mutate(group = case_when(g < cohort ~ groups[1],
                           g == cohort ~ groups[2],
                           g <= cohort + month + main_anticipation ~ groups[3],
                           TRUE ~ groups[4]),
         group = factor(group, levels = rev(groups))) %>%
  count(month, group, .drop = FALSE) %>%
  mutate(row = factor(paste0("Month ", month, "\n", format(seq(as.Date("2024-07-01"), by = "month", length.out = 25)[month + 1], "%b %Y")),
                      levels = rev(paste0("Month ", seq(0, 24, 6), "\n",
                                          format(seq(as.Date("2024-07-01"), by = "month", length.out = 25)[seq(0, 24, 6) + 1], "%b %Y")))))
controls <- fig_data %>% filter(group == groups[4])
stopifnot(controls$n == c(190, 162, 116, 38, 0))

fig <- ggplot(fig_data, aes(x = n, y = row, fill = group)) +
  geom_col(width = 0.65, colour = "white", linewidth = 0.2) +
  geom_text(aes(label = ifelse(n >= 9, n, ""), group = group, colour = group %in% groups[c(2, 4)]),
            position = position_stack(vjust = 0.5), size = 2.8, family = "Times New Roman",
            show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black")) +
  geom_text(data = controls, aes(x = nrow(units) + 4, y = row, label = paste(n, "comparison\ncounties")),
            hjust = 0, size = 2.8, lineheight = 0.9, family = "Times New Roman", inherit.aes = FALSE) +
  scale_fill_manual(values = setNames(c("grey80", col_main, "#f4c7a1", col_second), groups),
                    breaks = groups, name = NULL) +
  scale_x_continuous(limits = c(0, nrow(units) + 45), breaks = seq(0, 200, 50), expand = c(0, 0)) +
  guides(fill = guide_legend(nrow = 2)) +
  labs(title = "Figure A5: Comparison Group for the July 2024 Cohort by Months since Announcement",
       x = "Counties (number)", y = NULL) +
  theme_paper + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3),
                      axis.ticks.y = element_blank())
ggsave(file.path(results_dir, "Figure A5 - Comparison group for the July 2024 cohort.png"), fig,
       width = fig_width, height = 3.8, dpi = 300)

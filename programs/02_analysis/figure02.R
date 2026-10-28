# Figure 2: share of panel counties with a major data-centre announcement and with a
# data-centre rule in force, by calendar month.
#
# Input:  data/data_for_analysis/county_month_panel.csv
# Output: results/Figure 2 - Data center regulations over time.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

panel <- read_csv(file.path(clean_dir, "county_month_panel.csv"), show_col_types = FALSE)

fig_data <- panel %>%
  group_by(month) %>%
  summarise(`Major project announced` = mean(post_announce), `Any regulation` = mean(reg_any_any),
            `Permanent regulation` = mean(reg_perm_any), `Temporary regulation` = mean(reg_temp_any)) %>%
  pivot_longer(-month, names_to = "series", values_to = "share") %>%
  mutate(series = factor(series, levels = c("Major project announced", "Any regulation",
                                            "Permanent regulation", "Temporary regulation")))

# Labels at the end of each line instead of a legend; line types as well as colours
# so the figure also reads in black and white.
end_labels <- fig_data %>% filter(month == max(month))

fig <- ggplot(fig_data, aes(month, share, colour = series, linetype = series)) +
  geom_line(linewidth = 0.6) +
  geom_text(data = end_labels, aes(label = series), hjust = 0, nudge_x = 25,
            size = 3, family = "Times New Roman", colour = "black", show.legend = FALSE) +
  scale_colour_manual(values = c(col_pre, col_main, "#5b8fd1", col_second), guide = "none") +
  scale_linetype_manual(values = c("dashed", "solid", "longdash", "dotdash"), guide = "none") +
  scale_y_continuous(labels = function(x) 100 * x, breaks = seq(0, 1, 0.2)) +
  scale_x_date(breaks = seq(as.Date("2020-01-01"), as.Date("2026-01-01"), by = "1 year"), date_labels = "%Y") +
  coord_cartesian(clip = "off") +
  labs(title = "Figure 2: Data Center Regulations from 2020 to 2026", x = NULL, y = "Share of panel counties (%)") + theme_paper +
  theme(plot.margin = margin(5, 120, 5, 5))
# The right margin holds the line labels: stretch the title across the whole figure so
# it is centred on the page rather than over the plotting area only
fig <- ggplotGrob(fig)
title_cell <- fig$layout$name == "title"
fig$layout$l[title_cell] <- 1
fig$layout$r[title_cell] <- ncol(fig)
ggsave(file.path(results_dir, "Figure 2 - Data center regulations over time.png"), fig, width = fig_width, height = 3.8, dpi = 300)

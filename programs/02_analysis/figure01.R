# Figure 1: a simple timeline of what the study measures for each county: the
# anticipation window, the first major announcement (month 0), and a later data center
# regulation (placed at the median gap in the data). Drawn from the panel so the median
# gap updates with the data.
#
# Input:  data/data_for_analysis/county_units.csv
# Output: results/Figure 1 - Study timeline.png

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
gap <- median(units$months_announce_to_first_reg_any[!units$reg_before_announce_any], na.rm = TRUE)
antic <- 3
txt <- function(...) annotate("text", family = "Times New Roman", size = 3, lineheight = 0.95, ...)

fig <- ggplot() +
  # Anticipation window and the months over which effects are measured
  annotate("rect", xmin = -antic, xmax = 0, ymin = -0.12, ymax = 0.12, fill = "grey88") +
  annotate("segment", x = -6, xend = 26, y = 0, yend = 0, linewidth = 0.5,
           arrow = arrow(length = unit(0.08, "inches"), type = "closed")) +
  annotate("point", x = c(0, gap), y = 0, size = 3, shape = 21, fill = c(col_main, col_second),
           colour = "black", stroke = 0.4) +
  # Labels above the line, centred, with arrows down to their dots
  txt(x = -2.5, y = 0.55, label = "First major data center\nannouncement (month 0)") +
  annotate("segment", x = -2.2, xend = -0.1, y = 0.38, yend = 0.07, linewidth = 0.3,
           arrow = arrow(length = unit(0.06, "inches"), type = "closed")) +
  txt(x = gap + 3, y = 0.55, label = sprintf("Data center regulation adopted\n(median: %g months later)", gap)) +
  annotate("segment", x = gap + 2.7, xend = gap + 0.1, y = 0.38, yend = 0.07, linewidth = 0.3,
           arrow = arrow(length = unit(0.06, "inches"), type = "closed")) +
  # Labels below the line
  txt(x = -antic / 2, y = -0.16, vjust = 1, label = "Anticipation window\n(3 months)") +
  annotate("segment", x = 0.3, xend = 24, y = -0.5, yend = -0.5, linewidth = 0.3,
           arrow = arrow(length = unit(0.06, "inches"), ends = "both", type = "closed")) +
  txt(x = 12.15, y = -0.66, label = "Effect measured each month up to 24 months after the announcement,\ncompared with counties whose announcement has not happened yet") +
  scale_x_continuous(breaks = c(-3, 0, 6, 12, 18, 24), limits = c(-6.5, 26.5)) +
  scale_y_continuous(limits = c(-0.85, 0.75)) +
  labs(title = "Figure 1: Research Design",
       x = "Months since first major announcement", y = NULL) +
  theme_paper +
  theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank())
ggsave(file.path(results_dir, "Figure 1 - Study timeline.png"), fig, width = fig_width, height = 2.8, dpi = 300)

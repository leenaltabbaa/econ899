# Main-text results: estimates the difference-in-differences models once, then
# produces each table and figure in the main text.

if (!exists("CONFIG_LOADED")) source("programs/config.R")

source(file.path(programs_dir, "02_analysis", "estimates.R"))  # all DiD models -> results/estimates/
source(file.path(programs_dir, "02_analysis", "table01.R"))    # Table 1: summary statistics
source(file.path(programs_dir, "02_analysis", "table02.R"))    # Table 2: main DiD results
source(file.path(programs_dir, "02_analysis", "figure01.R"))   # Figure 1: study timeline
source(file.path(programs_dir, "02_analysis", "figure02.R"))   # Figure 2: regulations over time
source(file.path(programs_dir, "02_analysis", "figure03.R"))   # Figure 3: event study

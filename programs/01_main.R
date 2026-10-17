setwd("~/Desktop/ECON 899 GitHub"); source("programs/01_main.R")# Main program: runs every program in the correct order and reproduces all
# tables and figures in the paper and its appendix.
#
# Before the first run: run programs/00_setup.R once.
# Then, with econ899.Rproj open in RStudio:  source("programs/01_main.R")

source("programs/config.R")
start_time <- Sys.time()

# Data preparation: raw data -> data/data_for_analysis
source(file.path(programs_dir, "01_dataprep", "main.R"))

# Main text tables and figures -> results/
source(file.path(programs_dir, "02_analysis", "main.R"))

# Appendix tables and figures -> results/
source(file.path(programs_dir, "03_appendix", "main.R"))

# Record the software environment used
writeLines(capture.output(sessionInfo()), file.path(results_dir, "session_info.txt"))
message("All done in ", round(difftime(Sys.time(), start_time, units = "mins"), 1), " minutes.")

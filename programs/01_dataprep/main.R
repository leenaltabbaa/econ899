# Data preparation: runs the data cleaning programs in order.
# Reads data/raw_data, writes data/data_for_analysis.

if (!exists("CONFIG_LOADED")) source("programs/config.R")

source(file.path(programs_dir, "01_dataprep", "11_clean_server_country.R"))  # treatment timing
source(file.path(programs_dir, "01_dataprep", "12_merge_regulations.R"))     # regulation records
source(file.path(programs_dir, "01_dataprep", "13_build_panel.R"))           # county-month panel

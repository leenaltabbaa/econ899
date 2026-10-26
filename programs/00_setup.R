# Setup program: run ONCE before 01_main.R.
# Installs the R packages used by this replication package from CRAN.
# Running it again is harmless (it only installs packages that are missing).

packages <- c("readr", "dplyr", "tidyr", "stringr", "ggplot2", "scales", "did",
              "flextable", "officer")
missing  <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

# All raw data are included in data/raw_data (see README.md), so nothing to download.
message("Setup complete. Installed versions:")
for (p in packages) message("  ", p, " ", as.character(packageVersion(p)))

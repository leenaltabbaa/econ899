# Data for analysis

Everything in this folder is created by the programs in `programs/01_dataprep` from
the raw data in `data/raw_data`, and is read by the programs in `programs/02_analysis`
and `programs/03_appendix`. The files are not included in the repo (see `.gitignore`);
run `programs/01_main.R` to create them.

| File | Made by | Description |
|---|---|---|
| `first_major.csv` | `11_clean_server_country.R` | Each county's first major data-centre announcement |
| `regulations_merged.csv` | `12_merge_regulations.R` | FAS and web-search records, one row per record-county pair |
| `county_units.csv` | `13_build_panel.R` | One row per panel county (232) |
| `county_month_panel.csv` | `13_build_panel.R` | County-by-month panel, January 2020 (period 1) to October 2026 (period 82) |
| `excluded_units.csv` | `13_build_panel.R` | Counties left out of the panel, with the reason |

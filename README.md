# README for "Governing the Data Center Boom: Does Data Center Development Reshape Local Institutions?" (Leen Al Tabbaa)

## Overview

This replication package reproduces every table and figure in the paper and its
appendix. The paper asks whether counties, and the cities and townships inside them,
adopt data center rules (moratoria, zoning rules, use standards, noise and water rules)
after the first major data center project in the county is announced.

The code combines three data sources: Server Country's database of US data center
projects (Server Country, 2026), the Federation of American Scientists' database of
local data center ordinances (FAS, 2026), and a web search of local regulation records
collected by the author. All code is in R. One setup program installs the packages and
one main program, `programs/01_main.R`, runs everything else in order: it builds a
county-by-month panel (232 counties, January 2020 to October 2026) and estimates
staggered difference-in-differences models (Callaway and Sant'Anna, 2021).

Time in the panel is measured in **months**: period 1 is January 2020 and period 82 is
October 2026.

## Data Availability and Provenance Statements

### Statement about Rights

- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- [x] I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package.


The Server Country data are offered as a public download. The FAS records are taken
from a publicly shared database. The web-search records were collected by the author.

### Summary of Availability

- [x] All data **are** publicly available.

#### Summary of Data Availability

| Data.Name | Data.Files | Location | Provided | Citation |
|---|---|---|---|---|
| Server Country data center projects | `server_country_projects.csv` | `data/raw_data/` | TRUE | Server Country (2026) |
| FAS local data center ordinance database, coded | `fas_regulations_coded.csv` | `data/raw_data/` | TRUE | FAS (2026) |
| Web search of local regulation records | `web_search_regulations.csv`, `county_search_log.csv` | `data/raw_data/` | TRUE | Al Tabbaa (2026) |

### Details on each Data Source

**Server Country data center projects.** One row per announced US data center project
(1,048 projects), with location (state, county, city), announcement date, power
capacity (MW) and investment (USD). Downloaded as a CSV file from
https://servercountry.org/data/downloads/. A copy is provided.
Datafile: `data/raw_data/server_country_projects.csv`.

**FAS local data center ordinance database.** The Federation of American Scientists
keeps a public database of local data center ordinances, moratoria and related actions,
described in FAS (2025). The database was retrieved on 2026-10-09 from
https://docs.google.com/spreadsheets/d/1mxwMW4FuhtPnNWB8WPy9Ls6a4owjdUqPI4wax8Bl5k8.
The author coded each of the 42 records taken from the database by hand (level of government, type of action, whether it was adopted, date). The
original FAS columns are kept with a `fas_` prefix. A copy is provided.
Datafile: `data/raw_data/fas_regulations_coded.csv`.

**Web search of local regulation records.** Collected by the author (with AI-assisted
web search) and completed on 2026-10-13. Every county with a major announcement from
2020 on was searched for data center rules from 2020 onward, covering the county
government and the cities, towns and townships inside it. Each record has a source URL,
a source type (official, news, other) and a confidence rating. About two-thirds of
adopted records rely on local news rather than official documents. Counties marked
"nothing found" were searched on 2026-10-13; this is not a confirmed zero.
Datafiles: `data/raw_data/web_search_regulations.csv` (391 records, same columns as the
FAS file plus coding columns) and `data/raw_data/county_search_log.csv` (one row per
county searched; documentation only, not read by the code).

## Dataset list

| Data file | Source | Notes | Provided |
|---|---|---|---|
| `data/raw_data/server_country_projects.csv` | Server Country | Raw download | Yes |
| `data/raw_data/fas_regulations_coded.csv` | FAS | 42 records, hand-coded | Yes |
| `data/raw_data/web_search_regulations.csv` | Al Tabbaa | 391 records | Yes |
| `data/raw_data/county_search_log.csv` | Al Tabbaa | Search log, documentation only | Yes |
| `data/data_for_analysis/first_major.csv` | Server Country | Each county's first major announcement; made by `11_clean_server_country.R` | No (created by the code) |
| `data/data_for_analysis/regulations_merged.csv` | FAS, Al Tabbaa | All regulation records assigned to counties; made by `12_merge_regulations.R` | No (created by the code) |
| `data/data_for_analysis/county_units.csv` | All | One row per county; made by `13_build_panel.R` | No (created by the code) |
| `data/data_for_analysis/county_month_panel.csv` | All | County-by-month panel, input to all estimates; made by `13_build_panel.R` | No (created by the code) |
| `data/data_for_analysis/excluded_units.csv` | Server Country | Counties left out and why; made by `13_build_panel.R` | No (created by the code) |

## Computational requirements

### Software Requirements

- [x] The replication package contains one or more programs to install all dependencies and set up the necessary directory structure.

- R (code was last run with version 4.6.1)
  - `readr`, `dplyr`, `tidyr`, `stringr`, `ggplot2`, `scales`
  - `did` (Callaway and Sant'Anna, 2021)
  - The program `programs/00_setup.R` installs all of these from CRAN and should be run once. The versions used are listed in `results/session_info.txt` after a run.

### Controlled Randomness

- [x] Random seed is set at line 33 of program `programs/config.R` (`analysis_seed <- 20261013`) and applied at line 31 of program `programs/02_analysis/estimates.R`, before each model.

### Memory, Runtime, Storage Requirements

#### Summary time to reproduce

Approximate time needed to reproduce the analyses on a standard 2026 desktop machine:

- [x] <10 minutes 

#### Summary of required storage space

Approximate storage space needed:

- [x] < 25 MBytes

#### Computational Details

The code was last run on a 13-inch MacBook Air (Apple M5 chip, 16 GB memory) with macOS Tahoe 26.4.1.

## Description of programs/code

- `programs/config.R` sets the folder paths, loads the packages and holds the study
  settings (panel start and end, the random seed, the anticipation window) and small
  helper functions. Every other program reads it first. It is the only file a user
  should need to edit.
- `programs/00_setup.R` installs the R packages.
- `programs/01_main.R` runs all programs below in order.
- Programs in `programs/01_dataprep` build the analysis data from the raw data;
  `programs/01_dataprep/main.R` runs them in order:
  - `11_clean_server_country.R`: keeps major projects (at least 450 MW or $3 billion)
    and finds each county's first major announcement.
  - `12_merge_regulations.R`: merges the FAS and web-search records, assigns city
    records to their county, codes each record as permanent, temporary or non-binding,
    drops permissive records and web-search records that duplicate a FAS record.
  - `13_build_panel.R`: builds the county-by-month panel and the outcome variables.
- Programs in `programs/02_analysis` produce the tables and figures in the main text.
  `estimates.R` estimates every difference-in-differences model once and saves them in
  `results/estimates/`; each other program is named after the table or figure it makes.
- Programs in `programs/03_appendix` produce the appendix tables and figures from the
  saved estimates.
- Each program checks key counts (for example, 232 counties and 82 months) and stops
  with an error if a number changes.

### License for Code

See `LICENSE`.

## Instructions to Replicators

1. Open `econ899.Rproj` in RStudio. (If you run R another way, edit `myrepo` in
   `programs/config.R` to point to this folder.)
2. Run `programs/00_setup.R` once to install the packages.
3. Run `programs/01_main.R`. It rebuilds `data/data_for_analysis/` and writes every
   table and figure to `results/`.
   
### Details on various programs

- `programs/00_setup.R`: installs the R packages from CRAN. Run once; running it again only installs missing packages.
- `programs/01_dataprep/main.R`: runs `11_clean_server_country.R`, `12_merge_regulations.R` and `13_build_panel.R`. ORDER IS IMPORTANT: each program uses the output of the one before.
- `programs/02_analysis/main.R`: runs `estimates.R` first (it estimates all models and saves them), then the table and figure programs. ORDER IS IMPORTANT.
- `programs/03_appendix/main.R`: uses the estimates saved by `02_analysis/estimates.R`, so run it after `02_analysis`.
- `programs/01_main.R` runs all of the above in the correct order. The programs were last run top to bottom on October 17, 2026.

## List of tables and programs

The provided code reproduces:

- [x] All tables and figures in the paper

| Figure/Table # | Program | Output file | Note |
|---|---|---|---|
| Table 1 | `02_analysis/table01.R` | `results/Table01.csv`, `Table01.txt` | Summary statistics |
| Table 2 | `02_analysis/table02.R` | `results/Table02.csv`, `Table02.txt` | Main DiD results |
| Figure 1 | `02_analysis/figure01.R` | `results/Figure01.png` | Share of counties with a rule over time |
| Figure 2 | `02_analysis/figure02.R` | `results/Figure02.png` | Main event study |
| Table A1 | `03_appendix/tableA1.R` | `results/TableA1.csv`, `TableA1.txt` | Robustness checks |
| Table A2 | `03_appendix/tableA2.R` | `results/TableA2.csv`, `TableA2.txt` | Regulation records by source and type |
| Table A3 | `03_appendix/tableA3.R` | `results/TableA3.csv`, `TableA3.txt` | Counties with a rule before their announcement |
| Figure A1 | `03_appendix/figureA1.R` | `results/FigureA1.png` | Announcements by month |
| Figure A2 | `03_appendix/figureA2.R` | `results/FigureA2.png` | Raw share with a rule, by months since announcement |
| Figure A3 | `03_appendix/figureA3.R` | `results/FigureA3.png` | Event studies, all specifications |

## Use of AI tools

The data-cleaning and analysis code in this package was written with help from AI
coding assistants (Claude by Anthropic, and ChatGPT/Codex by OpenAI), and the web
search of regulation records was AI-assisted. The author reviewed the code and the
coding decisions and ran all results.

## References

Callaway, Brantly, and Pedro H. C. Sant'Anna. 2021. "Difference-in-Differences with
Multiple Time Periods." *Journal of Econometrics* 225 (2): 200–230.
https://doi.org/10.1016/j.jeconom.2020.12.001

Callaway, Brantly, and Pedro H. C. Sant'Anna. 2021. "did: Difference in Differences." R package
version 2.5.1. https://bcallaway11.github.io/did/

Federation of American Scientists (FAS). 2025. "Before Breaking Ground."
https://fas.org/publication/before-breaking-ground/

Federation of American Scientists (FAS). 2026. "Local Data Center Ordinance Database
[dataset]."
https://docs.google.com/spreadsheets/d/1mxwMW4FuhtPnNWB8WPy9Ls6a4owjdUqPI4wax8Bl5k8
(accessed October 9, 2026).

Server Country. 2026. "Data Center Projects [dataset]."
https://servercountry.org/data/downloads/ (accessed October 1, 2026).

Al Tabbaa, Leen. 2026. "Web search of local data center regulation records [dataset]." Collected
October 2026; provided in this package.

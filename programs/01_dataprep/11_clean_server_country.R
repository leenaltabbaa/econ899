# Server Country data-centre projects -> major projects -> each county's first major
# announcement (the treatment date used in the panel).
#   Major project: power capacity >= 450 MW or investment >= $3B.
#   First major: earliest announcement (year, then month) among a county's major projects.
#
# Input:  data/raw_data/server_country_projects.csv
# Output: data/data_for_analysis/first_major.csv (one row per county)

if (!exists("CONFIG_LOADED")) source("programs/config.R")

# camelCase / mixed headers -> snake_case (same result as janitor::clean_names here)
snake_case <- function(x) {
  x %>%
    str_replace_all("([a-z0-9])([A-Z])", "\\1_\\2") %>%
    str_replace_all("([A-Z]+)([A-Z][a-z])", "\\1_\\2") %>%
    str_replace_all("[^A-Za-z0-9]+", "_") %>%
    str_to_lower()
}

dc_raw <- read_csv(file.path(raw_dir, "server_country_projects.csv"), show_col_types = FALSE)
stopifnot(nrow(dc_raw) == 1048)
dc <- dc_raw %>% rename_with(snake_case)

dc_small <- dc %>%
  select(project_name, state, county, city, status, purpose, economic_impact_jobs,
         investment_usd, power_capacity_mw, total_square_feet, announced_date,
         construction_start_date, expected_completion_date, actual_completion_date) %>%
  mutate(
    # announced_date comes as "2018-07-09", "May-24" or "2025"
    announcement_year = case_when(
      str_detect(announced_date, "^\\d{4}") ~ as.numeric(str_extract(announced_date, "^\\d{4}")),
      str_detect(announced_date, "\\d{2}$") ~ 2000 + as.numeric(str_extract(announced_date, "\\d{2}$")),
      TRUE ~ NA_real_
    ),
    month_from_full_date = as.numeric(str_match(announced_date, "^\\d{4}-(\\d{2})-\\d{2}$")[, 2]),
    month_text = str_match(announced_date, "^([A-Za-z]{3})-\\d{2}$")[, 2],
    month_from_text = match(month_text, month.abb),
    announcement_month = coalesce(month_from_full_date, month_from_text),
    announcement_date_unusable = !is.na(announced_date) & is.na(announcement_year),
    major_project = if_else(power_capacity_mw >= 450 | investment_usd >= 3e9, 1, 0, missing = 0)
  )

dc_major <- dc_small %>% filter(major_project == 1)

first_major <- dc_major %>%
  filter(!is.na(announcement_year)) %>%
  arrange(state, county, announcement_year, announcement_month) %>%
  group_by(state, county) %>%
  slice(1) %>%
  ungroup()

stopifnot(nrow(dc_major) == 303, nrow(first_major) == 245)

write_csv(first_major, file.path(clean_dir, "first_major.csv"))
message("11_clean_server_country: ", nrow(dc_small), " projects; ", nrow(dc_major), " major; ",
        nrow(first_major), " counties with a first major announcement.")

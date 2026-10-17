# Merge the two sources of local data-centre regulation records into one file, with
# every record assigned to a county and coded for whether it counts as an adopted rule.
#
# Inputs:  data/raw_data/fas_regulations_coded.csv  (42 FAS ordinance-database records)
#          data/raw_data/web_search_regulations.csv (391 web-search records)
# Output:  data/data_for_analysis/regulations_merged.csv (one row per record-county pair)
#
# Coding rules:
#   - Level of government: county_government_rule = 1 for a county or consolidated
#     city-county, 0 for a city, town, village or township.
#   - Type: temporary_regulation (moratoria, pauses, interim measures), permanent_regulation
#     (zoning, use standards, noise and water rules, bans, ballot measures) or
#     other_nonbinding (studies, resolutions), which never counts.
#   - Direction: permissive records (only loosening rules or opening land to data
#     centres) never count. Mixed records (allowing data centres only under conditions)
#     count; mixed_direction flags them for a robustness check. FAS has no direction
#     field: its two lifted moratorium/ban records (DeKalb, Athens-Clarke), which
#     replaced the pause with rules, are coded mixed and the rest restrictive.
#   - City records count for the county the city is in; a city spanning several
#     counties (Atlanta, Kansas City) is assigned to each of them.
#   - A web record that matches a FAS record (same county, level, type and
#     jurisdiction, dates within 31 days) is flagged and not counted twice.
#   - Dates: "YYYY-MM-DD", "YYYY-MM" or "YYYY". Year-only dates are placed in July
#     (year_only_month in config.R) and flagged in reg_date_precision.

if (!exists("CONFIG_LOADED")) source("programs/config.R")

fas_raw <- read_chr(file.path(raw_dir, "fas_regulations_coded.csv"))
web_raw <- read_chr(file.path(raw_dir, "web_search_regulations.csv"))
stopifnot(nrow(fas_raw) == 42, nrow(web_raw) == 391,
          !anyDuplicated(c(fas_raw$action_id, web_raw$action_id)))

# Parse "YYYY-MM-DD" / "YYYY-MM" / "YYYY"; fall back to reported_year + reported_month.
parse_reg_date <- function(date_txt, yr, mo) {
  date_txt <- str_trim(date_txt)
  prec <- case_when(
    str_detect(date_txt, "^\\d{4}-\\d{2}-\\d{2}$") ~ "day",
    str_detect(date_txt, "^\\d{4}-\\d{2}$")        ~ "month",
    str_detect(date_txt, "^\\d{4}$")               ~ "year",
    !is.na(yr) & !is.na(mo)                         ~ "month",
    !is.na(yr)                                      ~ "year",
    TRUE                                            ~ "unknown"
  )
  y <- coalesce(as.integer(str_sub(date_txt, 1, 4)), as.integer(yr))
  m <- case_when(prec == "day" | (prec == "month" & str_detect(coalesce(date_txt, ""), "^\\d{4}-\\d{2}")) ~
                   as.integer(str_sub(date_txt, 6, 7)),
                 prec == "month" ~ as.integer(mo),
                 prec == "year"  ~ year_only_month,
                 TRUE ~ NA_integer_)
  d <- case_when(prec == "day" ~ as.Date(date_txt, format = "%Y-%m-%d"),
                 !is.na(y) & !is.na(m) ~ as.Date(sprintf("%04d-%02d-01", y, m)),
                 TRUE ~ as.Date(NA))
  tibble(reg_date = d, reg_date_precision = prec,
         reg_month = if_else(is.na(d), as.Date(NA), as.Date(format(d, "%Y-%m-01"))))
}

# ---- FAS records ---------------------------------------------------------------
# County for FAS city/township records that have no county_from_fas.
fas_city_crosswalk <- tribble(
  ~state, ~jurisdiction,              ~county_assigned,         ~crosswalk_note,
  "AL",   "Birmingham",               "Jefferson County",       "",
  "AK",   "Anchorage",                "Anchorage Municipality", "consolidated municipality",
  "AZ",   "City of Chandler",         "Maricopa County",        "",
  "AR",   "Little Rock",              "Pulaski County",         "",
  "AR",   "Fayetteville",             "Washington County",      "",
  "CA",   "City of Monterey Park",    "Los Angeles County",     "",
  "GA",   "City of Atlanta",          "Fulton County",          "city spans Fulton and DeKalb",
  "GA",   "City of Atlanta",          "DeKalb County",          "city spans Fulton and DeKalb",
  "GA",   "Statesboro",               "Bulloch County",         "",
  "KY",   "Bowling Green",            "Warren County",          "",
  "LA",   "City of New Orleans",      "Orleans Parish",         "consolidated city-parish",
  "MI",   "City of Saline",           "Washtenaw County",       "",
  "MI",   "City of Mason",            "Ingham County",          "",
  "MI",   "Ypsilanti",                "Washtenaw County",       "",
  "MN",   "City of Minneapolis",      "Hennepin County",        "",
  "MO",   "Kansas City",              "Jackson County",         "city spans Jackson, Clay, Platte and Cass",
  "MO",   "Kansas City",              "Clay County",            "city spans Jackson, Clay, Platte and Cass",
  "MO",   "Kansas City",              "Platte County",          "city spans Jackson, Clay, Platte and Cass",
  "MO",   "Kansas City",              "Cass County",            "city spans Jackson, Clay, Platte and Cass",
  "NV",   "City of Boulder City",     "Clark County",           "",
  "OK",   "Lawton",                   "Comanche County",        "",
  "PA",   "South Strabane Township",  "Washington County",      "",
  "PA",   "Franklin Park",            "Allegheny County",       "",
  "WA",   "Seattle",                  "King County",            "",
  "WI",   "City of Port Washington",  "Ozaukee County",         ""
)

fas <- fas_raw %>%
  mutate(
    record_origin = "FAS",
    county_government_rule = as.integer(jurisdiction_level %in% c("county", "consolidated_city_county")),
    regulation_category = case_when(
      event_type == "study_resolution" ~ "other_nonbinding",
      moratorium_reported == "1"       ~ "temporary_regulation",
      str_detect(fas_type, regex("^\\s*(\\d+ day )?moratorium|emergency moratorium", ignore_case = TRUE)) ~
        "temporary_regulation",
      TRUE                             ~ "permanent_regulation"
    ),
    # Proposals, denials, studies and pending items do not count.
    counts_as_adopted = as.integer(coalesce(reported_policy_adoption, "0") == "1" &
                                     regulation_category != "other_nonbinding"),
    regulatory_direction = if_else(str_detect(fas_type, regex("^\\s*lifted", ignore_case = TRUE)),
                                   "mixed", "restrictive"),
    county_assigned_fas = case_when(
      !is.na(county_from_fas) & jurisdiction_level == "county" ~ paste(county_from_fas, "County"),
      !is.na(county_from_fas)                                  ~ county_from_fas,
      TRUE ~ NA_character_)
  ) %>%
  left_join(fas_city_crosswalk, by = c("state", "jurisdiction"), relationship = "many-to-many") %>%
  mutate(county = coalesce(county_assigned_fas, county_assigned),
         county_assignment_note = case_when(
           !is.na(county_assigned_fas) ~ "county_from_fas",
           !is.na(county_assigned)     ~ paste0("FAS city crosswalk",
                                                if_else(crosswalk_note == "", "", paste0("; ", crosswalk_note))),
           TRUE ~ NA_character_)) %>%
  select(-county_assigned_fas, -county_assigned, -crosswalk_note)
stopifnot(!anyNA(fas$county))

# ---- Web-search records ----------------------------------------------------------
web <- web_raw %>%
  mutate(county_government_rule = as.integer(county_government_rule),
         counts_as_adopted = as.integer(counts_as_adopted),
         county_assignment_note = "web search")
stopifnot(all(web$regulatory_direction %in% c("restrictive", "mixed", "permissive")))

# ---- Merge -----------------------------------------------------------------------
regs <- bind_rows(fas, web) %>%
  mutate(state = to_abb(state),
         county_key = paste(state, norm_county(county), sep = "|"),
         n_counties_assigned = n(), .by = action_id) %>%
  bind_cols(parse_reg_date(.$reported_date, .$reported_year, .$reported_month)) %>%
  mutate(jurisdiction_stub = jurisdiction %>% str_to_lower() %>%
           str_remove_all("city of|town of|village of|charter township of|township|county|city|the|\\(.*\\)") %>%
           str_squish())

overlap <- regs %>% filter(record_origin == "FAS") %>%
  select(fas_id = action_id, county_key, regulation_category, county_government_rule,
         fas_date = reg_date, jurisdiction_stub) %>%
  inner_join(regs %>% filter(record_origin == "web_search") %>%
               select(action_id, county_key, regulation_category, county_government_rule,
                      reg_date, jurisdiction_stub),
             by = c("county_key", "regulation_category", "county_government_rule", "jurisdiction_stub"),
             relationship = "many-to-many") %>%
  filter(!is.na(fas_date), !is.na(reg_date), abs(as.numeric(reg_date - fas_date)) <= 31) %>%
  summarise(possible_fas_duplicate = paste(unique(fas_id), collapse = ";"), .by = action_id)

regs <- regs %>%
  left_join(overlap, by = "action_id") %>%
  mutate(mixed_direction = as.integer(regulatory_direction == "mixed"),
         counts_as_adopted_final = as.integer(counts_as_adopted == 1L & is.na(possible_fas_duplicate) &
                                                regulatory_direction != "permissive"),
         adopted_after_search_date = !is.na(reg_date) & reg_date > search_date) %>%
  select(-jurisdiction_stub)

n_adopted <- regs %>% distinct(action_id, .keep_all = TRUE) %>% count(record_origin, wt = counts_as_adopted_final)
stopifnot(n_adopted$n[n_adopted$record_origin == "FAS"] == 36,
          n_adopted$n[n_adopted$record_origin == "web_search"] == 189)

write_csv(regs, file.path(clean_dir, "regulations_merged.csv"), na = "")
message("12_merge_regulations: ", n_distinct(regs$action_id), " records; ",
        sum(n_adopted$n), " count as adopted rules.")

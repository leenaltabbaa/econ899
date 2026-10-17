# Build the county-by-month panel used in all analysis.
#
# Inputs:  data/data_for_analysis/first_major.csv        (from 11)
#          data/data_for_analysis/regulations_merged.csv  (from 12)
# Outputs: data/data_for_analysis/county_units.csv        one row per county
#          data/data_for_analysis/county_month_panel.csv  one row per county-month
#          data/data_for_analysis/excluded_units.csv      counties left out, with reasons
#
# Panel units are counties whose first major announcement is in January 2020 or later.
#   - Multi-county announcements ("Clay/Platte", "Caddo Parish; Bossier Parish") are split
#     and each county is treated at that announcement.
#   - Duplicate spellings ("Weld" / "Weld County") are merged; the earliest announcement
#     is kept.
#   - Counties first treated before 2020 and projects with an unknown county are excluded.
#   - Year-only announcement dates are placed in July and flagged (announce_precision).
#
# Outcomes (0/1, equal to 1 from the month of the first adopted rule onward):
#   reg_any_any     any rule by the county or any municipality in it (main outcome)
#   reg_perm_any    permanent rules only
#   reg_temp_any    temporary rules only (moratoria)
#   reg_any_cgov    county-government rules only (plus perm/temp versions)
#   reg_any_nomixed any rule, excluding mixed-direction rules
# period counts months from January 2020 (= 1); first_major_period is the treatment month.

if (!exists("CONFIG_LOADED")) source("programs/config.R")

fm_raw <- read_chr(file.path(clean_dir, "first_major.csv"))
regs   <- read_csv(file.path(clean_dir, "regulations_merged.csv"), show_col_types = FALSE,
                   col_types = cols(.default = col_character(), reg_date = col_date(), reg_month = col_date(),
                                    county_government_rule = col_integer(), counts_as_adopted_final = col_integer(),
                                    mixed_direction = col_integer(), adopted_after_search_date = col_logical()))

# ---- Panel units: first major announcement per county ----------------------------
fm_units <- fm_raw %>%
  mutate(source_county = county,
         ann_year  = as.integer(announcement_year),
         ann_month = as.integer(announcement_month),
         announce_precision = if_else(is.na(ann_month), "year", "month"),
         ann_month = coalesce(ann_month, year_only_month)) %>%
  filter(!is.na(ann_year)) %>%
  separate_longer_delim(county, delim = regex("\\s*(;|/|,| and )\\s*")) %>%
  mutate(county = str_squish(county),
         split_from_multi = county != source_county,
         state_abb = to_abb(state),
         county_key = paste(state_abb, norm_county(county), sep = "|"),
         first_major_month = as.Date(sprintf("%04d-%02d-01", ann_year, ann_month)))

bad_county <- fm_units$county %in% c("Unknown", "Multiple") | is.na(fm_units$county)

units_all <- fm_units %>% filter(!bad_county) %>%
  arrange(county_key, first_major_month) %>%
  summarise(state = first(state), state_abb = first(state_abb),
            county = if_else(any(str_detect(county, "(County|Parish|Borough|City)$")),
                             first(county[str_detect(county, "(County|Parish|Borough|City)$")]),
                             paste(first(county), "County")),
            first_major_month = first(first_major_month),
            announce_precision = first(announce_precision),
            first_major_project = first(project_name),
            source_rows = paste(unique(source_county), collapse = " | "),
            split_from_multi = first(split_from_multi),
            .by = county_key)

units <- units_all %>% filter(first_major_month >= panel_start) %>%
  arrange(state, county) %>% mutate(unit_id = row_number(), .before = 1)

excluded_units <- bind_rows(
  fm_units %>% filter(bad_county, ann_year >= 2020) %>%
    transmute(state, county = source_county, project_name, first_major_month,
              reason = "county unknown or 'Multiple' in Server Country data"),
  units_all %>% filter(first_major_month < panel_start,
                       county_key %in% fm_units$county_key[fm_units$ann_year >= 2020]) %>%
    transmute(state, county, project_name = first_major_project, first_major_month,
              reason = "first major announcement before 2020 (already treated)")
)

# ---- First adopted rule per county, by outcome ---------------------------------------
adopt <- regs %>%
  filter(counts_as_adopted_final == 1L, county_key %in% units$county_key, !adopted_after_search_date)

groups <- list(
  any_any     = quote(TRUE),
  perm_any    = quote(regulation_category == "permanent_regulation"),
  temp_any    = quote(regulation_category == "temporary_regulation"),
  any_cgov    = quote(county_government_rule == 1L),
  perm_cgov   = quote(county_government_rule == 1L & regulation_category == "permanent_regulation"),
  temp_cgov   = quote(county_government_rule == 1L & regulation_category == "temporary_regulation"),
  any_nomixed = quote(mixed_direction == 0L)
)

first_reg <- lapply(names(groups), function(g) {
  d <- adopt %>% filter(!!groups[[g]])
  d %>%
    summarise(first = if (all(is.na(reg_month))) as.Date(NA) else min(reg_month, na.rm = TRUE),
              n_dated = sum(!is.na(reg_month)), n_undated = sum(is.na(reg_month)), .by = county_key) %>%
    left_join(d %>% filter(!is.na(reg_month)) %>% arrange(reg_month, reg_date) %>%
                summarise(first_ids = paste(action_id[reg_month == first(reg_month)], collapse = ";"),
                          first_prec = first(reg_date_precision), .by = county_key),
              by = "county_key") %>%
    rename(!!paste0("first_reg_", g) := first, !!paste0("n_adopted_dated_", g) := n_dated,
           !!paste0("n_adopted_undated_", g) := n_undated, !!paste0("first_reg_ids_", g) := first_ids,
           !!paste0("first_reg_precision_", g) := first_prec)
}) %>% Reduce(function(a, b) full_join(a, b, by = "county_key"), .)

county_units <- units %>% left_join(first_reg, by = "county_key") %>%
  mutate(across(starts_with("n_adopted_"), ~ coalesce(.x, 0L)),
         first_major_period = month_index(first_major_month),
         months_announce_to_first_reg_any = month_index(first_reg_any_any) - first_major_period,
         reg_before_announce_any = !is.na(first_reg_any_any) & first_reg_any_any < first_major_month)

# ---- County-by-month panel ---------------------------------------------------------
months <- seq(panel_start, panel_end, by = "month")
monthly_counts <- lapply(names(groups), function(g) {
  adopt %>% filter(!!groups[[g]], !is.na(reg_month)) %>%
    count(county_key, month = reg_month, name = paste0("n_new_", g))
}) %>% Reduce(function(a, b) full_join(a, b, by = c("county_key", "month")), .)

panel <- county_units %>%
  select(unit_id, state, state_abb, county, county_key, first_major_month, first_major_period,
         announce_precision, reg_before_announce_any, all_of(paste0("first_reg_", names(groups)))) %>%
  cross_join(tibble(month = months)) %>%
  mutate(period = month_index(month),
         post_announce = as.integer(month >= first_major_month)) %>%
  left_join(monthly_counts, by = c("county_key", "month")) %>%
  mutate(across(starts_with("n_new_"), ~ coalesce(.x, 0L)))
for (g in names(groups)) {
  fr <- panel[[paste0("first_reg_", g)]]
  panel[[paste0("reg_", g)]] <- as.integer(!is.na(fr) & panel$month >= fr)
  panel[[paste0("first_reg_period_", g)]] <- if_else(is.na(fr), 0L, month_index(fr))  # 0 = never
}
panel <- panel %>% select(-all_of(paste0("first_reg_", names(groups)))) %>% arrange(unit_id, period)

# ---- Checks ------------------------------------------------------------------------
n_with <- function(g) sum(!is.na(county_units[[paste0("first_reg_", g)]]))
stopifnot(
  !anyDuplicated(panel[c("unit_id", "period")]),
  nrow(county_units) == 232, length(months) == 82, nrow(panel) == 232 * 82,
  nrow(excluded_units) == 7,
  n_with("any_any") == 106, n_with("perm_any") == 55, n_with("temp_any") == 69,
  n_with("any_cgov") == 54, n_with("any_nomixed") == 104
)

write_csv(county_units, file.path(clean_dir, "county_units.csv"), na = "")
write_csv(panel, file.path(clean_dir, "county_month_panel.csv"), na = "")
write_csv(excluded_units, file.path(clean_dir, "excluded_units.csv"), na = "")
message("13_build_panel: ", nrow(county_units), " counties x ", length(months), " months; ",
        n_with("any_any"), " counties adopt a rule by ", format(panel_end, "%B %Y"), ".")

# Table A3: counties whose first data-centre rule came before their first major
# announcement. These counties stay in the panel; their outcome is 1 before and after
# treatment, so they add no spurious effect.
#
# Input:  data/data_for_analysis/county_units.csv, regulations_merged.csv
# Output: results/TableA3.csv, results/TableA3.txt

if (!exists("CONFIG_LOADED")) source("programs/config.R")

units <- read_csv(file.path(clean_dir, "county_units.csv"), show_col_types = FALSE)
recs  <- read_chr(file.path(clean_dir, "regulations_merged.csv")) %>% distinct(action_id, .keep_all = TRUE)

early <- units %>% filter(reg_before_announce_any) %>% arrange(first_reg_any_any)
stopifnot(nrow(early) == 16)
first_ids <- strsplit(early$first_reg_ids_any_any, ";")

tableA3 <- early %>%
  transmute(County = county, State = state_abb,
            Announced = format(first_major_month, "%Y-%m"),
            `First rule` = paste0(format(first_reg_any_any, "%Y-%m"),
                                  if_else(first_reg_precision_any_any == "year", "*", "")),
            `Adopted by` = sapply(first_ids, function(i) paste(unique(recs$jurisdiction[recs$action_id %in% i]), collapse = "; ")),
            Type = sapply(first_ids, function(i) paste(unique(sub("_regulation", "", recs$regulation_category[recs$action_id %in% i])), collapse = "; ")))

write_csv(tableA3, file.path(results_dir, "TableA3.csv"))
writeLines(c("Table A3: Counties whose first rule predates their first major announcement", "",
             capture.output(print(as.data.frame(tableA3), row.names = FALSE, right = FALSE)), "",
             "* Year-only date, placed in July."),
           file.path(results_dir, "TableA3.txt"))

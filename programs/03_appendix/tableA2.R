# Table A2: regulation records by source, level of government and type, and how many
# count as adopted rules.
#
# Input:  data/data_for_analysis/regulations_merged.csv
# Output: results/Table A2 - Regulation records by source and type.csv, results/Table A2 - Regulation records by source and type.txt

if (!exists("CONFIG_LOADED")) source("programs/config.R")

recs <- read_chr(file.path(clean_dir, "regulations_merged.csv")) %>% distinct(action_id, .keep_all = TRUE)
stopifnot(nrow(recs) == 433)

tableA2 <- recs %>%
  mutate(Source = if_else(record_origin == "FAS", "FAS ordinance database", "Web search"),
         Level = if_else(county_government_rule == "1", "County government", "Municipality"),
         Type = recode(regulation_category, permanent_regulation = "Permanent",
                       temporary_regulation = "Temporary", other_nonbinding = "Non-binding")) %>%
  summarise(Records = n(), `Counted as adopted` = sum(counts_as_adopted_final == "1"),
            .by = c(Source, Level, Type)) %>%
  arrange(Source, Level, Type)
tableA2 <- bind_rows(tableA2, tibble(Source = "Total", Level = "", Type = "",
                                     Records = sum(tableA2$Records),
                                     `Counted as adopted` = sum(tableA2$`Counted as adopted`)))
stopifnot(tail(tableA2$`Counted as adopted`, 1) == 225)

write_csv(tableA2, file.path(results_dir, "Table A2 - Regulation records by source and type.csv"))
writeLines(c("Table A2: Regulation records by source, level and type", "",
             capture.output(print(as.data.frame(tableA2), row.names = FALSE, right = FALSE)), "",
             "Notes: Records not counted are proposals, failed votes, pending or unclear actions,",
             "permissive changes, non-binding actions and duplicates of FAS records."),
           file.path(results_dir, "Table A2 - Regulation records by source and type.txt"))

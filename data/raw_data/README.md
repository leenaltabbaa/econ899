# Raw data folder

All raw data used by the code. Nothing in this folder is changed by the code.
Full provenance and citations are in the main `README.md`.

| File | Source | Description |
|---|---|---|
| `server_country_projects.csv` | Server Country, https://servercountry.org/data/downloads/ | One row per US data-centre project (1,048 projects). Raw download. |
| `fas_regulations_coded.csv` | Federation of American Scientists local data-centre ordinance database, retrieved 2026-10-09 | 42 records for counties with a major announcement, hand-coded by the author. Original FAS columns have a `fas_` prefix. |
| `web_search_regulations.csv` | Collected by the author, completed 2026-10-13 | 391 local regulation records found by web search, with source URL, source type and confidence. |
| `county_search_log.csv` | Collected by the author, completed 2026-10-13 | One row per county searched, with what was searched and found. Documentation only; not read by the code. |

Key coding columns in the two regulation files:

- `jurisdiction_level` / `county_government_rule`: county (or consolidated city-county) vs. city, town or township.
- `regulation_category` (web search): `temporary_regulation` (moratoria, pauses), `permanent_regulation` (zoning, use standards, noise and water rules, bans, ballot measures), `other_nonbinding` (studies, resolutions).
- `regulatory_direction` (web search): `restrictive`, `mixed` (allows data centres only under conditions) or `permissive` (loosens rules; never counted).
- `counts_as_adopted`: 1 if the record is an adopted, binding rule.
- `reported_date`: `YYYY-MM-DD`, `YYYY-MM` or `YYYY`.

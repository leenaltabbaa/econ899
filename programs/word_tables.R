# Helper for writing tables as Word (.docx) files in the usual economics-journal style:
# horizontal rules only (top, under the header, bottom), Times New Roman, title above
# and notes below. Sourced by config.R; used by the table programs.

word_table <- function(df, path, title, notes = NULL, spanner = NULL, numbered = FALSE,
                       se_rows = integer(0), bottom_rows = integer(0), width = 6.5,
                       align_values = "center") {
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  df[] <- lapply(df, function(x) ifelse(is.na(x), "", as.character(x)))
  k <- ncol(df)

  # Leading spaces in the first column mark sub-rows: turn them into an indent
  indent <- nchar(df[[1]]) - nchar(sub("^ +", "", df[[1]]))
  df[[1]] <- sub("^ +", "", df[[1]])

  ft <- flextable::flextable(df)
  if (numbered) {
    ft <- flextable::add_header_row(ft, values = c("", sprintf("(%d)", seq_len(k - 1))), top = FALSE)
  }
  if (!is.null(spanner)) {
    ft <- flextable::add_header_row(ft, values = c("", spanner), colwidths = c(1, k - 1), top = TRUE)
  }

  thick <- officer::fp_border(color = "black", width = 1.5)
  thin  <- officer::fp_border(color = "black", width = 0.75)
  ft <- flextable::border_remove(ft)
  ft <- flextable::hline_top(ft, border = thick, part = "header")
  ft <- flextable::hline_bottom(ft, border = thin, part = "header")
  ft <- flextable::hline_bottom(ft, border = thick, part = "body")
  if (!is.null(spanner)) ft <- flextable::hline(ft, i = 1, j = 2:k, border = thin, part = "header")
  if (numbered) {
    ft <- flextable::hline(ft, i = flextable::nrow_part(ft, "header") - 1, j = 2:k,
                           border = thin, part = "header")
  }

  ft <- flextable::font(ft, fontname = "Times New Roman", part = "all")
  ft <- flextable::fontsize(ft, size = 10, part = "all")
  # Numbers centred, text columns (and the row labels) left-aligned
  is_text <- vapply(df, function(x) any(grepl("[A-Za-z]", x)), logical(1))
  is_text[1] <- TRUE
  ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::align(ft, j = which(is_text), align = "left", part = "all")
  ft <- flextable::padding(ft, padding.top = 1, padding.bottom = 1, part = "all")
  for (i in which(indent > 0)) ft <- flextable::padding(ft, i = i, j = 1, padding.left = 4 + 4 * indent[i])

  # Estimates: space above each coefficient, standard error tight underneath
  coef_rows <- setdiff(se_rows - 1L, 0L)
  if (length(coef_rows)) ft <- flextable::padding(ft, i = coef_rows, padding.top = 5)
  if (length(bottom_rows)) ft <- flextable::padding(ft, i = min(bottom_rows), padding.top = 8)

  # Column widths follow the contents (with a spanner, only the body: headers may wrap).
  # A table that is too wide gives up the space from its widest column; a narrow one
  # is stretched to the page width.
  w <- flextable::dim_pretty(ft, part = if (is.null(spanner)) "all" else "body")$widths + 0.05
  w <- pmax(w, 0.6)
  # Estimate tables: label column as wide as its labels, equal columns for the rest
  if (!is.null(spanner)) w[-1] <- (width - w[1]) / (k - 1)
  if (sum(w) > width) {
    widest <- which.max(w)
    w[widest] <- max(w[widest] - (sum(w) - width), 1.2)
  }
  w  <- w * width / sum(w)
  ft <- flextable::width(ft, width = w)
  # Summary statistics: values right-justified so they line up, with the block of values
  # centred under its (centred) heading
  if (align_values == "right") {
    body_w <- flextable::dim_pretty(ft, part = "body")$widths
    for (j in which(!is_text)) {
      ft <- flextable::align(ft, j = j, align = "right", part = "body")
      ft <- flextable::padding(ft, j = j, padding.right = max(72 * (w[j] - body_w[j]) / 2, 4), part = "body")
    }
  }
  ft <- flextable::height_all(ft, height = 0.17, part = "all")
  ft <- flextable::hrule(ft, rule = "atleast", part = "all")

  txt <- function(x, size, bold = FALSE, italic = FALSE) {
    officer::fpar(officer::ftext(x, officer::fp_text(font.family = "Times New Roman", font.size = size,
                                                    bold = bold, italic = italic)))
  }
  doc <- officer::read_docx()
  doc <- officer::body_add_fpar(doc, txt(title, 11, bold = TRUE))
  doc <- flextable::body_add_flextable(doc, ft, align = "center")
  for (n in notes) doc <- officer::body_add_fpar(doc, txt(n, 9))
  print(doc, target = path)
  invisible(ft)
}

# Coefficient block shared by Table 2 and Table A1: one column per specification
estimate_rows <- function(est) {
  fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
  out <- tibble(Row = c("Announcement effect (ATT)", "", "Event-study average effect", "",
                        "Pre-announcement average", "",
                        "Anticipation (months)", "Counties", "County-months", "Treatment cohorts"))
  for (j in seq_len(nrow(est))) {
    e <- est[j, ]
    out[[e$name]] <- c(paste0(fmt(e$att), stars(e$att, e$se)), paste0("(", fmt(e$se), ")"),
                       paste0(fmt(e$es_att), stars(e$es_att, e$es_se)), paste0("(", fmt(e$es_se), ")"),
                       paste0(fmt(e$pre_att), stars(e$pre_att, e$pre_se)), paste0("(", fmt(e$pre_se), ")"),
                       as.character(e$anticipation), as.character(e$n_counties),
                       format(e$n_obs, big.mark = ","), as.character(e$n_cohorts))
  }
  out
}

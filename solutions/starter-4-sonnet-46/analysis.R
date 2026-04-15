# =============================================================================
# analysis.R — Alberta Income Support Caseload Analysis
#
# Purpose : Load, clean, and shape the IS aggregated caseload data so that all
#           objects required by analysis.qmd are available in the session.
#
# Research questions addressed:
#   RQ1. What is the historic trend of Income Support caseload?
#   RQ2. How does breaking it down by BFE and ETW change the story?
#
# Data    : is-aggregated-data-april-2005-sep-2025.csv
#           Alberta ALSS Open Government data; two-row header, long format.
#
# Usage   : Sourced by analysis.qmd at render time.  Can also be run
#           interactively (Rscript analysis.R or source() in R).
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Packages
# -----------------------------------------------------------------------------
library(readr)      # fast CSV ingestion
library(dplyr)      # data manipulation
library(tidyr)      # pivoting
library(lubridate)  # date parsing helpers
library(scales)     # number formatting
library(plotly)     # interactive HTML charts
library(tibble)     # tibble helpers

# -----------------------------------------------------------------------------
# 1. Ingest
# -----------------------------------------------------------------------------

# Resolve the data path.
# When `quarto render` runs, the working directory is the .qmd file's folder,
# so a relative path from there is sufficient.  When sourced interactively from
# the project root, the same relative path also works.
DATA_PATH <- "../../is-aggregated-data-april-2005-sep-2025.csv"

raw <- read_csv(
  DATA_PATH,
  col_names = c(
    "ref_date", "geography", "measure_type", "measure", "value",
    paste0("drop_", 1:9)
  ),
  skip           = 2,
  show_col_types = FALSE
)

raw <- raw |>
  select(ref_date, geography, measure_type, measure, value) |>
  filter(!is.na(value), trimws(value) != "")

# -----------------------------------------------------------------------------
# 2. Parse dates and clean values
# -----------------------------------------------------------------------------

# Dates are encoded as "YY-Mon" (e.g. "05-Apr", "20-Jan").
# Two-digit years ≤ 25 → 2000s; otherwise 1900s.
parse_ref_date <- function(x) {
  x     <- trimws(x)
  parts <- strsplit(x, "-")
  yr    <- as.integer(vapply(parts, `[[`, character(1), 1))
  mon   <- vapply(parts, `[[`, character(1), 2)
  full_year <- ifelse(yr <= 25L, 2000L + yr, 1900L + yr)
  as.Date(paste(full_year, mon, "01"), format = "%Y %b %d")
}

raw <- raw |>
  mutate(
    date  = parse_ref_date(ref_date),
    value = as.numeric(gsub("[^0-9.]", "", value))
  )

# -----------------------------------------------------------------------------
# 3. Coverage summary (used in QMD narrative)
# -----------------------------------------------------------------------------

coverage_tbl <- raw |>
  group_by(measure_type) |>
  summarise(
    months      = n_distinct(date),
    first_month = format(min(date), "%b %Y"),
    last_month  = format(max(date), "%b %Y"),
    .groups = "drop"
  ) |>
  arrange(first_month)

# -----------------------------------------------------------------------------
# 4. RQ1 — Total caseload series, April 2005 – September 2025
# -----------------------------------------------------------------------------

# "Total Caseload" covers Apr 2005 – Mar 2012.
# "Client Caseload Total" within "Client Type Level" covers Apr 2012 – Sep 2025.
# Concatenating them yields a single unbroken 246-month series.

total_series <- bind_rows(
  raw |>
    filter(measure_type == "Total Caseload") |>
    select(date, value),
  raw |>
    filter(
      measure_type == "Client Type Level",
      measure      == "Client Caseload Total"
    ) |>
    select(date, value)
) |>
  distinct(date, .keep_all = TRUE) |>
  arrange(date)

# Key summary statistics for narrative callouts
total_stats <- total_series |>
  summarise(
    min_value  = min(value),
    min_date   = date[which.min(value)],
    max_value  = max(value),
    max_date   = date[which.max(value)],
    first_val  = first(value),
    last_val   = last(value),
    pct_change = round((last(value) - first(value)) / first(value) * 100, 1)
  )

# Economic disruption bands (for chart annotation)
bands_rq1 <- tibble(
  xstart = as.Date(c("2008-10-01", "2015-01-01", "2020-04-01")),
  xend   = as.Date(c("2011-12-01", "2016-12-01", "2021-08-01")),
  label  = c("GFC", "Oil price\ncollapse", "COVID /\nCERB"),
  fill   = c("#FF980026", "#FF980026", "#2196F320")
)

# Chart 1 — full monthly total caseload
chart_total <- plot_ly() |>
  add_ribbons(
    data        = total_series,
    x           = ~date,
    ymin        = ~rep(0, nrow(total_series)),
    ymax        = ~value,
    color       = I("rgba(33,150,243,0.08)"),
    line        = list(width = 0),
    showlegend  = FALSE,
    hoverinfo   = "skip"
  ) |>
  add_lines(
    data       = total_series,
    x          = ~date,
    y          = ~value,
    line       = list(color = "#1565C0", width = 2),
    name       = "Total caseload",
    hovertemplate = "%{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  # Recession / disruption bands as shapes
  layout(
    title = list(
      text = "Alberta Income Support — Monthly Total Caseload (Apr 2005 – Sep 2025)",
      font = list(size = 15)
    ),
    xaxis = list(title = "", showgrid = FALSE),
    yaxis = list(title = "Active cases", tickformat = ","),
    shapes = list(
      # GFC
      list(type = "rect", xref = "x", yref = "paper",
           x0 = "2008-10-01", x1 = "2011-12-01", y0 = 0, y1 = 1,
           fillcolor = "rgba(255,152,0,0.12)", line = list(width = 0)),
      # Oil price
      list(type = "rect", xref = "x", yref = "paper",
           x0 = "2015-01-01", x1 = "2016-12-01", y0 = 0, y1 = 1,
           fillcolor = "rgba(255,152,0,0.12)", line = list(width = 0)),
      # COVID/CERB
      list(type = "rect", xref = "x", yref = "paper",
           x0 = "2020-04-01", x1 = "2021-08-01", y0 = 0, y1 = 1,
           fillcolor = "rgba(33,150,243,0.10)", line = list(width = 0))
    ),
    annotations = list(
      list(x = as.numeric(as.Date("2010-03-01")), xref = "x", y = 0.97, yref = "paper",
           text = "GFC", showarrow = FALSE, font = list(size = 10, color = "#E65100")),
      list(x = as.numeric(as.Date("2016-01-01")), xref = "x", y = 0.97, yref = "paper",
           text = "Oil price<br>collapse", showarrow = FALSE, font = list(size = 10, color = "#E65100")),
      list(x = as.numeric(as.Date("2020-10-01")), xref = "x", y = 0.97, yref = "paper",
           text = "COVID/<br>CERB", showarrow = FALSE, font = list(size = 10, color = "#1565C0"))
    ),
    hovermode = "x unified",
    legend    = list(orientation = "h", y = -0.12)
  )

# -----------------------------------------------------------------------------
# 5. RQ2 — BFE vs ETW breakdown (April 2012 onward)
# -----------------------------------------------------------------------------

# Extract the three ETW sub-types and the BFE total
bfe_etw_raw <- raw |>
  filter(
    measure_type == "Client Type Level",
    measure %in% c(
      "BFE - Total",
      "ETW - Working Total",
      "ETW - Not Working (Available for Work) Total",
      "ETW - Not Working (Unavailable for Work) Total"
    )
  ) |>
  select(date, measure, value)

# Short labels for chart legend
label_map <- c(
  "BFE - Total"                                     = "BFE",
  "ETW - Working Total"                             = "ETW – Working",
  "ETW - Not Working (Available for Work) Total"    = "ETW – Available",
  "ETW - Not Working (Unavailable for Work) Total"  = "ETW – Unavailable"
)

bfe_etw <- bfe_etw_raw |>
  mutate(group = label_map[measure]) |>
  arrange(date, group)

# Wide format (one column per group) — useful for stacked area
bfe_etw_wide <- bfe_etw |>
  select(date, group, value) |>
  pivot_wider(names_from = group, values_from = value)

# BFE vs ETW total (collapse ETW sub-types)
bfe_etw_summary <- bfe_etw |>
  mutate(client_type = ifelse(startsWith(group, "BFE"), "BFE", "ETW")) |>
  group_by(date, client_type) |>
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop")

# ETW breakdown only (three sub-series)
etw_breakdown <- bfe_etw |>
  filter(startsWith(group, "ETW")) |>
  arrange(date, group)

# Colour palette (accessible)
palette_summary <- c("BFE" = "#D32F2F", "ETW" = "#1976D2")
palette_etw     <- c(
  "ETW – Working"      = "#388E3C",
  "ETW – Available"    = "#F57C00",
  "ETW – Unavailable"  = "#7B1FA2"
)

# Chart 2 — BFE vs ETW total lines
chart_bfe_etw <- plot_ly() |>
  add_lines(
    data             = bfe_etw_summary |> filter(client_type == "BFE"),
    x                = ~date,
    y                = ~value,
    name             = "BFE",
    line             = list(color = palette_summary["BFE"], width = 2.5),
    hovertemplate    = "BFE  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data             = bfe_etw_summary |> filter(client_type == "ETW"),
    x                = ~date,
    y                = ~value,
    name             = "ETW (total)",
    line             = list(color = palette_summary["ETW"], width = 2.5),
    hovertemplate    = "ETW  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  layout(
    title     = list(
      text = "BFE vs ETW Caseload (Apr 2012 – Sep 2025)",
      font = list(size = 15)
    ),
    xaxis     = list(title = "", showgrid = FALSE),
    yaxis     = list(title = "Active cases", tickformat = ","),
    hovermode = "x unified",
    legend    = list(orientation = "h", y = -0.12)
  )

# Chart 3 — ETW sub-type breakdown
chart_etw_detail <- plot_ly() |>
  add_lines(
    data          = etw_breakdown |> filter(group == "ETW – Working"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Working",
    line          = list(color = palette_etw["ETW – Working"], width = 2),
    hovertemplate = "ETW–Working  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data          = etw_breakdown |> filter(group == "ETW – Available"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Available",
    line          = list(color = palette_etw["ETW – Available"], width = 2),
    hovertemplate = "ETW–Available  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data          = etw_breakdown |> filter(group == "ETW – Unavailable"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Unavailable",
    line          = list(color = palette_etw["ETW – Unavailable"], width = 2),
    hovertemplate = "ETW–Unavailable  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  layout(
    title     = list(
      text = "ETW Sub-type Breakdown (Apr 2012 – Sep 2025)",
      font = list(size = 15)
    ),
    xaxis     = list(title = "", showgrid = FALSE),
    yaxis     = list(title = "Active cases", tickformat = ","),
    hovermode = "x unified",
    legend    = list(orientation = "h", y = -0.12)
  )

# Chart 4 — Stacked area: BFE + ETW sub-types
chart_stacked <- plot_ly() |>
  add_lines(
    data          = bfe_etw |> filter(group == "BFE"),
    x             = ~date,
    y             = ~value,
    name          = "BFE",
    stackgroup    = "one",
    fillcolor      = "rgba(211,47,47,0.55)",
    line          = list(color = "rgba(211,47,47,0.8)", width = 1),
    hovertemplate = "BFE  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data          = bfe_etw |> filter(group == "ETW – Unavailable"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Unavailable",
    stackgroup    = "one",
    fillcolor      = "rgba(123,31,162,0.45)",
    line          = list(color = "rgba(123,31,162,0.7)", width = 1),
    hovertemplate = "ETW–Unavailable  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data          = bfe_etw |> filter(group == "ETW – Available"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Available",
    stackgroup    = "one",
    fillcolor      = "rgba(245,124,0,0.45)",
    line          = list(color = "rgba(245,124,0,0.7)", width = 1),
    hovertemplate = "ETW–Available  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  add_lines(
    data          = bfe_etw |> filter(group == "ETW – Working"),
    x             = ~date,
    y             = ~value,
    name          = "ETW – Working",
    stackgroup    = "one",
    fillcolor      = "rgba(56,142,60,0.45)",
    line          = list(color = "rgba(56,142,60,0.7)", width = 1),
    hovertemplate = "ETW–Working  %{x|%b %Y}: %{y:,.0f}<extra></extra>"
  ) |>
  layout(
    title     = list(
      text = "Stacked Caseload by Client Type (Apr 2012 – Sep 2025)",
      font = list(size = 15)
    ),
    xaxis     = list(title = "", showgrid = FALSE),
    yaxis     = list(title = "Active cases", tickformat = ","),
    hovermode = "x unified",
    legend    = list(orientation = "h", y = -0.14)
  )

# -----------------------------------------------------------------------------
# 6. Share-of-total over time (BFE vs ETW)
# -----------------------------------------------------------------------------

bfe_etw_share <- bfe_etw_summary |>
  group_by(date) |>
  mutate(share = value / sum(value) * 100) |>
  ungroup()

chart_share <- plot_ly() |>
  add_lines(
    data          = bfe_etw_share |> filter(client_type == "BFE"),
    x             = ~date,
    y             = ~share,
    name          = "BFE share",
    line          = list(color = palette_summary["BFE"], width = 2, dash = "solid"),
    hovertemplate = "BFE  %{x|%b %Y}: %{y:.1f}%%<extra></extra>"
  ) |>
  add_lines(
    data          = bfe_etw_share |> filter(client_type == "ETW"),
    x             = ~date,
    y             = ~share,
    name          = "ETW share",
    line          = list(color = palette_summary["ETW"], width = 2, dash = "dash"),
    hovertemplate = "ETW  %{x|%b %Y}: %{y:.1f}%%<extra></extra>"
  ) |>
  layout(
    title     = list(
      text = "BFE vs ETW Share of Caseload (%)",
      font = list(size = 15)
    ),
    xaxis     = list(title = "", showgrid = FALSE),
    yaxis     = list(title = "Share (%)", ticksuffix = "%", range = c(0, 100)),
    hovermode = "x unified",
    legend    = list(orientation = "h", y = -0.12)
  )

# -----------------------------------------------------------------------------
# End of analysis.R
# Exported objects (consumed by analysis.qmd):
#   raw, total_series, total_stats, coverage_tbl,
#   bfe_etw, bfe_etw_summary, etw_breakdown, bfe_etw_share,
#   chart_total, chart_bfe_etw, chart_etw_detail, chart_stacked, chart_share
# -----------------------------------------------------------------------------

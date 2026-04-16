options(scipen = 999)
raw_path <- "../../is-aggregated-data-april-2005-sep-2025.csv"
raw <- read.csv(raw_path, skip = 1, stringsAsFactors = FALSE, check.names = FALSE, strip.white = TRUE)
cat('read', nrow(raw), 'rows\n')
raw <- raw[, 1:5]
names(raw) <- gsub("[^A-Za-z0-9]+", "_", trimws(names(raw)))
print(names(raw))
pick_col <- function(nm, pattern) {
  idx <- grep(pattern, nm, ignore.case = TRUE)
  if (length(idx) == 0) return(NA_character_)
  nm[idx[1]]
}

date_col <- pick_col(names(raw), "^Ref_Date")
geo_col <- pick_col(names(raw), "^Geography")
type_col <- pick_col(names(raw), "^Measure_Type")
measure_col <- pick_col(names(raw), "^Measure$")
value_col <- pick_col(names(raw), "^Value")
print(c(date_col, geo_col, type_col, measure_col, value_col))
names(raw)[names(raw) == date_col] <- "Ref_Date"
names(raw)[names(raw) == geo_col] <- "Geography"
names(raw)[names(raw) == type_col] <- "Measure_Type"
names(raw)[names(raw) == measure_col] <- "Measure"
names(raw)[names(raw) == value_col] <- "Value"
print(names(raw))
raw$Date <- as.Date(paste0("01-", raw$Ref_Date), format = "%d-%y-%b")
raw$Value <- as.numeric(gsub("[^0-9.-]", "", raw$Value))
cat('done parse\n')
raw <- raw[!is.na(raw$Date) & !is.na(raw$Value), c("Date", "Geography", "Measure_Type", "Measure", "Value")]
cat('filtered', nrow(raw), 'rows\n')

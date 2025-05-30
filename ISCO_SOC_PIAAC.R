library(iscoCrosswalks)
library(data.table)
library(haven)

data <- read_dta("C:/Users/bmmur/UH-ECON Dropbox/Brian Murphy/Chinhui Work/PIAAC/Data/piaac_cleaned.dta")
setDT(data)

data[, occ_2 := sprintf("%03s", as.character(occ_2))]

data[, job := occ_2]
data[, value := 1]

mapped <- isco_soc_crosswalk(
  data,
  isco_lvl = 2,
  soc_lvl = "soc_4",
  brkd_cols = NULL,
  indicator = FALSE
)

write_dta(mapped, "C:/Users/bmmur/UH-ECON Dropbox/Brian Murphy/Chinhui Work/PIAAC/Data/piaac_with_soc.dta")

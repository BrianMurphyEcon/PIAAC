install.packages("devtools")
devtools::install_github("Guidowe/occupationcross") 
install.packages("tidyverse")
install.packages("haven")

library(occupationcross)
library(tidyverse)
library(haven)

onet <- read_dta("C:/Users/bmmur/UH-ECON Dropbox/Brian Murphy/Chinhui Work/PIAAC/Data/1990_2010_Merge_DOT_ONET.dta")

onet <- onet %>%
  mutate(occ2010 = as.character(occ2010))

onet_crossed <- reclassify_to_isco08(
  base = onet,
  variable = occ2010,
  classif_origin = "Census2010",
  add_major_groups = TRUE,
  add_skill = TRUE,
  code_titles = TRUE
)

onet_crossed <- onet_crossed %>%
  rename(
    ISCO_title = `ISCO.title`
  )

names(onet_crossed)


write_dta(onet_crossed, "C:/Users/bmmur/UH-ECON Dropbox/Brian Murphy/Chinhui Work/PIAAC/Data/onet_with_isco08.dta")



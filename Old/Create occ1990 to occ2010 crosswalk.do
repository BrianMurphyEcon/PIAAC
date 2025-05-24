
use "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\PIAAC\crosswalks\usa_00026.dta", clear

drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
duplicates drop occ2010, force

save "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\PIAAC\crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", replace

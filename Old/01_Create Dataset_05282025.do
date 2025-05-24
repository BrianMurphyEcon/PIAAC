use "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\PIAAC\crosswalks\usa_00026.dta", clear

drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
duplicates drop occ2010, force

save "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\PIAAC\crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", replace

import excel using "$crosswalks\BrianOccCodeCrosswalk.xls", sheet("2010OccCodeList") firstrow clear
destring occ2010, replace ignore(" ") 
duplicates list occ2010
drop if occ2010 == .
save "$crosswalks\BrianOccCodeCrosswalk.dta", replace

use "$crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", clear
merge m:1 occ2010 using "$crosswalks\BrianOccCodeCrosswalk.dta"
rename occ1990 occ1990u
drop _merge
save "$crosswalks\1990_2010_Partial.dta", replace

*use "$crosswalks\1990_2010_Partial.dta", clear
*drop SOCCode
*rename occsoc SOCCode
*keep if _merge1 == 1
*save "$crosswalks\SOC_Fail.dta"

*use "$crosswalks\1990_2010_Partial.dta", clear
*drop SOCCode
*rename occsoc SOCCode
*merge m:1 SOCCode using "$crosswalks\SOC_Fail.dta", keep(1 3)
*drop if _merge1 == 2
*save "$crosswalks\1990_2010_SOC_Final.dta", replace

use "$crosswalks\1990_2010_Partial.dta", clear

use "$crosswalks\1990_2010_Partial.dta", clear
merge m:1 occ1990u using "$crosswalks\DOT_ONET_time_occ1990u.dta", keep(3)
save "$data\1990_2010_Merge_DOT_ONET", replace

import excel using "$crosswalks\isco_soc_crosswalk.xls", sheet("ISCO-08 to 2010 SOC") firstrow clear
destring ISCO08Code, replace ignore(" ") 
destring SOCCode, replace ignore(" ")
duplicates list SOCCode
replace SOCCode = subinstr(SOCCode, "-", "", .)
save "$crosswalks\isco_soc_crosswalk.dta", replace

use "$crosswalks\isco_soc_crosswalk.dta", clear

use "$data\1990_2010_Merge_DOT_ONET", clear
drop _merge
tostring SOCCode occsoc, replace force
replace SOCCode = occsoc if missing(SOCCode)
drop occsoc
replace SOCCode = subinstr(SOCCode, "-", "", .)
save "$data\1990_2010_Merge_DOT_ONET_copy", replace

use "$crosswalks\isco_soc_crosswalk.dta", clear
merge m:1 SOCCode using "$data\1990_2010_Merge_DOT_ONET_copy"
drop Comment81711
drop part
drop _merge
save "$crosswalks\allcrosswalk.dta", replace

use "$data\piaac_cleaned", clear

rename occ_4 ISCO08Code

merge m:m ISCO08Code using "$crosswalks\allcrosswalk.dta"

drop if ISCO08Code == .
drop if _merge == 1
drop if ztask_routine == .

save "$data\piaac_merged_final.dta", replace
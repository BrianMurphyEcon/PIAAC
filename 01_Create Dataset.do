use "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\Chinhui Work\PIAAC\crosswalks\usa_00026.dta", clear
drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
duplicates drop occ2010, force
save "$crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", replace

use "$crosswalks\BrianOccCodeCrosswalk.dta", clear
replace SOCCode = subinstr(SOCCode, "-", "", .)
save "$temp\BrianOccCodeCrosswalk_clean.dta", replace

use "$crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", clear
merge m:1 occ2010 using "$temp\BrianOccCodeCrosswalk_clean.dta", keep(1 3)
rename occ1990 occ1990u
drop _merge
tostring SOCCode, replace
tostring occsoc, replace
replace SOCCode = occsoc if missing(SOCCode) & !missing(occsoc)
save "$temp\1990_2010_Partial_Cleaned.dta", replace

use "$data\1990_2010_Merge_DOT_ONET.dta", clear
replace SOCCode = subinstr(SOCCode, "-", "", .)
drop _merge
replace SOCCode = occsoc if missing(SOCCode) & !missing(occsoc)
save "$temp\1990_2010_Merge_DOT_ONET_cleaned.dta", replace

use "$temp\1990_2010_Partial_Cleaned.dta", clear
merge m:1 occsoc using "$temp\1990_2010_Merge_DOT_ONET_cleaned.dta", keep(1 3)
save "$temp\1990_2010_Merged_DOT_ONET_Final.dta", replace

use "$crosswalks\isco_soc_crosswalk.dta", clear
replace SOCCode = subinstr(SOCCode, "-", "", .)
replace SOCCode = trim(SOCCode)
duplicates drop SOCCode, force
save "$temp\isco_soc_crosswalk_clean.dta", replace

use "$temp\1990_2010_Merged_DOT_ONET_Final.dta", clear
drop _merge
tostring SOCCode occsoc, replace force
replace SOCCode = occsoc if missing(SOCCode)
drop occsoc
replace SOCCode = trim(SOCCode)
replace SOCCode = subinstr(SOCCode, "-", "", .)
merge m:1 SOCCode using "$temp\isco_soc_crosswalk_clean.dta"
drop Comment81711 part _merge
save "$crosswalks\allcrosswalk.dta", replace

use "$crosswalks\allcrosswalk.dta", clear
duplicates report SOCCode
duplicates drop SOCCode, force
tostring ISCO08Code, replace
save "$crosswalks\allcrosswalk.dta", replace


use "$data\piaac_cleaned", clear

rename occ_4 ISCO08Code
tostring ISCO08Code, replace
replace ISCO08Code = trim(ISCO08Code)
replace ISCO08Code = subinstr(ISCO08Code, "-", "", .)

merge m:1 ISCO08Code using "$crosswalks\allcrosswalk.dta"

drop if ISCO08Code == ""
drop if _merge == 1
drop if ztask_routine == .

save "$data\piaac_merged_final.dta", replace
/*
use "$data\usa_00027.dta", clear

drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
duplicates drop occ2010, force
save "$temp\ACS_occ2010CW", replace

merge 1:1 occ2010 using "$temp\BrianOccCodeCrosswalk_clean.dta", keep(1 3)

drop _merge
replace SOCCode = occsoc if missing(SOCCode) & !missing(occsoc)
save "$temp\soccode_merge.dta", replace

use "$crosswalks\isco_soc_crosswalk", clear
duplicates drop SOCCode, force
merge 1:1 SOCCode using "$temp\soccode_merge.dta"
drop Comment81711 part
*/

*** Use No X Excel Sheet
/*
import excel using "$crosswalks\2010_to_SOC_NOX.xlsx", firstrow clear
rename SOCcode SOCCode
save "$crosswalks\2010_to_SOC_NOX.dta", replace
*/

use "$crosswalks\2010_to_SOC_NOX.dta", clear
rename CensusCode occ2010
drop if SOCCode == ""
drop if occ2010 == "9830" // dropping unspecified military, since it has the same SOCCode as unemployed.
gen SOCCode_nodash = subinstr(SOCCode, "-", "", .)
destring SOCCode_nodash, replace
drop SOCCode
rename SOCCode_nodash SOCCode
destring occ2010, replace force
destring SOCCode, replace force
merge m:1 occ2010 using "$temp\ACS_occ2010CW"
drop _merge
duplicates list SOCCode 
save "$temp\3column.dta", replace

** Now, for proof of concept, drop duplicates of soc in isco soc cw, and merge above

use "$crosswalks\isco_soc_crosswalk", clear
destring SOCCode, replace force
duplicates drop SOCCode, force
merge 1:m SOCCode using "$temp\3column"
export excel "$crosswalks\CW_uniqueSOC.xlsx", firstrow(variables) replace 

** Now, for proof of concept, keep ALL SOC Codes.
use "$crosswalks\isco_soc_crosswalk", clear
destring SOCCode, replace force
merge m:m SOCCode using "$temp\3column"
export excel "$crosswalks\CW_ALLSOC.xlsx", firstrow(variables) replace 
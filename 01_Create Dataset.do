* Step 1: Create a Census 2010 to Census 1990 Crosswalk, also including messy SOC Code

use "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\Chinhui Work\PIAAC\crosswalks\usa_00026.dta", clear
drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
duplicates drop occ2010, force
save "$crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", replace

* Step 2: Merge this with the ONET Measures

use "$crosswalks\occ2010_occ1990_occsoc_crosswalk.dta", clear
merge 1:1 occ2010 using "$temp\BrianOccCodeCrosswalk_clean.dta", keep(1 3)
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

* Step 3: Run the R Code: This code essentially takes the 2010 Census Code and Maps it to the ISCO Code
* From here, we just need to merge PIAAC to output from R
* Duplicates of ISCO08, take the average


use "$data\onet_with_isco08", clear
drop if ISCO08 == .
drop occ1990u occ2010 occsoc Occupation2010Description SOCCode Census SOC ISCO_title skill_level major_group _merge

collapse (mean) ehf finger dcp sts math zehf zfinger zdcp zsts zmath ztask_abstract ztask_routine ztask_manual noise hot light contami cramped vibrant radiate infection high_place hazard_condi hazard_equip burn_cut zrequire_social_onet1998 zmath_onet1998 zroutine_onet1998 zsocskills_onet1998 zservice_onet1998 zcustomer_onet1998 zinteract_onet1998 zcontact_onet1998 zabsanal_den_onet1998 zmanual_den_onet1998 zroutine_den_onet1998 znoise zhot zlight zcontami zcramped zvibrant zradiate zinfection zhigh_place zhazard_condi zhazard_equip zburn_cut bunching_ratio zbunching overwork_ratio zoverwork zonet_ch_1 zonet_ch_2 zonet_ch_3 zonet_ch_4 zonet_ch_5, by(ISCO08)
save "$data\onet_with_isco08_collapsed", replace

use "$data\piaac_cleaned", clear
keep if age >= 18
keep if age <=65
keep if hours >= 30
drop if hours == .
keep if emp == 1

** In Our Sample, we Have 100,169 people between the ages of 18 to 65 who are employed, and work over 30 hours a week
gen no_occ4 = (occ_4 == . )
tab no_occ4

** 20,871 do not have an occ_4 score reported. 79,298 have an occ_4

rename occ_4 ISCO08
merge m:1 ISCO08 using "$data\onet_with_isco08_collapsed"

count if !missing(ISCO08)
count if !missing(occ_2)
count if !missing(ztask_abstract)

gen occ_4_nomatch = (!missing(ISCO08) & ztask_abstract == .)
tab occ_4_nomatch

* Of the 79,298 have an occ_4, 27,872 does not have a match on the occ_4 the crosswalk on DOT_ONET
* Leaves us with 51,426 people with matched occ_4

tab occ_4_nomatch no_occ4


save "$data\piaac_merged_isco_final.dta", replace



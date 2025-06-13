use "$data\DOT_ONET_time_occ1990u", clear
rename occ1990u occ1990
merge 1:m occ1990 using "$crosswalks\CW_uniqueSOC_revision_4.dta"

use "$crosswalks\CW_uniqueSOC_revision_4.dta", clear
*duplicates drop occ1990, force
rename occ1990 occ1990u
merge m:1 occ1990u using "$data\DOT_ONET_time_occ1990u", keep(3)

sort ISCO08Code

use "C:\Users\bmmur\OneDrive\Desktop\usa_00028.dta\usa_00028.dta", clear
drop if missing(occ1990) | missing(occ2010) | missing(occsoc)
keep occ1990 occ2010 occsoc
*duplicates drop occ2010, force // 452 unique occ2010
duplicates drop occ1990, force // 339 unique occ1990

* Switch Crosswalk to Stata

import excel "$crosswalks\CW_uniqueSOC_revision_manualupdate.xlsx", firstrow clear
drop _merge
duplicates drop ISCO08Code, force
save "$crosswalks\Brian_Master.dta", replace

** STEP 2: Pull ISCO, Selection Statement, 

use "$data\piaac_cleaned", clear

*Selection Statement
keep if hours >=30
keep if age >= 18
keep if age <= 65
keep if female == 0
drop if occ_4 ==.
rename occ_4 ISCO08Code

* Count Obs for Each ISCO Code
bysort ISCO08Code: gen n_obs = _N
*duplicates drop ISCO08Code, force
merge m:1 ISCO08Code using "$crosswalks\Brian_Master.dta"
*merge 1:m ISCO08Code using "$crosswalks\CW_uniqueSOC_revision_4.dta"
keep ISCO08Code occ1990 n_obs _merge
duplicates drop ISCO08Code, force // This command is kept for the first preserve
drop _merge
save "$temp\PIACC_Master_merge", replace

* Now, merge back to Master

use "$temp\PIACC_Master_merge", clear
merge m:m ISCO08Code using "$crosswalks\Brian_Master.dta"
drop _merge

preserve	
	
	drop if missing(ISCO08Code) | missing(occ1990)
    
    contract occ1990 ISCO08Code
	contract occ1990, freq(n_ISCO08Codes)
	keep if n_ISCO08Codes > 1
	tempfile multi_mapping
    save "`multi_mapping'", replace
	
	use "$temp\PIACC_Master_merge", clear
	merge 1:m ISCO08Code using "$crosswalks\Brian_Master.dta"
	drop if missing(ISCO08Code) | missing(occ1990)

	merge m:1 occ1990 using "`multi_mapping'", keep(3) nogenerate
	sort occ1990 ISCO08Code
	
	duplicates drop ISCO08Code, force
	
	export excel "$crosswalks\PIAAC_occ1990_multiple_isco.xlsx", firstrow(variables) replace

restore
	
preserve	
	
	drop if missing(ISCO08Code) | missing(occ1990)
    
    contract ISCO08Code occ1990
	contract ISCO08Code, freq(n_occ1990)
	keep if n_occ1990 > 1
	tempfile multi_mapping2
    save "`multi_mapping2'", replace
	
	use "$temp\PIACC_Master_merge", clear
	sort occ1990
	duplicates drop occ1990, force
	merge 1:m ISCO08Code using "$crosswalks\Brian_Master.dta"
	drop if missing(ISCO08Code) | missing(occ1990)

	merge m:1 ISCO08Code using "`multi_mapping2'", keep(3) nogenerate
	sort occ1990 ISCO08Code
	duplicates drop ISCO08Code, force
	
	export excel "$crosswalks\PIAAC_isco_multiple_occ1990.xlsx", firstrow(variables) replace

restore


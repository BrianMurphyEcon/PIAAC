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
duplicates drop occ2010, force // 452 unique occ2010
*duplicates drop occ1990, force // 339 unique occ1990
save "$temp\CW2000Census.dta", replace

* Switch Crosswalk to Stata

import excel "$crosswalks\Master_Crosswalk.xlsx", firstrow clear
drop _merge
*duplicates drop ISCO08Code, force
*drop if occ1990 == .
save "$crosswalks\Master_Crosswalk.dta", replace

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
keep ISCO08Code n_obs
duplicates drop ISCO08Code, force

merge 1:m ISCO08Code using "$crosswalks\Brian_Master.dta", keep(3)

keep ISCO08Code n_obs occ1990 _merge
sort ISCO08Code
duplicates drop ISCO08Code occ1990, force
drop if occ1990 == .
drop if ISCO08Code == .

* Unique Occ1990 to Unique ISCO
bysort ISCO08Code (occ1990): gen n_occ1990_per_isco = .
bysort ISCO08Code (occ1990): replace n_occ1990_per_isco = _N 

* Unique ISCO to many occ1990u
bysort occ1990 (ISCO08Code): gen n_isco_per_occ1990 = .
bysort occ1990 (ISCO08Code): replace n_isco_per_occ1990 = _N
sort ISCO08Code
sort occ1990

* Save cases where there is only 1 occ1990 for each ISCO08
keep if n_occ1990_per_isco == 1
drop _merge
save "$crosswalks\UniqueOcc1990.dta", replace


* Understand what happens when occ1990 is missing: how big of a problem is this?
preserve
	duplicates drop ISCO08Code, force

	egen total_obs = total(n_obs)
	egen missing_occ1990_obs = total(n_obs) if missing(occ1990)
	egen nonmissing_occ1990_obs = total(n_obs) if !missing(occ1990)
	di "missing: " missing_occ1990_obs[1]
	gen pct_lost = (missing_occ1990_obs / total_obs) * 100

	di "Percentage of observations that would be lost: " %4.2f pct_lost[1] "%" // 28.6%
restore

* Understand what happens when 1 ISCO maps to multiple occ1990
preserve
	keep if _merge == 3
	duplicates drop ISCO08Code occ1990, force
	drop if occ1990 == .
	bysort ISCO08Code: gen n_occ1990_per_isco = _N
	gen multi_mapping = (n_occ1990_per_isco > 1)
	
	bysort ISCO08Code: gen flag = (_n == 1)
	
	keep if flag == 1
	summarize n_obs 
	local total_merge3 = r(sum)
	di "Total observations with _merge==3: " `total_merge3'
	
	summarize n_obs if multi_mapping == 1
	local lost_obs = r(sum)
	di "Observations with ISCO codes mapping to multiple occ1990: " `lost_obs'
	
	summarize n_obs if multi_mapping == 0
	local remaining_obs = r(sum)
	di "Observations that would remain: " `remaining_obs'

	* Calculate percentage lost
	local pct_lost = (`lost_obs' / `total_merge3') * 100
	di "Percentage of observations that would be lost: " %4.2f `pct_lost' "%" // 65% 
restore



preserve
	keep if _merge == 3
	duplicates drop occ1990 ISCO08Code, force
	drop if occ1990 == .
	bysort occ1990: gen n_occ1990 = _N
	gen multi_mapping = (n_occ1990 > 1)
	
	bysort occ1990: gen flag = (_n == 1)
	
	keep if flag == 1
	summarize n_obs 
	local total_merge3 = r(sum)
	di "Total observations with _merge==3: " `total_merge3'
	
	summarize n_obs if multi_mapping == 1
	local lost_obs = r(sum)
	di "Observations with ISCO codes mapping to multiple occ1990: " `lost_obs'
	
	summarize n_obs if multi_mapping == 0
	local remaining_obs = r(sum)
	di "Observations that would remain: " `remaining_obs'

	* Calculate percentage lost
	local pct_lost = (`lost_obs' / `total_merge3') * 100
	di "Percentage of observations that would be lost: " %4.2f `pct_lost' "%" // 65% 
restore



*duplicates drop ISCO08Code, force
merge m:m ISCO08Code using "$crosswalks\Brian_Master.dta"
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


* Current	
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

* Try with Non-Dropped Dups


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
merge m:m ISCO08Code using "$crosswalks\CW_uniqueSOC_revision_4.dta"
keep ISCO08Code occ1990 n_obs _merge
*duplicates drop ISCO08Code, force // This command is kept for the first preserve
drop _merge
save "$temp\PIACC_Master_merge", replace

* Now, merge back to Master

use "$temp\PIACC_Master_merge", clear
merge m:m ISCO08Code using "$crosswalks\Brian_Master.dta"
drop _merge

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
	merge m:m ISCO08Code using "$crosswalks\Brian_Master.dta"
	drop if missing(ISCO08Code) | missing(occ1990)

	merge m:m ISCO08Code using "`multi_mapping2'", keep(3) nogenerate
	sort occ1990 ISCO08Code
	duplicates drop ISCO08Code, force
	
	export excel "$crosswalks\PIAAC_isco_multiple_occ1990.xlsx", firstrow(variables) replace

restore

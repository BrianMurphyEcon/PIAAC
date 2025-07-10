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

use "$crosswalks\2010_to_SOC_NOX.dta", clear // Manually edited to change SOC codes with "X" in them
rename CensusCode occ2010
drop if SOCCode == ""
drop if occ2010 == "9830" // dropping unspecified military, since it has the same SOCCode as unemployed.\
gen SOCCode_nodash = subinstr(SOCCode, "-", "", .)
destring SOCCode_nodash, replace
drop SOCCode
rename SOCCode_nodash SOCCode
destring occ2010, replace force
destring SOCCode, replace force
merge m:1 occ2010 using "$temp\CW2000Census.dta" // Using 2000 Census gets us 443 matches on occ2010, 10 more than the ACS
drop _merge
duplicates list SOCCode 
drop if SOCCode == .
save "$temp\3column.dta", replace

** Now, for proof of concept, drop duplicates of soc in isco soc cw, and merge above
use "$crosswalks\isco_soc_crosswalk", clear
destring SOCCode, replace force
merge m:1 SOCCode using "$temp\3column"
preserve
	keep if _merge == 3
	save "$temp\merged_step1.dta", replace
restore

* Fix Failed Merges
preserve
	keep if _merge == 2
	tostring SOCCode, gen(SOC_str) format(%06.0f)
	gen SOCCode5 = substr(SOC_str, 1, 5)
	destring SOCCode5, replace
	drop SOC_str
	drop _merge
	drop ISCO08Code ISCO08TitleEN part SOCTitle Comment81711
	save "$temp\unmatched_SOC6_using.dta", replace
restore

preserve
	keep if _merge == 1
	tostring SOCCode, gen(SOC_str) format(%06.0f)
	gen SOCCode5 = substr(SOC_str, 1, 5)
	destring SOCCode5, replace
	drop SOC_str
	drop _merge
	drop Comment81711 part occ2010 SOCtitle occ1990 occsoc
	save "$temp\unmatched_SOC6_master.dta", replace
restore

use "$temp\unmatched_SOC6_master.dta", clear
merge m:m SOCCode5 using "$temp\unmatched_SOC6_using.dta"
preserve
	keep if _merge == 3
	save "$temp\merged_step2.dta", replace
restore

* Fix Failed Merges Again!

preserve
	keep if _merge == 2
	tostring SOCCode, gen(SOC_str) format(%06.0f)
	gen SOCCode4 = substr(SOC_str, 1, 4)
	destring SOCCode4, replace
	drop SOC_str
	drop _merge
	drop ISCO08Code ISCO08TitleEN SOCTitle
	save "$temp\unmatched_SOC6_using4.dta", replace
restore

preserve
	keep if _merge == 1
	tostring SOCCode, gen(SOC_str) format(%06.0f)
	gen SOCCode4 = substr(SOC_str, 1, 4)
	destring SOCCode4, replace
	drop SOC_str
	drop _merge
	drop occ2010 SOCtitle occ1990 occsoc
	save "$temp\unmatched_SOC6_master4.dta", replace
restore

use "$temp\unmatched_SOC6_master4.dta", clear
merge m:m SOCCode4 using "$temp\unmatched_SOC6_using4.dta"
save "$temp\merged_step3.dta", replace

use "$temp\merged_step1.dta", clear
append using "$temp\merged_step2.dta"
append using "$temp\merged_step3.dta"

export excel "$crosswalks\CW_uniqueSOC_revision_4.xlsx", firstrow(variables) replace nolabel
drop _merge
save "$crosswalks\CW_uniqueSOC_revision_4.dta", replace

preserve 
	bysort ISCO08Code (occ1990): gen n_occ1990 = _N
	bysort ISCO08Code occ1990: gen tag = _n == 1

	bysort occ1990 (ISCO08Code): gen n_isco = _N

	gen match_type = .
	replace match_type = 1 if n_isco == 1 & n_occ1990 == 1   // 1-to-1
	replace match_type = 2 if n_isco > 1 & n_occ1990 == 1    // m:1 (many ISCO to 1 occ)
	replace match_type = 3 if n_isco == 1 & n_occ1990 > 1    // 1:m (1 ISCO to many occ)

	keep if tag == 1

	tab match_type, matcell(freq)
	scalar total = freq[1,1] + freq[2,1] + freq[3,1]
	di "Fraction 1:1 = " freq[1,1] / total
	di "Fraction m:1 (ISCO to occ1990) = " freq[2,1] / total
	di "Fraction 1:m (ISCO to multiple occ1990) = " freq[3,1] / total
restore

preserve
	drop if missing(ISCO08Code) | missing(occ1990)
	contract ISCO08Code occ1990
	contract ISCO08Code, freq(n_occ1990)
	keep if n_occ1990 > 1
	tempfile multi
	save "$temp\multi.dta", replace

	use "$temp\merged_step1.dta", clear
	append using "$temp\merged_step2.dta"
	append using "$temp\merged_step3.dta"
	drop _merge
	
	merge m:1 ISCO08Code using "$temp\multi.dta", keep(3)

	export excel "$crosswalks\ISCO_multiple_occ1990_one.xlsx", firstrow(variables) replace
restore

preserve
	drop if missing(ISCO08Code) | missing(occ1990)
	contract occ1990 ISCO08Code
	contract occ1990, freq(n_ISCO08Code)
	keep if n_ISCO08Code > 1
	tempfile multi2
	save "$temp\multi2.dta", replace

	use "$temp\merged_step1.dta", clear
	append using "$temp\merged_step2.dta"
	append using "$temp\merged_step3.dta"
	drop _merge
	
	merge m:1 occ1990 using "$temp\multi2.dta", keep(3)

	export excel "$crosswalks\occ1990_multiple_isco_one.xlsx", firstrow(variables) replace
restore


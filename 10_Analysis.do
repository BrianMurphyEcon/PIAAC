use "$data\piaac_cleaned.dta", clear

gen male = (female == 0)

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(country_name field_num)
export excel using "$output\summary_stats_by_field_country.xlsx", firstrow(variables) replace
restore

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(field_num)
export excel using "$output\summary_stats_by_field.xlsx", firstrow(variables) replace
restore

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(country_name)
export excel using "$output\summary_stats_by_country.xlsx", firstrow(variables) replace
restore

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(country_name occ_1)
export excel using "$output\summary_stats_by_ISCO1_country.xlsx", firstrow(variables) replace
restore

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(country_name occ_2)
export excel using "$output\summary_stats_by_ISCO2_country.xlsx", firstrow(variables) replace
restore

preserve
collapse (mean) age hours male (sd) age_sd=age hours_sd=hours male_sd=male (count) N=age, by(country_name occ_4)
export excel using "$output\summary_stats_by_ISCO4_country.xlsx", firstrow(variables) replace
restore

preserve
keep country_name year_survey
duplicates drop
sort country_name year_survey
export excel using "$output\survey_year.xlsx", firstrow(variables) replace
restore

distinct occ_2

use "$data\piaac_merged_isco_final.dta", clear
keep if female == 0
keep if hours >=30
keep if age >= 18
keep if age <= 65
drop if ISCO08 == .
drop if ztask_abstract ==.
gen overwork2 = (hours >= 50 & hours != .)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
corr ztask_abstract zoverwork2

***** Northern Europe

preserve

keep if region == "NEurope"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(ISCO08)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_NEurope.dta", replace

restore

preserve 
keep if region == "NEurope"
drop _merge
merge m:1 ISCO08 using "$temp\overwork_NEurope.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("Northern Europe: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_NEurope", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("Northern Europe: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_NEurope", replace

restore

*** Scandinavia

preserve

keep if region == "Scandinavia"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_Scandinavia.dta", replace

restore

preserve 
keep if region == "Scandinavia"
drop _merge
merge m:1 occ1990u using "$temp\overwork_Scandinavia.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("Scandinavia: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_Scandinavia", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("Scandinavia: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_Scandinavia", replace

restore

*** SEurope

preserve

keep if region == "SEurope"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_SEurope.dta", replace

restore

preserve 
keep if region == "SEurope"
drop _merge
merge m:1 occ1990u using "$temp\overwork_SEurope.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("SEurope: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_SEurope", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("SEurope: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_SEurope", replace

restore

*** AsiaNZ

preserve

keep if region == "AsiaNZ"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_AsiaNZ.dta", replace

restore

preserve 
keep if region == "AsiaNZ"
drop _merge
merge m:1 occ1990u using "$temp\overwork_AsiaNZ.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("AsiaNZ: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_AsiaNZ", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("AsiaNZ: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_AsiaNZ", replace

restore


*** ExUSSR

preserve

keep if region == "ExUSSR"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_ExUSSR.dta", replace

restore

preserve 
keep if region == "ExUSSR"
drop _merge
merge m:1 occ1990u using "$temp\overwork_ExUSSR.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("ExUSSR: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_ExUSSR", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("ExUSSR: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_ExUSSR", replace

restore


*** SAmerica

preserve

keep if region == "SAmerica"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_SAmerica.dta", replace

restore

preserve 
keep if region == "SAmerica"
drop _merge
merge m:1 occ1990u using "$temp\overwork_SAmerica.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("SAmerica: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_SAmerica", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("SAmerica: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_SAmerica", replace

restore

*** NAmerica

preserve

keep if region == "NAmerica"
gen overwork2 = (hours >= 50 & hours != .)
*collapse (mean) overwork2 [pw=weight], by(ISCO08Code)
collapse (mean) overwork2 [pw=weight], by(occ1990u)
rename overwork2 overwork_ratio2
egen zoverwork2 = std(overwork_ratio2)
save "$temp\overwork_NAmerica.dta", replace

restore

preserve 
keep if region == "NAmerica"
drop _merge
merge m:1 occ1990u using "$temp\overwork_NAmerica.dta"
corr ztask_abstract zoverwork2
twoway (lfitci ztask_abstract zoverwork2), ///
    title("NAmerica: Abstract and Overwork") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)
	
graph save "$output\Abstract_Overwork_NAmerica", replace

twoway (lfitci ztask_routine zoverwork2), ///
    title("NAmerica: Routine and Overwork") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Standardized Overwork") ///
    legend(off)

graph save "$output\Routine_Overwork_NAmerica", replace

restore


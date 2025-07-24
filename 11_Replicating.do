* First, Do Deming:

use "$data\DOT_ONET_time_occ1990u", clear
	merge 1:m occ1990u using "$crosswalks\UniqueOcc1990.dta", keep(3) 
	drop _merge
save "$temp\onet_unique", replace

use "$data\DOT_ONET_time_occ1990u", clear
	merge 1:m occ1990u using "$crosswalks\DenningCaseOcc1990.dta", keep(3) 
	drop _merge

	preserve
		keep occ1990u ISCO08Code
		duplicates drop ISCO08Code, force
		save "$temp\occ1990x", replace
	restore

	collapse (mean) ztask_abstract ztask_routine ztask_manual, by(ISCO08Code)

	merge m:1 ISCO08Code using "$temp\occ1990x"
	drop _merge
	rename occ1990u occ1990x
save "$temp\onet_nonunique", replace

use "$temp\onet_unique", clear
	gen occ1990x = occ1990u
	append using "$temp\onet_nonunique"
save "$temp\taskmeasure_ISCO", replace // there are no duplicates in here either.

*** Now, move to PIAAC Data
use "$data\piaac_cleaned", clear

*Selection Statement
*keep if hours >=39
keep if age >= 25
keep if age <= 54
*keep if female == 0
drop if occ_4 ==.
rename occ_4 ISCO08Code
drop if hours == .

* Change to by country
preserve
	collapse (mean) mean_hours = hours (sd) sd_hours = hours, by(country)
	tempfile stats
	save `stats'
restore

merge m:1 country using `stats', keepusing(mean_hours sd_hours)
drop _merge
gen longhours = hours - 39

gen log_longhours = .
replace log_longhours = log(longhours) if longhours > 0

gen log_hours = .
replace log_hours = log(hours)

merge m:1 ISCO08Code using "$temp\taskmeasure_ISCO", keep(3)
drop if ztask_abstract == .


xi: reghdfe log_longhours female if hours >= 39, vce(cluster occ1990x)
xi: reghdfe log_hours female, vce(cluster occ1990x)

gen hours_cap = hours
replace hours_cap = 40 if hours >= 40 

gen log_hours_cap = .
replace log_hours_cap = log(hours_cap)

xi: reghdfe log_hours_cap female, vce(cluster occ1990x)

collapse (mean) log_longhours log_hours ztask_abstract ztask_routine ztask_manual weight, by(region occ1990x)
drop if region == ""
levelsof region, local(regions)

foreach r of local regions {
    
    preserve
    keep if region == "`r'"

    * Abstract vs Routine
    twoway ///
        (lfitci ztask_abstract log_longhours [aweight=weight]) ///
        (lfitci ztask_routine log_longhours [aweight=weight], clpattern(dash)), ///
        xtitle("Long Hours (z-score)", size(small)) ///
        ytitle("Task Requirement (z-score)") ///
        legend(size(small) order(1 "Routine" 2 "Abstract")) ///
        ylabel(-2(1)3) ///
        title("Region `r': Abstract vs Routine", size(medsmall)) ///
        graphregion(color(white)) ///
        saving("$fig2\region`r'_abstract_routine.gph", replace)

    * Abstract vs Manual
     twoway ///
        (lfitci ztask_abstract log_longhours [aweight=weight]) ///
        (lfitci ztask_manual log_longhours [aweight=weight], clpattern(dash)), ///
        xtitle("Long Hours (z-score)", size(small)) ///
        ytitle("Task Requirement (z-score)") ///
        legend(size(small) order(1 "Manual" 2 "Abstract")) ///
        ylabel(-2(1)3) ///
        title("Region `r': Abstract vs Manual", size(medsmall)) ///
        graphregion(color(white)) ///
        saving("$fig2\region`r'_abstract_manual.gph", replace)

    graph combine ///
        "$fig2/region`r'_abstract_routine.gph" ///
        "$fig2/region`r'_abstract_manual.gph", ///
        title("Figure 2: Region `r' – Task and Long Hours", size(medium)) ///
        graphregion(color(white)) ///
        saving("$fig2\Figure2_region`r'.gph", replace)

    graph export "$fig2\Figure2_region`r'_log_longhours.jpg", replace

	erase "$fig2\region`r'_abstract_routine.gph"
	erase "$fig2\region`r'_abstract_manual.gph"
	erase "$fig2/Figure2_region`r'.gph"
	
    restore
}

*** Replicate Figure 3

use "$data\piaac_cleaned", clear

*Selection Statement
keep if hours >=30
keep if age >= 25
keep if age <= 54
drop if occ_4 ==.
rename occ_4 ISCO08Code
drop if hours == .

preserve
	collapse (mean) mean_hours = hours (sd) sd_hours = hours, by(region)
	tempfile stats
	save `stats'
restore

merge m:1 region using `stats', keepusing(mean_hours sd_hours)
drop _merge
gen zoverwork2 = hours > (mean_hours + sd_hours)

merge m:1 ISCO08Code using "$temp\taskmeasure_ISCO", keep(3)


gen zclaudia=(zonet_ch_1 + zonet_ch_2 + zonet_ch_3 + zonet_ch_4 + zonet_ch_5)/5

label variable ztask_abstract "Abstract"
label variable ztask_routine "Routine"
label variable zoverwork2 "Long Hours"
label variable zonet_ch_1 "Contact with Others"
label variable zonet_ch_2 "Establish and Maintain Relationships"
label variable zonet_ch_3 "Freedom to Make Decisions"
label variable zonet_ch_4 "Structured vs. Unstructured"
label variable zonet_ch_5 "Time Pressure"
label variable zclaudia "O*NET Index"


global X "ztask_abstract ztask_routine ztask_manual"

gen X1 = ztask_abstract
gen X2 = ztask_routine
gen X3 = ztask_manual

global X "X1 X2 X3"

global RAW "region age"

xi: reghdfe female $X [aw=weight], absorb(edu $RAW) vce(cluster occ1990x)

estimates store taskmodel

esttab taskmodel using "$fig3\task_coeff_table.tex", replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) ///
    keep(X1 X2 X3 _cons) ///
    title(Task Effects on Female Indicator)

drop if region == ""
levelsof region, local(regions)

foreach r of local regions {
	preserve
		keep if region == "`r'"
		
		xi: reghdfe female $X [aw=weight], absorb(edu age) vce(cluster occ1990x)
		estimates store region_`r'
	
    restore
}

esttab region_* using "$fig3\task_coeff_region.tex", replace ///
	se label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(X1 X2 X3 _cons) ///
	title("Task Effects on Female Indicator by Region")	///
	collabels(`"`regions'"')

*** Replicate Table 6

use "$data\piaac_cleaned", clear

*Selection Statement
keep if hours >=30
keep if age >= 25
keep if age <= 54
keep if female == 0
drop if occ_4 ==.
rename occ_4 ISCO08Code
drop if hours == .

preserve
	collapse (mean) mean_hours = hours (sd) sd_hours = hours, by(region)
	tempfile stats
	save `stats'
restore

merge m:1 region using `stats', keepusing(mean_hours sd_hours)
drop _merge
gen zoverwork2 = hours > (mean_hours + sd_hours)

merge m:1 ISCO08Code using "$temp\taskmeasure_ISCO", keep(3)

* Create Cognitive Ability
* standardize the exams first, and replace problem solve with literacy

egen zpvnum1 = std(pvnum1)
egen zpvlit1 = std(pvlit1)
egen zpsolve1 = std(pvpsl1)

drop if missing(zpvnum1) & missing(zpvlit1)
gen zcog_score = (zpvnum1 + zpsolve1)/2

gen cog_abstract = zcog_score * ztask_abstract
gen cog_routine = zcog_score * ztask_routine
gen cog_manual = zcog_score * ztask_manual

* Create NonCog
* No good measures

* Create Social

*gen social = task_intrct_advise + task_intrct_coop + task_intrct_neg + task_intrct_present + task_intrct_sharing + task_intrct_teach
*encode social, gen(social_num)
*egen zsocial = std(social_num)
*drop if zsocial == .
drop if wage_log == .

*Mincerian Eq
gen edu_years = .
replace edu_years = 0  if edu == 0
replace edu_years = 6  if edu == 1
replace edu_years = 9  if edu == 2
replace edu_years = 12 if edu == 3
replace edu_years = 14 if edu == 4
replace edu_years = 16 if edu == 5


xi: reghdfe wage_log edu_years age exp2 if country_code_3 == "FRA", vce(cluster occ1990x) 

* Regress

xi: reghdfe wage_log ztask_abstract ztask_routine ztask_manual zcog_score cog_abstract cog_routine cog_manual if country_code_3 == "CHL", absorb(edu age) vce(cluster occ1990x)
estimates store skillreturns

esttab skillreturns using "$tab6\skill_returns.tex", replace ///
    se label star(* 0.10 ** 0.05 *** 0.01) ///
    title("Returns to Skills and Job Task Requirements")

drop if region == ""
levelsof region, local(region)

foreach r of local region {
	preserve
		keep if region == "`r'"
		
		xi: reghdfe wage_log ztask_abstract ztask_routine ztask_manual zcog_score cog_abstract cog_routine cog_manual, absorb(country edu age) vce(cluster occ1990x)
		estimates store skill_`r'
	
    restore
}

esttab skill_* using "$tab6\skill_returns_region.tex", replace ///
	se label star(* 0.10 ** 0.05 *** 0.01) ///
	title("Returns to Skills and Job Task Requirements: by Region")	///
	collabels(`"`country'"')


	
	
	
	
	
* Replicate

use "$data\piaac_cleaned", clear

*Selection Statement
keep if hours >=30
keep if age >= 18
keep if age <= 65
drop if occ_4 ==.
rename occ_4 ISCO08Code
drop if hours == .

preserve
	collapse (mean) mean_hours = hours (sd) sd_hours = hours, by(region)
	tempfile stats
	save `stats'
restore

merge m:1 region using `stats', keepusing(mean_hours sd_hours)
drop _merge
gen zoverwork2 = hours > (mean_hours + sd_hours)

merge m:1 ISCO08Code using "$temp\taskmeasure_ISCO", keep(3)


gen zclaudia=(zonet_ch_1 + zonet_ch_2 + zonet_ch_3 + zonet_ch_4 + zonet_ch_5)/5

label variable ztask_abstract "Abstract"
label variable ztask_routine "Routine"
label variable zoverwork2 "Long Hours"
label variable zonet_ch_1 "Contact with Others"
label variable zonet_ch_2 "Establish and Maintain Relationships"
label variable zonet_ch_3 "Freedom to Make Decisions"
label variable zonet_ch_4 "Structured vs. Unstructured"
label variable zonet_ch_5 "Time Pressure"
label variable zclaudia "O*NET Index"

levelsof region, local(regions)

foreach r of local regions {
    preserve
    keep if region == "`r'"

    eststo clear

    eststo: estpost corr ztask_abstract zoverwork2 zonet_ch_1 zonet_ch_2 zonet_ch_3 zonet_ch_4 zonet_ch_5 zclaudia

    eststo: estpost corr ztask_routine zoverwork2 zonet_ch_1 zonet_ch_2 zonet_ch_3 zonet_ch_4 zonet_ch_5 zclaudia

    esttab est1 est2 using "$tab1/Table1_`r'_Task_Time_Correlations.tex", replace f ///
        cells(b(star fmt(3)) se(par fmt (3)))  ///
        label booktabs collabels(none) noobs compress alignment(D{.}{.}{-1}) ///
        star(* 0.05) ///
        mtitles("Abstract" "Routine") refcat(zonet_ch_1 "" zclaudia "", nolabel) ///
        prehead("Time Requirements")

    restore
}


*** Replicate Table 1

gen T1 = ztask_abstract
gen T2 = ztask_routine
gen T3 = ztask_manual
gen Z1 = zoverwork2

gen num_score = (pvnum2 + pvnum3 + pvnum4 + pvnum5 + pvnum6 + pvnum7 + pvnum8 + pvnum9 + pvnum10)/9
gen probsolve_score = (pvpsl2 + pvpsl3 + pvpsl4 + pvpsl5 + pvpsl6 + pvpsl7 + pvpsl8 + pvpsl9 + pvpsl10)/9
drop if num_score == .

egen znum_score = std(num_score)
egen zprobsolve_score = std(probsolve_score)

gen S1 = znum_score
gen S2 = zprobsolve_score

keep if !missing(female, T1, T2, T3, Z1, region)
keep if hours >=30
keep if age >= 18
keep if age <= 65

eststo clear

xi: reghdfe female T1 T2 T3 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
eststo EQ1

xi: reghdfe female T1 T2 T3 S1 S2 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
eststo EQ2

xi: reghdfe female T1 T2 T3 Z1 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
eststo EQ3

xi: reghdfe female T1 T2 T3 Z1 S1 S2 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
eststo EQ4

esttab EQ1 EQ2 EQ3 EQ4 using "$tab3/Table3_PIAAC_Female_Share_Task_Time.tex", replace f ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    label booktabs nomtitle collabels(none) noobs compress alignment(D{.}{.}{-1}) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    prehead("\textit{Outcome is Female Dummy}") ///
    title("Female Share by Task and Time Requirements (PIAAC)") 
	
*** Now Let's do By Region

levelsof region, local(regions)
eststo clear

foreach r of local regions {
    
    preserve
    keep if region == "`r'"

    xi: reghdfe female T1 T2 T3 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
    eststo EQ1

    xi: reghdfe female T1 T2 T3 S1 S2 [aw=weight], absorb(country#edu_group#age_group)vce(cluster id_unique)
    eststo EQ2

    xi: reghdfe female T1 T2 T3 Z1 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
    eststo EQ3

    xi: reghdfe female T1 T2 T3 Z1 S1 S2 [aw=weight], absorb(country#edu_group#age_group) vce(cluster id_unique)
    eststo EQ4
	
	 esttab EQ1 EQ2 EQ3 EQ4 using "$tab3/Table3_PIAAC_Region`r'.tex", replace f ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        label booktabs nomtitle collabels(none) noobs compress alignment(D{.}{.}{-1}) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        prehead("\textit{Region: `rname' \\\\ Outcome is Female Dummy}") ///
        title("Female Share by Task and Time Requirements: `rname' (PIAAC)")

    restore
}


*** Replicate Yona:

use "$data/piaac_cleaned.dta", clear

keep if inrange(age, 25, 54) & hours < .
drop if occ_4==.
rename occ_4 ISCO08Code

gen longhours    = hours - 39
gen log_hours    = log(hours)
gen log_longhours = .
replace log_longhours = log(longhours) if longhours>0

merge m:1 ISCO08Code using "$temp/taskmeasure_ISCO.dta", keep(match using) nogenerate

preserve

gen log_m = log_hours if female==0
gen log_f = log_hours if female==1
gen d = 1

collapse ///
    (mean) mean_log_m = log_m ///
    (mean) mean_log_f = log_f ///
    (mean) z_abstract = ztask_abstract ///
    (mean) z_routine = ztask_routine  ///
    (mean) z_manual = ztask_manual   ///
    (sum) obs = d, ///
    by(occ1990x)


gen dE = mean_log_m - mean_log_f


twoway ///
	   (lfitci z_abstract dE [aweight=obs], sort) ///
	   (lfitci z_routine  dE [aweight=obs], sort clpattern(dash)), ///
		title("Task Requirements (z‐scores) and the Gender Gap in Long Hours in `r'", ///
			  size(small)) ///
		xtitle("Gender Gap in Log Hours (Men − Women)") ///
		ytitle("Task Requirement (z‐score)") ///
		legend(order(2 "Abstract" 4 "Routine" 1 "95%CI") ///
			   size(small)) ///
		ylabel(-2(1)4) ///
		graphregion(color(white))
	
graph export "$yona/PIAAC_Task_GenderGap.png", replace

restore

*** By Region
gen log_m = log_hours if female==0
gen log_f = log_hours if female==1
gen d = 1

collapse ///
    (mean) mean_log_m=log_m ///
    (mean) mean_log_f=log_f ///
    (mean) z_abstract   = ztask_abstract ///
    (mean) z_routine    = ztask_routine  ///
    (mean) z_manual     = ztask_manual   ///
    (sum) obs = d, ///
    by(region occ1990x)

gen dE = mean_log_m - mean_log_f

drop if region == ""
levelsof region, local(regions)

foreach r of local regions {

preserve 
    keep if region == "`r'"
	
	twoway ///
	   (lfitci z_abstract dE [aweight=obs], sort) ///
	   (lfitci z_routine  dE [aweight=obs], sort clpattern(dash)), ///
		title("Task Requirements (z‐scores) and the Gender Gap in Long Hours in `r'", ///
			  size(small)) ///
		xtitle("Gender Gap in Log Hours (Men − Women)") ///
		ytitle("Task Requirement (z‐score)") ///
		legend(order(2 "Abstract" 4 "Routine" 1 "95%CI") ///
			   size(small)) ///
		ylabel(-2(1)4) ///
		graphregion(color(white))
	
graph export "$yona/PIAAC_Task_GenderGap_`r'.png", replace

restore
}
clear
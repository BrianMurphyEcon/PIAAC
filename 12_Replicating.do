use "$data\piaac_merged_isco_final.dta", clear

*** Replicate Figure 2

keep if hours >=30
keep if age >= 18
keep if age <= 65
keep if female == 0
drop if ISCO08 ==.
drop if ztask_abstract == .

*** Calculate ZOVERWORK BY COUNTRY
gen overwork2 = (hours >= 50 & hours != .)
egen zoverwork2 = std(overwork2), by(country)


collapse (mean) ztask_abstract ztask_routine ztask_manual zoverwork2 weight, by(region ISCO08)

drop if region == ""
levelsof region, local(regions)

foreach r of local regions {
    
    preserve
    keep if region == "`r'"

    * Abstract vs Routine
    twoway ///
        (lfitci ztask_abstract zoverwork2 [aweight=weight]) ///
        (lfitci ztask_routine zoverwork2 [aweight=weight], clpattern(dash)), ///
        xtitle("Long Hours (z-score)", size(small)) ///
        ytitle("Task Requirement (z-score)") ///
        legend(size(small) order(1 "Abstract" 2 "Routine")) ///
        ylabel(-2(1)3) ///
        title("Region `r': Abstract vs Routine", size(medsmall)) ///
        graphregion(color(white)) ///
        saving("$fig2\region`r'_abstract_routine.gph", replace)

    * Abstract vs Manual
     twoway ///
        (lfitci ztask_abstract zoverwork2 [aweight=weight]) ///
        (lfitci ztask_manual zoverwork2 [aweight=weight], clpattern(dash)), ///
        xtitle("Long Hours (z-score)", size(small)) ///
        ytitle("Task Requirement (z-score)") ///
        legend(size(small) order(1 "Abstract" 2 "Manual")) ///
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

    graph export "$fig2\Figure2_region`r'.jpg", replace

	erase "$fig2\region`r'_abstract_routine.gph"
	erase "$fig2\region`r'_abstract_manual.gph"
	erase "$fig2/Figure2_region`r'.gph"
	
    restore
}

*** Replicate Table 1
use "$data\piaac_merged_isco_final.dta", clear

*** Replicate Figure 2

keep if hours >=30
keep if age >= 18
keep if age <= 65
keep if female == 0
drop if ISCO08 ==.
drop if ztask_abstract == .

*** Calculate ZOVERWORK BY COUNTRY
gen overwork2 = (hours >= 50 & hours != .)
egen zoverwork2 = std(overwork2), by(country)

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

*** Replicate Table 3

*** Replicate Table 1
use "$data\piaac_merged_isco_final.dta", clear

keep if hours >=30
keep if age >= 18
keep if age <= 65
drop if ISCO08 ==.
drop if ztask_abstract == .

*** Calculate ZOVERWORK BY COUNTRY
gen overwork2 = (hours >= 50 & hours != .)
egen zoverwork2 = std(overwork2), by(country)

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


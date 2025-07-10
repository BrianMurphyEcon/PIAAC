use "$data\piaac_cleaned", clear

*Selection Statement
keep if hours >=30
keep if age >= 18
keep if age <= 65
*keep if female == 0
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

drop if ztask_abstract == .

describe female age pv*

gen num_score = (pvnum2 + pvnum3 + pvnum4 + pvnum5 + pvnum6 + pvnum7 + pvnum8 + pvnum9 + pvnum10)/9
gen lit_score = (pvlit2 + pvlit3 + pvlit4 + pvlit5 + pvlit6 + pvlit7 + pvlit8 + pvlit9 + pvlit10)/9
gen probsolve_score = (pvpsl2 + pvpsl3 + pvpsl4 + pvpsl5 + pvpsl6 + pvpsl7 + pvpsl8 + pvpsl9 + pvpsl10)/9
drop if num_score == .

xtile num_score_group = num_score, n(10)
xtile probsolve_score_group = probsolve_score, n(10)

** Abstract Tasks: Numer Score
reghdfe ztask_abstract c.num_score##i.female age, absorb(country) cluster(country) resid(resid)
margins female, over(num_score_group) predict(xb)

marginsplot, ///
    xdimension(num_score_group) ///
    title("Predicted Abstract Task Content by Numeracy Decile and Gender") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Numeracy Ability Decile") ///
    legend(order(1 "Male" 2 "Female") pos(6)) ///
    recast(line) ///
    plotopts(lwidth(medthick))
graph export "$output\continuous_predictedabstracttask_gender.png", replace

reghdfe ztask_abstract i.num_score_group##i.female age, absorb(country) cluster(country)

margins female, over(num_score_group)

marginsplot, ///
    xdimension(num_score_group) ///
    title("Predicted Abstract Task Content by Numeracy Decile and Gender") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Numeracy Decile") ///
    legend(order(1 "Male" 2 "Female")) ///
    recast(line)
graph export "$output\decile_predictedabstracttask_gender.png", replace

* Abstract County FE

* For women
reghdfe ztask_abstract c.num_score age if female == 1, absorb(country) cluster(country) resid(resid_f)
predict xb_f, xb
gen country_fe_f = ztask_abstract - xb_f - resid_f

* For men
reghdfe ztask_abstract c.num_score age if female == 0, absorb(country) cluster(country) resid(resid_m)
predict xb_m, xb
gen country_fe_m = ztask_abstract - xb_m - resid_m
preserve 
collapse (mean) country_fe_f country_fe_m, by(country)
gen fe_gap = country_fe_f - country_fe_m
graph bar fe_gap, over(country, sort(1)) ///
    yline(0, lcolor(red) lpattern(dash)) ///
    bar(1, color(gs6)) ///
    title("Gender Gap in Abstract Task Sorting") ///
    ytitle("Fixed Effect Gap") ///
    legend(off)
restore

** Routine Tasks
reghdfe ztask_routine c.num_score##i.female age, absorb(country) cluster(country)
margins female, over(num_score_group) predict(xb)

marginsplot, ///
    xdimension(num_score_group) ///
    title("Predicted Routine Task Content by Numeracy Decile and Gender") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Numeracy Ability Decile") ///
    legend(order(1 "Male" 2 "Female") pos(6)) ///
    recast(line) ///
    plotopts(lwidth(medthick))
graph export "$output\continuous_predictedroutinetask_gender.png", replace

reghdfe ztask_routine i.num_score_group##i.female age, absorb(country) cluster(country)
margins female, over(num_score_group)

marginsplot, ///
    xdimension(num_score_group) ///
    title("Predicted Routine Task Content by Numeracy Decile and Gender") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Numeracy Decile") ///
    legend(order(1 "Male" 2 "Female")) ///
    recast(line)
graph export "$output\decile_predictedRoutinetask_gender.png", replace

** Wage Penalty?

reghdfe wage_log c.num_score##c.ztask_abstract##i.female age edu, absorb(country) cluster(country)

* Decomp
oaxaca ztask_abstract num_score age, by(female)


********************************************************************************
** Problem Solves


** Abstract Tasks: Problem Solving Score
reghdfe ztask_abstract c.probsolve_score##i.female age, absorb(country) cluster(country)
margins female, over(probsolve_score_group) predict(xb)

marginsplot, ///
    xdimension(probsolve_score_group) ///
    title("Predicted Abstract Task Content by Problem Solving Decile and Gender") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Numeracy Ability Decile") ///
    legend(order(1 "Male" 2 "Female") pos(6)) ///
    recast(line) ///
    plotopts(lwidth(medthick))
graph export "$output\continuous_predictedabstracttask_gender_problemsolving.png", replace

reghdfe ztask_abstract i.probsolve_score_group##i.female age, absorb(country) cluster(country)

margins female, over(probsolve_score_group)

marginsplot, ///
    xdimension(probsolve_score_group) ///
    title("Predicted Abstract Task Content by Problem Solving Decile and Gender") ///
    ytitle("Standardized Abstract Task Score") ///
    xtitle("Numeracy Decile") ///
    legend(order(1 "Male" 2 "Female")) ///
    recast(line)
graph export "$output\decile_predictedabstracttask_gender_problemsolving.png", replace


** Routine Tasks
reghdfe ztask_routine c.probsolve_score##i.female age, absorb(country) cluster(country)
margins female, over(probsolve_score_group) predict(xb)

marginsplot, ///
    xdimension(probsolve_score_group) ///
    title("Predicted Routine Task Content by Problem Solving Decile and Gender") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Numeracy Ability Decile") ///
    legend(order(1 "Male" 2 "Female") pos(6)) ///
    recast(line) ///
    plotopts(lwidth(medthick))
graph export "$output\continuous_predictedroutinetask_gender.png", replace

reghdfe ztask_routine i.probsolve_score_group##i.female age, absorb(country) cluster(country)
margins female, over(probsolve_score_group)

marginsplot, ///
    xdimension(probsolve_score_group) ///
    title("Predicted Routine Task Content by Problem Solving Decile and Gender") ///
    ytitle("Standardized Routine Task Score") ///
    xtitle("Numeracy Decile") ///
    legend(order(1 "Male" 2 "Female")) ///
    recast(line)
graph export "$output\decile_predictedRoutinetask_gender.png", replace

** Wage Penalty?

reghdfe wage_log c.probsolve_score##c.ztask_abstract##i.female age edu, absorb(country) cluster(country)

* Decomp
oaxaca ztask_abstract probsolve_score age, by(female)


********************************************************************************
* Sorting Because of Hours Requirements?

reg hours ztask_abstract age edu, cluster(country)
corr ztask_abstract hours

reg hours c.ztask_abstract##i.female age edu, cluster(country)

reghdfe ztask_abstract i.num_score_group##i.female age edu, absorb(country) cluster(country)

reghdfe ztask_abstract i.num_score_group##i.female age edu hours, absorb(country) cluster(country)

reghdfe ztask_abstract i.num_score_group##i.female##i.child age edu, absorb(country) cluster(country)
margins female#child, over(num_score_group)

marginsplot, xdimension(num_score_group) ///
  title("Predicted Abstract Task Score by Skill, Gender, and Parental Status") ///
    legend(order(1 "Men w/o child" 2 "Men w child" 3 "Women w/o child" 4 "Women w/ child")) ///
  ytitle("Standardized Abstract Task Score") ///
  xtitle("Problem-Solving Score Decile") ///
  recast(line)
 graph export "$output\decile_predictedabtracttask_genderwithkids.png", replace
 
********************************************************************************
* By Country
encode country_name, generate(Countrycode)
reg ztask_abstract c.zoverwork##i.Countrycode
margins Countrycode, dydx(zoverwork)
marginsplot, xdimension(Countrycode) ///
    title("Marginal Effect of Overwork on Abstract Tasks by Country")
	
levelsof Countrycode, local(countries)

foreach c of local countries {
    preserve
    keep if Countrycode == `c'

    reghdfe ztask_abstract i.num_score_group##i.female age

    margins female, over(num_score_group)

    marginsplot, ///
        title("Countrycode `c': Abstract Task by Numeracy Decile & Gender") ///
        xdimension(num_score_group) ///
        ytitle("Standardized Abstract Task Score") ///
        xtitle("Numeracy Decile") ///
        legend(order(1 "Male" 2 "Female")) ///
        name(graph_`c', replace) ///
        recast(line)

    graph export "$output\PredictedByCountry/abstractnumeracy_gender_`c'.png", replace
	restore
}
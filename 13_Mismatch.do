use "$data\piaac_merged_final.dta", clear

gen num_score = (pvnum2 + pvnum3 + pvnum4 + pvnum5 + pvnum6 + pvnum7 + pvnum8 + pvnum9 + pvnum10)/9
gen probsolve_score = (pvpsl2 + pvpsl3 + pvpsl4 + pvpsl5 + pvpsl6 + pvpsl7 + pvpsl8 + pvpsl9 + pvpsl10)/9
drop if num_score == .

keep if age >= 25
keep if hours >= 30

egen znum_score = std(num_score)
egen zprobsolve_score = std(probsolve_score)

destring numwork_wle_ca, replace force
destring ictwork_wle_ca, replace force
egen znum_work = std(numwork_wle_ca)
egen zict_work = std(ictwork_wle_ca)

drop if zict_work == .
drop if znum_work == . 

gen mismatch_num = znum_score - znum_work
gen mismatch_psl = zprobsolve_score - zict_work

gen mismatch = (mismatch_num + mismatch_psl) / 2

preserve
collapse (mean) mismatch [pw=weight], by(occ_2 female)
sort occ_2

graph bar mismatch ///
    , over(occ_2, label(angle(45))) ///
      over(female) ///
      bargap(15) ///
      ytitle("Mean mismatch (z-score)") ///
      title("Skill–Job Mismatch by Gender and Occupation")
restore

oaxaca mismatch edlevel3 c_d09, by(female)

destring edlevel3, replace
destring c_d09, replace
reghdfe mismatch i.female edlevel3 c_d09 [aweight=weight], absorb(country occ_2) vce(cluster country)

margins, at(female=(0 1))
marginsplot, xdimension(female) ///
    title("Adjusted Gender Gap in Mismatch") ///
    ytitle("Predicted mismatch") ///
    xlabel(0 "Male" 1 "Female")


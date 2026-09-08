/*=========================================================================*/
*---Table I: Unweighted descriptive statistics---*
* Panel A: full sample, mean, S.D. and quantiles; Panel B: +/-5 discontinuity
* sample, mean and S.D. Grades 5 and 4 only (grade 3 file not provided).
* Output: output/table1.tex, log output/2_table1.log
*
* Course code (same key as 1_clean.do):
*   use / log                           W1 lab s.1, s.12; pset_1 every file
*   local varlist, foreach ... in       W1 lab s.11 (local controls), s.13 (loops)
*   summarize ..., detail               W1 lab s.13 (summarize `var', detail)
*   r(mean) r(sd) r(p10)... into locals W1 lab s.12 (local mean_price = r(mean));
*                                       W4 lab Q7 (local m1 : display %5.3f r(mean))
*   count if -> r(N)                    W2 lab Q4b; W4 lab Q11 (r(N) into a scalar)
*   file open / write / close, trim()   W1 lab s.12; W4 lab Q7 and Q11 (LaTeX tables)
*   display with locals                 W1 lab s.12
*   Nested macro `lab_`v'' for row labels is OUR CHANGE (W1 s.11 locals, nested)
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/2_table1.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---rows of the table, in the paper's order, and their labels (Table I notes)---*
/*=========================================================================*/
local vars classize c_size tipuach verbsize mathsize avgverb avgmath
local lab_classize "Class size"
local lab_c_size   "Enrollment"
local lab_tipuach  "Percent disadvantaged"
local lab_verbsize "Reading size"
local lab_mathsize "Math size"
local lab_avgverb  "Average verbal"
local lab_avgmath  "Average math"

/*=========================================================================*/
*---write the table---*
/*=========================================================================*/
file open t1 using "$root/output/table1.tex", write replace
file write t1 "\begin{tabular}{lccccccc}" _n
file write t1 "\toprule" _n
file write t1 " & & & \multicolumn{5}{c}{Quantiles} \\" _n
file write t1 "Variable & Mean & S.D. & 0.10 & 0.25 & 0.50 & 0.75 & 0.90 \\" _n
file write t1 "\midrule" _n

*---Panel A: full sample---*
file write t1 "\multicolumn{8}{l}{A. Full sample} \\" _n
foreach g in 5 4 {                                   // grade 5 first, as in the paper
    count if grade == `g'
    local ncl = r(N)                                 // classes
    count if grade == `g' & sch_first == 1
    local nsch = r(N)                                // schools (tag built in 1_clean.do)
    display _n "Panel A, grade `g': `ncl' classes, `nsch' schools"
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools, tested in 1991)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g', detail
        local m   : display %6.1f r(mean)
        local sd  : display %6.1f r(sd)
        local p10 : display %6.1f r(p10)
        local p25 : display %6.1f r(p25)
        local p50 : display %6.1f r(p50)
        local p75 : display %6.1f r(p75)
        local p90 : display %6.1f r(p90)
        display "`lab_`v'': mean `m'  sd `sd'  p10 `p10'  p25 `p25'  p50 `p50'  p75 `p75'  p90 `p90'"
        file write t1 "`lab_`v'' & `=trim("`m'")' & `=trim("`sd'")' & `=trim("`p10'")' & `=trim("`p25'")' & `=trim("`p50'")' & `=trim("`p75'")' & `=trim("`p90'")' \\" _n
    }
}

*---Panel B: +/-5 discontinuity sample (enrollment 36-45, 76-85, 116-125)---*
file write t1 "\midrule" _n
file write t1 "\multicolumn{8}{l}{B. +/-5 discontinuity sample (enrollment 36--45, 76--85, 116--125)} \\" _n
foreach g in 5 4 {
    count if grade == `g' & disc5 == 1
    local ncl = r(N)
    count if grade == `g' & disc5 == 1 & sch_first == 1
    local nsch = r(N)
    display _n "Panel B, grade `g': `ncl' classes, `nsch' schools"
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g' & disc5 == 1
        local m  : display %6.1f r(mean)
        local sd : display %6.1f r(sd)
        display "`lab_`v'': mean `m'  sd `sd'"
        file write t1 "`lab_`v'' & `=trim("`m'")' & `=trim("`sd'")' & & & & & \\" _n
    }
}

file write t1 "\bottomrule" _n
file write t1 "\end{tabular}" _n
file close t1

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

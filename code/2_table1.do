/*=========================================================================*/
*---Table I: Unweighted descriptive statistics---*
* Writes output/table1.tex. Panel A is the full sample (mean, s.d. and quantiles), panel B
* is the +/-5 discontinuity sample (mean and s.d.). Grades 5 and 4 only, since the grade 3
* data isn't provided. Log: output/2_table1.log
*
* Reads output/al_clean.dta. The sample, the school tag sch_first and the +/-5 marker disc5
* all come from 1_clean.do, nothing new is built here.
*
* Unweighted like Angrist and Lavy's Table I, so each class counts once. Grade 5 comes first
* and the rows follow the paper's order, so the .tex reads like their table.
/*=========================================================================*/

* setup
*
clear all
set more off                            // so long output doesn't pause the run
if "$root" == "" {                      // run on its own, find the project folder the same way 0_master.do does
    capture confirm file "../code/0_master.do"    // double-clicking a do file opens Stata inside code/
    if !_rc cd ..                                 // move up to the project folder
    confirm file "code/0_master.do"               // stops with "file not found" if we are not in the project folder
    global root "`c(pwd)'"
}
capture log close                       // closes any log left open by a crashed run

*--- needs output/al_clean.dta, built by 1_clean.do if it's missing so this file can run alone
capture confirm file "$root/output/al_clean.dta"   // _rc is 0 if the file exists
if _rc do "$root/code/1_clean.do"                  // only runs the cleaning file if the .dta isn't there

log using "$root/output/2_table1.log", replace text
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. Rows of the table and their labels---*
* The seven Table I variables in the paper's order, listed once so both panels and both
* grades are built from the same list. Reading size and math size are the number of test
* takers per class, and the two score rows are class averages.
/*=========================================================================*/

local vars classize c_size tipuach verbsize mathsize avgverb avgmath
local lab_classize "Class size"         // row labels as printed in the paper, looked up below as `lab_`v''
local lab_c_size   "Enrollment"
local lab_tipuach  "Percent disadvantaged"
local lab_verbsize "Reading size"
local lab_mathsize "Math size"
local lab_avgverb  "Average verbal"
local lab_avgmath  "Average math"


/*=========================================================================*/
*---2. Write the table, panel A then panel B---*
* Table I shows who is in the data, and that the +/-5 sample looks much like the full sample.
* That similarity is what makes it reasonable to compare schools near the cutoffs later on.
*
* Written line by line with file write, because the quantile columns don't fit an esttab
* layout. Numbers to one decimal as printed, with the class and school counts in each panel
* header as in the paper.
/*=========================================================================*/

file open t1 using "$root/output/table1.tex", write replace
file write t1 "\begin{tabular}{lccccccc}" _n
file write t1 "\toprule" _n
file write t1 " & & & \multicolumn{5}{c}{Quantiles} \\" _n
file write t1 "Variable & Mean & S.D. & 0.10 & 0.25 & 0.50 & 0.75 & 0.90 \\" _n   // same column heads as the paper
file write t1 "\midrule" _n

*--- panel A, full sample, mean, s.d. and quantiles
file write t1 "\multicolumn{8}{l}{A. Full sample} \\" _n
foreach g in 5 4 {                                   // grade 5 first, as in the paper
    quietly summarize sch_first if grade == `g'
    local ncl  = r(N)                                // classes
    local nsch = r(sum)                              // schools, since sch_first is 1 for one class in each school
    display _n "Panel A, grade `g': `ncl' classes, `nsch' schools"
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools, tested in 1991)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g', detail   // detail adds the quantiles, the missing math score is skipped
        foreach s in mean sd p10 p25 p50 p75 p90 {   // each statistic summarize leaves in r()
            local `s' = string(r(`s'), "%6.1f")      // one decimal, as printed
        }
        display "`lab_`v'': mean `mean'  sd `sd'  p10 `p10'  p25 `p25'  p50 `p50'  p75 `p75'  p90 `p90'"
        file write t1 "`lab_`v'' & `mean' & `sd' & `p10' & `p25' & `p50' & `p75' & `p90' \\" _n
    }
}

*--- panel B, +/-5 discontinuity sample, mean and s.d. only, as in the paper
file write t1 "\midrule" _n
file write t1 "\multicolumn{8}{l}{B. +/-5 discontinuity sample (enrollment 36--45, 76--85, 116--125)} \\" _n   // 125, not the 124 in the paper's header (see 1_clean.do)
foreach g in 5 4 {
    quietly summarize sch_first if grade == `g' & disc5 == 1
    local ncl  = r(N)
    local nsch = r(sum)
    display _n "Panel B, grade `g': `ncl' classes, `nsch' schools"
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g' & disc5 == 1
        local mean = string(r(mean), "%6.1f")
        local sd   = string(r(sd), "%6.1f")
        display "`lab_`v'': mean `mean'  sd `sd'"
        file write t1 "`lab_`v'' & `mean' & `sd' & & & & & \\" _n
    }
}

file write t1 "\bottomrule" _n
file write t1 "\end{tabular}" _n
file close t1


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close

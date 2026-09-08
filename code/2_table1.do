/*=========================================================================*/
*---Table I: Unweighted descriptive statistics (Angrist, Table I, p 539)---*
* Writes output/table1.tex: panel A full sample (mean, s.d., quantiles), panel B +/-5
* discontinuity sample (mean, s.d.). Grades 5 and 4 only, the grade 3 file is not
* provided (what_to_replicate). Log: output/2_table1.log
*
* Reads output/al_clean.dta from 1_clean.do. The sample, the school tag sch_first and the
* +/-5 sample disc5 are decided there (1_clean.do sections 3 and 5), nothing new is built here
*
* Unweighted, as Table I is. The per-pupil version is Appendix 1 (p 572), not required.
* Grade 5 first and the rows in the table's order, so the .tex reads like the paper (p 539)
*
* Sources cited in comments (same key as 1_clean.do):
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
*    what_to_replicate = the task list on Moodle
* Anything not lifted from a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup. Course code: W1/W3 lab
*
clear all
set more off                            // lets file run w/o manual input when output is long
if "$root" == "" global root "C:/Users/otisr/Documents/ECX5479/Final_Assignment"   // fallback when run alone, 0_master.do sets it for the full run (OUR CHANGE)
capture log close                       // closes a log if crash run left open

*--- dependency: needs output/al_clean.dta from 1_clean.do, built here if missing so this file runs alone (OUR CHANGE)
capture confirm file "$root/output/al_clean.dta"   // _rc is 0 if the file exists (code: capture prefix W3 lab bonus, W4 lab section 0)
if _rc do "$root/code/1_clean.do"                  // runs the cleaning file only when the .dta is not there, before this log opens (code: if _rc W4 lab section 0)

log using "$root/output/2_table1.log", replace text   // $root set once in 0_master.do, edit the path there
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. Rows of the table and their labels (Angrist, Table I, p 539)---*
* The seven rows in the paper's order. Reading size and math size are test takers per
* class, the two score rows are class averages (Table I variable definitions, p 539)
/*=========================================================================*/

local vars classize c_size tipuach verbsize mathsize avgverb avgmath   // dictionary rows 25, 3, 52, 32, 29, 33, 30 (code: W1 lab section 11 locals)
local lab_classize "Class size"         // row labels as printed (p 539), nested macro `lab_`v'' below is OUR CHANGE
local lab_c_size   "Enrollment"
local lab_tipuach  "Percent disadvantaged"
local lab_verbsize "Reading size"
local lab_mathsize "Math size"
local lab_avgverb  "Average verbal"
local lab_avgmath  "Average math"


/*=========================================================================*/
*---2. Write the table, panel A then panel B (Angrist, Table I, p 539)---*
* One LaTeX file written line by line, because the quantile columns do not fit an esttab
* layout (code: W4 lab Q7 file write table). Numbers to one decimal as printed
*
* Classes and schools per grade go in the panel header as in the paper. sch_first counts
* schools (1_clean.do section 3). Panel B keeps disc5 == 1 (1_clean.do section 5)
/*=========================================================================*/

file open t1 using "$root/output/table1.tex", write replace   // (code: W1 lab section 12, W4 lab Q7)
file write t1 "\begin{tabular}{lccccccc}" _n
file write t1 "\toprule" _n
file write t1 " & & & \multicolumn{5}{c}{Quantiles} \\" _n
file write t1 "Variable & Mean & S.D. & 0.10 & 0.25 & 0.50 & 0.75 & 0.90 \\" _n   // column heads as in Table I (p 539)
file write t1 "\midrule" _n

*--- panel A: full sample, mean, s.d. and quantiles
file write t1 "\multicolumn{8}{l}{A. Full sample} \\" _n
foreach g in 5 4 {                                   // grade 5 first, as in the paper (code: W1 lab section 13 foreach)
    count if grade == `g'
    local ncl = r(N)                                 // classes (code: W5 lab Bonus 2 r(N) into a local)
    count if grade == `g' & sch_first == 1
    local nsch = r(N)                                // schools, one class per school tagged (1_clean.do section 3)
    display _n "Panel A, grade `g': `ncl' classes, `nsch' schools"   // 2,019 and 1,002 grade 5, 2,049 and 1,013 grade 4, matches paper (p 539; code: W2 lab Q2 display _n)
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools, tested in 1991)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g', detail   // detail gives the quantiles, missing avgmath skipped (code: W1 lab section 13; quietly W4 lab Q7)
        local m   : display %6.1f r(mean)            // one decimal as printed (code: W4 lab Q7)
        local sd  : display %6.1f r(sd)
        local p10 : display %6.1f r(p10)             // r(p10) to r(p90) from summarize, detail (code: W5 lab Bonus 1)
        local p25 : display %6.1f r(p25)
        local p50 : display %6.1f r(p50)
        local p75 : display %6.1f r(p75)
        local p90 : display %6.1f r(p90)
        display "`lab_`v'': mean `m'  sd `sd'  p10 `p10'  p25 `p25'  p50 `p50'  p75 `p75'  p90 `p90'"   // grade 5 class size 29.9 (6.5) with quantiles 21 26 31 35 38, enrollment 77.7, average verbal 74.4, average math 67.3, then grade 4 30.3 (6.3), 78.3, 72.5, 68.9, matches paper (p 539)
        file write t1 "`lab_`v'' & `=trim("`m'")' & `=trim("`sd'")' & `=trim("`p10'")' & `=trim("`p25'")' & `=trim("`p50'")' & `=trim("`p75'")' & `=trim("`p90'")' \\" _n   // trim() drops the padding of %6.1f (code: W4 lab Q8)
    }
}

*--- panel B: +/-5 discontinuity sample, mean and s.d. only, as printed (p 539)
file write t1 "\midrule" _n
file write t1 "\multicolumn{8}{l}{B. +/-5 discontinuity sample (enrollment 36--45, 76--85, 116--125)} \\" _n   // 125 not the header's 124 (1_clean.do section 5)
foreach g in 5 4 {
    count if grade == `g' & disc5 == 1
    local ncl = r(N)
    count if grade == `g' & disc5 == 1 & sch_first == 1
    local nsch = r(N)
    display _n "Panel B, grade `g': `ncl' classes, `nsch' schools"   // 471 and 224 grade 5, 415 and 195 grade 4, matches paper (p 539)
    file write t1 "\multicolumn{8}{l}{`g'th grade (`ncl' classes, `nsch' schools)} \\" _n
    foreach v in `vars' {
        quietly summarize `v' if grade == `g' & disc5 == 1
        local m  : display %6.1f r(mean)
        local sd : display %6.1f r(sd)
        display "`lab_`v'': mean `m'  sd `sd'"       // grade 5 class size 30.8 (7.4), enrollment 76.4, average verbal 74.5, average math 67.0, then grade 4 31.1 (7.2), 78.5, 72.5, 68.7, matches paper (p 539)
        file write t1 "`lab_`v'' & `=trim("`m'")' & `=trim("`sd'")' & & & & & \\" _n
    }
}

file write t1 "\bottomrule" _n
file write t1 "\end{tabular}" _n
file close t1                                        // (code: W1 lab section 12)


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

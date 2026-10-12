/*
Angrist & Lavy (1999) replication
Required outputs: Tables I-VI, Figures I-II (grades 4 and 5),
and the three-SE comparison for Table II column (2).

RUN INSTRUCTIONS
1. Keep data/final4.dta and data/final5.dta under the project folder.
2. Set root below to the full path of that folder (forward slashes).
Uses built-in Stata commands only (no etable, no SSC packages).
Existing generated files under output/ are replaced on rerun.
*/

clear all
set more off
capture log close _all

* EDIT THIS LINE: full path of the project folder (the one holding data/).
global root "C:/Users/tyan0083/Documents/Codex-Restored-Projects/final project/Final_Submission"


foreach g in 4 5 {
    capture confirm file "$root/data/final`g'.dta"
    if _rc {
        display as error "Missing data/final`g'.dta. Edit global root above."
        exit 601
    }
}
capture mkdir "$root/output"


/*=========================================================================*/
*---Data Cleaning---*
* Cleans both grades and saves output/al_clean.dta, the one file every table and figure reads.
* Log: output/1_clean.log
*
* What happens here, by section
*    1  stack the grade 4 and grade 5 files, one row per class
*    2  fix two coding errors in the grade 5 scores
*    3  apply the paper's sample rule, drop classes with no scores, tag one class per school
*    4  build fsc, the class size Maimonides' rule predicts, our instrument
*    5  mark the +/-5 and +/-3 discontinuity samples
* Anything only one table or figure needs is built in that file instead.
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
log using "$root/output/1_clean.log", replace text

/*=========================================================================*/
*---1. Load and stack the two grade files---*
* Each row is one class, the same unit Angrist and Lavy use. Stacking both grades into one
* file lets every table and figure loop over grade instead of repeating the code.
/*=========================================================================*/

* append, not merge, because the grades are different classes with the same variables
use "$root/data/final4.dta", clear
append using "$root/data/final5.dta"    // adds the grade 5 classes underneath
describe
tab grade
isid grade schlcode classid             // grade, school and class identify each row, stops if any class appears twice

* the paper only covers Jewish public schools, secular and religious, so check nothing else is here
tab c_leom c_pik, missing


/*=========================================================================*/
*---2. Fix coding errors in the grade 5 scores---*
* The data dictionary flags two errors in the grade 5 file. One class has its reading and
* math averages recorded as score + 100, and one class had nobody sit the math test but
* shows a math average of 0. Scores run from 1 to 100, so both are recording errors, and
* left in they would distort the score means in Table I and every regression on scores.
/*=========================================================================*/

*--- look at the two flagged classes before changing anything
list grade schlcode classid avgverb avgmath mathsize verbsize if (avgverb > 100 & !missing(avgverb)) | mathsize == 0


* take off the extra 100, !missing() matters because Stata treats missing as bigger than any number
replace avgverb = avgverb - 100 if avgverb > 100 & !missing(avgverb)
replace avgmath = avgmath - 100 if avgmath > 100 & !missing(avgmath)

* nobody sat the math test in this class, so its 0 is not a real score, set it to missing
replace avgmath = . if mathsize == 0


/*=========================================================================*/
*---3. Sample restrictions and a school tag---*
* Angrist and Lavy keep classes with fewer than 45 pupils, in schools with at least 5 pupils
* enrolled in the grade (their footnote 11). Every table uses this sample, so it has to match.
*
* The footnote says at least 5, but the authors' own code drops schools with exactly 5.
* Only one school sits at 5, well below the next smallest at 8, so we follow their code.
* That gives the 2,019 grade 5 classes in 1,002 schools reported in their Table I.
*
* Classes with no score in either subject are dropped too, 4 in grade 4 and 5 in grade 5.
* These are the classes the paper says it could not fill in from school averages.
/*=========================================================================*/

*--- the footnote's rule against the authors' code, on grade 5
count if grade == 5 & classize < 45 & c_size >= 5 & !(missing(avgverb) & missing(avgmath))   // footnote 11 as written
count if grade == 5 & classize < 45 & c_size >  5 & !(missing(avgverb) & missing(avgmath))   // the authors' code


summarize c_size, detail                // the smallest enrollments show how far the school at 5 sits from the rest


*--- apply the rule, looking at what goes first
tab grade if classize >= 45
tab grade if c_size <= 5                // the one school at exactly 5
drop if classize >= 45 | c_size <= 5


*--- drop classes with no score in either subject
tab grade if missing(avgverb) & missing(avgmath)
drop if missing(avgverb) & missing(avgmath)



*--- sch_first marks one class in each school, so summing it counts schools the way Table I does
bysort grade schlcode: gen sch_first = (_n == 1)   // _n is the row number within each school, so only the first class gets a 1
label variable sch_first "1 for one class per school-grade"

*--- classes and schools per grade after the drops
tab grade sch_first                     // row totals are classes, the sch_first = 1 column is schools
summarize avgverb avgmath if grade == 5 // Obs counts classes with each score, math is one short because of the untested class


/*=========================================================================*/
*---4. Maimonides' rule class size, fsc---*
* fsc is the class size the rule predicts from enrollment, es / (int((es - 1)/40) + 1),
* which is Angrist and Lavy's equation 1. It is our instrument for actual class size.
* It drops sharply when enrollment passes 40, 80 and 120, for reasons that have nothing to
* do with the pupils, and that jump is the variation the whole paper relies on.
*
* We use September enrollment (c_size), not the spring count (cohsize). September is fixed
* before parents or schools can react to class sizes, so it can't reflect their choices.
/*=========================================================================*/

*--- new variable fsc
gen fsc = c_size / (floor((c_size - 1)/40) + 1)   // floor() does the paper's int(), rounding down
* Stata's int() cuts toward zero, floor() always rounds down, which is how the paper defines it.
* With enrollment never negative (obviously) the two give the same answer here.

label variable fsc "predicted class size, Maimonides' rule (eq 1)"
summarize fsc classize c_size cohsize



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

/*=========================================================================*/
*---Figure I: Class size by enrollment, actual and Maimonides' rule---*
* Writes output/figure1_grade5.png and output/figure1_grade4.png. Log: output/3_figure1.log
*
* Reads output/al_clean.dta. The sample and fsc both come from 1_clean.do, nothing new is
* built here.
*
* Each panel plots the average actual class size at each enrollment count (solid) against the
* class size the rule predicts (dashed), as in Angrist and Lavy's Figure I. The paper also
* draws horizontal lines at the corners of the rule, we leave those out.
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

log using "$root/output/3_figure1.log", replace text
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade---*
* Shows the rule really drives class size. Actual class size follows fsc and drops sharply
* just past 40, 80 and 120, so fsc moves class size, which the instrument needs to work.
*
* Collapse to one row per enrollment count inside preserve/restore, so the full data is back
* for the next grade. fsc is the same for every class with a given enrollment, so its mean
* is just fsc.
/*=========================================================================*/

foreach g in 5 4 {                                  // grade 5 then grade 4, the paper's order
    preserve
    keep if grade == `g'
    collapse (mean) classize fsc, by(c_size)        // average class size at each enrollment count
    summarize classize fsc c_size
    twoway (line fsc c_size, lpattern(dash)) ///    // the rule dashed, as in the paper
           (line classize c_size), ///              // actual class size solid
        legend(label(1 "Maimonides' rule") label(2 "Actual class size")) ///
        title("Grade `g'") xtitle("Enrollment count") ytitle("Class size") ///   // axis titles as in the paper
        xlabel(0(20)220) ylabel(5(5)40)             // same axes as the paper
    graph export "$root/output/figure1_grade`g'.png", replace
    restore                                         // back to the full two-grade data for the next panel
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close

/*=========================================================================*/
*---Figure II: Average reading scores and predicted class size by enrollment---*
* Writes output/figure2_grade5.png and output/figure2_grade4.png. Log: output/4_figure2.log
*
* Reads output/al_clean.dta, with the sample and fsc from 1_clean.do. Builds e_bin, the
* midpoint of each ten-pupil enrollment interval, used only here.
*
* Each panel plots average reading score and average fsc by enrollment in intervals of ten,
* scores on the left axis and fsc on the right, as in Angrist and Lavy's Figure II.
* Math is their Figure III, which is optional, so it isn't produced.
*
* The paper averages enrollments 9 to 190 and lumps 160 to 190 into its last point at 165.
* We stop at 169 instead, so every point is one interval of ten and the axis still runs
* 5 to 165. Only the first and last points differ, the first keeps enrollments 5 to 8 and
* the last stops at 169.
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

log using "$root/output/4_figure2.log", replace text
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade---*
* Reading scores move up and down as a mirror image of fsc. Other effects of enrollment
* should be smooth, so this zigzag is the class size effect showing up before any regression.
*
* Keep one grade and enrollment up to 169, bin enrollment into tens, collapse to one row
* per bin, plot, then restore the full data for the next grade.
/*=========================================================================*/

tab grade if c_size > 169                           // classes left out of the figure, the paper lumps 160 to 190 into its last point

foreach g in 5 4 {                                  // grade 5 then grade 4, as in the paper
    preserve
    keep if grade == `g' & c_size <= 169            // intervals up to 160-169, see the header
    gen e_bin = 10 * floor(c_size / 10) + 5         // midpoint of each ten-pupil interval, 5, 15, ..., 165
    collapse (mean) avgverb fsc (count) n=avgverb, by(e_bin)   // averages per interval and how many classes are in each
    list e_bin n avgverb fsc                        // the plotted points, the small first interval is kept so the axis matches the paper
    twoway (connected avgverb e_bin) ///            // scores on the left axis
           (connected fsc e_bin, yaxis(2) lpattern(dash)), ///   // fsc dashed on the right axis, as in the paper
        legend(label(1 "Average reading score") label(2 "Predicted class size (right axis)")) ///
        title("Grade `g'") xtitle("Enrollment count") ///
        ytitle("Average reading score") ytitle("Predicted class size", axis(2)) ///
        xlabel(5(20)165)                            // same axis as the paper
    graph export "$root/output/figure2_grade`g'.png", replace
    restore
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close

******************************************************************************
* SECTION 5: TABLES II-V AND THREE STANDARD ERRORS
******************************************************************************

/*=========================================================================*/
*---Tables II to V---*
* Reads output/al_clean.dta (built in SECTION 1) and produces, in this order:
*    s.1  new variables these tables alone need: c_size2, trend
*    s.2  Table II   OLS, grades 5 and 4                    (Angrist, Table II, p 551)
*    s.3  Table II   three-SE comparison, one column       (what_to_replicate, required small addition)
*    s.4  Table III  reduced forms, full and +/-5 samples   (Angrist, Table III, p 553)
*    s.5  Tables IV and V  2SLS, grade 5 then grade 4      (Angrist, Tables IV-V, pp 554, 556)
* Output: output/table2, table3_panelA, table3_panelB, table4, table5 (.csv ), table2_se.xlsx
* Log:    output/5_tables2to5.log
*
* Standard errors
*    - paper reports Moulton-corrected SEs (Angrist, notes to Tables II-V)
*    - we cluster at the school level instead, allowed by what_to_replicate
*      ("Moulton-corrected standard errors may be replaced by ... clustered at the school level")
*    - classes in a school share teachers, neighbourhood and enrollment, so their
*      residuals are correlated; schlcode is the cluster (README data notes)
*    - the one exception, the hand-built Moulton SE, is s.3
*
* Sources cited in comments:
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx
*    README = the paper folder's README.txt, data notes
*    what_to_replicate = the task list on Moodle
* Anything not lifted from the paper or a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup
clear
capture log close                       // closes a log if crash run left open
log using "$root/output/5_tables2to5.log", replace text

use "$root/output/al_clean.dta", clear
tab grade                               // check: 2,049 grade 4, 2,019 grade 5, as left by SECTION 1


*--- small helper: adds the mean and s.d. of the dependent variable to e()
*--- so the tables can show the paper's "Mean score (s.d.)" row (Angrist, Tables II-V, top row)
*--- computed on the estimation sample, e(sample), so it matches each column's N (OUR CHANGE)
capture program drop add_ymean
program define add_ymean, eclass
    quietly summarize `e(depvar)' if e(sample)
    ereturn scalar ymean = r(mean)
    ereturn scalar ysd   = r(sd)
end

*--- small helper: run right after ivregress, adds the first-stage F to e() (OUR CHANGE)
*   - first stage = class size on the excluded instruments and the same controls,
*     on exactly the 2SLS estimation sample, clustered by school as the 2SLS is
*   - the F tests the excluded instruments only (fsc here, z1-z3 in Table VI), not the controls
*   - the 2SLS results are put back afterwards, so the stored column is still the 2SLS model
capture program drop add_fsF
program define add_fsF, eclass
    local endog `e(instd)'              // class size
    local exog  `e(exogr)'              // included controls
    local insts `e(insts)'              // controls + excluded instruments
    local excl  : list insts - exog     // excluded instruments only
    local clu   `e(clustvar)'
    tempvar es
    tempname iv
    gen byte `es' = e(sample)
    estimates store `iv'
    quietly regress `endog' `excl' `exog' if `es', vce(cluster `clu')
    quietly test `excl'
    local F = r(F)
    local p = r(p)
    quietly estimates restore `iv'
    ereturn scalar fs_F = `F'
    ereturn scalar fs_p = `p'
end

*--- table export helpers, built-in commands only (post, reshape, export delimited, file write)
*   record_table_result: run right after an estimation (and add_ymean / add_fsF), posts that
*     model as one column: b and se of each term, then N, schools, RMSE, mean, s.d., R2, first-stage F
*     terms a model does not have are left missing, so all columns share the same rows
*   export_results: one row per statistic, one column per model, saved as <stub>.csv
*     rows missing in every column (e.g. first-stage F in an OLS table) are dropped
capture program drop record_table_result
program define record_table_result
    args handle column terms
    local k = 0
    foreach term of local terms {
        local ++k
        local b = .
        local se = .
        capture local b = _b[`term']
        capture local se = _se[`term']
        post `handle' (2*`k'-1) ("b_`term'") (`column') (`b')
        post `handle' (2*`k') ("se_`term'") (`column') (`se')
    }
    post `handle' (90) ("N_classes") (`column') (e(N))
    post `handle' (91) ("N_schools") (`column') (e(N_clust))
    post `handle' (92) ("RMSE") (`column') (e(rmse))
    post `handle' (93) ("mean_score") (`column') (e(ymean))
    post `handle' (94) ("sd_score") (`column') (e(ysd))
    post `handle' (95) ("R2") (`column') (e(r2))
    post `handle' (96) ("first_stage_F") (`column') (e(fs_F))
    post `handle' (97) ("first_stage_p") (`column') (e(fs_p))
end

capture program drop export_results
program define export_results
    args source stub
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order
    egen byte n_nonmiss = rownonmiss(value*)
    drop if n_nonmiss == 0
    drop n_nonmiss
    export delimited using "`stub'.csv", replace
    restore
end


/*=========================================================================*/
*---1. Variables only these tables need---*
*   - c_size2 = enrollment squared / 100, the quadratic control in Tables IV-V col (3), (9)
*       - divided by 100 as the paper does, so the coefficient is readable (Angrist, Table IV, row label)
*   - trend   = piecewise linear trend in enrollment, Tables IV-V col (4), (10) (Angrist, p 555)
*       - slopes match fsc on each segment, so the only variation left in fsc is the jumps at 40, 80, 120
*       - the paper defines it on [0,160] only, so schools above 160 get missing and drop
*         from those two columns. We follow the paper rather than extend the formula (OUR CHANGE)
/*=========================================================================*/

gen c_size2 = c_size^2 / 100
label variable c_size2 "Enrollment squared/100"

gen trend = .
replace trend = c_size                    if inrange(c_size,   0,  40)   // slope 1
replace trend = 20      + c_size/2        if inrange(c_size,  41,  80)   // slope 1/2
replace trend = 100/3   + c_size/3        if inrange(c_size,  81, 120)   // slope 1/3
replace trend = 130/3   + c_size/4        if inrange(c_size, 121, 160)   // slope 1/4
label variable trend "Piecewise linear trend"

count if missing(trend)                 // classes in schools with enrollment > 160, dropped only in col (4), (10)
tab grade if missing(trend)

* labels so the estimates tables in the log read like the paper's row names (varlabel option)
label variable classize "Class size"
label variable tipuach  "Percent disadvantaged"
label variable c_size   "Enrollment"
label variable fsc      "f_sc (Maimonides' rule)"
label variable avgverb  "Reading comprehension"
label variable avgmath  "Math"


/*=========================================================================*/
*---2. Table II: OLS (Angrist, Table II, p 551)---*
* For each grade and subject, three columns:
*   (a) class size only
*   (b) + percent disadvantaged (PD)
*   (c) + PD + enrollment
* Paper column order: grade 5 reading (1)-(3), math (4)-(6); grade 4 reading (7)-(9), math (10)-(12)
* We loop grade 5 first so stored columns come out in the paper's order
/*=========================================================================*/

local ctrl_a ""                         // (a) class size only
local ctrl_b tipuach                    // (b) + PD
local ctrl_c tipuach c_size             // (c) + PD + enrollment

tempname h2
tempfile r2
postfile `h2' int order str32 row byte column double value using "`r2'", replace
local col = 0
local t2 ""                             // collects estimate names, in column order
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        foreach s in a b c {
            local ++col
            regress `y' classize `ctrl_`s'' if grade == `g', vce(cluster schlcode)
            add_ymean
            estimates store t2_g`g'_`y'_`s'
            record_table_result `h2' `col' "classize tipuach c_size"
            local t2 "`t2' t2_g`g'_`y'_`s'"
        }
    }
}
postclose `h2'

estimates table `t2', keep(classize tipuach c_size) varlabel b(%9.4f) se(%9.4f) stats(ymean ysd rmse r2 N)
export_results "`r2'" "$root/output/table2"


/*=========================================================================*/
*---3. Table II: three standard errors side by side (what_to_replicate, required small addition)---*
* Column chosen: Table II column (2), grade 5 reading on class size and PD
*   - reading is the paper's headline outcome, and PD is the control kept in every later table
*     so this is the OLS column the IV tables are compared with (OUR CHANGE)
*
* Three SEs for the class-size coefficient:
*   (i)   conventional OLS, assumes independent errors across classes
*   (ii)  clustered by school
*   (iii) Moulton: (i) * sqrt(1 + (m-1)*rho)   (Module 5)
*         m   = average classes per school in the estimation sample
*         rho = intraclass (within-school) correlation of the OLS residuals
*   - rho from loneway, Stata's one-way ANOVA estimate of the intraclass correlation;
*     it allows schools to have different numbers of classes (OUR CHANGE)
*   - (iii) will not match the paper's Moulton SE: the paper also corrects for the
*     within-school correlation of class size itself (what_to_replicate); our formula treats it as 1
/*=========================================================================*/

* (i) conventional OLS
regress avgverb classize tipuach if grade == 5
scalar se_ols = _se[classize]
scalar b_cs   = _b[classize]
gen byte s3_sample = e(sample)          // keep the estimation sample so m and rho use the same classes
predict double s3_resid if s3_sample, residuals

* (ii) clustered by school, same sample, same point estimate
regress avgverb classize tipuach if s3_sample, vce(cluster schlcode)
scalar se_clu = _se[classize]
scalar n_sch  = e(N_clust)              // number of schools in the sample

* (iii) Moulton by hand
loneway s3_resid schlcode if s3_sample  // log shows the ANOVA table and rho
scalar rho = r(rho)
quietly count if s3_sample
scalar m = r(N) / n_sch                 // classes / schools = average classes per school
scalar se_moul = se_ols * sqrt(1 + (m - 1) * rho)

display "m = " m "   rho = " rho "   inflation factor = " sqrt(1 + (m - 1) * rho)

matrix SE3 = (b_cs, se_ols, se_clu, se_moul, m, rho)
matrix colnames SE3 = coef "(i) OLS" "(ii) cluster" "(iii) Moulton" m rho
matrix rownames SE3 = "Class size, T2 col 2"
matlist SE3, format(%9.4f)

putexcel set "$root/output/table2_se.xlsx", replace
putexcel A1 = "Table II, column (2): grade 5 reading on class size and PD. Three standard errors for the class-size coefficient"
putexcel A3 = matrix(SE3), names nformat("0.0000")

drop s3_sample s3_resid


/*=========================================================================*/
*---4. Table III: reduced forms (Angrist, Table III, p 553)---*
* Regress class size, reading and math on fsc, with
*   (a) PD only
*   (b) PD + enrollment
* Panel A uses the full sample, panel B the +/-5 discontinuity sample (disc5, from SECTION 1)
* Column order per panel: grade 5 class size (1)-(2), reading (3)-(4), math (5)-(6);
*                         grade 4 the same in (7)-(12)
* The class-size columns are the first stage of Tables IV-V; the score columns are the reduced form
* Panel A and panel B are saved as separate files, table3_panelA and table3_panelB
/*=========================================================================*/

local ctrl_a tipuach                    // (a) PD only
local ctrl_b tipuach c_size             // (b) PD + enrollment

foreach p in A B {
    if "`p'" == "A" local smp "1"           // full sample: no restriction
    if "`p'" == "B" local smp "disc5 == 1"  // +/-5 sample (Angrist, p 540)
    tempname h3
    tempfile r3`p'
    postfile `h3' int order str32 row byte column double value using "`r3`p''", replace
    local col = 0
    local t3`p' ""
    foreach g in 5 4 {
        foreach y in classize avgverb avgmath {
            foreach s in a b {
                local ++col
                regress `y' fsc `ctrl_`s'' if grade == `g' & `smp', vce(cluster schlcode)
                add_ymean
                estimates store t3`p'_g`g'_`y'_`s'
                record_table_result `h3' `col' "fsc tipuach c_size"
                local t3`p' "`t3`p'' t3`p'_g`g'_`y'_`s'"
            }
        }
    }
    postclose `h3'
    estimates table `t3`p'', keep(fsc tipuach c_size) varlabel b(%9.4f) se(%9.4f) stats(ymean ysd rmse r2 N)
}

export_results "`r3A'" "$root/output/table3_panelA"   // full sample
export_results "`r3B'" "$root/output/table3_panelB"   // +/-5 sample


/*=========================================================================*/
*---5. Tables IV and V: 2SLS (Angrist, Table IV p 554, Table V p 556)---*
* Same six models for each subject, fsc instruments class size in all of them:
*   full sample
*   (1) PD
*   (2) PD + enrollment
*   (3) PD + enrollment + enrollment squared/100
*   (4) piecewise linear trend only, no PD (Angrist, p 555)
*   +/-5 discontinuity sample
*   (5) PD
*   (6) PD + enrollment
* Reading is (1)-(6), math (7)-(12)
* Table IV is grade 5, Table V grade 4: one loop, the grade sets the table number
* ivregress 2sls with one instrument and one endogenous regressor is just identified,
* so the estimate equals reduced form / first stage from Table III (Angrist, p 552)
/*=========================================================================*/

* controls and sample of each specification, column s of each subject
local ctrl1 tipuach
local ctrl2 tipuach c_size
local ctrl3 tipuach c_size c_size2
local ctrl4 trend                       // no PD, as in the published table (Angrist, p 555)
local ctrl5 tipuach
local ctrl6 tipuach c_size
forvalues s = 1/4 {
    local smp`s' "1"                    // full sample
}
local smp5 "disc5 == 1"                 // +/-5 sample
local smp6 "disc5 == 1"

foreach g in 5 4 {
    if `g' == 5 local tab "4"
    if `g' == 5 local rom "IV"
    if `g' == 4 local tab "5"
    if `g' == 4 local rom "V"
    display _n "Table `rom': 2SLS, grade `g'"
    tempname h`tab'
    tempfile r`tab'
    postfile `h`tab'' int order str32 row byte column double value using "`r`tab''", replace
    local col = 0
    local t`tab' ""
    foreach y in avgverb avgmath {
        forvalues s = 1/6 {
            local ++col
            ivregress 2sls `y' (classize = fsc) `ctrl`s'' if grade == `g' & `smp`s'', vce(cluster schlcode)
            add_ymean
            add_fsF
            estimates store t`tab'_`y'_`s'
            record_table_result `h`tab'' `col' "classize tipuach c_size c_size2 trend"
            local t`tab' "`t`tab'' t`tab'_`y'_`s'"
        }
    }
    postclose `h`tab''

    estimates table `t`tab'', keep(classize tipuach c_size c_size2 trend) varlabel b(%9.4f) se(%9.4f) stats(ymean ysd rmse N fs_F)
    export_results "`r`tab''" "$root/output/table`tab'"
}


/*=========================================================================*/
*--- Close ---*
/*=========================================================================*/
estimates dir                           // log check: every stored column listed
log close

******************************************************************************
* SECTION 6: TABLE VI
******************************************************************************

/*=========================================================================*/
*---Table VI: dummy-instrument results for discontinuity samples (Angrist, Table VI, pp 558-560)---*
* Note: export_results now exports CSV only; the .tex output named above no longer applies.
*
* Each grade and subject, three columns:
*   (1) +/-5 sample, PD + segment dummies
*   (2) +/-3 sample, PD + segment dummies
*   (3) +/-3 sample, segment dummies only
* Grade 5 reading (1)-(3), math (4)-(6); grade 4 reading (7)-(9), math (10)-(12)
* No continuous enrollment control: the only enrollment control is seg1, seg2 (Angrist, p 559)
* Instruments z1-z3 = upper half of each segment, i.e. 1[fsc < 32] by segment (Angrist, p 559)
*
* The three binary instruments predict actual class size in the first stage.
* Segment controls allow the outcome level to differ across the three cutoff windows.
* School-clustered standard errors allow errors to be correlated within schools.
* Helpers add_ymean, add_fsF, record_table_result and export_results are defined in SECTION 5.
/*=========================================================================*/

*---1. Load the cleaned data and check the sample definitions---*

clear                                     
capture log close                          
log using "$root/output/6_table6.log", replace text  
use "$root/output/al_clean.dta", clear      

* isid checks that each combination identifies one observation; duplicates or missing IDs cause an error.
* assert checks a condition without changing the data; a failed check stops the do-file.
isid grade schlcode classid                 // each grade-school-class combination must be unique
assert inlist(grade,4,5)                    // every observation must be either grade 4 or grade 5
assert !missing(c_size, classize, schlcode, fsc)   // enrollment, actual size, school ID and predicted size must be observed
assert seg1 == inrange(c_size,36,45)        // check the first +/-5 window around the cutoff of 40
assert seg2 == inrange(c_size,76,85)        // check the second +/-5 window around the cutoff of 80
assert seg3 == inrange(c_size,116,125)      // check the third +/-5 window around the cutoff of 120
assert disc5 == (seg1 | seg2 | seg3)        // disc5 must identify the union of the three windows
assert disc3 == (inrange(c_size,38,43) | inrange(c_size,78,83) | inrange(c_size,118,123))   // check the narrower +/-3 windows
assert disc5 == 1 if disc3 == 1             // every observation in the +/-3 sample must also belong to the +/-5 sample

*---2. Construct and check the three binary instruments---*

* Three instruments: above-cutoff indicator within each segment.
* Reusing them after restricting to disc3 yields [41,43], [81,83], [121,123].
* Each indicator is 1 on the upper side of its own cutoff window and 0 elsewhere.
* Therefore, z1 = 0 alone does not identify the lower side of every window.
* The three instruments and the segment controls together distinguish the relevant comparisons.
gen byte z1 = inrange(c_size,41,45)         // 1 for enrollment 41-45, the upper side of the first window
gen byte z2 = inrange(c_size,81,85)         // 1 for enrollment 81-85, the upper side of the second window
gen byte z3 = inrange(c_size,121,125)       // 1 for enrollment 121-125, the upper side of the third window


tab grade disc5                            // show each grade's counts inside and outside the +/-5 sample
tab grade disc3                            // show each grade's counts inside and outside the +/-3 sample

label variable classize "Class size"        // label the endogenous class-size variable
label variable tipuach  "Percent disadvantaged"   // label the disadvantaged-student control
label variable seg1     "Segment 1 (enrollment 36-45)"   // label the first cutoff-window indicator
label variable seg2     "Segment 2 (enrollment 76-85)"   // label the second cutoff-window indicator

*---3. Define the controls and sample condition for each specification---*

* seg3 is omitted because a constant plus all three segments is collinear.
* Within either estimation sample, seg1 + seg2 + seg3 = 1.
* Keep the constant and include seg1 and seg2; the third segment is the reference group.
local ctrl1 tipuach seg1 seg2               // specification 1: PD and two segment controls
local ctrl2 tipuach seg1 seg2               // specification 2: the same controls, but a narrower sample
local ctrl3 seg1 seg2                       // specification 3: segment controls only, without PD
local smp1 "disc5 == 1"                     // specification 1 uses the +/-5 sample
local smp2 "disc3 == 1"                     // specification 2 uses the +/-3 sample
local smp3 "disc3 == 1"                     // specification 3 also uses the +/-3 sample

*---4. Prepare a temporary file to collect the table results---*

tempname h6                                // create a temporary name for the results-file writing handle
tempfile r6                                // create a temporary file path for the recorded results
postfile `h6' int order str32 row byte column double value using "`r6'", replace   // define four columns: sorting order, statistic name, model number and value
local col = 0                              // initialise the model-column counter; it will run from 1 to 12
local t6 ""                                // start an empty list of stored model names

*---5. Estimate all 12 models in the paper's column order---*

foreach g in 5 4 {                         
    foreach y in avgverb avgmath {          
        forvalues s = 1/3 {                // run the three specifications for the current grade and subject
            local ++col                    // increase the table-column number by one

            * ctrl`s' selects ctrl1, ctrl2 or ctrl3; smp`s' selects the corresponding sample condition.
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) if grade == `g' & `smp`s'', vce(cluster schlcode)

            add_ymean                      // attach the dependent-variable mean and SD for this model's actual estimation sample
            add_fsF                     // joint F of z1 z2 z3, helper from SECTION 5
            * add_fsF uses the same estimation sample and controls, then restores the original 2SLS results.
            * Its F statistic tests whether all three instrument coefficients are zero in the first stage.

            estimates store t6_g`g'_`y'_`s'   // save the model under a name identifying its grade, subject and specification
            record_table_result `h6' `col' "classize tipuach seg1 seg2"   // record coefficients, SEs and model statistics; absent terms remain missing
            local t6 "`t6' t6_g`g'_`y'_`s'"   // append this model's name to the list, preserving the column order
        }                                 
    }                                     
}                                        

postclose `h6'     
                        

*---6. Display and export Table VI---*

* Show the stored models side by side in the Results window and log.
estimates table `t6', keep(classize tipuach seg1 seg2) varlabel b(%9.4f) se(%9.4f) stats(ymean rmse N fs_F)

export_results "`r6'" "$root/output/table6"



log close                 

display as result "All replication sections completed. See $root/output."   

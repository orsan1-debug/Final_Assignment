/*
Angrist & Lavy (1999): single-file replication
Required outputs: Tables I-VI, Figures I-II (grades 4 and 5),
and the three-SE comparison for Table II column (2).

RUN INSTRUCTIONS
1. Keep data/final4.dta and data/final5.dta under the project folder.
2. Set root below to the full path of that folder (forward slashes).
3. Run this ENTIRE do-file. No other do-files are needed.
Requires a Stata installation with the built-in etable command.
Existing generated files under output/ are replaced on rerun.
*/

clear all
set more off
capture log close _all

* EDIT ONLY THIS LINE if the project folder is not the current directory.
global root "C:/Users/tyan0083/Documents/Codex-Restored-Projects/final project/Final_Submission"


foreach g in 4 5 {
    capture confirm file "$root/data/final`g'.dta"
    if _rc {
        display as error "Missing data/final`g'.dta. Edit global root above."
        exit 601
    }
}
capture mkdir "$root/output"
capture mkdir "$root/output/tables5_6"


******************************************************************************
* SECTION 1: DATA CLEANING
******************************************************************************

/*=========================================================================*/
*---Data Cleaning---*
* Cleans the data for both grades and saves output/al_clean.dta, which every
* table and figure file reads. Log: output/1_clean.log.
* Includes what all tables and figures share:
*    s.1  stack final4 and final5 into one file, one row per class
*    s.2  fix two coding errors in the grade 5 scores (dictionary)
*    s.3  apply the paper's sample rule and drop no-score classes (Angrist, fn 11, p 542)
*    s.3  new: sch_first, tags one class per school so schools can be counted
*    s.4  new: fsc, Maimonides' rule class size, the instrument (Angrist, eq 1, p 540)
*    s.5  new: seg1-seg3 disc5 disc3, the +/-5 and +/-3 samples (Angrist, pp 540, 557-559)
* Anything one table or figure alone needs is built in that file.
*
* Sources cited in comments:
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
* Anything not lifted from a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup. Course code: W1/W3 lab
*                    
clear
capture log close                       // closes a log if crash run left open
log using "$root/output/1_clean.log", replace text   // root is set at the top of this merged file

/*=========================================================================*/
*---1. Load and stack the two grade files---*
* Paper repeats every table for grades 5 and 4 (Angrist, Section I, p 538; Table II, p 551)
* We create one combined file and a loop over grade for tables/figures (STATA_RULES slide 6)
/*=========================================================================*/

*append data (not merge)
use "$root/data/final4.dta", clear
append using "$root/data/final5.dta"    // adds the grade 5 rows (README, W1 lab section 15)
describe                                // log check: 4,088 obs (raw classes), 58 var. 
tab grade                               // 2,059 grade 4, 2,029 grade 5, matches observations (dictionary row 23)
isid grade schlcode classid             // unique key, would stop if any class appears twice (dictionary row 24; W3 lab Q5)

* check sample is Jewish public schools only
tab c_leom, missing                     // all 1, Jewish public schools only, matches paper (p. 538)
tab c_pik, missing                      // 1 secular, 2 religious only: matches paper, nothing to drop (p. 538)


/*=========================================================================*/
*---2. Fix coding errors in the grade 5 scores---*
* Two data errors flagged in the dictionary (final5 sheet):
*   - one class has its reading and math averages recorded as score + 100 (rows 30, 33)
*   - one class has mathsize = 0, so nobody sat the math test, yet avgmath = 0 (row 29)
/*=========================================================================*/

*--- errors
list grade schlcode classid avgverb avgmath mathsize verbsize if avgverb > 100 & !missing(avgverb)   // the +100 class
list grade schlcode classid avgverb avgmath mathsize verbsize if mathsize == 0                        // the untested class


* fix scores: subtract the extra 100
replace avgverb = avgverb - 100 if avgverb > 100 & !missing(avgverb)    
replace avgmath = avgmath - 100 if avgmath > 100 & !missing(avgmath)    // (W3 lab Q3)

* mathsize 0 means no math test sat, so the 0 is not a score: set to missing
count if mathsize == 0                          
replace avgmath = . if mathsize == 0            // sets to missing, (W3 lab Q5)


/*=========================================================================*/
*---3. Sample restrictions (Angrist, fn 11, p 542) and a school tag---*
* Paper keeps classes under 45 pupils and schools with at least 5 enrolled (Angrist, fn 11, p 542)
*
* This stated threshold (c_size >= 5) doesn't match their applied threshold (c_size > 5, AngristLavy_Table2.do line 32),
* which drops the one school at exactly 5. We follow their method, so we drop
* classize >= 45 and c_size <= 5: 2,019 classes and 1,002 schools (Angrist, Table I, p 539)
*
* Classes with no score in either subject are dropped, 4 grade 4 and 5 grade 5,
* same ones the paper could not impute (Angrist, Data Appendix, p 571)
*
* sch_first tags one class per school-grade so schools can be counted (Angrist, Table I, p 539)
/*=========================================================================*/

*--- fn 11 as written (keep c_size >= 5) vs the authors' code (c_size > 5, AngristLavy_Table2.do line 32)
*--- their stated threshold doesnt match method, we follow their method to define our threshold.
*--- only 1 school at 5, isolated from rest of sample, reasonable to follow their applied threshold

count if grade == 5 & classize < 45 & c_size >= 5 & !(missing(avgverb) & missing(avgmath))   // 2020, fn 11 as written
count if grade == 5 & classize < 45 & c_size >  5 & !(missing(avgverb) & missing(avgmath))   // 2019, matches paper sample size


tab c_size if c_size <= 15              // only 1 school at 5, next lowest is 3 schools at 8
summarize c_size, detail                // school at 5 well below the rest: next 8, 1st percentile 14 (W1 lab section 1)


*--- we follow their method
tab grade if classize >= 45             // 6 grade 4, 4 grade 5 (W1 lab section 8)
tab grade if c_size <= 5                // 1 grade 5, the school at exactly 5
drop if classize >= 45 | c_size <= 5    // drops classes on both threshold bounds (W3 lab Q5)


*--- Drop classes with no scores, as in the paper (Angrist, Data Appendix, p 571)
tab grade if missing(avgverb) & missing(avgmath)   // total: 9, 4 in grade 4 and 5 in grade 5, matches paper
drop if missing(avgverb) & missing(avgmath)



*--- NEW VARIABLE sch_first: one class per school gets a 1, so summing it counts schools as Table I does (Angrist, Table I, p 539)
bysort grade schlcode: gen sch_first = (_n == 1)   // _n = row number within school, 1 for the first class (code: W1 lab section 7 + W4 lab Q4)
label variable sch_first "1 for one class per school-grade"   // (W4 lab section 0)

*--- verification  vs Angrist, Table I, p 539 and Table II p 551 (math N)
tab grade                               // classes: 2,049 grade 4, 2,019 grade 5, matches paper
tab grade if sch_first == 1             // schools: 1,013 grade 4, 1,002 grade 5, matches paper
count if grade == 5 & !missing(avgverb) // classes with a reading score: 2,019, matches paper (Angrist, Table II, p 551)
count if grade == 5 & !missing(avgmath) // classes with a math score: 2,018, matches paper; one below reading, the untested class from section 2


/*=========================================================================*/
*---4. Maimonides' rule class size, fsc (Angrist, eq 1, p 540)---*

* New variable: fsc = es / [int((es - 1)/40) + 1]: class size predicted by the rule from September enrollment es.
*              - Used as the instrument for actual class size in Tables III to V         
*
* Following Angrist (p 550)
*   - es is c_size, September enrollment, not the spring count cohsize (dictionary rows 3, 28)
*   - September is set before parents can react to class sizes, so it cannot carry their choices (Angrist, p 550)
/*=========================================================================*/

*--- new variable fsc
gen fsc = c_size / (floor((c_size - 1)/40) + 1)   // floor() is the paper's int() (code: W1 lab section 8, W4 lab Q4c)
* floor() is more flexible and is courses rounding function (rounds down +'s and -'s). Stata's int() only for positives. 
* same result here as no negative class sizes (obviously), floor() matches the paper's definition (Angrist, p 540)

label variable fsc "predicted class size, Maimonides' rule (eq 1)"   // (code: W4 lab section 0)
summarize fsc classize c_size cohsize   // fsc 8 to 40 by construction; class size 30.1 and enrollment 78.0 
                                        //  - sit between the grade means in Angrist, Table I (code: W1 lab section 1)



/*=========================================================================*/
*---5. Discontinuity samples and segment dummies (Angrist, pp 540, 557-559)---*
* Why: class size jumps at enrollment 40, 80, 120, where one more pupil splits the grade. Schools just
* either side of a cutoff have similar enrollment but very different fsc, so which side a school lands on
* is as good as random (Angrist, p 565; Week 4 lecture, slide 1).
*   - Tables III to VI rerun the models on these samples
*   - there is a cost in precision, 471 classes instead of 2,019 in grade 5 (Angrist, Table I, p 539)
*
* New variables
*   - seg1 seg2 seg3 = 1 if enrollment in [36,45], [76,85], [116,125] (Angrist, p 540)
*       - one dummy per cutoff, 40, 80, 120
*   - disc5 = 1 if in any segment, the +/-5 sample (Angrist, p 540, p 557)
*       - keeps only near-cutoff schools for Table I panel B, Table III panel B, Tables IV to VI
*   - disc3 = 1 if enrollment in [38,43], [78,83], [118,123], the +/-3 sample (Angrist, p 559)
*       - same, tighter band, for the +/-3 columns of Table VI
*   - seg1 seg2 double as Table VI's segment dummies (Angrist, p 559)
*       - control for which cutoff a school is at, seg3 omitted
*
* Following the text, not the table header
*   - Table I panel B header says 116-124, the text says [116,125] (Angrist, p 540, p 557)
*   - 125 gives the paper's own 471 and 415 classes, so the header is a typo
*
* sch_first still counts schools inside these samples
*   - c_size is the same for every class in a school (dictionary row 3), so a school is wholly in or out
/*=========================================================================*/

*--- +/-5 sample, one dummy per cutoff then their union
gen seg1 = inrange(c_size, 36, 45)      // cutoff 40 (Angrist, p 540; code: W4 lab Q10b, W1 lab section 8)
gen seg2 = inrange(c_size, 76, 85)      // cutoff 80
gen seg3 = inrange(c_size, 116, 125)    // cutoff 120, 125 as in the text (Angrist, p 540, p 557)
gen disc5 = (seg1 | seg2 | seg3)        // 1 if near any cutoff (code: W5 lab Bonus 5)
label variable disc5 "+/-5 discontinuity sample"   // (code: W4 lab section 0)

*--- +/-3 sample, no segment dummies: Table VI reuses seg1 seg2
gen disc3 = inrange(c_size, 38, 43) | inrange(c_size, 78, 83) | inrange(c_size, 118, 123)   // (Angrist, p 559)
label variable disc3 "+/-3 discontinuity sample"

*--- verification vs Angrist, Table I panel B p 539, Table VI p 558
tab grade disc5                         // 415 grade 4, 471 grade 5, matches paper (code: W1 lab section 8)
tab grade disc3                         // 265 grade 4, 302 grade 5, matches paper
tab grade if disc5 == 1 & sch_first == 1   // schools: 195 grade 4, 224 grade 5, matches paper


/*=========================================================================*/
*--- Close, Save the analysis file, and verify clean---*
* One file every table and figure reads, saved to output/ so data/ stays untouched (STATA_RULES slide 5)
/*=========================================================================*/
isid grade schlcode classid             // cleared: key still unique after the drops (safeguard, errors and stops if not)
describe                                // cleared: as expected, 4,068 obs and 65 variables: 58 raw + 7 new
save "$root/output/al_clean.dta", replace   // save fixed data
log close                               // close log


******************************************************************************
* SECTION 2: TABLE I
******************************************************************************

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
clear
capture log close                       // closes a log if crash run left open

* Cleaned data were created in SECTION 1 above.
confirm file "$root/output/al_clean.dta"

log using "$root/output/2_table1.log", replace text   // root is set at the top of this merged file
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


******************************************************************************
* SECTION 3: FIGURE I
******************************************************************************

/*=========================================================================*/
*---Figure I: Class size by enrollment count, actual and Maimonides' rule (Angrist, Figure I, p 541)---*
* Writes output/figure1_grade5.png (panel a) and output/figure1_grade4.png (panel b).
* Log: output/3_figure1.log
*
* Reads output/al_clean.dta from 1_clean.do. The sample is decided there (section 3) and
* fsc is built there (section 4), nothing new is built here
*
* Each panel plots the average actual class size at each enrollment count, solid, against
* the class size the rule predicts, fsc, dashed (Figure I caption, p 541). The paper also
* draws horizontal lines at the corners of fsc (p 541), we leave those out
*
* Sources cited in comments (same key as 1_clean.do):
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
* Anything not lifted from a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup. Course code: W1/W3 lab
*
clear
capture log close                       // closes a log if crash run left open

* Cleaned data were created in SECTION 1 above.
confirm file "$root/output/al_clean.dta"

log using "$root/output/3_figure1.log", replace text   // root is set at the top of this merged file
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade (Angrist, Figure I, p 541)---*
* Collapse to one row per enrollment count inside preserve/restore, so the full file is
* back for the next grade (code: W4 lab Q4c). fsc is the same for every class with that
* enrollment (Angrist, eq 1, p 540), so its mean is fsc itself
/*=========================================================================*/

foreach g in 5 4 {                                  // panel a grade 5, panel b grade 4, the paper's order (p 541; code: W1 lab section 13 foreach)
    preserve                                        // (code: W4 lab Q4c)
    keep if grade == `g'                            // (code: W1 lab section 5 keep if)
    collapse (mean) classize fsc, by(c_size)        // mean actual class size at each enrollment count (p 541; code: W3 lab Q3 collapse mean by)
    summarize classize fsc c_size                   // fsc max 40 by construction (eq 1, p 540), mean actual size tops out at 40.0 grade 5 and 40.3 grade 4, a few classes exceed 40 (p 542)
    twoway (line fsc c_size, lpattern(dash)) ///    // rule dashed, as the paper's legend (p 541; code: W3 lab Q4 twoway line, W4 lab Q4a lpattern(dash))
           (line classize c_size), ///              // actual solid
        legend(label(1 "Maimonides' rule") label(2 "Actual class size")) ///   // (code: W1 lab section 10)
        title("Grade `g'") xtitle("Enrollment count") ytitle("Class size") ///   // axis titles as printed (p 541; code: W4 lab Q4a)
        xlabel(0(20)220) ylabel(5(5)40)             // the paper's axes (p 541), the numlist form is OUR CHANGE
    graph export "$root/output/figure1_grade`g'.png", replace   // (code: W1 lab section 10)
    restore                                         // back to the full two-grade file for the next panel (code: W4 lab Q4c)
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log


******************************************************************************
* SECTION 4: FIGURE II
******************************************************************************

/*=========================================================================*/
*---Figure II: Average reading scores and predicted class size by enrollment (Angrist, Figure II, p 543)---*
* Writes output/figure2_grade5.png (panel a) and output/figure2_grade4.png (panel b).
* Log: output/4_figure2.log
*
* Reads output/al_clean.dta from 1_clean.do (sample section 3, fsc section 4). Builds e_bin,
* the enrollment interval midpoint, used only here
*
* Each panel plots the average reading score and the average fsc by enrollment, in intervals
* of ten plotted at their midpoints, scores on the left axis and fsc on the right (p 543 and
* fn 12, p 544). Math is Figure III, optional (what_to_replicate), not produced
*
* Enrollment range. The paper averages schools with enrollment 9 to 190 and pools 160 to 190
* into the last point at 165 (fn 12, p 544). We keep enrollment up to 169, so every point is one
* interval of ten and the axis still runs 5 to 165 (OUR CHANGE). Only the first and last
* points differ from the paper's rule, the first keeps enrollment 5 to 8, the last stops at 169
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
clear
capture log close                       // closes a log if crash run left open

* Cleaned data were created in SECTION 1 above.
confirm file "$root/output/al_clean.dta"

log using "$root/output/4_figure2.log", replace text   // root is set at the top of this merged file
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade (Angrist, Figure II, p 543)---*
* Keep one grade and enrollment up to 169 (see header), bin enrollment into intervals of ten,
* collapse to one row per interval, plot, then restore the full file for the next grade
* (code: W4 lab Q4c preserve, keep if, floor bin, collapse, restore)
/*=========================================================================*/

tab grade if c_size > 169                           // 53 grade 5, 40 grade 4 left out of the figure, the paper pools 160 to 190 into its last point (fn 12, p 544; code: W1 lab section 8 tab if)

foreach g in 5 4 {                                  // panel a grade 5, panel b grade 4 (p 543; code: W1 lab section 13 foreach)
    preserve                                        // (code: W4 lab Q4c)
    keep if grade == `g' & c_size <= 169            // intervals up to [160,169], see header (fn 12, p 544; code: W1 lab section 8 conditions)
    gen e_bin = 10 * floor(c_size / 10) + 5         // interval midpoint 5, 15, ..., 165 (fn 12, p 544; code: W4 lab Q4c floor bin)
    collapse (mean) avgverb fsc (count) n=avgverb, by(e_bin)   // averages by interval and the classes in each (p 543; code: W4 lab Q4c collapse mean count)
    list e_bin n avgverb fsc                        // 17 rows, 5 to 165, first interval 4 classes grade 5 and 3 grade 4, kept so the axis matches the paper's (p 543; code: W1 lab section 6 list)
    twoway (connected avgverb e_bin) ///            // scores, left axis (code: W4 lab Q11 connected)
           (connected fsc e_bin, yaxis(2) lpattern(dash)), ///   // fsc dashed on the right axis, as the paper (p 543; code: W4 lab Q11 yaxis(2), W4 lab Q4a lpattern(dash))
        legend(label(1 "Average reading score") label(2 "Predicted class size (right axis)")) ///   // (code: W1 lab section 10)
        title("Grade `g'") xtitle("Enrollment count") ///   // (code: W4 lab Q4a)
        ytitle("Average reading score") ytitle("Predicted class size", axis(2)) ///   // (code: W4 lab Q11 ytitle axis(2))
        xlabel(5(20)165)                            // midpoints 5 to 165 as the paper's axis (fn 12, p 544), the numlist form is OUR CHANGE
    graph export "$root/output/figure2_grade`g'.png", replace   // (code: W1 lab section 10)
    restore                                         // (code: W4 lab Q4c)
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log


******************************************************************************
* SECTION 5: TABLES II-IV AND THREE STANDARD ERRORS
******************************************************************************

/*=========================================================================*/
*---Tables II to IV---*
* Reads output/al_clean.dta (built by 1_clean.do) and produces, in this order:
*    s.1  new variables these tables alone need: c_size2, trend
*    s.2  Table II   OLS, grades 5 and 4                    (Angrist, Table II, p 551)
*    s.3  Table II   three-SE comparison, one column       (what_to_replicate.txt, required small addition)
*    s.4  Table III  reduced forms, full and +/-5 samples   (Angrist, Table III, p 553)
*    s.5  Table IV  2SLS, grade 5 (Table V is in SECTION 7)
* Output: output/table2.xlsx, table2_se.xlsx, table3.xlsx, table4.xlsx
* Log:    output/5_tables2to4.log
*
* Standard errors
*    - paper reports Moulton-corrected SEs (Angrist, notes to Tables II-V)
*    - we cluster at the school level instead, allowed by what_to_replicate.txt
*      ("Moulton-corrected standard errors may be replaced by ... clustered at the school level")
*    - classes in a school share teachers, neighbourhood and enrollment, so their
*      residuals are correlated; schlcode is the cluster (README data notes)
*    - the one exception, the hand-built Moulton SE, is s.3
*
* Sources cited in comments:
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx
*    task list = what_to_replicate.txt
* Anything not lifted from the paper file is marked OUR CHANGE.
/*=========================================================================*/

* setup
clear
capture log close                       // closes a log if crash run left open
log using "$root/output/5_tables2to4.log", replace text

use "$root/output/al_clean.dta", clear
tab grade                               
// check: 2,049 grade 4, 2,019 grade 5, as left by 1_clean.do


*--- small helper: adds the mean and s.d. of the dependent variable to e()
*--- so the tables can show the paper's "Mean score (s.d.)" row (Angrist, Tables II-V, top row)
*--- computed on the estimation sample, e(sample), so it matches each column's N (OUR CHANGE)
capture program drop add_ymean
program define add_ymean, eclass
    quietly summarize `e(depvar)' if e(sample)
    ereturn scalar ymean = r(mean)
    ereturn scalar ysd   = r(sd)
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
label variable c_size2 "enrollment squared / 100"

gen trend = .
replace trend = c_size                    if inrange(c_size,   0,  40)   // slope 1
replace trend = 20      + c_size/2        if inrange(c_size,  41,  80)   // slope 1/2
replace trend = 100/3   + c_size/3        if inrange(c_size,  81, 120)   // slope 1/3
replace trend = 130/3   + c_size/4        if inrange(c_size, 121, 160)   // slope 1/4
label variable trend "piecewise linear enrollment trend (p 555)"

count if missing(trend)                 // classes in schools with enrollment > 160, dropped only in col (4), (10)
tab grade if missing(trend)

* labels so the exported tables read like the paper's row names
label variable classize "Class size"
label variable tipuach  "Percent disadvantaged"
label variable c_size   "Enrollment"
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

local t2 ""                             // collects estimate names, in column order
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        regress `y' classize                  if grade == `g', vce(cluster schlcode)
        add_ymean
        estimates store t2_g`g'_`y'_a
        regress `y' classize tipuach          if grade == `g', vce(cluster schlcode)
        add_ymean
        estimates store t2_g`g'_`y'_b
        regress `y' classize tipuach c_size   if grade == `g', vce(cluster schlcode)
        add_ymean
        estimates store t2_g`g'_`y'_c
        local t2 "`t2' t2_g`g'_`y'_a t2_g`g'_`y'_b t2_g`g'_`y'_c"
    }
}

estimates table `t2', ///
    keep(classize tipuach c_size) ///
    b(%9.4f) se(%9.4f) stats(ymean ysd rmse r2 N)


/*=========================================================================*/
*---3. Table II: three standard errors side by side (task list, required small addition)---*
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
*     within-school correlation of class size itself (task list); our formula treats it as 1
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
* Panel A uses the full sample, panel B the +/-5 discontinuity sample (disc5, from 1_clean.do)
* Column order per panel: grade 5 class size (1)-(2), reading (3)-(4), math (5)-(6);
*                         grade 4 the same in (7)-(12)
* The class-size columns are the first stage of Tables IV-V; the score columns are the reduced form
/*=========================================================================*/

foreach p in A B {
    if "`p'" == "A" local smp "1"           // full sample: no restriction
    if "`p'" == "B" local smp "disc5 == 1"  // +/-5 sample (Angrist, p 540)
    local t3`p' ""
    foreach g in 5 4 {
        foreach y in classize avgverb avgmath {
            regress `y' fsc tipuach          if grade == `g' & `smp', vce(cluster schlcode)
            add_ymean
            estimates store t3`p'_g`g'_`y'_a
            regress `y' fsc tipuach c_size   if grade == `g' & `smp', vce(cluster schlcode)
            add_ymean
            estimates store t3`p'_g`g'_`y'_b
            local t3`p' "`t3`p'' t3`p'_g`g'_`y'_a t3`p'_g`g'_`y'_b"
        }
    }
}

estimates table `t3A', ///
    keep(fsc tipuach c_size) ///
    b(%9.4f) se(%9.4f) stats(ymean ysd rmse r2 N)

estimates table `t3B', ///
    keep(fsc tipuach c_size) ///
    b(%9.4f) se(%9.4f) stats(ymean ysd rmse r2 N)

/*=========================================================================*/
*---5. Table IV: 2SLS, grade 5 (Angrist, p 554)---*
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
* Only grade 5 is estimated here; SECTION 7 supplies Table V from file 11.
* ivregress 2sls with one instrument and one endogenous regressor is just identified,
* so the estimate equals reduced form / first stage from Table III (Angrist, p 552)
/*=========================================================================*/

foreach g in 5 {
    if `g' == 5 local tab "4"
    if `g' == 5 local rom "IV"
    local t`tab' ""
    foreach y in avgverb avgmath {
        ivregress 2sls `y' (classize = fsc) tipuach                  if grade == `g',              vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_1
        ivregress 2sls `y' (classize = fsc) tipuach c_size           if grade == `g',              vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_2
        ivregress 2sls `y' (classize = fsc) tipuach c_size c_size2   if grade == `g',              vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_3
        ivregress 2sls `y' (classize = fsc) trend                    if grade == `g',              vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_4
        ivregress 2sls `y' (classize = fsc) tipuach                  if grade == `g' & disc5 == 1, vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_5
        ivregress 2sls `y' (classize = fsc) tipuach c_size           if grade == `g' & disc5 == 1, vce(cluster schlcode)
        add_ymean
        estimates store t`tab'_`y'_6
        local t`tab' "`t`tab'' t`tab'_`y'_1 t`tab'_`y'_2 t`tab'_`y'_3 t`tab'_`y'_4 t`tab'_`y'_5 t`tab'_`y'_6"
    }

estimates table `t`tab'', ///
    keep(classize tipuach c_size c_size2 trend) ///
    b(%9.4f) se(%9.4f) stats(ymean ysd rmse N)
}


/*=========================================================================*/
*--- Close ---*
/*=========================================================================*/
estimates dir                           // log check: every stored column listed
log close


******************************************************************************
* SECTION 6: HELPER PROGRAMS
******************************************************************************

* Built-in Stata only. Record each model as a column in a CSV table.
* Call immediately after ivregress, before any other estimation command.
capture program drop record_table_result
program define record_table_result
    args handle column outcome terms
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
    quietly summarize `outcome' if e(sample)
    post `handle' (93) ("mean_score") (`column') (r(mean))
end

capture program drop export_table_results
program define export_table_results
    args source destination
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order
    export delimited using "`destination'", replace
    restore
end

capture program drop export_latex_results
program define export_latex_results
    args source destination
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order

    file open texout using "`destination'", write replace text
    file write texout "\begin{tabular}{l*{12}{c}}" _n
    file write texout "\hline" _n
    file write texout " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) & (11) & (12) \\" _n
    file write texout "\hline" _n
    quietly count
    forvalues i = 1/`r(N)' {
        local label = row[`i']
        local label = subinstr("`label'", "_", "\_", .)
        file write texout "`label'"
        forvalues c = 1/12 {
            capture confirm variable value`c'
            if _rc {
                local cell ""
            }
            else if missing(value`c'[`i']) {
                local cell ""
            }
            else {
                local cell : display %9.3f value`c'[`i']
                local cell = trim("`cell'")
            }
            file write texout " & `cell'"
        }
        file write texout " \\" _n
    }
    file write texout "\hline" _n
    file write texout "\end{tabular}" _n
    file close texout
    restore
end


******************************************************************************
* SECTION 7: TABLE V
******************************************************************************

* Table V, fourth grade: six specifications for each of reading and math.
* Requires output/al_clean.dta and helper programs defined in SECTION 6 above (original file 10).
* Paper pp. 555-556; school-clustered SEs allowed by what_to_replicate.txt.
capture log close
log using "$root/output/tables5_6/table5.log", text replace
use "$root/output/al_clean.dta", clear
keep if grade == 4
isid schlcode classid
assert !missing(c_size, classize, schlcode, fsc)
assert abs(fsc - c_size/(floor((c_size-1)/40)+1)) < 0.00001
assert disc5 == (inrange(c_size,36,45) | inrange(c_size,76,85) | inrange(c_size,116,125))

gen double c_size2 = c_size^2/100
* Continuous piecewise trend: slopes match fsc between cutoffs.
* Only defined through 160; larger cohorts leave this specification.
gen double trend = c_size if c_size <= 40
replace trend = 20 + c_size/2 if inrange(c_size,41,80)
replace trend = 100/3 + c_size/3 if inrange(c_size,81,120)
replace trend = 130/3 + c_size/4 if inrange(c_size,121,160)
gen byte full = 1

local ctrl1 tipuach
local ctrl2 tipuach c_size
local ctrl3 tipuach c_size c_size2
local ctrl4 trend
local ctrl5 tipuach
local ctrl6 tipuach c_size
* Specification 4 intentionally omits PD, as in the published table.
local sample1 full
local sample2 full
local sample3 full
local sample4 full
local sample5 disc5
local sample6 disc5

tempname results
tempfile records
postfile `results' int order str32 row byte column double value using "`records'", replace
local column = 0
local models
foreach y in avgverb avgmath {
    forvalues s = 1/6 {
        local ++column
        display "Table V column `column': `y', specification `s'"
        ivregress 2sls `y' `ctrl`s'' (classize = fsc) ///
            if `sample`s'' == 1, vce(cluster schlcode)
        estimates store T5_`column'
        local models `models' T5_`column'
        record_table_result `results' `column' `y' "classize tipuach c_size c_size2 trend"
        gen byte estimation_sample = e(sample)

        * First stage on exactly the same observations and controls as 2SLS.
        * This clustered F tests the excluded instrument, not all regressors.
        regress classize fsc `ctrl`s'' if estimation_sample, vce(cluster schlcode)
        test fsc
        post `results' (94) ("first_stage_F") (`column') (r(F))
        post `results' (95) ("first_stage_p") (`column') (r(p))
        drop estimation_sample
    }
}
postclose `results'
estimates table `models', b(%9.4f) se(%9.4f) stats(N rmse)
export_table_results "`records'" "$root/output/tables5_6/table5.csv"
export_latex_results "`records'" "$root/output/tables5_6/table5.tex"
log close


******************************************************************************
* SECTION 8: TABLE VI
******************************************************************************

* Table VI, fifth then fourth grade; reading then math within each grade.
* Each outcome: (1) +/-5 with PD; (2) +/-3 with PD; (3) +/-3 without PD.
* Paper pp. 558-560. No continuous enrollment controls in this table.
capture log close
log using "$root/output/tables5_6/table6.log", text replace
use "$root/output/al_clean.dta", clear
isid grade schlcode classid
assert inlist(grade,4,5)
assert !missing(c_size, classize, schlcode, fsc)
assert seg1 == inrange(c_size,36,45)
assert seg2 == inrange(c_size,76,85)
assert seg3 == inrange(c_size,116,125)
assert disc5 == (seg1 | seg2 | seg3)
assert disc3 == (inrange(c_size,38,43) | inrange(c_size,78,83) | inrange(c_size,118,123))
assert disc5 == 1 if disc3 == 1

* Three excluded instruments: above-cutoff indicator within each segment.
* Reusing them after restricting to disc3 yields [41,43], [81,83], [121,123].
gen byte z1 = inrange(c_size,41,45)
gen byte z2 = inrange(c_size,81,85)
gen byte z3 = inrange(c_size,121,125)
forvalues j = 1/3 {
    assert z`j' == ((fsc < 32)*seg`j') if disc5 == 1
}
tab grade disc5
tab grade disc3

* seg3 is omitted because a constant plus all three segments is collinear.
local ctrl1 tipuach seg1 seg2
local ctrl2 tipuach seg1 seg2
local ctrl3 seg1 seg2
local sample1 disc5
local sample2 disc3
local sample3 disc3

tempname results
tempfile records
postfile `results' int order str32 row byte column double value using "`records'", replace
local column = 0
local models
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        forvalues s = 1/3 {
            local ++column
            display "Table VI column `column': grade `g', `y', specification `s'"
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) ///
                if grade == `g' & `sample`s'' == 1, vce(cluster schlcode)
            estimates store T6_`column'
            local models `models' T6_`column'
            record_table_result `results' `column' `y' "classize tipuach seg1 seg2"
            gen byte estimation_sample = e(sample)
            regress classize z1 z2 z3 `ctrl`s'' if estimation_sample, vce(cluster schlcode)
            test z1 z2 z3
            post `results' (94) ("first_stage_F") (`column') (r(F))
            post `results' (95) ("first_stage_p") (`column') (r(p))
            drop estimation_sample
        }
    }
}
postclose `results'
estimates table `models', b(%9.4f) se(%9.4f) stats(N rmse)
export_table_results "`records'" "$root/output/tables5_6/table6.csv"
export_latex_results "`records'" "$root/output/tables5_6/table6.tex"

* Teaching/QA example, not another column of Table VI:
* One segment, grade 5 reading, +/-5, no PD. IV equals the Wald ratio.
* Use the IV estimation sample for BOTH mean differences.
ivregress 2sls avgverb (classize = z1) ///
    if grade == 5 & seg1 == 1, vce(cluster schlcode)
local iv = _b[classize]
gen byte wald_sample = e(sample)
quietly summarize avgverb if wald_sample & z1 == 1
local y1 = r(mean)
quietly summarize avgverb if wald_sample & z1 == 0
local y0 = r(mean)
quietly summarize classize if wald_sample & z1 == 1
local n1 = r(mean)
quietly summarize classize if wald_sample & z1 == 0
local n0 = r(mean)
assert abs(`n1'-`n0') > 0.00000001
local wald = (`y1'-`y0')/(`n1'-`n0')
display "Reading means (above, below): " `y1' " " `y0'
display "Class-size means (above, below): " `n1' " " `n0'
display "Wald ratio: " %9.6f `wald' "; IV coefficient: " %9.6f `iv'
assert abs(`wald'-`iv') < 0.000001
log close


display as result "All replication sections completed. See $root/output."

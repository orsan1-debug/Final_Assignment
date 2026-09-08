/*=========================================================================*/
*---Tables IV and V: 2SLS estimates for 1991, grade 5 (IV) and grade 4 (V)---*
* Same specification for both grades (paper pp. 554-556), so one loop over grades
* writes two tables. Twelve columns each: reading (1)-(6) then math (7)-(12);
* full sample (1) PD, (2) + enrollment, (3) + enrollment squared/100,
* (4) piecewise linear trend only; +/-5 discontinuity sample (5) PD, (6) + enrollment.
* fsc instruments class size in every column; SEs clustered by school.
* Output: output/table4.tex (grade 5), output/table5.tex (grade 4). Log: output/7_table4_5.log
*
* Course code (same key as 1_clean.do):
*   ivregress 2sls y x (d = z)           Week 6 lecture, "2SLS in Stata" (slide 15); vce(cluster)
*                                        option as in pset_1 3_rct Q4
*   gen / replace ... if / inrange()     W3 lab Q3 (group_cat); W4 lab Q10b
*   gen full = 1, nested foreach, spec and sample locals, esttab   as in 6_table3.do
*   estimates store / esttab             pset_1 3_rct Q5; W3 lab Q6
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/7_table4_5.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---enrollment controls used only in these two tables (paper p. 555)---*
/*=========================================================================*/
gen c_size2 = c_size^2 / 100                       // "Enrollment squared/100"
label variable c_size2 "enrollment squared / 100"

* piecewise linear trend: slopes equal the slopes of fsc on each segment (1, 1/2, 1/3, 1/4),
* so any variation left around it comes only from the jumps at 40, 80, 120.
* Defined on [0,160]: classes with enrollment above 160 are missing and drop out of
* column (4), which is why its N is 1961 (grade 5) and 2001 (grade 4) in the paper.
gen     trend = c_size                             if c_size <= 40
replace trend = 20 + c_size/2                      if inrange(c_size, 41, 80)
replace trend = 100/3 + c_size/3                   if inrange(c_size, 81, 120)
replace trend = 130/3 + c_size/4                   if inrange(c_size, 121, 160)
label variable trend "piecewise linear enrollment trend (p. 555)"
count if missing(trend)                            // 58 (grade 5) + 48 (grade 4) classes above 160

gen full = 1                                       // full-sample marker (as in 6_table3.do)

/*=========================================================================*/
*---the six specifications: controls and sample---*
/*=========================================================================*/
local ctrl1 tipuach
local ctrl2 tipuach c_size
local ctrl3 tipuach c_size c_size2
local ctrl4 trend
local ctrl5 tipuach
local ctrl6 tipuach c_size
local smp1 full
local smp2 full
local smp3 full
local smp4 full
local smp5 disc5
local smp6 disc5

local name_g5 table4                               // grade 5 is Table IV, grade 4 is Table V
local name_g4 table5

/*=========================================================================*/
*---2SLS, one table per grade---*
/*=========================================================================*/
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        summarize `y' if grade == `g' & full == 1
        summarize `y' if grade == `g' & disc5 == 1  // "Mean score (s.d.)" rows (log only)
        forvalues s = 1/6 {
            ivregress 2sls `y' `ctrl`s'' (classize = fsc) ///
                if grade == `g' & `smp`s'' == 1, vce(cluster schlcode)
            estimates store t45_g`g'_`y'_s`s'
        }
    }
    esttab t45_g`g'_avgverb_s1 t45_g`g'_avgverb_s2 t45_g`g'_avgverb_s3 ///
           t45_g`g'_avgverb_s4 t45_g`g'_avgverb_s5 t45_g`g'_avgverb_s6 ///
           t45_g`g'_avgmath_s1 t45_g`g'_avgmath_s2 t45_g`g'_avgmath_s3 ///
           t45_g`g'_avgmath_s4 t45_g`g'_avgmath_s5 t45_g`g'_avgmath_s6 ///
        using "$root/output/`name_g`g''.tex", replace booktabs ///
        b(%7.3f) se(%7.3f) keep(classize tipuach c_size c_size2 trend) ///
        coeflabels(classize "Class size" tipuach "Percent disadvantaged" ///
                   c_size "Enrollment" c_size2 "Enrollment squared/100" ///
                   trend "Piecewise linear trend") ///
        stats(rmse N, fmt(2 0) labels("Root MSE" "N")) ///
        mtitles("Reading" "Reading" "Reading" "Reading" "Reading" "Reading" ///
                "Math" "Math" "Math" "Math" "Math" "Math") ///
        addnotes("Grade `g'. Columns 1-4 and 7-10 full sample, 5-6 and 11-12 +/-5 discontinuity sample." ///
                 "2SLS, fsc instruments class size. Standard errors clustered by school.")
}
* log check, class-size coefficient on reading: grade 5 columns (1)-(6) -.158 -.277 -.278 -.190 -.410 -.582,
* grade 4 -.110 -.133 -.125 -.147 -.098 -.150. Columns (1), (5), (6) equal the paper's; the
* enrollment-control columns differ from the published numbers (most in the quadratic column,
* grade 4: -.125 here vs -.074 published). The specification is the one the paper describes and
* the one in the authors' deposited code, so the gap lies between the published table and the
* deposited data, not in a coding choice (PROJECT_README: published numbers are a benchmark).

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

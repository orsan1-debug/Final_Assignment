/*=========================================================================*/
*---Tables IV and V: 2SLS estimates for 1991, grade 5 (Table IV) and grade 4 (Table V) (Angrist, pp 554, 556)---*
* Writes output/table4.tex (grade 5) and output/table5.tex (grade 4). Twelve columns each:
* reading (1) to (6) then math (7) to (12). Full sample (1) PD, (2) + enrollment,
* (3) + enrollment squared/100, (4) piecewise linear trend only, then the +/-5 sample
* (5) PD, (6) + enrollment (pp 554, 556). Log: output/7_table4_5.log
*
* Reads output/al_clean.dta from 1_clean.do (sample section 3, fsc section 4, disc5 section 5).
* Builds c_size2, trend and full, used only here
*
* fsc instruments class size in every column (Table IV notes, p 554). The same specification
* runs for both grades, so one loop writes both tables. Standard errors
* clustered by school (what_to_replicate allowed simplification)
*
* Sources cited in comments (same key as 1_clean.do):
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    what_to_replicate = the task list on Moodle
*    AngristLavy_Table4.do = the authors' deposited code, reference only, never copied
* Steps and choices that are our own, not the paper's, are marked OUR CHANGE.
/*=========================================================================*/

* setup
*
clear all
set more off                            // lets file run w/o manual input when output is long
if "$root" == "" {                      // run alone: find the project folder as 0_master.do does (OUR CHANGE)
    capture confirm file "../code/0_master.do"    // Stata starts in code/ when a do-file is opened by double-click
    if !_rc cd ..                                 // up to the project folder
    confirm file "code/0_master.do"               // stops with "file not found" unless the working directory is the project folder
    global root "`c(pwd)'"
}
capture log close                       // closes a log if crash run left open

*--- dependency: needs output/al_clean.dta from 1_clean.do, built here if missing so this file runs alone (OUR CHANGE)
capture confirm file "$root/output/al_clean.dta"   // _rc is 0 if the file exists
if _rc do "$root/code/1_clean.do"                  // runs the cleaning file only when the .dta is not there, before this log opens

log using "$root/output/7_table4_5.log", replace text   // $root set once in 0_master.do
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. Enrollment controls used only in these two tables (Angrist, p 555)---*
* Column (3) adds enrollment squared over 100 (Table IV row label, p 554). Column (4) replaces
* PD and enrollment with a piecewise linear trend whose slopes equal the slopes of fsc on each
* segment, 1, 1/2, 1/3, 1/4, so what is left around it comes only from the jumps at 40, 80, 120 (p 555)
*
* The trend is defined on [0,160] (p 555). Classes with enrollment above 160 have trend missing
* and drop out of column (4), which is why its N is 1,961 and 2,001 (pp 554, 556). Same
* definition as the authors' code (AngristLavy_Table4.do lines 42, 45-48)
/*=========================================================================*/

gen c_size2 = c_size^2 / 100            // "Enrollment squared/100" (p 554)
label variable c_size2 "enrollment squared / 100"

gen     trend = c_size            if c_size <= 40               // slope 1 on [0,40] (p 555)
replace trend = 20 + c_size/2     if inrange(c_size, 41, 80)    // slope 1/2
replace trend = 100/3 + c_size/3  if inrange(c_size, 81, 120)   // slope 1/3
replace trend = 130/3 + c_size/4  if inrange(c_size, 121, 160)  // slope 1/4, missing above 160
label variable trend "piecewise linear enrollment trend (p 555)"
tab grade if missing(trend)             // 58 grade 5 and 48 grade 4 above 160, the classes column (4) loses, matches the column (4) N (pp 554, 556)

gen full = 1                            // full-sample marker, as in 6_table3.do (OUR CHANGE)


/*=========================================================================*/
*---2. The six specifications: controls and sample (Angrist, Tables IV and V, pp 554, 556)---*
* Two locals per column, controls and sample marker, so one loop runs every column.
* Nested `ctrl`s'' and `smp`s'' are OUR CHANGE
/*=========================================================================*/

local ctrl1 tipuach                     // (1) PD (p 554)
local ctrl2 tipuach c_size              // (2) + enrollment
local ctrl3 tipuach c_size c_size2      // (3) + enrollment squared/100
local ctrl4 trend                       // (4) trend only, no PD (p 555)
local ctrl5 tipuach                     // (5) PD, +/-5 sample
local ctrl6 tipuach c_size              // (6) + enrollment, +/-5 sample
local smp1 full
local smp2 full
local smp3 full
local smp4 full
local smp5 disc5                        // +/-5 discontinuity sample (1_clean.do section 5)
local smp6 disc5

local name_g5 table4                    // grade 5 is Table IV, grade 4 is Table V, nested `name_g`g'' is OUR CHANGE
local name_g4 table5


/*=========================================================================*/
*---3. 2SLS, one table per grade, export and checks (Angrist, Tables IV and V, pp 554, 556)---*
/*=========================================================================*/

foreach g in 5 4 {                                  // Table IV then Table V
    foreach y in avgverb avgmath {                  // reading then math
        summarize `y' if grade == `g' & full == 1   // mean score rows, 74.4 67.3 grade 5 and 72.5 68.9 grade 4 match Table I (p 539), Table V prints 67.3 for grade 4 math (p 556)
        summarize `y' if grade == `g' & disc5 == 1  // 74.5 67.0 grade 5 and 72.5 68.7 grade 4, matches paper (pp 554, 556)
        forvalues s = 1/6 {
            ivregress 2sls `y' `ctrl`s'' (classize = fsc) ///   // one command runs both stages with the right SEs
                if grade == `g' & `smp`s'' == 1, vce(cluster schlcode)   // clustered by school
            estimates store t45_g`g'_`y'_s`s'       // one name per grade and column
        }
    }
    esttab t45_g`g'_avgverb_s1 t45_g`g'_avgverb_s2 t45_g`g'_avgverb_s3 ///   // columns in the paper's order
           t45_g`g'_avgverb_s4 t45_g`g'_avgverb_s5 t45_g`g'_avgverb_s6 ///
           t45_g`g'_avgmath_s1 t45_g`g'_avgmath_s2 t45_g`g'_avgmath_s3 ///
           t45_g`g'_avgmath_s4 t45_g`g'_avgmath_s5 t45_g`g'_avgmath_s6 ///
        using "$root/output/`name_g`g''.tex", replace booktabs ///   // table4.tex for grade 5, table5.tex for grade 4
        b(%7.3f) se(%7.3f) keep(classize tipuach c_size c_size2 trend) ///   // three decimals as printed
        coeflabels(classize "Class size" tipuach "Percent disadvantaged" ///   // row names as printed
                   c_size "Enrollment" c_size2 "Enrollment squared/100" ///
                   trend "Piecewise linear trend") ///
        stats(rmse N, fmt(2 0) labels("Root MSE" "N")) ///   // the table's bottom rows, rmse as an esttab stat is OUR CHANGE
        mtitles("Reading" "Reading" "Reading" "Reading" "Reading" "Reading" ///
                "Math" "Math" "Math" "Math" "Math" "Math") ///
        addnotes("Grade `g'. Columns 1-4 and 7-10 full sample, 5-6 and 11-12 +/-5 discontinuity sample." ///
                 "2SLS, fsc instruments class size. Standard errors clustered by school.")
}

*--- verification vs Angrist, Table IV p 554 and Table V p 556, class size row, columns (1) to (6) then (7) to (12)
* grade 5 -.158 -.277 -.263 -.190 -.410 -.582 and -.013 -.231 -.264 -.205 -.185 -.443
* (paper -.158 -.275 -.260 -.186 -.410 -.582 and -.013 -.230 -.261 -.202 -.185 -.443)
* grade 4 -.110 -.133 -.074 -.147 -.098 -.150 and .049 -.050 -.033 -.098 .095 .023, matches paper
* Table V matches to three decimals. Table IV columns (1), (5), (6), (7), (11), (12) match, the enrollment-control
* columns sit within .004 of the published numbers. The specification is the paper's and the authors'
* (AngristLavy_Table4.do lines 59-62), so the small gap sits between the published table and the deposited
* data, not in a coding choice. Published numbers are a benchmark, not a target (README)
* N 2,019 2,019 2,019 1,961 471 471 grade 5 and 2,049 2,049 2,049 2,001 415 415 grade 4, matches paper


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

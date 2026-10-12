/*=========================================================================*/
*---Table II: OLS estimates for 1991 (Angrist, Table II, p 551)---*
* Writes output/table2.tex, twelve columns: grade 5 then grade 4, reading then math, three
* specifications each, (1) class size, (2) + percent disadvantaged, (3) + enrollment (p 551).
* The second block writes output/table2_se.tex, the required three-SE comparison.
* Log: output/5_table2.log
*
* Reads output/al_clean.dta from 1_clean.do (sample section 3). Builds resid, the residuals
* of column (2), used only here
*
* Standard errors clustered by school replace the paper's Moulton correction for the
* correlation of classes within a school (Angrist, p 547), the allowed simplification in
* what_to_replicate. The three-SE block is the one place the correction itself is computed
*
* Sources cited in comments (same key as 1_clean.do):
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    what_to_replicate = the task list on Moodle, incl. the required small addition
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

log using "$root/output/5_table2.log", replace text   // $root set once in 0_master.do
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. The twelve regressions (Angrist, Table II, p 551)---*
* WHAT  OLS of class average reading and math on class size, then adding PD, then enrollment, by grade
* WHY   The benchmark before IV. Class size looks good for scores (.221) until PD is added (-.031,
*       Angrist, p 550). Disadvantaged schools get funds for extra classes (p 542) and score lower,
*       so OLS mixes class size with background (p 546). That is why the paper needs an instrument
*
* One loop over grade, outcome and specification, with spec locals, so nothing is copy-pasted.
* reg drops the one grade 5 class without a math score, so math N is
* 2,018 (Table II, p 551; 1_clean.do section 2)
/*=========================================================================*/

local spec1 classize                    // column (1) (p 551)
local spec2 classize tipuach            // column (2) adds percent disadvantaged, PD (dictionary row 52)
local spec3 classize tipuach c_size     // column (3) adds September enrollment (dictionary row 3)

eststo clear                                        // empties the list of stored columns, so a rerun starts at column (1)
foreach g in 5 4 {                                  // grade 5 first, as in the paper
    summarize avgverb avgmath if grade == `g'       // mean score rows
    foreach y in avgverb avgmath {                  // reading then math
        forvalues s = 1/3 {
            eststo: reg `y' `spec`s'' if grade == `g', vce(cluster schlcode)   // stores each column in the order run, clustered by school, nested `spec`s'' is OUR CHANGE
        }
    }
}


/*=========================================================================*/
*---2. Export (Angrist, Table II, p 551)---*
* WHAT  Write the twelve stored columns to output/table2.tex
* WHY   The loop ran them in the paper's column order, so each column lines up with Table II (p 551)
/*=========================================================================*/

esttab using "$root/output/table2.tex", replace booktabs ///   // every column stored by eststo above
    b(%7.3f) se(%7.3f) keep(classize tipuach c_size) ///   // three decimals as printed
    coeflabels(classize "Class size" tipuach "Percent disadvantaged" c_size "Enrollment") ///   // row names as printed
    stats(rmse r2 N, fmt(2 3 0) labels("Root MSE" "R-squared" "N")) ///   // the table's bottom rows (p 551), rmse as an esttab stat is OUR CHANGE
    mtitles("Reading" "Reading" "Reading" "Math" "Math" "Math" ///
            "Reading" "Reading" "Reading" "Math" "Math" "Math") ///
    addnotes("Columns 1-6 grade 5, columns 7-12 grade 4. Standard errors clustered by school.")


/*=========================================================================*/
*---3. Required addition: three standard errors for column (2) (what_to_replicate)---*
* WHAT  The class size SE of column (2) three ways, conventional, clustered by school, and
*       conventional inflated by the design effect
* WHY   Classes in one school share a school error (eq 3, Angrist, p 547), so conventional SEs
*       are too small. The paper corrects for this (p 547), the comparison shows by how much
*
* Column (2), grade 5 reading on class size and PD, is the paper's headline OLS result. The
* positive raw correlation of .221 turns into -.031 once PD is controlled (Angrist, p 550)
*
* (i) conventional OLS, (ii) clustered by school, (iii) (i) inflated by sqrt(1 + (m - 1) rho),
* the design effect DEFF (what_to_replicate). m is the mean number
* of classes per school in the estimation sample, rho the intraclass correlation of the residuals
*
* (iii) will not equal the paper's Moulton SE, which also allows for the within-school correlation
* of class size itself (what_to_replicate required addition; Angrist, p 547)
/*=========================================================================*/

*--- (i) conventional OLS, the same regression without clustering
reg avgverb classize tipuach if grade == 5
local b_cs = _b[classize]
local se_i = _se[classize]                 // _se[] is the same syntax for the standard error (OUR CHANGE)
local n_cl = e(N)                          // classes in the estimation sample, e() holds the regression's own results (OUR CHANGE)

*--- rho: share of the residual variance that is a school component shared by its classes
*--- rho = sigma_u^2 / (sigma_u^2 + sigma_e^2)
predict resid if e(sample), residuals      // residuals of (i), estimation sample only (residuals option and e(sample) are OUR CHANGE)
loneway resid schlcode                     // one-way ANOVA of the residuals across schools, r(rho) is the ratio above (OUR CHANGE, built-in Stata)
local rho = r(rho)

*--- m: average number of classes per school in the estimation sample, the classes with a residual
preserve
keep if !missing(resid)                    // the classes of (i)
collapse (count) n_classes=classize, by(schlcode)   // one row per school with its number of classes
summarize n_classes                        // mean is m
local m = r(mean)
restore

*--- (iii) the design effect applied to (i)
local deff   = 1 + (`m' - 1) * `rho'       // DEFF = 1 + (m - 1) rho (what_to_replicate)
local se_iii = `se_i' * sqrt(`deff')       // sqrt() is a Stata function (OUR CHANGE)

*--- (ii) clustered by school, the Table II column itself
reg avgverb classize tipuach if grade == 5, vce(cluster schlcode)
local se_ii = _se[classize]

*--- the coefficient and the three standard errors, printed to the log
display _n "Table II column (2), class size coefficient: " %7.3f `b_cs'
display "(i)   conventional OLS s.e.:            " %7.4f `se_i'
display "(ii)  clustered by school s.e.:         " %7.4f `se_ii'
display "(iii) Moulton-inflated s.e.:            " %7.4f `se_iii'
display "      m = " %6.3f `m' "   rho = " %6.3f `rho' "   sqrt(DEFF) = " %6.3f sqrt(`deff')

*--- export as a small table
local b_cs   = string(`b_cs', "%7.3f")     // formatted for the .tex, string() leaves no padding
local se_i   = string(`se_i', "%7.4f")
local se_ii  = string(`se_ii', "%7.4f")
local se_iii = string(`se_iii', "%7.4f")
local m      = string(`m', "%6.3f")
local rho    = string(`rho', "%6.3f")

file open t2se using "$root/output/table2_se.tex", write replace
file write t2se "\begin{tabular}{lc}" _n
file write t2se "\toprule" _n
file write t2se "Table II, column (2): grade 5 reading on class size and percent disadvantaged & \\" _n
file write t2se "\midrule" _n
file write t2se "Class size coefficient & `b_cs' \\" _n
file write t2se "(i) conventional OLS standard error & `se_i' \\" _n
file write t2se "(ii) standard error clustered by school & `se_ii' \\" _n
file write t2se "(iii) Moulton-inflated: (i) x sqrt(1 + (m - 1) rho) & `se_iii' \\" _n
file write t2se "\midrule" _n
file write t2se "m, average classes per school & `m' \\" _n
file write t2se "rho, intraclass correlation of residuals & `rho' \\" _n
file write t2se "N & `n_cl' \\" _n
file write t2se "\bottomrule" _n
file write t2se "\end{tabular}" _n
file close t2se


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

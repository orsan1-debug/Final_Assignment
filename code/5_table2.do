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
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
*    what_to_replicate = the task list on Moodle, incl. the required small addition
*    Week 5 lecture = Module 5 slides, section 4.2 clustering and the appendix deriving the design effect
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

log using "$root/output/5_table2.log", replace text   // $root set once in 0_master.do, edit the path there
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. The twelve regressions (Angrist, Table II, p 551)---*
* One loop over grade, outcome and specification, with spec locals, so nothing is copy-pasted
* (STATA_RULES slide 6). reg drops the one grade 5 class without a math score, so math N is
* 2,018 (Table II, p 551; 1_clean.do section 2)
/*=========================================================================*/

local spec1 classize                    // column (1) (p 551; code: W1 lab section 11 locals)
local spec2 classize tipuach            // column (2) adds percent disadvantaged, PD (dictionary row 52)
local spec3 classize tipuach c_size     // column (3) adds September enrollment (dictionary row 3)

foreach g in 5 4 {                                  // grade 5 first, as in the paper (code: W1 lab section 13 foreach)
    summarize avgverb avgmath if grade == `g'       // mean score rows, 74.4 67.3 grade 5 and 72.5 68.9 grade 4 match Table I (p 539), Table II itself prints 74.3 and 69.9 (p 551)
    foreach y in avgverb avgmath {                  // reading then math
        forvalues s = 1/3 {                         // (code: W1 lab section 13 forvalues)
            reg `y' `spec`s'' if grade == `g', vce(cluster schlcode)   // clustered by school, nested `spec`s'' is OUR CHANGE (code: W5 lab Q2 vce(cluster))
            estimates store t2_g`g'_`y'_s`s'        // one name per column (code: W5 lab Q2)
        }
    }
}


/*=========================================================================*/
*---2. Export and checks (Angrist, Table II, p 551)---*
/*=========================================================================*/

esttab t2_g5_avgverb_s1 t2_g5_avgverb_s2 t2_g5_avgverb_s3 ///   // columns in the paper's order (p 551; code: W2 lab Q12 esttab using)
       t2_g5_avgmath_s1 t2_g5_avgmath_s2 t2_g5_avgmath_s3 ///
       t2_g4_avgverb_s1 t2_g4_avgverb_s2 t2_g4_avgverb_s3 ///
       t2_g4_avgmath_s1 t2_g4_avgmath_s2 t2_g4_avgmath_s3 ///
    using "$root/output/table2.tex", replace booktabs ///
    b(%7.3f) se(%7.3f) keep(classize tipuach c_size) ///   // three decimals as printed (code: W2 lab Q12 b() se(), W4 lab Q1 keep())
    coeflabels(classize "Class size" tipuach "Percent disadvantaged" c_size "Enrollment") ///   // row names as printed (code: W3 lab Q6 coeflabels)
    stats(rmse r2 N, fmt(2 3 0) labels("Root MSE" "R-squared" "N")) ///   // the table's bottom rows (p 551; code: W3 lab Q6 stats labels), rmse as an esttab stat is OUR CHANGE
    mtitles("Reading" "Reading" "Reading" "Math" "Math" "Math" ///   // (code: W3 lab Q6 mtitles)
            "Reading" "Reading" "Reading" "Math" "Math" "Math") ///
    addnotes("Columns 1-6 grade 5, columns 7-12 grade 4. Standard errors clustered by school.")   // (code: W4 lab Q1 addnotes)

*--- verification vs Angrist, Table II, p 551 (the regressions above are in the log)
* class size row .221 -.031 -.025 .322 .076 .019 .141 -.053 -.040 .221 .055 .009, matches paper
* N 2,019 reading and 2,018 math in grade 5, 2,049 in grade 4, matches paper


/*=========================================================================*/
*---3. Required addition: three standard errors for column (2) (what_to_replicate; Week 5 lecture)---*
* Column (2), grade 5 reading on class size and PD, is the paper's headline OLS result. The
* positive raw correlation of .221 turns into -.031 once PD is controlled (Angrist, p 550)
*
* (i) conventional OLS, (ii) clustered by school, (iii) (i) inflated by sqrt(1 + (m - 1) rho),
* the design effect DEFF of the Week 5 lecture (section 4.2 and appendix). m is the mean number
* of classes per school in the estimation sample, rho the intraclass correlation of the residuals
*
* (iii) will not equal the paper's Moulton SE, which also allows for the within-school correlation
* of class size itself (what_to_replicate required addition; Angrist, p 547)
/*=========================================================================*/

*--- (i) conventional OLS, the same regression without clustering
reg avgverb classize tipuach if grade == 5   // b -.031, SE .022, the numbers quoted in the text (Angrist, p 550; code: W1 lab section 8 reg if)
local b_cs = _b[classize]                  // (code: W2 lab Q6b _b[] into a local)
local se_i = _se[classize]                 // _se[] is the same syntax for the standard error (OUR CHANGE)
local n_cl = e(N)                          // 2,019 classes in the estimation sample, e() holds the regression's own results (OUR CHANGE)

*--- rho: share of the residual variance that is a school component shared by its classes
*--- rho = sigma_u^2 / (sigma_u^2 + sigma_e^2), Week 5 lecture appendix, deriving the design effect
predict resid if e(sample), residuals      // residuals of (i), estimation sample only (residuals option and e(sample) are OUR CHANGE; code: W4 lab Q6b predict)
loneway resid schlcode                     // one-way ANOVA of the residuals across schools, r(rho) is the ratio above (OUR CHANGE, built-in Stata), rho .535
local rho = r(rho)                         // (code: W1 lab section 12 r() into a local)

*--- m: average number of classes per school in the estimation sample, the classes with a residual
preserve                                   // (code: W4 lab Q4c)
keep if !missing(resid)                    // the 2,019 classes of (i) (code: W1 lab section 5 keep if)
collapse (count) n_classes=classize, by(schlcode)   // one row per school with its number of classes (code: W4 lab Q4c collapse count)
summarize n_classes                        // 1,002 schools, matches paper (Angrist, Table I, p 539), mean 2.015 is m
local m = r(mean)                          // (code: W1 lab section 12)
restore                                    // (code: W4 lab Q4c)

*--- (iii) the design effect applied to (i)
local deff   = 1 + (`m' - 1) * `rho'       // DEFF = 1 + (m - 1) rho (Week 5 lecture appendix), 1.543
local se_iii = `se_i' * sqrt(`deff')       // sqrt(DEFF) 1.242, sqrt() is a Stata function (OUR CHANGE)

*--- (ii) clustered by school, the Table II column itself
reg avgverb classize tipuach if grade == 5, vce(cluster schlcode)   // SE .026, the same to three decimals as the paper's Moulton SE (Table II, p 551; code: W5 lab Q2)
local se_ii = _se[classize]

*--- verification: b -.031 with (i) .0222 matches the text (Angrist, p 550), (ii) .0262, (iii) .0276, m 2.015, rho .535, sqrt(DEFF) 1.242
display _n "Table II column (2), class size coefficient: " %7.3f `b_cs'   // (code: W2 lab Q6b display %7.3f, W2 lab Q2 display _n)
display "(i)   conventional OLS s.e.:            " %7.4f `se_i'
display "(ii)  clustered by school s.e.:         " %7.4f `se_ii'
display "(iii) Moulton-inflated s.e.:            " %7.4f `se_iii'
display "      m = " %6.3f `m' "   rho = " %6.3f `rho' "   sqrt(DEFF) = " %6.3f sqrt(`deff')

*--- export as a small table
local b_cs   : display %7.3f `b_cs'        // formatted for the .tex (code: W4 lab Q7)
local se_i   : display %7.4f `se_i'
local se_ii  : display %7.4f `se_ii'
local se_iii : display %7.4f `se_iii'
local m      : display %6.3f `m'
local rho    : display %6.3f `rho'

file open t2se using "$root/output/table2_se.tex", write replace   // (code: W1 lab section 12, W4 lab Q7)
file write t2se "\begin{tabular}{lc}" _n
file write t2se "\toprule" _n
file write t2se "Table II, column (2): grade 5 reading on class size and percent disadvantaged & \\" _n
file write t2se "\midrule" _n
file write t2se "Class size coefficient & `=trim("`b_cs'")' \\" _n   // trim() drops the padding of the display format (code: W4 lab Q8)
file write t2se "(i) conventional OLS standard error & `=trim("`se_i'")' \\" _n
file write t2se "(ii) standard error clustered by school & `=trim("`se_ii'")' \\" _n
file write t2se "(iii) Moulton-inflated: (i) x sqrt(1 + (m - 1) rho) & `=trim("`se_iii'")' \\" _n
file write t2se "\midrule" _n
file write t2se "m, average classes per school & `=trim("`m'")' \\" _n
file write t2se "rho, intraclass correlation of residuals & `=trim("`rho'")' \\" _n
file write t2se "N & `n_cl' \\" _n
file write t2se "\bottomrule" _n
file write t2se "\end{tabular}" _n
file close t2se                            // (code: W1 lab section 12)


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

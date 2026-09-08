/*=========================================================================*/
*---Table II: OLS estimates for 1991---*
* Twelve columns: grade 5 then grade 4; reading then math; three specifications
* each: (1) class size, (2) + percent disadvantaged, (3) + enrollment (paper p. 551).
* Standard errors clustered by school replace the paper's Moulton SEs
* (what_to_replicate: allowed simplification). Output: output/table2.tex
*
* Required small addition: for column (2), grade 5 reading with class size and
* percent disadvantaged, three SEs for the class-size coefficient side by side:
* (i) conventional OLS, (ii) clustered by school, (iii) (i) x sqrt(1 + (m - 1) rho),
* m = average classes per school in the estimation sample, rho = intraclass
* correlation of the residuals. Output: output/table2_se.tex. Log: output/5_table2.log
*
* Course code (same key as 1_clean.do):
*   reg y x if ..., vce(cluster schlcode)   pset_1 3_rct Q4 (vce(cluster schoolid))
*   nested foreach / forvalues              W1 lab s.13; pset_1 3_rct Q6 (foreach g / foreach v)
*   local speclist, nested `spec`s''        W1 lab s.11 (local controls); nesting as in 2_table1.do
*   estimates store / esttab ... using, replace booktabs b() se() keep() stats() mtitles() addnotes()
*                                           pset_1 3_rct Q5; stats(..., fmt() labels()) and
*                                           coeflabels() from W3 lab Q6 (balance_table.tex)
*   summarize                               W1 lab s.1
*   _b[] into a local                       W2 lab Q6 (local beta_long = _b[treated]); _se[] is the
*                                           same syntax for the standard error: OUR CHANGE
*   e(N), e(sample)                         W4 lab Q11 uses r(N); e() are the regression's stored
*                                           results (Stata regress): OUR CHANGE
*   preserve / keep if / collapse (count) / summarize / restore   W4 lab Q4c
*   predict resid if e(sample), residuals   W4 lab Q4c (predict ..., xb) and Q6 (predict ..., pr);
*                                           the residuals option: OUR CHANGE
*   loneway                                 OUR CHANGE: built-in Stata one-way ANOVA, estimates the two
*                                           variance components rho is made of (Week 5 lecture, appendix)
*   sqrt()                                  Stata function; the formula is the Week 5 lecture's design effect
*   display / file open / write / close     W1 lab s.12; W4 lab Q7
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/5_table2.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---Table II: the twelve regressions---*
/*=========================================================================*/
local spec1 classize
local spec2 classize tipuach
local spec3 classize tipuach c_size

foreach g in 5 4 {
    summarize avgverb avgmath if grade == `g'          // "Mean score (s.d.)" rows of the table (log only)
    foreach y in avgverb avgmath {
        forvalues s = 1/3 {
            reg `y' `spec`s'' if grade == `g', vce(cluster schlcode)
            estimates store t2_g`g'_`y'_s`s'
        }
    }
}

esttab t2_g5_avgverb_s1 t2_g5_avgverb_s2 t2_g5_avgverb_s3 ///
       t2_g5_avgmath_s1 t2_g5_avgmath_s2 t2_g5_avgmath_s3 ///
       t2_g4_avgverb_s1 t2_g4_avgverb_s2 t2_g4_avgverb_s3 ///
       t2_g4_avgmath_s1 t2_g4_avgmath_s2 t2_g4_avgmath_s3 ///
    using "$root/output/table2.tex", replace booktabs ///
    b(%7.3f) se(%7.3f) keep(classize tipuach c_size) ///
    coeflabels(classize "Class size" tipuach "Percent disadvantaged" c_size "Enrollment") ///
    stats(rmse r2 N, fmt(2 3 0) labels("Root MSE" "R-squared" "N")) ///
    mtitles("Reading" "Reading" "Reading" "Math" "Math" "Math" ///
            "Reading" "Reading" "Reading" "Math" "Math" "Math") ///
    addnotes("Columns 1-6 grade 5, columns 7-12 grade 4. Standard errors clustered by school.")

/*=========================================================================*/
*---Required addition: three standard errors for column (2)---*
* Column (2) is grade 5 reading on class size and percent disadvantaged, the
* paper's headline OLS result (p. 550: -.031 once PD is controlled for).
/*=========================================================================*/

* (i) conventional OLS: the same regression without clustering
reg avgverb classize tipuach if grade == 5
local b_cs   = _b[classize]
local se_i   = _se[classize]
local n_cl   = e(N)                                   // 2019 classes in the estimation sample

* rho: intraclass correlation of the regression residuals. Week 5 lecture (design effect
* appendix): rho = sigma_u^2 / (sigma_u^2 + sigma_e^2), the share of residual variance
* that is a school component shared by all classes in the school. loneway estimates the
* two components by one-way ANOVA of the residuals across schools and reports the ratio.
predict resid if e(sample), residuals                 // residuals of (i), estimation sample only
loneway resid schlcode
local rho = r(rho)

* m: average number of classes per school in the estimation sample (the classes with a residual)
preserve
keep if !missing(resid)
collapse (count) n_classes=classize, by(schlcode)     // one row per school, its number of classes
summarize n_classes                                   // mean = m; 1002 schools
local m = r(mean)
restore

* (iii) the Week 5 lecture's design effect applied to (i): DEFF = 1 + (m - 1) rho.
* Residual-only version as required; the paper's Moulton SE also allows for the
* within-school correlation of the regressor, so (iii) is not expected to match it.
local deff   = 1 + (`m' - 1) * `rho'
local se_iii = `se_i' * sqrt(`deff')

* (ii) clustered by school, the Table II column itself
reg avgverb classize tipuach if grade == 5, vce(cluster schlcode)
local se_ii = _se[classize]

* log check: b = -.031; (i) .022, the SE quoted in the paper's text (p. 550); (ii) .026; (iii) about .028
* (m = 2.015, rho about .54, so sqrt(DEFF) about 1.24)
display _n "Table II column (2), class size coefficient: " %7.3f `b_cs'
display "(i)   conventional OLS s.e.:            " %7.4f `se_i'
display "(ii)  clustered by school s.e.:         " %7.4f `se_ii'
display "(iii) Moulton-inflated s.e.:            " %7.4f `se_iii'
display "      m = " %6.3f `m' "   rho = " %6.3f `rho' "   sqrt(DEFF) = " %6.3f sqrt(`deff')

* export as a small table (numbers formatted the way the Week 4 lab does it)
local b_cs   : display %7.3f `b_cs'
local se_i   : display %7.4f `se_i'
local se_ii  : display %7.4f `se_ii'
local se_iii : display %7.4f `se_iii'
local m      : display %6.3f `m'
local rho    : display %6.3f `rho'

file open t2se using "$root/output/table2_se.tex", write replace
file write t2se "\begin{tabular}{lc}" _n
file write t2se "\toprule" _n
file write t2se "Table II, column (2): grade 5 reading on class size and percent disadvantaged & \\" _n
file write t2se "\midrule" _n
file write t2se "Class size coefficient & `=trim("`b_cs'")' \\" _n
file write t2se "(i) conventional OLS standard error & `=trim("`se_i'")' \\" _n
file write t2se "(ii) standard error clustered by school & `=trim("`se_ii'")' \\" _n
file write t2se "(iii) Moulton-inflated: (i) x sqrt(1 + (m - 1) rho) & `=trim("`se_iii'")' \\" _n
file write t2se "\midrule" _n
file write t2se "m, average classes per school & `=trim("`m'")' \\" _n
file write t2se "rho, intraclass correlation of residuals & `=trim("`rho'")' \\" _n
file write t2se "N & `n_cl' \\" _n
file write t2se "\bottomrule" _n
file write t2se "\end{tabular}" _n
file close t2se

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

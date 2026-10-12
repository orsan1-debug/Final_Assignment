/*=========================================================================*/
*---Tables II to V---*
* Reads output/al_clean.dta (built by 1_clean.do) and produces, in this order:
*    s.1  new variables these tables alone need: c_size2, trend
*    s.2  Table II   OLS, grades 5 and 4                    (Angrist, Table II, p 551)
*    s.3  Table II   three-SE comparison, one column       (what_to_replicate, required small addition)
*    s.4  Table III  reduced forms, full and +/-5 samples   (Angrist, Table III, p 553)
*    s.5  Tables IV and V  2SLS, grade 5 then grade 4      (Angrist, Tables IV-V, pp 554, 556)
* Output: output/table2.csv, table2_se.xlsx, table3_panelA.csv, table3_panelB.csv,
*         table4.csv, table5.csv
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
* Helper programs (add_ymean, add_fsF, record_table_result, export_results) are in
* code/table_helpers.do, which this file runs first.
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

log using "$root/output/5_tables2to5.log", replace text
run "$root/code/table_helpers.do"     // defines the four helper programs used below
use "$root/output/al_clean.dta", clear
tab grade                               // check: 2,049 grade 4, 2,019 grade 5, as left by 1_clean.do


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
* Panel A uses the full sample, panel B the +/-5 discontinuity sample (disc5, from 1_clean.do)
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

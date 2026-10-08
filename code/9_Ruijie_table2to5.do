/*=========================================================================*/
*---Tables II to V---*
* Reads output/al_clean.dta (built by 1_clean.do) and produces, in this order:
*    s.1  new variables these tables alone need: c_size2, trend
*    s.2  Table II   OLS, grades 5 and 4                    (Angrist, Table II, p 551)
*    s.3  Table II   three-SE comparison, one column       (what_to_replicate.txt, required small addition)
*    s.4  Table III  reduced forms, full and +/-5 samples   (Angrist, Table III, p 553)
*    s.5  Tables IV and V  2SLS, grade 5 then grade 4      (Angrist, Tables IV-V, pp 554, 556)
* Output: output/table2.xlsx, table2_se.xlsx, table3.xlsx, table4.xlsx, table5.xlsx
* Log:    output/5_table2to5.log
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
clear all
set more off                 
if "$root" == "" global root "/Users/chenruijie/Desktop/EXC5479/Angrist_Lavy_1999"   // change the root when you want to rerun 
capture log close                       // closes a log if crash run left open
log using "$root/output/5_table2to5.log", replace text

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

etable, estimates(`t2') column(estimates) ///
    mstat(ymean, label("Mean score")) mstat(ysd, label("(s.d.)")) ///
    mstat(rmse, label("Root MSE")) mstat(r2, label("R2")) mstat(N) ///
    keep(classize tipuach c_size) eqrecode(classize = xb avgverb = xb avgmath = xb) varlabel showstars showstarsnote ///
    title("Table II: OLS estimates, 1991 (SEs clustered by school)") ///
    export("$root/output/table2.xlsx", replace)


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
putexcel save

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

etable, estimates(`t3A') column(estimates) ///
    mstat(ymean, label("Mean")) mstat(ysd, label("(s.d.)")) ///
    mstat(rmse, label("Root MSE")) mstat(r2, label("R2")) mstat(N) ///
    keep(fsc tipuach c_size) eqrecode(classize = xb avgverb = xb avgmath = xb) varlabel showstars showstarsnote ///
    title("Table III panel A: reduced forms, full sample (SEs clustered by school)") ///
    export("$root/output/table3.xlsx", sheet(A_full) replace)

etable, estimates(`t3B') column(estimates) ///
    mstat(ymean, label("Mean")) mstat(ysd, label("(s.d.)")) ///
    mstat(rmse, label("Root MSE")) mstat(r2, label("R2")) mstat(N) ///
    keep(fsc tipuach c_size) eqrecode(classize = xb avgverb = xb avgmath = xb) varlabel showstars showstarsnote ///
    title("Table III panel B: reduced forms, +/-5 discontinuity sample (SEs clustered by school)") ///
    export("$root/output/table3.xlsx", sheet(B_disc5) modify)


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

foreach g in 5 4 {
    if `g' == 5 local tab "4"
    if `g' == 5 local rom "IV"
    if `g' == 4 local tab "5"
    if `g' == 4 local rom "V"
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

    etable, estimates(`t`tab'') column(estimates) ///
        mstat(ymean, label("Mean score")) mstat(ysd, label("(s.d.)")) ///
        mstat(rmse, label("Root MSE")) mstat(N) ///
        keep(classize tipuach c_size c_size2 trend) eqrecode(classize = xb avgverb = xb avgmath = xb) varlabel showstars showstarsnote ///
        title("Table `rom': 2SLS estimates, grade `g' (fsc instruments class size; SEs clustered by school)") ///
        export("$root/output/table`tab'.xlsx", replace)
}


/*=========================================================================*/
*--- Close ---*
/*=========================================================================*/
estimates dir                           // log check: every stored column listed
log close

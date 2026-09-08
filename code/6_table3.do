/*=========================================================================*/
*---Table III: Reduced-form estimates for 1991---*
* Class size, reading and math regressed on fsc (paper p. 553). Twelve columns
* per panel: grade 5 then grade 4; class size, reading, math; two specifications
* each: (1) fsc + percent disadvantaged, (2) + enrollment.
* Panel A = full sample, Panel B = +/-5 discontinuity sample (disc5, 1_clean.do).
* Standard errors clustered by school (allowed simplification).
* Output: output/table3_full.tex, output/table3_disc5.tex. Log: output/6_table3.log
*
* Course code (same key as 1_clean.do):
*   gen full = 1 as a sample marker      W1 lab s.8 (generate); loop over sample names OUR CHANGE
*   nested foreach / forvalues           W1 lab s.13; pset_1 3_rct Q6
*   local spec lists, nested `spec`s''   W1 lab s.11; as in 5_table2.do
*   reg y x if ..., vce(cluster schlcode) pset_1 3_rct Q4
*   summarize                            W1 lab s.1
*   estimates store / esttab             pset_1 3_rct Q5; W3 lab Q6 (stats labels, coeflabels)
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/6_table3.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---the regressions: two panels x two grades x three outcomes x two specifications---*
/*=========================================================================*/
gen full = 1                                            // marker for the full sample, so the two
                                                        // panels run through one loop: `smp' == 1
local spec1 fsc tipuach
local spec2 fsc tipuach c_size

foreach smp in full disc5 {
    foreach g in 5 4 {
        summarize classize avgverb avgmath if grade == `g' & `smp' == 1   // "Means (s.d.)" rows (log only)
        foreach y in classize avgverb avgmath {
            forvalues s = 1/2 {
                reg `y' `spec`s'' if grade == `g' & `smp' == 1, vce(cluster schlcode)
                estimates store t3_`smp'_g`g'_`y'_s`s'
            }
        }
    }
}

/*=========================================================================*/
*---export: one table per panel---*
/*=========================================================================*/
foreach smp in full disc5 {
    esttab t3_`smp'_g5_classize_s1 t3_`smp'_g5_classize_s2 ///
           t3_`smp'_g5_avgverb_s1  t3_`smp'_g5_avgverb_s2  ///
           t3_`smp'_g5_avgmath_s1  t3_`smp'_g5_avgmath_s2  ///
           t3_`smp'_g4_classize_s1 t3_`smp'_g4_classize_s2 ///
           t3_`smp'_g4_avgverb_s1  t3_`smp'_g4_avgverb_s2  ///
           t3_`smp'_g4_avgmath_s1  t3_`smp'_g4_avgmath_s2  ///
        using "$root/output/table3_`smp'.tex", replace booktabs ///
        b(%7.3f) se(%7.3f) keep(fsc tipuach c_size) ///
        coeflabels(fsc "fsc" tipuach "Percent disadvantaged" c_size "Enrollment") ///
        stats(rmse r2 N, fmt(2 3 0) labels("Root MSE" "R-squared" "N")) ///
        mtitles("Class size" "Class size" "Reading" "Reading" "Math" "Math" ///
                "Class size" "Class size" "Reading" "Reading" "Math" "Math") ///
        addnotes("Columns 1-6 grade 5, columns 7-12 grade 4. Standard errors clustered by school." ///
                 "fsc = enrollment / [int((enrollment - 1)/40) + 1].")
}
* log check, fsc on class size, full sample: .704 and .542 (grade 5), .772 and .670 (grade 4);
* discontinuity sample: .481 and .346, .625 and .503 (paper p. 553)

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

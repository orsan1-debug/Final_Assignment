/*=========================================================================*/
*---Table III: Reduced-form estimates for 1991 (Angrist, Table III, p 553)---*
* Writes output/table3_full.tex (panel A, full sample) and output/table3_disc5.tex (panel B,
* +/-5 discontinuity sample). Twelve columns per panel: grade 5 then grade 4, class size
* then reading then math, each with (1) fsc + PD, (2) + enrollment (p 553). Log: output/6_table3.log
*
* Reads output/al_clean.dta from 1_clean.do (sample section 3, fsc section 4, disc5 section 5).
* Builds full, a marker for the full sample, used only here
*
* Reduced form: class size and the two scores regressed straight on the instrument fsc. The
* fsc coefficient in the class size columns is the first stage, .54 to .77 (Angrist, p 552).
* Standard errors clustered by school (what_to_replicate allowed simplification)
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
clear all
set more off                            // lets file run w/o manual input when output is long
if "$root" == "" global root "C:/Users/otisr/Documents/ECX5479/Final_Assignment"   // fallback when run alone, 0_master.do sets it for the full run (OUR CHANGE)
capture log close                       // closes a log if crash run left open

*--- dependency: needs output/al_clean.dta from 1_clean.do, built here if missing so this file runs alone (OUR CHANGE)
capture confirm file "$root/output/al_clean.dta"   // _rc is 0 if the file exists (code: capture prefix W3 lab bonus, W4 lab section 0)
if _rc do "$root/code/1_clean.do"                  // runs the cleaning file only when the .dta is not there, before this log opens (code: if _rc W4 lab section 0)

log using "$root/output/6_table3.log", replace text   // $root set once in 0_master.do, edit the path there
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. Sample marker and specifications (Angrist, Table III, p 553)---*
* full is 1 for every class, so the two panels run through one loop over `smp' == 1 with
* disc5 as the second marker (1_clean.do section 5). Spec locals give the two columns
/*=========================================================================*/

gen full = 1                            // full-sample marker, looping over sample names is OUR CHANGE (code: W1 lab section 8 generate)
local spec1 fsc tipuach                 // column (1), fsc and PD (p 553; code: W1 lab section 11 locals)
local spec2 fsc tipuach c_size          // column (2) adds September enrollment (dictionary row 3)


/*=========================================================================*/
*---2. The regressions, two panels (Angrist, Table III, p 553)---*
* Panel A is the full sample, panel B keeps disc5 == 1. reg drops the one grade 5 class
* without a math score, so math N is 2,018 (p 553; 1_clean.do section 2)
/*=========================================================================*/

foreach smp in full disc5 {                         // panel A then panel B (code: W1 lab section 13 foreach)
    foreach g in 5 4 {                              // grade 5 first, as in the paper
        summarize classize avgverb avgmath if grade == `g' & `smp' == 1   // means rows, 29.9 74.4 67.3 and 30.3 72.5 68.9 full sample, 30.8 74.5 67.0 and 31.1 72.5 68.7 +/-5 sample, matches paper (p 553)
        foreach y in classize avgverb avgmath {     // class size, reading, math
            forvalues s = 1/2 {                     // (code: W1 lab section 13 forvalues)
                reg `y' `spec`s'' if grade == `g' & `smp' == 1, vce(cluster schlcode)   // clustered by school, nested `spec`s'' is OUR CHANGE (code: W5 lab Q2 vce(cluster))
                estimates store t3_`smp'_g`g'_`y'_s`s'   // one name per panel and column (code: W5 lab Q2)
            }
        }
    }
}


/*=========================================================================*/
*---3. Export, one table per panel, and checks (Angrist, Table III, p 553)---*
/*=========================================================================*/

foreach smp in full disc5 {                         // (code: W1 lab section 13 foreach)
    esttab t3_`smp'_g5_classize_s1 t3_`smp'_g5_classize_s2 ///   // columns in the paper's order (p 553; code: W2 lab Q12 esttab using)
           t3_`smp'_g5_avgverb_s1  t3_`smp'_g5_avgverb_s2  ///
           t3_`smp'_g5_avgmath_s1  t3_`smp'_g5_avgmath_s2  ///
           t3_`smp'_g4_classize_s1 t3_`smp'_g4_classize_s2 ///
           t3_`smp'_g4_avgverb_s1  t3_`smp'_g4_avgverb_s2  ///
           t3_`smp'_g4_avgmath_s1  t3_`smp'_g4_avgmath_s2  ///
        using "$root/output/table3_`smp'.tex", replace booktabs ///   // one file per panel
        b(%7.3f) se(%7.3f) keep(fsc tipuach c_size) ///   // three decimals as printed (code: W2 lab Q12 b() se(), W4 lab Q1 keep())
        coeflabels(fsc "fsc" tipuach "Percent disadvantaged" c_size "Enrollment") ///   // row names as printed (code: W3 lab Q6 coeflabels)
        stats(rmse r2 N, fmt(2 3 0) labels("Root MSE" "R-squared" "N")) ///   // the table's bottom rows (p 553; code: W3 lab Q6 stats labels), rmse as an esttab stat is OUR CHANGE
        mtitles("Class size" "Class size" "Reading" "Reading" "Math" "Math" ///   // (code: W3 lab Q6 mtitles)
                "Class size" "Class size" "Reading" "Reading" "Math" "Math") ///
        addnotes("Columns 1-6 grade 5, columns 7-12 grade 4. Standard errors clustered by school." ///   // (code: W4 lab Q1 addnotes)
                 "fsc = enrollment / [int((enrollment - 1)/40) + 1].")   // the table's own note (p 553)
}

*--- verification vs Angrist, Table III, p 553 (the regressions above are in the log)
* fsc on class size, full sample .704 .542 grade 5 and .772 .670 grade 4, +/-5 sample .481 .346 and .625 .503, matches paper
* reading and math columns match to three decimals except two grade 5 full-sample cells off by .001 (-.150 here, paper -.149, and -.125 here, paper -.124)
* N 2,019 2,019 2,018 grade 5 and 2,049 grade 4 in panel A, 471 and 415 in panel B, matches paper


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

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
clear all
set more off                            // lets file run w/o manual input when output is long
if "$root" == "" global root "C:/Users/otisr/Documents/ECX5479/Final_Assignment"   // fallback when run alone, 0_master.do sets it for the full run (OUR CHANGE)
capture log close                       // closes a log if crash run left open

*--- dependency: needs output/al_clean.dta from 1_clean.do, built here if missing so this file runs alone (OUR CHANGE)
capture confirm file "$root/output/al_clean.dta"   // _rc is 0 if the file exists (code: capture prefix W3 lab bonus, W4 lab section 0)
if _rc do "$root/code/1_clean.do"                  // runs the cleaning file only when the .dta is not there, before this log opens (code: if _rc W4 lab section 0)

log using "$root/output/3_figure1.log", replace text   // $root set once in 0_master.do, edit the path there
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

/*=========================================================================*/
*---Figure I: Class size by enrollment, actual and Maimonides' rule---*
* Writes output/figure1_grade5.png and output/figure1_grade4.png. Log: output/3_figure1.log
*
* Reads output/al_clean.dta. The sample and fsc both come from 1_clean.do, nothing new is
* built here.
*
* Each panel plots the average actual class size at each enrollment count (solid) against the
* class size the rule predicts (dashed), as in Angrist and Lavy's Figure I. The paper also
* draws horizontal lines at the corners of the rule, we leave those out.
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

log using "$root/output/3_figure1.log", replace text
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade---*
* Shows the rule really drives class size. Actual class size follows fsc and drops sharply
* just past 40, 80 and 120, so fsc moves class size, which the instrument needs to work.
*
* Collapse to one row per enrollment count inside preserve/restore, so the full data is back
* for the next grade. fsc is the same for every class with a given enrollment, so its mean
* is just fsc.
/*=========================================================================*/

foreach g in 5 4 {                                  // grade 5 then grade 4, the paper's order
    preserve
    keep if grade == `g'
    collapse (mean) classize fsc, by(c_size)        // average class size at each enrollment count
    summarize classize fsc c_size
    twoway (line fsc c_size, lpattern(dash)) ///    // the rule dashed, as in the paper
           (line classize c_size), ///              // actual class size solid
        legend(label(1 "Maimonides' rule") label(2 "Actual class size")) ///
        title("Grade `g'") xtitle("Enrollment count") ytitle("Class size") ///   // axis titles as in the paper
        xlabel(0(20)220) ylabel(5(5)40)             // same axes as the paper
    graph export "$root/output/figure1_grade`g'.png", replace
    restore                                         // back to the full two-grade data for the next panel
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close

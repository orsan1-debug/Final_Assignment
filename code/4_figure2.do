/*=========================================================================*/
*---Figure II: Average reading scores and predicted class size by enrollment---*
* Writes output/figure2_grade5.png and output/figure2_grade4.png. Log: output/4_figure2.log
*
* Reads output/al_clean.dta, with the sample and fsc from 1_clean.do. Builds e_bin, the
* midpoint of each ten-pupil enrollment interval, used only here.
*
* Each panel plots average reading score and average fsc by enrollment in intervals of ten,
* scores on the left axis and fsc on the right, as in Angrist and Lavy's Figure II.
* Math is their Figure III, which is optional, so it isn't produced.
*
* The paper averages enrollments 9 to 190 and lumps 160 to 190 into its last point at 165.
* We stop at 169 instead, so every point is one interval of ten and the axis still runs
* 5 to 165. Only the first and last points differ, the first keeps enrollments 5 to 8 and
* the last stops at 169.
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

log using "$root/output/4_figure2.log", replace text
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade---*
* Reading scores move up and down as a mirror image of fsc. Other effects of enrollment
* should be smooth, so this zigzag is the class size effect showing up before any regression.
*
* Keep one grade and enrollment up to 169, bin enrollment into tens, collapse to one row
* per bin, plot, then restore the full data for the next grade.
/*=========================================================================*/

tab grade if c_size > 169                           // classes left out of the figure, the paper lumps 160 to 190 into its last point

foreach g in 5 4 {                                  // grade 5 then grade 4, as in the paper
    preserve
    keep if grade == `g' & c_size <= 169            // intervals up to 160-169, see the header
    gen e_bin = 10 * floor(c_size / 10) + 5         // midpoint of each ten-pupil interval, 5, 15, ..., 165
    collapse (mean) avgverb fsc (count) n=avgverb, by(e_bin)   // averages per interval and how many classes are in each
    list e_bin n avgverb fsc                        // the plotted points, the small first interval is kept so the axis matches the paper
    twoway (connected avgverb e_bin) ///            // scores on the left axis
           (connected fsc e_bin, yaxis(2) lpattern(dash)), ///   // fsc dashed on the right axis, as in the paper
        legend(label(1 "Average reading score") label(2 "Predicted class size (right axis)")) ///
        title("Grade `g'") xtitle("Enrollment count") ///
        ytitle("Average reading score") ytitle("Predicted class size", axis(2)) ///
        xlabel(5(20)165)                            // same axis as the paper
    graph export "$root/output/figure2_grade`g'.png", replace
    restore
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close

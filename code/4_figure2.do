/*=========================================================================*/
*---Figure II: Average reading scores and predicted class size by enrollment (Angrist, Figure II, p 543)---*
* Writes output/figure2_grade5.png (panel a) and output/figure2_grade4.png (panel b).
* Log: output/4_figure2.log
*
* Reads output/al_clean.dta from 1_clean.do (sample section 3, fsc section 4). Builds e_bin,
* the enrollment interval midpoint, used only here
*
* Each panel plots the average reading score and the average fsc by enrollment, in intervals
* of ten plotted at their midpoints, scores on the left axis and fsc on the right (p 543 and
* fn 12, p 544). Math is Figure III, optional (what_to_replicate), not produced
*
* Enrollment range. The paper averages schools with enrollment 9 to 190 and pools 160 to 190
* into the last point at 165 (fn 12, p 544). We keep enrollment up to 169, so every point is one
* interval of ten and the axis still runs 5 to 165 (OUR CHANGE). Only the first and last
* points differ from the paper's rule, the first keeps enrollment 5 to 8, the last stops at 169
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

log using "$root/output/4_figure2.log", replace text   // $root set once in 0_master.do, edit the path there
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. One panel per grade (Angrist, Figure II, p 543)---*
* Keep one grade and enrollment up to 169 (see header), bin enrollment into intervals of ten,
* collapse to one row per interval, plot, then restore the full file for the next grade
* (code: W4 lab Q4c preserve, keep if, floor bin, collapse, restore)
/*=========================================================================*/

tab grade if c_size > 169                           // 53 grade 5, 40 grade 4 left out of the figure, the paper pools 160 to 190 into its last point (fn 12, p 544; code: W1 lab section 8 tab if)

foreach g in 5 4 {                                  // panel a grade 5, panel b grade 4 (p 543; code: W1 lab section 13 foreach)
    preserve                                        // (code: W4 lab Q4c)
    keep if grade == `g' & c_size <= 169            // intervals up to [160,169], see header (fn 12, p 544; code: W1 lab section 8 conditions)
    gen e_bin = 10 * floor(c_size / 10) + 5         // interval midpoint 5, 15, ..., 165 (fn 12, p 544; code: W4 lab Q4c floor bin)
    collapse (mean) avgverb fsc (count) n=avgverb, by(e_bin)   // averages by interval and the classes in each (p 543; code: W4 lab Q4c collapse mean count)
    list e_bin n avgverb fsc                        // 17 rows, 5 to 165, first interval 4 classes grade 5 and 3 grade 4, kept so the axis matches the paper's (p 543; code: W1 lab section 6 list)
    twoway (connected avgverb e_bin) ///            // scores, left axis (code: W4 lab Q11 connected)
           (connected fsc e_bin, yaxis(2) lpattern(dash)), ///   // fsc dashed on the right axis, as the paper (p 543; code: W4 lab Q11 yaxis(2), W4 lab Q4a lpattern(dash))
        legend(label(1 "Average reading score") label(2 "Predicted class size (right axis)")) ///   // (code: W1 lab section 10)
        title("Grade `g'") xtitle("Enrollment count") ///   // (code: W4 lab Q4a)
        ytitle("Average reading score") ytitle("Predicted class size", axis(2)) ///   // (code: W4 lab Q11 ytitle axis(2))
        xlabel(5(20)165)                            // midpoints 5 to 165 as the paper's axis (fn 12, p 544), the numlist form is OUR CHANGE
    graph export "$root/output/figure2_grade`g'.png", replace   // (code: W1 lab section 10)
    restore                                         // (code: W4 lab Q4c)
}


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

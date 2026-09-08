/*=========================================================================*/
*---Figure II: Average reading scores and predicted class size by enrollment---*
* One panel per grade, grade 5 = panel a, grade 4 = panel b (paper p. 543):
* average reading score and average fsc in enrollment intervals of ten,
* scores on the left axis and fsc on the right axis.
* Output: output/figure2_grade5.png, output/figure2_grade4.png, log output/4_figure2.log
*
* Course code (same key as 1_clean.do):
*   use / log / foreach / preserve / keep if / restore   as in 3_figure1.do
*   bin variable with floor()       W4 lab Q4c (gen re74_bin = floor(re74 / 5000) * 5000 + 2500)
*   collapse (mean) (count) n=..    W4 lab Q4c (collapse (mean) mean_re78=re78 (count) n=re78)
*   list                            W1 lab s.7 (list foreign price ... in 1/10)
*   twoway (connected ...) with yaxis(2), ytitle(..., axis(2)), lpattern(dash)
*                                   W4 lab Q11 (connected nobs bw_id, yaxis(2) ...)
*   legend / title / xtitle / xlabel / graph export   as in 3_figure1.do
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/4_figure2.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---one panel per grade---*
/*=========================================================================*/
foreach g in 5 4 {
    preserve
    * the paper plots enrollment 5 to 165, i.e. the intervals up to [160,169];
    * larger schools (58 classes in grade 5, 48 in grade 4) are left out as in the paper
    keep if grade == `g' & c_size <= 169

    * "enrollment intervals of ten" (p. 543), plotted at the midpoint 5, 15, ..., 165
    gen e_bin = 10 * floor(c_size / 10) + 5

    collapse (mean) avgverb fsc (count) n=avgverb, by(e_bin)
    list e_bin n avgverb fsc                    // log check: the first interval holds only 3-4 classes,
                                                // kept so the x-axis matches the paper's (5 to 165)
    twoway (connected avgverb e_bin) ///
           (connected fsc e_bin, yaxis(2) lpattern(dash)), ///
        legend(label(1 "Average reading score") label(2 "Predicted class size (right axis)")) ///
        title("Grade `g'") xtitle("Enrollment count") ///
        ytitle("Average reading score") ytitle("Predicted class size", axis(2)) ///
        xlabel(5(20)165)
    graph export "$root/output/figure2_grade`g'.png", replace
    restore
}

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

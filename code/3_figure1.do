/*=========================================================================*/
*---Figure I: Class size by enrollment count, actual and Maimonides' rule---*
* One panel per grade, grade 5 = panel a, grade 4 = panel b (paper p. 541):
* average actual class size at each enrollment count, with fsc from eq. (1).
* Output: output/figure1_grade5.png, output/figure1_grade4.png, log output/3_figure1.log
*
* Course code (same key as 1_clean.do):
*   use / log                       W1 lab s.1, s.12; pset_1
*   foreach g in 5 4                W1 lab s.13; pset_1 3_rct Q6 (foreach g in 3 4)
*   preserve / keep if / collapse (mean) ... , by() / restore
*                                   W4 lab Q4c (collapse mean_re78 by treat education); pset_1 1_clean Q5
*   twoway (line ...) (line ...)    W4 lab Q4b (twoway line pred_linear education)
*   lpattern(dash)                  W4 lab Q11 (function line, lpattern(dash))
*   legend(label(1 ..) label(2 ..)) W1 lab s.10; pset_1 1_clean Q5
*   title / xtitle / ytitle         pset_1 1_clean Q5
*   xlabel(#(#)#) / ylabel          W4 lab Q4c, Q11; W1 lab s.10
*   graph export ..., replace       W1 lab s.10; pset_1 1_clean Q5
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/3_figure1.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---one panel per grade---*
/*=========================================================================*/
foreach g in 5 4 {
    preserve
    keep if grade == `g'
    collapse (mean) classize fsc, by(c_size)    // mean actual class size at each enrollment count;
                                                // fsc is a function of c_size, so its mean is fsc itself
    summarize classize fsc c_size               // log check: fsc peaks at 40, actual peaks a little above
    twoway (line fsc c_size, lpattern(dash)) ///
           (line classize c_size), ///
        legend(label(1 "Maimonides' rule") label(2 "Actual class size")) ///
        title("Grade `g'") xtitle("Enrollment count") ytitle("Class size") ///
        xlabel(0(20)220) ylabel(5(5)40)
    graph export "$root/output/figure1_grade`g'.png", replace
    restore                                     // back to the full two-grade file for the next panel
}

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

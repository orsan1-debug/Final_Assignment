/*=========================================================================*/
*---Master File---*
* Runs every do file in order, one per exhibit, and each one writes its own log.
* Replicates Tables I to VI and Figures I and II of Angrist and Lavy (1999).
*
* The project folder is read from Stata's working directory, so nobody has to type a path.
* Each do file can also find the folder on its own, so any file runs by itself,
* and each exhibit file rebuilds output/al_clean.dta if it is missing.
* The last step runs figure_check/figure_check.do, which puts our figures and tables next to the paper's.
/*=========================================================================*/

* setup
*
clear all
set more off                            // so long output doesn't pause the run

*--- find the project folder from the working directory, so the path never needs editing
*--- double-clicking 0_master.do opens Stata inside code/, so step up one level
capture confirm file "../code/0_master.do"        // _rc is 0 if we are inside code/
if !_rc cd ..                                     // move up to the project folder
capture confirm file "code/0_master.do"           // _rc is 0 if we are in the project folder
if _rc {
    display as error "Set the working directory to the project folder, the one holding code/ data/ output/, then rerun"
    exit 601                                      // stop here with a clear message instead of failing later
}
global root "`c(pwd)'"                            // set once here, every do file uses it
capture mkdir "$root/output"            // makes output/ if it isn't there yet, log using needs it

*--- delete last run's figures and tables, so the check at the end only passes if this run made them
local exhibits figure1_grade5.png figure1_grade4.png figure2_grade5.png figure2_grade4.png ///
    table1.tex table2.tex table2_se.tex table3_full.tex table3_disc5.tex table4.tex table5.tex table6.tex
foreach f in `exhibits' {
    capture erase "$root/output/`f'"           // capture, so a first run with nothing to delete doesn't stop
}

*--- run in order, one do file per exhibit
do "$root/code/1_clean.do"        // cleans both grades and saves output/al_clean.dta
do "$root/code/2_table1.do"       // Table I    descriptive statistics, full and +/-5 samples
do "$root/code/3_figure1.do"      // Figure I   class size and Maimonides' rule by enrollment
do "$root/code/4_figure2.do"      // Figure II  reading scores and fsc by enrollment interval
do "$root/code/5_table2.do"       // Table II   OLS, plus the three standard error comparison
do "$root/code/6_table3.do"       // Table III  reduced forms, full and +/-5 samples
do "$root/code/7_table4_5.do"     // Tables IV and V  2SLS, grade 5 then grade 4
do "$root/code/8_table6.do"       // Table VI   dummy instruments, +/-5 and +/-3 samples

*--- check every figure and table was produced, next to the paper's
do "$root/figure_check/figure_check.do"   // writes figure_check/figure_check.html

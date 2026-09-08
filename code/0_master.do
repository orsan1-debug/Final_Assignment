/*=========================================================================*/
*---Master File---*
*runs all do files
*Angrist & Lavy (1999), QJE 114(2): replication of Tables I-VI, Figures I-II
*one do file per exhibit in what_to_replicate.txt, each writes its own log
*
* $root is set once here and is the only absolute path in the package (STATA_RULES slides 11, 25).
* Every child also carries a fallback root line, so any file runs alone in a fresh session,
* and every exhibit file builds output/al_clean.dta itself if it is missing (OUR CHANGE)
*
* Sources cited in comments (same key as 1_clean.do):
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
* Anything not lifted from a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup. Course code: W1/W3 lab
*
clear all
set more off                            // lets file run w/o manual input when output is long
global root "C:/Users/otisr/Documents/ECX5479/Final_Assignment"   // edit this line to run the package (STATA_RULES slide 25; code: W3 lab section 0 global path)
capture mkdir "$root/output"            // creates output/ if it is not there, log using stops without it (OUR CHANGE, capture prefix as W3 lab bonus)

*--- run in order, one do file per exhibit, chaining do files is OUR CHANGE
do "$root/code/1_clean.do"        // both grades: fixes, sample rule, fsc, samples, instruments -> output/al_clean.dta
do "$root/code/2_table1.do"       // Table I    descriptive statistics, full and +/-5 samples
do "$root/code/3_figure1.do"      // Figure I   class size and Maimonides' rule by enrollment
do "$root/code/4_figure2.do"      // Figure II  reading scores and fsc by enrollment interval
do "$root/code/5_table2.do"       // Table II   OLS + three-SE comparison (required small addition)
do "$root/code/6_table3.do"       // Table III  reduced forms, full and +/-5 samples
do "$root/code/7_table4_5.do"     // Tables IV and V  2SLS, grade 5 then grade 4 (same code, one loop)
do "$root/code/8_table6.do"       // Table VI   dummy instruments, +/-5 and +/-3 samples

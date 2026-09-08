/*=========================================================================*/
*---Master File---*
*runs all do files
*Angrist & Lavy (1999), QJE 114(2): replication of Tables I-VI, Figures I-II
*one do file per exhibit in what_to_replicate.txt, each writes its own log
/*=========================================================================*/

clear all
set more off

global root "C:/Users/otisr/Documents/ECX5479/final_project"

do "$root/code/1_clean.do"        // both grades: fixes, sample rule, fsc, samples, instruments -> output/al_clean.dta
do "$root/code/2_table1.do"       // Table I    descriptive statistics, full and +/-5 samples
do "$root/code/3_figure1.do"      // Figure I   class size and Maimonides' rule by enrollment
do "$root/code/4_figure2.do"      // Figure II  reading scores and fsc by enrollment interval
do "$root/code/5_table2.do"       // Table II   OLS + three-SE comparison (required small addition)
do "$root/code/6_table3.do"       // Table III  reduced forms, full and +/-5 samples
do "$root/code/7_table4_5.do"     // Tables IV and V  2SLS, grade 5 then grade 4 (same code, one loop)
do "$root/code/8_table6.do"       // Table VI   dummy instruments, +/-5 and +/-3 samples

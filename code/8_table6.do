/*=========================================================================*/
*---Table VI: Dummy-instrument results for discontinuity samples (Angrist, Table VI, p 558)---*
* Writes output/table6.tex, twelve columns: grade 5 then grade 4, reading then math, three
* per block, (a) +/-5 sample with PD, (b) +/-3 sample with PD, (c) +/-3 sample without PD.
* Log: output/8_table6.log
*
* Reads output/al_clean.dta from 1_clean.do (fsc section 4, seg1 to seg3, disc5 and disc3
* section 5). Builds the binary instruments z, z1, z2, z3, used only here
*
* 2SLS with three binary instruments and enrollment controlled only through the two segment
* dummies seg1 seg2 (Table VI notes, p 558; what_to_replicate). The column order per block is
* read off the N row, 471 302 302 (p 558), and the text, which puts the no-PD estimate
* -.45 (.24) in the +/-3 sample (p 560). Standard errors clustered by school (allowed simplification)
*
* Sources cited in comments (same key as 1_clean.do):
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
*    what_to_replicate = the task list on Moodle
*    Week 6 lecture = Module 6 slides, instrumental variables
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

log using "$root/output/8_table6.log", replace text   // $root set once in 0_master.do, edit the path there
use "$root/output/al_clean.dta", clear


/*=========================================================================*/
*---1. The dummy instruments (Angrist, p 559)---*
* z = 1[fsc < 32]: 1 in the upper half of each segment, where enrollment has just crossed a
* multiple of 40 and the rule splits the cohort, 0 in the lower half (p 559)
*
* z fully interacted with the segments gives the paper's three instruments, z1 = 1[41<=e<=45],
* z2 = 1[81<=e<=85], z3 = 1[121<=e<=125], one per cutoff, so the first stage can differ by segment (p 559)
*
* Inside the +/-3 sample the same variables mark [41,43], [81,83], [121,123] and seg1 seg2 mark
* [38,43], [78,83] (pp 557, 559), so no separate definitions are needed (1_clean.do section 5)
/*=========================================================================*/

gen z = (fsc < 32)                      // (p 559; code: W1 lab section 8 generate (weight < 3000))
label variable z "1[fsc < 32]"          // (code: W4 lab section 0)
gen z1 = z * seg1                       // product of two dummies (p 559; code: W5 lab Q1 gen d = ez*post)
gen z2 = z * seg2
gen z3 = z * seg3
count if disc5 == 1 & z1 != inrange(c_size, 41, 45)   // 0, the product equals the p 559 definition (code: W2 lab Q4b count if, W4 lab Q10b inrange)
count if disc5 == 1 & z2 != inrange(c_size, 81, 85)   // 0
count if disc5 == 1 & z3 != inrange(c_size, 121, 125) // 0
tab z if disc5 == 1                                   // z = 1 for 49 percent of the +/-5 sample, about half as the paper says (p 559)


/*=========================================================================*/
*---2. The three specifications per block: sample and controls (Angrist, Table VI, p 558)---*
* Nested `smp`s'' and `ctrl`s'' are OUR CHANGE, as in 7_table4_5.do
/*=========================================================================*/

local smp1  disc5                       // (a) +/-5 sample (1_clean.do section 5; code: W1 lab section 11 locals)
local smp2  disc3                       // (b) +/-3 sample
local smp3  disc3                       // (c) +/-3 sample
local ctrl1 tipuach seg1 seg2           // (a) PD and the two segment dummies, seg3 omitted (Table VI notes, p 558)
local ctrl2 tipuach seg1 seg2           // (b)
local ctrl3 seg1 seg2                   // (c) segment dummies only, the -.45 (.24) column of the text (p 560)


/*=========================================================================*/
*---3. 2SLS with the dummy instruments, export and checks (Angrist, Table VI, p 558)---*
/*=========================================================================*/

foreach g in 5 4 {                                  // grade 5 first, as in the paper (code: W1 lab section 13 foreach)
    foreach y in avgverb avgmath {                  // reading then math
        forvalues s = 1/3 {                         // (code: W1 lab section 13 forvalues)
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) ///   // three instruments, one command for both stages (p 559; Week 6 lecture slide 15)
                if grade == `g' & `smp`s'' == 1, vce(cluster schlcode)   // clustered by school (code: W5 lab Q2 vce(cluster))
            estimates store t6_g`g'_`y'_s`s'        // one name per column (code: W5 lab Q2)
        }
    }
}

esttab t6_g5_avgverb_s1 t6_g5_avgverb_s2 t6_g5_avgverb_s3 ///   // columns in the paper's order (p 558; code: W2 lab Q12 esttab using)
       t6_g5_avgmath_s1 t6_g5_avgmath_s2 t6_g5_avgmath_s3 ///
       t6_g4_avgverb_s1 t6_g4_avgverb_s2 t6_g4_avgverb_s3 ///
       t6_g4_avgmath_s1 t6_g4_avgmath_s2 t6_g4_avgmath_s3 ///
    using "$root/output/table6.tex", replace booktabs ///
    b(%7.3f) se(%7.3f) keep(classize tipuach seg1 seg2) ///   // three decimals as printed (code: W2 lab Q12 b() se(), W4 lab Q1 keep())
    coeflabels(classize "Class size" tipuach "Percent disadvantaged" ///   // row names as printed (code: W3 lab Q6 coeflabels)
               seg1 "Segment 1 (enrollment 36-45)" seg2 "Segment 2 (enrollment 76-85)") ///
    stats(rmse N, fmt(2 0) labels("Root MSE" "N")) ///   // the table's bottom rows (code: W3 lab Q6 stats labels), rmse as an esttab stat is OUR CHANGE
    mtitles("Reading" "Reading" "Reading" "Math" "Math" "Math" ///   // (code: W3 lab Q6 mtitles)
            "Reading" "Reading" "Reading" "Math" "Math" "Math") ///
    addnotes("Columns 1-6 grade 5, 7-12 grade 4. Within each block: +/-5 sample with PD, +/-3 sample with PD, +/-3 sample without PD." ///   // (code: W4 lab Q1 addnotes)
             "2SLS, instruments z1 z2 z3 = 1[fsc below 32] interacted with the enrollment segments; segment 3 is the omitted segment." ///
             "Standard errors clustered by school.")

*--- verification vs Angrist, Table VI, p 558 (the regressions above are in the log)
* class size row -.687 -.588 -.451 -.596 -.395 -.270 grade 5 and -.175 -.234 -.380 .018 -.118 -.247 grade 4, matches paper
* N 471 302 302 per block in grade 5 and 415 265 265 in grade 4, matches paper


/*=========================================================================*/
*---4. Why this is "built from simple comparisons of means" (what_to_replicate; Week 6 lecture slide 12)---*
* With one binary instrument and no controls, IV is the Wald ratio, reduced form over first stage,
* four means and one division (Week 6 lecture slide 12). Segment 1, grade 5 reading, z1 alone
*
* Table VI's estimator is a linear combination of the three segment Wald estimates (Angrist, p 559)
/*=========================================================================*/

bysort z: summarize classize avgverb if grade == 5 & seg1 == 1   // the four means, class size 29.7 vs 23.0 and reading 68.2 vs 73.4 (code: W1 lab section 7 bysort summarize, W5 lab Bonus 1 with if)
reg avgverb  z1 if grade == 5 & seg1 == 1, vce(cluster schlcode)  // reduced form 5.20 points (code: W5 lab Q2)
local rf = _b[z1]                       // (code: W2 lab Q6b _b[] into a local)
reg classize z1 if grade == 5 & seg1 == 1, vce(cluster schlcode)  // first stage -6.69 pupils
local fs = _b[z1]
display _n "Wald estimate, segment 1: " %7.3f `rf' / `fs'      // -.778 (code: W2 lab Q6b display %7.3f, W2 lab Q2 display _n)
ivregress 2sls avgverb (classize = z1) if grade == 5 & seg1 == 1, vce(cluster schlcode)   // -.778 on the 160 classes of segment 1, the same number (Week 6 lecture slide 15)


/*=========================================================================*/
*---Close---*
/*=========================================================================*/
log close                               // close log

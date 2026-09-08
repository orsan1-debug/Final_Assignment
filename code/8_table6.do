/*=========================================================================*/
*---Table VI: Dummy-instrument results for discontinuity samples---*
* 2SLS with the three binary instruments z1 z2 z3 (paper p. 559) and enrollment
* controlled only through the segment dummies seg1 seg2 (segment 3 omitted).
* Twelve columns: grade 5 then grade 4; reading then math; three per block:
* (a) +/-5 sample with PD, (b) +/-3 sample with PD, (c) +/-3 sample without PD
* (layout read off the N row of the paper's table: 471, 302, 302 for grade 5).
* SEs clustered by school. Output: output/table6.tex. Log: output/8_table6.log
*
* Course code (same key as 1_clean.do):
*   gen z = (fsc < 32), gen z1 = z * seg1     W1 lab s.8 (generate light_car = (weight < 3000));
*                                             pset_1 1_clean Q2 (gen male = (gender == "M"))
*   count if with !=, inrange()               W2 lab Q4b; W4 lab Q10b
*   tab ... if                                W1 lab s.8
*   ivregress 2sls y x (d = z1 z2 z3)         Week 6 lecture, "2SLS in Stata" (slide 15)
*   Wald = reduced form / first stage         Week 6 lecture, section 2.2, with reg and _b[] into
*                                             locals as in W2 lab Q6 and 5_table2.do
*   loops, spec locals, estimates store, esttab   as in 6_table3.do and 7_table4_5.do
/*=========================================================================*/
clear all
set more off
capture log close
log using "$root/output/8_table6.log", replace text
use "$root/output/al_clean.dta", clear

/*=========================================================================*/
*---the dummy instruments (paper p. 559)---*
/*=========================================================================*/
* z = 1[fsc < 32]: 1 in the upper half of each segment, where enrollment has just
* crossed a multiple of 40 and the rule splits the cohort; 0 in the lower half
gen z = (fsc < 32)
label variable z "1[fsc < 32]"

* z fully interacted with the segments (seg1-seg3 from 1_clean.do):
* z1 = 1[41<=e<=45], z2 = 1[81<=e<=85], z3 = 1[121<=e<=125]
gen z1 = z * seg1
gen z2 = z * seg2
gen z3 = z * seg3
count if disc5 == 1 & z1 != inrange(c_size, 41, 45)   // 0: the interaction equals the p. 559 definition
count if disc5 == 1 & z2 != inrange(c_size, 81, 85)   // 0
count if disc5 == 1 & z3 != inrange(c_size, 121, 125) // 0
tab z if disc5 == 1                                   // about half of the +/-5 sample has z = 1 (p. 559)
* inside the +/-3 sample the same variables mark [41,43], [81,83], [121,123],
* and seg1 seg2 mark [38,43], [78,83]: no separate definitions needed

/*=========================================================================*/
*---the three specifications per block: sample and controls---*
/*=========================================================================*/
local smp1  disc5
local smp2  disc3
local smp3  disc3
local ctrl1 tipuach seg1 seg2
local ctrl2 tipuach seg1 seg2
local ctrl3 seg1 seg2

/*=========================================================================*/
*---2SLS with the dummy instruments---*
/*=========================================================================*/
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        forvalues s = 1/3 {
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) ///
                if grade == `g' & `smp`s'' == 1, vce(cluster schlcode)
            estimates store t6_g`g'_`y'_s`s'
        }
    }
}

esttab t6_g5_avgverb_s1 t6_g5_avgverb_s2 t6_g5_avgverb_s3 ///
       t6_g5_avgmath_s1 t6_g5_avgmath_s2 t6_g5_avgmath_s3 ///
       t6_g4_avgverb_s1 t6_g4_avgverb_s2 t6_g4_avgverb_s3 ///
       t6_g4_avgmath_s1 t6_g4_avgmath_s2 t6_g4_avgmath_s3 ///
    using "$root/output/table6.tex", replace booktabs ///
    b(%7.3f) se(%7.3f) keep(classize tipuach seg1 seg2) ///
    coeflabels(classize "Class size" tipuach "Percent disadvantaged" ///
               seg1 "Segment 1 (enrollment 36-45)" seg2 "Segment 2 (enrollment 76-85)") ///
    stats(rmse N, fmt(2 0) labels("Root MSE" "N")) ///
    mtitles("Reading" "Reading" "Reading" "Math" "Math" "Math" ///
            "Reading" "Reading" "Reading" "Math" "Math" "Math") ///
    addnotes("Columns 1-6 grade 5, 7-12 grade 4. Within each block: +/-5 sample with PD, +/-3 sample with PD, +/-3 sample without PD." ///
             "2SLS, instruments z1 z2 z3 = 1[fsc below 32] interacted with the enrollment segments; segment 3 is the omitted segment." ///
             "Standard errors clustered by school.")
* log check, class size on grade 5 reading: -.687, -.588, -.451 (paper p. 558)

/*=========================================================================*/
*---why this is "built from simple comparisons of means" (what_to_replicate note)---*
* Week 6 lecture: with one binary instrument and no controls, IV = Wald ratio =
* reduced form / first stage. Segment 1, grade 5 reading, instrument z1 alone:
/*=========================================================================*/
bysort z: summarize classize avgverb if grade == 5 & seg1 == 1   // the four means being compared
reg avgverb  z1 if grade == 5 & seg1 == 1, vce(cluster schlcode)  // reduced form: about 5.2 points
local rf = _b[z1]
reg classize z1 if grade == 5 & seg1 == 1, vce(cluster schlcode)  // first stage: about -6.7 pupils
local fs = _b[z1]
display _n "Wald estimate, segment 1: " %7.3f `rf' / `fs'      // about -.78
ivregress 2sls avgverb (classize = z1) if grade == 5 & seg1 == 1, vce(cluster schlcode)   // same number
* Table VI's estimator is a linear combination of the three segment Wald estimates (paper p. 559)

/*=========================================================================*/
*closing up
/*=========================================================================*/
log close

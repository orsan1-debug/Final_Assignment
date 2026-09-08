/*=========================================================================*/
*---Data Cleaning---*
* Cleans the data for both grades and saves output/al_clean.dta, which every
* table and figure file reads. Log: output/1_clean.log.
* Includes what all tables and figures share:
*    s.1  stack final4 and final5 into one file, one row per class
*    s.2  fix two coding errors in the grade 5 scores (dictionary)
*    s.3  apply the paper's sample rule and drop no-score classes (Angrist, fn 11, p 542)
*    s.3  new: sch_first, tags one class per school so schools can be counted
*    s.4  new: fsc, Maimonides' rule class size, the instrument (Angrist, eq 1, p 540)
*    s.5  new: seg1-seg3 disc5 disc3, the +/-5 and +/-3 samples (Angrist, pp 540, 557-559)
* Anything one table or figure alone needs is built in that file.
*
* Sources cited in comments:
*    Angrist = Angrist & Lavy (1999), item then page
*    dictionary = data/data_dictionary.xlsx, sheet row
*    README = the paper folder's README.txt, data notes
*    code = W1 to W5 lab solution do-files (W1 by section, W2 to W5 by question)
*    STATA_RULES = Week 1 "Project and Code Management" slides
* Anything not lifted from a course file is marked OUR CHANGE.
/*=========================================================================*/

* setup. Course code: W1/W3 lab
*                    
clear all
set more off                            // lets file run w/o manual input when output is long
if "$root" == "" global root "C:/Users/otisr/Documents/ECX5479/Final_Assignment"   // fallback when run alone, 0_master.do sets it for the full run (OUR CHANGE)
capture log close                       // closes a log if crash run left open
log using "$root/output/1_clean.log", replace text   // $root set once in 0_master.do, edit the path there

/*=========================================================================*/
*---1. Load and stack the two grade files---*
* Paper repeats every table for grades 5 and 4 (Angrist, Section I, p 538; Table II, p 551)
* We create one combined file and a loop over grade for tables/figures (STATA_RULES slide 6)
/*=========================================================================*/

*append data (not merge)
use "$root/data/final4.dta", clear
append using "$root/data/final5.dta"    // adds the grade 5 rows (README, W1 lab section 15)
describe                                // log check: 4,088 obs (raw classes), 58 var. 
tab grade                               // 2,059 grade 4, 2,029 grade 5, matches observations (dictionary row 23)
isid grade schlcode classid             // unique key, would stop if any class appears twice (dictionary row 24; W3 lab Q5)

* check sample is Jewish public schools only
tab c_leom, missing                     // all 1, Jewish public schools only, matches paper (p. 538)
tab c_pik, missing                      // 1 secular, 2 religious only: matches paper, nothing to drop (p. 538)


/*=========================================================================*/
*---2. Fix coding errors in the grade 5 scores---*
* Two data errors flagged in the dictionary (final5 sheet):
*   - one class has its reading and math averages recorded as score + 100 (rows 30, 33)
*   - one class has mathsize = 0, so nobody sat the math test, yet avgmath = 0 (row 29)
/*=========================================================================*/

*--- errors
list grade schlcode classid avgverb avgmath mathsize verbsize if avgverb > 100 & !missing(avgverb)   // the +100 class
list grade schlcode classid avgverb avgmath mathsize verbsize if mathsize == 0                        // the untested class


* fix scores: subtract the extra 100
replace avgverb = avgverb - 100 if avgverb > 100 & !missing(avgverb)    
replace avgmath = avgmath - 100 if avgmath > 100 & !missing(avgmath)    // (W3 lab Q3)

* mathsize 0 means no math test sat, so the 0 is not a score: set to missing
count if mathsize == 0                          
replace avgmath = . if mathsize == 0            // sets to missing, (W3 lab Q5)


/*=========================================================================*/
*---3. Sample restrictions (Angrist, fn 11, p 542) and a school tag---*
* Paper keeps classes under 45 pupils and schools with at least 5 enrolled (Angrist, fn 11, p 542)
*
* This stated threshold (c_size >= 5) doesn't match their applied threshold (c_size > 5, AngristLavy_Table2.do line 32),
* which drops the one school at exactly 5. We follow their method, so we drop
* classize >= 45 and c_size <= 5: 2,019 classes and 1,002 schools (Angrist, Table I, p 539)
*
* Classes with no score in either subject are dropped, 4 grade 4 and 5 grade 5,
* same ones the paper could not impute (Angrist, Data Appendix, p 571)
*
* sch_first tags one class per school-grade so schools can be counted (Angrist, Table I, p 539)
/*=========================================================================*/

*--- fn 11 as written (keep c_size >= 5) vs the authors' code (c_size > 5, AngristLavy_Table2.do line 32)
*--- their stated threshold doesnt match method, we follow their method to define our threshold.
*--- only 1 school at 5, isolated from rest of sample, reasonable to follow their applied threshold

count if grade == 5 & classize < 45 & c_size >= 5 & !(missing(avgverb) & missing(avgmath))   // 2020, fn 11 as written
count if grade == 5 & classize < 45 & c_size >  5 & !(missing(avgverb) & missing(avgmath))   // 2019, matches paper sample size


tab c_size if c_size <= 15              // only 1 school at 5, next lowest is 3 schools at 8
summarize c_size, detail                // school at 5 well below the rest: next 8, 1st percentile 14 (W1 lab section 1)


*--- we follow their method
tab grade if classize >= 45             // 6 grade 4, 4 grade 5 (W1 lab section 8)
tab grade if c_size <= 5                // 1 grade 5, the school at exactly 5
drop if classize >= 45 | c_size <= 5    // drops classes on both threshold bounds (W3 lab Q5)


*--- Drop classes with no scores, as in the paper (Angrist, Data Appendix, p 571)
tab grade if missing(avgverb) & missing(avgmath)   // total: 9, 4 in grade 4 and 5 in grade 5, matches paper
drop if missing(avgverb) & missing(avgmath)



*--- NEW VARIABLE sch_first: one class per school gets a 1, so summing it counts schools as Table I does (Angrist, Table I, p 539)
bysort grade schlcode: gen sch_first = (_n == 1)   // _n = row number within school, 1 for the first class (code: W1 lab section 7 + W4 lab Q4)
label variable sch_first "1 for one class per school-grade"   // (W4 lab section 0)

*--- verification  vs Angrist, Table I, p 539 and Table II p 551 (math N)
tab grade                               // classes: 2,049 grade 4, 2,019 grade 5, matches paper
tab grade if sch_first == 1             // schools: 1,013 grade 4, 1,002 grade 5, matches paper
count if grade == 5 & !missing(avgverb) // classes with a reading score: 2,019, matches paper (Angrist, Table II, p 551)
count if grade == 5 & !missing(avgmath) // classes with a math score: 2,018, matches paper; one below reading, the untested class from section 2


/*=========================================================================*/
*---4. Maimonides' rule class size, fsc (Angrist, eq 1, p 540)---*

* New variable: fsc = es / [int((es - 1)/40) + 1]: class size predicted by the rule from September enrollment es.
*              - Used as the instrument for actual class size in Tables III to V         
*
* Following Angrist (p 550)
*   - es is c_size, September enrollment, not the spring count cohsize (dictionary rows 3, 28)
*   - September is set before parents can react to class sizes, so it cannot carry their choices (Angrist, p 550)
/*=========================================================================*/

*--- new variable fsc
gen fsc = c_size / (floor((c_size - 1)/40) + 1)   // floor() is the paper's int() (code: W1 lab section 8, W4 lab Q4c)
* floor() is more flexible and is courses rounding function (rounds down +'s and -'s). Stata's int() only for positives. 
* same result here as no negative class sizes (obviously), floor() matches the paper's definition (Angrist, p 540)

label variable fsc "predicted class size, Maimonides' rule (eq 1)"   // (code: W4 lab section 0)
summarize fsc classize c_size cohsize   // fsc 8 to 40 by construction; class size 30.1 and enrollment 78.0 
                                        //  - sit between the grade means in Angrist, Table I (code: W1 lab section 1)



/*=========================================================================*/
*---5. Discontinuity samples and segment dummies (Angrist, pp 540, 557-559)---*
* Why: class size jumps at enrollment 40, 80, 120, where one more pupil splits the grade. Schools just
* either side of a cutoff have similar enrollment but very different fsc, so which side a school lands on
* is as good as random (Angrist, p 565; Week 4 lecture, slide 1).
*   - Tables III to VI rerun the models on these samples
*   - there is a cost in precision, 471 classes instead of 2,019 in grade 5 (Angrist, Table I, p 539)
*
* New variables
*   - seg1 seg2 seg3 = 1 if enrollment in [36,45], [76,85], [116,125] (Angrist, p 540)
*       - one dummy per cutoff, 40, 80, 120
*   - disc5 = 1 if in any segment, the +/-5 sample (Angrist, p 540, p 557)
*       - keeps only near-cutoff schools for Table I panel B, Table III panel B, Tables IV to VI
*   - disc3 = 1 if enrollment in [38,43], [78,83], [118,123], the +/-3 sample (Angrist, p 559)
*       - same, tighter band, for the +/-3 columns of Table VI
*   - seg1 seg2 double as Table VI's segment dummies (Angrist, p 559)
*       - control for which cutoff a school is at, seg3 omitted
*
* Following the text, not the table header
*   - Table I panel B header says 116-124, the text says [116,125] (Angrist, p 540, p 557)
*   - 125 gives the paper's own 471 and 415 classes, so the header is a typo
*
* sch_first still counts schools inside these samples
*   - c_size is the same for every class in a school (dictionary row 3), so a school is wholly in or out
/*=========================================================================*/

*--- +/-5 sample, one dummy per cutoff then their union
gen seg1 = inrange(c_size, 36, 45)      // cutoff 40 (Angrist, p 540; code: W4 lab Q10b, W1 lab section 8)
gen seg2 = inrange(c_size, 76, 85)      // cutoff 80
gen seg3 = inrange(c_size, 116, 125)    // cutoff 120, 125 as in the text (Angrist, p 540, p 557)
gen disc5 = (seg1 | seg2 | seg3)        // 1 if near any cutoff (code: W5 lab Bonus 5)
label variable disc5 "+/-5 discontinuity sample"   // (code: W4 lab section 0)

*--- +/-3 sample, no segment dummies: Table VI reuses seg1 seg2
gen disc3 = inrange(c_size, 38, 43) | inrange(c_size, 78, 83) | inrange(c_size, 118, 123)   // (Angrist, p 559)
label variable disc3 "+/-3 discontinuity sample"

*--- verification vs Angrist, Table I panel B p 539, Table VI p 558
tab grade disc5                         // 415 grade 4, 471 grade 5, matches paper (code: W1 lab section 8)
tab grade disc3                         // 265 grade 4, 302 grade 5, matches paper
tab grade if disc5 == 1 & sch_first == 1   // schools: 195 grade 4, 224 grade 5, matches paper


/*=========================================================================*/
*--- Close, Save the analysis file, and verify clean---*
* One file every table and figure reads, saved to output/ so data/ stays untouched (STATA_RULES slide 5)
/*=========================================================================*/
isid grade schlcode classid             // cleared: key still unique after the drops (safeguard, errors and stops if not)
describe                                // cleared: as expected, 4,068 obs and 65 variables: 58 raw + 7 new
save "$root/output/al_clean.dta", replace   // save fixed data
log close                               // close log

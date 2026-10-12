/*=========================================================================*/
*---Table VI: dummy-instrument results for discontinuity samples (Angrist, Table VI, pp 558-560)---*
* Writes output/table6.csv. Log: output/6_table6.log
*
* Each grade and subject, three columns:
*   (1) +/-5 sample, PD + segment dummies
*   (2) +/-3 sample, PD + segment dummies
*   (3) +/-3 sample, segment dummies only
* Grade 5 reading (1)-(3), math (4)-(6); grade 4 reading (7)-(9), math (10)-(12)
* No continuous enrollment control: the only enrollment control is seg1, seg2 (Angrist, p 559)
* Instruments z1-z3 = upper half of each segment, i.e. 1[fsc < 32] by segment (Angrist, p 559)
*
* The three binary instruments predict actual class size in the first stage.
* Segment controls allow the outcome level to differ across the three cutoff windows.
* School-clustered standard errors allow errors to be correlated within schools.
* Helpers add_ymean, add_fsF, record_table_result and export_results are in
* code/table_helpers.do, which this file runs first.
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

log using "$root/output/6_table6.log", replace text
run "$root/code/table_helpers.do"     // defines the four helper programs used below
use "$root/output/al_clean.dta", clear

*---1. Check the sample definitions---*

* isid checks that each combination identifies one observation; duplicates or missing IDs cause an error.
* assert checks a condition without changing the data; a failed check stops the do-file.
isid grade schlcode classid                 // each grade-school-class combination must be unique
assert inlist(grade,4,5)                    // every observation must be either grade 4 or grade 5
assert !missing(c_size, classize, schlcode, fsc)   // enrollment, actual size, school ID and predicted size must be observed
assert seg1 == inrange(c_size,36,45)        // check the first +/-5 window around the cutoff of 40
assert seg2 == inrange(c_size,76,85)        // check the second +/-5 window around the cutoff of 80
assert seg3 == inrange(c_size,116,125)      // check the third +/-5 window around the cutoff of 120
assert disc5 == (seg1 | seg2 | seg3)        // disc5 must identify the union of the three windows
assert disc3 == (inrange(c_size,38,43) | inrange(c_size,78,83) | inrange(c_size,118,123))   // check the narrower +/-3 windows
assert disc5 == 1 if disc3 == 1             // every observation in the +/-3 sample must also belong to the +/-5 sample

*---2. Construct and check the three binary instruments---*

* Three instruments: above-cutoff indicator within each segment.
* Reusing them after restricting to disc3 yields [41,43], [81,83], [121,123].
* Each indicator is 1 on the upper side of its own cutoff window and 0 elsewhere.
* Therefore, z1 = 0 alone does not identify the lower side of every window.
* The three instruments and the segment controls together distinguish the relevant comparisons.
gen byte z1 = inrange(c_size,41,45)         // 1 for enrollment 41-45, the upper side of the first window
gen byte z2 = inrange(c_size,81,85)         // 1 for enrollment 81-85, the upper side of the second window
gen byte z3 = inrange(c_size,121,125)       // 1 for enrollment 121-125, the upper side of the third window


tab grade disc5                            // show each grade's counts inside and outside the +/-5 sample
tab grade disc3                            // show each grade's counts inside and outside the +/-3 sample

label variable classize "Class size"        // label the endogenous class-size variable
label variable tipuach  "Percent disadvantaged"   // label the disadvantaged-student control
label variable seg1     "Segment 1 (enrollment 36-45)"   // label the first cutoff-window indicator
label variable seg2     "Segment 2 (enrollment 76-85)"   // label the second cutoff-window indicator

*---3. Define the controls and sample condition for each specification---*

* seg3 is omitted because a constant plus all three segments is collinear.
* Within either estimation sample, seg1 + seg2 + seg3 = 1.
* Keep the constant and include seg1 and seg2; the third segment is the reference group.
local ctrl1 tipuach seg1 seg2               // specification 1: PD and two segment controls
local ctrl2 tipuach seg1 seg2               // specification 2: the same controls, but a narrower sample
local ctrl3 seg1 seg2                       // specification 3: segment controls only, without PD
local smp1 "disc5 == 1"                     // specification 1 uses the +/-5 sample
local smp2 "disc3 == 1"                     // specification 2 uses the +/-3 sample
local smp3 "disc3 == 1"                     // specification 3 also uses the +/-3 sample

*---4. Prepare a temporary file to collect the table results---*

tempname h6                                // create a temporary name for the results-file writing handle
tempfile r6                                // create a temporary file path for the recorded results
postfile `h6' int order str32 row byte column double value using "`r6'", replace   // define four columns: sorting order, statistic name, model number and value
local col = 0                              // initialise the model-column counter; it will run from 1 to 12
local t6 ""                                // start an empty list of stored model names

*---5. Estimate all 12 models in the paper's column order---*

foreach g in 5 4 {
    foreach y in avgverb avgmath {
        forvalues s = 1/3 {                // run the three specifications for the current grade and subject
            local ++col                    // increase the table-column number by one

            * ctrl`s' selects ctrl1, ctrl2 or ctrl3; smp`s' selects the corresponding sample condition.
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) if grade == `g' & `smp`s'', vce(cluster schlcode)

            add_ymean                      // attach the dependent-variable mean and SD for this model's actual estimation sample
            add_fsF                     // joint F of z1 z2 z3, helper from table_helpers.do
            * add_fsF uses the same estimation sample and controls, then restores the original 2SLS results.
            * Its F statistic tests whether all three instrument coefficients are zero in the first stage.

            estimates store t6_g`g'_`y'_`s'   // save the model under a name identifying its grade, subject and specification
            record_table_result `h6' `col' "classize tipuach seg1 seg2"   // record coefficients, SEs and model statistics; absent terms remain missing
            local t6 "`t6' t6_g`g'_`y'_`s'"   // append this model's name to the list, preserving the column order
        }
    }
}

postclose `h6'


*---6. Display and export Table VI---*

* Show the stored models side by side in the Results window and log.
estimates table `t6', keep(classize tipuach seg1 seg2) varlabel b(%9.4f) se(%9.4f) stats(ymean rmse N fs_F)

export_results "`r6'" "$root/output/table6"


log close

* Table V, fourth grade: six specifications for each of reading and math.
* Requires output/al_clean.dta and helper programs from 16_table_helpers.do.
* Paper pp. 555-556; school-clustered SEs allowed by what_to_replicate.txt.
capture log close
log using "$root/output/tables5_6/table5.log", text replace
use "$root/output/al_clean.dta", clear
keep if grade == 4
isid schlcode classid
assert !missing(c_size, classize, schlcode, fsc)
assert abs(fsc - c_size/(floor((c_size-1)/40)+1)) < 0.00001
assert disc5 == (inrange(c_size,36,45) | inrange(c_size,76,85) | inrange(c_size,116,125))

gen double c_size2 = c_size^2/100
* Continuous piecewise trend: slopes match fsc between cutoffs.
* Only defined through 160; larger cohorts leave this specification.
gen double trend = c_size if c_size <= 40
replace trend = 20 + c_size/2 if inrange(c_size,41,80)
replace trend = 100/3 + c_size/3 if inrange(c_size,81,120)
replace trend = 130/3 + c_size/4 if inrange(c_size,121,160)
gen byte full = 1

local ctrl1 tipuach
local ctrl2 tipuach c_size
local ctrl3 tipuach c_size c_size2
local ctrl4 trend
local ctrl5 tipuach
local ctrl6 tipuach c_size
* Specification 4 intentionally omits PD, as in the published table.
local sample1 full
local sample2 full
local sample3 full
local sample4 full
local sample5 disc5
local sample6 disc5

tempname results
tempfile records
postfile `results' int order str32 row byte column double value using "`records'", replace
local column = 0
local models
foreach y in avgverb avgmath {
    forvalues s = 1/6 {
        local ++column
        display "Table V column `column': `y', specification `s'"
        ivregress 2sls `y' `ctrl`s'' (classize = fsc) ///
            if `sample`s'' == 1, vce(cluster schlcode)
        estimates store T5_`column'
        local models `models' T5_`column'
        record_table_result `results' `column' `y' "classize tipuach c_size c_size2 trend"
        gen byte estimation_sample = e(sample)

        * First stage on exactly the same observations and controls as 2SLS.
        * This clustered F tests the excluded instrument, not all regressors.
        regress classize fsc `ctrl`s'' if estimation_sample, vce(cluster schlcode)
        test fsc
        post `results' (94) ("first_stage_F") (`column') (r(F))
        post `results' (95) ("first_stage_p") (`column') (r(p))
        drop estimation_sample
    }
}
postclose `results'
estimates table `models', b(%9.4f) se(%9.4f) stats(N rmse)
export_table_results "`records'" "$root/output/tables5_6/table5.csv"
export_latex_results "`records'" "$root/output/tables5_6/table5.tex"
log close

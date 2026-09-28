* Table VI, fifth then fourth grade; reading then math within each grade.
* Each outcome: (1) +/-5 with PD; (2) +/-3 with PD; (3) +/-3 without PD.
* Paper pp. 558-560. No continuous enrollment controls in this table.
capture log close
log using "$root/output/tables5_6/table6.log", text replace
use "$root/output/al_clean.dta", clear
isid grade schlcode classid
assert inlist(grade,4,5)
assert !missing(c_size, classize, schlcode, fsc)
assert seg1 == inrange(c_size,36,45)
assert seg2 == inrange(c_size,76,85)
assert seg3 == inrange(c_size,116,125)
assert disc5 == (seg1 | seg2 | seg3)
assert disc3 == (inrange(c_size,38,43) | inrange(c_size,78,83) | inrange(c_size,118,123))
assert disc5 == 1 if disc3 == 1

* Three excluded instruments: above-cutoff indicator within each segment.
* Reusing them after restricting to disc3 yields [41,43], [81,83], [121,123].
gen byte z1 = inrange(c_size,41,45)
gen byte z2 = inrange(c_size,81,85)
gen byte z3 = inrange(c_size,121,125)
forvalues j = 1/3 {
    assert z`j' == ((fsc < 32)*seg`j') if disc5 == 1
}
tab grade disc5
tab grade disc3

* seg3 is omitted because a constant plus all three segments is collinear.
local ctrl1 tipuach seg1 seg2
local ctrl2 tipuach seg1 seg2
local ctrl3 seg1 seg2
local sample1 disc5
local sample2 disc3
local sample3 disc3

tempname results
tempfile records
postfile `results' int order str32 row byte column double value using "`records'", replace
local column = 0
local models
foreach g in 5 4 {
    foreach y in avgverb avgmath {
        forvalues s = 1/3 {
            local ++column
            display "Table VI column `column': grade `g', `y', specification `s'"
            ivregress 2sls `y' `ctrl`s'' (classize = z1 z2 z3) ///
                if grade == `g' & `sample`s'' == 1, vce(cluster schlcode)
            estimates store T6_`column'
            local models `models' T6_`column'
            record_table_result `results' `column' `y' "classize tipuach seg1 seg2"
            gen byte estimation_sample = e(sample)
            regress classize z1 z2 z3 `ctrl`s'' if estimation_sample, vce(cluster schlcode)
            test z1 z2 z3
            post `results' (94) ("first_stage_F") (`column') (r(F))
            post `results' (95) ("first_stage_p") (`column') (r(p))
            drop estimation_sample
        }
    }
}
postclose `results'
estimates table `models', b(%9.4f) se(%9.4f) stats(N rmse)
export_table_results "`records'" "$root/output/tables5_6/table6.csv"
export_latex_results "`records'" "$root/output/tables5_6/table6.tex"

* Teaching/QA example, not another column of Table VI:
* One segment, grade 5 reading, +/-5, no PD. IV equals the Wald ratio.
* Use the IV estimation sample for BOTH mean differences.
ivregress 2sls avgverb (classize = z1) ///
    if grade == 5 & seg1 == 1, vce(cluster schlcode)
local iv = _b[classize]
gen byte wald_sample = e(sample)
quietly summarize avgverb if wald_sample & z1 == 1
local y1 = r(mean)
quietly summarize avgverb if wald_sample & z1 == 0
local y0 = r(mean)
quietly summarize classize if wald_sample & z1 == 1
local n1 = r(mean)
quietly summarize classize if wald_sample & z1 == 0
local n0 = r(mean)
assert abs(`n1'-`n0') > 0.00000001
local wald = (`y1'-`y0')/(`n1'-`n0')
display "Reading means (above, below): " `y1' " " `y0'
display "Class-size means (above, below): " `n1' " " `n0'
display "Wald ratio: " %9.6f `wald' "; IV coefficient: " %9.6f `iv'
assert abs(`wald'-`iv') < 0.000001
log close

/*=========================================================================*/
*---Helper programs for Tables II to VI---*
* Defines add_ymean, add_fsF, record_table_result and export_results, used by
* 5_tables2to5.do and 6_table6.do. Each of those files runs this one first, so
* either can run on its own. Built-in Stata commands only.
/*=========================================================================*/


*--- small helper: adds the mean and s.d. of the dependent variable to e()
*--- so the tables can show the paper's "Mean score (s.d.)" row (Angrist, Tables II-V, top row)
*--- computed on the estimation sample, e(sample), so it matches each column's N (OUR CHANGE)
capture program drop add_ymean
program define add_ymean, eclass
    quietly summarize `e(depvar)' if e(sample)
    ereturn scalar ymean = r(mean)
    ereturn scalar ysd   = r(sd)
end

*--- small helper: run right after ivregress, adds the first-stage F to e() (OUR CHANGE)
*   - first stage = class size on the excluded instruments and the same controls,
*     on exactly the 2SLS estimation sample, clustered by school as the 2SLS is
*   - the F tests the excluded instruments only (fsc here, z1-z3 in Table VI), not the controls
*   - the 2SLS results are put back afterwards, so the stored column is still the 2SLS model
capture program drop add_fsF
program define add_fsF, eclass
    local endog `e(instd)'              // class size
    local exog  `e(exogr)'              // included controls
    local insts `e(insts)'              // controls + excluded instruments
    local excl  : list insts - exog     // excluded instruments only
    local clu   `e(clustvar)'
    tempvar es
    tempname iv
    gen byte `es' = e(sample)
    estimates store `iv'
    quietly regress `endog' `excl' `exog' if `es', vce(cluster `clu')
    quietly test `excl'
    local F = r(F)
    local p = r(p)
    quietly estimates restore `iv'
    ereturn scalar fs_F = `F'
    ereturn scalar fs_p = `p'
end

*--- table export helpers, built-in commands only (post, reshape, export delimited, file write)
*   record_table_result: run right after an estimation (and add_ymean / add_fsF), posts that
*     model as one column: b and se of each term, then N, schools, RMSE, mean, s.d., R2, first-stage F
*     terms a model does not have are left missing, so all columns share the same rows
*   export_results: one row per statistic, one column per model, saved as <stub>.csv
*     rows missing in every column (e.g. first-stage F in an OLS table) are dropped
capture program drop record_table_result
program define record_table_result
    args handle column terms
    local k = 0
    foreach term of local terms {
        local ++k
        local b = .
        local se = .
        capture local b = _b[`term']
        capture local se = _se[`term']
        post `handle' (2*`k'-1) ("b_`term'") (`column') (`b')
        post `handle' (2*`k') ("se_`term'") (`column') (`se')
    }
    post `handle' (90) ("N_classes") (`column') (e(N))
    post `handle' (91) ("N_schools") (`column') (e(N_clust))
    post `handle' (92) ("RMSE") (`column') (e(rmse))
    post `handle' (93) ("mean_score") (`column') (e(ymean))
    post `handle' (94) ("sd_score") (`column') (e(ysd))
    post `handle' (95) ("R2") (`column') (e(r2))
    post `handle' (96) ("first_stage_F") (`column') (e(fs_F))
    post `handle' (97) ("first_stage_p") (`column') (e(fs_p))
end

capture program drop export_results
program define export_results
    args source stub
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order
    egen byte n_nonmiss = rownonmiss(value*)
    drop if n_nonmiss == 0
    drop n_nonmiss
    export delimited using "`stub'.csv", replace
    restore
end

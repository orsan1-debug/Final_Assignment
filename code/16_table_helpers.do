* Built-in Stata only. Record each model as a column in a CSV table.
* Call immediately after ivregress, before any other estimation command.
capture program drop record_table_result
program define record_table_result
    args handle column outcome terms
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
    quietly summarize `outcome' if e(sample)
    post `handle' (93) ("mean_score") (`column') (r(mean))
end

capture program drop export_table_results
program define export_table_results
    args source destination
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order
    export delimited using "`destination'", replace
    restore
end

capture program drop export_latex_results
program define export_latex_results
    args source destination
    preserve
    use "`source'", clear
    isid order row column
    reshape wide value, i(order row) j(column)
    sort order
    drop order

    file open texout using "`destination'", write replace text
    file write texout "\begin{tabular}{l*{12}{c}}" _n
    file write texout "\hline" _n
    file write texout " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) & (11) & (12) \\" _n
    file write texout "\hline" _n
    quietly count
    forvalues i = 1/`r(N)' {
        local label = row[`i']
        local label = subinstr("`label'", "_", "\_", .)
        file write texout "`label'"
        forvalues c = 1/12 {
            capture confirm variable value`c'
            if _rc {
                local cell ""
            }
            else if missing(value`c'[`i']) {
                local cell ""
            }
            else {
                local cell : display %9.3f value`c'[`i']
                local cell = trim("`cell'")
            }
            file write texout " & `cell'"
        }
        file write texout " \\" _n
    }
    file write texout "\hline" _n
    file write texout "\end{tabular}" _n
    file close texout
    restore
end

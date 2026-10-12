ECX5479 Empirical Strategies for Policy Evaluation - Final project
Replication of Angrist, J. D. and V. Lavy (1999), "Using Maimonides' Rule to
Estimate the Effect of Class Size on Scholastic Achievement", QJE 114(2),
533-575.
Group: Otis Sandford, Ruijie Chen, Tianlin Yan

HOW TO RUN
1. Open Stata and set the working directory to this folder, the one that
   holds code/, data/ and output/:
       cd "<path to this folder>"
   No path needs editing. Double-clicking code/0_master.do also works.
2. Run the master file:
       do "code/0_master.do"
   It clears the previous run's tables and figures, runs 1_clean.do to
   6_table6.do in order, and writes every log, table and figure to output/.
3. Each numbered do-file can also be run on its own from the same working
   directory. If output/al_clean.dta is missing, it runs 1_clean.do first.

Tested in StataNow 19.5 MP. No user-written packages are needed.

FILES
code/
  0_master.do       runs every numbered file below in order
  1_clean.do        stacks grades 4 and 5, fixes coding errors in the grade 5
                    scores, applies the paper's sample rule (footnote 11),
                    builds predicted class size (fsc) and the +/-5 and +/-3
                    discontinuity samples                -> al_clean.dta
  2_table1.do       Table I                              -> table1.tex
  3_figure1.do      Figure I                             -> figure1_grade5.png
                                                            figure1_grade4.png
  4_figure2.do      Figure II                            -> figure2_grade5.png
                                                            figure2_grade4.png
  5_tables2to5.do   Table II                             -> table2.csv
                    three standard errors, column (2)    -> table2_se.xlsx
                    Table III, panel A (full sample)     -> table3_panelA.csv
                    Table III, panel B (+/-5 sample)     -> table3_panelB.csv
                    Table IV (grade 5)                   -> table4.csv
                    Table V (grade 4)                    -> table5.csv
  6_table6.do       Table VI                             -> table6.csv
  table_helpers.do  helper programs that 5_tables2to5.do and 6_table6.do
                    run first (record each model, export each table)
data/               final4.dta, final5.dta, data_dictionary.xlsx (as
                    provided, not edited)
output/             one log per numbered do-file (1_clean.log to
                    6_table6.log), the tables and figures above, and
                    al_clean.dta

Tables II to VI are written as CSV files with one column per model, in the
paper's column order, and one row per coefficient, standard error and model
statistic.

WHAT_TO_REPLICATE
1. Table I, 4th and 5th grade columns     2_table1.do
2. Figure I, both grades                  3_figure1.do
3. Figure II, both grades                 4_figure2.do
4. Table II                               5_tables2to5.do, section 2
5. Table III                              5_tables2to5.do, section 4
6. Table IV                               5_tables2to5.do, section 5
7. Table V                                5_tables2to5.do, section 5
8. Table VI, +/-5 and +/-3 estimates      6_table6.do
   Required addition, three SEs           5_tables2to5.do, section 3
Optional Table VII and Figures III-IV are not produced.

STANDARD ERRORS
Standard errors are clustered by school throughout, the allowed
simplification in place of the paper's Moulton correction. The one exception
is the required addition in 5_tables2to5.do, section 3. It reports the class
size standard error of Table II column (2) (grade 5 reading on class size and
percent disadvantaged) three ways: conventional OLS, clustered by school, and
the conventional SE inflated by sqrt(1 + (m - 1) rho).

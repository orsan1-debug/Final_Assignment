Final project - README
ECX5479 Empirical Strategies for Policy Evaluation
Angrist, J. D. and V. Lavy (1999), "Using Maimonides' Rule to Estimate the
Effect of Class Size on Scholastic Achievement", QJE 114(2), 533-575.
Group: [names, student IDs]

REPLICATION
1. Edit one line: the global root path at the top of code/0_master.do
   (currently "C:/Users/otisr/Documents/ECX5479/final_project").
2. Run code/0_master.do. It runs 1_clean.do to 8_table6.do in order and
   exports results into output/ (logs, .tex tables, .png figures, .dta).
   Each exhibit file reads output/al_clean.dta, so after 1_clean.do has
   run once, any exhibit file can also be run on its own.

REQUIRED PACKAGES
ssc install estout    (for esttab)
Everything else is built-in Stata (ivregress 2sls, loneway).

STRUCTURE
code/    0_master.do
         1_clean.do     both grades stacked, score fixes, sample rule (paper fn. 11),
                        school tag, fsc, +/-5 and +/-3 samples  -> al_clean.dta
         2_table1.do    Table I           -> table1.tex
         3_figure1.do   Figure I          -> figure1_grade5.png, figure1_grade4.png
         4_figure2.do   Figure II         -> figure2_grade5.png, figure2_grade4.png
         5_table2.do    Table II          -> table2.tex
                        + required three-SE comparison, Table II column (2)
                          (grade 5 reading, class size and PD) -> table2_se.tex
         6_table3.do    Table III         -> table3_full.tex (panel A), table3_disc5.tex (panel B)
         7_table4_5.do  Tables IV and V   -> table4.tex (grade 5), table5.tex (grade 4)
         8_table6.do    Table VI          -> table6.tex
data/    final4.dta, final5.dta, data_dictionary.xlsx (as provided, never edited)
output/  logs 1_clean.log ... 8_table6.log and the files listed above

WHAT_TO_REPLICATE CHECKLIST
1. Table I, 4th and 5th grade columns      2_table1.do
2. Figure I, both grades                   3_figure1.do
3. Figure II, both grades                  4_figure2.do
4. Table II                                5_table2.do
5. Table III                               6_table3.do
6. Table IV (final5)                       7_table4_5.do
7. Table V (final4)                        7_table4_5.do
8. Table VI, +/-5 and +/-3 estimates       8_table6.do
   Required small addition (three SEs)     5_table2.do, second block
   Optional Table VII, Figures III-IV      not produced

CONVENTIONS
- Standard errors clustered by school throughout (allowed simplification);
  the only exception is the three-SE block in 5_table2.do.
- Every data decision is written as a comment where it is taken
  (1_clean.do sections 2-3 for the sample, each exhibit file for its own
  variables), with the paper page or data-dictionary entry it rests on.
- Every section carries a "Course code:" note naming the lab file, section
  or lecture slide the commands come from; the few departures are marked
  OUR CHANGE. Key: W1-W4 lab = the Week 1-4 lab solution do-files,
  pset_1 = our Problem Set 1 code.
- "log check" comments give the numbers the log should show, mostly the
  paper's own; where our numbers differ from the published table the
  comment says so and why.

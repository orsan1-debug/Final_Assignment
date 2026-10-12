Final project - README
ECX5479 Empirical Strategies for Policy Evaluation
Angrist, J. D. and V. Lavy (1999), "Using Maimonides' Rule to Estimate the
Effect of Class Size on Scholastic Achievement", QJE 114(2), 533-575.
Group: [names, student IDs]

REPLICATION
1. Set Stata's working directory to this folder (the one holding code/,
   data/, output/):  cd "<path to this folder>"  or File > Change Working
   Directory. No path is typed anywhere in the package: 0_master.do reads
   the project folder from the working directory. Opening code/0_master.do
   by double-click does this for you, Stata then starts in code/ and the
   master steps up one level. From any other folder the master stops with
   a message saying to cd here.
2. Run code/0_master.do (do "code/0_master.do"). It creates output/ if
   needed, then runs 1_clean.do to 8_table6.do in order and exports results
   into output/ (logs, .tex tables, .png figures, al_clean.dta). Each do-file
   writes its own log.
3. Any do-file also runs on its own in a fresh Stata session, from the same
   working directory. Its fallback block sets $root when the master has not,
   and every exhibit file checks for output/al_clean.dta and runs 1_clean.do
   first if it is missing. All exhibit files read that one cleaned file,
   which only 1_clean.do builds.

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
         (created by 0_master.do if it does not exist)

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
- Every data decision is written as a comment where it is taken, with the
  paper page, data-dictionary row or authors' do-file line it rests on.
  1_clean.do sections 2 to 5 hold the score fixes, the sample rule, fsc and
  the discontinuity samples. Each exhibit file builds only what it alone
  needs and points back to the 1_clean.do section for the rest.
- Every command a marker could ask about carries a comment at the end of
  its line saying what it does and why, with the paper page, dictionary row
  or task-list item it rests on in one bracket. Steps and choices that are
  our own, not the paper's, are marked OUR CHANGE. The header of every file
  carries the same key.

ECX5479 - EMPIRICAL STRATEGIES FOR POLICY EVALUATION
FINAL PROJECT - REPLICATION PACKAGES
=========================================================================

This package contains everything your group needs to do the replication
part of the final project.

There are twelve papers. Each has its own folder, and each folder is
posted on Moodle as a separate zip file. YOU ONLY NEED THE ZIP FOR THE
PAPER YOUR GROUP IS ASSIGNED. Do not download the others - some of them
are large.

Before papers are assigned, download only the small file
"all_papers_for_ranking.zip". It holds the twelve papers and their task
lists, without the data, and is what you need in order to rank the
papers (see "What happens when" below).


-------------------------------------------------------------------------
WHAT IS IN EACH PAPER FOLDER
-------------------------------------------------------------------------

  PROJECT_README.txt      A copy of this file, so that the zip you
                          download is self-contained.

  README.txt              Read this first. It lists every file in the
                          folder, says which software and which add-on
                          packages you need, and gives the data notes
                          specific to that paper.

  what_to_replicate.txt   The task list: exactly which figures and
                          tables your code must produce, from which
                          data files, which simplifications are
                          allowed, and what is explicitly NOT required.
                          This document defines your coding task. If an
                          exhibit is not on it, you do not have to
                          produce it.

  paper.pdf               The published article.

  data/                   The data files, plus data_dictionary.xlsx -
                          a variable dictionary with one sheet per data
                          file and a sheet documenting how the files
                          link together (the merge keys). Read the
                          dictionary before you write any code.

Some folders also contain an online appendix, a corrigendum, or the
authors' own readme. The folder's README.txt lists them.


-------------------------------------------------------------------------
WHAT HAPPENS WHEN
-------------------------------------------------------------------------

  Thu 13/08     Email me your group's members (or tell me you have no
                group and I will place you in one).

  Tue 18/08     Come to class with your group and your ranked list of
                all twelve papers, number 1 being the paper you would
                most like to work on. Groups draw a random order and
                pick in that order; each group gets the highest paper
                on its list that is still free. No two groups work on
                the same paper. Rank the full list - your group may not
                get its first choice.

  Mon 12/10     Hand in, on Moodle: your slides and your code. No
                written report. Late work loses 25%; nothing is
                accepted after 9am on Tue 13/10.

  13/10 - 22/10 Presentations in class (four dates). You present the
                PAPER, using the paper's own figures and tables. Do not
                put any output of your own code in your slides.

  13/10 - 23/10 Code sessions on Zoom, 15 minutes per group (20 for a
                group of three), booked through a Moodle sign-up sheet.
                We simply read the code you submitted; I choose which
                lines we look at, and every group member is questioned.


-------------------------------------------------------------------------
HOW YOUR CODE IS JUDGED
-------------------------------------------------------------------------

Read this carefully - it is the point most groups get wrong.

DO NOT AIM TO REPRODUCE THE PAPER'S EXACT NUMBERS. The published
numbers are a benchmark, not a target. You will not lose points because
your results differ from the paper's, and you are not asked to explain
why they differ.

Where the data leave several reasonable ways to proceed - which sample
to keep, how to define a variable, which command to use - any decision
is fine as long as the justification is sound. WRITE THAT JUSTIFICATION
AS A COMMENT IN YOUR CODE, and be ready to defend it in the code
session. What costs points is a coding mistake, not a defensible
decision.

For several papers, part of the job is building the working dataset
yourselves from raw source files: importing, cleaning, merging, and
constructing variables. Where your task list asks for this, the choices
are yours to make - document each one as a comment.

Your code must run and produce every exhibit on your paper's task list,
and it must be clean and well organised.


-------------------------------------------------------------------------
SOFTWARE
-------------------------------------------------------------------------

Stata is expected. Contact me if your group would prefer to use another
package. Where a paper needs a user-written (SSC) command or a
particular amount of memory, its own README.txt says so.


-------------------------------------------------------------------------
RULES
-------------------------------------------------------------------------

The code you hand in must be written by your group. Collaboration is
within your group only - not with other groups. Slides and code are run
through a similarity-detection system that compares them with online
sources, published work, the authors' own code, and other students'
submissions, past and present.

Where the authors published a replication package of their own, it is
on Moodle as a separate zip, named after the paper and ending in
"_authors_code" - for example Card_Krueger_1994_authors_code.zip.
Eleven of the twelve papers have one; Nunn is the exception, as nothing
was ever deposited for it.

Those zips are there for reference only. You are not expected to look
at them, nothing on your task list requires them, and they are not
meant to be run - most of that code reads files you do not have. If you
do open one, read the READ_ME_FIRST.txt inside it. Either way, the code
you submit must be yours, and you must be able to defend it line by
line in the code session, which is much harder to do with code you did
not write.

You may use AI to help you understand the paper, build your slides and
write your code. You may NOT use AI during the presentation or during
the code session - no AI window open, no prompting between questions.
You must understand every line of code you submit.


-------------------------------------------------------------------------

The full project description on Moodle is the authoritative document
for deadlines, grading and rules. This README summarises it; where the
two differ, the Moodle description wins.

Questions about a data file, a variable, or what an exhibit asks for:
email me. Do not spend a week stuck on something a one-line answer
would fix.

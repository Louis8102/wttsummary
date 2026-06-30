clear all
set more off

* Example using a wtttable results() dataset.
* In your own project, replace example_results.dta with your results() file.

wttsummary using "example_results.dta", ///
    saving("summary.docx") ///
    summarydata("block_summary.dta") ///
    style(brief) replace

wttsummary using "example_results.dta", ///
    saving("summary_academic.docx") ///
    style(academic) top(10) replace

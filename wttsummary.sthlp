{smcl}
{* *! version 0.2.9  30jun2026}{...}
{vieweralsosee "wtttable" "help wtttable"}{...}
{vieweralsosee "wttplot" "help wttplot"}{...}

{title:Title}

{phang}
{bf:wttsummary} {hline 2} brief and academic summaries for {cmd:wtttable} results datasets

{title:Syntax}

{p 8 17 2}
{cmd:wttsummary using} {it:results.dta}{cmd:,}
{opt saving(filename)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt saving(filename)}}save the summary as {cmd:.docx}, {cmd:.txt}, or {cmd:.md}{p_end}
{synopt:{opt summarydata(filename)}}save a block-level summary dataset{p_end}
{synopt:{opt style(brief|academic)}}select the writing style; default is {cmd:brief}{p_end}
{synopt:{opt top(#)}}number of largest FDR-significant effects to mention in {cmd:style(academic)}; default is {cmd:top(5)}{p_end}
{synopt:{opt alpha(#)}}FDR q-value threshold; default is {cmd:alpha(.05)}{p_end}
{synopt:{opt rq(string)}}supply a custom research question paragraph{p_end}
{synopt:{opt hypothesis(string)}}add a hypothesis paragraph{p_end}
{synopt:{opt implication(string)}}add an implication paragraph{p_end}
{synopt:{opt replace}}overwrite existing files{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:wttsummary} reads a {cmd:results()} dataset produced by {cmd:wtttable}
and writes a conservative summary of Welch independent-samples t-test results.
It does not rerun Welch tests.  The summary emphasizes group sample sizes,
the number of FDR-significant outcomes, block/subscale-level patterns,
direction of significant differences, signed Hedges' {it:g_av} ranges, and
the largest effects by absolute magnitude.

{pstd}
The command is intentionally conservative: it describes item-level patterns
and does not infer that an entire scale or domain differs unless scale-level
scores were analyzed directly.

{pstd}
The default brief report includes three parts: research questions, methods,
and key findings.  The brief style emphasizes the overall number of
FDR-significant outcomes, the block-level distribution of reliable differences,
and a pointer to Appendix A.  The academic style adds direction counts and
the largest signed Hedges' {it:g_av} effects by absolute magnitude.

{pstd}
The command is designed to adapt to different result patterns.  It handles
cases with no FDR-significant outcomes, some FDR-significant outcomes, all
outcomes FDR-significant, blocks with no significant outcomes, blocks with
some or all outcomes significant, positive and negative effect sizes, and
one-sided direction patterns.  Missing q-values are treated as not
FDR-significant and generate a warning.  Missing Hedges' {it:g_av} values are
excluded from effect-size summaries and generate a warning.  If all effect
sizes are missing, effect-size ranges and largest effects are reported as
unavailable rather than blank.

{pstd}
{cmd:wttsummary} expects a current {cmd:wtttable} results dataset with block
metadata.  If required variables are missing, the command stops with an error
instead of guessing the structure of the results.

{pstd}
The original dataset may contain more than one two-category grouping variable
such as gender, pass/fail status, or treatment/control status.  This is not a
problem, but each {cmd:wttsummary} report corresponds to one {cmd:wtttable}
analysis and one saved results dataset.  Run {cmd:wtttable} separately for each
grouping variable and save each results dataset under a distinct name.

{title:Options}

{phang}
{opt saving(filename)} specifies the output summary file.  Supported extensions
are {cmd:.docx}, {cmd:.txt}, and {cmd:.md}.

{phang}
{opt summarydata(filename)} saves the block-level summary dataset used to
generate the narrative.

{phang}
{opt style()} controls the prose style.  {cmd:brief} is compact and designed
for research briefs or project reports.  {cmd:academic} includes more method
and direction detail for manuscripts, technical reports, or appendices.

{phang}
{opt top(#)} controls how many of the largest FDR-significant effects are mentioned in the academic narrative. In {cmd:style(brief)}, the report remains deliberately concise and points readers to Appendix A instead of listing top effects.

{phang}
{opt rq(string)} replaces the default three-part research-question text with
user-supplied text.

{phang}
{opt hypothesis(string)} adds a hypothesis paragraph after the research
question section.

{phang}
{opt implication(string)} adds an implication paragraph before Appendix A.

{title:Example}

{phang2}{cmd:. net get wttsummary, from("https://raw.githubusercontent.com/Louis8102/wttsummary/main/") replace}{p_end}
{phang2}{cmd:. wttsummary using example_results.dta, saving(summary.docx) summarydata(block_summary.dta) style(brief) replace}{p_end}
{phang2}{cmd:. wttsummary using example_results.dta, saving(summary_academic.docx) style(academic) top(10) replace}{p_end}

{pstd}
Typical workflow after running {cmd:wtttable}:

{phang2}{cmd:. wtttable item1-item60, by(gender) blockfromchar saving(table1.docx) results(wtt_results.dta) replace}{p_end}
{phang2}{cmd:. wttsummary using wtt_results.dta, saving(summary.docx) replace}{p_end}

{pstd}
If several two-category grouping variables are analyzed, save separate results
files:

{phang2}{cmd:. wtttable item1-item60, by(gender) blockfromchar saving(gender_table.docx) results(gender_results.dta) replace}{p_end}
{phang2}{cmd:. wttsummary using gender_results.dta, saving(gender_summary.docx) replace}{p_end}
{phang2}{cmd:. wtttable item1-item60, by(pass) blockfromchar saving(pass_table.docx) results(pass_results.dta) replace}{p_end}
{phang2}{cmd:. wttsummary using pass_results.dta, saving(pass_summary.docx) replace}{p_end}

{title:Selected methodological references}

{pstd}
Appelbaum, M., Cooper, H., Kline, R. B., Mayo-Wilson, E., Nezu, A. M., and Rao, S. M. (2018).
Journal article reporting standards for quantitative research in psychology: The APA Publications
and Communications Board task force report. {it:American Psychologist, 73}(1), 3-25.

{pstd}
Benjamini, Y., and Hochberg, Y. (1995). Controlling the false discovery rate: A practical and
powerful approach to multiple testing. {it:Journal of the Royal Statistical Society: Series B, 57}(1), 289-300.

{pstd}
Cumming, G. (2014). The new statistics: Why and how. {it:Psychological Science, 25}(1), 7-29.

{pstd}
Delacre, M., Lakens, D., and Leys, C. (2017). Why psychologists should by default use Welch's
t-test instead of Student's t-test. {it:International Review of Social Psychology, 30}(1), 92-101.

{pstd}
Lakens, D. (2013). Calculating and reporting effect sizes to facilitate cumulative science.
{it:Frontiers in Psychology, 4}, 863.

{pstd}
Welch, B. L. (1947). The generalization of Student's problem when several different population
variances are involved. {it:Biometrika, 34}(1/2), 28-35.

{pstd}
Wilkinson, L., and the Task Force on Statistical Inference. (1999). Statistical methods in
psychology journals: Guidelines and explanations. {it:American Psychologist, 54}(8), 594-604.

{title:Author}

{pstd}
Hao Ma


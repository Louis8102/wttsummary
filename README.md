# wttsummary

`wttsummary` creates conservative brief-style and academic-style summaries from `wtttable` results datasets.

It is designed to work as the narrative component of a Welch independent-samples t-test reporting workflow:

```stata
wtttable   // APA Word table
wttplot    // effect-size figures
wttsummary // narrative results summary
```

Install from GitHub:

```stata
net install wttsummary, from("https://raw.githubusercontent.com/Louis8102/wttsummary/main/") replace
```

Example with the included results dataset:

```stata
net get wttsummary, from("https://raw.githubusercontent.com/Louis8102/wttsummary/main/") replace

wttsummary using example_results.dta, ///
    saving(summary.docx) summarydata(block_summary.dta) ///
    style(brief) replace

wttsummary using example_results.dta, ///
    saving(summary_academic.docx) ///
    style(academic) top(10) replace
```

Typical workflow:

```stata
wtttable item1-item60, by(gender) blockfromchar ///
    saving(table1.docx) results(wtt_results.dta) replace

wttsummary using wtt_results.dta, saving(summary.docx) replace
```

If the original dataset contains several two-category grouping variables, run
the table and summary workflow separately for each grouping variable and keep
separate results files:

```stata
wtttable item1-item60, by(gender) blockfromchar ///
    saving(gender_table.docx) results(gender_results.dta) replace
wttsummary using gender_results.dta, saving(gender_summary.docx) replace

wtttable item1-item60, by(pass) blockfromchar ///
    saving(pass_table.docx) results(pass_results.dta) replace
wttsummary using pass_results.dta, saving(pass_summary.docx) replace
```

`wttsummary` does not rerun t tests. It reads the saved results from `wtttable`, reports group sample sizes, summarizes the number of FDR-significant outcomes, identifies block-level patterns, describes direction of effects, and lists the largest signed Hedges' `g_av` effects by absolute magnitude.

The generated text is intentionally conservative. It describes item-level patterns and does not infer that an entire scale or domain differs unless scale-level scores were analyzed directly.

`wttsummary` adapts to common result patterns, including no FDR-significant
outcomes, all outcomes FDR-significant, blocks with no significant outcomes,
blocks with partial or complete significance, positive or negative effect
sizes, one-sided direction patterns, missing q values, missing Hedges'
`g_av` values, and varied group sizes across outcomes. Missing q values are
treated as not FDR-significant and reported with a warning; missing effect
sizes are excluded from effect-size summaries and reported with a warning.

## Selected methodological references

- Appelbaum, M., Cooper, H., Kline, R. B., Mayo-Wilson, E., Nezu, A. M., & Rao, S. M. (2018). Journal article reporting standards for quantitative research in psychology: The APA Publications and Communications Board task force report. *American Psychologist, 73*(1), 3-25.
- Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate: A practical and powerful approach to multiple testing. *Journal of the Royal Statistical Society: Series B, 57*(1), 289-300.
- Cumming, G. (2014). The new statistics: Why and how. *Psychological Science, 25*(1), 7-29.
- Delacre, M., Lakens, D., & Leys, C. (2017). Why psychologists should by default use Welch's t-test instead of Student's t-test. *International Review of Social Psychology, 30*(1), 92-101.
- Lakens, D. (2013). Calculating and reporting effect sizes to facilitate cumulative science. *Frontiers in Psychology, 4*, 863.
- Welch, B. L. (1947). The generalization of Student's problem when several different population variances are involved. *Biometrika, 34*(1/2), 28-35.
- Wilkinson, L., & the Task Force on Statistical Inference. (1999). Statistical methods in psychology journals: Guidelines and explanations. *American Psychologist, 54*(8), 594-604.

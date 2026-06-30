*! version 0.2.9-preview  30jun2026
program define wttsummary, rclass
    version 19.5

    syntax using/, SAVING(string) ///
        [ SUMMARYDATA(string) STYLE(string) TOP(integer 5) ALPHA(real 0.05) ///
          REPLACE ESIZEWORDS TITLE(string) RQ(string) HYPOTHESIS(string) ///
          IMPLICATION(string) ]

    if `alpha' <= 0 | `alpha' >= 1 {
        di as err "alpha() must be strictly between 0 and 1"
        exit 198
    }
    if `top' < 0 {
        di as err "top() must be 0 or a positive integer"
        exit 198
    }

    local style = lower(strtrim(`"`style'"'))
    if `"`style'"' == "" local style "brief"
    if !inlist(`"`style'"', "brief", "academic") {
        di as err "style() must be brief or academic"
        exit 198
    }
    local default_title = (`"`title'"' == "")
    if `"`title'"' == "" local title "Welch Independent-Samples t-Test Analysis Summary"

    local saving_l = lower(`"`saving'"')
    local slen = strlen(`"`saving_l'"')
    local ext = substr(`"`saving_l'"', max(1, `slen' - 4), 5)
    local ext4 = substr(`"`saving_l'"', max(1, `slen' - 3), 4)
    if !inlist(`"`ext'"', ".docx") & !inlist(`"`ext4'"', ".txt", ".md") {
        di as err "saving() must end in .docx, .txt, or .md"
        exit 198
    }
    capture confirm new file `"`saving'"'
    if _rc & `"`replace'"' == "" {
        di as err `"file `saving' already exists; specify replace"'
        exit 602
    }
    if `"`summarydata'"' != "" {
        capture confirm new file `"`summarydata'"'
        if _rc & `"`replace'"' == "" {
            di as err `"file `summarydata' already exists; specify replace"'
            exit 602
        }
    }

    preserve
        quietly use `"`using'"', clear

        foreach needed in variable rowlabel mean1 mean2 p q gav n1 n2 blockid blocklabel {
            capture confirm variable `needed'
            if _rc {
                di as err `"results file is missing required variable `needed'"'
                di as err "Use a results() dataset produced by the current version of wtttable."
                restore
                exit 198
            }
        }

        capture confirm variable item_no
        if _rc quietly generate long item_no = _n
        capture confirm numeric variable q
        if _rc {
            di as err "q must be numeric in the results dataset"
            restore
            exit 198
        }
        capture confirm numeric variable gav
        if _rc {
            di as err "gav must be numeric in the results dataset"
            restore
            exit 198
        }
        capture confirm numeric variable n1
        if _rc {
            di as err "n1 must be numeric in the results dataset"
            restore
            exit 198
        }
        capture confirm numeric variable n2
        if _rc {
            di as err "n2 must be numeric in the results dataset"
            restore
            exit 198
        }

        local warn_group ""
        capture confirm variable group1
        if !_rc {
            quietly levelsof group1, local(g1levels) clean
            local g1nlevels : word count `g1levels'
            if `g1nlevels' > 1 local warn_group `"group1 contains more than one value in the results dataset; the first value was used in the summary."'
            quietly levelsof group1 in 1, local(g1name) clean
        }
        else {
            local g1name "G1"
            local warn_group `"group labels were not found; G1 and G2 were used."'
        }
        capture confirm variable group2
        if !_rc {
            quietly levelsof group2, local(g2levels) clean
            local g2nlevels : word count `g2levels'
            if `g2nlevels' > 1 local warn_group `"group2 contains more than one value in the results dataset; the first value was used in the summary."'
            quietly levelsof group2 in 1, local(g2name) clean
        }
        else {
            local g2name "G2"
            local warn_group `"group labels were not found; G1 and G2 were used."'
        }
        if `"`g1name'"' == "" local g1name "G1"
        if `"`g2name'"' == "" local g2name "G2"

        quietly count
        local nout = r(N)
        if `nout' == 0 {
            di as err "results file has no observations"
            restore
            exit 2000
        }
        quietly count if missing(q)
        local nmissq = r(N)
        if `nmissq' == `nout' {
            di as err "all q-values are missing; wttsummary cannot identify FDR-significant outcomes"
            restore
            exit 459
        }
        quietly count if missing(gav)
        local nmissgav = r(N)
        local warn_q ""
        if `nmissq' > 0 local warn_q `"`nmissq' q-values were missing and were treated as not FDR-significant."'
        local warn_gav ""
        if `nmissgav' > 0 local warn_gav `"`nmissgav' Hedges' g_av values were missing; effect-size summaries exclude those missing values."'
        if `nmissgav' == `nout' local warn_gav `"all Hedges' g_av values were missing; effect-size ranges and largest effects are reported as unavailable."'
        quietly count if missing(n1) | missing(n2)
        local nmissn = r(N)
        if `nmissn' > 0 {
            di as err "n1 and n2 must be nonmissing for every outcome"
            restore
            exit 459
        }

        quietly summarize n1, meanonly
        local n1min = r(min)
        local n1max = r(max)
        quietly summarize n2, meanonly
        local n2min = r(min)
        local n2max = r(max)
        local n1min_s : display %9.0f `n1min'
        local n1max_s : display %9.0f `n1max'
        local n2min_s : display %9.0f `n2min'
        local n2max_s : display %9.0f `n2max'
        local n1min_s = strtrim(`"`n1min_s'"')
        local n1max_s = strtrim(`"`n1max_s'"')
        local n2min_s = strtrim(`"`n2min_s'"')
        local n2max_s = strtrim(`"`n2max_s'"')
        if `n1min' == `n1max' & `n2min' == `n2max' {
            local ntotal = `n1min' + `n2min'
            local ntotal_s : display %9.0f `ntotal'
            local ntotal_s = strtrim(`"`ntotal_s'"')
            local sample_text `"The analytic sample included `ntotal_s' complete cases (`g1name' = `n1min_s', `g2name' = `n2min_s') across all summarized outcomes."'
            local sample_design `""'
            local warn_n ""
        }
        else {
            local sample_text `"Analytic sample varied across outcomes: `g1name' = `n1min_s'-`n1max_s'; `g2name' = `n2min_s'-`n2max_s'."'
            local sample_design `"Outcome-specific analytic samples were used because group sizes varied across summarized outcomes."'
            local warn_n `"group sizes varied across outcomes; this usually means outcome-level samples were not identical."'
        }
        local g1note = lower("`g1name'")
        local g2note = lower("`g2name'")

        quietly generate byte sig = !missing(q) & q < `alpha'
        quietly generate double abs_gav = abs(gav)
        quietly generate byte sig_eff = sig & !missing(gav)
        quietly generate byte direction = cond(mean1 > mean2, 1, cond(mean2 > mean1, -1, 0))
        quietly generate str16 itemcode = "Item" + string(item_no, "%02.0f")
        quietly generate str20 abs_gav_txt = cond(missing(abs_gav), ".", string(abs_gav, "%4.2f"))

        quietly count if sig
        local nsig = r(N)
        local pctsig : display %4.1f 100 * `nsig' / `nout'
        local pctsig = strtrim(`"`pctsig'"')
        quietly count if sig & direction == 1
        local ng1 = r(N)
        quietly count if sig & direction == -1
        local ng2 = r(N)

        tempfile full blocksum
        quietly save `"`full'"', replace

        quietly sort blockid item_no
        quietly by blockid: egen outcomes = count(variable)
        quietly by blockid: egen sig_n = total(sig)
        quietly by blockid: egen g1_higher = total(sig & direction == 1)
        quietly by blockid: egen g2_higher = total(sig & direction == -1)
        quietly by blockid: egen min_eff = min(cond(sig_eff, gav, .))
        quietly by blockid: egen max_eff = max(cond(sig_eff, gav, .))

        quietly gsort blockid -sig -sig_eff -abs_gav item_no
        quietly by blockid: generate str32 largest_item = itemcode[1] if sig_n > 0
        quietly by blockid: generate double largest_eff = gav[1] if sig_n > 0
        quietly by blockid: keep if _n == 1
        quietly sort blockid

        quietly generate double sig_pct = 100 * sig_n / outcomes
        quietly generate str12 g1_higher_text = ""
        quietly generate str12 g2_higher_text = ""
        quietly replace g1_higher_text = strtrim(string(g1_higher, "%9.0f")) if sig_n > 0
        quietly replace g2_higher_text = strtrim(string(g2_higher, "%9.0f")) if sig_n > 0
        quietly generate str80 direction_text = g1_higher_text + " / " + g2_higher_text if sig_n > 0
        quietly replace direction_text = "/" if sig_n == 0

        quietly generate str20 min_eff_txt = cond(min_eff >= 0, "+" + strtrim(string(min_eff, "%9.2f")), strtrim(string(min_eff, "%9.2f"))) if sig_n > 0
        quietly generate str20 max_eff_txt = cond(max_eff >= 0, "+" + strtrim(string(max_eff, "%9.2f")), strtrim(string(max_eff, "%9.2f"))) if sig_n > 0
        quietly generate str20 largest_eff_txt = cond(largest_eff >= 0, "+" + strtrim(string(largest_eff, "%9.2f")), strtrim(string(largest_eff, "%9.2f"))) if sig_n > 0
        quietly generate str20 largest_eff_mag_txt = cond(largest_eff >= 0, "+" + strtrim(string(largest_eff, "%9.2f")), strtrim(string(largest_eff, "%9.2f"))) if sig_n > 0
        quietly generate str40 effect_range = ""
        quietly replace effect_range = "/" if sig_n == 0
        quietly replace effect_range = "[" + min_eff_txt + ", " + max_eff_txt + "]" if sig_n > 0 & !missing(min_eff)
        quietly replace effect_range = "effect size missing" if sig_n > 0 & missing(min_eff)
        quietly generate str80 largest_text = cond(sig_n == 0, "/", cond(missing(largest_eff), "effect size missing", largest_item + " (" + largest_eff_txt + ")"))
        quietly generate str20 sig_text = string(sig_n, "%9.0f") + " of " + string(outcomes, "%9.0f")
        quietly generate str12 sig_n_text = strtrim(string(sig_n, "%9.0f"))
        quietly generate str12 outcomes_text = strtrim(string(outcomes, "%9.0f"))

        quietly save `"`blocksum'"', replace
        if `"`summarydata'"' != "" {
            quietly save `"`summarydata'"', replace
        }

        quietly count
        local nblocks_total = r(N)
        quietly count if sig_n > 0
        local nblocks_sig = r(N)
        quietly count if sig_n == 0
        local nblocks_nosig = r(N)
        quietly count if sig_n == outcomes
        local nblocks_all_sig = r(N)

        local sigblocks ""
        local nosigblocks ""
        local consistentblocks ""
        local mixedblocks ""
        local onlynosig ""
        quietly levelsof blockid, local(blocks)
        foreach b of local blocks {
            quietly levelsof blocklabel if blockid == `b', local(blab) clean
            quietly summarize sig_n if blockid == `b', meanonly
            local bsig = r(mean)
            quietly summarize sig_pct if blockid == `b', meanonly
            local bpct = r(mean)
            if `bsig' > 0 local sigblocks `"`sigblocks'`sep1'`blab'"'
            if `bsig' == 0 local nosigblocks `"`nosigblocks'`sep2'`blab'"'
            if `bsig' > 0 & `bpct' >= 70 local consistentblocks `"`consistentblocks'`sep3'`blab'"'
            if `bsig' > 0 local sep1 ", "
            if `bsig' == 0 local sep2 ", "
            if `bsig' > 0 & `bpct' >= 70 local sep3 ", "
            if `bsig' == 0 & `nblocks_nosig' == 1 local onlynosig `"`blab'"'
        }
        if `"`sigblocks'"' == "" local sigblocks "none"
        if `"`nosigblocks'"' == "" local nosigblocks "none"
        if `"`consistentblocks'"' == "" local consistentblocks "none"
        if `"`mixedblocks'"' == "" local mixedblocks "none"

        quietly use `"`blocksum'"', clear
        quietly keep if sig_n > 0
        quietly gsort -sig_n blockid
        local nstrong = min(3, _N)
        local strong1 ""
        local strong2 ""
        local strong3 ""
        if `nstrong' > 0 {
            forvalues i = 1/`nstrong' {
                local strong`i' = blocklabel[`i']
            }
        }
        local strongest_tail ""
        if `nstrong' == 1 {
            local strongest_tail `"with the strongest pattern in `strong1'."'
        }
        else if `nstrong' == 2 {
            local strongest_tail `"with the strongest pattern in `strong1', followed by `strong2'."'
        }
        else if `nstrong' >= 3 {
            local strongest_tail `"with the strongest pattern in `strong1', followed by `strong2' and `strong3'."'
        }

        quietly use `"`full'"', clear
        quietly keep if sig_eff
        quietly gsort -abs_gav item_no
        quietly count
        local nefftop = r(N)
        local ntop = min(`top', `nefftop')
        local top_phrase ""
        forvalues i = 1/`ntop' {
            local ti = itemcode[`i']
            local tb = blocklabel[`i']
            local te : display %9.2f gav[`i']
            local te = strtrim(`"`te'"')
            if gav[`i'] >= 0 local te "+`te'"
            local td = cond(direction[`i'] == 1, "`g1name' higher", cond(direction[`i'] == -1, "`g2name' higher", "no clear direction"))
            local piece "`ti' (`tb', signed g=`te', `td')"
            if `i' == 1 local top_phrase `"`piece'"'
            else local top_phrase `"`top_phrase'; `piece'"'
        }
        if `"`top_phrase'"' == "" local top_phrase "No FDR-significant effects were available."

        local rq_user = (`"`rq'"' != "")
        if !`rq_user' {
            local rq_intro `"This analysis addressed the following three related questions."'
            local rq1 `"Do the two groups show systematic mean differences across a set of outcome variables?"'
            local rq2 `"After controlling the false discovery rate, which outcomes show statistically significant differences?"'
            local rq3 `"Which blocks contain the strongest patterns, what is the direction of the differences, how large are the effects, and do the observed effects appear substantively meaningful?"'
            local rq `"`rq_intro' `rq1' `rq2' `rq3'"'
        }
        local method1 `"`sample_text' `sample_design'"'
        local method2 `"Welch independent-samples t tests examined `nout' outcomes."'
        local method3 `"Benjamini-Hochberg FDR-adjusted q values evaluated statistical significance across the `nout' outcomes."'
        local method4 `"Signed Hedges' g_av values were used to summarize effect-size direction and magnitude."'
        local method_brief `"`method1' `method2' `method3'"'
        local approach `"`method1' `method2' `method3' `method4'"'
        local overall `"After FDR correction, `nsig' of `nout' outcomes (`pctsig'%) remained statistically significant."'
        if `nsig' == 0 {
            local pattern `"No outcomes remained statistically significant after FDR correction. The summary therefore does not interpret block-level differences."'
            local direction `"No direction of FDR-significant differences is reported because no outcomes met the FDR criterion."'
            local toptext `"No top effects are reported because no outcomes were FDR-significant."'
            local appendixtext `"Block-level counts, directions, effect-size ranges, and largest effects are summarized in Appendix A."'
        }
        else {
            if `nsig' == `nout' {
                local pattern `"All outcomes remained FDR-significant, and every block showed FDR-significant differences for all summarized outcomes."'
            }
            else if `nblocks_all_sig' == `nblocks_total' {
                local pattern `"Every block showed FDR-significant differences for all summarized outcomes."'
            }
            else if `nblocks_nosig' == 0 {
                local pattern `"All blocks showed at least some FDR-significant differences, `strongest_tail'"'
            }
            else if `nblocks_nosig' == 1 {
                local pattern `"Except for `onlynosig', all blocks showed at least some FDR-significant differences, `strongest_tail'"'
            }
            else {
                local pattern `"FDR-significant differences appeared in `nblocks_sig' of `nblocks_total' blocks, `strongest_tail'"'
            }
            local direction `"Among FDR-significant outcomes, `ng1' had higher means for `g1name' and `ng2' had higher means for `g2name'. Block-level direction counts are reported in Appendix A."'
            if `ntop' == 0 {
                local toptext `"No largest effects are reported because effect sizes were unavailable for FDR-significant outcomes."'
            }
            else {
                local toptext `"The largest signed Hedges' g_av effects by absolute magnitude were: `top_phrase'."'
            }
            local appendixtext `"Block-level counts, directions, effect-size ranges, and largest effects are summarized in Appendix A."'
        }
        if `"`style'"' == "brief" {
            local methodp `"`method_brief'"'
            local findings_heading "Key findings"
            local f1 `"`overall'"'
            local f2 `"`pattern'"'
            local f3 `"`appendixtext'"'
            local f4 ""
        }
        else {
            local methodp `"`approach'"'
            local findings_heading "Results summary"
            local f1 `"`overall'"'
            local f2 `"`pattern'"'
            local f3 `"`direction'"'
            local f4 `"`toptext' `appendixtext'"'
        }
        if `"`implication'"' == "" & `"`style'"' == "academic" {
            local implication `"These findings identify outcome domains that may warrant closer substantive or model-based follow-up."'
        }

        if `"`ext'"' == ".docx" {
            quietly putdocx clear
            quietly putdocx begin, pagesize(letter) margin(top, .55) margin(bottom, .55) margin(left, 1) margin(right, 1) font("Times New Roman", 10)
            local bullet = uchar(8226)
            forvalues __blank = 1/4 {
                putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
                putdocx text (" "), font("Times New Roman", 10, black)
            }
            putdocx paragraph, halign(center) spacing(before, 0pt) spacing(after, 2pt)
            if `default_title' {
                putdocx text ("Welch Independent-Samples "), font("Times New Roman", 14, black)
                putdocx text ("t"), italic font("Times New Roman", 14, black)
                putdocx text ("-Test Analysis Summary"), font("Times New Roman", 14, black)
            }
            else {
                putdocx text (`"`title'"'), font("Times New Roman", 14, black)
            }
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text (" "), font("Times New Roman", 10, black)
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text (" "), font("Times New Roman", 10, black)

            putdocx paragraph, spacing(before, 0pt) spacing(after, 1pt)
            putdocx text ("Research question"), bold
            if `rq_user' {
                putdocx paragraph, spacing(before, 0pt) spacing(after, 2pt)
                putdocx text (`"`rq'"')
            }
            else {
                putdocx paragraph, spacing(before, 0pt) spacing(after, 1pt)
                putdocx text (`"`rq_intro'"')
                putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
                putdocx text (`"`bullet' `rq1'"')
                putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
                putdocx text (`"`bullet' `rq2'"')
                putdocx paragraph, spacing(before, 0pt) spacing(after, 2pt) indent(left, .25) indent(hanging, .25)
                putdocx text (`"`bullet' `rq3'"')
            }
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text (" "), font("Times New Roman", 10, black)

            if `"`hypothesis'"' != "" {
                putdocx paragraph, spacing(before, 4pt) spacing(after, 1pt)
                putdocx text ("Hypothesis"), bold
                putdocx paragraph, spacing(before, 0pt) spacing(after, 2pt)
                putdocx text (`"`hypothesis'"')
            }

            putdocx paragraph, spacing(before, 0pt) spacing(after, 1pt)
            putdocx text ("Methods"), bold
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' `method1'"')
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' Welch independent-samples "')
            putdocx text ("t"), italic
            putdocx text (`" tests examined `nout' outcomes."')
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' Benjamini-Hochberg FDR-adjusted "')
            putdocx text ("q"), italic
            putdocx text (`" values evaluated statistical significance across the `nout' outcomes."')
            if `"`style'"' == "academic" {
                putdocx paragraph, spacing(before, 0pt) spacing(after, 2pt) indent(left, .25) indent(hanging, .25)
                putdocx text (`"`bullet' Signed Hedges' "')
                putdocx text ("g_av"), italic
                putdocx text (`" values were used to summarize effect-size direction and magnitude."')
            }
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text (" "), font("Times New Roman", 10, black)

            putdocx paragraph, spacing(before, 0pt) spacing(after, 1pt)
            putdocx text (`"`findings_heading'"'), bold
            putdocx paragraph, spacing(before, 0pt) spacing(after, 3pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' `f1'"')
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' `f2'"')
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt) indent(left, .25) indent(hanging, .25)
            putdocx text (`"`bullet' `f3'"')
            if `"`f4'"' != "" {
                putdocx paragraph, spacing(before, 0pt) spacing(after, 3pt) indent(left, .25) indent(hanging, .25)
                putdocx text (`"`bullet' `f4'"')
            }

            if `"`implication'"' != "" {
                putdocx paragraph, spacing(before, 4pt) spacing(after, 1pt)
                putdocx text ("Implication"), bold
                putdocx paragraph, spacing(before, 0pt) spacing(after, 3pt)
                putdocx text (`"`implication'"')
            }

            putdocx sectionbreak, pagesize(letter) landscape margin(top, 1) margin(bottom, 1) margin(left, .55) margin(right, .55)
            quietly use `"`blocksum'"', clear
            local rows = _N + 3
            local note_row = `rows'
            local data_bottom = `rows' - 1
            putdocx paragraph, halign(center) spacing(before, 0pt) spacing(after, 0pt)
            putdocx text ("Appendix A.")
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text ("")
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text ("Table 1"), italic
            putdocx paragraph, spacing(before, 0pt) spacing(after, 0pt)
            putdocx text ("Block-Level Summary of Welch ")
            putdocx text ("t"), italic
            putdocx text ("-Test Analysis")
            putdocx table bsum = (`rows', 12), width(9.40in) halign(left) ///
                border(all, nil) layout(fixed) ///
                cellmargin(top, .5pt) cellmargin(bottom, 0pt) ///
                cellmargin(left, 2pt) cellmargin(right, 2pt)
            putdocx table bsum(.,1), width(1.54in)
            putdocx table bsum(.,2), width(.90in)
            putdocx table bsum(.,3), width(.46in)
            putdocx table bsum(.,4), width(.18in)
            putdocx table bsum(.,5), width(1.25in)
            putdocx table bsum(.,6), width(1.22in)
            putdocx table bsum(.,7), width(.18in)
            putdocx table bsum(.,8), width(.80in)
            putdocx table bsum(.,9), width(.90in)
            putdocx table bsum(.,10), width(.18in)
            putdocx table bsum(.,11), width(.75in)
            putdocx table bsum(.,12), width(.75in)
            putdocx table bsum(1,1) = ("Block Name")
            putdocx table bsum(1,2) = ("# of Outcomes")
            putdocx table bsum(2,2) = ("FDR Q-Sig.")
            putdocx table bsum(2,3) = ("Total")
            putdocx table bsum(1,5) = ("Mean Difference Direction")
            putdocx table bsum(2,5) = ("# of `g1name' Higher")
            putdocx table bsum(2,6) = ("# of `g2name' Higher")
            putdocx table bsum(1,8) = ("Effect-Size Range")
            putdocx table bsum(2,8) = ("Minimum")
            putdocx table bsum(2,9) = ("Maximum")
            putdocx table bsum(1,11) = ("Largest Effect Size")
            putdocx table bsum(2,11) = ("Location")
            putdocx table bsum(2,12) = ("Magnitude")
            putdocx table bsum(1,11), colspan(2)
            putdocx table bsum(1,8), colspan(2)
            putdocx table bsum(1,5), colspan(2)
            putdocx table bsum(1,2), colspan(2)
            putdocx table bsum(1,.), border(top, single, black, 1.5pt)
            putdocx table bsum(2,2), border(top)
            putdocx table bsum(2,3), border(top)
            putdocx table bsum(2,5), border(top)
            putdocx table bsum(2,6), border(top)
            putdocx table bsum(2,8), border(top)
            putdocx table bsum(2,9), border(top)
            putdocx table bsum(2,11), border(top)
            putdocx table bsum(2,12), border(top)
            putdocx table bsum(2,.), border(bottom)
            putdocx table bsum(1,.), halign(center)
            putdocx table bsum(2,.), halign(center)
            putdocx table bsum(.,2), halign(center)
            putdocx table bsum(.,3), halign(center)
            putdocx table bsum(.,5), halign(center)
            putdocx table bsum(.,6), halign(center)
            putdocx table bsum(.,8), halign(center)
            putdocx table bsum(.,9), halign(center)
            putdocx table bsum(.,11), halign(center)
            putdocx table bsum(.,12), halign(center)
            forvalues i = 1/`=_N' {
                local r = `i' + 2
                local location = largest_item[`i']
                local magnitude = largest_eff_mag_txt[`i']
                local minrange = min_eff_txt[`i']
                local maxrange = max_eff_txt[`i']
                local g1higher = g1_higher_text[`i']
                local g2higher = g2_higher_text[`i']
                if sig_n[`i'] == 0 {
                    local location = "/"
                    local magnitude = "/"
                    local minrange = "/"
                    local maxrange = "/"
                    local g1higher = "/"
                    local g2higher = "/"
                }
                if sig_n[`i'] > 0 & missing(min_eff[`i']) {
                    local minrange = "/"
                    local maxrange = "/"
                }
                if sig_n[`i'] > 0 & missing(largest_eff[`i']) {
                    local location = "/"
                    local magnitude = "/"
                }
                putdocx table bsum(`r',1) = (blocklabel[`i'])
                putdocx table bsum(`r',2) = (sig_n_text[`i'])
                putdocx table bsum(`r',3) = (outcomes_text[`i'])
                putdocx table bsum(`r',5) = ("`g1higher'")
                putdocx table bsum(`r',6) = ("`g2higher'")
                putdocx table bsum(`r',8) = ("`minrange'")
                putdocx table bsum(`r',9) = ("`maxrange'")
                putdocx table bsum(`r',11) = ("`location'")
                putdocx table bsum(`r',12) = ("`magnitude'")
            }
            putdocx table bsum(.,2), halign(center)
            putdocx table bsum(.,3), halign(center)
            putdocx table bsum(.,5), halign(center)
            putdocx table bsum(.,6), halign(center)
            putdocx table bsum(.,8), halign(center)
            putdocx table bsum(.,9), halign(center)
            putdocx table bsum(.,11), halign(center)
            putdocx table bsum(.,12), halign(center)
            putdocx table bsum(`note_row',1) = ("Note. "), italic
            putdocx table bsum(`note_row',1) = ("Mean-difference direction reports the number of FDR-significant outcomes with higher means for `g1note' and `g2note', respectively. Effect-size ranges are signed Hedges' g_av intervals among FDR-significant outcomes within each block; positive values indicate higher means for `g1note' and negative values indicate higher means for `g2note'."), append
            putdocx table bsum(`note_row',1), colspan(12)
            putdocx table bsum(`note_row',.), border(top, single, black, 1.5pt)
            putdocx table bsum(`note_row',.), font("Times New Roman", 10)
            quietly putdocx save `"`saving'"', replace
        }
        else {
            tempname fh
            file open `fh' using `"`saving'"', write replace text
            file write `fh' `"`title'"' _n _n
            file write `fh' `"Research question"' _n
            if `rq_user' {
                file write `fh' `"`rq'"' _n _n
            }
            else {
                file write `fh' `"`rq_intro'"' _n
                file write `fh' `"* `rq1'"' _n
                file write `fh' `"* `rq2'"' _n
                file write `fh' `"* `rq3'"' _n _n
            }
            if `"`hypothesis'"' != "" {
                file write `fh' `"Hypothesis"' _n
                file write `fh' `"`hypothesis'"' _n _n
            }
            file write `fh' `"Methods"' _n
            file write `fh' `"* `method1'"' _n
            file write `fh' `"* `method2'"' _n
            file write `fh' `"* `method3'"' _n
            if `"`style'"' == "academic" file write `fh' `"* `method4'"' _n
            file write `fh' _n
            file write `fh' `"`findings_heading'"' _n
            file write `fh' `"* `f1'"' _n
            file write `fh' `"* `f2'"' _n
            file write `fh' `"* `f3'"' _n
            if `"`f4'"' != "" file write `fh' `"* `f4'"' _n
            file write `fh' _n
            if `"`implication'"' != "" {
                file write `fh' `"Implication"' _n
                file write `fh' `"`implication'"' _n _n
            }
            file write `fh' `"Appendix A. Block Summary Table"' _n
            file write `fh' `"Block	Sig. Outcomes	Direction	Effect-Size Range	Largest Effect"' _n
            quietly use `"`blocksum'"', clear
            forvalues i = 1/`=_N' {
                file write `fh' `"`=blocklabel[`i']'	`=sig_text[`i']'	`=direction_text[`i']'	`=effect_range[`i']'	`=largest_text[`i']'"' _n
            }
            file write `fh' _n `"Note. Signed Hedges' g_av values are reported in the effect-size range; positive values indicate higher means for `g1name' and vice versa for negative values."' _n
            file close `fh'
        }

        return scalar outcomes = `nout'
        return scalar significant = `nsig'
        return scalar n1_min = `n1min'
        return scalar n1_max = `n1max'
        return scalar n2_min = `n2min'
        return scalar n2_max = `n2max'
        return local saving `"`saving'"'
        if `"`summarydata'"' != "" return local summarydata `"`summarydata'"'
    restore

    di as txt "wttsummary complete"
    di as txt "Outcomes summarized: " as res `nout'
    if `n1min' == `n1max' & `n2min' == `n2max' {
        di as txt "Group sizes: " as res "`g1name' n=`n1min_s', `g2name' n=`n2min_s'"
    }
    else {
        di as txt "Group size ranges: " as res "`g1name' n=`n1min_s'-`n1max_s', `g2name' n=`n2min_s'-`n2max_s'"
    }
    di as txt "FDR-significant outcomes: " as res `nsig'
    if `"`warn_group'"' != "" di as txt "warning: `warn_group'"
    if `"`warn_n'"' != "" di as txt "warning: `warn_n'"
    if `"`warn_q'"' != "" di as txt "warning: `warn_q'"
    if `"`warn_gav'"' != "" di as txt "warning: `warn_gav'"
    local saving_abs `"`saving'"'
    if strpos(`"`saving_abs'"', ":") == 0 & substr(`"`saving_abs'"', 1, 1) != "/" {
        local saving_abs `"`c(pwd)'/`saving_abs'"'
    }
    local saving_abs = subinstr(`"`saving_abs'"', "\", "/", .)
    local saving_uri `"file:///`saving_abs'"'
    local saving_label `"`saving'"'
    while strpos(`"`saving_label'"', "\") > 0 {
        local p = strpos(`"`saving_label'"', "\")
        local saving_label = substr(`"`saving_label'"', `p' + 1, .)
    }
    while strpos(`"`saving_label'"', "/") > 0 {
        local p = strpos(`"`saving_label'"', "/")
        local saving_label = substr(`"`saving_label'"', `p' + 1, .)
    }
    di as txt "Summary saved to:"
    di as smcl `"  {browse "`saving_uri'":`saving_label'}"'
    if `"`summarydata'"' != "" {
        local sdata_abs `"`summarydata'"'
        if strpos(`"`sdata_abs'"', ":") == 0 & substr(`"`sdata_abs'"', 1, 1) != "/" {
            local sdata_abs `"`c(pwd)'/`sdata_abs'"'
        }
        local sdata_abs = subinstr(`"`sdata_abs'"', "\", "/", .)
        local sdata_uri `"file:///`sdata_abs'"'
        local sdata_label `"`summarydata'"'
        while strpos(`"`sdata_label'"', "\") > 0 {
            local p = strpos(`"`sdata_label'"', "\")
            local sdata_label = substr(`"`sdata_label'"', `p' + 1, .)
        }
        while strpos(`"`sdata_label'"', "/") > 0 {
            local p = strpos(`"`sdata_label'"', "/")
            local sdata_label = substr(`"`sdata_label'"', `p' + 1, .)
        }
        di as txt "Block summary data saved to:"
        di as smcl `"  {browse "`sdata_uri'":`sdata_label'}"'
    }
end

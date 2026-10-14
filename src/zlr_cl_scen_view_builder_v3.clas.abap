CLASS zlr_cl_scen_view_builder_v3 DEFINITION
*CLASS /egs/cl_scen_view_builder DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_sequence_nr  TYPE /egs/if_prs_glb_payroll_data=>ty_sequence_number.
    TYPES ty_tab_sequence TYPE /egs/if_prs_glb_payroll_data=>ty_t_sequence_numbers.
    TYPES ty_tab_plan     TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Distinct sequence numbers in first-seen order: plan results first, then ledger periods.
    CLASS-METHODS collect_sequences
      IMPORTING it_results       TYPE /egs/if_pri_scen_runner=>ty_tab_plan_run_result
                it_periods       TYPE /egs/if_pri_scen_runner=>ty_tab_ledger_period
      RETURNING VALUE(rt_result) TYPE ty_tab_sequence.

    "! Distinct plan names of one sequence in first-seen order.
    CLASS-METHODS collect_plans
      IMPORTING it_results       TYPE /egs/if_pri_scen_runner=>ty_tab_plan_run_result
                iv_sequence_nr   TYPE ty_sequence_nr
      RETURNING VALUE(rt_result) TYPE ty_tab_plan.

    "! Run details of one plan in one sequence: one collapsible section per day,
    "! nested tables and structures rendered as tables. First day open, rest collapsed.
    CLASS-METHODS build_details_html
      IMPORTING it_results       TYPE /egs/if_pri_scen_runner=>ty_tab_plan_run_result
                iv_plan_name     TYPE string
                iv_sequence_nr   TYPE ty_sequence_nr
      RETURNING VALUE(rv_result) TYPE string
      RAISING   cx_static_check.

    "! Captured output of one plan in one sequence: one collapsible section per slice.
    CLASS-METHODS build_captured_html
      IMPORTING it_results       TYPE /egs/if_pri_scen_runner=>ty_tab_plan_run_result
                iv_plan_name     TYPE string
                iv_sequence_nr   TYPE ty_sequence_nr
      RETURNING VALUE(rv_result) TYPE string
      RAISING   cx_static_check.

    "! Ledger accounts as one table. Each account is a header row carrying its totals;
    "! clicking it expands the postings underneath. All accounts start collapsed.
    CLASS-METHODS build_ledger_html
      IMPORTING it_accounts      TYPE /egs/if_han_bts_ledger=>ty_tab_ledger_output
                iv_title         TYPE string
                iv_subtitle      TYPE string
      RETURNING VALUE(rv_result) TYPE string.

    "! Simple page with a title and one line of text - empty states and errors.
    CLASS-METHODS build_message_html
      IMPORTING iv_title         TYPE string
                iv_text          TYPE string
      RETURNING VALUE(rv_result) TYPE string.

    "! Logger HTML report for exactly one sequence - no iframes, no srcdoc.
    "! II_BTS and II_SEQUENCE_HANDLER must be the instances RUN( ) used.
    CLASS-METHODS build_logger_html
      IMPORTING ii_bts              TYPE REF TO /egs/if_bts_store
                iv_pernr            TYPE string
                ii_sequence_handler TYPE REF TO /egs/if_prs_pr_seq_handlr
                it_results          TYPE /egs/if_pri_scen_runner=>ty_tab_plan_run_result
                iv_sequence_nr      TYPE ty_sequence_nr
      RETURNING VALUE(rv_result)    TYPE string
      RAISING   cx_static_check.

  PRIVATE SECTION.

    CLASS-METHODS page_start
      IMPORTING iv_title         TYPE string
                iv_subtitle      TYPE string
      RETURNING VALUE(rv_result) TYPE string.

    CLASS-METHODS page_end
      RETURNING VALUE(rv_result) TYPE string.

    CLASS-METHODS expand_tools
      RETURNING VALUE(rv_result) TYPE string.

    CLASS-METHODS build_section
      IMPORTING iv_title         TYPE string
                iv_meta          TYPE string
                iv_body          TYPE string
                iv_open          TYPE abap_bool
      RETURNING VALUE(rv_result) TYPE string.

    CLASS-METHODS esc
      IMPORTING iv_text          TYPE string
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.


CLASS zlr_cl_scen_view_builder_v3 IMPLEMENTATION.

  METHOD collect_sequences.
    LOOP AT it_results INTO DATA(ls_result).
      IF NOT line_exists( rt_result[ table_line = ls_result-sequence_nr ] ).
        APPEND ls_result-sequence_nr TO rt_result.
      ENDIF.
    ENDLOOP.

    LOOP AT it_periods INTO DATA(ls_period).
      IF NOT line_exists( rt_result[ table_line = ls_period-sequence_nr ] ).
        APPEND ls_period-sequence_nr TO rt_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD collect_plans.
    LOOP AT it_results INTO DATA(ls_result) WHERE sequence_nr = iv_sequence_nr.
      DATA(lv_name) = CONV string( ls_result-plan_name ).
      IF NOT line_exists( rt_result[ table_line = lv_name ] ).
        APPEND lv_name TO rt_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_details_html.
    DATA lv_rows  TYPE string.
    DATA lv_count TYPE i.
    DATA lv_open  TYPE abap_bool VALUE abap_true.
    DATA lv_found TYPE abap_bool.

    DATA(lo_html_builder) = NEW /egs/cl_util_html_builder( ).

    rv_result = page_start( iv_title    = `Run details`
                            iv_subtitle = |Plan { iv_plan_name }  \|  Sequence { iv_sequence_nr }| ).

    LOOP AT it_results INTO DATA(ls_plan) WHERE plan_name = iv_plan_name AND sequence_nr = iv_sequence_nr.
      lv_found = abap_true.

      IF ls_plan-run_details-daily_execute_data IS NOT BOUND.
        rv_result = rv_result && `<p>No run details captured for this plan.</p>`.
        CONTINUE.
      ENDIF.

      rv_result = rv_result && expand_tools( ).

      ASSIGN ls_plan-run_details-daily_execute_data->* TO FIELD-SYMBOL(<lt_days>).

      LOOP AT <lt_days> INTO DATA(ls_day).
        CLEAR: lv_rows, lv_count.

        IF ls_day-data IS BOUND.
          LOOP AT ls_day-data->to_table( ) INTO DATA(ls_entry).
            DATA(lv_key) = |{ ls_entry-key }|.
            lv_rows  = lv_rows &&
                       |<tr><td class="k">{ esc( lv_key ) }</td>| &&
                       |<td>{ lo_html_builder->render_value( ls_entry-data ) }</td></tr>|.
            lv_count = lv_count + 1.
          ENDLOOP.
        ENDIF.

        rv_result = rv_result && build_section(
            iv_title = |Day { ls_day-date DATE = USER }|
            iv_meta  = |{ lv_count } values|
            iv_body  = COND #( WHEN lv_rows IS INITIAL
                               THEN `<p><i>(no values for this day)</i></p>`
                               ELSE |<table><tr><th>Key</th><th>Value</th></tr>{ lv_rows }</table>| )
            iv_open  = lv_open ).
        lv_open = abap_false.
      ENDLOOP.
    ENDLOOP.

    IF lv_found = abap_false.
      rv_result = rv_result && `<p>This plan has no results in this sequence.</p>`.
    ENDIF.

    rv_result = rv_result && page_end( ).
  ENDMETHOD.


  METHOD build_captured_html.
    DATA lv_rows  TYPE string.
    DATA lv_count TYPE i.
    DATA lv_open  TYPE abap_bool VALUE abap_true.
    DATA lv_found TYPE abap_bool.

    DATA(lo_html_builder) = NEW /egs/cl_util_html_builder( ).

    rv_result = page_start( iv_title    = `Captured output`
                            iv_subtitle = |Plan { iv_plan_name }  \|  Sequence { iv_sequence_nr }| ).

    LOOP AT it_results INTO DATA(ls_plan) WHERE plan_name = iv_plan_name AND sequence_nr = iv_sequence_nr.
      lv_found = abap_true.

      IF ls_plan-captured_output IS INITIAL.
        rv_result = rv_result && `<p>No captured output for this plan.</p>`.
        CONTINUE.
      ENDIF.

      rv_result = rv_result && expand_tools( ).

      LOOP AT ls_plan-captured_output INTO DATA(ls_slice).
        CLEAR: lv_rows, lv_count.

        IF ls_slice-results IS BOUND.
          LOOP AT ls_slice-results->to_table( ) INTO DATA(ls_entry).
            DATA(lv_key) = |{ ls_entry-key }|.
            lv_rows  = lv_rows &&
                       |<tr><td class="k">{ esc( lv_key ) }</td>| &&
                       |<td>{ lo_html_builder->render_value( ls_entry-data ) }</td></tr>|.
            lv_count = lv_count + 1.
          ENDLOOP.
        ENDIF.

        rv_result = rv_result && build_section(
            iv_title = |Slice { ls_slice-slice_begin DATE = USER } - { ls_slice-slice_end DATE = USER }|
            iv_meta  = |{ lv_count } values|
            iv_body  = COND #( WHEN ls_slice-results IS NOT BOUND
                               THEN `<p><i>(no results captured for this slice)</i></p>`
                               ELSE |<table><tr><th>Key</th><th>Value</th></tr>{ lv_rows }</table>| )
            iv_open  = lv_open ).
        lv_open = abap_false.
      ENDLOOP.
    ENDLOOP.

    IF lv_found = abap_false.
      rv_result = rv_result && `<p>This plan has no results in this sequence.</p>`.
    ENDIF.

    rv_result = rv_result && page_end( ).
  ENDMETHOD.


  METHOD build_ledger_html.
    rv_result = page_start( iv_title = iv_title iv_subtitle = iv_subtitle ).

    IF it_accounts IS INITIAL.
      rv_result = rv_result && `<p>No ledger postings.</p>` && page_end( ).
      RETURN.
    ENDIF.

    rv_result = rv_result && expand_tools( ) &&
        `<table class="ldg"><tr><th>Account / posting date</th><th class="num">Debit</th>` &&
        `<th class="num">Credit</th><th class="num">Balance</th><th>Unit</th></tr>`.

    LOOP AT it_accounts INTO DATA(ls_account).
      DATA(lv_account) = |{ ls_account-account_path }|.

      rv_result = rv_result &&
          `<tbody><tr class="acct" data-t="r" onclick="sw(this,this.parentNode.nextElementSibling)">` &&
          |<td><span class="mk">&#9656;</span>{ esc( lv_account ) }</td>| &&
          |<td class="num">{ ls_account-total_debit }</td>| &&
          |<td class="num">{ ls_account-total_credit }</td>| &&
          |<td class="num">{ ls_account-total_balance }</td>| &&
          |<td>{ ls_account-unit_key }</td></tr></tbody>| &&
          `<tbody style="display:none">`.

      LOOP AT ls_account-entries INTO DATA(ls_line).
        rv_result = rv_result &&
            |<tr><td class="d">{ ls_line-posting_date DATE = USER }</td>| &&
            |<td class="num">{ ls_line-debit }</td><td class="num">{ ls_line-credit }</td>| &&
            `<td></td><td></td></tr>`.
      ENDLOOP.

      rv_result = rv_result && `</tbody>`.
    ENDLOOP.

    rv_result = rv_result && `</table>` && page_end( ).
  ENDMETHOD.


  METHOD build_message_html.
    rv_result = page_start( iv_title = iv_title iv_subtitle = `` ) &&
                |<p>{ esc( iv_text ) }</p>| &&
                page_end( ).
  ENDMETHOD.


  METHOD build_logger_html.
    DATA(lt_run_details) = VALUE /egs/if_prs_run_details_handlr=>ty_tab_run_details( ).

    LOOP AT it_results INTO DATA(ls_plan_result) WHERE sequence_nr = iv_sequence_nr.
      APPEND ls_plan_result-run_details TO lt_run_details.
    ENDLOOP.

    TRY.
        DATA(lo_logger) = NEW /egs/cl_prs_pr_run_logger( ii_bts              = ii_bts
                                                         iv_pernr            = iv_pernr
                                                         ii_sequence_handler = ii_sequence_handler ).

        rv_result = lo_logger->get_html_report(
                        lo_logger->build_run_data_tab( iv_sequence_number = iv_sequence_nr
                                                       it_run_details     = lt_run_details ) ).

      CATCH /egs/cx_exc_not_found INTO DATA(lx_not_found).
        rv_result = build_message_html(
            iv_title = |Sequence { iv_sequence_nr }: no sequence entry|
            iv_text  = |{ lx_not_found->get_text( ) } | &&
                       |The sequence handler holds no entry for this sequence, so the payroll run logger | &&
                       |cannot build it. Run details, captured output and ledger are still available.| ).
    ENDTRY.
  ENDMETHOD.


  METHOD page_start.
    rv_result =
        `<!DOCTYPE html><html><head>` &&
        `<meta http-equiv="X-UA-Compatible" content="IE=edge"><meta charset="utf-8"><style>` &&
        `body { font-family: Arial, sans-serif; font-size: 13px; color: #1d2d3e; background: #ffffff; margin: 12px 16px; }` &&
        `h1 { font-size: 16px; font-weight: bold; margin: 0 0 2px 0; }` &&
        `.sub { font-size: 12px; color: #556b82; margin-bottom: 12px; }` &&
        `.tools { margin-bottom: 8px; font-size: 12px; }` &&
        `.tools a { color: #0a6ed1; cursor: pointer; margin-right: 16px; text-decoration: none; }` &&
        `.sec { border: 1px solid #d9dde3; margin-bottom: 6px; }` &&
        `.sec-head { background: #f5f6f7; padding: 6px 10px; cursor: pointer; font-weight: bold; }` &&
        `.sec-head .meta { font-weight: normal; color: #556b82; margin-left: 12px; font-size: 12px; }` &&
        `.sec-body { padding: 8px 10px; overflow-x: auto; }` &&
        `.mk { display: inline-block; width: 16px; color: #556b82; }` &&
        `table { border-collapse: collapse; }` &&
        `th, td { border: 1px solid #e4e7eb; padding: 3px 8px; text-align: left; vertical-align: top; }` &&
        `th { background: #f5f6f7; font-weight: bold; }` &&
        `td.k { white-space: nowrap; font-family: Consolas, monospace; font-size: 12px; }` &&
        `table.ldg { width: 100%; }` &&
        `.num { text-align: right; white-space: nowrap; }` &&
        `tr.acct td { background: #eef4fb; cursor: pointer; font-weight: bold; }` &&
        `td.d { padding-left: 30px; }` &&
         NEW /egs/cl_util_html_builder( )->get_css( ) &&
        `</style></head><body>` &&
        |<h1>{ esc( iv_title ) }</h1>|.

    IF iv_subtitle IS NOT INITIAL.
      rv_result = rv_result && |<div class="sub">{ esc( iv_subtitle ) }</div>|.
    ENDIF.
  ENDMETHOD.


  METHOD page_end.
    rv_result =
        `<script>` &&
        `function sw(h, b) {` &&
        `  var closed = b.style.display === 'none';` &&
        `  b.style.display = closed ? '' : 'none';` &&
        `  var m = h.getElementsByTagName('span')[0];` &&
        `  if (m) { m.innerHTML = closed ? '&#9662;' : '&#9656;'; }` &&
        `}` &&
        `function setAll(open) {` &&
        `  var hs = document.querySelectorAll('[data-t]');` &&
        `  for (var i = 0; i < hs.length; i++) {` &&
        `    var h = hs[i];` &&
        `    var b = h.getAttribute('data-t') === 'r' ? h.parentNode.nextElementSibling : h.nextElementSibling;` &&
        `    b.style.display = open ? '' : 'none';` &&
        `    var m = h.getElementsByTagName('span')[0];` &&
        `    if (m) { m.innerHTML = open ? '&#9662;' : '&#9656;'; }` &&
        `  }` &&
        `}` &&
        `</script></body></html>`.
  ENDMETHOD.


  METHOD expand_tools.
    rv_result = `<div class="tools"><a onclick="setAll(true)">Expand all</a>` &&
                `<a onclick="setAll(false)">Collapse all</a></div>`.
  ENDMETHOD.


  METHOD build_section.
    rv_result =
        `<div class="sec"><div class="sec-head" data-t="s" onclick="sw(this,this.nextElementSibling)">` &&
        |<span class="mk">{ COND string( WHEN iv_open = abap_true THEN `&#9662;` ELSE `&#9656;` ) }</span>| &&
        esc( iv_title ) &&
        |<span class="meta">{ esc( iv_meta ) }</span></div>| &&
        |<div class="sec-body"{ COND string( WHEN iv_open = abap_true THEN `` ELSE ` style="display:none"` ) }>| &&
        iv_body &&
        `</div></div>`.
  ENDMETHOD.


  METHOD esc.
    rv_result = escape( val = iv_text format = cl_abap_format=>e_html_text ).
  ENDMETHOD.

ENDCLASS.


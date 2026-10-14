*&---------------------------------------------------------------------*
*& Report zlr_pr_scenario_runner_v4
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zlr_pr_scenario_runner_v4.

TYPE-POOLS vrm.
TABLES sscrfields.

DATA gv_last_libcls TYPE seoclsname.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_libcls TYPE seoclsname.
PARAMETERS p_scen   TYPE c LENGTH 20 AS LISTBOX VISIBLE LENGTH 60.
SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-004.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 1(20) bt_prev USER-COMMAND depl_prev.
SELECTION-SCREEN PUSHBUTTON 23(20) bt_depl USER-COMMAND depl_live.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b4.


CLASS lcl_deployment_ui DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS run
      IMPORTING iv_libcls    TYPE seoclsname
                iv_scenario  TYPE string
                iv_test_mode TYPE abap_bool.

    CLASS-METHODS set_columns
      IMPORTING io_alv TYPE REF TO cl_salv_table
      RAISING   cx_salv_not_found.
ENDCLASS.

CLASS lcl_deployment_ui IMPLEMENTATION.

  METHOD run.

    DATA lo_instance TYPE REF TO object.
    DATA li_library  TYPE REF TO /egs/if_pri_scen_library.
    DATA lv_answer   TYPE c LENGTH 1.

    IF iv_libcls IS INITIAL OR iv_scenario IS INITIAL.
      MESSAGE 'Choose a library class and a scenario first' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF iv_test_mode = abap_false.
      DATA(lv_question) = |Write the plans and config of scenario { iv_scenario } to the BTS | &&
                          |in client { sy-mandt } ({ sy-sysid })? Every deploy adds a new version, | &&
                          |even if the values are unchanged.|.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Deploy scenario to BTS'
          text_question         = lv_question
          default_button        = '2'
          display_cancel_button = abap_false
        IMPORTING
          answer                = lv_answer.
      IF lv_answer <> '1'.
        RETURN.
      ENDIF.
    ENDIF.

    TRY.
        CREATE OBJECT lo_instance TYPE (iv_libcls).
        li_library ?= lo_instance.

        DATA(ls_scenario) = li_library->build_scenario( iv_scenario ).

        DATA(lt_log) = NEW /egs/cl_scen_deployment( )->deploy(
            is_scenario       = ls_scenario
            is_default_config = /egs/cl_zw_configuration_data=>get_config_data( )
            iv_test_mode      = iv_test_mode ).

        IF line_exists( lt_log[ status = /egs/cl_scen_deployment=>c_status-not_written ] ).
          ROLLBACK WORK.
          MESSAGE 'Nothing was written - see CONFLICT / PRODUCTIVE CLIENT rows' TYPE 'S' DISPLAY LIKE 'E'.
        ELSEIF iv_test_mode = abap_false.
          COMMIT WORK.
          MESSAGE |Scenario { iv_scenario } written to the BTS| TYPE 'S'.
        ENDIF.

        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = lt_log ).
        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->get_display_settings( )->set_list_header(
            COND #( WHEN iv_test_mode = abap_true THEN 'Deployment preview - nothing written'
                                                  ELSE 'Deployment log' ) ).
        lo_alv->set_screen_popup( start_column = 5  end_column = 160
                                  start_line   = 3  end_line   = 25 ).
        set_columns( lo_alv ).
        lo_alv->display( ).

      CATCH cx_root INTO DATA(lx_error).
        ROLLBACK WORK.
        /egs/cl_scen_runner=>render_error_chain( lx_error ).
    ENDTRY.

  ENDMETHOD.

  METHOD set_columns.

    TYPES: BEGIN OF ty_struc_column_text,
             name   TYPE lvc_fname,
             short  TYPE scrtext_s,
             medium TYPE scrtext_m,
             long   TYPE scrtext_l,
           END OF ty_struc_column_text,
           ty_tab_column_text TYPE STANDARD TABLE OF ty_struc_column_text WITH EMPTY KEY.

    DATA(lo_columns) = io_alv->get_columns( ).
    lo_columns->set_optimize( abap_true ).

    DATA(lt_texts) = VALUE ty_tab_column_text(
        ( name = 'OBJECT_TYPE'    short = 'Object'     medium = 'Object type'       long = 'Object type' )
        ( name = 'NAME'           short = 'Name'       medium = 'Plan / config key' long = 'Plan name or config key' )
        ( name = 'BEGIN_DATE'     short = 'Valid from' medium = 'Valid from'        long = 'Valid from' )
        ( name = 'END_DATE'       short = 'Valid to'   medium = 'Valid to'          long = 'Valid to (exclusive)' )
        ( name = 'ACTION'         short = 'Action'     medium = 'Action'            long = 'Default / override / conflict' )
        ( name = 'STATUS'         short = 'Status'     medium = 'Status'            long = 'Written / test mode / not written' )
        ( name = 'OCCURRENCES'    short = 'Plan units' medium = 'Plan units'        long = 'Plan units carrying this entry' )
        ( name = 'OVERRIDE_COUNT' short = 'Overrides'  medium = 'Overriding units'  long = 'Plan units overriding the default' )
        ( name = 'FIRST_PLAN'     short = 'First plan' medium = 'First plan'        long = 'First plan that supplied the value' ) ).

    LOOP AT lt_texts INTO DATA(ls_text).
      DATA(lo_column) = lo_columns->get_column( ls_text-name ).
      lo_column->set_short_text( ls_text-short ).
      lo_column->set_medium_text( ls_text-medium ).
      lo_column->set_long_text( ls_text-long ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lcl_view_data DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES ty_seq      TYPE /egs/cl_scen_view_builder=>ty_sequence_nr.
    TYPES ty_tab_seq  TYPE /egs/cl_scen_view_builder=>ty_tab_sequence.
    TYPES ty_tab_plan TYPE /egs/cl_scen_view_builder=>ty_tab_plan.

    CONSTANTS: BEGIN OF c_view,
                 logger   TYPE ui_func VALUE 'V_LOG',
                 details  TYPE ui_func VALUE 'V_DET',
                 captured TYPE ui_func VALUE 'V_CAP',
                 ledger   TYPE ui_func VALUE 'V_LDG',
               END OF c_view.

    EVENTS theme_changed.

    METHODS constructor
      IMPORTING is_scenario         TYPE /egs/if_pri_scen_runner=>ty_struc_scenario
                is_result           TYPE /egs/if_pri_scen_runner=>ty_struc_run_result
                ii_bts              TYPE REF TO /egs/if_bts_store
                ii_sequence_handler TYPE REF TO /egs/if_prs_pr_seq_handlr
      RAISING   cx_static_check.

    METHODS get_pernr     RETURNING VALUE(rv_result) TYPE string.
    METHODS get_sequences RETURNING VALUE(rt_result) TYPE ty_tab_seq.
    METHODS get_theme     RETURNING VALUE(rv_result) TYPE string.
    METHODS toggle_theme.

    METHODS get_plans
      IMPORTING iv_seq           TYPE ty_seq
      RETURNING VALUE(rt_result) TYPE ty_tab_plan.

    METHODS get_period_label
      IMPORTING iv_seq           TYPE ty_seq
      RETURNING VALUE(rv_result) TYPE string.

    METHODS get_page
      IMPORTING iv_view          TYPE ui_func
                iv_plan          TYPE string    OPTIONAL
                iv_seq           TYPE ty_seq    OPTIONAL
                iv_all_periods   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rv_result) TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_struc_text,
             key  TYPE string,
             text TYPE string,
           END OF ty_struc_text,
           ty_tab_text TYPE HASHED TABLE OF ty_struc_text WITH UNIQUE KEY key.

    TYPES: BEGIN OF ty_struc_seq_plans,
             sequence_nr TYPE ty_seq,
             plans       TYPE ty_tab_plan,
           END OF ty_struc_seq_plans,
           ty_tab_seq_plans TYPE HASHED TABLE OF ty_struc_seq_plans WITH UNIQUE KEY sequence_nr.

    DATA mv_pernr     TYPE string.
    DATA mv_theme     TYPE string.
    DATA mt_sequences TYPE ty_tab_seq.
    DATA mt_periods   TYPE ty_tab_text.
    DATA mt_pages     TYPE ty_tab_text.
    DATA mt_plans     TYPE ty_tab_seq_plans.

    METHODS page_key
      IMPORTING iv_view          TYPE ui_func
                iv_plan          TYPE string    OPTIONAL
                iv_seq           TYPE ty_seq    OPTIONAL
                iv_all_periods   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rv_result) TYPE string.

    METHODS failure_page
      IMPORTING ix_error         TYPE REF TO cx_root
      RETURNING VALUE(rv_result) TYPE string.
ENDCLASS.

CLASS lcl_view_data IMPLEMENTATION.

  METHOD constructor.
    DATA lv_last_day TYPE d.
    DATA lv_from     TYPE d.
    DATA lv_to       TYPE d.
    DATA lv_html     TYPE string.
    DATA lv_total    TYPE string.

    mv_theme     = /egs/cl_util_html_builder=>c_theme-light.
    mv_pernr     = is_scenario-personnel_id.
    mt_sequences = /egs/cl_scen_view_builder=>collect_sequences( it_results = is_result-plan_results
                                                                 it_periods = is_result-ledger_by_period ).

    LOOP AT is_result-ledger_by_period INTO DATA(ls_period).
      lv_last_day = ls_period-end_date - 1.
      INSERT VALUE #( key  = |{ ls_period-sequence_nr }|
                      text = |{ ls_period-begin_date DATE = USER } - { lv_last_day DATE = USER }| )
             INTO TABLE mt_periods.

      IF lv_from IS INITIAL OR ls_period-begin_date < lv_from.
        lv_from = ls_period-begin_date.
      ENDIF.
      IF ls_period-end_date > lv_to.
        lv_to = ls_period-end_date.
      ENDIF.
    ENDLOOP.

    IF lv_to IS NOT INITIAL.
      lv_last_day = lv_to - 1.
      lv_total    = |{ lv_from DATE = USER } - { lv_last_day DATE = USER }|.
    ENDIF.

    LOOP AT mt_sequences INTO DATA(lv_seq).
      DATA(lv_period) = get_period_label( lv_seq ).

      TRY.
          lv_html = /egs/cl_scen_view_builder=>build_logger_html(
                        ii_bts              = ii_bts
                        iv_pernr            = mv_pernr
                        ii_sequence_handler = ii_sequence_handler
                        it_results          = is_result-plan_results
                        iv_sequence_nr      = lv_seq ).
        CATCH cx_root INTO DATA(lx_logger).
          lv_html = failure_page( lx_logger ).
      ENDTRY.
      INSERT VALUE #( key = page_key( iv_view = c_view-logger iv_seq = lv_seq ) text = lv_html )
             INTO TABLE mt_pages.

      INSERT VALUE #( key  = page_key( iv_view = c_view-ledger iv_seq = lv_seq )
                      text = /egs/cl_scen_view_builder=>build_ledger_html(
                                 it_accounts = VALUE #( is_result-ledger_by_period[ sequence_nr = lv_seq ]-ledger_output OPTIONAL )
                                 iv_title    = `Ledger`
                                 iv_subtitle = |Sequence { lv_seq }  \|  postings dated { lv_period }| ) )
             INTO TABLE mt_pages.

      DATA(lt_plans) = /egs/cl_scen_view_builder=>collect_plans( it_results     = is_result-plan_results
                                                                 iv_sequence_nr = lv_seq ).
      INSERT VALUE #( sequence_nr = lv_seq plans = lt_plans ) INTO TABLE mt_plans.

      LOOP AT lt_plans INTO DATA(lv_plan).
        TRY.
            lv_html = /egs/cl_scen_view_builder=>build_details_html( it_results     = is_result-plan_results
                                                                     iv_plan_name   = lv_plan
                                                                     iv_sequence_nr = lv_seq ).
          CATCH cx_root INTO DATA(lx_details).
            lv_html = failure_page( lx_details ).
        ENDTRY.
        INSERT VALUE #( key = page_key( iv_view = c_view-details iv_plan = lv_plan iv_seq = lv_seq ) text = lv_html )
               INTO TABLE mt_pages.

        TRY.
            lv_html = /egs/cl_scen_view_builder=>build_captured_html( it_results     = is_result-plan_results
                                                                      iv_plan_name   = lv_plan
                                                                      iv_sequence_nr = lv_seq ).
          CATCH cx_root INTO DATA(lx_captured).
            lv_html = failure_page( lx_captured ).
        ENDTRY.
        INSERT VALUE #( key = page_key( iv_view = c_view-captured iv_plan = lv_plan iv_seq = lv_seq ) text = lv_html )
               INTO TABLE mt_pages.
      ENDLOOP.
    ENDLOOP.

    INSERT VALUE #( key  = page_key( iv_view = c_view-ledger iv_all_periods = abap_true )
                    text = /egs/cl_scen_view_builder=>build_ledger_html(
                               it_accounts = is_result-ledger_total
                               iv_title    = `Ledger - all periods`
                               iv_subtitle = |Postings dated { lv_total }| ) )
           INTO TABLE mt_pages.
  ENDMETHOD.

  METHOD get_pernr.
    rv_result = mv_pernr.
  ENDMETHOD.

  METHOD get_sequences.
    rt_result = mt_sequences.
  ENDMETHOD.

  METHOD get_theme.
    rv_result = mv_theme.
  ENDMETHOD.

  METHOD toggle_theme.
    mv_theme = COND #( WHEN mv_theme = /egs/cl_util_html_builder=>c_theme-dark
                       THEN /egs/cl_util_html_builder=>c_theme-light
                       ELSE /egs/cl_util_html_builder=>c_theme-dark ).
    RAISE EVENT theme_changed.
  ENDMETHOD.

  METHOD get_plans.
    rt_result = VALUE #( mt_plans[ sequence_nr = iv_seq ]-plans OPTIONAL ).
  ENDMETHOD.

  METHOD get_period_label.
    rv_result = VALUE #( mt_periods[ key = |{ iv_seq }| ]-text OPTIONAL ).
  ENDMETHOD.

  METHOD get_page.
    rv_result = VALUE #( mt_pages[ key = page_key( iv_view        = iv_view
                                                   iv_plan        = iv_plan
                                                   iv_seq         = iv_seq
                                                   iv_all_periods = iv_all_periods ) ]-text OPTIONAL ).
  ENDMETHOD.

  METHOD page_key.
    rv_result = |{ iv_view }\|{ iv_plan }\|{ iv_seq }\|{ iv_all_periods }|.
  ENDMETHOD.

  METHOD failure_page.
    rv_result = /egs/cl_scen_view_builder=>build_message_html( iv_title = `This view could not be built`
                                                               iv_text  = ix_error->get_text( ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_pane DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_struc_state,
             view        TYPE ui_func,
             plan        TYPE string,
             seq         TYPE lcl_view_data=>ty_seq,
             all_periods TYPE abap_bool,
           END OF ty_struc_state.

    METHODS constructor
      IMPORTING io_parent         TYPE REF TO cl_gui_container
                io_data           TYPE REF TO lcl_view_data
                is_state          TYPE ty_struc_state
                iv_stacked_header TYPE abap_bool DEFAULT abap_false.

    METHODS get_state
      RETURNING VALUE(rs_result) TYPE ty_struc_state.

    "! Unregister from the shared theme event before the controls are freed.
    METHODS detach.

  PRIVATE SECTION.
    CONSTANTS c_ribbon_height         TYPE i      VALUE 44.
    CONSTANTS c_ribbon_height_stacked TYPE i      VALUE 80.
    CONSTANTS c_all_periods           TYPE string VALUE `ALL`.
    CONSTANTS c_no_plan               TYPE string VALUE `0`.

    DATA mo_data    TYPE REF TO lcl_view_data.
    DATA ms_state   TYPE ty_struc_state.
    DATA mv_stacked TYPE abap_bool.
    DATA mo_ribbon  TYPE REF TO cl_gui_html_viewer.
    DATA mo_content TYPE REF TO cl_gui_html_viewer.

    METHODS align_plan.
    METHODS render_ribbon.
    METHODS render_content.

    METHODS uses_plan
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS shows_all_periods
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS show_html
      IMPORTING io_viewer TYPE REF TO cl_gui_html_viewer
                iv_html   TYPE string
      RAISING   cx_static_check.

    METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action getdata.

    METHODS on_theme_changed FOR EVENT theme_changed OF lcl_view_data.
ENDCLASS.

CLASS lcl_pane IMPLEMENTATION.

  METHOD constructor.
    mo_data    = io_data.
    ms_state   = is_state.
    mv_stacked = iv_stacked_header.
    align_plan( ).

    DATA(lo_layout) = NEW cl_gui_splitter_container( parent  = io_parent
                                                     rows    = 2
                                                     columns = 1 ).
    lo_layout->set_row_mode( EXPORTING mode = cl_gui_splitter_container=>mode_absolute
                             EXCEPTIONS OTHERS = 1 ).
    lo_layout->set_row_height( EXPORTING id     = 1
                                         height = COND #( WHEN mv_stacked = abap_true
                                                          THEN c_ribbon_height_stacked
                                                          ELSE c_ribbon_height )
                               EXCEPTIONS OTHERS = 1 ).
    lo_layout->set_row_sash( EXPORTING id    = 1
                                       type  = cl_gui_splitter_container=>type_movable
                                       value = cl_gui_splitter_container=>false
                             EXCEPTIONS OTHERS = 1 ).
    lo_layout->set_row_sash( EXPORTING id    = 1
                                       type  = cl_gui_splitter_container=>type_sashvisible
                                       value = cl_gui_splitter_container=>false
                             EXCEPTIONS OTHERS = 1 ).

    mo_ribbon  = NEW #( parent = lo_layout->get_container( row = 1 column = 1 ) ).
    mo_content = NEW #( parent = lo_layout->get_container( row = 2 column = 1 ) ).

    mo_ribbon->set_registered_events(
        EXPORTING events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = abap_false ) )
        EXCEPTIONS OTHERS = 1 ).
    SET HANDLER on_sapevent FOR mo_ribbon.
    SET HANDLER on_theme_changed FOR mo_data.

    render_ribbon( ).
    render_content( ).
  ENDMETHOD.

  METHOD get_state.
    rs_result = ms_state.
  ENDMETHOD.

  METHOD detach.
    SET HANDLER on_theme_changed FOR mo_data ACTIVATION abap_false.
    SET HANDLER on_sapevent FOR mo_ribbon ACTIVATION abap_false.
  ENDMETHOD.

  METHOD on_theme_changed.
    render_ribbon( ).
    render_content( ).
  ENDMETHOD.

  METHOD uses_plan.
    rv_result = xsdbool( ms_state-view = lcl_view_data=>c_view-details
                      OR ms_state-view = lcl_view_data=>c_view-captured ).
  ENDMETHOD.

  METHOD shows_all_periods.
    rv_result = xsdbool( ms_state-view = lcl_view_data=>c_view-ledger AND ms_state-all_periods = abap_true ).
  ENDMETHOD.

  METHOD align_plan.
    DATA(lt_plans) = mo_data->get_plans( ms_state-seq ).
    IF NOT line_exists( lt_plans[ table_line = ms_state-plan ] ).
      ms_state-plan = VALUE #( lt_plans[ 1 ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.

  METHOD on_sapevent.
    DATA(lv_action) = to_upper( condense( CONV string( action ) ) ).
    DATA(lv_value)  = condense( CONV string( getdata ) ).

    CASE lv_action.
      WHEN /egs/cl_scen_view_builder=>c_event-view.
        IF lv_value = ms_state-view.
          RETURN.
        ENDIF.
        ms_state-view = lv_value.

      WHEN /egs/cl_scen_view_builder=>c_event-plan.
        DATA(lt_plans) = mo_data->get_plans( ms_state-seq ).
        DATA(lv_index) = CONV i( lv_value ).
        ms_state-plan  = VALUE #( lt_plans[ lv_index ] OPTIONAL ).

      WHEN /egs/cl_scen_view_builder=>c_event-seq.
        IF lv_value = c_all_periods.
          ms_state-all_periods = abap_true.
        ELSE.
          ms_state-seq         = lv_value.
          ms_state-all_periods = abap_false.
        ENDIF.

      WHEN /egs/cl_scen_view_builder=>c_event-theme.
        mo_data->toggle_theme( ).
        RETURN.

      WHEN OTHERS.
        RETURN.
    ENDCASE.

    align_plan( ).
    render_ribbon( ).
    render_content( ).
  ENDMETHOD.

  METHOD render_ribbon.
    DATA ls_ribbon TYPE /egs/cl_scen_view_builder=>ty_struc_ribbon.

    ls_ribbon-views = VALUE #( ( fcode = CONV #( lcl_view_data=>c_view-captured ) text = `Captured Outputs` )
                           ( fcode = CONV #( lcl_view_data=>c_view-details )  text = `Run Details Results` )
                           ( fcode = CONV #( lcl_view_data=>c_view-ledger )   text = `Ledger Results` )
                           ( fcode = CONV #( lcl_view_data=>c_view-logger )   text = `Payroll Run Results` ) ).
    ls_ribbon-active_view = ms_state-view.

    IF uses_plan( ) = abap_true.
      DATA(lt_plans) = mo_data->get_plans( ms_state-seq ).
      LOOP AT lt_plans INTO DATA(lv_plan).
        APPEND VALUE #( value = |{ sy-tabix }| text = lv_plan ) TO ls_ribbon-plans.
      ENDLOOP.
      ls_ribbon-active_plan  = |{ line_index( lt_plans[ table_line = ms_state-plan ] ) }|.
      ls_ribbon-plan_enabled = abap_true.
    ELSE.
      ls_ribbon-plans        = VALUE #( ( value = c_no_plan text = `All plans` ) ).
      ls_ribbon-active_plan  = c_no_plan.
      ls_ribbon-plan_enabled = abap_false.
    ENDIF.

    LOOP AT mo_data->get_sequences( ) INTO DATA(lv_seq).
      APPEND VALUE #( value = |{ lv_seq }|
                      text  = |{ lv_seq } ({ mo_data->get_period_label( lv_seq ) })| )
             TO ls_ribbon-sequences.
    ENDLOOP.
    IF ms_state-view = lcl_view_data=>c_view-ledger.
      APPEND VALUE #( value = c_all_periods text = `All periods` ) TO ls_ribbon-sequences.
    ENDIF.
    ls_ribbon-active_seq = COND #( WHEN shows_all_periods( ) = abap_true THEN c_all_periods
                                   ELSE |{ ms_state-seq }| ).

    ls_ribbon-theme   = mo_data->get_theme( ).
    ls_ribbon-stacked = mv_stacked.

    TRY.
        show_html( io_viewer = mo_ribbon
                   iv_html   = /egs/cl_scen_view_builder=>build_ribbon_html( ls_ribbon ) ).
      CATCH cx_root INTO DATA(lx_error).
        MESSAGE lx_error TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD render_content.
    DATA(lv_html) = mo_data->get_page(
        iv_view        = ms_state-view
        iv_plan        = COND #( WHEN uses_plan( ) = abap_true THEN ms_state-plan )
        iv_seq         = COND #( WHEN shows_all_periods( ) = abap_false THEN ms_state-seq )
        iv_all_periods = shows_all_periods( ) ).

    IF lv_html IS INITIAL.
      lv_html = /egs/cl_scen_view_builder=>build_message_html(
                    iv_title = `No data`
                    iv_text  = `There is no data for this selection.` ).
    ENDIF.

    TRY.
        show_html( io_viewer = mo_content
                   iv_html   = /egs/cl_util_html_builder=>apply_theme( iv_html  = lv_html
                                                                      iv_theme = mo_data->get_theme( ) ) ).
      CATCH cx_root INTO DATA(lx_error).
        MESSAGE lx_error TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD show_html.
    DATA lv_size TYPE so_obj_len.
    DATA lv_url  TYPE c LENGTH 250.
    DATA lt_data TYPE solix_tab.

    cl_bcs_convert=>string_to_solix( EXPORTING iv_string   = iv_html
                                               iv_codepage = '4110'
                                     IMPORTING et_solix    = lt_data
                                               ev_size     = lv_size ).

    io_viewer->load_data( EXPORTING  type         = 'text'
                                     subtype      = 'html'
                                     size         = CONV i( lv_size )
                          IMPORTING  assigned_url = lv_url
                          CHANGING   data_table   = lt_data
                          EXCEPTIONS OTHERS       = 1 ).
    IF sy-subrc <> 0.
      MESSAGE 'The view could not be loaded' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    io_viewer->show_url( EXPORTING  url    = lv_url
                         EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_viewer DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS: BEGIN OF c_fcode,
                 back   TYPE sy-ucomm VALUE 'BACK',
                 exit   TYPE sy-ucomm VALUE 'EXIT',
                 cancel TYPE sy-ucomm VALUE 'CANC',
                 single TYPE sy-ucomm VALUE 'SINGLE',
                 side   TYPE sy-ucomm VALUE 'SIDE',
                 stack  TYPE sy-ucomm VALUE 'STACK',
                 theme  TYPE sy-ucomm VALUE 'THEME',
               END OF c_fcode.

    METHODS constructor
      IMPORTING io_data     TYPE REF TO lcl_view_data
                iv_scenario TYPE string.

    METHODS pbo.

    METHODS pai
      IMPORTING iv_okcode TYPE sy-ucomm.

  PRIVATE SECTION.
    DATA mo_data     TYPE REF TO lcl_view_data.
    DATA mv_scenario TYPE string.
    DATA mv_pernr    TYPE string.
    DATA mv_layout   TYPE sy-ucomm.
    DATA mo_frame    TYPE REF TO cl_gui_splitter_container.
    DATA mo_first    TYPE REF TO lcl_pane.
    DATA mo_second   TYPE REF TO lcl_pane.
    DATA ms_first    TYPE lcl_pane=>ty_struc_state.
    DATA ms_second   TYPE lcl_pane=>ty_struc_state.

    METHODS build_layout.
    METHODS remember_state.
    METHODS free_frame.
ENDCLASS.

CLASS lcl_viewer IMPLEMENTATION.

  METHOD constructor.
    mo_data     = io_data.
    mv_scenario = iv_scenario.
    mv_pernr    = io_data->get_pernr( ).
    mv_layout   = c_fcode-single.

    DATA(lt_sequences) = io_data->get_sequences( ).
    DATA(lv_seq)       = VALUE lcl_view_data=>ty_seq( lt_sequences[ 1 ] OPTIONAL ).
    DATA(lt_plans)     = io_data->get_plans( lv_seq ).
    DATA(lv_plan)      = VALUE string( lt_plans[ 1 ] OPTIONAL ).

    ms_first  = VALUE #( view = lcl_view_data=>c_view-captured seq = lv_seq plan = lv_plan ).
    ms_second = VALUE #( view = lcl_view_data=>c_view-ledger seq = lv_seq plan = lv_plan ).
  ENDMETHOD.

  METHOD pbo.
    SET PF-STATUS 'S100'.
    SET TITLEBAR 'T100' WITH mv_scenario mv_pernr.

    IF mo_frame IS NOT BOUND.
      build_layout( ).
    ENDIF.
  ENDMETHOD.

  METHOD pai.
    CASE iv_okcode.
      WHEN c_fcode-back OR c_fcode-exit OR c_fcode-cancel.
        free_frame( ).
        LEAVE TO SCREEN 0.

      WHEN c_fcode-single OR c_fcode-side OR c_fcode-stack.
        IF iv_okcode <> mv_layout.
          mv_layout = iv_okcode.
          build_layout( ).
        ENDIF.

      WHEN c_fcode-theme.
        mo_data->toggle_theme( ).
    ENDCASE.
  ENDMETHOD.

  METHOD remember_state.
    IF mo_first IS BOUND.
      ms_first = mo_first->get_state( ).
    ENDIF.
    IF mo_second IS BOUND.
      ms_second = mo_second->get_state( ).
    ENDIF.
  ENDMETHOD.

  METHOD free_frame.
    IF mo_first IS BOUND.
      mo_first->detach( ).
    ENDIF.
    IF mo_second IS BOUND.
      mo_second->detach( ).
    ENDIF.
    IF mo_frame IS BOUND.
      mo_frame->free( EXCEPTIONS OTHERS = 1 ).
    ENDIF.
    CLEAR: mo_frame, mo_first, mo_second.
  ENDMETHOD.

  METHOD build_layout.
    remember_state( ).
    free_frame( ).

    mo_frame = NEW #( parent  = cl_gui_container=>default_screen
                      rows    = COND #( WHEN mv_layout = c_fcode-stack THEN 2 ELSE 1 )
                      columns = COND #( WHEN mv_layout = c_fcode-side  THEN 2 ELSE 1 ) ).

    mo_first = NEW #( io_parent         = mo_frame->get_container( row = 1 column = 1 )
                      io_data           = mo_data
                      is_state          = ms_first
                      iv_stacked_header = xsdbool( mv_layout = c_fcode-side ) ).

    IF mv_layout = c_fcode-single.
      RETURN.
    ENDIF.

    mo_second = NEW #( io_parent         = mo_frame->get_container(
                                               row    = COND #( WHEN mv_layout = c_fcode-stack THEN 2 ELSE 1 )
                                               column = COND #( WHEN mv_layout = c_fcode-side  THEN 2 ELSE 1 ) )
                       io_data           = mo_data
                       is_state          = ms_second
                       iv_stacked_header = xsdbool( mv_layout = c_fcode-side ) ).
  ENDMETHOD.

ENDCLASS.

DATA go_viewer TYPE REF TO lcl_viewer.
DATA gv_okcode TYPE sy-ucomm.
DATA gv_ucomm  TYPE sy-ucomm.

INITIALIZATION.

  bt_prev = 'Preview deployment'.
  bt_depl = 'Deploy to BTS'.

  IMPORT p_libcls TO p_libcls
         p_scen   TO p_scen
         FROM MEMORY ID '/EGS/PRI_SCEN_RUNNER'.
  IF sy-subrc = 0.
    gv_last_libcls = p_libcls.
  ENDIF.

AT SELECTION-SCREEN ON p_libcls.
  DATA lo_check TYPE REF TO object.
  DATA li_check TYPE REF TO /egs/if_pri_scen_library.

  TRY.
      CREATE OBJECT lo_check TYPE (p_libcls).
      li_check ?= lo_check.
    CATCH cx_sy_create_object_error.
      MESSAGE |{ p_libcls } does not exist or cannot be instantiated| TYPE 'E'.
    CATCH cx_sy_move_cast_error.
      MESSAGE |{ p_libcls } does not implement /EGS/IF_PRI_SCEN_LIBRARY| TYPE 'E'.
  ENDTRY.

AT SELECTION-SCREEN OUTPUT.
  DATA lo_instance       TYPE REF TO object.
  DATA li_library_output TYPE REF TO /egs/if_pri_scen_library.
  DATA lt_listbox_values TYPE vrm_values.

  IF p_libcls <> gv_last_libcls.
    CLEAR p_scen.
    gv_last_libcls = p_libcls.
  ENDIF.

  CLEAR lt_listbox_values.
  IF p_libcls IS NOT INITIAL.
    TRY.
        CREATE OBJECT lo_instance TYPE (p_libcls).
        li_library_output ?= lo_instance.

        LOOP AT li_library_output->get_scenario_catalog( ) INTO DATA(ls_catalog_entry).
          APPEND VALUE #( key  = ls_catalog_entry-name
                          text = ls_catalog_entry-name ) TO lt_listbox_values.
        ENDLOOP.
      CATCH cx_sy_create_object_error
            cx_sy_move_cast_error.
        CLEAR lt_listbox_values.
    ENDTRY.
  ENDIF.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_SCEN'
      values = lt_listbox_values.

AT SELECTION-SCREEN.
  EXPORT p_libcls = p_libcls
         p_scen   = p_scen
         TO MEMORY ID '/EGS/PRI_SCEN_RUNNER'.

  CASE sscrfields-ucomm.
    WHEN 'DEPL_PREV'.
      lcl_deployment_ui=>run( iv_libcls    = p_libcls
                              iv_scenario  = CONV #( p_scen )
                              iv_test_mode = abap_true ).
    WHEN 'DEPL_LIVE'.
      lcl_deployment_ui=>run( iv_libcls    = p_libcls
                              iv_scenario  = CONV #( p_scen )
                              iv_test_mode = abap_false ).
  ENDCASE.


*&=====================================================================*
*& PART B - START-OF-SELECTION
*&=====================================================================*

START-OF-SELECTION.

  DATA lo_runtime_instance TYPE REF TO object.
  DATA li_library          TYPE REF TO /egs/if_pri_scen_library.

  DATA(lo_runner) = NEW /egs/cl_scen_runner( ).

  TRY.
      CREATE OBJECT lo_runtime_instance TYPE (p_libcls).
      li_library ?= lo_runtime_instance.

      DATA(ls_scenario) = li_library->build_scenario( CONV string( p_scen ) ).
      DATA(ls_result)   = lo_runner->run( ls_scenario ).

      DATA(lo_view_data) = NEW lcl_view_data( is_scenario         = ls_scenario
                                              is_result           = ls_result
                                              ii_bts              = lo_runner->get_bts( )
                                              ii_sequence_handler = lo_runner->get_sequence_handler( ) ).

      ROLLBACK WORK.

      go_viewer = NEW lcl_viewer( io_data     = lo_view_data
                                  iv_scenario = CONV #( p_scen ) ).

    CATCH cx_root INTO DATA(lx_error).
      ROLLBACK WORK.
      /egs/cl_scen_runner=>render_error_chain(
          ix_error   = lx_error
          iv_context = COND #( WHEN lo_runner IS BOUND THEN lo_runner->get_failure_context( ) ) ).
      RETURN.
  ENDTRY.

  CALL SCREEN 100.


*&=====================================================================*
*& PART C - screen 100 modules
*&=====================================================================*

MODULE pbo_0100 OUTPUT.
  go_viewer->pbo( ).
ENDMODULE.

MODULE pai_0100 INPUT.
  gv_ucomm = gv_okcode.
  CLEAR gv_okcode.
  go_viewer->pai( gv_ucomm ).
ENDMODULE.

*&---------------------------------------------------------------------*
*& Report zlr_pr_scenario_runner
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zlr_pr_scenario_runner_1.

TYPE-POOLS: vrm.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_scen TYPE c LENGTH 20 AS LISTBOX VISIBLE LENGTH 60.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS p_pernr TYPE c LENGTH 20 LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

AT SELECTION-SCREEN OUTPUT.
  DATA lt_listbox_values TYPE vrm_values.
  DATA(lo_library_for_catalog) = NEW zlr_cl_scenario_library( ).

  LOOP AT lo_library_for_catalog->get_scenario_catalog( ) INTO DATA(ls_catalog_entry).
    APPEND VALUE #( key  = ls_catalog_entry-name
                    text = ls_catalog_entry-description ) TO lt_listbox_values.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_SCEN'
      values = lt_listbox_values.

START-OF-SELECTION.

  DATA(lo_library) = NEW zlr_cl_scenario_library( ).
  DATA(lo_runner)  = NEW zlr_cl_scenario_runner( ).

  TRY.
      DATA(ls_scenario) = lo_library->build_scenario( CONV string( p_scen ) ).

      IF p_pernr IS NOT INITIAL.
        ls_scenario-personnel_id = p_pernr.
      ENDIF.

      DATA(ls_result) = lo_runner->run( ls_scenario ).
      zlr_cl_scenario_runner=>render( ls_result ).

    CATCH cx_static_check INTO DATA(lx_error).
      DATA lv_error_html TYPE string.
      lv_error_html = `<html><body><h2>Scenario failed</h2>`.

      DATA lx_current TYPE REF TO cx_root.
      lx_current = lx_error.

      WHILE lx_current IS BOUND.
        lv_error_html = lv_error_html &&
            |<p><b>{ cl_abap_typedescr=>describe_by_object_ref( lx_current )->get_relative_name( ) }</b><br/>| &&
            |{ lx_current->get_text( ) }</p>|.
        lx_current = lx_current->previous.
      ENDWHILE.

      lv_error_html = lv_error_html && `</body></html>`.
      cl_abap_browser=>show_html( html_string = lv_error_html
                                  title       = 'BAT Scenario Run Result' ).
  ENDTRY.

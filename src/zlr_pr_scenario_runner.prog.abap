REPORT zlr_pr_scenario_runner.

TYPE-POOLS: vrm.

DATA gv_last_libcls TYPE seoclsname.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_libcls TYPE seoclsname.
PARAMETERS p_scen   TYPE c LENGTH 20 AS LISTBOX VISIBLE LENGTH 60.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS p_pernr TYPE c LENGTH 20 LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

" No default lookup yet -- ZLR_TSCENLIB doesn't exist. Everyone types
" their own class name into p_libcls for now.

AT SELECTION-SCREEN ON p_libcls.
  DATA lo_check TYPE REF TO object.
  DATA li_check TYPE REF TO zlr_if_scenario_library.
  TRY.
      CREATE OBJECT lo_check TYPE (p_libcls).
      li_check ?= lo_check.
    CATCH cx_sy_create_object_error.
      MESSAGE |{ p_libcls } does not exist or cannot be instantiated| TYPE 'E'.
    CATCH cx_sy_move_cast_error.
      MESSAGE |{ p_libcls } does not implement ZLR_IF_SCENARIO_LIBRARY| TYPE 'E'.
  ENDTRY.

AT SELECTION-SCREEN OUTPUT.
  DATA lt_listbox_values TYPE vrm_values.
  DATA lo_instance       TYPE REF TO object.
  DATA li_library_output TYPE REF TO zlr_if_scenario_library.

  " The library actually changed since the last redraw -- forget
  " whatever scenario was picked under the previous library.
  IF p_libcls <> gv_last_libcls.
    CLEAR p_scen.
    gv_last_libcls = p_libcls.
  ENDIF.

  IF p_libcls IS NOT INITIAL.
    TRY.
        CREATE OBJECT lo_instance TYPE (p_libcls).
        li_library_output ?= lo_instance.

        LOOP AT li_library_output->get_scenario_catalog( ) INTO DATA(ls_catalog_entry).
          APPEND VALUE #( key  = ls_catalog_entry-name
                          text = ls_catalog_entry-description ) TO lt_listbox_values.
        ENDLOOP.
      CATCH cx_sy_create_object_error cx_sy_move_cast_error.
        CLEAR lt_listbox_values.
    ENDTRY.
  ENDIF.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_SCEN'
      values = lt_listbox_values.

START-OF-SELECTION.

  DATA lo_runtime_instance TYPE REF TO object.
  DATA li_library          TYPE REF TO zlr_if_scenario_library.
  DATA(lo_runner)          = NEW zlr_cl_scenario_runner( ).

  TRY.
      CREATE OBJECT lo_runtime_instance TYPE (p_libcls).
      li_library ?= lo_runtime_instance.

      DATA(ls_scenario) = li_library->build_scenario( CONV string( p_scen ) ).

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

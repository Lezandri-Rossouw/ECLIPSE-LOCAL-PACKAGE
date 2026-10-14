CLASS zcl_clsf_exception_list_member DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /egs/if_clsf_classifier.

    CONSTANTS c_match    TYPE string VALUE 'MATCH'.
    CONSTANTS c_no_match TYPE string VALUE 'NO_MATCH'.

    TYPES ty_tab_values TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    METHODS constructor
      IMPORTING iv_metric_key      TYPE string
                it_approved_values TYPE ty_tab_values.

    METHODS get_metric_key
      RETURNING VALUE(rv_result) TYPE string.

    METHODS get_approved_values
      RETURNING VALUE(rt_result) TYPE ty_tab_values.

  PRIVATE SECTION.
    DATA mv_metric_key      TYPE string.
    DATA mt_approved_values TYPE ty_tab_values.

    METHODS find_slice_value
      IMPORTING it_slices        TYPE /egs/if_han_bts_base=>ty_tab_slice_data
                iv_begin_date    TYPE d
      RETURNING VALUE(rv_result) TYPE string.

ENDCLASS.

CLASS zcl_clsf_exception_list_member IMPLEMENTATION.

  METHOD constructor.
    mv_metric_key      = iv_metric_key.
    mt_approved_values = it_approved_values.
  ENDMETHOD.

  METHOD get_metric_key.
    rv_result = mv_metric_key.
  ENDMETHOD.

  METHOD get_approved_values.
    rt_result = mt_approved_values.
  ENDMETHOD.

  METHOD /egs/if_clsf_classifier~classify.
    rv_result = c_no_match.

    IF ii_bts IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(li_personnel_data) = NEW /egs/cl_han_bts_personnel_data( ii_bts ).

    TRY.
        DATA(lr_slices) = li_personnel_data->read_personnel_key_table(
                              it_personnel_metric_keys = VALUE #( ( mv_metric_key ) )
                              iv_pernr                 = iv_pernr
                              iv_begin_date            = iv_begin_date
                              iv_end_date              = iv_end_date ).

      CATCH /egs/cx_exc_empty_result INTO DATA(lx_empty).
        IF lx_empty->get_msg_id( ) = /egs/cl_util_validation=>c_han_msg_id
           AND lx_empty->get_msg_no( ) = '022'.
          RETURN.  " no data at all -> can't be on the list, NO_MATCH
        ENDIF.
        RAISE EXCEPTION lx_empty.
    ENDTRY.

    IF lr_slices IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lv_value) = find_slice_value( it_slices = lr_slices->* iv_begin_date = iv_begin_date ).

    IF line_exists( mt_approved_values[ table_line = lv_value ] ).
      rv_result = c_match.
    ENDIF.
  ENDMETHOD.

  METHOD find_slice_value.
    LOOP AT it_slices INTO DATA(ls_slice)
         WHERE begin <= iv_begin_date
           AND ( end = 0 OR end > iv_begin_date ).

      READ TABLE ls_slice-data_map INTO DATA(ls_entry) WITH TABLE KEY key = mv_metric_key.
      IF sy-subrc = 0 AND ls_entry-value IS BOUND.
        rv_result = ls_entry-value->to_string( ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

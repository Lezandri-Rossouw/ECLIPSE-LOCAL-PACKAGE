CLASS lcl_bld_zim_nssa_integration DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES /egs/if_scen_builder.
ENDCLASS.

CLASS lcl_bld_zim_nssa_integration IMPLEMENTATION.
  METHOD /egs/if_scen_builder~build.

*    DATA(lo_ledger) = zlr_cl_pri_segment_registry=>get_provider( iv_library = 'LEDGER_BRIDGE' io_provider = NEW zlr_cl_lib_ledger( ) ).
*    DATA(lo_nssa) = zlr_cl_pri_segment_registry=>get_provider( iv_library = 'NSSA' io_provider = NEW zlr_cl_lib_nssa( ) ).
*
*    DATA(ls_ledger) = lo_ledger->segment_plan_composite( ).
*    DATA(ls_nssa)   = lo_nssa->segment_plan_composite( ).

*    rs_result-personnel_id          = '00000001'.
*    rs_result-processing_begin_date = '20260101'.
*    rs_result-processing_end_date   = '20260201'.
*    rs_result-current_seq           = '01'.
*    rs_result-master_badi_data      = zlr_cl_lib_zim_shared_input=>get_master_data( ).
*
*    rs_result-plans = VALUE #(
*        ( plan_definition = NEW /egs/cl_cmd_composite(
*              iv_list_name = 'ZIM_PAYROLL_PLAN'
*              it_children  = VALUE #(
*                  ( zlr_cl_lib_zim_shared_input=>declare_all( ) )
*                  ( NEW zlr_cl_lib_ledger( )->segment_plan_composite( ) )
*                  ( NEW zlr_cl_lib_nssa( )->segment_plan_composite( ) )
*                  " ( paye segment slots in here next )
*                  ) )
*          plan_begin_date = zlr_if_pri_plan_segment=>c_sot_date
*          plan_end_date   = zlr_if_pri_plan_segment=>c_eot_date
*          config_data     = zlr_cl_lib_zim_shared_input=>get_config( )
*          input_badi_data = zlr_cl_lib_zim_shared_input=>get_input_data( ) ) ).

  ENDMETHOD.
ENDCLASS.

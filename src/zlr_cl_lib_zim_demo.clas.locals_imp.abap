CLASS lcl_demo_plans DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS config_data
      RETURNING VALUE(rt_result) TYPE /egs/if_scen_config_data=>ty_struc_config_input
      RAISING   cx_static_check.

    CLASS-METHODS get_a_plan
      IMPORTING iv_a1            TYPE decfloat16
                iv_a2            TYPE decfloat16
      RETURNING VALUE(ro_result) TYPE REF TO /egs/cl_cmd_composite
      RAISING   cx_static_check.

    CLASS-METHODS get_b_plan
      IMPORTING iv_b1            TYPE decfloat16
                iv_b2            TYPE decfloat16
      RETURNING VALUE(ro_result) TYPE REF TO /egs/cl_cmd_composite
      RAISING   cx_static_check.

    CLASS-METHODS get_net_plan
      RETURNING VALUE(ro_result) TYPE REF TO /egs/cl_cmd_composite
      RAISING   cx_static_check.

    CLASS-METHODS get_error_plan
      RETURNING VALUE(ro_result) TYPE REF TO /egs/cl_cmd_composite
      RAISING   cx_static_check.

  PRIVATE SECTION.
    CONSTANTS c_currency TYPE string VALUE `ZWG`.

    CLASS-METHODS amount
      IMPORTING iv_value         TYPE decfloat16
      RETURNING VALUE(ro_result) TYPE REF TO /egs/cl_enc_dimension_amount
      RAISING   cx_static_check.
ENDCLASS.

CLASS lcl_demo_plans IMPLEMENTATION.

  METHOD amount.
    ro_result = /egs/cl_enc_dimension_amount=>create( iv_value     = iv_value
                                                      it_numerator = VALUE #( ( c_currency ) ) ).
  ENDMETHOD.

  METHOD config_data.
    rt_result = /egs/cl_zw_configuration_data=>change_config_value( it_overrides = VALUE #(
        ( key            = 'DEMO_A_ACTION_RULE'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( NEW /egs/if_prs_input=>ty_struc_action_rule( action_dr_path = 'L/SALARIES_AND_WAGES'
                                                                                                                 action_cr_path = 'L/DEMO_A' ) ) )
        ( key            = 'DEMO_B_ACTION_RULE'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( NEW /egs/if_prs_input=>ty_struc_action_rule( action_dr_path = 'L/SALARIES_AND_WAGES'
                                                                                                                 action_cr_path = 'L/DEMO_B' ) ) )
        ( key            = 'DEMO_NET_ACTION_RULE'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( NEW /egs/if_prs_input=>ty_struc_action_rule( action_dr_path = 'L/SALARIES_AND_WAGES'
                                                                                                                 action_cr_path = 'L/DEMO_NET' ) ) )
        ( key            = 'DEMO_A_PATH'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( 'L/DEMO_A' ) )
        ( key            = 'DEMO_B_PATH'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( 'L/DEMO_B' ) )
        ( key            = 'DEMO_NET_PATH'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref( 'L/DEMO_NET' ) )
        ( key            = 'NSSA_INSURABLE_EARNINGS'
          temp_value_ref = /egs/cl_util_obj_helper=>create_data_ref(
                               VALUE /egs/if_han_bts_ledger=>ty_tab_classification( type = /egs/if_han_bts_ledger=>c_timing_basis-when_earned
                                                                                    ( path = 'E/SALARY' )
                                                                                    ( path = 'E/OVERTIME' ) ) ) ) ) ).
  ENDMETHOD.

  METHOD get_a_plan.
    ro_result = NEW /egs/cl_cmd_composite(
        iv_list_name = 'DEMO_GET_A_PLAN'
        it_children  = VALUE #(
            ( /egs/cl_zw_configuration_data=>declare_global_plan( ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_A_ACTION_RULE' ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_A_PATH' ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_A1'
                                          iv_data = amount( iv_a1 ) ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_A2'
                                          iv_data = amount( iv_a2 ) ) )
            ( NEW /egs/cl_cmd_sum( iv_num1_key   = 'DEMO_A1'
                                   iv_num2_key   = 'DEMO_A2'
                                   iv_result_key = 'DEMO_A' ) )
            ( NEW /egs/cl_cmd_get_balance( iv_account_path_key   = 'DEMO_A_PATH'
                                           iv_currency_key       = 'PAYROLL_CURRENCY'
                                           iv_validity_begin_key = 'PROCESSING_BEGIN_DATE'
                                           iv_validity_end_key   = 'SLICE_END_DATE'
                                           iv_result_key         = 'DEMO_A_PTD' ) )
            ( NEW /egs/cl_cmd_subtract( iv_num1_key   = 'DEMO_A'
                                        iv_num2_key   = 'DEMO_A_PTD'
                                        iv_result_key = 'DEMO_A_DELTA' ) )
            ( NEW /egs/cl_cmd_write_journal( iv_acc_action_key = 'DEMO_A_ACTION_RULE'
                                             iv_amount_key     = 'DEMO_A_DELTA'
                                             iv_date_key       = 'SLICE_BEGIN_DATE'
                                             iv_unit_table_key = 'CONFIG_DECIMAL_UNIT_TABLE' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A1' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A2' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A_PTD' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A_DELTA' ) ) ) ).
  ENDMETHOD.

  METHOD get_b_plan.
    ro_result = NEW /egs/cl_cmd_composite(
        iv_list_name = 'DEMO_GET_B_PLAN'
        it_children  = VALUE #(
            ( /egs/cl_zw_configuration_data=>declare_global_plan( ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_B_ACTION_RULE' ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_B_PATH' ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_B1'
                                          iv_data = amount( iv_b1 ) ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_B2'
                                          iv_data = amount( iv_b2 ) ) )
            ( NEW /egs/cl_cmd_sum( iv_num1_key   = 'DEMO_B1'
                                   iv_num2_key   = 'DEMO_B2'
                                   iv_result_key = 'DEMO_B' ) )
            ( NEW /egs/cl_cmd_get_balance( iv_account_path_key   = 'DEMO_B_PATH'
                                           iv_currency_key       = 'PAYROLL_CURRENCY'
                                           iv_validity_begin_key = 'PROCESSING_BEGIN_DATE'
                                           iv_validity_end_key   = 'SLICE_END_DATE'
                                           iv_result_key         = 'DEMO_B_PTD' ) )
            ( NEW /egs/cl_cmd_subtract( iv_num1_key   = 'DEMO_B'
                                        iv_num2_key   = 'DEMO_B_PTD'
                                        iv_result_key = 'DEMO_B_DELTA' ) )
            ( NEW /egs/cl_cmd_write_journal( iv_acc_action_key = 'DEMO_B_ACTION_RULE'
                                             iv_amount_key     = 'DEMO_B_DELTA'
                                             iv_date_key       = 'SLICE_BEGIN_DATE'
                                             iv_unit_table_key = 'CONFIG_DECIMAL_UNIT_TABLE' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B1' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B2' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B_PTD' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B_DELTA' ) ) ) ).
  ENDMETHOD.

  METHOD get_net_plan.
    ro_result = NEW /egs/cl_cmd_composite(
        iv_list_name = 'DEMO_GET_NET_PLAN'
        it_children  = VALUE #(
            ( /egs/cl_zw_configuration_data=>declare_global_plan( ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_A_PATH' ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_B_PATH' ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_NET_ACTION_RULE' ) )
            ( NEW /egs/cl_cmd_define_config( 'DEMO_NET_PATH' ) )
            ( NEW /egs/cl_cmd_get_balance( iv_account_path_key   = 'DEMO_A_PATH'
                                           iv_currency_key       = 'PAYROLL_CURRENCY'
                                           iv_validity_begin_key = 'PROCESSING_BEGIN_DATE'
                                           iv_validity_end_key   = 'SLICE_END_DATE'
                                           iv_result_key         = 'DEMO_A_POSTED' ) )
            ( NEW /egs/cl_cmd_get_balance( iv_account_path_key   = 'DEMO_B_PATH'
                                           iv_currency_key       = 'PAYROLL_CURRENCY'
                                           iv_validity_begin_key = 'PROCESSING_BEGIN_DATE'
                                           iv_validity_end_key   = 'SLICE_END_DATE'
                                           iv_result_key         = 'DEMO_B_POSTED' ) )
            ( NEW /egs/cl_cmd_subtract( iv_num1_key   = 'DEMO_A_POSTED'
                                        iv_num2_key   = 'DEMO_B_POSTED'
                                        iv_result_key = 'DEMO_NET' ) )
            ( NEW /egs/cl_cmd_get_balance( iv_account_path_key   = 'DEMO_NET_PATH'
                                           iv_currency_key       = 'PAYROLL_CURRENCY'
                                           iv_validity_begin_key = 'PROCESSING_BEGIN_DATE'
                                           iv_validity_end_key   = 'SLICE_END_DATE'
                                           iv_result_key         = 'DEMO_NET_PTD' ) )
            ( NEW /egs/cl_cmd_subtract( iv_num1_key   = 'DEMO_NET'
                                        iv_num2_key   = 'DEMO_NET_PTD'
                                        iv_result_key = 'DEMO_NET_DELTA' ) )
            ( NEW /egs/cl_cmd_write_journal( iv_acc_action_key = 'DEMO_NET_ACTION_RULE'
                                             iv_amount_key     = 'DEMO_NET_DELTA'
                                             iv_date_key       = 'SLICE_BEGIN_DATE'
                                             iv_unit_table_key = 'CONFIG_DECIMAL_UNIT_TABLE' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A_POSTED' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_B_POSTED' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_NET' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_NET_PTD' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_NET_DELTA' ) ) ) ).
  ENDMETHOD.

  METHOD get_error_plan.
    ro_result = NEW /egs/cl_cmd_composite(
        iv_list_name = 'DEMO_ERROR_PLAN'
        it_children  = VALUE #(
            ( /egs/cl_zw_configuration_data=>declare_global_plan( ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_A1'
                                          iv_data = amount( CONV #( '200' ) ) ) )
            ( NEW /egs/cl_cmd_store_data( iv_key  = 'DEMO_A2'
                                          iv_data = amount( CONV #( '100' ) ) ) )
            ( NEW /egs/cl_cmd_sum( iv_num1_key   = 'DEMO_A1'
                                   iv_num2_key   = 'DEMO_A3'
                                   iv_result_key = 'DEMO_A' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A1' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A2' ) )
            ( NEW /egs/cl_cmd_fetch_data( 'DEMO_A' ) ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lcl_bld_demo_one_one DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES /egs/if_scen_builder.
ENDCLASS.

CLASS lcl_bld_demo_one_one IMPLEMENTATION.
  METHOD /egs/if_scen_builder~build.

    rs_result-personnel_id     = '00000001'.
    rs_result-master_badi_data = /egs/cl_zw_configuration_data=>get_master_data( ).

    rs_result-periods = VALUE #(
        ( processing_begin_date = '20260101'
          processing_end_date   = '20260201'
          current_seq           = '01'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_a_plan( iv_a1 = CONV #( '200' )
                                                              iv_a2 = CONV #( '100' ) ) ) ) ) ).

  ENDMETHOD.
ENDCLASS.

CLASS lcl_bld_demo_one_two DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES /egs/if_scen_builder.
ENDCLASS.

CLASS lcl_bld_demo_one_two IMPLEMENTATION.
  METHOD /egs/if_scen_builder~build.

    rs_result-personnel_id     = '00000001'.
    rs_result-master_badi_data = /egs/cl_zw_configuration_data=>get_master_data( ).

    rs_result-periods = VALUE #(
        ( processing_begin_date = '20260101'
          processing_end_date   = '20260201'
          current_seq           = '01'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_a_plan( iv_a1 = CONV #( '200' )
                                                              iv_a2 = CONV #( '100' ) ) ) ) )

        ( processing_begin_date = '20260201'
          processing_end_date   = '20260301'
          current_seq           = '02'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_a_plan( iv_a1 = CONV #( '250' )
                                                              iv_a2 = CONV #( '100' ) ) ) ) ) ).

  ENDMETHOD.
ENDCLASS.

CLASS lcl_bld_demo_multi_two DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES /egs/if_scen_builder.
ENDCLASS.

CLASS lcl_bld_demo_multi_two IMPLEMENTATION.
  METHOD /egs/if_scen_builder~build.

    rs_result-personnel_id     = '00000001'.
    rs_result-master_badi_data = /egs/cl_zw_configuration_data=>get_master_data( ).

    rs_result-periods = VALUE #(
        ( processing_begin_date = '20260101'
          processing_end_date   = '20260201'
          current_seq           = '01'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_a_plan( iv_a1 = CONV #( '200' )
                                                              iv_a2 = CONV #( '100' ) ) )
              ( plan_definition = lcl_demo_plans=>get_b_plan( iv_b1 = CONV #( '80' )
                                                              iv_b2 = CONV #( '40' ) ) )
              ( plan_definition = lcl_demo_plans=>get_net_plan( ) ) ) )

        ( processing_begin_date = '20260201'
          processing_end_date   = '20260301'
          current_seq           = '02'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_a_plan( iv_a1 = CONV #( '250' )
                                                              iv_a2 = CONV #( '100' ) ) )
              ( plan_definition = lcl_demo_plans=>get_b_plan( iv_b1 = CONV #( '80' )
                                                              iv_b2 = CONV #( '60' ) ) )
              ( plan_definition = lcl_demo_plans=>get_net_plan( ) ) ) ) ).

  ENDMETHOD.
ENDCLASS.

CLASS lcl_bld_demo_error DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES /egs/if_scen_builder.
ENDCLASS.

CLASS lcl_bld_demo_error IMPLEMENTATION.
  METHOD /egs/if_scen_builder~build.

    rs_result-personnel_id     = '00000001'.
    rs_result-master_badi_data = /egs/cl_zw_configuration_data=>get_master_data( ).

    rs_result-periods = VALUE #(
        ( processing_begin_date = '20260101'
          processing_end_date   = '20260201'
          current_seq           = '01'
          plans = VALUE #(
                plan_begin_date = /egs/if_scen_config_data=>c_sot_date
                plan_end_date   = /egs/if_scen_config_data=>c_eot_date
                config_data     = lcl_demo_plans=>config_data( )
                input_badi_data = /egs/cl_zw_configuration_data=>get_input_data( )
              ( plan_definition = lcl_demo_plans=>get_error_plan( ) ) ) ) ).

  ENDMETHOD.
ENDCLASS.

interface ZLR_SCENARIO_GLOBAL_DATA
  public .

  TYPES: BEGIN OF ty_struc_config_path,
             key   TYPE string,
             value TYPE string,
           END OF ty_struc_config_path,
           ty_tab_config_path TYPE STANDARD TABLE OF ty_struc_config_path WITH EMPTY KEY.

    TYPES: BEGIN OF ty_struc_config_action_rule,
             key     TYPE string,
             dr_path TYPE string,
             cr_path TYPE string,
           END OF ty_struc_config_action_rule,
           ty_tab_config_action_rule TYPE STANDARD TABLE OF ty_struc_config_action_rule WITH EMPTY KEY.

    TYPES: BEGIN OF ty_struc_config_absence_rule,
             key   TYPE string,
             rules TYPE /egs/cl_cmd_deduct_absences=>ty_tab_absence_config,
           END OF ty_struc_config_absence_rule,
           ty_tab_config_absence_rule TYPE STANDARD TABLE OF ty_struc_config_absence_rule WITH EMPTY KEY.

    TYPES: BEGIN OF ty_struc_config_custom_entries,
             begin_date TYPE d,
             end_date   TYPE d,
             key        TYPE string,
             value      TYPE REF TO data,
           END OF ty_struc_config_custom_entries,
           ty_tab_config_custom_entries TYPE STANDARD TABLE OF ty_struc_config_custom_entries WITH EMPTY KEY.

    TYPES: BEGIN OF ty_struc_config_conversion_tab,
             key   TYPE string,
             value TYPE /egs/cl_util_dim_amount_calcs=>ty_tab_conversion_rules,
           END OF ty_struc_config_conversion_tab.

    TYPES: BEGIN OF ty_struc_config_unit_decimal,
             key   TYPE string,
             value TYPE /egs/cl_util_dim_amount_calcs=>ty_tab_unit_table,
           END OF ty_struc_config_unit_decimal.

           TYPES: BEGIN OF ty_struc_config_input,
             conversion_table   TYPE ty_struc_config_conversion_tab,
             unit_decimal_table TYPE ty_struc_config_unit_decimal,
             absence_rules      TYPE ty_tab_config_absence_rule,
             action_rules       TYPE ty_tab_config_action_rule,
             paths              TYPE ty_tab_config_path,
             custom_entries     TYPE ty_tab_config_custom_entries,
           END OF ty_struc_config_input.

endinterface.

INTERFACE zlr_if_scenario_library
  PUBLIC.

  TYPES: BEGIN OF ty_struc_catalog_entry,
           name        TYPE c LENGTH 20,
           description TYPE string,
         END OF ty_struc_catalog_entry,
         ty_tab_catalog_entry TYPE STANDARD TABLE OF ty_struc_catalog_entry WITH EMPTY KEY.

  METHODS get_scenario_catalog
    RETURNING VALUE(rt_result) TYPE ty_tab_catalog_entry.

  METHODS build_scenario
    IMPORTING iv_scenario_name TYPE string
    RETURNING VALUE(rs_result) TYPE zlr_cl_scenario_runner=>ty_struc_scenario
    RAISING   cx_static_check.

  METHODS execute_scenario
    IMPORTING iv_scenario_name TYPE string
    RETURNING VALUE(rs_result) TYPE zlr_cl_scenario_runner=>ty_struc_run_result
    RAISING   cx_static_check.
ENDINTERFACE.

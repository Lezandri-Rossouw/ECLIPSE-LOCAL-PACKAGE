INTERFACE zlr_if_scenario_builder
  PUBLIC.

  METHODS build
    RETURNING VALUE(rs_result) TYPE zlr_cl_scenario_runner=>ty_struc_scenario
    RAISING   cx_static_check.
ENDINTERFACE.

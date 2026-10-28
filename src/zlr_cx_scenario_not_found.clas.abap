CLASS zlr_cx_scenario_not_found DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_scenario_name TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING iv_scenario_name TYPE string
                previous        TYPE REF TO cx_root OPTIONAL.
ENDCLASS.

CLASS zlr_cx_scenario_not_found IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_scenario_name = iv_scenario_name.
  ENDMETHOD.
ENDCLASS.

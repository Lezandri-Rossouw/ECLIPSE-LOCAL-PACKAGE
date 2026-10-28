CLASS zcx_pri_config_mismatch DEFINITION
  PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA mv_detail TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING iv_detail TYPE string
                previous  TYPE REF TO cx_root OPTIONAL.
ENDCLASS.

CLASS zcx_pri_config_mismatch IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_detail = iv_detail.
  ENDMETHOD.
ENDCLASS.

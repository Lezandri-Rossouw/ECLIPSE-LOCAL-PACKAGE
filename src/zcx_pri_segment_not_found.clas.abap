CLASS zcx_pri_segment_not_found DEFINITION
  PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    DATA mv_library TYPE string READ-ONLY.
    DATA mv_segment TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING iv_library TYPE string
                iv_segment TYPE string
                previous   TYPE REF TO cx_root OPTIONAL.
ENDCLASS.

CLASS zcx_pri_segment_not_found IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_library = iv_library.
    mv_segment = iv_segment.
  ENDMETHOD.
ENDCLASS.

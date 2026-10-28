CLASS zcx_prs_unmapped_value DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_value TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING iv_value TYPE string OPTIONAL
                previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.

CLASS zcx_prs_unmapped_value IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_value = iv_value.
  ENDMETHOD.

ENDCLASS.

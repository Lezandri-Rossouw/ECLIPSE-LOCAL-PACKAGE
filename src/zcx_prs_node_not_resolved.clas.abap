CLASS zcx_prs_node_not_resolved DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_class_name TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING iv_class_name TYPE string OPTIONAL
                previous      TYPE REF TO cx_root OPTIONAL.

ENDCLASS.

CLASS zcx_prs_node_not_resolved IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_class_name = iv_class_name.
  ENDMETHOD.

ENDCLASS.

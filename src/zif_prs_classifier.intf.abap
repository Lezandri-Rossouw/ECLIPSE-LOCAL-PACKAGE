INTERFACE zif_prs_classifier
  PUBLIC.

  METHODS classify
    IMPORTING iv_pernr         TYPE string
              iv_begin_date    TYPE d
              iv_end_date      TYPE d
              ii_bts           TYPE REF TO /egs/if_bts_store OPTIONAL
    RETURNING VALUE(rv_result) TYPE string
    RAISING   cx_static_check.

ENDINTERFACE.

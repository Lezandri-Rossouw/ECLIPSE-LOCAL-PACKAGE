INTERFACE zif_prs_resolvable
  PUBLIC.

  METHODS resolve
    IMPORTING iv_pernr         TYPE string
              iv_begin_date    TYPE d
              iv_end_date      TYPE d
              ii_bts           TYPE REF TO /egs/if_bts_store OPTIONAL
    RETURNING VALUE(rt_result) TYPE /egs/cl_cmd_base=>ty_tab_cmd_list
    RAISING   cx_static_check.

ENDINTERFACE.

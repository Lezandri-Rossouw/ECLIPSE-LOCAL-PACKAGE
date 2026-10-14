CLASS zlr_cl_lib_zim_demo DEFINITION
  PUBLIC INHERITING FROM /egs/cl_scen_library_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor.

    CONSTANTS: c_sce_demo_one_one   TYPE string VALUE 'ONE_PLAN_PERIOD',
               c_sce_demo_one_two   TYPE string VALUE 'ONE_PLAN_TWO_PERIODS',
               c_sce_demo_multi_two TYPE string VALUE 'MULTI_PLAN_PERIODS',
               c_sce_demo_error     TYPE string VALUE 'ERROR_PLAN'.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS zlr_cl_lib_zim_demo IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mt_registry = VALUE #(
  ( name        = c_sce_demo_one_one
    description = 'DEMO - GET_A plan with ledger posting, one period'
    builder     = NEW lcl_bld_demo_one_one( ) )
  ( name        = c_sce_demo_one_two
    description = 'DEMO - GET_A plan with ledger posting, two periods'
    builder     = NEW lcl_bld_demo_one_two( ) )
  ( name        = c_sce_demo_multi_two
    description = 'DEMO - GET_A + GET_B + GET_NET via ledger, two periods'
    builder     = NEW lcl_bld_demo_multi_two( ) )
  ( name        = c_sce_demo_error
    description = 'DEMO - sum reads a key that was never stored, triggers error handling'
    builder     = NEW lcl_bld_demo_error( ) ) ).
  ENDMETHOD.

ENDCLASS.

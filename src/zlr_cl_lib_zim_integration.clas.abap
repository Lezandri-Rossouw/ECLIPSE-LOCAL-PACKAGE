CLASS zlr_cl_lib_zim_integration DEFINITION
  PUBLIC INHERITING FROM /egs/cl_scen_library_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor.
    CONSTANTS c_sce_zim_nssa_integration TYPE string VALUE 'ZIM_NSSA_INTEGRATION'.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS zlr_cl_lib_zim_integration IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mt_registry = VALUE #(
      ( name        = c_sce_zim_nssa_integration
        description = 'Ledger bridge + NSSA - one payroll pass, shared config from ZIM_SHARED_INPUT'
        builder     = NEW lcl_bld_zim_nssa_integration( ) ) ).
  ENDMETHOD.

ENDCLASS.

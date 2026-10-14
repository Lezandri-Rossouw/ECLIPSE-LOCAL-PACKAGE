*&---------------------------------------------------------------------*
*& Report zlr_unit_test_runner
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zlr_unit_test_runner.

PARAMETERS: p_pkg TYPE devclass  DEFAULT '/EGS/DP_CMD'.

START-OF-SELECTION.

  " Build the object set referencing the package
  DATA: ls_obj_set  TYPE if_adt_tools_core_types=>ty_object_set.
  DATA: ls_obj_ref  TYPE if_adt_tools_core_types=>ty_object_reference.

  ls_obj_ref-package_name = p_pkg.
  ls_obj_ref-type = 'DEVC/K'.  " ABAP package object type
  ls_obj_set-kind = 'PACKAGE'.
  APPEND ls_obj_ref TO ls_obj_set-object_references.

  " Build the run config request
  DATA: ls_request TYPE if_aunit_adt_types=>ty_run_config_request.
  APPEND ls_obj_set TO ls_request-object_sets.

  " Execute
  DATA(lo_runner) = NEW cl_aunit_adt_res_test_runs( ).
  " Execute and capture result
  DATA: ls_response TYPE if_aunit_adt_types=>ty_run_config_response.

  lo_runner->execute_tests(
    EXPORTING
      request_data  = ls_request
    IMPORTING
      response_data = ls_response
  ).

  " Log results - iterate over programs
  LOOP AT ls_response-programs INTO DATA(ls_program).
    WRITE: / ls_program-name.

    " Iterate over test classes within each program
    LOOP AT ls_program-test_classes INTO DATA(ls_class).
      LOOP AT ls_class-test_methods INTO DATA(ls_method).
        WRITE: / ls_method-name, ls_method-type, ls_method-duration, ls_method-duration_unit.

        " Log any method-level alerts
        LOOP AT ls_method-alerts INTO DATA(ls_alert).
          WRITE: / '  Alert:', ls_alert-kind, ls_alert-severity.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.

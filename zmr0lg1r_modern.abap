*&---------------------------------------------------------------------*
*& Report ZMR0LG1R_MODERN
*&---------------------------------------------------------------------*
*& Description: Update Storage Location Desc.
*& Refactored for S/4HANA, ABAP 7.50+ Syntax, and OO Patterns
*&---------------------------------------------------------------------*
REPORT zmr0lg1r_modern MESSAGE-ID z4.

*----------------------------------------------------------------------*
* Global Data (Tables needed for VIEW_MAINTENANCE_CALL types)
*----------------------------------------------------------------------*
* TABLES statement removed as it is obsolete for data declaration.
* Using types from DDIC directly.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
CONSTANTS: c_display  TYPE char1   VALUE 'S',
           c_update   TYPE char1   VALUE 'U',
           c_zv_t001l TYPE tabname VALUE 'ZV_T001L'.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_werks TYPE werks_d OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Local Class Definition
*----------------------------------------------------------------------*
CLASS lcl_sloc_manager DEFINITION.
  PUBLIC SECTION.
    METHODS: constructor IMPORTING iv_werks TYPE werks_d,
             run.

  PRIVATE SECTION.
    DATA: mv_werks TYPE werks_d,
          mv_action TYPE char1.

    DATA: mt_dba_sellist    TYPE STANDARD TABLE OF vimsellist,
          mt_excl_cua_funct TYPE STANDARD TABLE OF vimexclfun.

    METHODS: check_auth,
             check_role,
             call_view_maintenance.
ENDCLASS.

*----------------------------------------------------------------------*
* Local Class Implementation
*----------------------------------------------------------------------*
CLASS lcl_sloc_manager IMPLEMENTATION.

  METHOD constructor.
    mv_werks = iv_werks.
  ENDMETHOD.

  METHOD run.
    " Initial Authorization Check at Plant Level
    AUTHORITY-CHECK OBJECT 'M_MATE_WRK'
             ID 'ACTVT' FIELD '03'
             ID 'WERKS' FIELD mv_werks.
    IF sy-subrc <> 0.
      MESSAGE e000(z4) WITH TEXT-e01 mv_werks.
      " 'No authorization for plant'
      RETURN.
    ENDIF.

    check_auth( ).

    IF mv_action EQ c_display AND sy-modno EQ '0'.
      " do nothing - Skip batch input if display only logic from legacy
    ELSE.
      call_view_maintenance( ).
    ENDIF.
  ENDMETHOD.

  METHOD check_auth.
    " Prepare selection for view maintenance
    CLEAR mt_dba_sellist.
    APPEND VALUE #( viewfield = 'WERKS'
                    operator  = 'EQ'
                    value     = mv_werks ) TO mt_dba_sellist.

    " Check Custom Plant Table
    SELECT SINGLE mm_maintainer, mm_maintainer2,
                  plant_contact, plant_contact2,
                  pm_manager, pm_manager2
      FROM zmcplant
      INTO @DATA(ls_plant)
      WHERE werks = @mv_werks.

    IF sy-subrc <> 0.
      check_role( ).
    ELSE.
      IF sy-uname = ls_plant-mm_maintainer  OR
         sy-uname = ls_plant-mm_maintainer2 OR
         sy-uname = ls_plant-plant_contact  OR
         sy-uname = ls_plant-plant_contact2 OR
         sy-uname = ls_plant-pm_manager     OR
         sy-uname = ls_plant-pm_manager2.
        mv_action = c_update.
      ELSE.
        check_role( ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD check_role.
    DATA: lv_agr_name TYPE agr_name.

    " Check for specific role assignment
    " Using UP TO 1 ROWS with ORDER BY PRIMARY KEY for strict SQL compliance
    SELECT agr_name
      INTO @lv_agr_name
      FROM agr_users
      WHERE agr_name LIKE '%IMSUU000' " Role pattern
        AND to_dat   >= @sy-datum
        AND uname     = @sy-uname
      ORDER BY PRIMARY KEY
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc = 0.
      mv_action = c_update.
    ELSE.
      MESSAGE i000(z4) WITH TEXT-er2
                            sy-uname
                            TEXT-er3
                            mv_werks.
      mv_action = c_display.

      " Exclude update functions if only display
      CLEAR mt_excl_cua_funct.
      APPEND VALUE #( function = 'AEND' ) TO mt_excl_cua_funct.
    ENDIF.
  ENDMETHOD.

  METHOD call_view_maintenance.
    CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
      EXPORTING
        action         = mv_action
        view_name      = c_zv_t001l
      TABLES
        dba_sellist    = mt_dba_sellist
        excl_cua_funct = mt_excl_cua_funct
      EXCEPTIONS
        client_reference = 1
        foreign_lock     = 2
        invalid_action   = 3
        no_clientindependent_auth = 4
        no_database_function = 5
        no_editor_function = 6
        no_show_auth     = 7
        no_tvdir_entry   = 8
        no_upd_auth      = 9
        only_show_allowed = 10
        system_failure   = 11
        unknown_field_in_dba_sellist = 12
        view_not_found   = 13
        maintenance_prohibited = 14
        OTHERS           = 15.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
*  INCLUDE zux0ac1r. " Removed external include dependency, assuming standard init

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  NEW lcl_sloc_manager( iv_werks = p_werks )->run( ).

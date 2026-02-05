*&---------------------------------------------------------------------*
*& Report ZMU0POMR_MODERN
*&---------------------------------------------------------------------*
*& Description: Interface program to load data into ZMFPDATA.
*& Refactored for S/4HANA and ABAP 7.50+ Syntax
*&---------------------------------------------------------------------*
REPORT zmu0pomr_modern LINE-SIZE 170 NO STANDARD PAGE HEADING MESSAGE-ID zl.

* Tables for Selection Screen
TABLES: zmfpdata, zifap, zusrsmtp, zmfpfarm, t001w.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
CONSTANTS: c_delimiter TYPE c VALUE '|'.
CONSTANTS: c_probclass_very_high TYPE bal_s_msg-probclass VALUE '1',
           c_probclass_high      TYPE bal_s_msg-probclass VALUE '2',
           c_probclass_medium    TYPE bal_s_msg-probclass VALUE '3',
           c_probclass_low       TYPE bal_s_msg-probclass VALUE '4',
           c_probclass_none      TYPE bal_s_msg-probclass VALUE ' '.
CONSTANTS: c_msn_apl  TYPE sy-msgno       VALUE '001'.
CONSTANTS: c_object   TYPE bal_s_log-object VALUE 'ZMFP',
           c_sobj_crt TYPE bal_s_log-object VALUE 'FARMOUT'.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_farm_out,
         ebeln         TYPE ekpo-ebeln,
         ebelp         TYPE ekpo-ebelp,
         dotyp(15)     TYPE c,
         aufnr         TYPE afko-aufnr,
         popno(4)      TYPE c,
         lpst_d(8)     TYPE c,
         l_time(4)     TYPE c,
         d_date(8)     TYPE c,
         lpct          TYPE zmfpfarm-lpct,
         pst           TYPE zmfpfarm-pst,
         matnr         TYPE zmfpfarm-matnr,
         order_qty(16) TYPE c,
         plnnr         TYPE zmfpfarm-plnnr,
         plnal         TYPE zmfpfarm-plnal,
         plnfl         TYPE zmfpfarm-plnfl,
         res           TYPE zmfpfarm-arbpl,
         werks         TYPE zmfpfarm-dwerk,
       END OF ty_farm_out.

TYPES: BEGIN OF ty_caufv,
         aufnr  TYPE caufv-aufnr,
         werks  TYPE caufv-werks,
         plnbez TYPE caufv-plnbez,
         aufpl  TYPE caufv-aufpl,
       END OF ty_caufv.

TYPES: BEGIN OF ty_marc,
         matnr TYPE marc-matnr,
         werks TYPE marc-werks,
         dispo TYPE marc-dispo,
       END OF ty_marc.

TYPES: BEGIN OF ty_ekko,
         ebeln TYPE ekko-ebeln,
         lifnr TYPE ekko-lifnr,
         ekgrp TYPE ekko-ekgrp,
       END OF ty_ekko.

TYPES: BEGIN OF ty_ekpo,
         ebeln TYPE ekpo-ebeln,
         ebelp TYPE ekpo-ebelp,
         infnr TYPE ekpo-infnr,
       END OF ty_ekpo.

TYPES: BEGIN OF ty_eket,
         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         eindt TYPE eket-eindt,
       END OF ty_eket.

TYPES: BEGIN OF ty_eban,
         banfn TYPE eban-banfn,
         bnfpo TYPE eban-bnfpo,
         ekgrp TYPE eban-ekgrp,
         lfdat TYPE eban-lfdat,
         flief TYPE eban-flief,
       END OF ty_eban.

TYPES: BEGIN OF ty_afvc1,
         aufpl TYPE afvc-aufpl,
         aplzl TYPE afvc-aplzl,
         vornr TYPE afvc-vornr,
         infnr TYPE afvc-infnr,
       END OF ty_afvc1.

TYPES: BEGIN OF ty_plpo,
         plnty    TYPE plpo-plnty,
         plnnr    TYPE plpo-plnnr,
         plnal    TYPE plas-plnal,
         plnfl    TYPE plas-plnfl,
         plnkn    TYPE plpo-plnkn,
         zaehl    TYPE plpo-zaehl,
         vornr    TYPE plpo-vornr,
         infnr    TYPE plpo-infnr,
         ekgrp    TYPE plpo-ekgrp,
         lifnr    TYPE plpo-lifnr,
         ekorg    TYPE plpo-ekorg,
         lifnr_ir TYPE eina-lifnr,
         ekgrp_ir TYPE eine-ekgrp,
       END OF ty_plpo.

TYPES: BEGIN OF ty_zmfpfarm_err.
         INCLUDE STRUCTURE zmfpfarm.
TYPES:   chgid(1),
       END OF ty_zmfpfarm_err.

TYPES: BEGIN OF ty_indata,
         matnr(18),      "Material no
         menge(25),      "Qty
         flag(15),       "LPST Flag
         exdat(8),       "Need Doc Date
         avldat(8),      "Avail Date
         poline(40),     "PO number+Line+sched line no
         vendor(55),     "Vendor number+Name
         prldat(8),      "Planned Proc Rel Date
         dorder(35),     "Demand Order
         pstdue(1),      "Past Due indicator
         werks(4),       "Plant
         uom(3),
         po(20),          "Purchase Order no
         item(6),         "PO Line item no
         line(4),         "PO Schedule line no
         type(2),         "Supply type
         pst_edc(15),     "Expedite PO
         pst_date(8),
         capind(6),       "Order type
         run_date(8),
         cost(13),
         po_comments(50),
       END OF ty_indata.

TYPES: BEGIN OF ty_i_data,
         matnr(18),
         menge(25),
         flag(15),
         exdat           TYPE dats,
         avldat(8),
         poline(40),
         vendor(55),
         prldat(8),
         dorder(35),
         pstdue(1),
         werks(4),
         uom(3),
         po(20),
         item(6),
         line(4),
         type(2),
         pst_edc(15),
         pst_date(8),
         capind(6),
         run_date(8),
         cost(13),
         po_comments(50),
       END OF ty_i_data.

TYPES: BEGIN OF ty_zmfpdata_old,
         werks  TYPE werks_d,
         matnr  TYPE matnr,
         ebeln  TYPE ebeln,
         ebelp  TYPE ebelp,
         eeten  TYPE eeten,
         menge  TYPE bstmg,
         exdat  TYPE zzexdat,
         avldat TYPE zzavldat,
         flag   TYPE zzflag1,
       END OF ty_zmfpdata_old.

TYPES: BEGIN OF ty_buffer,
         buffer(300) TYPE c,
       END OF ty_buffer.

TYPES: BEGIN OF ty_select,
         sdata(300),
       END OF ty_select.

TYPES: BEGIN OF ty_zordcomnt_part,
          werks    LIKE zordcomnt-werks,
          matnr    LIKE zordcomnt-matnr,
          delnr    LIKE zordcomnt-delnr,
          ebelp    LIKE zordcomnt-ebelp,
          etenr    LIKE zordcomnt-etenr,
          savedate LIKE zordcomnt-savedate,
       END OF ty_zordcomnt_part.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA: gt_farm_out      TYPE STANDARD TABLE OF ty_farm_out,
      gt_caufv         TYPE STANDARD TABLE OF ty_caufv,
      gt_marc          TYPE STANDARD TABLE OF ty_marc,
      gt_ekko          TYPE STANDARD TABLE OF ty_ekko,
      gt_ekpo          TYPE STANDARD TABLE OF ty_ekpo,
      gt_eket          TYPE STANDARD TABLE OF ty_eket,
      gt_eban          TYPE STANDARD TABLE OF ty_eban,
      gt_afvc          TYPE STANDARD TABLE OF ty_afvc1,
      gt_plpo          TYPE STANDARD TABLE OF ty_plpo.

DATA: gt_zmfpfarm      TYPE STANDARD TABLE OF zmfpfarm,
      gt_stat_zmfpfarm TYPE STANDARD TABLE OF zmfpfarm,
      gt_zmfpfarm_err  TYPE STANDARD TABLE OF ty_zmfpfarm_err,
      gt_zmfpfarm_del  TYPE STANDARD TABLE OF ty_zmfpfarm_err.

DATA: gt_indata TYPE STANDARD TABLE OF ty_indata,
      gt_idata  TYPE STANDARD TABLE OF ty_i_data,
      gt_inerr  TYPE STANDARD TABLE OF ty_i_data.

DATA: gt_zmfpdata TYPE STANDARD TABLE OF zmfpdata,
      gt_zmfpdata_old TYPE STANDARD TABLE OF ty_zmfpdata_old.

DATA: gt_zmfpdatau TYPE STANDARD TABLE OF zmfpdatau.

DATA: gt_i_werks  TYPE STANDARD TABLE OF t001w.
DATA: gt_i_uwerks TYPE STANDARD TABLE OF t001w.

DATA: gt_zordcomnt TYPE STANDARD TABLE OF ty_zordcomnt_part.
DATA: gs_zordcomnt TYPE ty_zordcomnt_part.

DATA: gv_upd     TYPE i,
      gv_ins     TYPE i,
      gv_err     TYPE i,
      gv_lines_d TYPE i.

DATA: gv_s_log TYPE bal_s_log,
      gv_s_msg TYPE bal_s_msg.

DATA: gv_sc_text TYPE string.
DATA: gv_ans TYPE c.
DATA: gv_fil_path1 TYPE string.

* ALV Data
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv,
      gs_variant  TYPE disvariant,
      g_repid     LIKE sy-repid,
      g_save      VALUE 'A'.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) TEXT-053 FOR FIELD rb_load.
PARAMETER: rb_load RADIOBUTTON GROUP p1 DEFAULT 'X'.
SELECTION-SCREEN COMMENT 30(14) TEXT-054 FOR FIELD rb_risk.
PARAMETER: rb_risk RADIOBUTTON GROUP p1.
SELECTION-SCREEN COMMENT 54(14) TEXT-055 FOR FIELD rb_farm.
PARAMETER: rb_farm RADIOBUTTON GROUP p1.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF SCREEN 100 AS SUBSCREEN.
PARAMETERS: p_local RADIOBUTTON GROUP g2.
SELECTION-SCREEN BEGIN OF BLOCK c1 WITH FRAME.
PARAMETERS: pc_file  TYPE string DEFAULT 'C:\?.txt',
            pc_type(10) TYPE c DEFAULT 'DAT' NO-DISPLAY,
            pc_err   TYPE string DEFAULT 'C:\Zmfperror.txt',
            pc_etype(10) TYPE c DEFAULT 'DAT'.
SELECTION-SCREEN END OF BLOCK c1.

PARAMETERS: p_unx RADIOBUTTON GROUP g2 DEFAULT 'X'.
SELECTION-SCREEN BEGIN OF BLOCK c2 WITH FRAME.
PARAMETERS: p_unx_pt TYPE string,
            pc_ux_er TYPE string.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 33(30) gv_sc_text.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK c2.

SELECTION-SCREEN BEGIN OF BLOCK c3 WITH FRAME TITLE TEXT-ert.
SELECT-OPTIONS: s_uname FOR zusrsmtp-uname NO INTERVALS.
SELECTION-SCREEN END OF BLOCK c3.

SELECTION-SCREEN BEGIN OF BLOCK c4 WITH FRAME TITLE TEXT-dec.
PARAMETERS: p_delete AS CHECKBOX DEFAULT 'X',
            p_kepday TYPE i DEFAULT 30.
SELECT-OPTIONS: s_delwrk FOR zmfpdata-werks,
                s_delmat FOR zmfpdata-matnr.
SELECTION-SCREEN END OF BLOCK c4.

SELECTION-SCREEN BEGIN OF BLOCK c5 WITH FRAME TITLE TEXT-cmt.
PARAMETERS: p_cmtprg AS CHECKBOX DEFAULT ' ',
            p_prgday TYPE i DEFAULT 180.
SELECTION-SCREEN END OF BLOCK c5.
SELECTION-SCREEN END OF SCREEN 100.

SELECTION-SCREEN BEGIN OF SCREEN 200 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
SELECT-OPTIONS: s_matnr FOR zmfpdata-matnr,
                s_werks FOR zmfpdata-werks.
PARAMETER: p_dis  RADIOBUTTON GROUP g1 DEFAULT 'X',
           p_edit RADIOBUTTON GROUP g1,
           p_fix  RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN END OF SCREEN 200.

SELECTION-SCREEN BEGIN OF TABBED BLOCK mytab FOR 20 LINES.
SELECTION-SCREEN TAB (20) first  USER-COMMAND push1 DEFAULT SCREEN 100.
SELECTION-SCREEN TAB (20) second USER-COMMAND push2 DEFAULT SCREEN 200.
SELECTION-SCREEN END OF BLOCK mytab.

*---------------------------------------------------------------------*
* Initialization
*---------------------------------------------------------------------*
INITIALIZATION.
  p_dis = 'X'.
  first    = TEXT-010.
  second   = TEXT-020.
  mytab-dynnr       = 100.
  mytab-prog        = sy-repid.
  mytab-activetab   = 'UPLD_TAB'.

  g_repid = sy-repid.
  gs_variant-report = g_repid.

  SELECT SINGLE zparm1 INTO zifap-zparm1
    FROM zifap WHERE zlgclid = 'INBPTH'.
  IF sy-subrc EQ 0.
    gv_sc_text = zifap-zparm1.
  ENDIF.

*---------------------------------------------------------------------*
* At Selection Screen
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  CASE sy-ucomm.
    WHEN 'PUSH1'.
      mytab-dynnr       = 100.
      mytab-activetab   = 'UPLD_TAB'.

    WHEN 'PUSH2'.
      mytab-dynnr       = 200.
      mytab-activetab = 'FIX_TAB'.

    WHEN 'ONLI'.
      CASE mytab-dynnr.
        WHEN '100'.
          IF pc_file IS INITIAL.
            SET CURSOR FIELD 'PC_FILE'.
            MESSAGE e000(zl) WITH 'Please input File Name'(001).
          ENDIF.
          IF pc_type IS INITIAL.
            SET CURSOR FIELD 'PC_TYPE'.
            MESSAGE e000(zl) WITH 'Please input File Type'(002).
          ENDIF.
          IF pc_err IS INITIAL.
            SET CURSOR FIELD 'PC_ERR'.
            MESSAGE e000(zl) WITH 'Please input Error File Name'(003).
          ENDIF.
        WHEN '200'.
      ENDCASE.
  ENDCASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pc_file.
  PERFORM f_infile_help1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pc_err.
  PERFORM f_infile_help1.

*---------------------------------------------------------------------*
* Start of Selection
*---------------------------------------------------------------------*
START-OF-SELECTION.

  CASE mytab-dynnr.
    WHEN '100'.
      CASE 'X'.
        WHEN rb_load.
          IF p_cmtprg = 'X'.
            PERFORM f_purge_comments.
          ENDIF.

          DATA(lv_datum_start) = sy-datum.
          DATA(lv_uzeit_start) = sy-uzeit.

          PERFORM f_upload_data.

          PERFORM f_rec_finish_date_time USING 'ZMU0POMR'
                                               lv_datum_start
                                               lv_uzeit_start.
        WHEN rb_risk.
          " PERFORM f_reset_risk_flag.
        WHEN rb_farm.
          PERFORM f_upload_farmout.
      ENDCASE.

    WHEN '200'.
      PERFORM f_sanction_country.

      IF p_dis = 'X'.
        PERFORM f_disp_data.
      ELSEIF p_fix = 'X'.
        PERFORM f_delete_data.
      ELSEIF p_edit = 'X'.
        PERFORM f_edit_data.
      ENDIF.
  ENDCASE.

*---------------------------------------------------------------------*
* Forms
*---------------------------------------------------------------------*

FORM f_infile_help1.
  DATA: lt_file_table TYPE filetable,
        lv_rc         TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title      = CONV string( TEXT-hlp )
      default_filename  = ''
      file_filter       = '|*.*|*.*|'
      initial_directory = 'C:\'
    CHANGING
      file_table        = lt_file_table
      rc                = lv_rc
    EXCEPTIONS
      OTHERS            = 5.

  IF sy-subrc = 0 AND lt_file_table IS NOT INITIAL.
    pc_file = lt_file_table[ 1 ]-filename.
  ENDIF.
ENDFORM.

FORM f_upload_data.
  DATA: lt_raw_data TYPE TABLE OF string,
        lv_line     TYPE string.

  CLEAR: gt_indata, gt_idata, gt_inerr.

  IF p_local = 'X'.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename = pc_file
        filetype = 'ASC'
      CHANGING
        data_tab = lt_raw_data
      EXCEPTIONS
        OTHERS   = 17.

    IF sy-subrc NE 0.
      WRITE: / 'Error Opening File:'(008), pc_file.
      RETURN.
    ELSE.
      LOOP AT lt_raw_data INTO lv_line.
        DATA(ls_indata) = VALUE ty_indata( ).
        SPLIT lv_line AT c_delimiter INTO
           ls_indata-matnr
           ls_indata-menge
           ls_indata-flag
           ls_indata-exdat
           ls_indata-avldat
           ls_indata-poline
           ls_indata-vendor
           ls_indata-prldat
           ls_indata-dorder
           ls_indata-pstdue
           ls_indata-werks
           ls_indata-uom
           ls_indata-po
           ls_indata-item
           ls_indata-line
           ls_indata-type
           ls_indata-pst_edc
           ls_indata-pst_date
           ls_indata-capind
           ls_indata-run_date
           ls_indata-cost
           ls_indata-po_comments.
        APPEND ls_indata TO gt_indata.
      ENDLOOP.
    ENDIF.

  ELSEIF p_unx = 'X'.
    SELECT SINGLE zparm1 INTO zifap-zparm1 FROM zifap
      WHERE zlgclid = 'INBPTH'.
    IF sy-subrc EQ 0.
      gv_fil_path1 = |{ zifap-zparm1 }{ p_unx_pt }|.
      CONDENSE gv_fil_path1 NO-GAPS.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'S_DATASET'
      ID 'PROGRAM' FIELD sy-repid
      ID 'ACTVT' FIELD '33'
      ID 'FILENAME' FIELD gv_fil_path1.
    IF sy-subrc <> 0.
       MESSAGE e000(zl) WITH 'No authorization to read file'(023).
       STOP.
    ENDIF.

    OPEN DATASET gv_fil_path1 FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      MESSAGE s000(zl) WITH TEXT-unf gv_fil_path1.
      STOP.
    ENDIF.

    DO.
      READ DATASET gv_fil_path1 INTO lv_line.
      IF sy-subrc = 0.
        DATA(ls_indata) = VALUE ty_indata( ).
        SPLIT lv_line AT c_delimiter INTO
           ls_indata-matnr
           ls_indata-menge
           ls_indata-flag
           ls_indata-exdat
           ls_indata-avldat
           ls_indata-poline
           ls_indata-vendor
           ls_indata-prldat
           ls_indata-dorder
           ls_indata-pstdue
           ls_indata-werks
           ls_indata-uom
           ls_indata-po
           ls_indata-item
           ls_indata-line
           ls_indata-type
           ls_indata-pst_edc
           ls_indata-pst_date
           ls_indata-capind
           ls_indata-run_date
           ls_indata-cost
           ls_indata-po_comments.
        APPEND ls_indata TO gt_indata.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.
    CLOSE DATASET gv_fil_path1.
  ENDIF.

  LOOP AT gt_indata INTO DATA(ls_indata_proc).
    IF ls_indata_proc-matnr CA 'part'.
      CONTINUE.
    ELSE.
      DATA(ls_idata) = VALUE ty_i_data( ).
      ls_idata-matnr   = ls_indata_proc-matnr.
      ls_idata-menge   = ls_indata_proc-menge.
      ls_idata-flag    = ls_indata_proc-flag.
      ls_idata-exdat   = ls_indata_proc-exdat.
      ls_idata-avldat  = ls_indata_proc-avldat.
      ls_idata-poline  = ls_indata_proc-poline.
      ls_idata-vendor  = ls_indata_proc-vendor.
      ls_idata-prldat  = ls_indata_proc-prldat.
      ls_idata-dorder  = ls_indata_proc-dorder.
      ls_idata-pstdue  = ls_indata_proc-pstdue.
      ls_idata-werks   = ls_indata_proc-werks.
      ls_idata-uom     = ls_indata_proc-uom.
      ls_idata-po      = ls_indata_proc-po.
      ls_idata-item    = ls_indata_proc-item.
      ls_idata-line    = ls_indata_proc-line.
      ls_idata-type    = ls_indata_proc-type.
      ls_idata-pst_edc = ls_indata_proc-pst_edc.
      ls_idata-pst_date = ls_indata_proc-pst_date.
      ls_idata-capind  = ls_indata_proc-capind.
      ls_idata-cost    = ls_indata_proc-cost.
      APPEND ls_idata TO gt_idata.
    ENDIF.
  ENDLOOP.

  IF gt_idata IS NOT INITIAL.
    SORT gt_idata BY werks matnr vendor.
    PERFORM f_populate_zmfpdatau.
    PERFORM f_load_data.
  ENDIF.
ENDFORM.

FORM f_populate_zmfpdatau.
  SELECT * FROM zmfpdatau INTO TABLE gt_zmfpdatau.
  SORT gt_zmfpdatau BY werks ekgrp.
ENDFORM.

FORM f_load_data.
  DATA: lv_counter TYPE zmfpdata-counter,
        lv_change  TYPE c,
        lv_rsdays  TYPE zmfpdatau-rsdays,
        lv_avdays  TYPE zmfpdatau-avdays,
        lv_flag_check_ok TYPE c,
        lv_etens   TYPE ekes-etens.

  DATA: lv_found_settings       TYPE c,
        lv_default_threshold    TYPE d,
        lv_reset_reason         TYPE zzreset_reason,
        lv_temp_threshold(10)   TYPE c,
        lv_temp_savedate(10)    TYPE c,
        lv_days(3)              TYPE c,
        lv_diff_today           TYPE i,
        lv_diff_yesterday       TYPE i,
        lv_diff_today_yesterday TYPE i,
        lv_yestneeddate(10)     TYPE c,
        lv_todayneeddate(10)    TYPE c,
        lv_yestdeldate(10)      TYPE c,
        lv_todaydeldate(10)     TYPE c,
        lv_qty_yest(13)         TYPE c,
        lv_qty_today(13)        TYPE c.

  DATA: prev_mat_no  TYPE zmfpdata-matnr,
        prev_tl_mtnr TYPE zmfpdata-tl_mtnr,
        prev_disgr   TYPE zmfpdata-disgr.

  DATA: ls_zmfpdata TYPE zmfpdata.

  CLEAR: gv_upd, gv_ins, gv_err, gt_zmfpdata.

  IF s_delwrk[] IS NOT INITIAL.
     SELECT werks, matnr, delnr, ebelp, etenr, savedate
      FROM zordcomnt
      INTO CORRESPONDING FIELDS OF TABLE @gt_zordcomnt
      WHERE werks IN @s_delwrk
        AND processed = 'X'.
  ENDIF.

  IF gt_zordcomnt IS NOT INITIAL.
    SORT gt_zordcomnt BY werks matnr delnr ebelp etenr.

    SELECT werks, matnr, ebeln, ebelp, eeten, menge, exdat, avldat, flag
      FROM zmfpdata
      FOR ALL ENTRIES IN @gt_zordcomnt
      WHERE werks = @gt_zordcomnt-werks
        AND matnr = @gt_zordcomnt-matnr
        AND ebeln = @gt_zordcomnt-delnr
        AND ebelp = @gt_zordcomnt-ebelp
      INTO TABLE @gt_zmfpdata_old.

    SORT gt_zmfpdata_old BY werks matnr ebeln ebelp eeten.
  ENDIF.

  IF p_delete = 'X'.
    DELETE FROM zmfpdata
      WHERE werks IN @s_delwrk
        AND matnr IN @s_delmat.
  ENDIF.

  LOOP AT gt_idata INTO DATA(ls_idata).
    IF ls_idata-werks IS INITIAL.
      CONTINUE.
    ENDIF.
    CLEAR ls_zmfpdata.
    ls_zmfpdata-mandt = sy-mandt.

    AT NEW matnr.
      CLEAR lv_counter.
    ENDAT.

    lv_counter = lv_counter + 1.
    ls_zmfpdata-counter = lv_counter.

    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = ls_idata-matnr
      IMPORTING
        output       = ls_zmfpdata-matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.

    ls_zmfpdata-werks = ls_idata-werks.
    SPLIT ls_idata-vendor AT '-' INTO ls_zmfpdata-lifnr DATA(lv_dummy).

    CASE ls_idata-type.
      WHEN 'QM'.
        ls_zmfpdata-qmnum = ls_idata-po.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input = ls_idata-po
          IMPORTING output = ls_zmfpdata-ebeln.
      WHEN 'PL'.
        ls_zmfpdata-plorder = ls_idata-po.
        SELECT SINGLE ekgrp INTO ls_zmfpdata-ekgrp FROM marc
          WHERE matnr = ls_zmfpdata-matnr
            AND werks = ls_zmfpdata-werks.
      WHEN OTHERS.
        IF ls_idata-poline(2) = 'CC' OR ls_idata-poline(2) = 'DE'.
          SPLIT ls_idata-poline AT '-' INTO DATA(lv_extra3) ls_idata-po ls_idata-item ls_idata-line.
        ENDIF.
        ls_zmfpdata-ebeln = ls_idata-po.
        ls_zmfpdata-posnr = ls_idata-item.
        ls_zmfpdata-eeten = ls_idata-line.
        SELECT SINGLE ekgrp INTO ls_zmfpdata-ekgrp FROM ekko
          WHERE ebeln = ls_zmfpdata-ebeln.
    ENDCASE.

    ls_zmfpdata-best = ls_idata-type.
    ls_zmfpdata-ebelp = ls_idata-item.
    REPLACE ALL OCCURRENCES OF ',' IN ls_idata-menge WITH space.
    CONDENSE ls_idata-menge NO-GAPS.
    ls_zmfpdata-menge = ls_idata-menge.
    ls_zmfpdata-flag = ls_idata-flag.

    IF ls_idata-exdat IS INITIAL.
      CLEAR ls_zmfpdata-exdat.
    ELSE.
      ls_zmfpdata-exdat = ls_idata-exdat.
    ENDIF.
    ls_zmfpdata-fpndat = ls_zmfpdata-exdat.

    IF ls_idata-prldat IS INITIAL.
       CLEAR ls_zmfpdata-prldat.
    ELSE.
      ls_zmfpdata-prldat = ls_idata-prldat.
    ENDIF.

    IF ls_idata-avldat IS INITIAL.
      CLEAR ls_zmfpdata-avldat.
    ELSE.
      ls_zmfpdata-avldat = ls_idata-avldat.
    ENDIF.

    IF ls_idata-pstdue = 'Y'.
      ls_zmfpdata-pstdue = ls_idata-avldat.
    ENDIF.

    ls_zmfpdata-ordtyp = ls_idata-capind.

    SPLIT ls_idata-dorder AT '-' INTO ls_zmfpdata-dorder ls_zmfpdata-posnr ls_zmfpdata-etenr.
    ls_zmfpdata-dorder = ls_idata-dorder(10).
    ls_zmfpdata-meins = ls_idata-uom.

    SELECT SINGLE qmnum INTO @DATA(lv_qmnum) FROM qmel
      WHERE ebeln = @ls_zmfpdata-ebeln
        AND ebelp = @ls_zmfpdata-ebelp.
    IF sy-subrc = 0.
      ls_zmfpdata-qnotes = 'X'.
    ENDIF.

    SELECT SINGLE prctr, dismm, dispo, ekgrp
      INTO (@ls_zmfpdata-prctr, @ls_zmfpdata-dismm, @ls_zmfpdata-dispo, @ls_zmfpdata-ekgrp)
      FROM marc
      WHERE matnr = @ls_zmfpdata-matnr
        AND werks = @ls_zmfpdata-werks.

    IF ls_zmfpdata-best <> 'PL'.
      SELECT SINGLE ekgrp INTO @ls_zmfpdata-ekgrp_po
        FROM ekko WHERE ebeln = @ls_zmfpdata-ebeln.
      SELECT SINGLE bednr INTO @ls_zmfpdata-bednr
        FROM ekpo WHERE ebeln = @ls_zmfpdata-ebeln
                    AND ebelp = @ls_zmfpdata-ebelp.
    ELSE.
      CLEAR ls_zmfpdata-ekgrp_po.
    ENDIF.

    ls_zmfpdata-pst_edc = ls_idata-pst_edc.
    IF ls_zmfpdata-pst_edc IS INITIAL AND ls_idata-flag = 'Expedite PO'.
      ls_zmfpdata-bottleneck = 'X'.
    ELSE.
      ls_zmfpdata-bottleneck = ''.
    ENDIF.

    ls_zmfpdata-herbie_code = '0'.
    IF ls_idata-flag = 'Cancel' AND ls_zmfpdata-pst_edc = 'Cancel'.
      ls_zmfpdata-herbie_code = '1'.
    ENDIF.
    IF ls_idata-flag = 'Expedite PO' AND ( ls_zmfpdata-pst_edc = 'OnTime' OR ls_zmfpdata-pst_edc = 'Cancel' ).
      ls_zmfpdata-herbie_code = '2'.
    ENDIF.
    IF ls_idata-flag = 'New Expedite' AND ( ls_zmfpdata-pst_edc = 'OnTime' OR ls_zmfpdata-pst_edc = 'Cancel' ).
      ls_zmfpdata-herbie_code = '3'.
    ENDIF.
    IF ls_idata-flag = 'Expedite PO' AND ls_zmfpdata-pst_edc = 'Expedite PO'.
      ls_zmfpdata-herbie_code = '4'.
    ENDIF.
    IF ls_idata-flag = 'New Expedite' AND ls_zmfpdata-pst_edc = 'New Expedite'.
      ls_zmfpdata-herbie_code = '5'.
    ENDIF.

    DATA: lv_diff TYPE i.
    IF ls_idata-flag = 'De-expedite' AND ls_zmfpdata-pst_edc = 'De-expedite'.
      lv_diff = ls_idata-exdat - 20.
      IF lv_diff >= ls_idata-avldat.
        ls_zmfpdata-herbie_code = '6'.
      ENDIF.
    ENDIF.

    IF ( ls_idata-flag = 'Expedite PO' OR ls_idata-flag = 'New Expedite' ) AND ls_zmfpdata-pst_edc = 'De-expedite'.
      lv_diff = ls_idata-exdat - 20.
      IF lv_diff >= ls_idata-avldat.
        ls_zmfpdata-herbie_code = '7'.
        ls_zmfpdata-flag = 'De-expedite'.
      ENDIF.
    ENDIF.

    CLEAR lv_etens.
    SELECT SINGLE etens INTO lv_etens FROM ekes
      WHERE ebeln = ls_zmfpdata-ebeln AND ebelp = ls_zmfpdata-ebelp AND etens = ls_zmfpdata-eeten.
    IF sy-subrc EQ 0.
      ls_zmfpdata-po_sched_line = lv_etens.
    ELSE.
      SELECT SINGLE etenr INTO lv_etens FROM eket
        WHERE ebeln = ls_zmfpdata-ebeln AND ebelp = ls_zmfpdata-ebelp AND etenr = ls_zmfpdata-eeten.
      IF sy-subrc EQ 0.
        ls_zmfpdata-po_sched_line = lv_etens.
      ENDIF.
    ENDIF.

    IF ls_idata-pst_date IS NOT INITIAL.
      ls_zmfpdata-pst_date = ls_idata-pst_date.
    ENDIF.

    REPLACE ALL OCCURRENCES OF ',' IN ls_idata-cost WITH space.
    CONDENSE ls_idata-cost NO-GAPS.
    ls_zmfpdata-cost = ls_idata-cost.
    ls_zmfpdata-waers = 'USD'.

    APPEND ls_zmfpdata TO gt_zmfpdata.
  ENDLOOP.

  SORT gt_zmfpdata BY matnr werks lifnr ebeln ebelp eeten plorder.
  DELETE ADJACENT DUPLICATES FROM gt_zmfpdata COMPARING matnr werks lifnr ebeln ebelp eeten plorder.

  LOOP AT gt_zmfpdata INTO ls_zmfpdata.
    IF ls_zmfpdata-matnr <> prev_mat_no.
      PERFORM f_get_top_lvl_mat_mrpgrp USING ls_zmfpdata-matnr ls_zmfpdata-werks
                                       CHANGING ls_zmfpdata-tl_mtnr ls_zmfpdata-disgr.
      prev_mat_no = ls_zmfpdata-matnr.
      prev_tl_mtnr = ls_zmfpdata-tl_mtnr.
      prev_disgr = ls_zmfpdata-disgr.
    ELSE.
      ls_zmfpdata-tl_mtnr = prev_tl_mtnr.
      ls_zmfpdata-disgr = prev_disgr.
    ENDIF.

    MODIFY gt_zmfpdata FROM ls_zmfpdata.

    DATA(ls_uwerks) = VALUE t001w( werks = ls_zmfpdata-werks ).
    APPEND ls_uwerks TO gt_i_uwerks.

    INSERT zmfpdata FROM ls_zmfpdata.
    IF sy-subrc = 0.
      gv_ins = gv_ins + 1.
    ELSE.
      gv_err = gv_err + 1.
      DATA(ls_inerr) = VALUE ty_i_data( ).
      MOVE-CORRESPONDING ls_zmfpdata TO ls_inerr.
      APPEND ls_inerr TO gt_inerr.
    ENDIF.

    " Check logic for ZORDCOMNT update
    lv_change = 'No'.
    READ TABLE gt_zmfpdata_old INTO DATA(ls_old)
      WITH KEY werks = ls_zmfpdata-werks
               matnr = ls_zmfpdata-matnr
               ebeln = ls_zmfpdata-ebeln
               ebelp = ls_zmfpdata-ebelp
               eeten = ls_zmfpdata-eeten
      BINARY SEARCH.

    IF sy-subrc = 0.
       READ TABLE gt_zordcomnt INTO gs_zordcomnt
         WITH KEY werks = ls_zmfpdata-werks
                  matnr = ls_zmfpdata-matnr
                  delnr = ls_zmfpdata-ebeln
                  ebelp = ls_zmfpdata-ebelp
         BINARY SEARCH.
       IF sy-subrc = 0.
          CLEAR lv_found_settings.
          READ TABLE gt_zmfpdatau INTO DATA(ls_zmfpdatau)
            WITH KEY werks = ls_zmfpdata-werks ekgrp = ls_zmfpdata-ekgrp
            BINARY SEARCH.
          IF sy-subrc <> 0.
            READ TABLE gt_zmfpdatau INTO ls_zmfpdatau
              WITH KEY werks = ls_zmfpdata-werks ekgrp = '***'
              BINARY SEARCH.
            IF sy-subrc = 0.
               lv_found_settings = 'Y'.
            ELSE.
               lv_found_settings = 'N'.
            ENDIF.
          ELSE.
             lv_found_settings = 'Y'.
          ENDIF.

          IF lv_found_settings = 'N'.
             ls_zmfpdatau-edc_msg_chg = 'Y'.
             ls_zmfpdatau-exped_thresh = 10.
             ls_zmfpdatau-deexped_thresh = 60.
             ls_zmfpdatau-cancel_thresh = 30.
             ls_zmfpdatau-default_thresh = 45.
          ENDIF.

          lv_default_threshold = sy-datum - ls_zmfpdatau-default_thresh.

          IF gs_zordcomnt-savedate <= lv_default_threshold.
             lv_change = 'YES'.
             lv_temp_threshold = ls_zmfpdatau-default_thresh.
             WRITE gs_zordcomnt-savedate TO lv_temp_savedate.
             lv_reset_reason = |Default threshold of { lv_temp_threshold } days exceeded - last updated on: { lv_temp_savedate }|.
          ELSE.
             IF ls_old-menge = ls_zmfpdata-menge.
                IF ls_zmfpdatau-edc_msg_chg = 'Y'.
                   IF ls_old-flag = ls_zmfpdata-flag.
                      lv_flag_check_ok = 'Y'.
                   ELSE.
                      lv_flag_check_ok = 'N'.
                   ENDIF.
                ELSE.
                   lv_flag_check_ok = 'Y'.
                ENDIF.

                IF lv_flag_check_ok = 'Y'.
                   CASE ls_zmfpdata-flag.
                      WHEN 'Expedite PO' OR 'New Expedite'. lv_days = ls_zmfpdatau-exped_thresh.
                      WHEN 'OnTime'. lv_days = 999.
                      WHEN 'De-expedite'. lv_days = ls_zmfpdatau-deexped_thresh.
                      WHEN 'Cancel'. lv_days = ls_zmfpdatau-cancel_thresh.
                      WHEN OTHERS. lv_days = 999.
                   ENDCASE.

                   lv_diff_yesterday = abs( ls_old-exdat - ls_zmfpdata-exdat ).
                   lv_diff_today = abs( ls_old-avldat - ls_zmfpdata-avldat ).
                   lv_diff_today_yesterday = abs( lv_diff_yesterday - lv_diff_today ).

                   IF lv_diff_today_yesterday > lv_days.
                      lv_change = 'YES'.
                      WRITE ls_old-exdat TO lv_yestneeddate.
                      WRITE ls_zmfpdata-exdat TO lv_todayneeddate.
                      WRITE ls_old-avldat TO lv_yestdeldate.
                      WRITE ls_zmfpdata-avldat TO lv_todaydeldate.

                      lv_reset_reason = |{ ls_zmfpdata-flag } threshold of { lv_days } days exceeded ({ lv_yestneeddate(5) }-{ lv_todayneeddate(5) }) - ({ lv_yestdeldate(5) }-{ lv_todaydeldate(5) })|.
                   ENDIF.
                ELSE.
                   lv_change = 'YES'.
                   lv_reset_reason = |EDC Flag changed from { ls_old-flag } to: { ls_zmfpdata-flag }|.
                ENDIF.
             ELSE.
                lv_change = 'YES'.
                WRITE ls_old-menge TO lv_qty_yest.
                WRITE ls_zmfpdata-menge TO lv_qty_today.
                lv_reset_reason = |Quantity Changed from { lv_qty_yest } to: { lv_qty_today }|.
             ENDIF.
          ENDIF.
       ENDIF.
    ENDIF.

    IF lv_change = 'YES'.
       UPDATE zordcomnt SET
         savedate = sy-datum
         processed = ' '
         reset_reason = lv_reset_reason
         WHERE werks = ls_zmfpdata-werks
           AND matnr = ls_zmfpdata-matnr
           AND delnr = ls_zmfpdata-ebeln
           AND ebelp = ls_zmfpdata-ebelp.
    ENDIF.
  ENDLOOP.

  IF gv_ins GT 0.
    WRITE: / gv_ins, 'Records inserted successfully'(009).
  ENDIF.

  IF gt_inerr IS NOT INITIAL.
     IF s_uname[] IS NOT INITIAL.
        PERFORM f_send_email.
     ENDIF.

     IF p_local = 'X'.
       CALL METHOD cl_gui_frontend_services=>gui_download
         EXPORTING filename = pc_err filetype = 'ASC'
         CHANGING data_tab = gt_inerr
         EXCEPTIONS OTHERS = 1.
       IF sy-subrc NE 0.
         WRITE: / 'Error generating file'.
         LOOP AT gt_inerr INTO ls_inerr. WRITE: / ls_inerr-matnr, ls_inerr-werks. ENDLOOP.
       ELSE.
         WRITE: / 'Error file generated'(012).
       ENDIF.
     ELSEIF p_unx = 'X'.
        DATA: lt_select TYPE TABLE OF ty_select, ls_select TYPE ty_select.
        LOOP AT gt_inerr INTO ls_inerr.
          CONCATENATE ls_inerr-werks ls_inerr-matnr ls_inerr-menge ls_inerr-flag ls_inerr-exdat
                      ls_inerr-poline ls_inerr-vendor ls_inerr-avldat ls_inerr-prldat ls_inerr-dorder
                      ls_inerr-pstdue ls_inerr-uom ls_inerr-po ls_inerr-item ls_inerr-line ls_inerr-type
                      INTO ls_select-sdata SEPARATED BY c_delimiter.
          APPEND ls_select TO lt_select.
        ENDLOOP.

        gv_fil_path1 = |{ zifap-zparm1 }{ pc_ux_er }|.
        CONDENSE gv_fil_path1 NO-GAPS.

        OPEN DATASET gv_fil_path1 FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
        IF sy-subrc NE 0. WRITE: / TEXT-122, gv_fil_path1. STOP. ENDIF.
        LOOP AT lt_select INTO ls_select.
           TRANSFER ls_select-sdata TO gv_fil_path1.
        ENDLOOP.
        CLOSE DATASET gv_fil_path1.
     ENDIF.
  ELSE.
    WRITE: / 'No errors found'(021).
  ENDIF.

ENDFORM.

FORM f_get_top_lvl_mat_mrpgrp USING p_matnr p_werks
                               CHANGING p_tl_mtnr p_disgr.
  SELECT SINGLE tl_mtnr INTO p_tl_mtnr FROM zmpeg
    WHERE werks = p_werks AND matnr = p_matnr.
  IF sy-subrc <> 0.
    p_tl_mtnr = p_matnr.
  ENDIF.

  SELECT SINGLE disgr INTO p_disgr FROM marc
    WHERE werks = p_werks AND matnr = p_tl_mtnr.
ENDFORM.

FORM f_purge_comments.
  DATA: lv_purge_date TYPE d.
  lv_purge_date = sy-datum - p_prgday.
  DELETE FROM zordcomnt WHERE savedate < lv_purge_date.
  MESSAGE i000(z4) WITH 'Purged' sy-dbcnt 'Comments older than' lv_purge_date.
  COMMIT WORK.
ENDFORM.

FORM f_rec_finish_date_time USING p_repid p_datum_start p_uzeit_start.
  SORT gt_i_uwerks BY werks.
  DELETE ADJACENT DUPLICATES FROM gt_i_uwerks COMPARING werks.

  LOOP AT gt_i_uwerks INTO DATA(ls_werks).
    UPDATE zmfgload SET
      datum_finish = sy-datum
      uzeit_finish = sy-uzeit
      datum_start  = p_datum_start
      uzeit_start  = p_uzeit_start
      WHERE repid = p_repid AND werks = ls_werks-werks.
    IF sy-subrc <> 0.
       DATA(ls_zmfgload) = VALUE zmfgload(
         mandt = sy-mandt
         repid = p_repid
         werks = ls_werks-werks
         datum_finish = sy-datum
         uzeit_finish = sy-uzeit
         datum_start  = p_datum_start
         uzeit_start  = p_uzeit_start
       ).
       INSERT zmfgload FROM ls_zmfgload.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM f_disp_data.
  SELECT * FROM zmfpdata INTO TABLE gt_zmfpdata
    WHERE matnr IN s_matnr
      AND werks IN s_werks.

  IF gt_zmfpdata IS INITIAL.
    WRITE: / 'No Data found'(013).
  ELSE.
    PERFORM f_build_fcat.
    gs_layout-colwidth_optimize = 'X'.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = g_repid
        i_callback_user_command = 'USER_COMMAND'
        i_structure_name = 'ZMFPDATA'
        is_layout = gs_layout
        i_save = g_save
        is_variant = gs_variant
        it_fieldcat = gt_fieldcat
      TABLES
        t_outtab = gt_zmfpdata
      EXCEPTIONS
        OTHERS = 2.
  ENDIF.
ENDFORM.

FORM f_build_fcat.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name = g_repid
      i_structure_name = 'ZMFPDATA'
      i_inclname = g_repid
    CHANGING
      ct_fieldcat = gt_fieldcat
    EXCEPTIONS
      OTHERS = 3.

  IF p_edit = 'X'.
    LOOP AT gt_fieldcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
      CASE <fs_fcat>-fieldname.
        WHEN 'EBELN' OR 'LIFNR' OR 'MENGE' OR 'DATE1' OR 'DATE2' OR 'DATE3' OR 'PORTIME' OR 'LNTIME' OR 'DORDER' OR 'PSTDUE' OR 'MEINS'.
          <fs_fcat>-edit = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDIF.
ENDFORM.

FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  IF r_ucomm = '&DATA_SAVE'.
    UPDATE zmfpdata FROM TABLE gt_zmfpdata.
    IF sy-subrc = 0. COMMIT WORK. ENDIF.
  ELSEIF r_ucomm = 'DEL'.
    IF rs_selfield-tabindex GT 0.
      DATA(lv_ans) = ' '.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          text_question = 'Do you want to delete?'(del)
          titlebar = 'Confirm'(cfm)
        IMPORTING
          answer = lv_ans.

      IF lv_ans = '1'.
        READ TABLE gt_zmfpdata INTO DATA(ls_data) INDEX rs_selfield-tabindex.
        DELETE FROM zmfpdata WHERE matnr = ls_data-matnr AND werks = ls_data-werks.
        IF sy-subrc = 0.
          COMMIT WORK.
          DELETE gt_zmfpdata INDEX rs_selfield-tabindex.
          MESSAGE s000(zl) WITH 'Successfully deleted'.
          rs_selfield-refresh = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.

FORM f_delete_data.
  DATA(lv_ans) = ' '.
  IF sy-batch EQ 'X'.
    lv_ans = '1'.
  ELSE.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question = 'Do you want to delete?'(del)
        titlebar = 'Confirm'(cfm)
      IMPORTING
        answer = lv_ans.
  ENDIF.

  IF lv_ans = '1'.
    DELETE FROM zmfpdata WHERE matnr IN s_matnr AND werks IN s_werks.
    IF sy-subrc = 0.
      WRITE: / 'Successfully deleted'(016), sy-dbcnt, 'records'(017).
    ELSE.
      WRITE: / 'Unable to delete records'(018).
    ENDIF.
  ELSE.
    WRITE: / 'Nothing has been deleted'(019).
  ENDIF.
ENDFORM.

FORM f_upload_farmout.
  CLEAR: gv_ins, gv_err, gv_upd, gv_lines_d.
  CLEAR gt_farm_out.
  DATA: lt_raw_data TYPE TABLE OF string,
        lv_line     TYPE string.

  IF p_local = 'X' AND pc_file IS NOT INITIAL.
    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename = pc_file
        filetype = 'ASC'
      CHANGING
        data_tab = lt_raw_data
      EXCEPTIONS
        OTHERS   = 17.
    IF sy-subrc NE 0.
      WRITE: / 'Error Opening File:'(008), pc_file.
      RETURN.
    ELSE.
      LOOP AT lt_raw_data INTO lv_line.
        DATA(ls_farm) = VALUE ty_farm_out( ).
        SPLIT lv_line AT c_delimiter INTO
          ls_farm-ebeln ls_farm-ebelp ls_farm-dotyp ls_farm-aufnr
          ls_farm-popno ls_farm-lpst_d ls_farm-l_time ls_farm-d_date
          ls_farm-lpct ls_farm-pst ls_farm-matnr ls_farm-order_qty
          ls_farm-plnnr ls_farm-plnal ls_farm-plnfl ls_farm-res ls_farm-werks.
        IF ls_farm-plnfl IS INITIAL. ls_farm-plnfl = '000000'. ENDIF.
        APPEND ls_farm TO gt_farm_out.
      ENDLOOP.
    ENDIF.
  ELSEIF p_unx = 'X'.
    SELECT SINGLE zparm1 INTO zifap-zparm1 FROM zifap
      WHERE zlgclid = 'INBPTH'.
    IF sy-subrc EQ 0.
      gv_fil_path1 = |{ zifap-zparm1 }{ p_unx_pt }|.
      CONDENSE gv_fil_path1 NO-GAPS.
    ENDIF.

    OPEN DATASET gv_fil_path1 FOR INPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc <> 0.
      MESSAGE s000(zl) WITH TEXT-unf gv_fil_path1.
      STOP.
    ENDIF.

    DO.
      READ DATASET gv_fil_path1 INTO lv_line.
      IF sy-subrc = 0.
        DATA(ls_farm) = VALUE ty_farm_out( ).
        SPLIT lv_line AT c_delimiter INTO
          ls_farm-ebeln ls_farm-ebelp ls_farm-dotyp ls_farm-aufnr
          ls_farm-popno ls_farm-lpst_d ls_farm-l_time ls_farm-d_date
          ls_farm-lpct ls_farm-pst ls_farm-matnr ls_farm-order_qty
          ls_farm-plnnr ls_farm-plnal ls_farm-plnfl ls_farm-res ls_farm-werks.
        IF ls_farm-plnfl IS INITIAL. ls_farm-plnfl = '000000'. ENDIF.
        APPEND ls_farm TO gt_farm_out.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.
    CLOSE DATASET gv_fil_path1.
  ENDIF.

  IF p_delete IS NOT INITIAL.
    DATA(lv_cutoff) = COND d( WHEN p_kepday IS NOT INITIAL THEN sy-datum - p_kepday ELSE sy-datum + 1 ).
    SELECT * FROM zmfpfarm INTO TABLE gt_stat_zmfpfarm
      WHERE ebeln GT '0000000000' AND ebelp GT '00000'
        AND bidatum LT lv_cutoff AND dwerk IN s_delwrk AND matnr IN s_delmat.

    IF gt_stat_zmfpfarm IS NOT INITIAL.
       DELETE zmfpfarm FROM TABLE gt_stat_zmfpfarm.
       LOOP AT gt_stat_zmfpfarm INTO DATA(ls_del).
         DATA(ls_err) = VALUE ty_zmfpfarm_err( ).
         MOVE-CORRESPONDING ls_del TO ls_err.
         ls_err-chgid = 'D'.
         APPEND ls_err TO gt_zmfpfarm_del.
       ENDLOOP.
    ENDIF.
  ENDIF.

  IF gt_farm_out IS NOT INITIAL.
     SELECT ebeln, lifnr, ekgrp FROM ekko INTO TABLE @gt_ekko
       FOR ALL ENTRIES IN @gt_farm_out WHERE ebeln = @gt_farm_out-ebeln.
     IF gt_ekko IS NOT INITIAL.
        SELECT ebeln, ebelp, eindt FROM eket INTO TABLE @gt_eket
          FOR ALL ENTRIES IN @gt_farm_out WHERE ebeln = @gt_farm_out-ebeln AND ebelp = @gt_farm_out-ebelp.
        SORT gt_eket BY ebeln ebelp eindt.
     ENDIF.

     SELECT banfn, bnfpo, ekgrp, lfdat, flief FROM eban INTO TABLE @gt_eban
       FOR ALL ENTRIES IN @gt_farm_out WHERE banfn = @gt_farm_out-ebeln AND bnfpo = @gt_farm_out-ebelp.

     SELECT aufnr, werks, plnbez, aufpl FROM caufv INTO TABLE @gt_caufv
       FOR ALL ENTRIES IN @gt_farm_out WHERE aufnr = @gt_farm_out-aufnr.

     IF gt_caufv IS NOT INITIAL.
        SELECT aufpl, aplzl, vornr, infnr FROM afvc INTO TABLE @gt_afvc
          FOR ALL ENTRIES IN @gt_caufv WHERE aufpl = @gt_caufv-aufpl.
        SORT gt_afvc BY aufpl vornr.

        SELECT matnr, werks, dispo FROM marc INTO TABLE @gt_marc
          FOR ALL ENTRIES IN @gt_caufv WHERE matnr = @gt_caufv-plnbez AND werks = @gt_caufv-werks.
     ENDIF.

     SELECT matnr, werks, dispo FROM marc APPENDING TABLE @gt_marc
       FOR ALL ENTRIES IN @gt_farm_out WHERE matnr = @gt_farm_out-matnr AND werks = @gt_farm_out-werks.

     SELECT plpo~plnty, plpo~plnnr, plas~plnal, plas~plnfl, plpo~plnkn, plpo~zaehl,
            plpo~vornr, plpo~infnr, plpo~ekgrp, plpo~lifnr, plpo~ekorg, eina~lifnr AS lifnr_ir, eine~ekgrp AS ekgrp_ir
       FROM plas
       INNER JOIN plpo ON plpo~plnty = plas~plnty AND plpo~plnnr = plas~plnnr AND plpo~plnkn = plas~plnkn
       INNER JOIN eina ON plpo~infnr = eina~infnr
       INNER JOIN eine ON plpo~infnr = eine~infnr AND plpo~ekorg = eine~ekorg
       INTO TABLE @gt_plpo
       FOR ALL ENTRIES IN @gt_farm_out
       WHERE plas~plnty = 'N' AND plas~plnnr = @gt_farm_out-plnnr
         AND plas~plnal = @gt_farm_out-plnal AND plas~plnfl = @gt_farm_out-plnfl.

     SORT gt_plpo BY plnnr plnal plnfl vornr ASCENDING zaehl DESCENDING.
  ENDIF.

  SORT gt_caufv BY aufnr.
  SORT gt_marc BY matnr werks.
  SORT gt_ekko BY ebeln.
  SORT gt_eban BY banfn bnfpo.

  LOOP AT gt_farm_out INTO DATA(ls_farm_out).
    DATA(ls_zmfpfarm) = VALUE zmfpfarm( ).
    ls_zmfpfarm-ebeln = ls_farm_out-ebeln.
    ls_zmfpfarm-ebelp = ls_farm_out-ebelp.

    READ TABLE gt_eban INTO DATA(ls_eban) WITH KEY banfn = ls_farm_out-ebeln bnfpo = ls_farm_out-ebelp BINARY SEARCH.
    IF sy-subrc = 0.
       ls_zmfpfarm-bsart = 'PR'.
       ls_zmfpfarm-lifnr = ls_eban-flief.
       ls_zmfpfarm-ekgrp = ls_eban-ekgrp.
       ls_zmfpfarm-eindt = ls_eban-lfdat.
    ELSE.
       READ TABLE gt_ekko INTO DATA(ls_ekko) WITH KEY ebeln = ls_farm_out-ebeln BINARY SEARCH.
       IF sy-subrc = 0.
          ls_zmfpfarm-bsart = 'PO'.
          ls_zmfpfarm-ekgrp = ls_ekko-ekgrp.
          ls_zmfpfarm-lifnr = ls_ekko-lifnr.
          READ TABLE gt_eket INTO DATA(ls_eket) WITH KEY ebeln = ls_farm_out-ebeln ebelp = ls_farm_out-ebelp BINARY SEARCH.
          IF sy-subrc = 0. ls_zmfpfarm-eindt = ls_eket-eindt. ENDIF.
       ENDIF.
    ENDIF.

    ls_zmfpfarm-vornr = ls_farm_out-popno.
    ls_zmfpfarm-lpct = ls_farm_out-lpct.
    ls_zmfpfarm-pst = ls_farm_out-pst.
    IF ls_farm_out-dotyp EQ 'Farmout_pl_ord'.
       ls_zmfpfarm-bsart = 'MFPL'.
       ls_zmfpfarm-arbpl = ls_farm_out-res.
       ls_zmfpfarm-plnnr = ls_farm_out-plnnr.
       ls_zmfpfarm-plnal = ls_farm_out-plnal.
       ls_zmfpfarm-plnfl = ls_farm_out-plnfl.
       ls_zmfpfarm-order_qty = ls_farm_out-order_qty.
    ENDIF.
    ls_zmfpfarm-aufnr = ls_farm_out-aufnr.

    READ TABLE gt_caufv INTO DATA(ls_caufv) WITH KEY aufnr = ls_zmfpfarm-aufnr BINARY SEARCH.
    IF sy-subrc = 0.
       IF ls_farm_out-dotyp NE 'Farmout_pl_ord'.
          ls_zmfpfarm-matnr = ls_caufv-plnbez.
          ls_zmfpfarm-dwerk = ls_caufv-werks.
       ENDIF.

       CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' EXPORTING input = ls_farm_out-popno IMPORTING output = ls_zmfpfarm-vornr.
       READ TABLE gt_afvc INTO DATA(ls_afvc) WITH KEY aufpl = ls_caufv-aufpl vornr = ls_zmfpfarm-vornr BINARY SEARCH.
       IF sy-subrc = 0. ls_zmfpfarm-infnr = ls_afvc-infnr. ENDIF.
    ENDIF.

    IF ls_farm_out-dotyp EQ 'Farmout_pl_ord'.
       ls_zmfpfarm-matnr = ls_farm_out-matnr.
       ls_zmfpfarm-dwerk = ls_farm_out-werks.

       READ TABLE gt_plpo INTO DATA(ls_plpo) WITH KEY plnnr = ls_farm_out-plnnr plnal = ls_farm_out-plnal plnfl = ls_farm_out-plnfl vornr = ls_farm_out-popno BINARY SEARCH.
       IF sy-subrc = 0.
          ls_zmfpfarm-lifnr = COND #( WHEN ls_plpo-lifnr_ir IS NOT INITIAL THEN ls_plpo-lifnr_ir ELSE ls_plpo-lifnr ).
          ls_zmfpfarm-ekgrp = COND #( WHEN ls_plpo-ekgrp_ir IS NOT INITIAL THEN ls_plpo-ekgrp_ir ELSE ls_plpo-ekgrp ).
          ls_zmfpfarm-infnr = ls_plpo-infnr.
       ENDIF.
    ENDIF.

    ls_zmfpfarm-lpst = ls_farm_out-lpst_d.
    ls_zmfpfarm-leat = ls_farm_out-l_time.
    ls_zmfpfarm-bidatum = sy-datum.

    IF ls_zmfpfarm-lpst NE '' AND ls_zmfpfarm-eindt NE ''.
       IF ls_zmfpfarm-lpst GT ls_zmfpfarm-eindt.
          ls_zmfpfarm-exped = 'D'.
       ELSEIF ls_zmfpfarm-lpst EQ ls_zmfpfarm-eindt.
          ls_zmfpfarm-exped = space.
       ELSE.
          ls_zmfpfarm-exped = 'E'.
       ENDIF.
    ENDIF.

    READ TABLE gt_marc INTO DATA(ls_marc) WITH KEY matnr = ls_zmfpfarm-matnr werks = ls_zmfpfarm-dwerk BINARY SEARCH.
    IF sy-subrc = 0. ls_zmfpfarm-dispo = ls_marc-dispo. ENDIF.

    APPEND ls_zmfpfarm TO gt_zmfpfarm.
  ENDLOOP.

  IF gt_zmfpfarm IS NOT INITIAL.
     SELECT * FROM zmfpfarm INTO TABLE gt_stat_zmfpfarm FOR ALL ENTRIES IN gt_zmfpfarm WHERE ebeln = gt_zmfpfarm-ebeln AND ebelp = gt_zmfpfarm-ebelp.
  ENDIF.

  LOOP AT gt_zmfpfarm INTO ls_zmfpfarm.
    READ TABLE gt_stat_zmfpfarm INTO DATA(ls_stat) WITH KEY ebeln = ls_zmfpfarm-ebeln ebelp = ls_zmfpfarm-ebelp.
    IF sy-subrc = 0.
       UPDATE zmfpfarm FROM ls_zmfpfarm.
       IF sy-subrc = 0. gv_upd = gv_upd + 1. ELSE.
         DATA(ls_err) = VALUE ty_zmfpfarm_err( ). MOVE-CORRESPONDING ls_zmfpfarm TO ls_err. ls_err-chgid = 'U'. APPEND ls_err TO gt_zmfpfarm_err.
       ENDIF.
    ELSE.
       INSERT zmfpfarm FROM ls_zmfpfarm.
       IF sy-subrc = 0. gv_ins = gv_ins + 1. ELSE.
         DATA(ls_err2) = VALUE ty_zmfpfarm_err( ). MOVE-CORRESPONDING ls_zmfpfarm TO ls_err2. ls_err2-chgid = 'I'. APPEND ls_err2 TO gt_zmfpfarm_err.
       ENDIF.
    ENDIF.
  ENDLOOP.
  COMMIT WORK AND WAIT.

  IF gt_zmfpfarm_err IS NOT INITIAL.
     PERFORM f_process_err_zmfpfarm.
  ENDIF.

  " Logging
  CLEAR gv_s_log.
  gv_s_log-object = c_object. gv_s_log-subobject = c_sobj_crt.
  gv_s_log-alprog = sy-repid. gv_s_log-extnumber = 'ZMFPFARM Log'. gv_s_log-aluser = sy-uname.
  CALL FUNCTION 'BAL_LOG_CREATE' EXPORTING i_s_log = gv_s_log IMPORTING e_log_handle = gv_s_msg-log_handle.
  gv_s_msg-msgty = 'S'. gv_s_msg-msgid = 'ZMPF'. gv_s_msg-msgno = c_msn_apl.
  gv_s_msg-msgv1 = gv_ins. gv_s_msg-msgv2 = gv_lines_d. gv_s_msg-msgv3 = gv_upd. gv_s_msg-msgv4 = gv_err.
  CONDENSE: gv_s_msg-msgv1, gv_s_msg-msgv2, gv_s_msg-msgv3, gv_s_msg-msgv4.
  CALL FUNCTION 'BAL_LOG_MSG_ADD' EXPORTING i_s_msg = gv_s_msg.
  CALL FUNCTION 'BAL_DB_SAVE' EXPORTING i_save_all = 'X'.

  MESSAGE s000(zl) WITH TEXT-022.
ENDFORM.

FORM f_process_err_zmfpfarm.
  IF p_local = 'X' AND pc_err IS NOT INITIAL.
    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING filename = pc_err filetype = 'ASC'
      CHANGING data_tab = gt_zmfpfarm_err
      EXCEPTIONS OTHERS = 1.
      IF sy-subrc NE 0. WRITE: / TEXT-011. ELSE. WRITE: / 'Error file generated'(012). ENDIF.
  ELSEIF p_unx = 'X'.
     DATA: lt_select TYPE TABLE OF ty_select, ls_select TYPE ty_select.
     LOOP AT gt_zmfpfarm_err INTO DATA(ls_err).
        CONCATENATE ls_err-ebeln ls_err-ebelp ls_err-dwerk ls_err-matnr ls_err-bsart ls_err-aufnr
                    ls_err-vornr ls_err-lpst ls_err-leat ls_err-eindt ls_err-dispo ls_err-ekgrp
                    ls_err-lifnr ls_err-infnr ls_err-exped ls_err-bidatum ls_err-chgid
                    INTO ls_select-sdata SEPARATED BY c_delimiter.
        APPEND ls_select TO lt_select.
     ENDLOOP.
     gv_fil_path1 = |{ zifap-zparm1 }{ pc_ux_er }|.
     CONDENSE gv_fil_path1 NO-GAPS.
     OPEN DATASET gv_fil_path1 FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
     IF sy-subrc NE 0. WRITE: / TEXT-122, gv_fil_path1. STOP. ENDIF.
     LOOP AT lt_select INTO ls_select.
        TRANSFER ls_select-sdata TO gv_fil_path1.
     ENDLOOP.
     CLOSE DATASET gv_fil_path1.
  ENDIF.
ENDFORM.

FORM f_send_email.
  DATA: lt_users TYPE TABLE OF zusrsmtp,
        lt_email TYPE TABLE OF solisti1,
        ls_user  TYPE zusrsmtp,
        ls_email TYPE solisti1.

  LOOP AT s_uname INTO DATA(ls_uname).
     ls_user-uname = ls_uname-low. APPEND ls_user TO lt_users.
  ENDLOOP.

  ls_email-line = TEXT-ert. APPEND ls_email TO lt_email.
  LOOP AT gt_inerr INTO DATA(ls_inerr).
     ls_email-line = |{ ls_inerr-matnr } { ls_inerr-werks }|. APPEND ls_email TO lt_email.
  ENDLOOP.

  CALL FUNCTION 'Z_SEND_EMAIL' TABLES users = lt_users email = lt_email EXCEPTIONS OTHERS = 1.
ENDFORM.

FORM f_sanction_country.
   SELECT werks FROM t001w INTO TABLE gt_i_werks WHERE werks IN s_werks.
   IF sy-subrc <> 0.
      MESSAGE e014(zl) WITH TEXT-101.
   ELSE.
      CLEAR s_werks. REFRESH s_werks.
      LOOP AT gt_i_werks INTO DATA(ls_werks).
         AUTHORITY-CHECK OBJECT 'M_MATE_WRK' ID 'ACTVT' FIELD '03' ID 'WERKS' FIELD ls_werks-werks.
         IF sy-subrc = 0.
            s_werks-sign = 'I'. s_werks-option = 'EQ'.
            s_werks-low = ls_werks-werks. APPEND s_werks.
         ENDIF.
      ENDLOOP.
   ENDIF.
   IF s_werks[] IS INITIAL.
      MESSAGE e014(zl) WITH TEXT-102.
   ENDIF.
ENDFORM.

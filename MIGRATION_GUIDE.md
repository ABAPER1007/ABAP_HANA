# S/4HANA Migration and Modern ABAP Refactoring Guide

This guide outlines the key considerations for migrating SAP ECC ABAP code to S/4HANA, adopting modern ABAP 7.4/7.5 syntax standards, and refactoring procedural code (Subroutines) to Object-Oriented patterns.

## 1. ECC to S/4HANA Migration Checklist

### 1.1. Data Model Changes (Simplifications)
S/4HANA introduces significant data model simplifications. Code relying on direct table access might fail or perform poorly.
*   **Material Number Extension (MATNR):** Extended from 18 to 40 characters. Use valid API calls/conversion routines (`CONVERSION_EXIT_MATN1_...`) instead of direct length assumptions.
*   **Inventory Management:** `MSEG` and `MKPF` are replaced by `MATDOC` (proxy views exist, but beware of performance). Aggregates like `MARD`, `MBEW` are dynamic views.
*   **Finance (Universal Journal):** `ACDOCA` consolidates data. Index tables (`BSIS`, `BSAS`, `BSID`, `BSAD`, `BSIK`, `BSAK`) and aggregate tables (`GLT0`, `KNC1`, `LFC1`) are now compatibility views.
*   **Pricing:** Table `KONV` is replaced by `PRCD_ELEMENTS`. Direct selects on `KONV` must be replaced with `PRC_API_*` methods or redirect views.
*   **Status Management:** Tables `TJ02`, `TJ03`, etc. might have changes; prefer standard function modules.

### 1.2. Obsolete Statements and Function Modules
*   **Native SQL:** Remove `EXEC SQL` blocks. Use ADBC (ABAP Database Connectivity) or AMDP (ABAP Managed Database Procedures).
*   **File I/O:** Function modules like `GUI_UPLOAD`, `GUI_DOWNLOAD`, `WS_FILENAME_GET` are obsolete/forbidden in some contexts (e.g., Fiori). Use `CL_GUI_FRONTEND_SERVICES`.
*   **Desupported Transactions:** Many ECC transactions (e.g., `MB01`, `MB1A`) are obsolete. Use `MIGO`.

### 1.3. ABAP Test Cockpit (ATC)
*   Run ATC with the variant **S4HANA_READINESS_2022** (or your target version).
*   Address all Priority 1 and 2 errors.
*   **ORDER BY:** `SELECT *` without `ORDER BY` returns data in an undefined order in HANA. Ensure `ORDER BY PRIMARY KEY` or specific fields if sorting is relied upon, especially before `BINARY SEARCH`.
*   **Pool/Cluster Tables:** These are transparent in HANA. Relying on their implicit sorting or special handling is no longer valid.

### 1.4. Security
*   **File Access:** `OPEN DATASET` must be preceded by an `AUTHORITY-CHECK OBJECT 'S_DATASET'`.
*   **SQL Injection:** Avoid dynamic SQL WHERE clauses generated from unsanitized user input.

---

## 2. ABAP 7.4 / 7.5 Syntax Standards

### 2.1. Declarations
*   **Inline Declarations:** Use `DATA(lv_var)` instead of pre-declaring variables at the top.
    *   *Example:* `LOOP AT gt_data INTO DATA(ls_data).`
*   **Constants:** Use `CONSTANTS` for magic numbers and fixed strings.

### 2.2. Internal Tables
*   **Header Lines:** **Strictly Forbidden.** Use explicit work areas or field symbols.
    *   *Bad:* `DATA: itab LIKE table OCCURS 0 WITH HEADER LINE.`
    *   *Good:* `DATA: gt_itab TYPE STANDARD TABLE OF table.`
*   **Reading:** Use table expressions for single line reads.
    *   *Old:* `READ TABLE itab INTO wa WITH KEY k = '1'.`
    *   *New:* `TRY. DATA(wa) = itab[ k = '1' ]. CATCH cx_sy_itab_line_not_found. ... ENDTRY.`
*   **Checking Existence:** `IF line_exists( itab[ k = '1' ] ).`
*   **Looping:** Use `LOOP AT ... ASSIGNING FIELD-SYMBOL(<fs>)` for performance.

### 2.3. Constructor Operators
*   **VALUE:** Build structures/tables inline.
    *   `DATA(ls_str) = VALUE ty_struc( field1 = 'A' field2 = 'B' ).`
*   **NEW:** Instantiate objects.
    *   `DATA(lo_obj) = NEW zcl_class( ).`
*   **COND / SWITCH:** Inline conditional logic.
    *   `DATA(res) = COND #( WHEN a > 10 THEN 'High' ELSE 'Low' ).`
*   **CORRESPONDING:** Move matching fields.
    *   `ls_target = CORRESPONDING #( ls_source ).`

### 2.4. Database Access (Open SQL Strict Mode)
*   **Comma Separation:** Fields in SELECT lists must be comma-separated.
*   **Host Variables:** Use `@` to escape ABAP variables.
*   **Inline Declaration:** `SELECT * FROM table INTO TABLE @DATA(lt_data).`
*   **Aggregates/Expressions:** perform calculations directly in SQL (e.g., `CAST`, `CASE`, arithmetic).

### 2.5. String Processing
*   **Templates:** Use pipe symbols `|` for concatenation and formatting.
    *   `DATA(msg) = |Error in material { ls_mat-matnr }: { lv_err_text }|.`.
*   **Functions:** Use built-in functions like `condense( )`, `to_upper( )`, `substring( )`.

---

## 3. Refactoring Subroutines (FORM) to Class Methods

### 3.1. Preparation
1.  **Analyze Global Data:** Identify which global variables are used in the `FORM`.
2.  **Grouping:** Group related `FORM`s that operate on the same data into a single Class.

### 3.2. Conversion Steps
1.  **Create Local/Global Class:** Start with a local class (`LCL_...`) inside the report if the logic is report-specific, or a global class (`ZCL_...`) if reusable.
2.  **Define Attributes:** Move global variables used by the subroutines to:
    *   **Instance Attributes:** If the data describes the state of an object.
    *   **Method Parameters (IMPORTING/CHANGING):** If the data is transient and only needed for that specific operation.
3.  **Define Methods:** Convert each `FORM` to a `METHOD`.
    *   `FORM get_data USING p_id CHANGING p_res` -> `METHOD get_data IMPORTING iv_id TYPE ... EXPORTING ev_res TYPE ...`
4.  **Visibility:**
    *   **PUBLIC:** Methods called from the main program (`START-OF-SELECTION`).
    *   **PRIVATE:** Helper methods called only internally by the class.
5.  **Exception Handling:** Replace `MESSAGE ... RAISING` or return codes (`sy-subrc`) with Class-based Exceptions (`CX_...`).

### 3.3. Calling the Class
*   Instantiate the class in the report event block.
*   Call the public entry method.

#### Example Refactoring

**Legacy (Procedural):**
```abap
DATA: gv_cnt TYPE i.

START-OF-SELECTION.
  PERFORM add_one USING 5 CHANGING gv_cnt.

FORM add_one USING p_num TYPE i CHANGING p_res TYPE i.
  p_res = p_num + 1.
ENDFORM.
```

**Modern (OO):**
```abap
CLASS lcl_logic DEFINITION.
  PUBLIC SECTION.
    METHODS: run.
  PRIVATE SECTION.
    METHODS: add_one IMPORTING iv_num TYPE i
                     RETURNING VALUE(rv_res) TYPE i.
ENDCLASS.

CLASS lcl_logic IMPLEMENTATION.
  METHOD run.
    DATA(lv_cnt) = add_one( 5 ).
  ENDMETHOD.

  METHOD add_one.
    rv_res = iv_num + 1.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  NEW lcl_logic( )->run( ).
```

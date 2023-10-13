CREATE OR REPLACE TYPE BODY T_USER_VIEWS AS
/**
 * Constructor. Sets all attributes to NULL.
 * @return  New object type instance.
 */

  CONSTRUCTOR FUNCTION T_USER_VIEWS
  RETURN SELF AS RESULT AS
  BEGIN
    RETURN;
  END T_USER_VIEWS;

/**
 * Constructor. Sets all attributes to corresponding column values in fetched
 * DBMS_SQL cursor.
 * @param   dbms_sql_cursor
 *                  Executed and fetched DBMS_SQL cursor on a query from
 *                  USER_VIEWS.
 * @return  New object type instance.
 */

  CONSTRUCTOR FUNCTION T_USER_VIEWS(dbms_sql_cursor IN INTEGER)
  RETURN SELF AS RESULT AS
  BEGIN

    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 01, view_name);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 02, text_length);
    -- Convert LONG to CLOB.
    text := F_LONG_TO_CLOB(dbms_sql_cursor,  03);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 04, type_text_length);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 05, type_text);

    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 06, oid_text_length);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 07, oid_text);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 08, view_type_owner);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 09, view_type);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 10, superview_name);

    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 11, editioning_view);
    DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 12, read_only);

    RETURN;

  END T_USER_VIEWS;

/**
 * Defines all columns in DBMS_SQL cursor.
 * @param   Parsed DBMS_SQL cursor on a query from USER_VIEWS.
 */

  MEMBER PROCEDURE DEFINE_COLUMNS(dbms_sql_cursor in integer) AS
  BEGIN

    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 01, view_name, 30);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 02, text_length);
    -- LONG column.
    DBMS_SQL.DEFINE_COLUMN_LONG(dbms_sql_cursor, 03);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 04, type_text_length);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 05, type_text, 4000);

    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 06, oid_text_length);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 07, oid_text, 4000);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 08, view_type_owner, 30);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 09, view_type, 30);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 10, superview_name, 30);

    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 11, editioning_view, 1);
    DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 12, read_only, 1);

  END DEFINE_COLUMNS;

END;
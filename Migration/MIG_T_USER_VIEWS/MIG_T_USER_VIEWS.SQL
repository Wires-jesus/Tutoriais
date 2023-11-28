DECLARE
  V_EXISTE VARCHAR2(100);
BEGIN
  BEGIN
    SELECT T.TYPE_NAME
      INTO V_EXISTE
      FROM ALL_TYPES T
     WHERE T.TYPE_NAME = 'T_USER_VIEWS_COLLECTION'
       AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
  EXCEPTION
    WHEN OTHERS THEN
      V_EXISTE := NULL;
  END;
  
  IF NOT V_EXISTE IS NULL THEN
    EXECUTE IMMEDIATE 'DROP TYPE T_USER_VIEWS_COLLECTION';
  END IF;
  
  BEGIN
    SELECT T.TYPE_NAME
      INTO V_EXISTE
      FROM ALL_TYPES T
     WHERE T.TYPE_NAME = 'T_USER_VIEWS'
       AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
  EXCEPTION
    WHEN OTHERS THEN
      V_EXISTE := NULL;
  END;
  
  IF NOT V_EXISTE IS NULL THEN
    EXECUTE IMMEDIATE 'DROP TYPE T_USER_VIEWS';
  END IF;
  
END;
\
CREATE OR REPLACE TYPE T_USER_VIEWS AS OBJECT (
/**
 * Object type representing columns in data dictionary view USER_VIEWS, with the
 * TEXT column represented by a CLOB instead of a LONG.
 * Source https://ellebaek.wordpress.com/2010/12/06/converting-a-long-column-to-a-clob-on-the-fly/
 */

  view_name        varchar2(30),
  text_length      number,
  -- CLOB instead of LONG.
  text             clob,
  type_text_length number,
  type_text        varchar2(4000),
  oid_text_length  number,
  oid_text         varchar2(4000),
  view_type_owner  varchar2(30),
  view_type        varchar2(30),
  superview_name   varchar2(30),
  --editioning_view  varchar2(1),
  --read_only        varchar2(1),

  CONSTRUCTOR FUNCTION T_USER_VIEWS
  RETURN SELF AS RESULT,
  CONSTRUCTOR FUNCTION T_USER_VIEWS(dbms_sql_cursor in integer)
  RETURN SELF AS RESULT,

  MEMBER PROCEDURE DEFINE_COLUMNS(dbms_sql_cursor in integer)

);
\
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

    --DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 11, editioning_view);
    --DBMS_SQL.COLUMN_VALUE(dbms_sql_cursor, 12, read_only);

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

    --DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 11, editioning_view, 1);
    --DBMS_SQL.DEFINE_COLUMN(dbms_sql_cursor, 12, read_only, 1);

  END DEFINE_COLUMNS;

END;
\
CREATE OR REPLACE TYPE T_USER_VIEWS_COLLECTION AS
TABLE OF T_USER_VIEWS;
/**
 * Defines type to T_USER_VIEWS
 * Source : https://ellebaek.wordpress.com/2010/12/06/converting-a-long-column-to-a-clob-on-the-fly/
 */
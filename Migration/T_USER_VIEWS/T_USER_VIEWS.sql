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
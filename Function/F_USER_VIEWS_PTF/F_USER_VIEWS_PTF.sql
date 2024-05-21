CREATE OR REPLACE FUNCTION F_USER_VIEWS_PTF(
  view_name_like IN VARCHAR2 := '%'
)
RETURN T_USER_VIEWS_COLLECTION PIPELINED AS

/**
 * Gets collection of user views representing rows in USER_VIEWS. Resolved
 * through a dynamic SQL query against USER_VIEWS and the TEXT column is
 * converted from a LONG to a CLOB.
 * @param   view_name_like
 *                  LIKE expression used in a WHERE clause predicate against
 *                  USER_VIEWS.VIEW_NAME. Default '%', ie all.
 * @return  Collection that can be used in a FROM clause with a TABLE() cast.
 * @source  https://ellebaek.wordpress.com/2010/12/06/converting-a-long-column-to-a-clob-on-the-fly/
 */

  query           VARCHAR2(500);
  dbms_sql_cursor BINARY_INTEGER;
  n               PLS_INTEGER;
  each            T_USER_VIEWS;

BEGIN
  query :=
     'select VIEW_NAME, ' ||
             'TEXT_LENGTH, ' || 
             'TEXT, ' ||
             'TYPE_TEXT_LENGTH, ' ||
             'TYPE_TEXT, ' ||
             'OID_TEXT_LENGTH, ' || 
             'OID_TEXT, ' || 
             'VIEW_TYPE_OWNER, ' ||
             'VIEW_TYPE, ' || 
             'SUPERVIEW_NAME ' ||
     'from   user_views uv ' ||
     'where length(uv.VIEW_NAME) <= 30' ||  
     '  and uv.view_name like :view_name_like' ;

  -- Create cursor, parse and bind.
  DBMS_SQL_CURSOR := dbms_sql.open_cursor;
  DBMS_SQL.PARSE(dbms_sql_cursor, query, dbms_sql.native);
  DBMS_SQL.BIND_VARIABLE(dbms_sql_cursor, 'view_name_like', view_name_like);

  -- Define columns through dummy object type instance.
  each := T_USER_VIEWS();
  EACH.DEFINE_COLUMNS(dbms_sql_cursor);

  -- Execute.
  n := DBMS_SQL.EXECUTE(dbms_sql_cursor);

  -- Fetch all rows, pipe each back.
  WHILE DBMS_SQL.FETCH_ROWS(dbms_sql_cursor) > 0 LOOP
    each := T_USER_VIEWS(dbms_sql_cursor);

    PIPE ROW(each);
  END LOOP;

  DBMS_SQL.CLOSE_CURSOR(dbms_sql_cursor);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('long_to_clob: ' || sqlerrm);
    DBMS_OUTPUT.PUT_LINE(dbms_utility.format_error_backtrace);
    IF DBMS_SQL.IS_OPEN(dbms_sql_cursor) THEN
      DBMS_SQL.CLOSE_CURSOR(dbms_sql_cursor);
    END IF;

    RAISE;
end F_USER_VIEWS_PTF;
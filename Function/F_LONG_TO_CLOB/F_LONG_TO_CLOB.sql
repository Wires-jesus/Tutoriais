CREATE OR REPLACE FUNCTION F_LONG_TO_CLOB(
  dbms_sql_cursor IN INTEGER,
  col_id in INTEGER
)
RETURN CLOB AS

/**
 * Fetches LONG column value and converts it to a CLOB.
 * @param   dbms_sql_cursor
 *                  DBMS_SQL cursor parsed, prepared (given column "defined"
 *                  with DBMS_SQL.DEFINE_COLUMN_LONG) and executed.
 * @param   col_id  Column ID.
 * @return  LONG column value as a CLOB.
 * @Source  https://ellebaek.wordpress.com/2010/12/06/converting-a-long-column-to-a-clob-on-the-fly/
 */

  long_val LONG;
  long_len INTEGER;
  buf_len  INTEGER := 32760;
  cur_pos  NUMBER := 0;

  RESULT   CLOB;

BEGIN
  -- Create CLOB.
  DBMS_LOB.CREATETEMPORARY(RESULT, FALSE, DBMS_LOB.CALL);

  -- Piecewise fetching of the LONG column, appending to the CLOB.
  LOOP
    DBMS_SQL.COLUMN_VALUE_LONG(
      dbms_sql_cursor,
      col_id,
      buf_len,
      cur_pos,
      long_val,
      long_len
    );

    EXIT WHEN long_len = 0;

    DBMS_LOB.APPEND(result, long_val);
    
    cur_pos := cur_pos + long_len;

  END LOOP;

  RETURN RESULT;

END F_LONG_TO_CLOB;
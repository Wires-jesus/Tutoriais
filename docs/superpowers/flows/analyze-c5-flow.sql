-- ============================================================================
-- Oracle Data Flow Analysis Script
-- Purpose: Extract cascading flow of C5/CONSINCO objects to monitorpdvmiddle
-- Author: Copilot
-- ============================================================================

SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
SET TERMOUT ON
SET LINESIZE 32767
SET LONG 20000
SET LONGCHUNKSIZE 20000

-- Set columns for CSV output
COL object_type FORMAT A30
COL object_name FORMAT A100
COL owner FORMAT A30
COL referenced_owner FORMAT A30
COL referenced_name FORMAT A100
COL referenced_type FORMAT A30

SPOOL &1

SELECT '=== C5/CONSINCO Flow Analysis ===' AS report_title FROM dual;
SELECT 'Generated: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS generated_date FROM dual;
SELECT '' AS blank_line FROM dual;

-- Extract all C5/CONSINCO objects
WITH c5_objects AS (
  SELECT 
    object_name,
    object_type,
    owner,
    CASE 
      WHEN object_name LIKE '%C5%' OR object_name LIKE '%CONSINCO%' THEN 1
      ELSE 0
    END AS is_c5
  FROM dba_objects
  WHERE (object_name LIKE '%C5%' OR object_name LIKE '%CONSINCO%')
    AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'VIEW')
),
-- Get direct dependencies
direct_deps AS (
  SELECT 
    d.name AS object_name,
    d.type AS object_type,
    d.owner,
    d.referenced_name,
    d.referenced_type,
    d.referenced_owner
  FROM dba_dependencies d
  WHERE (d.name LIKE '%C5%' OR d.name LIKE '%CONSINCO%')
    AND d.type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION', 'VIEW')
)
SELECT DISTINCT
  c.object_name,
  c.object_type,
  c.owner,
  NVL(dd.referenced_name, ''),
  NVL(dd.referenced_type, ''),
  NVL(dd.referenced_owner, '')
FROM c5_objects c
LEFT JOIN direct_deps dd ON c.object_name = dd.object_name AND c.owner = dd.owner
WHERE c.is_c5 = 1
ORDER BY c.object_name, dd.referenced_type DESC, dd.referenced_name;

SPOOL OFF

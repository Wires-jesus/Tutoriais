CREATE OR REPLACE PACKAGE PKG_CRC32
IS
  FUNCTION CALCULATE (
    A_DATA_I                       IN VARCHAR2
  , A_INIT_I                       IN INTEGER := 0
  ) RETURN INTEGER;

  FUNCTION CALCULATE10 (
    A_DATA_I                       IN VARCHAR2
  , A_INIT_I                       IN INTEGER := 0
  ) RETURN INTEGER;

END;
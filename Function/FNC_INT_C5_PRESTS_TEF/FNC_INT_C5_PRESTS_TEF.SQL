CREATE OR REPLACE FUNCTION FNC_INT_C5_PRESTS_TEF(pSeqDocto NUMBER)
  RETURN TB_PREST_DESD IS

  TYPE tList IS REF CURSOR;
  sList          tList;
  vList          T_PREST_DESD := T_PREST_DESD(0, 0, 0, 0, 0, 0, TRUNC(SYSDATE));
  vListTemp      T_PREST_DESD := T_PREST_DESD(0, 0, 0, 0, 0, 0, TRUNC(SYSDATE));
  ttList         TB_PREST_DESD := TB_PREST_DESD();
  vContador      INTEGER;
  vTotalParcelas NUMBER(18, 6);
  vDif           NUMBER(18, 6);
  vContParc      INTEGER;
  vCodfilial     VARCHAR2(2);

BEGIN

  BEGIN
    SELECT TO_CHAR(T.NROEMPRESA)
      INTO vCodfilial
      FROM MONITORPDVMIDDLE.TB_DOCTO T
     WHERE T.SEQDOCTO = pSeqDocto;
  EXCEPTION
    WHEN OTHERS THEN
      vCodfilial := '99';
  end;

  if FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('GERAPARCELAMENTOTEF',
                                        vCodfilial,
                                        'S') = 'S' then
  
    vContParc := 1;
    OPEN sList FOR
      select seqdocto,
             nrocheckout,
             nroempresa,
             seqitem,
             qtdparcelatef parcela,
             TRUNC((VLRTOTAL / NVL(qtdparcelatef, 1)), 2) valor,
             TRUNC(SYSDATE),
             VLRTOTAL VALORTOT
        from monitorpdvmiddle.tb_doctopagto
       where nvl(qtdparcelatef, 0) > 1
         AND seqdocto = pSeqDocto
       order by seqdocto, seqitem;
  
    LOOP
      FETCH sList
        INTO vList.seqdocto,
             vList.nrocheckout,
             vList.nroempresa,
             vList.seqitem,
             vList.parcela,
             vList.valor,
             vList.DTVENC,
             vTotalParcelas;
    
      EXIT WHEN sList%NOTFOUND;
    
      vContador := 1;
    
      LOOP
        --vListTemp := PREST_DESD(0, 0, 0, 0, 0, 0, TRUNC(SYSDATE));
        vListTemp := T_PREST_DESD(vList.seqdocto,
                                vList.nrocheckout,
                                vList.nroempresa,
                                vList.seqitem,
                                vContador,
                                vList.valor,
                                TRUNC(SYSDATE + (30 * vContador)));
        ttList.extend;
        ttList(ttList.Count) := vListTemp;
      
        vContador := vContador + 1;
        vContParc := vContParc + 1;
        EXIT WHEN vContador > vList.parcela;
      
      END LOOP;
    
      vDif := vTotalParcelas - (vList.Parcela * (vList.Valor));
    
      if vDif <> 0 then
        ttList(vContParc - 1).valor := ttList(vContParc - 1).valor + vDif;
      end if;
    
    END LOOP;
  
    CLOSE sList;
  
  end if;

  RETURN(ttList);

END FNC_INT_C5_PRESTS_TEF;
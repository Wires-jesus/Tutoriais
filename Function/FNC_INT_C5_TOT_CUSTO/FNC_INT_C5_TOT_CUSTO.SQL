CREATE OR REPLACE FUNCTION fnc_int_c5_tot_custo (pSeqDocto IN NUMBER,
                                  pNumeroCaixa IN NUMBER,
                                  pCodigoFilial IN NUMBER,
                  pTipoCusto VARCHAR2 DEFAULT 'F')
    RETURN NUMBER
IS
    vTotalCusto NUMBER;

BEGIN
/* 
 Interpretção do parametro pTipoCusto
                           'F' CustoFinanceiro,
                           'U' Custo Ultima Entrada,
                           'C' Custo Reposição,
                           'T' Custo Contabil,
						               'R' Custo Real,

*/
    SELECT  CASE pTipoCusto
               WHEN 'F' THEN SUM(NVL(S.vlcustofin,0)) 
               WHEN 'U' THEN SUM(NVL(S.vlcustoultent,0)) 
               WHEN 'C' THEN SUM(NVL(S.vlcustorep,0)) 
               WHEN 'T' THEN SUM(NVL(S.vlcustocont,0)) 
               WHEN 'R' THEN SUM(NVL(S.vlcustoreal,0)) 
               ELSE SUM(NVL(S.vlcustofin,0)) 
             END TOTCUSTO 
      INTO  vTotalCusto
      FROM  vw_int_c5_custos s,
            monitorpdvmiddle.tb_doctoitem i
     WHERE  i.nroempresa = s.codfilial
       AND  i.codacesso = s.codauxiliar
       AND  i.seqdocto = pSeqDocto
       AND  I.nroempresa = pCodigoFilial
       AND  i.nrocheckout = pNumeroCaixa;
    RETURN vTotalCusto;
END;
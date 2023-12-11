CREATE OR REPLACE FUNCTION CTE_VEICULO(P_TRANSACAO NUMBER)
  RETURN TABELA_CTE_VEICULO IS

  CURSOR CR_INF_VEICULO IS
     SELECT -- DADOS DO VEICULO
           CODVEICULO,
           RENAVAM,
           PLACA,
           PESOCARGAKG AS TARA,
           PESOCARGAKG2 AS CAPAC_VEICULO_KG,
           VOLUME AS CAPAC_VEICULO_M3,
           DECODE (NVL(PROPRIO,'S'), 'S', 0, 1) TIPO_PROD_VEICULO,
           TIPOVEICULO2 AS TIPO_VEICULO,
           TIPORODADO,
           TIPOCARROCERIA,
           UFPLACAVEICULO,
           --PROPRIETARIO DO VEICULO
           DECODE(NVL(PROPRIO,'S'), 'N',CGCCPFPROPRIETARIO) CGCCPFPROPRIETARIO,
           DECODE(NVL(PROPRIO,'S'), 'N',NOMEPROPRIETARIO) NOMEPROPRIETARIO,
           CODIGORNTRC,
           DECODE(NVL(PROPRIO,'S'), 'N',IEPROPRIETARIO) IEPROPRIETARIO,
           DECODE(NVL(PROPRIO,'S'), 'N',UFPROPRIETARIO) UFPROPRIETARIO,
           DECODE(NVL(PROPRIO,'S'), 'N',TIPOPROPRIETARIO) TIPOPROPRIETARIO,
           --MOTORISTA
           CPF  AS CPF_MOTORISTA,
           NOME AS NOME_MOTORISTA
            FROM (SELECT PCNFSAID.CODVEICULO,
                         PCVEICUL.RENAVAM,
                         PCVEICUL.PLACA,
                         PCVEICUL.PESOCARGAKG,
                         PCVEICUL.PESOCARGAKG2,
                         PCVEICUL.VOLUME,
                         PCVEICUL.PROPRIO,
                         PCVEICUL.TIPOVEICULO2,
                         PCVEICUL.TIPORODADO,
                         PCVEICUL.TIPOCARROCERIA,
                         PCVEICUL.UFPLACAVEICULO,
                         PCVEICUL.CGCCPFPROPRIETARIO,
                         PCVEICUL.NOMEPROPRIETARIO,
                         PCVEICUL.CODIGORNTRC,
                         PCVEICUL.IEPROPRIETARIO,
                         UPPER(PCVEICUL.UFPROPRIETARIO) UFPROPRIETARIO,
                         PCVEICUL.TIPOPROPRIETARIO,
                         PCEMPR.CPF,
                         PCEMPR.NOME
                    FROM PCNFSAID, PCVEICUL, PCEMPR
                   WHERE PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                     AND PCNFSAID.CODVEICULO = PCVEICUL.CODVEICULO
                     AND PCNFSAID.CODMOTORISTA = PCEMPR.MATRICULA(+)
                     AND PCNFSAID.ESPECIE IN ('CE', 'CO')
                  UNION ALL
                  SELECT PCNFSAID.CODVEICULO1,
                         PCVEICUL.RENAVAM,
                         PCVEICUL.PLACA,
                         PCVEICUL.PESOCARGAKG,
                         PCVEICUL.PESOCARGAKG2,
                         PCVEICUL.VOLUME,
                         PCVEICUL.PROPRIO,
                         PCVEICUL.TIPOVEICULO2,
                         PCVEICUL.TIPORODADO,
                         PCVEICUL.TIPOCARROCERIA,
                         PCVEICUL.UFPLACAVEICULO,
                         PCVEICUL.CGCCPFPROPRIETARIO,
                         PCVEICUL.NOMEPROPRIETARIO,
                         PCVEICUL.CODIGORNTRC,
                         PCVEICUL.IEPROPRIETARIO,
                         UPPER(PCVEICUL.UFPROPRIETARIO) UFPROPRIETARIO,
                         PCVEICUL.TIPOPROPRIETARIO,
                         PCEMPR.CPF,
                         PCEMPR.NOME
                    FROM PCNFSAID, PCVEICUL, PCEMPR
                   WHERE PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                     AND PCNFSAID.CODVEICULO1 = PCVEICUL.CODVEICULO
                     AND PCNFSAID.CODMOTORISTA = PCEMPR.MATRICULA(+)
                     AND PCNFSAID.ESPECIE IN ('CE', 'CO')
                  UNION ALL
                  SELECT PCNFSAID.CODVEICULO2,
                         PCVEICUL.RENAVAM,
                         PCVEICUL.PLACA,
                         PCVEICUL.PESOCARGAKG,
                         PCVEICUL.PESOCARGAKG2,
                         PCVEICUL.VOLUME,
                         PCVEICUL.PROPRIO,
                         PCVEICUL.TIPOVEICULO2,
                         PCVEICUL.TIPORODADO,
                         PCVEICUL.TIPOCARROCERIA,
                         PCVEICUL.UFPLACAVEICULO,
                         PCVEICUL.CGCCPFPROPRIETARIO,
                         PCVEICUL.NOMEPROPRIETARIO,
                         PCVEICUL.CODIGORNTRC,
                         PCVEICUL.IEPROPRIETARIO,
                         UPPER(PCVEICUL.UFPROPRIETARIO) UFPROPRIETARIO,
                         PCVEICUL.TIPOPROPRIETARIO,
                         PCEMPR.CPF,
                         PCEMPR.NOME
                    FROM PCNFSAID, PCVEICUL, PCEMPR
                   WHERE PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                     AND PCNFSAID.CODVEICULO2 = PCVEICUL.CODVEICULO
                     AND PCNFSAID.CODMOTORISTA = PCEMPR.MATRICULA(+)
                     AND PCNFSAID.ESPECIE IN ('CE', 'CO')
                  );

  RETORNO TABELA_CTE_VEICULO;
BEGIN
  RETORNO := TABELA_CTE_VEICULO();

  FOR ITEM IN CR_INF_VEICULO LOOP
    RETORNO.EXTEND;
    RETORNO(RETORNO.COUNT) := TIPO_CTE_VEICULO(CODVEICULO           => NULL,
                                               RENAVAM              => NULL,
                                               PLACA                => NULL,
                                               TARA                 => NULL,
                                               CAPAC_VEICULO_KG     => NULL,
                                               CAPAC_VEICULO_M3     => NULL,
                                               TIPO_PROD_VEICULO    => NULL,
                                               TIPO_VEICULO         => NULL,
                                               TIPORODADO           => NULL,
                                               TIPOCARROCERIA       => NULL,
                                               UFPLACAVEICULO       => NULL,
                                               CGCCPFPROPRIETARIO   => NULL,
                                               NOMEPROPRIETARIO     => NULL,
                                               CODIGORNTRC          => NULL,
                                               IEPROPRIETARIO       => NULL,
                                               UFPROPRIETARIO       => NULL,
                                               TIPOPROPRIETARIO     => NULL,
                                               CPF_MOTORISTA        => NULL,
                                               NOME_MOTORISTA       => NULL);
                                               
      RETORNO(RETORNO.COUNT).CODVEICULO           := ITEM.CODVEICULO;
      RETORNO(RETORNO.COUNT).RENAVAM              := ITEM.RENAVAM;
      RETORNO(RETORNO.COUNT).PLACA                := ITEM.PLACA;
      RETORNO(RETORNO.COUNT).TARA                 := ITEM.TARA;
      RETORNO(RETORNO.COUNT).CAPAC_VEICULO_KG     := ITEM.CAPAC_VEICULO_KG;
      RETORNO(RETORNO.COUNT).CAPAC_VEICULO_M3     := ITEM.CAPAC_VEICULO_M3;
      RETORNO(RETORNO.COUNT).TIPO_PROD_VEICULO    := ITEM.TIPO_PROD_VEICULO;
      RETORNO(RETORNO.COUNT).TIPO_VEICULO         := ITEM.TIPO_VEICULO;
      RETORNO(RETORNO.COUNT).TIPORODADO           := ITEM.TIPORODADO;
      RETORNO(RETORNO.COUNT).TIPOCARROCERIA       := ITEM.TIPOCARROCERIA;
      RETORNO(RETORNO.COUNT).UFPLACAVEICULO       := ITEM.UFPLACAVEICULO;
      RETORNO(RETORNO.COUNT).CGCCPFPROPRIETARIO   := ITEM.CGCCPFPROPRIETARIO;
      RETORNO(RETORNO.COUNT).NOMEPROPRIETARIO     := ITEM.NOMEPROPRIETARIO;
      RETORNO(RETORNO.COUNT).CODIGORNTRC          := ITEM.CODIGORNTRC;
      RETORNO(RETORNO.COUNT).IEPROPRIETARIO       := ITEM.IEPROPRIETARIO;
      RETORNO(RETORNO.COUNT).UFPROPRIETARIO       := ITEM.UFPROPRIETARIO;
      RETORNO(RETORNO.COUNT).TIPOPROPRIETARIO     := ITEM.TIPOPROPRIETARIO;
      RETORNO(RETORNO.COUNT).CPF_MOTORISTA        := ITEM.CPF_MOTORISTA;
      RETORNO(RETORNO.COUNT).NOME_MOTORISTA       := ITEM.NOME_MOTORISTA;                                               
  
  
  END LOOP;

  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
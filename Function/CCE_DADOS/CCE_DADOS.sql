CREATE OR REPLACE FUNCTION CCE_DADOS(P_NUMCARTACORRECAO NUMBER)
  RETURN TABELA_CCE_DADOS IS
  CURSOR CR_CCE IS
    --SAIDA
    SELECT DECODE(NVL(PCCARTACORRECAOC.AMBIENTECARTACORRECAO, 'X'),
                  'H',
                  2,
                  'P',
                  1,
                  -1) TIPO_AMBIENTE,
           PCFORNEC.CGC CNPJCPF,
           PCFILIAL.CODIGO CODIGO_EMITENTE,
           DECODE(NVL(PCCARTACORRECAOC.TIPODOC, 0),
                  0,
                  PCNFSAID.CHAVENFE,
                  PCNFSAID.CHAVECTE) CHAVENFE,
           PCCARTACORRECAOC.DATACARTACORRECAO DATAHORAEVENTO,
           PCESTADO.UF SIGLA_UF_EMITENTE,
           PCCARTACORRECAOC.NUMTRANSACAO,
           PCCARTACORRECAOC.MOVIMENTO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SERIALCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS SERIALCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PINCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS PINCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PROVIDERCERTIFICADOA3',
                                             PCFILIAL.CODIGO),
               'SafeSign Standard Cryptographic Service Provider') AS PROVIDERCERTIFICADOA3,
           NVL(PARAMFILIAL.OBTERCOMONUMBER('TIPOPROVIDERA3',
                                           PCFILIAL.CODIGO),
               1) AS TIPOPROVIDERA3,
           NVL(PCCARTACORRECAOC.TIPODOC, 0) AS TIPO_CCE
      FROM PCCARTACORRECAOC,
           PCFILIAL,
           PCNFSAID,
           PCFORNEC,
           PCCIDADE,
           PCESTADO
     WHERE PCNFSAID.NUMTRANSVENDA = PCCARTACORRECAOC.NUMTRANSACAO
       AND PCFILIAL.CODIGO = NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL)
       AND PCFORNEC.CODFORNEC = PCFILIAL.CODFORNEC
       AND PCFORNEC.CODCIDADE = PCCIDADE.CODCIDADE(+)
       AND PCCIDADE.UF = PCESTADO.UF(+)
       AND PCCARTACORRECAOC.ESPECIE = 'CE'
       AND PCCARTACORRECAOC.MOVIMENTO = 'S'
       AND PCCARTACORRECAOC.NUMCARTACORRECAO = P_NUMCARTACORRECAO
    UNION ALL
    --ENTRADA
    SELECT DECODE(NVL(PCCARTACORRECAOC.AMBIENTECARTACORRECAO, 'X'),
                  'H',
                  2,
                  'P',
                  1,
                  -1) TIPO_AMBIENTE,
           PCFORNEC.CGC CNPJCPF,
           PCFILIAL.CODIGO CODIGO_EMITENTE,
           DECODE(NVL(PCCARTACORRECAOC.TIPODOC, 0),
                  0,
                  PCNFENT.CHAVENFE,
                  PCNFENT.CHAVECTE) CHAVENFE,
           PCCARTACORRECAOC.DATACARTACORRECAO DATAHORAEVENTO,
           PCESTADO.UF SIGLA_UF_EMITENTE,
           PCCARTACORRECAOC.NUMTRANSACAO,
           PCCARTACORRECAOC.MOVIMENTO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SERIALCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS SERIALCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PINCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS PINCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PROVIDERCERTIFICADOA3',
                                             PCFILIAL.CODIGO),
               'SafeSign Standard Cryptographic Service Provider') AS PROVIDERCERTIFICADOA3,
           NVL(PARAMFILIAL.OBTERCOMONUMBER('TIPOPROVIDERA3',
                                           PCFILIAL.CODIGO),
               1) AS TIPOPROVIDERA3,
           NVL(PCCARTACORRECAOC.TIPODOC, 0) AS TIPO_CCE
      FROM PCCARTACORRECAOC,
           PCFILIAL,
           PCNFENT,
           PCFORNEC,
           PCCIDADE,
           PCESTADO
     WHERE PCNFENT.NUMTRANSENT = PCCARTACORRECAOC.NUMTRANSACAO
       AND (((NVL(PCCARTACORRECAOC.TIPODOC, 0) = 0) AND
            (PCNFENT.ESPECIE IN ('NF', 'EI'))) OR
            ((NVL(PCCARTACORRECAOC.TIPODOC, 0) = 1) AND
            (PCNFENT.ESPECIE IN ('CT', 'CO'))))
       AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
       AND PCFORNEC.CODFORNEC = PCFILIAL.CODFORNEC
       AND PCFORNEC.CODCIDADE = PCCIDADE.CODCIDADE(+)
       AND PCCIDADE.UF = PCESTADO.UF(+)
       AND PCCARTACORRECAOC.ESPECIE = 'CE'
       AND PCCARTACORRECAOC.MOVIMENTO = 'E'
       AND PCNFENT.TIPODESCARGA NOT IN ('6', '7', '8', 'C', 'T')
       AND PCCARTACORRECAOC.NUMCARTACORRECAO = P_NUMCARTACORRECAO
    UNION ALL
    SELECT DECODE(NVL(PCCARTACORRECAOC.AMBIENTECARTACORRECAO, 'X'),
                  'H',
                  2,
                  'P',
                  1,
                  -1) TIPO_AMBIENTE,
           PCFORNEC.CGC CNPJCPF,
           PCFILIAL.CODIGO CODIGO_EMITENTE,
           DECODE(NVL(PCCARTACORRECAOC.TIPODOC, 0),
                  0,
                  PCNFENT.CHAVENFE,
                  PCNFENT.CHAVECTE) CHAVENFE,
           PCCARTACORRECAOC.DATACARTACORRECAO DATAHORAEVENTO,
           PCESTADO.UF SIGLA_UF_EMITENTE,
           PCCARTACORRECAOC.NUMTRANSACAO,
           PCCARTACORRECAOC.MOVIMENTO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('SERIALCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS SERIALCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PINCERTIFICADO',
                                             PCFILIAL.CODIGO),
               '') AS PINCERTIFICADO,
           NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PROVIDERCERTIFICADOA3',
                                             PCFILIAL.CODIGO),
               'SafeSign Standard Cryptographic Service Provider') AS PROVIDERCERTIFICADOA3,
           NVL(PARAMFILIAL.OBTERCOMONUMBER('TIPOPROVIDERA3',
                                           PCFILIAL.CODIGO),
               1) AS TIPOPROVIDERA3,
           NVL(PCCARTACORRECAOC.TIPODOC, 0) AS TIPO_CCE
      FROM PCCARTACORRECAOC,
           PCFILIAL,
           PCNFENT,
           PCFORNEC,
           PCCIDADE,
           PCESTADO
     WHERE PCNFENT.NUMTRANSENT = PCCARTACORRECAOC.NUMTRANSACAO
       AND (((NVL(PCCARTACORRECAOC.TIPODOC, 0) = 0) AND
            (PCNFENT.ESPECIE IN ('NF', 'EI'))) OR
            ((NVL(PCCARTACORRECAOC.TIPODOC, 0) = 1) AND
            (PCNFENT.ESPECIE IN ('CT', 'CO'))))
       AND PCFILIAL.CODIGO = NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL)
       AND PCFORNEC.CODFORNEC = PCFILIAL.CODFORNEC
       AND PCFORNEC.CODCIDADE = PCCIDADE.CODCIDADE(+)
       AND PCCIDADE.UF = PCESTADO.UF(+)
       AND PCCARTACORRECAOC.ESPECIE = 'CE'
       AND PCCARTACORRECAOC.MOVIMENTO = 'E'
       AND PCNFENT.TIPODESCARGA IN ('6', '7', '8', 'C', 'T')
       AND PCCARTACORRECAOC.NUMCARTACORRECAO = P_NUMCARTACORRECAO;

  CURSOR CR_ITENS_CCE IS
    SELECT PCCARTACORRECAOI.DESCRICAOITEMCORRECAO ROTULO,
           PCCARTACORRECAOI.DESCRICAOCORRECAO     CORRECAO
      FROM PCCARTACORRECAOI
     WHERE PCCARTACORRECAOI.NUMCARTACORRECAO = P_NUMCARTACORRECAO;

  RETORNO         TABELA_CCE_DADOS;
  VCONDICAOUSONFE VARCHAR2(1500);
  VCONDICAOUSOCTE VARCHAR2(1500);
  VCORRECAO       VARCHAR2(1000);
BEGIN
  RETORNO         := TABELA_CCE_DADOS();
  VCORRECAO       := '';
  VCONDICAOUSONFE := 'A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, de 15 de dezembro de 1970 e pode ser utilizada para regularizacao de erro ocorrido na emissao de documento fiscal, desde que o erro nao esteja relacionado com: I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, diferenca de preco, quantidade, valor da operacao ou da prestacao; II - a correcao de dados cadastrais que implique mudanca do remetente ou do destinatario; III - a data de emissao ou de saida.';
  VCONDICAOUSOCTE := 'A Carta de Correcao e disciplinada pelo Art. 58-B do CONVENIO/SINIEF 06/89: Fica permitida a utilizacao de carta de correcao, para regularizacao de erro ocorrido na emissao de documentos fiscais relativos a prestacao de servico de transporte, desde que o erro nao esteja relacionado com: I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, diferenca de preco, quantidade, valor da prestacao;II - a correcao de dados cadastrais que implique mudanca do emitente, tomador, remetente ou do destinatario;III - a data de emissao ou de saida.';

  FOR ITEM IN CR_ITENS_CCE LOOP
    VCORRECAO := SUBSTR(VCORRECAO || ITEM.ROTULO || ': ' || ITEM.CORRECAO || '; ',
                        1,
                        999);
  END LOOP;

  FOR CCE IN CR_CCE LOOP
    RETORNO.EXTEND;
    RETORNO(RETORNO.COUNT) := TIPO_CCE_DADOS(TIPO_AMBIENTE         => NULL,
                                             CNPJCPF               => NULL,
                                             CODIGO_EMITENTE       => NULL,
                                             CHAVENFE              => NULL,
                                             DATAHORAEVENTO        => NULL,
                                             SIGLA_UF_EMITENTE     => NULL,
                                             NUMTRANSACAO          => NULL,
                                             MOVIMENTO             => NULL,
                                             SERIALCERTIFICADO     => NULL,
                                             PINCERTIFICADO        => NULL,
                                             TIPOPROVIDERA3        => NULL,
                                             PROVIDERCERTIFICADOA3 => NULL,
                                             CONDICAOUSO           => NULL,
                                             CORRECAO              => NULL,
                                             TIPO_CCE              => NULL);
  
    RETORNO(RETORNO.COUNT).TIPO_AMBIENTE := CCE.TIPO_AMBIENTE;
    RETORNO(RETORNO.COUNT).CNPJCPF := CCE.CNPJCPF;
    RETORNO(RETORNO.COUNT).CODIGO_EMITENTE := CCE.CODIGO_EMITENTE;
    RETORNO(RETORNO.COUNT).CHAVENFE := CCE.CHAVENFE;
    RETORNO(RETORNO.COUNT).DATAHORAEVENTO := CCE.DATAHORAEVENTO;
    RETORNO(RETORNO.COUNT).SIGLA_UF_EMITENTE := CCE.SIGLA_UF_EMITENTE;
    RETORNO(RETORNO.COUNT).NUMTRANSACAO := CCE.NUMTRANSACAO;
    RETORNO(RETORNO.COUNT).MOVIMENTO := CCE.MOVIMENTO;
    RETORNO(RETORNO.COUNT).SERIALCERTIFICADO := CCE.SERIALCERTIFICADO;
    RETORNO(RETORNO.COUNT).PINCERTIFICADO := CCE.PINCERTIFICADO;
    RETORNO(RETORNO.COUNT).TIPOPROVIDERA3 := CCE.TIPOPROVIDERA3;
    RETORNO(RETORNO.COUNT).PROVIDERCERTIFICADOA3 := CCE.PROVIDERCERTIFICADOA3;
    RETORNO(RETORNO.COUNT).CONDICAOUSO := (case
                                            when CCE.TIPO_CCE = 1 then
                                             SUBSTR(VCONDICAOUSOCTE, 1, 999)
                                            else
                                             SUBSTR(VCONDICAOUSONFE, 1, 999)
                                          end);
    RETORNO(RETORNO.COUNT).CORRECAO := SUBSTR(VCORRECAO, 1, 1499);
    RETORNO(RETORNO.COUNT).TIPO_CCE := CCE.TIPO_CCE;
  
  END LOOP;
  
  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN  
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END; 
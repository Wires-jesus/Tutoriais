CREATE OR REPLACE Package Body PKG_INT_C5_MOVCX Is

  Procedure processar_movimento_caixa(p_seqdocto Number Default 0) Is
    Cursor c_logaberturacx Is
      Select defseq_numpedecf.NEXTVAL numpedecf,
             a.numcaixa,
             a.codfunccxatual,
             a.dtabertura,
             a.seqturno,
             a.nroempresa,
             a.seqdocto,
             a.especie,
             a.ROWID,
             a.rowid_tb_docto
        From vw_int_c5_aberturacx a
       Where a.especie = 'AC'
         And a.seqdocto = DECODE(p_seqdocto, 0, a.seqdocto, p_seqdocto);

    r_logaberturacx      c_logaberturacx%Rowtype;
    l_xmltype            XMLTYPE;
    mensagemerro         Varchar2(1000);
    dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.TR_DADOS_PCFILAMENSAGEM;

    -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XML_MOVIMENTO_CAIXA )
    Function retornar_xml_movimento_caixa(r_logaberturacx c_logaberturacx%Rowtype)
      Return XMLTYPE Is
      l_xmlesquema      XMLTYPE;
      l_logaberturacx   XMLTYPE;
      l_fechamentomovcx XMLTYPE;
      l_logcaixa        XMLTYPE;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGABERTURACX )
      Function retornar_xmllogaberturacx(p_logaberturacx c_logaberturacx%Rowtype)
        Return XMLTYPE Is
        l_xmltypelogaberturacx XMLTYPE;
      Begin
        Select XMLELEMENT(PCLOGABERTURACX,
                          XMLAGG(XMLELEMENT(PCLOGABERTURACX,
                                            XMLFOREST(p_logaberturacx.numpedecf As
                                                      Numpedecf,
                                                      a.numcaixa As Numcaixa,
                                                      'F' As Posicaoant,
                                                      'A' As Posicaoatual,
                                                      Null As Codfunccxant,
                                                      a.codfunccxatual As
                                                      Codfunccxatual, --OPERADOR
                                                      a.codfunccxatual As
                                                      Codfuncfiscalcx, --FISCAL
                                                      a.dtabertura,
                                                      'S' As Exportado,
                                                      Null As Dtexportacao,
                                                      a.seqdocto As
                                                      Numfechamentomovcx))))
          Into l_xmltypelogaberturacx
          From vw_int_c5_aberturacx a
         Where numcaixa = p_logaberturacx.numcaixa
           And a.especie = 'AC'
           And a.dtabertura = p_logaberturacx.dtabertura
           And a.seqturno = p_logaberturacx.seqturno
           And a.nroempresa = p_logaberturacx.nroempresa
           And a.codfunccxatual = p_logaberturacx.codfunccxatual
           And ROWNUM = 1;

        Return l_xmltypelogaberturacx;
      End retornar_xmllogaberturacx;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLFECHAMENTOMOVCX )
      Function retornar_xmlfechamentomovcx(p_logaberturacx c_logaberturacx%Rowtype)
        Return XMLTYPE Is
        l_xmlfechamentomovcx XMLTYPE;
      Begin
        Select XMLELEMENT(PCFECHAMENTOMOVCX,
                          XMLAGG(XMLELEMENT(PCFECHAMENTOMOVCX,
                                            XMLFOREST(p_logaberturacx.numpedecf As
                                                      Numpedecf, --<Numpedecf>0</Numpedecf>
                                                      Null As Exportado, -->N</Exportado>
                                                      a.seqdocto As
                                                      Numfechamentomovcx, -->2854</Numfechamentomovcx>
                                                      a.nroempresa As
                                                      Codfilial, -->1</Codfilial>
                                                      a.numcaixa As Numcaixa, -->1</Numcaixa>
                                                      a.codfunccxatual As
                                                      Codfunccx, -->13</Codfunccx>
                                                      a.dtabertura As
                                                      Dtmovimentocx, -->2022-09-27</Dtmovimentocx>
                                                      a.dtabertura As
                                                      Dtabertura, -->2022-09-27T12:20:27</Dtabertura>
                                                      Null As Horaabertura, -->12</Horaabertura>
                                                      Null As Minutoabertura, -->9</Minutoabertura>
                                                      Null As Dtfechamento, --xsi:nil=true/>
                                                      Null As Horafechamento, --xsi:nil=true/>
                                                      Null As Minutofechamento, --xsi:nil=true/>
                                                      a.seqdocto As
                                                      Nummovimentopdv -->149</Nummovimentopdv> N�O TEM CONTADOR DE MOVIEMNTO
                                                      ))))
          Into l_xmlfechamentomovcx
          From vw_int_c5_aberturacx a
         Where a.especie In ('FC', 'FM')
           And numcaixa = p_logaberturacx.numcaixa
           And a.dtabertura = p_logaberturacx.dtabertura
           And a.seqturno = p_logaberturacx.seqturno
           And a.nroempresa = p_logaberturacx.nroempresa
           And a.codfunccxatual = p_logaberturacx.codfunccxatual
           And ROWNUM = 1;

        Return l_xmlfechamentomovcx;
      End retornar_xmlfechamentomovcx;

      -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_XMLLOGCAIXA )
      Function retornar_xmllogcaixa(p_logaberturacx c_logaberturacx%Rowtype)
        Return XMLTYPE Is
        l_xmltypepclogcaixa XMLTYPE;
      Begin
        Select XMLELEMENT(PCLOGCAIXA,
                          XMLAGG(XMLELEMENT(PCLOGCAIXA,
                                            XMLFOREST(p_logaberturacx.numpedecf As
                                                      numpedecf,
                                                      a.dtabertura As Data, -->2022-09-27</Data>
                                                      Null As Hora, --<Hora>12</Hora>
                                                      Null As Minuto, --<Minuto>20</Minuto>
                                                      a.Numcaixa As Numcaixa, --->1</Numcaixa>
                                                      a.codfunccxatual As
                                                      Codfunccx, --->13</Codfunccx> OPERADOR
                                                      a.codfunccxatual As
                                                      Codfiscalcx, --->14</Codfiscalcx> FISCAL
                                                      '1' As Codcli,
                                                      '0' As Valor,
                                                      Case a.especie
                                                        When 'FC' Then
                                                         'Caixa Aberto pelo Fiscal de Caixa' ||
                                                         ' - ' ||
                                                         a.codfunccxatual || '' -->4-Caixa Aberto pelo Fiscal de Caixa</Historico>
                                                        When 'AC' Then
                                                         'Caixa Fechado pelo Fiscal de Caixa' ||
                                                         ' - ' ||
                                                         a.codfunccxatual || '' -->4-Caixa Fechado pelo Fiscal de Caixa</Historico>
                                                      End As Historico,
                                                      '0' As Numseqitem,
                                                      '0' As Numcupom,
                                                      a.seqdocto As Numseq, --->1230012227</Numseq>
                                                      a.nroempresa As
                                                      Codfilial, -->1</Codfilial>
                                                      Null As
                                                      Motivocancelamento, -- xsi:nil=true/>
                                                      Null As Dtexportacao, --xsi:nil=true/>
                                                      Null As Exportado -->N</Exportado
                                                      ))))
          Into l_xmltypepclogcaixa
          From vw_int_c5_aberturacx a
         Where a.especie In ('AC', 'FC', 'CX', 'FM')
           And numcaixa = p_logaberturacx.numcaixa
           And a.dtabertura = p_logaberturacx.dtabertura
           And a.seqturno = p_logaberturacx.seqturno
           And a.nroempresa = p_logaberturacx.nroempresa
           And a.codfunccxatual = p_logaberturacx.codfunccxatual
           And ROWNUM = 1;

        Return l_xmltypepclogcaixa;
      End retornar_xmllogcaixa;
    Begin
      l_logaberturacx   := retornar_xmllogaberturacx(r_logaberturacx);
      l_fechamentomovcx := retornar_xmlfechamentomovcx(r_logaberturacx);
      l_logcaixa        := retornar_xmllogcaixa(r_logaberturacx);

      Select XMLELEMENT(EsquemaExportacao,
                        XMLELEMENT(Complemento,
                                   l_logaberturacx,
                                   l_fechamentomovcx,
                                   l_logcaixa)) esquemaexportacao
        Into l_xmlesquema
        From DUAL;

      Return l_xmlesquema;
    End retornar_xml_movimento_caixa;

    -- PROCESSAR_MOVIMENTO_CAIXA ( RETORNAR_PCFILAMENSAGEM )
    Function retornar_pcfilamensagem(r_logaberturacx c_logaberturacx%Rowtype)
      Return PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem Is
      dados_pcfilamensagem PKG_SINC_PDV_CONSINCO_UTIL.tr_dados_pcfilamensagem;
      l_xmltype            XMLTYPE;
      daodoscabecalhoxml   Varchar2(200) := '<?xml version=1.0 encoding=UTF-8 standalone=yes?> <EsquemaExportacao xmlns:xsi=http://www.w3.org/2001/XMLSchema-instance xmlns:xsd=http://www.w3.org/2001/XMLSchema>';
    Begin
      -- recebe xml da VENDA
      l_xmltype := retornar_xml_movimento_caixa(r_logaberturacx);

      dados_pcfilamensagem.rowpcfilamensagem.idmensagem          := dfseq_pcfilamensagem.NEXTVAL;
      dados_pcfilamensagem.rowpcfilamensagem.datatransacao       := Sysdate;
      dados_pcfilamensagem.rowpcfilamensagem.codfilial           := '1';
      dados_pcfilamensagem.rowpcfilamensagem.numcaixa            := '10';
      dados_pcfilamensagem.rowpcfilamensagem.numnota             := 109;
      dados_pcfilamensagem.rowpcfilamensagem.serie               := Null;
      dados_pcfilamensagem.rowpcfilamensagem.chavesefaz          := Null;
      dados_pcfilamensagem.rowpcfilamensagem.protocolo           := Null;
      dados_pcfilamensagem.rowpcfilamensagem.contingencia        := 'N';
      dados_pcfilamensagem.rowpcfilamensagem.idexterno           := dados_pcfilamensagem.rowpcfilamensagem.idmensagem || '-' ||
                                                                    r_logaberturacx.seqdocto || '-' ||
                                                                    r_logaberturacx.numcaixa || '-' ||
                                                                    r_logaberturacx.especie;
      dados_pcfilamensagem.rowpcfilamensagem.status              := 0;
      dados_pcfilamensagem.rowpcfilamensagem.qtprocessamento     := Null;
      dados_pcfilamensagem.rowpcfilamensagem.tipodocumento       := 'OD';
      dados_pcfilamensagem.rowpcfilamensagem.tipooperacao        := 'MOVC';
      dados_pcfilamensagem.rowpcfilamensagem.mensagem            := Replace(l_xmltype.getclobval(),
                                                                            '<EsquemaExportacao>',
                                                                            daodoscabecalhoxml);
      dados_pcfilamensagem.rowpcfilamensagem.tipomensagem        := 1;
      dados_pcfilamensagem.rowpcfilamensagem.codigoerro          := Null;
      dados_pcfilamensagem.rowpcfilamensagem.dataultimaalteracao := Sysdate;
      dados_pcfilamensagem.rowpcfilamensagem.pdvorigem           := 'consinco';
      dados_pcfilamensagem.rowpcfilamensagem.qtreprocessado      := Null;

      Return dados_pcfilamensagem;
    End retornar_pcfilamensagem;
  Begin
    ------------- INICIO LOOP C_LOGABERTURACX ---------------
    Execute Immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';

    Open c_logaberturacx;

    Fetch c_logaberturacx
      Into r_logaberturacx;

    While c_logaberturacx%Found Loop
      Begin
        -- insere os dados da PCFILAMENSAGEM
        dados_pcfilamensagem := retornar_pcfilamensagem(r_logaberturacx);
        PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem(dados_pcfilamensagem);

        --ATUALIZA O REGISTRO na tabela consinco
        Update monitorpdvmiddle.tb_docto
           Set replicacao = 'F'
         Where Rowid = r_logaberturacx.rowid_tb_docto;
      Exception
        When Others Then
          mensagemerro := 'Consinco - erro ao persistir Abertura/Fechamento de caixa na tabela PCFILAMENSAGEM - ERROR: ' ||
                          Sqlcode || '-' || Sqlerrm || '- LINHA: ' ||
                          DBMS_UTILITY.format_error_backtrace;

          Update monitorpdvmiddle.tb_docto
             Set replicacao = 'E'
           Where Rowid = r_logaberturacx.rowid_tb_docto;

          PKG_SINC_PDV_CONSINCO_UTIL.inserir_pcfilamensagem_erro(dados_pcfilamensagem,
                                                                 mensagemerro);
          --ROLLBACK;
      End;

      Fetch c_logaberturacx
        Into r_logaberturacx;
    End Loop;

    Close c_logaberturacx;
    ------------- FIM LOOP C_LOGABERTURACX ---------------
  End processar_movimento_caixa;
End PKG_INT_C5_MOVCX;

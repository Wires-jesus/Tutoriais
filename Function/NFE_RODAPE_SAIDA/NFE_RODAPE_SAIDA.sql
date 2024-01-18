CREATE OR REPLACE FUNCTION NFE_RODAPE_SAIDA(P_TRANSACAO NUMBER)
  RETURN TABELA_NFE_RODAPE IS
  CURSOR CR_RODAPE IS
    SELECT *
    FROM   SQL_NFE_RODAPE_SAIDA RODAPE
    WHERE  RODAPE.NUM_TRANSACAO = P_TRANSACAO;

  CURSOR CR_RODAPE_COMPL IS
    SELECT *
    FROM   SQL_NFE_RODAPE_SAIDA_COMP RODAPE
    WHERE  RODAPE.NUM_TRANSACAO = P_TRANSACAO;

  RETORNO TABELA_NFE_RODAPE;
BEGIN
  RETORNO := TABELA_NFE_RODAPE();

  FOR RODAPE IN CR_RODAPE
  LOOP
    RETORNO.EXTEND;

    RETORNO(RETORNO.COUNT) := TIPO_NFE_RODAPE(ANTT                  => NULL,
                                              BASE_ICMS             => NULL,
                                              BASE_ICMS_ST          => NULL,
                                              BASE_ISS              => NULL,
                                              CIDADE_TRANSPORTADOR  => NULL,
                                              CNPJ_TRANSPORTADOR    => NULL,
                                              CODMOTORISTA          => NULL,
                                              DTENTREGA             => NULL,
                                              END_TRANSPORTADOR     => NULL,
                                              ESPECIEVOLUME         => NULL,
                                              ESTADO_TRANSPORTADOR  => NULL,
                                              IE_TRANSPORTADOR      => NULL,
                                              MARCAVOLUME           => NULL,
                                              MODALIDADE_FRETE      => NULL,
                                              NOME_MOTORISTA        => NULL,
                                              NUMCAR                => NULL,
                                              NUM_VOLUME            => NULL,
                                              NUMVOL                => NULL,
                                              NUMVOLUMESCONFERENCIA => NULL,
                                              VOLUME_PEDIDO         => NULL,
                                              PESO_BRUTO            => NULL,
                                              PESO_LIQUIDO          => NULL,
                                              PLACA                 => NULL,
                                              PLACA_UF              => NULL,
                                              TRANSPORTADOR         => NULL,
                                              VLDESCRODAPE          => NULL,
                                              VALOR_COFINS          => NULL,
                                              VALOR_DESCONTO        => NULL,
                                              VALOR_FRETE           => NULL,
                                              VALOR_ICMS            => NULL,
                                              VALOR_ICMS_ST         => NULL,
                                              VALOR_IPI             => NULL,
                                              VALOR_II              => NULL,
                                              VALOR_ISS             => NULL,
                                              VALOR_OUTRO           => NULL,
                                              VALOR_PIS             => NULL,
                                              VALOR_TOTAL           => NULL,
                                              VALOR_TOTAL_PRODUTOS  => NULL,
                                              NVOL                  => NULL,
                                              INFOADICIONALFISCO    => NULL,
                                              NUM_VOLUME_EMB        => NULL,
                                              DESC_PL_PAGTO         => NULL,
                                              VLTOTALIMPOSTOS       => NULL,
                                              VALOR_TOTAL_SEGURO    => NULL,
                                              VALOR_TOTAL_DESONERADO => NULL,
                                              VLFCPPART             => NULL,
                                              VLICMSPARTDEST        => NULL,
                                              VLICMSPARTREM         => NULL,
                                              VLBASEFCPICMS         => NULL,
                                              VLBASEFCPST           => NULL,
                                              VLBCFCPSTRET          => NULL,
                                              VLFCPSTRET            => NULL,
                                              VLCREDFCPICMSSN       => NULL,
                                              VLFECP                => NULL,
                                              VLACRESCIMOFUNCEP     => NULL,
                                              VALOR_IPI_DEVOLVIDO   => NULL,
                                              DATACONSOLIDACAOPREFAT => NULL,
                                              PREFATURAMENTO         => NULL,
                                              VALOR_SERVICO_TRANSP   => NULL,
                                              BASE_RETENCAO_ICMS_TRANSP    => NULL,
                                              PERC_RETENCAO_ICMS_TRANSP    => NULL,
                                              VALOR_RETENCAO_ICMS_TRANSP  => NULL,
                                              CFOP_TRANSP      => NULL,
                                              COD_MUN_FATO_GERADOR_TRANSP => NULL,
                                              FINALIDADENFE => NULL,
                                              GERAGRPRETTRIB    => NULL,
                                              VLPISRETORGPUB    => NULL,
                                              VLCOFINSRETORGPUB => NULL,
                                              VLCSLLRETORGPUB   => NULL,
                                              VLIRPJRETORGPUB   => NULL,
                                              VLBCIRRFRETORGPUB => NULL,
                                              QBCMONO           => NULL,
                                              VICMSMONO         => NULL,
                                              QBCMONORETEN      => NULL,
                                              VICMSMONORETEN    => NULL,
                                              QBCMONODIF        => NULL,
                                              VICMSMONODIF      => NULL,
                                              QBCMONORET        => NULL,
                                              VICMSMONORET      => NULL);

    RETORNO(RETORNO.COUNT).ANTT                  := RODAPE.ANTT;
    RETORNO(RETORNO.COUNT).BASE_ICMS             := RODAPE.BASE_ICMS;
    RETORNO(RETORNO.COUNT).BASE_ICMS_ST          := RODAPE.BASE_ICMS_ST;
    RETORNO(RETORNO.COUNT).BASE_ISS              := RODAPE.BASE_ISS;
    RETORNO(RETORNO.COUNT).FINALIDADENFE         := RODAPE.FINALIDADENFE;

    IF (RODAPE.MODALIDADE_FRETE = 9) OR (RODAPE.FINALIDADENFE IN ('2','3')) THEN
      RETORNO(RETORNO.COUNT).CIDADE_TRANSPORTADOR  := NULL;
      RETORNO(RETORNO.COUNT).CNPJ_TRANSPORTADOR    := NULL;
      RETORNO(RETORNO.COUNT).END_TRANSPORTADOR     := NULL;
      RETORNO(RETORNO.COUNT).ESTADO_TRANSPORTADOR  := NULL;
      RETORNO(RETORNO.COUNT).IE_TRANSPORTADOR      := NULL;
      RETORNO(RETORNO.COUNT).TRANSPORTADOR         := NULL;
    ELSE
      RETORNO(RETORNO.COUNT).TRANSPORTADOR         := RODAPE.TRANSPORTADOR;
      RETORNO(RETORNO.COUNT).IE_TRANSPORTADOR      := RODAPE.IE_TRANSPORTADOR;
      RETORNO(RETORNO.COUNT).END_TRANSPORTADOR     := RODAPE.END_TRANSPORTADOR;
      RETORNO(RETORNO.COUNT).CNPJ_TRANSPORTADOR    := RODAPE.CNPJ_TRANSPORTADOR;
      RETORNO(RETORNO.COUNT).CIDADE_TRANSPORTADOR  := RODAPE.CIDADE_TRANSPORTADOR;
      RETORNO(RETORNO.COUNT).ESTADO_TRANSPORTADOR  := RODAPE.ESTADO_TRANSPORTADOR;
    END IF;

    RETORNO(RETORNO.COUNT).CODMOTORISTA          := RODAPE.CODMOTORISTA;
    RETORNO(RETORNO.COUNT).DTENTREGA             := RODAPE.DTENTREGA;
    RETORNO(RETORNO.COUNT).ESPECIEVOLUME         := RODAPE.ESPECIEVOLUME;
    RETORNO(RETORNO.COUNT).MARCAVOLUME           := RODAPE.MARCAVOLUME;
    RETORNO(RETORNO.COUNT).MODALIDADE_FRETE      := RODAPE.MODALIDADE_FRETE;
    RETORNO(RETORNO.COUNT).NOME_MOTORISTA        := RODAPE.NOME_MOTORISTA;
    RETORNO(RETORNO.COUNT).NUMCAR                := RODAPE.NUMCAR;
    RETORNO(RETORNO.COUNT).NUM_VOLUME            := RODAPE.NUM_VOLUME;
    RETORNO(RETORNO.COUNT).NUMVOL                := NVL(RODAPE.NUMVOL,1);
    RETORNO(RETORNO.COUNT).NUMVOLUMESCONFERENCIA := RODAPE.NUMVOLUMESCONFERENCIA;
    RETORNO(RETORNO.COUNT).VOLUME_PEDIDO         := RODAPE.VOLUME_PEDIDO;
    RETORNO(RETORNO.COUNT).PESO_BRUTO            := RODAPE.PESO_BRUTO;
    RETORNO(RETORNO.COUNT).PESO_LIQUIDO          := RODAPE.PESO_LIQUIDO;
    RETORNO(RETORNO.COUNT).PLACA                 := RODAPE.PLACA;
    RETORNO(RETORNO.COUNT).PLACA_UF              := RODAPE.PLACA_UF;
    RETORNO(RETORNO.COUNT).TRANSPORTADOR         := RODAPE.TRANSPORTADOR;
    RETORNO(RETORNO.COUNT).VLDESCRODAPE          := RODAPE.VLDESCRODAPE;
    RETORNO(RETORNO.COUNT).VALOR_COFINS          := RODAPE.VALOR_COFINS;
    RETORNO(RETORNO.COUNT).VALOR_DESCONTO        := RODAPE.VALOR_DESCONTO;
    RETORNO(RETORNO.COUNT).VALOR_FRETE           := RODAPE.VALOR_FRETE;
    RETORNO(RETORNO.COUNT).VALOR_ICMS            := RODAPE.VALOR_ICMS;
    RETORNO(RETORNO.COUNT).VALOR_ICMS_ST         := RODAPE.VALOR_ICMS_ST;
    RETORNO(RETORNO.COUNT).VALOR_IPI             := RODAPE.VALOR_IPI;
    RETORNO(RETORNO.COUNT).VALOR_II              := RODAPE.VALOR_II;
    RETORNO(RETORNO.COUNT).VALOR_ISS             := RODAPE.VALOR_ISS;
    RETORNO(RETORNO.COUNT).VALOR_OUTRO           := RODAPE.VALOR_OUTRO;
    RETORNO(RETORNO.COUNT).VALOR_PIS             := RODAPE.VALOR_PIS;
    RETORNO(RETORNO.COUNT).VALOR_TOTAL           := RODAPE.VALOR_TOTAL;
    RETORNO(RETORNO.COUNT).VALOR_TOTAL_PRODUTOS  := RODAPE.VALOR_TOTAL_PRODUTOS;
    RETORNO(RETORNO.COUNT).NVOL                  := NVL(RODAPE.NUMVOL,1);
    RETORNO(RETORNO.COUNT).INFOADICIONALFISCO    := NULL;
    RETORNO(RETORNO.COUNT).NUM_VOLUME_EMB        := NVL(RODAPE.NUM_VOLUME_EMB, RODAPE.NUM_VOLUME);
    RETORNO(RETORNO.COUNT).DESC_PL_PAGTO         := RODAPE.DESC_PL_PAGTO;
    RETORNO(RETORNO.COUNT).VLTOTALIMPOSTOS       := RODAPE.VLTOTALIMPOSTOS;
    RETORNO(RETORNO.COUNT).VALOR_TOTAL_SEGURO    := RODAPE.VALOR_TOTAL_SEGURO;
    RETORNO(RETORNO.COUNT).VALOR_TOTAL_DESONERADO:= RODAPE.VALOR_TOTAL_DESONERADO;
    RETORNO(RETORNO.COUNT).VLFCPPART             := RODAPE.VLFCPPART;
    RETORNO(RETORNO.COUNT).VLICMSPARTDEST        := RODAPE.VLICMSPARTDEST;
    RETORNO(RETORNO.COUNT).VLICMSPARTREM         := RODAPE.VLICMSPARTREM;
    RETORNO(RETORNO.COUNT).VLBASEFCPICMS         := RODAPE.VLBASEFCPICMS;
    RETORNO(RETORNO.COUNT).VLBASEFCPST           := RODAPE.VLBASEFCPST;
    RETORNO(RETORNO.COUNT).VLBCFCPSTRET          := RODAPE.VLBCFCPSTRET;
    RETORNO(RETORNO.COUNT).VLFCPSTRET            := RODAPE.VLFCPSTRET;
    RETORNO(RETORNO.COUNT).VLCREDFCPICMSSN       := RODAPE.VLCREDFCPICMSSN;
    RETORNO(RETORNO.COUNT).VLFECP                := RODAPE.VLFECP;
    RETORNO(RETORNO.COUNT).VLACRESCIMOFUNCEP     := RODAPE.VLACRESCIMOFUNCEP;
    RETORNO(RETORNO.COUNT).VALOR_IPI_DEVOLVIDO   := RODAPE.VALOR_IPI_DEVOLVIDO;
    RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT:= RODAPE.DATACONSOLIDACAOPREFAT;
    RETORNO(RETORNO.COUNT).PREFATURAMENTO        := RODAPE.PREFATURAMENTO;
    RETORNO(RETORNO.COUNT).VALOR_SERVICO_TRANSP        := RODAPE.VALOR_SERVICO_TRANSP;
    RETORNO(RETORNO.COUNT).BASE_RETENCAO_ICMS_TRANSP   := RODAPE.BASE_RETENCAO_ICMS_TRANSP;
    RETORNO(RETORNO.COUNT).PERC_RETENCAO_ICMS_TRANSP   := RODAPE.PERC_RETENCAO_ICMS_TRANSP;
    RETORNO(RETORNO.COUNT).VALOR_RETENCAO_ICMS_TRANSP  := RODAPE.VALOR_RETENCAO_ICMS_TRANSP;
    RETORNO(RETORNO.COUNT).CFOP_TRANSP                 := RODAPE.CFOP_TRANSP;
    RETORNO(RETORNO.COUNT).COD_MUN_FATO_GERADOR_TRANSP := RODAPE.COD_MUN_FATO_GERADOR_TRANSP;
    RETORNO(RETORNO.COUNT).GERAGRPRETTRIB              := RODAPE.GERAGRPRETTRIB;
    RETORNO(RETORNO.COUNT).VLPISRETORGPUB              := RODAPE.VLPISRETORGPUB;
    RETORNO(RETORNO.COUNT).VLCOFINSRETORGPUB           := RODAPE.VLCOFINSRETORGPUB;
    RETORNO(RETORNO.COUNT).VLCSLLRETORGPUB             := RODAPE.VLCSLLRETORGPUB;
    RETORNO(RETORNO.COUNT).VLIRPJRETORGPUB             := RODAPE.VLIRPJRETORGPUB;
    RETORNO(RETORNO.COUNT).VLBCIRRFRETORGPUB           := RODAPE.VLBCIRRFRETORGPUB;   
    RETORNO(RETORNO.COUNT).QBCMONO                     := RODAPE.QBCMONO;
    RETORNO(RETORNO.COUNT).VICMSMONO                   := RODAPE.VICMSMONO;
    RETORNO(RETORNO.COUNT).QBCMONORETEN                := RODAPE.QBCMONORETEN;
    RETORNO(RETORNO.COUNT).VICMSMONORETEN              := RODAPE.VICMSMONORETEN;
    RETORNO(RETORNO.COUNT).QBCMONODIF                  := RODAPE.QBCMONODIF;
    RETORNO(RETORNO.COUNT).VICMSMONODIF                := RODAPE.VICMSMONODIF;
    RETORNO(RETORNO.COUNT).QBCMONORET                  := RODAPE.QBCMONORET;
    RETORNO(RETORNO.COUNT).VICMSMONORET                := RODAPE.VICMSMONORET;     

  END LOOP;

  IF RETORNO.COUNT = 0 THEN
    FOR RODAPE IN CR_RODAPE_COMPL
    LOOP
      RETORNO.EXTEND;

      RETORNO(RETORNO.COUNT) := TIPO_NFE_RODAPE(ANTT                  => NULL,
                                                BASE_ICMS             => NULL,
                                                BASE_ICMS_ST          => NULL,
                                                BASE_ISS              => NULL,
                                                CIDADE_TRANSPORTADOR  => NULL,
                                                CNPJ_TRANSPORTADOR    => NULL,
                                                CODMOTORISTA          => NULL,
                                                DTENTREGA             => NULL,
                                                END_TRANSPORTADOR     => NULL,
                                                ESPECIEVOLUME         => NULL,
                                                ESTADO_TRANSPORTADOR  => NULL,
                                                IE_TRANSPORTADOR      => NULL,
                                                MARCAVOLUME           => NULL,
                                                MODALIDADE_FRETE      => NULL,
                                                NOME_MOTORISTA        => NULL,
                                                NUMCAR                => NULL,
                                                NUM_VOLUME            => NULL,
                                                NUMVOL                => NULL,
                                                NUMVOLUMESCONFERENCIA => NULL,
                                                VOLUME_PEDIDO         => NULL,
                                                PESO_BRUTO            => NULL,
                                                PESO_LIQUIDO          => NULL,
                                                PLACA                 => NULL,
                                                PLACA_UF              => NULL,
                                                TRANSPORTADOR         => NULL,
                                                VLDESCRODAPE          => NULL,
                                                VALOR_COFINS          => NULL,
                                                VALOR_DESCONTO        => NULL,
                                                VALOR_FRETE           => NULL,
                                                VALOR_ICMS            => NULL,
                                                VALOR_ICMS_ST         => NULL,
                                                VALOR_IPI             => NULL,
                                                VALOR_II              => NULL,
                                                VALOR_ISS             => NULL,
                                                VALOR_OUTRO           => NULL,
                                                VALOR_PIS             => NULL,
                                                VALOR_TOTAL           => NULL,
                                                VALOR_TOTAL_PRODUTOS  => NULL,
                                                NVOL                  => NULL,
                                                INFOADICIONALFISCO    => NULL,
                                                NUM_VOLUME_EMB        => NULL,
                                                DESC_PL_PAGTO         => NULL,
                                                VLTOTALIMPOSTOS       => NULL,
                                                VALOR_TOTAL_SEGURO    => NULL,
                                                VALOR_TOTAL_DESONERADO => NULL,
                                                VLFCPPART             => NULL,
                                                VLICMSPARTDEST        => NULL,
                                                VLICMSPARTREM         => NULL,
                                                VLBASEFCPICMS         => NULL,
                                                VLBASEFCPST           => NULL,
                                                VLBCFCPSTRET          => NULL,
                                                VLFCPSTRET            => NULL,
                                                VLCREDFCPICMSSN       => NULL,
                                                VLFECP                => NULL,
                                                VLACRESCIMOFUNCEP     => NULL,
                                                VALOR_IPI_DEVOLVIDO   => NULL,
                                                DATACONSOLIDACAOPREFAT => NULL,
                                                PREFATURAMENTO         => NULL,
                                                VALOR_SERVICO_TRANSP      => NULL,
                                                BASE_RETENCAO_ICMS_TRANSP   => NULL,
                                                PERC_RETENCAO_ICMS_TRANSP   => NULL,
                                                VALOR_RETENCAO_ICMS_TRANSP  => NULL,
                                                CFOP_TRANSP        => NULL,
                                                COD_MUN_FATO_GERADOR_TRANSP => NULL,
                                                FINALIDADENFE => NULL,
                                                GERAGRPRETTRIB    => NULL,
                                                VLPISRETORGPUB    => NULL,
                                                VLCOFINSRETORGPUB => NULL,
                                                VLCSLLRETORGPUB   => NULL,
                                                VLIRPJRETORGPUB   => NULL,
                                                VLBCIRRFRETORGPUB => NULL,
                                                QBCMONO           => NULL,
                                                VICMSMONO         => NULL,
                                                QBCMONORETEN      => NULL,
                                                VICMSMONORETEN    => NULL,
                                                QBCMONODIF        => NULL,
                                                VICMSMONODIF      => NULL,
                                                QBCMONORET        => NULL,
                                                VICMSMONORET      => NULL);

      RETORNO(RETORNO.COUNT).ANTT                  := NULL;
      RETORNO(RETORNO.COUNT).BASE_ICMS             := RODAPE.BASE_ICMS;
      RETORNO(RETORNO.COUNT).BASE_ICMS_ST          := RODAPE.BASE_ST;
      RETORNO(RETORNO.COUNT).BASE_ISS              := 0;
      RETORNO(RETORNO.COUNT).END_TRANSPORTADOR     := NULL;
      RETORNO(RETORNO.COUNT).CIDADE_TRANSPORTADOR  := NULL;
      RETORNO(RETORNO.COUNT).MODALIDADE_FRETE      := RODAPE.MODALIDADE_FRETE;
      RETORNO(RETORNO.COUNT).FINALIDADENFE         := RODAPE.FINALIDADENFE;


      IF (RODAPE.MODALIDADE_FRETE = 9) OR (RODAPE.FINALIDADENFE IN ('2','3')) THEN
        RETORNO(RETORNO.COUNT).CNPJ_TRANSPORTADOR    := NULL;
        RETORNO(RETORNO.COUNT).ESTADO_TRANSPORTADOR  := NULL;
        RETORNO(RETORNO.COUNT).IE_TRANSPORTADOR      := NULL;
        RETORNO(RETORNO.COUNT).TRANSPORTADOR         := NULL;
      ELSE
        RETORNO(RETORNO.COUNT).TRANSPORTADOR         := RODAPE.TRANSPORTADOR;
        RETORNO(RETORNO.COUNT).IE_TRANSPORTADOR      := RODAPE.IE_TRANSPORTADOR;
        RETORNO(RETORNO.COUNT).CNPJ_TRANSPORTADOR    := RODAPE.CNPJ_TRANSPORTADOR;
        RETORNO(RETORNO.COUNT).ESTADO_TRANSPORTADOR  := RODAPE.ESTADO_TRANSPORTADOR;
      END IF;

      RETORNO(RETORNO.COUNT).CODMOTORISTA          := NULL;
      RETORNO(RETORNO.COUNT).DTENTREGA             := NULL;
      RETORNO(RETORNO.COUNT).ESPECIEVOLUME         := NULL;
      RETORNO(RETORNO.COUNT).MARCAVOLUME           := NULL;
      RETORNO(RETORNO.COUNT).NOME_MOTORISTA        := NULL;
      RETORNO(RETORNO.COUNT).NUMCAR                := NULL;
      RETORNO(RETORNO.COUNT).NUM_VOLUME            := NULL;
      RETORNO(RETORNO.COUNT).NUMVOL                := 1;
      RETORNO(RETORNO.COUNT).NUMVOLUMESCONFERENCIA := NULL;
      RETORNO(RETORNO.COUNT).VOLUME_PEDIDO         := NULL;
      RETORNO(RETORNO.COUNT).PESO_BRUTO            := NULL;
      RETORNO(RETORNO.COUNT).PESO_LIQUIDO          := NULL;
      RETORNO(RETORNO.COUNT).PLACA                 := RODAPE.PLACA;
      RETORNO(RETORNO.COUNT).PLACA_UF              := NULL;
      RETORNO(RETORNO.COUNT).VALOR_COFINS          := 0;
      RETORNO(RETORNO.COUNT).VLDESCRODAPE          := 0;
      RETORNO(RETORNO.COUNT).VALOR_DESCONTO        := RODAPE.VALOR_DESCONTO;
      RETORNO(RETORNO.COUNT).VALOR_FRETE           := RODAPE.VALOR_FRETE;
      RETORNO(RETORNO.COUNT).VALOR_ICMS            := RODAPE.VALOR_ICMS;
      RETORNO(RETORNO.COUNT).VALOR_ICMS_ST         := RODAPE.VALOR_ST;
      RETORNO(RETORNO.COUNT).VALOR_IPI             := RODAPE.VALOR_IPI;
      RETORNO(RETORNO.COUNT).VALOR_II              := 0;
      RETORNO(RETORNO.COUNT).VALOR_ISS             := 0;
      RETORNO(RETORNO.COUNT).VALOR_OUTRO           := RODAPE.VALOR_OUTRO;
      RETORNO(RETORNO.COUNT).VALOR_PIS             := 0;
      RETORNO(RETORNO.COUNT).VALOR_TOTAL           := RODAPE.VALOR_TOTAL;
      RETORNO(RETORNO.COUNT).VALOR_TOTAL_PRODUTOS  := RODAPE.VALOR_TOTAL_PRODUTOS;
      RETORNO(RETORNO.COUNT).NVOL                  := 1;
      RETORNO(RETORNO.COUNT).INFOADICIONALFISCO    := NULL;
      RETORNO(RETORNO.COUNT).NUM_VOLUME_EMB        := 0;
      RETORNO(RETORNO.COUNT).DESC_PL_PAGTO         := NULL;
      RETORNO(RETORNO.COUNT).VLTOTALIMPOSTOS       := 0;
      RETORNO(RETORNO.COUNT).VALOR_TOTAL_SEGURO    := 0;
      RETORNO(RETORNO.COUNT).VLFCPPART             := 0;
      RETORNO(RETORNO.COUNT).VLICMSPARTDEST        := 0;
      RETORNO(RETORNO.COUNT).VLICMSPARTREM         := 0;
      RETORNO(RETORNO.COUNT).VLBASEFCPICMS         := 0;
      RETORNO(RETORNO.COUNT).VLBASEFCPST           := 0;
      RETORNO(RETORNO.COUNT).VLBCFCPSTRET          := 0;
      RETORNO(RETORNO.COUNT).VLFCPSTRET            := 0;
      RETORNO(RETORNO.COUNT).VLCREDFCPICMSSN       := 0;
      RETORNO(RETORNO.COUNT).VLFECP                := 0;
      RETORNO(RETORNO.COUNT).VLACRESCIMOFUNCEP     := 0;
      RETORNO(RETORNO.COUNT).VALOR_IPI_DEVOLVIDO   := 0;
      RETORNO(RETORNO.COUNT).DATACONSOLIDACAOPREFAT:= NULL;
      RETORNO(RETORNO.COUNT).PREFATURAMENTO        := 'N';
      RETORNO(RETORNO.COUNT).VALOR_SERVICO_TRANSP        := 0;
      RETORNO(RETORNO.COUNT).BASE_RETENCAO_ICMS_TRANSP   := 0;
      RETORNO(RETORNO.COUNT).PERC_RETENCAO_ICMS_TRANSP   := 0;
      RETORNO(RETORNO.COUNT).VALOR_RETENCAO_ICMS_TRANSP  := 0;
      RETORNO(RETORNO.COUNT).CFOP_TRANSP                 := 0;
      RETORNO(RETORNO.COUNT).COD_MUN_FATO_GERADOR_TRANSP := 0;
      RETORNO(RETORNO.COUNT).GERAGRPRETTRIB              := 'N';
      RETORNO(RETORNO.COUNT).VLPISRETORGPUB              := 0;
      RETORNO(RETORNO.COUNT).VLCOFINSRETORGPUB           := 0;
      RETORNO(RETORNO.COUNT).VLCSLLRETORGPUB             := 0;
      RETORNO(RETORNO.COUNT).VLIRPJRETORGPUB             := 0;
      RETORNO(RETORNO.COUNT).VLBCIRRFRETORGPUB           := 0;    
      RETORNO(RETORNO.COUNT).QBCMONO                     := 0;
      RETORNO(RETORNO.COUNT).VICMSMONO                   := 0;
      RETORNO(RETORNO.COUNT).QBCMONORETEN                := 0;
      RETORNO(RETORNO.COUNT).VICMSMONORETEN              := 0;
      RETORNO(RETORNO.COUNT).QBCMONODIF                  := 0;
      RETORNO(RETORNO.COUNT).VICMSMONODIF                := 0;
      RETORNO(RETORNO.COUNT).QBCMONORET                  := 0;
      RETORNO(RETORNO.COUNT).VICMSMONORET                := 0;        

    END LOOP;
  END IF;

  RETURN RETORNO;

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001, 'Erro motivo: ' || SQLERRM || '. Linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
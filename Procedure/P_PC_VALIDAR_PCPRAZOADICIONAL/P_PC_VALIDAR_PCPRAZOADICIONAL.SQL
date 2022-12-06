CREATE OR REPLACE PROCEDURE P_PC_Validar_PCPRAZOADICIONAL
/******************************************************************************************
->Nome da PROCEDURE : P_PC_Validar_PCPRAZOADICIONAL
->Objetivo          : Faturar pedidos nao faturados.
->Versao            : Pacote

-------------------------------- Historico ------------------------------------------------------------------
Data          Responsavel       Tarefa   Comentarios
------------  ---------------   -------- --------------------------------------------------------------------
05/03/2007    Pablo             39450    Procedure criada para retornar o NUMERO de DIAS do Prazo Adicional
                                         (PCPRAZOADICIONA) rotina PCSIS397
21/03/2007    Pablo                      Procedure passa a ser criada pela rotina PCSIS500
03/05/2012    Silvomar          156967   incluir cidade do cliente e e filial de venda para calcular prazo adicional de venda.
09/08/2013    Silvomar          207081   incluir a função max para casos de ter mais de um prazo adicional inserido
**************************************************************************************************************************/
(
--Parametros de entrada
  pdtDATA            in Date,
  pdNUMREGIAO        in pcregiao.numregiao%TYPE ,
  pdCODCLI           in pcclient.codcli%TYPE,
  pdCODUSUR          in pcusuari.codusur%TYPE,
  psORIGEMPEDIDO     in pcpedc.origemped%TYPE,
  pdCODPLPAG         in pcplpag.codplpag%TYPE,
  pnVlTotal          in pcnfsaid.vltotal%TYPE,
  psCODFILIAL        in pcpedc.Codfilial%TYPE,
--Parametros de Saida
  psMensagem         out VARCHAR2,
  pdNumDias          out pcprazoadicional.numdias%TYPE
  )
is
  --Dados do Cliente
  vdCODCLIPRINC      pcclient.codcliprinc%TYPE;
  vdCODATV1          pcclient.codatv1%TYPE;
  vdCODPRACA         pcclient.Codpraca%TYPE;
  vdCODCIDADE        pcclient.CODCIDADE%TYPE;
  --Dados do RCA
  vdCODSUPERVISOR    pcsuperv.codsupervisor%TYPE;
  --Variaveis de Controle
  vnContador         number;
  pvc2menssagen      VARCHAR2 (255);
begin
  pdNumdias := 0;
  pvc2menssagen := 'OK';

  BEGIN
    -- Buscar dados do cliente
    BEGIN
      SELECT NVL(CODCLIPRINC, CODCLI) CODCLIPRINC
             ,CODATV1
             ,CODPRACA
             ,CODCIDADE
        INTO vdCODCLIPRINC
             ,vdCODATV1
             ,vdCODPRACA
             ,vdCODCIDADE
        FROM PCCLIENT
       WHERE CODCLI = pdCODCLI;
    EXCEPTION
       WHEN OTHERS
       THEN
          pvc2menssagen :=
                SQLCODE
             || '-'
             || SQLERRM
             || '22.00 - Não foi possível buscar dados do PCCLIENT!';
           RAISE;
    END;

    -- Buscar dados do RCA
    BEGIN
      SELECT CODSUPERVISOR
        INTO vdCODSUPERVISOR
        FROM PCUSUARI
       WHERE CODUSUR = pdCODUSUR;
    EXCEPTION
       WHEN OTHERS
       THEN
          pvc2menssagen :=
                SQLCODE
             || '-'
             || SQLERRM
             || '22.01 - Não foi possível buscar dados do PCUSUARI!';
           RAISE;
    END;

    -- Verificação de Políticas de Descontos

    -- Verifica Tabela de Prazo Adicional (sem rede de clientes)
     SELECT COUNT(*)
       INTO vnContador
       FROM PCPRAZOADICIONAL
      WHERE pdtDATA BETWEEN DTINICIO AND DTFIM
        AND NVL(UTILIZADESCREDE,'N') = 'N'
        AND ( ( CODUSUR = pdCODUSUR ) OR ( CODUSUR IS NULL ) )
        AND ( ( CODSUPERVISOR = vdCODSUPERVISOR ) OR ( CODSUPERVISOR IS NULL ) )
        AND ( ( CODCLI = pdCODCLI ) OR ( CODCLI IS NULL ) )
        AND ( ( NUMREGIAO = pdNUMREGIAO ) OR ( NUMREGIAO IS NULL ) )
        AND ( ( CODATIV = vdCODATV1 ) OR ( CODATIV IS NULL ) )
        AND ( ( ORIGEMPED = psORIGEMPEDIDO ) OR ( NVL(ORIGEMPED,'O') = 'O' ) )
        AND ( ( CODPRACA = vdCODPRACA ) OR ( CODPRACA IS NULL ) )
        AND ( ( CODPLPAG = pdCODPLPAG ) OR ( CODPLPAG IS NULL ) )
        AND ( ( CODCIDADE = vdCODCIDADE) OR ( CODCIDADE IS NULL ) )
        AND ( ( CODFILIAL = psCODFILIAL) OR ( CODFILIAL IS NULL ) )
        AND ( ( NVL(VLMINVENDA,0) <= pnVlTotal))
     ORDER BY NUMDIAS DESC;

     IF vnContador > 0
     THEN
       SELECT MAX(NVL(NUMDIAS,0))
         INTO pdNumdias
         FROM PCPRAZOADICIONAL
        WHERE pdtDATA BETWEEN DTINICIO AND DTFIM
          AND NVL(UTILIZADESCREDE,'N') = 'N'
          AND ( ( CODUSUR = pdCODUSUR ) OR ( CODUSUR IS NULL ) )
          AND ( ( CODSUPERVISOR = vdCODSUPERVISOR ) OR ( CODSUPERVISOR IS NULL ) )
          AND ( ( CODCLI = pdCODCLI ) OR ( CODCLI IS NULL ) )
          AND ( ( NUMREGIAO = pdNUMREGIAO ) OR ( NUMREGIAO IS NULL ) )
          AND ( ( CODATIV = vdCODATV1 ) OR ( CODATIV IS NULL ) )
          AND ( ( ORIGEMPED = psORIGEMPEDIDO ) OR ( NVL(ORIGEMPED,'O') = 'O' ) )
          AND ( ( CODPRACA = vdCODPRACA ) OR ( CODPRACA IS NULL ) )
          AND ( ( CODPLPAG = pdCODPLPAG ) OR ( CODPLPAG IS NULL ) )
          AND ( ( CODCIDADE = vdCODCIDADE) OR ( CODCIDADE IS NULL ) )
          AND ( ( CODFILIAL = psCODFILIAL) OR ( CODFILIAL IS NULL ) )
          AND ( ( NVL(VLMINVENDA,0) <= pnVlTotal))
       ORDER BY NUMDIAS DESC;
     END IF;

     -- Verifica Tabela de Prazo Adicional da Rede de Clientes //
     SELECT COUNT(*)
       INTO vnContador
       FROM PCPRAZOADICIONAL
      WHERE CODCLI = vdCODCLIPRINC
        AND pdtDATA BETWEEN DTINICIO AND DTFIM
        AND NVL(UTILIZADESCREDE,'N') = 'S'
        AND ( ( CODUSUR = pdCODUSUR ) OR ( CODUSUR IS NULL ) )
        AND ( ( CODSUPERVISOR = vdCODSUPERVISOR ) OR ( CODSUPERVISOR IS NULL ) )
        AND ( ( NUMREGIAO = pdNUMREGIAO ) OR ( NUMREGIAO IS NULL ) )
        AND ( ( CODATIV = vdCODATV1 ) OR ( CODATIV IS NULL ) )
        AND ( ( ORIGEMPED = psORIGEMPEDIDO ) OR ( NVL(ORIGEMPED,'O') = 'O' ) )
        AND ( ( CODPRACA = vdCODPRACA ) OR ( CODPRACA IS NULL ) )
        AND ( ( CODPLPAG = pdCODPLPAG ) OR ( CODPLPAG IS NULL ) )
        AND ( ( CODCIDADE = vdCODCIDADE) OR ( CODCIDADE IS NULL ) )
        AND ( ( CODFILIAL = psCODFILIAL) OR ( CODFILIAL IS NULL ) )
        AND ( ( NVL(VLMINVENDA,0) <= pnVlTotal))
       ORDER BY NUMDIAS DESC;

     IF vnContador > 0
     THEN
       SELECT MAX(NVL(NUMDIAS,0))
         INTO pdNumDias
         FROM PCPRAZOADICIONAL
        WHERE CODCLI = vdCODCLIPRINC
          AND pdtDATA BETWEEN DTINICIO AND DTFIM
          AND NVL(UTILIZADESCREDE,'N') = 'S'
          AND ( ( CODUSUR = pdCODUSUR ) OR ( CODUSUR IS NULL ) )
          AND ( ( CODSUPERVISOR = vdCODSUPERVISOR ) OR ( CODSUPERVISOR IS NULL ) )
          AND ( ( NUMREGIAO = pdNUMREGIAO ) OR ( NUMREGIAO IS NULL ) )
          AND ( ( CODATIV = vdCODATV1 ) OR ( CODATIV IS NULL ) )
          AND ( ( ORIGEMPED = psORIGEMPEDIDO ) OR ( NVL(ORIGEMPED,'O') = 'O' ) )
          AND ( ( CODPRACA = vdCODPRACA ) OR ( CODPRACA IS NULL ) )
          AND ( ( CODPLPAG = pdCODPLPAG ) OR ( CODPLPAG IS NULL ) )
          AND ( ( CODCIDADE = vdCODCIDADE) OR ( CODCIDADE IS NULL ) )
          AND ( ( CODFILIAL = psCODFILIAL) OR ( CODFILIAL IS NULL ) )
          AND ( ( NVL(VLMINVENDA,0) <= pnVlTotal))
       ORDER BY NUMDIAS DESC;
     END IF;

    --Fim da função
   EXCEPTION
      WHEN OTHERS
      THEN
         pvc2menssagen :=
               SQLCODE
            || '-'
            || SQLERRM
            || '22.02 -Não possível validar o prazo Adicional (PCPRAZOADICIONAL)';
         RAISE;
   END;

  --Retorno da função
  psMensagem := pvc2menssagen;
end P_PC_Validar_PCPRAZOADICIONAL;
/

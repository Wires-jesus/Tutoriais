create or replace package ATUALIZACAO_MENSAL is

  -- Author  : WATSON.WILLIAN
    ------------------------------------------------------------------------------
    -- Author  : Tatiane Mota de Souza Rodrigues Figueiredo
    -- Created : 01/08/2011 
    -- Purpose : Criado para armazenar os procedimento de atualizaÃ§Ã£o mensal da rotina 506
    ------------------------------------------------------------------------------  
   PROCEDURE P_PC_ZERAMESPCAUXCLI (pMes      in VARCHAR2,
                                 pAno      in VARCHAR2,
                                 pMensagem OUT VARCHAR2);
  
   PROCEDURE P_PC_ZERAMESPCAUXPRO(PMES      IN VARCHAR2,
                                 pAno      IN VARCHAR2,
                                 pMensagem OUT VARCHAR2);
                                 
   PROCEDURE P_PC_ATUALIZAPCAUXCLI (pCodCli in integer,
                                    pAno in Varchar2,
                                    pMes in Varchar2,
                                    PVlvendames in Float,
                                    PVlcustofinmes in Float,
                                    PVlcustorealmes in Float,
                                    PQtvendames in Float,                                                                        
                                    PQtmixmes in Float,
                                    pMensagem out Varchar2);
                                                                  
   PROCEDURE P_PC_ATUALIZAPCAUXPRO(PCodProd    in Float,
                                  pAno         in Varchar2,
                                  pMes         in Varchar2,
                                  PCodFilial   in Varchar2,
                                  pVlvenda     in Float,
                                  pVlcustofin  in Float,
                                  pVlcustoreal in Float,
                                  pQtvenda     in Float,
                                  pVldevolucao in Float,
                                  pQtdevolucao in Float,
                                  pVlcompra    in Float,
                                  pQtcompra    in Float,
                                  pVlestoque   in Float,
                                  pCustoFin    in Float,
                                  pCustoReal   in Float,
                                  pCustocont   in Float,
                                  pQtestger    in Float,
                                  pVenda1      in Float) ;
  
  PROCEDURE P_PC_ATUALIZAPCCONSOLIDAMES(pCodigo    in Integer,
                                        pAno       in Varchar2,
                                        pMes       in Varchar2,
                                        pVlvenda   in Float,
                                        pVlcompra  in Float,
                                        pQtvenda   in Float,
                                        pCodfilial in Varchar2,
                                        pTipo      in Varchar2);                            
  
  PROCEDURE P_PC_CONSOLIDADADOSHISTORICO(pdataini  in date,
                                         pdatafim  in date,
                                         pMensagem out VARCHAR2,
                                         pCommit   in Varchar2 Default 'N');

 
  PROCEDURE P_PC_ZERAMESPCCONSOLIDAMES (pMes      in VARCHAR2,
                                        pAno      in VARCHAR2,
                                        pMensagem OUT VARCHAR2);  
  

end ATUALIZACAO_MENSAL;

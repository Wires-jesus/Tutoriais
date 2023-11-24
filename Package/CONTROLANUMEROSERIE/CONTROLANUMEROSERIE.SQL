CREATE OR REPLACE package CONTROLANUMEROSERIE is

/*  EXECOES  */
    PARAMETRO_ENTRADA_NULO      EXCEPTION;
    DADOS_ROWID_NAO_ENCONTRADO  EXCEPTION;
    DADOS_NAO_ENCONTRADO  EXCEPTION;

  PROCEDURE PRC_NUMERO_SERIE_FATURAMENTO(p_ROWID    in varchar2,
                                         p_MENSAGEM out varchar2);

  PROCEDURE PRC_NUMERO_SERIE_CANCELAMENTO(p_ROWID    in varchar2,
                                          p_MANTERRESERVADO in varchar2,
                                          p_MENSAGEM out varchar2);
                                          
  FUNCTION FUNC_CONTROLA_NUMERO_SERIE(p_CODFILIAL in varchar2,
                                      p_CODPRODUTO in pcprodut.codprod%TYPE) return varchar2;
                                                                                
  PROCEDURE PRC_INSERIR_NUMSERIE(p_CODFILIAL PCNUMEROSERIE.CODFILIAL%TYPE,
                                 p_CODPROD   PCNUMEROSERIE.CODPROD%TYPE,
                                 p_NUMSERIE  PCNUMEROSERIE.NUMSERIE%TYPE,
                                 p_NUMLOTE  PCNUMEROSERIE.NUMLOTE%TYPE,
                                 p_BLOQUEIO  PCNUMEROSERIE.BLOQUEIO%TYPE,
                                 p_AVARIA  PCNUMEROSERIE.AVARIA%TYPE,
                                 p_RESERVADA  PCNUMEROSERIE.RESERVADA%TYPE
                                );
                            
  PROCEDURE TRANSFERIR_NUMERO_SERIE(p_NUMPEDDESTINO PCCONTROLENUMSERIE.NUMPED%TYPE,
                                    p_NUMSEQDESTINO PCCONTROLENUMSERIE.NUMSEQ%TYPE,
                                    p_NUMPEDORIGEM PCCONTROLENUMSERIE.NUMPED%TYPE,
                                    p_NUMSEQORIGEM PCCONTROLENUMSERIE.NUMSEQ%TYPE,
                                    p_CODPROD PCCONTROLENUMSERIE.CODPROD%TYPE,
                                    p_NUMSERIE PCCONTROLENUMSERIE.NUMSERIE%TYPE,
                                    p_MENSAGEM out varchar2
                                     );

  FUNCTION FUNC_EXISTE_CONFERENCIA(P_NUMPED    PCMOV.NUMPED%TYPE,
                                   P_CODFILIAL PCMOV.CODFILIAL%TYPE,
                                   P_CODPROD   PCMOV.CODPROD%TYPE,
                                   P_NUMSEQ    PCMOV.NUMSEQ%TYPE)
  RETURN varchar2;
                                   
end;
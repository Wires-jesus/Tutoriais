CREATE OR REPLACE package PKG_FWPC_FISCAL is

   procedure ICMSPARTILHA_CALCULAR_1_0(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

   procedure ICMSPARTILHA_CALCULAR_1_1(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

   procedure ICMSPARTILHA_CALCULAR_1_2(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

   procedure ICMSPARTILHA_CALCULAR_1_3(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

   procedure ICMSPARTILHA_CALCULAR_1_4(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

   function CEST_OBTERCODIGO_1_0(P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2) return varchar2;

   function CEST_OBTERCODIGO_1_1(P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODFILIAL    in varchar2
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2) return varchar2;

   procedure PEPS_OBTERORIGEMMERC_1_0(P_CODPROD          in number
                                     ,P_CODFILIAL        in varchar2
                                     ,P_QUANTIDADE       in number
                                     ,P_DATA             in date
                                     ,P_ENTRADASORIGMERC out TIPO_ENTRADASPEPSTAB
                                     ,P_CODMSG           out number
                                     ,P_MSG              out varchar2);

   PROCEDURE CEST_OBTERCODIGO_1_3 (P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODFILIAL    in varchar2
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2);

   PROCEDURE ICMSPARTILHA_CALCULAR_1_5(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

  PROCEDURE ICMSPARTILHA_CALCULAR_1_6(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_BASEICMS     in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

  PROCEDURE ICMSPARTILHA_CALCULAR_1_7(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_BASEICMS     in number
                                      ,P_CST          in varchar2
                                      ,P_ROTINA       in varchar2  := 'X'
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2);

  PROCEDURE ICMSPARTILHA_CALCULAR_1_8(P_NUMTRANSACAO in number
                                     ,P_TIPOMOV  varchar2
                                     ,P_ATIVARLOG varchar2 := 'N'
                                     ,P_MSG      out varchar2);

  PROCEDURE ICMSPARTILHA_CALCULAR_1_9(P_NUMTRANSACAO in number
                                     ,P_TIPOMOV  varchar2
                                     ,P_ATIVARLOG varchar2 := 'N'
                                     ,P_CODIGO_MSG out varchar2
                                     ,P_MSG        out varchar2);

  FUNCTION F_CALCULAR_PARTILHA_ICMS_1_9(P_NUMTRANSACAO in number
                                       ,P_TIPOMOV      varchar2
                                       ,P_ATIVARLOG    varchar2 := 'N'
                                       ,P_CODMSG   out varchar2
                                       ,P_MSG      out varchar2)
            RETURN VARCHAR2 ;

end PKG_FWPC_FISCAL;

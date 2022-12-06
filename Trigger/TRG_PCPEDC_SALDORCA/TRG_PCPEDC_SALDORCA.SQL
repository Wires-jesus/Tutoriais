CREATE OR REPLACE TRIGGER trg_pcpedc_saldorca
 BEFORE
  INSERT
 ON pcpedc
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
/*****************************************************************************
                           Historico de Alteracoes
------------------------------------------------------------------------------
 Data        Responsavel           Tarefa      Alteração
 ----------  --------------------  ----------  --------------------------------
 25/04/2009  Pablo                 73278       Projeto 71133 - Reformulação Controle Saldo RCA
 15/07/2009  Pablo                 73289       Para o campo PCPEDC.TipoMovRCA não será validado se o mesmo IS NULL
                                                                uma vez que o campo é criado com Default 'VV'
 17/11/2009  Andréa                95731       Projeto 90992 - Melhoria no desconto financeiro e saldo de conta corrente de rca                                                                 
 23/09/2011  Marcos                144410      Ajuste da exceção NO_DATA_FOUND
*****************************************************************************/
   vsusacredrca                    pcconsum.usacredrca%TYPE;
   vsbonificaltdebcredrca          pcconsum.bonificaltdebcredrca%TYPE;
   vstrocaaltdebcredrca            pcconsum.trocaaltdebcredrca%TYPE;
   vsbrokeraltdebcredrca           pcconsum.brokeraltdebcredrca%TYPE;
   vscrmaltdebcredrca              pcconsum.crmaltdebcredrca%TYPE;
   vstipomovccrca                  pcconsum.tipomovccrca%TYPE;
   vsusadebcredrca                 pcusuari.usadebcredrca%TYPE;
   vsusasaldocontacorrentedescfin  pcconsum.usasaldocontacorrentedescfin%type;
   vsatualizasaldoccdescfin        pcclient.atualizasaldoccdescfin%type;

BEGIN
   SELECT usacredrca
         ,NVL( bonificaltdebcredrca, 'S' )
         ,NVL( trocaaltdebcredrca, 'S' )
         ,NVL( brokeraltdebcredrca, 'S' )
         ,NVL( crmaltdebcredrca, 'S' )
         ,NVL( tipomovccrca, 'VV' )
         ,nvl(pcconsum.usasaldocontacorrentedescfin,'N')
     INTO vsusacredrca
         ,vsbonificaltdebcredrca
         ,vstrocaaltdebcredrca
         ,vsbrokeraltdebcredrca
         ,vscrmaltdebcredrca
         ,vstipomovccrca
         ,vsusasaldocontacorrentedescfin
     FROM pcconsum
    WHERE ROWNUM = 1;
   
   BEGIN
     SELECT pcclient.atualizasaldoccdescfin
     INTO   vsatualizasaldoccdescfin
     FROM   pcclient
     WHERE  codcli = :new.codcli;
   EXCEPTION
     WHEN OTHERS THEN
       vsatualizasaldoccdescfin := 'N';
   END;   

   if vsusasaldocontacorrentedescfin ='S' and NVL(vsatualizasaldoccdescfin,'N') = 'N' then
      :new.USASALDOCONTACORRENTEDESCFIN := 'S';
   else
      :new.USASALDOCONTACORRENTEDESCFIN := 'N';
   end if;

   BEGIN
     SELECT NVL( usadebcredrca, 'S' )
       INTO vsusadebcredrca
       FROM pcusuari
      WHERE codusur = :NEW.codusur;
   EXCEPTION
     WHEN OTHERS THEN
       vsusadebcredrca := 'N';
   END;   
   
   IF :NEW.usacredrca IS NULL
   THEN
     :NEW.usacredrca := vsusacredrca;
   END IF;

   IF :NEW.bonificaltdebcredrca IS NULL
   THEN
     :NEW.bonificaltdebcredrca := vsbonificaltdebcredrca;
   END IF;

   IF :NEW.trocaaltdebcredrca IS NULL
   THEN
     :NEW.trocaaltdebcredrca := vstrocaaltdebcredrca;
   END IF;

   IF :NEW.brokeraltdebcredrca IS NULL
   THEN
     :NEW.brokeraltdebcredrca := vsbrokeraltdebcredrca;
   END IF;

   IF :NEW.crmaltdebcredrca IS NULL
   THEN
     :NEW.crmaltdebcredrca := vscrmaltdebcredrca;
   END IF;

   :NEW.tipomovccrca := vstipomovccrca;

   IF :NEW.usadebcredrca IS NULL
   THEN
     :NEW.usadebcredrca := vsusadebcredrca;
   END IF;
END; -- trg_pcpedc_saldorca
/

/

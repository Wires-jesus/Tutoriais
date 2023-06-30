CREATE OR REPLACE VIEW VW_INT_C5_USUARIO AS
(
SELECT  r.codfilial,
        r.codusur,
        r.matricula sequsuario,
        1 seqpessoa,
        SUBSTR(r.nome,1,40) nome,
        SUBSTR(r.nome_guerra,1,30) apelido,
        fnc_int_c5_pwd(r.matricula) senha,
        (CASE
             WHEN r.codsetor = setor.fiscal
                  THEN 0
             ELSE
                 1
          END) nivel,
        r.dtexpirasenha dtaexpirar,
        (CASE
             WHEN NVL(r.perdescmaxitem,0) > 0
                  THEN r.perdescmaxitem
             WHEN TO_NUMBER(setor.percdesc) > 0
                  THEN setor.percdesc
             ELSE
                 0
          END) percdescmaximo,
        SUBSTR(r.email,80) email,

        (CASE
             WHEN r.dt_exclusao IS NULL
                  AND
                  NVL(r.situacao,'A') = 'A'
                  THEN 'S'
             ELSE
                 'N'
          END) ativo,

          r.dtalterc5
  FROM  pcempr r,
        (SELECT (SELECT valor FROM pcparamfilial WHERE nome = 'CON_CODSETOROPERCX' AND codfilial = '99') oper,
                (SELECT valor FROM pcparamfilial WHERE nome = 'CON_CODSETORFISCALCX' AND codfilial = '99') fiscal,
                (SELECT NVL(TO_NUMBER(valor),0) FROM pcparamfilial WHERE nome = 'CON_PERMAXDESCITEMCF' AND codfilial = '99') percdesc
           FROM dual) setor,
        pcusuari i,
        (select s.ultimaexecucao from pccontroleconsinco s where upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_USUARIO') DTPADRAO
 WHERE  r.codusur = i.codusur
   AND  i.codsupervisor IS NOT NULL
   AND  i.dtexclusao IS NULL
   AND  r.codusur > 0
   AND  r.matricula > 0
   AND  r.codsetor IN (setor.fiscal,setor.oper)
   AND NVL(r.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO)  >= DTPADRAO.ULTIMAEXECUCAO)


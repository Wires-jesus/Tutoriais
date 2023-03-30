-- No Servidor Principal
CREATE OR REPLACE VIEW vw_credito_cliente
AS
   SELECT pcclient.codcli,
            NVL (pedidos_pendentes.vlatend, 0)
          + NVL (cr_aberto.valor, 0) total_receber
     FROM pcclient,
          (SELECT   codcli, SUM (NVL (vlatend, 0)) AS vlatend
               FROM pcpedc
              WHERE posicao IN ('L', 'M')
           GROUP BY codcli) pedidos_pendentes,
          (SELECT   codcli, SUM (NVL (valor, 0)) valor
               FROM pcprest
              WHERE dtpag IS NULL
           GROUP BY codcli) cr_aberto
    WHERE pcclient.dtexclusao IS NULL
      AND pcclient.codcli = pedidos_pendentes.codcli(+)
      AND pcclient.codcli = cr_aberto.codcli(+);

CREATE OR REPLACE VIEW VW_INT_C5_CARTEIRA AS
(SELECT 'pix' nomecarteira, 3001 idcarteira FROM DUAL
     UNION
     SELECT 'mercadopago' nomecarteira, 3002 idcarteira FROM DUAL
     UNION
     SELECT 'picpay' nomecarteira, 3003 idcarteira FROM DUAL
     UNION
     SELECT 'ame' nomecarteira, 3004 idcarteira FROM DUAL
     UNION
     SELECT 'shipaypagador' nomecarteira, 30099 idcarteira FROM DUAL
     )




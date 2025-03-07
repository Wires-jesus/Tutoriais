BEGIN
  UPDATE PCPARAMFILIAL SET VALOR = 'https://raas.varejo.totvs.com.br/pay-hub/reporting/api/v1/settlement' WHERE NOME = 'URI_TPI';

  UPDATE PCPARAMFILIAL SET VALOR = 'https://raas.varejo.totvs.com.br/pay-hub/transacting/api/v3/payment/bolepix' WHERE NOME = 'URI_BOLEPIX';

  UPDATE PCPARAMFILIAL SET VALOR = 'https://raas.varejo.totvs.com.br/pay-hub/transacting/api/v3/payment/refund' WHERE NOME = 'URI_BOLEPIX_CANCELAMENTO';

  UPDATE PCPARAMFILIAL SET VALOR = 'https://raas.varejo.totvs.com.br/pay-hub/transacting/api/v2/payment/link/{externalBusinessUnitId}/pos/{externalPosId}/transaction/{processorTransactionId}' WHERE NOME = 'URI_BOLEPIX_RETORNO';
END;
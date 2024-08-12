CREATE OR REPLACE Package PKG_INT_C5_MOVCX Is

  Procedure processar_movimento_caixa(p_seqdocto NUMBER Default 0,
                                      p_nrocheckout NUMBER default 0,
									  p_nroempresa NUMBER default 0);

End PKG_INT_C5_MOVCX;
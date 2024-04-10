DECLARE
  TYPE ListaTabelas IS TABLE OF VARCHAR2(60);
  nomeTabela ListaTabelas := ListaTabelas('PCINTEGRACAOCOREMIGRATION',
                                          'PCINTEGRACAODADOSEMPRESA',
                                          'PCINTEGRACAOROTASERVICO',
                                          'PCINTEGRACAOVARIAVEIS',
                                          'PCINTEGRACAODADOSRECEBIDOS',
                                          'PCINTEGRACAOCORE',
                                          'PCINTEGRACAOVARIAVEISTEMP',
                                          'PCINTEGRACAOERROREQUISICAO',
                                          'PCINTEGRACAODADOSCLASSE',
                                          'PCINTEGRACAODADOSMETODO',
                                          'PCINTEGRACAOCLASSEMETODO',
                                          'PCINTEGRACAOAGENDAMENTO',
                                          'PCINTEGRACAOAGENDAMENTOFLUXO',
                                          'PCINTEGRACAOFLUXOEXECUCAO',
                                          'PCINTEGRACAOLOGEXCLUSAODADOS');

  vContador NUMBER;
  VSQL      VARCHAR2(5000) := '';
BEGIN
  FOR i IN 1 .. nomeTabela.COUNT LOOP
    SELECT COUNT(1)
      INTO vContador
      FROM ALL_OBJECTS
     WHERE OBJECT_TYPE = 'TABLE'
       AND OBJECT_NAME = nomeTabela(i)
       AND UPPER(OWNER) = UPPER(USER);
  
    IF ((nomeTabela(i) = 'PCINTEGRACAOCOREMIGRATION') AND (vContador = 0)) THEN
      VSQL := '  create table PCINTEGRACAOCOREMIGRATION(NOME VARCHAR2(255) not null,';
      VSQL := VSQL || ' DTCRIACAO     DATE default SYSDATE not null,';
      VSQL := VSQL || ' DTATUALIZACAO DATE default SYSDATE not null,';
      VSQL := VSQL || ' DESCRICAOERRO CLOB,';
      VSQL := VSQL || ' SUCESSO       VARCHAR2(1) default ''S'' not null,';
      VSQL := VSQL || ' TENTATIVAS    NUMBER default 0 not null,';
      VSQL := VSQL || ' TESTE         VARCHAR2(1) default ''N'' not null,';
      VSQL := VSQL || ' SQLGERADO CLOB,';
      VSQL := VSQL || ' VERSAO VARCHAR2(10),';
      VSQL := VSQL || ' PROJETONOME VARCHAR2(20),';
      VSQL := VSQL || ' TABELA VARCHAR2(40))';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' comment on column PCINTEGRACAOCOREMIGRATION.NOME is ''Nome do arquivo de migration''';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOCOREMIGRATION add constraint PCINTEGRACAOCOREMIGRATION_PK primary key(NOME, TESTE)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' create index IDX_PROJETONOME_VERSAO on PCINTEGRACAOCOREMIGRATION(PROJETONOME, VERSAO)';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAODADOSEMPRESA') AND (vContador = 0) THEN
      VSQL := 'create table PCINTEGRACAODADOSEMPRESA';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '  ID                  NUMBER not null,';
      VSQL := VSQL || '  NOME                VARCHAR2(40),';
      VSQL := VSQL || '  URLBASE             VARCHAR2(80),';
      VSQL := VSQL || '  TOKENCLIENTE        CLOB,';
      VSQL := VSQL || '  WTA                 VARCHAR2(1),';
      VSQL := VSQL || '  DTSOLICITACAOTOKEN  DATE,';
      VSQL := VSQL || '  TOKENTEMPOEXPIRACAO NUMBER default 3600,';
      VSQL := VSQL || '  VERSAO  VARCHAR2(20),';
      VSQL := VSQL || '  PROJETONOME VARCHAR2(40)';
      VSQL := VSQL || ' )';
    
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAODADOSEMPRESA  add constraint PCINTEGRACAODADOSEMPRESA_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAODADOSEMPRESA  add constraint NOME_UK unique (NOME)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOROTASERVICO') AND (vContador = 0) THEN
      VSQL := 'create table PCINTEGRACAOROTASERVICO';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID                             NUMBER not null,';
      VSQL := VSQL || '   IDEMPRESAAPI                   NUMBER not null,';
      VSQL := VSQL || '   SERVICO                        VARCHAR2(40),';
      VSQL := VSQL || '   LAYOUTCOMUNICACAO              CLOB,';
      VSQL := VSQL || '   LAYOUTTRANSFORMACAO            CLOB,';
      VSQL := VSQL || '   ARQUITETURA                    VARCHAR2(20),';
      VSQL := VSQL || '   ATIVO                          VARCHAR2(1),';
      VSQL := VSQL || '   TIPOPROCESSO                   VARCHAR2(80),';
      VSQL := VSQL || '   AUTENTICADOR                   VARCHAR2(1),';
      VSQL := VSQL || '   DATASINCRONISMO                DATE,';
      VSQL := VSQL || '   REFRESHTOKEN                   VARCHAR2(1),';
      VSQL := VSQL || '   IDROTAIDEXTERNO                NUMBER,';
      VSQL := VSQL || '   SOMENTEATUALIZARINTEGRACAOCORE VARCHAR2(1) default ''N'' not null';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOROTASERVICO  add constraint PCINTEGRACAOROTASERVICO_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOROTASERVICO  add constraint SERVICO_UK unique (SERVICO)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOROTASERVICO  add constraint PCINTEGRACAODADOSEMPRESA_FK foreign key (IDEMPRESAAPI)  references PCINTEGRACAODADOSEMPRESA (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOROTASERVICO_IDX1 on PCINTEGRACAOROTASERVICO (TIPOPROCESSO)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOROTASERVICO_IDX2 on PCINTEGRACAOROTASERVICO (ATIVO)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOVARIAVEIS') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOVARIAVEIS';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID            NUMBER not null,';
      VSQL := VSQL || '   CHAVE         VARCHAR2(40),';
      VSQL := VSQL || '   TIPOCHAVE     VARCHAR2(20),';
      VSQL := VSQL || '   TIPOVALOR     VARCHAR2(20),';
      VSQL := VSQL || '   IDROTASERVICO NUMBER not null,';
      VSQL := VSQL || '   DTULTALTER    DATE,';
      VSQL := VSQL || '   CODEMPALTER   VARCHAR2(40),';
      VSQL := VSQL || '   VALOR         CLOB';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOROTASERVICO_FK foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := 'alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_CK1  check (TIPOCHAVE IN(''HEADER'', ''BODY'', ''PARAMS'', ''REQUEST'', ''RESPONSE''))';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_CK2  check (TIPOVALOR IN(''STRING'', ''INTEGER'', ''DOUBLE'', ''DATE'', ''SELECT'', ''ENCRYPTED''))';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAODADOSRECEBIDOS') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAODADOSRECEBIDOS';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID             NUMBER not null,';
      VSQL := VSQL || '   IDROTASERVICO  NUMBER not null,';
      VSQL := VSQL || '   DADOSRECEBIDOS CLOB not null,';
      VSQL := VSQL || '   DATACRIACAO    DATE default SYSDATE not null';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAODADOSRECEBIDOS  add constraint PCINTEGRACAODADOSRECEBIDOS_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAODADOSRECEBIDOS  add constraint PCINTEGRACAODADOSRECEBIDOS_FK1 foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOCORE') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOCORE';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID                 NUMBER not null,';
      VSQL := VSQL || '   IDWINTHOR          NUMBER,';
      VSQL := VSQL || '   DATACRIACAO        DATE,';
      VSQL := VSQL || '   IDROTASERVICO      NUMBER not null,';
      VSQL := VSQL || '   DADOSRECEBIDOS     CLOB,';
      VSQL := VSQL || '   DADOSTRANSFORMADOS CLOB,';
      VSQL := VSQL || '   DADOSDEPENDENTES   CLOB,';
      VSQL := VSQL || '   IDEXTERNO          VARCHAR2(100),';
      VSQL := VSQL || '   TENTATIVAS         NUMBER,';
      VSQL := VSQL || '   TIPODOCUMENTO      VARCHAR2(40),';
      VSQL := VSQL || '   OBSERVACAO         CLOB,';
      VSQL := VSQL || '   IDREQUISICAO       VARCHAR2(100),';
      VSQL := VSQL || '   DATASINCRONISMO    DATE,';
      VSQL := VSQL || '   IDPROCESSOWINTHOR  NUMBER(1,1),';
      VSQL := VSQL || '   IDDADOSRECEBIDO    NUMBER,';
      VSQL := VSQL || '   STATUS             NUMBER(2),';
      VSQL := VSQL || '   IDINTERNO          VARCHAR2(100),';
      VSQL := VSQL || '   DTULTALTER         DATE,';
      VSQL := VSQL || '   PAYLOADCONFIRMACAO CLOB,';
      VSQL := VSQL || '   IDREQUISICAOENVIO  VARCHAR2(100),';
      VSQL := VSQL || '   IDROTASERVICOENVIO NUMBER';
      VSQL := VSQL || ' )';
    
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOCORE_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOCORE_FK2 foreign key (IDDADOSRECEBIDO)  references PCINTEGRACAODADOSRECEBIDOS (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOROTASERVICO_FK1 foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOCORE_IDX1 on PCINTEGRACAOCORE (IDEXTERNO)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOCORE_IDX2 on PCINTEGRACAOCORE (IDROTASERVICO)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOCORE_IDX3 on PCINTEGRACAOCORE (IDWINTHOR)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOCORE_IDX4 on PCINTEGRACAOCORE (STATUS)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOCORE_IDX5 on PCINTEGRACAOCORE (IDDADOSRECEBIDO DESC)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOVARIAVEISTEMP') AND (vContador = 0) THEN
      VSQL := 'create table PCINTEGRACAOVARIAVEISTEMP';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID            NUMBER not null,';
      VSQL := VSQL || '   CHAVE         VARCHAR2(100),';
      VSQL := VSQL || '   VALOR         VARCHAR2(255),';
      VSQL := VSQL || '   IDREQUISICAO  VARCHAR2(100),';
      VSQL := VSQL || '   ENCERRADO     VARCHAR2(1) default ''N'',';
      VSQL := VSQL || '   IDROTASERVICO INTEGER,';
      VSQL := VSQL || '   IDREQUISICAOENVIO VARCHAR2(100)';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOVARIAVEISTEMP add constraint PCINTEGRACAOVARIAVEISTEMP_PK primary key(ID)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOVARIAVEISTEMP add constraint PCINTEGRACAOROTASERVICO_FK2 foreign key(IDROTASERVICO) references PCINTEGRACAOROTASERVICO(ID)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOERROREQUISICAO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOERROREQUISICAO';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID                     NUMBER not null,';
      VSQL := VSQL || '   LAYOUTERROTRANSFORMADO CLOB not null,';
      VSQL := VSQL || '   IDROTAERRO             NUMBER not null,';
      VSQL := VSQL || '   IDROTAEXEC             NUMBER not null,';
      VSQL := VSQL || '   HTTPSTATUS             NUMBER not null';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOERROREQUISICAO  add constraint FK_PCINTEGRACAOROTASERVICOERRO foreign key (IDROTAERRO)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOERROREQUISICAO  add constraint FK_PCINTEGRACAOROTASERVICOEXEC foreign key (IDROTAEXEC)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAODADOSCLASSE') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAODADOSCLASSE';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID        NUMBER not null,';
      VSQL := VSQL || '   NOME      VARCHAR2(60),';
      VSQL := VSQL || '   DESCRICAO VARCHAR2(60)';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAODADOSCLASSE  add constraint PCINTEGRACAODADOSCLASSE_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAODADOSMETODO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAODADOSMETODO';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '   ID        NUMBER not null,';
      VSQL := VSQL || '   NOME      VARCHAR2(60),';
      VSQL := VSQL || '   DESCRICAO VARCHAR2(60)';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAODADOSMETODO  add constraint PCINTEGRACAODADOSMETODO_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
    
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOCLASSEMETODO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOCLASSEMETODO';
      VSQL := VSQL || ' (';
      VSQL := VSQL || '  ID                      NUMBER not null,';
      VSQL := VSQL || '  IDINTEGRACAODADOSCLASSE NUMBER,';
      VSQL := VSQL || '   IDINTEGRACAODADOSMETODO NUMBER';
      VSQL := VSQL || ' )';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAOCLASSEMETODO_PK primary key (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAODADOSCLASSE_FK foreign key (IDINTEGRACAODADOSCLASSE)  references PCINTEGRACAODADOSCLASSE (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAODADOSMETODO_FK foreign key (IDINTEGRACAODADOSMETODO)  references PCINTEGRACAODADOSMETODO (ID)';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOAGENDAMENTO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOAGENDAMENTO(ID NUMBER not null,';
      VSQL := VSQL || ' DESCRICAO VARCHAR2(80),';
      VSQL := VSQL || ' AGENDAMENTOSEGUNDOS  NUMBER default (60),';
      VSQL := VSQL || ' DELAYINICIALSEGUNDOS NUMBER default (60))';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOAGENDAMENTO add constraint PCINTEGRACAOAGENDAMENTO_PK primary key(ID)';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOAGENDAMENTOFLUXO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOAGENDAMENTOFLUXO(IDAGENDAMENTO NUMBER not null, IDFLUXO INTEGER not null)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOAGENDAMENTOFLUXO add constraint PCINTEGRACAOAGENDAMENTO_FK1 foreign key(IDAGENDAMENTO) references PCINTEGRACAOAGENDAMENTO(ID)';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOFLUXOEXECUCAO') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOFLUXOEXECUCAO(ORDEMEXECUCAO NUMBER not null,';
      VSQL := VSQL || ' IDROTASERVICO NUMBER not null,';
      VSQL := VSQL || ' IDINTEGRACAOCLASSEMETODO NUMBER,';
      VSQL := VSQL || ' IDFLUXO NUMBER not null,';
      VSQL := VSQL || ' ATIVO VARCHAR2(1),';
      VSQL := VSQL || ' IDDEPENDENTE NUMBER,';
      VSQL := VSQL || ' DTULTALTER DATE,';
      VSQL := VSQL || ' CODEMPALTER VARCHAR2(40),';
      VSQL := VSQL || ' DESCRICAO VARCHAR2(80),';
      VSQL := VSQL || ' ID NUMBER)';
      EXECUTE IMMEDIATE VSQL;
    
      VSQL := ' alter table PCINTEGRACAOFLUXOEXECUCAO add constraint PCINTEGRACAOFLUXOEXECUCAO_PK primary key(ORDEMEXECUCAO, IDFLUXO)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' alter table PCINTEGRACAOFLUXOEXECUCAO add constraint PCINTEGRACAOCLASSEMETODO_FK foreign key (IDINTEGRACAOCLASSEMETODO) references PCINTEGRACAOCLASSEMETODO (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := 'alter table PCINTEGRACAOFLUXOEXECUCAO  add constraint ROTASERVICO_FLUXO_FK foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID)';
      EXECUTE IMMEDIATE VSQL;
      VSQL := ' create index PCINTEGRACAOFLUXOEXECUCAO_IDX1 on PCINTEGRACAOFLUXOEXECUCAO(IDROTASERVICO)';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
    IF (nomeTabela(i) = 'PCINTEGRACAOLOGEXCLUSAODADOS') AND (vContador = 0) THEN
      VSQL := ' create table PCINTEGRACAOLOGEXCLUSAODADOS(';
      VSQL := VSQL || ' CRONTAB            VARCHAR2(20),';
      VSQL := VSQL || ' LOG_DADOSEXCLUIDOS CLOB,';
      VSQL := VSQL || ' DATA_EXECUCAO      DATE,';
      VSQL := VSQL || ' DIAS               NUMBER,';
      VSQL := VSQL || ' TIPO_DADO          VARCHAR2(20))';
      EXECUTE IMMEDIATE VSQL;
    END IF;
  
  END LOOP;

END;
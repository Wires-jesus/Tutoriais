  create table PCINTEGRACAOCOREMIGRATION(NOME VARCHAR2(255) not null,
       DTCRIACAO     DATE default SYSDATE not null,
       DTATUALIZACAO DATE default SYSDATE not null,
       DESCRICAOERRO CLOB,
       SUCESSO       VARCHAR2(1) default 'S' not null,
       TENTATIVAS    NUMBER default 0 not null,
       TESTE         VARCHAR2(1) default 'N' not null,
       SQLGERADO CLOB,
       VERSAO VARCHAR2(10),
       PROJETONOME VARCHAR2(20),
       TABELA VARCHAR2(40));
    
       comment on column PCINTEGRACAOCOREMIGRATION.NOME is 'Nome do arquivo de migration';    
       alter table PCINTEGRACAOCOREMIGRATION add constraint PCINTEGRACAOCOREMIGRATION_PK primary key(NOME, TESTE);
       create index IDX_PROJETONOME_VERSAO on PCINTEGRACAOCOREMIGRATION(PROJETONOME, VERSAO);
  
    /  
      create table PCINTEGRACAODADOSEMPRESA
       (
        ID                  NUMBER not null,
        NOME                VARCHAR2(40),
        URLBASE             VARCHAR2(80),
        TOKENCLIENTE        CLOB,
        WTA                 VARCHAR2(1),
        DTSOLICITACAOTOKEN  DATE,
        TOKENTEMPOEXPIRACAO NUMBER default 3600,
        VERSAO  VARCHAR2(20),
        PROJETONOME VARCHAR2(40)
       );
    
       alter table PCINTEGRACAODADOSEMPRESA  add constraint PCINTEGRACAODADOSEMPRESA_PK primary key (ID);
       alter table PCINTEGRACAODADOSEMPRESA  add constraint NOME_UK unique (NOME);
    
      / 
      create table PCINTEGRACAOROTASERVICO
       (
         ID                             NUMBER not null,
         IDEMPRESAAPI                   NUMBER not null,
         SERVICO                        VARCHAR2(40),
         LAYOUTCOMUNICACAO              CLOB,
         LAYOUTTRANSFORMACAO            CLOB,
         ARQUITETURA                    VARCHAR2(20),
         ATIVO                          VARCHAR2(1),
         TIPOPROCESSO                   VARCHAR2(80),
         AUTENTICADOR                   VARCHAR2(1),
         DATASINCRONISMO                DATE,
         REFRESHTOKEN                   VARCHAR2(1),
         IDROTAIDEXTERNO                NUMBER,
         SOMENTEATUALIZARINTEGRACAOCORE VARCHAR2(1) default 'N' not null
       );
      
       alter table PCINTEGRACAOROTASERVICO  add constraint PCINTEGRACAOROTASERVICO_PK primary key (ID);
       alter table PCINTEGRACAOROTASERVICO  add constraint SERVICO_UK unique (SERVICO);
       alter table PCINTEGRACAOROTASERVICO  add constraint PCINTEGRACAODADOSEMPRESA_FK foreign key (IDEMPRESAAPI)  references PCINTEGRACAODADOSEMPRESA (ID);
       create index PCINTEGRACAOROTASERVICO_IDX1 on PCINTEGRACAOROTASERVICO (TIPOPROCESSO);
       create index PCINTEGRACAOROTASERVICO_IDX2 on PCINTEGRACAOROTASERVICO (ATIVO);
    
      / 
       create table PCINTEGRACAOVARIAVEIS
       (
         ID            NUMBER not null,
         CHAVE         VARCHAR2(40),
         TIPOCHAVE     VARCHAR2(20),
         TIPOVALOR     VARCHAR2(20),
         IDROTASERVICO NUMBER not null,
         DTULTALTER    DATE,
         CODEMPALTER   VARCHAR2(40),
         VALOR         CLOB
       );
      
       alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_PK primary key (ID);
       alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOROTASERVICO_FK foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID);
       alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_CK1  check (TIPOCHAVE IN('HEADER', 'BODY', 'PARAMS', 'REQUEST', 'RESPONSE'));
       alter table PCINTEGRACAOVARIAVEIS  add constraint PCINTEGRACAOVARIAVEIS_CK2  check (TIPOVALOR IN('STRING', 'INTEGER', 'DOUBLE', 'DATE', 'SELECT', 'ENCRYPTED'));
     
    / 
       create table PCINTEGRACAODADOSRECEBIDOS
       (
         ID             NUMBER not null,
         IDROTASERVICO  NUMBER not null,
         DADOSRECEBIDOS CLOB not null,
         DATACRIACAO    DATE default SYSDATE not null
       );
     
        alter table PCINTEGRACAODADOSRECEBIDOS  add constraint PCINTEGRACAODADOSRECEBIDOS_PK primary key (ID);
        alter table PCINTEGRACAODADOSRECEBIDOS  add constraint PCINTEGRACAODADOSRECEBIDOS_FK1 foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID);
      
    /
       create table PCINTEGRACAOCORE
       (
         ID                 NUMBER not null,
         IDWINTHOR          NUMBER,
         DATACRIACAO        DATE,
         IDROTASERVICO      NUMBER not null,
         DADOSRECEBIDOS     CLOB,
         DADOSTRANSFORMADOS CLOB,
         DADOSDEPENDENTES   CLOB,
         IDEXTERNO          VARCHAR2(100),
         TENTATIVAS         NUMBER,
         TIPODOCUMENTO      VARCHAR2(40),
         OBSERVACAO         CLOB,
         IDREQUISICAO       VARCHAR2(100),
         DATASINCRONISMO    DATE,
         IDPROCESSOWINTHOR  NUMBER(1,1),
         IDDADOSRECEBIDO    NUMBER,
         STATUS             NUMBER(2),
         IDINTERNO          VARCHAR2(100),
         DTULTALTER         DATE,
         PAYLOADCONFIRMACAO CLOB,
         IDREQUISICAOENVIO  VARCHAR2(100),
         IDROTASERVICOENVIO NUMBER
       );
    
       alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOCORE_PK primary key (ID);
       alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOCORE_FK2 foreign key (IDDADOSRECEBIDO)  references PCINTEGRACAODADOSRECEBIDOS (ID);
       alter table PCINTEGRACAOCORE  add constraint PCINTEGRACAOROTASERVICO_FK1 foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID);
       create index PCINTEGRACAOCORE_IDX1 on PCINTEGRACAOCORE (IDEXTERNO);
       create index PCINTEGRACAOCORE_IDX2 on PCINTEGRACAOCORE (IDROTASERVICO);
       create index PCINTEGRACAOCORE_IDX3 on PCINTEGRACAOCORE (IDWINTHOR);
       create index PCINTEGRACAOCORE_IDX4 on PCINTEGRACAOCORE (STATUS);
       create index PCINTEGRACAOCORE_IDX5 on PCINTEGRACAOCORE (IDDADOSRECEBIDO DESC);
       
    / 
      create table PCINTEGRACAOVARIAVEISTEMP
       (
         ID            NUMBER not null,
         CHAVE         VARCHAR2(100),
         VALOR         VARCHAR2(255),
         IDREQUISICAO  VARCHAR2(100),
         ENCERRADO     VARCHAR2(1) default 'N',
         IDROTASERVICO INTEGER,
         IDREQUISICAOENVIO VARCHAR2(100)
       );
       
       alter table PCINTEGRACAOVARIAVEISTEMP add constraint PCINTEGRACAOVARIAVEISTEMP_PK primary key(ID);
       alter table PCINTEGRACAOVARIAVEISTEMP add constraint PCINTEGRACAOROTASERVICO_FK2 foreign key(IDROTASERVICO) references PCINTEGRACAOROTASERVICO(ID);
       
    /
       create table PCINTEGRACAOERROREQUISICAO
       (
         ID                     NUMBER not null,
         LAYOUTERROTRANSFORMADO CLOB not null,
         IDROTAERRO             NUMBER not null,
         IDROTAEXEC             NUMBER not null,
         HTTPSTATUS             NUMBER not null
       );
      
       alter table PCINTEGRACAOERROREQUISICAO  add constraint FK_PCINTEGRACAOROTASERVICOERRO foreign key (IDROTAERRO)  references PCINTEGRACAOROTASERVICO (ID);
       alter table PCINTEGRACAOERROREQUISICAO  add constraint FK_PCINTEGRACAOROTASERVICOEXEC foreign key (IDROTAEXEC)  references PCINTEGRACAOROTASERVICO (ID);
    
      /
       create table PCINTEGRACAODADOSCLASSE
       (
         ID        NUMBER not null,
         NOME      VARCHAR2(60),
         DESCRICAO VARCHAR2(60)
       );
    
       alter table PCINTEGRACAODADOSCLASSE  add constraint PCINTEGRACAODADOSCLASSE_PK primary key (ID);
  
    / 
       create table PCINTEGRACAODADOSMETODO
       (
         ID        NUMBER not null,
         NOME      VARCHAR2(60),
         DESCRICAO VARCHAR2(60)
       );
      
       alter table PCINTEGRACAODADOSMETODO  add constraint PCINTEGRACAODADOSMETODO_PK primary key (ID);
       
    /
       create table PCINTEGRACAOCLASSEMETODO
       (
        ID                      NUMBER not null,
        IDINTEGRACAODADOSCLASSE NUMBER,
         IDINTEGRACAODADOSMETODO NUMBER
       );
      
       alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAOCLASSEMETODO_PK primary key (ID);
       alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAODADOSCLASSE_FK foreign key (IDINTEGRACAODADOSCLASSE)  references PCINTEGRACAODADOSCLASSE (ID);
       alter table PCINTEGRACAOCLASSEMETODO  add constraint PCINTEGRACAODADOSMETODO_FK foreign key (IDINTEGRACAODADOSMETODO)  references PCINTEGRACAODADOSMETODO (ID);

    / 
       create table PCINTEGRACAOAGENDAMENTO(ID NUMBER not null,
       DESCRICAO VARCHAR2(80),
       AGENDAMENTOSEGUNDOS  NUMBER default (60),
       DELAYINICIALSEGUNDOS NUMBER default (60));
       
       alter table PCINTEGRACAOAGENDAMENTO add constraint PCINTEGRACAOAGENDAMENTO_PK primary key(ID);
    / 
       create table PCINTEGRACAOAGENDAMENTOFLUXO(IDAGENDAMENTO NUMBER not null, IDFLUXO INTEGER not null);
       alter table PCINTEGRACAOAGENDAMENTOFLUXO add constraint PCINTEGRACAOAGENDAMENTO_FK1 foreign key(IDAGENDAMENTO) references PCINTEGRACAOAGENDAMENTO(ID);
  
    /  
       create table PCINTEGRACAOFLUXOEXECUCAO(ORDEMEXECUCAO NUMBER not null,
       IDROTASERVICO NUMBER not null,
       IDINTEGRACAOCLASSEMETODO NUMBER,
       IDFLUXO NUMBER not null,
       ATIVO VARCHAR2(1),
       IDDEPENDENTE NUMBER,
       DTULTALTER DATE,
       CODEMPALTER VARCHAR2(40),
       DESCRICAO VARCHAR2(80),
       ID NUMBER);
      
       alter table PCINTEGRACAOFLUXOEXECUCAO add constraint PCINTEGRACAOFLUXOEXECUCAO_PK primary key(ORDEMEXECUCAO, IDFLUXO);
       alter table PCINTEGRACAOFLUXOEXECUCAO add constraint PCINTEGRACAOCLASSEMETODO_FK foreign key (IDINTEGRACAOCLASSEMETODO) references PCINTEGRACAOCLASSEMETODO (ID);
       alter table PCINTEGRACAOFLUXOEXECUCAO  add constraint ROTASERVICO_FLUXO_FK foreign key (IDROTASERVICO)  references PCINTEGRACAOROTASERVICO (ID);
       create index PCINTEGRACAOFLUXOEXECUCAO_IDX1 on PCINTEGRACAOFLUXOEXECUCAO(IDROTASERVICO);
  
    /  
       create table PCINTEGRACAOLOGEXCLUSAODADOS(
       CRONTAB            VARCHAR2(20),
       LOG_DADOSEXCLUIDOS CLOB,
       DATA_EXECUCAO      DATE,
       DIAS               NUMBER,
       TIPO_DADO          VARCHAR2(20));
      
    
  
  
 
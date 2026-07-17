# Conexão ao Banco Oracle via SQLPlus (GitHub Copilot CLI)

Guia para configurar o fluxo de conexão diária ao banco Oracle usando `sqlplus` integrado ao **GitHub Copilot CLI**, com suporte a múltiplos perfis de owner/banco.

---

## Como funciona

As credenciais ficam armazenadas em um arquivo local **fora do repositório**, com um perfil por owner. Quando necessário, solicite ao Copilot informando qual perfil usar:

> *"Conecte no owner local"*
> *"Conecte no owner monitorpdvmiddle"*

O Copilot lê o arquivo de credenciais, identifica o perfil solicitado e abre a conexão via `sqlplus`.

---

## Pré-requisitos

- `sqlplus` disponível no PATH (Oracle Database Home instalado)
- GitHub Copilot CLI ativo no VS Code
- Arquivo `db.env` preenchido com os perfis desejados

---

## 1. Criar o arquivo de credenciais

O arquivo deve ficar em:

```
C:\Analises-Copilot\Conexao_banco\db.env
```

> ⚠️ **Este diretório fica fora do repositório Git** — as credenciais nunca serão commitadas.

### Estrutura do arquivo com múltiplos perfis

Cada perfil é identificado por um prefixo em maiúsculas com o nome do owner:

```env
# ============================================================
# Perfis de conexão Oracle - GitHub Copilot CLI
# Uso: "conecte no owner local" ou "conecte no owner monitorpdvmiddle"
# ============================================================

# Perfil: local
LOCAL_USER=seu_usuario
LOCAL_PASS=sua_senha
LOCAL_HOST=127.0.0.1
LOCAL_PORT=1521
LOCAL_SERVICE=orcl

# Perfil: monitorpdvmiddle
MONITORPDVMIDDLE_USER=seu_usuario
MONITORPDVMIDDLE_PASS=sua_senha
MONITORPDVMIDDLE_HOST=host_do_banco
MONITORPDVMIDDLE_PORT=1521
MONITORPDVMIDDLE_SERVICE=nome_do_servico
```

### Adicionando novos perfis

Para adicionar um novo banco ou owner, basta incluir um novo bloco seguindo o padrão:

```env
# Perfil: novoowner
NOVOOWNER_USER=usuario
NOVOOWNER_PASS=senha
NOVOOWNER_HOST=host
NOVOOWNER_PORT=1521
NOVOOWNER_SERVICE=service
```

---

## 2. Uso diário

Abra o **GitHub Copilot CLI** no terminal do VS Code e solicite informando o perfil:

| Comando | Perfil usado |
|---|---|
| `"Conecte no owner local"` | Perfil `LOCAL_*` |
| `"Conecte no owner monitorpdvmiddle"` | Perfil `MONITORPDVMIDDLE_*` |
| `"Conecte no owner novoowner"` | Perfil `NOVOOWNER_*` |

### Exemplos de análises após conexão

```
"Quais os campos da tabela PCDESCONTOFIDELIDADE?"
"Liste as tabelas que referenciam PCPRODUT"
"Quantos registros tem PCGRUPOFIDELIDADE?"
"Descreva a estrutura da tabela PCCLIENT"
```

---

## 3. Segurança

| Prática | Status |
|---|---|
| Credenciais fora do repositório Git | ✅ |
| Arquivo não versionado | ✅ |
| Conexão somente sob demanda explícita | ✅ |
| Perfil informado pelo analista a cada sessão | ✅ |

> 🔒 **Nunca adicione o arquivo `db.env` ao repositório Git.**

---

## 4. Integração com GitHub Copilot

> 💡 Com o Copilot conectado ao banco, é possível realizar análises como:
> - Estrutura de tabelas (`ALL_TAB_COLUMNS`)
> - Dependências entre objetos (`ALL_DEPENDENCIES`)
> - Validação de dados e contagens em tempo real
> - Comparação entre estrutura do banco e objetos do repositório
>
> O Copilot **não acessa o banco automaticamente** — a conexão só ocorre quando explicitamente solicitada com o comando *"conecte no owner \<nome\>"*.


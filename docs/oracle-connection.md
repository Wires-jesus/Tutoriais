# Conectando ao Banco Oracle via VS Code

Guia para configurar a extensão **Oracle Developer Tools for VS Code** e conectar ao banco Oracle do Winthor.

---

## Pré-requisitos

- [VS Code](https://code.visualstudio.com/) instalado
- Oracle Database Home ou Oracle Instant Client instalado na máquina
- Credenciais de acesso ao banco (usuário, senha, host, porta, service name)

---

## 1. Instalar a Extensão

No VS Code, abra o **Marketplace** (`Ctrl + Shift + X`), pesquise por:

```
Oracle Developer Tools for VS Code
```

Instale a extensão publicada por **Oracle** (ID: `Oracle.oracledevtools`).

---

## 2. Configurar o settings.json

A extensão precisa saber onde está o Oracle Client instalado na sua máquina.

### Como abrir o settings.json

**Opção 1 — Atalho de teclado:**
1. Pressione `Ctrl + Shift + P`
2. Digite `Open User Settings (JSON)`
3. Pressione Enter

**Opção 2 — Pelo menu:**
1. `File → Preferences → Settings`
2. Clique no ícone **{ }** (Open Settings JSON) no canto superior direito da aba

### Adicionar a configuração do Oracle Client

Dentro do `settings.json`, adicione a propriedade abaixo apontando para a pasta `bin` do seu Oracle Home:

```json
"oracle.connections.instantClientDirectory": "C:\\oracle\\product\\11.2.0\\dbhome_1\\bin"
```

Exemplo de arquivo completo:

```json
{
    "oracle.connections.instantClientDirectory": "C:\\oracle\\product\\11.2.0\\dbhome_1\\bin"
}
```

> ⚠️ No Windows, use barras duplas `\\` no caminho.

Salve o arquivo (`Ctrl + S`) e **reinicie o VS Code**.

---

## 3. Criar a Conexão no Oracle Explorer

Após reiniciar o VS Code:

1. Clique no ícone do **Oracle Explorer** na barra lateral esquerda
2. Clique em **"+"** para adicionar uma nova conexão
3. Preencha os campos:
   - **Connection Type:** Basic
   - **Host:** endereço do servidor Oracle
   - **Port:** `1521` (padrão Oracle)
   - **Service Name / SID:** nome do serviço ou SID do banco
   - **Username:** seu usuário
   - **Password:** sua senha
4. Clique em **Create Connection**

A conexão aparecerá no Oracle Explorer. Clique nela para expandir e navegar pelos objetos do banco.

---

## 4. Executando Scripts PL/SQL

Com a conexão ativa, você pode executar arquivos `.sql`, `.pks` e `.pkb` diretamente no VS Code:

- Abra o arquivo desejado
- Clique com o botão direito no editor → **Execute in Oracle Database**
- Ou use o atalho `Ctrl + Enter` para executar o bloco selecionado

Os resultados aparecem na aba **Oracle DB Output** no terminal inferior.

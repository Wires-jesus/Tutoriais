# Ajuste: Proteção contra valores nulos nos campos BASEICMS e PERCICM

**Data:** 2026-07-15
**Arquivo alterado:** `Migration/PROCESSO_INT_C5_VENDA/PROCESSO_INT_C5_VENDA.sql`
**Banco de dados:** Oracle 11g ou superior

---

## O que foi alterado

Foram adicionadas funções `NVL` em **5 ocorrências** do campo `PERCICM`, garantindo que esse campo nunca retorne valor nulo. O campo `BASEICMS` foi analisado e **já estava corretamente protegido** em todas as suas 4 ocorrências.

### Campo BASEICMS — sem alteração necessária

Todas as 4 ocorrências do campo `BASEICMS` (nas views `vw_int_c5_pcpedcecf`, `vw_int_c5_pcpediecf` e `VW_INT_C5_PCPEDIECFCESTA`) já estavam protegidas com `NVL(..., 0)`. Nenhuma modificação foi realizada.

---

### Campo PERCICM — 5 ocorrências alteradas

#### Alteração 1 — Valor literal NULL (linha ~1698)

**View:** `vw_int_c5_pcpedcecf`

**Antes:**
```sql
NULL percicm,
```

**Depois:**
```sql
0 percicm,
```

---

#### Alterações 2, 3, 4, 5 — Subquery sem NVL (linhas ~2058, ~2604, ~3771, ~4094)

**Views afetadas:**

| # | Linha | View |
|---|-------|------|
| 2 | ~2058 | `vw_int_c5_pcpedcecf` |
| 3 | ~2604 | `vw_int_c5_pcpediecf` |
| 4 | ~3771 | `VW_INT_C5_PCPEDIECFCESTA` (seção 1) |
| 5 | ~4094 | `VW_INT_C5_PCPEDIECFCESTA` (seção 2) |

**Antes:**
```sql
(select percaliquota
   from monitorpdvmiddle.tb_doctotributacaoitem
  where nroempresa = i.nroempresa
    and nrocheckout = i.nrocheckout
    and seqdocto = i.seqdocto
    and seqitem = i.seqitem
    and seqtipotributacao = 1) percicm,
```

**Depois:**
```sql
NVL((select percaliquota
   from monitorpdvmiddle.tb_doctotributacaoitem
  where nroempresa = i.nroempresa
    and nrocheckout = i.nrocheckout
    and seqdocto = i.seqdocto
    and seqitem = i.seqitem
    and seqtipotributacao = 1), 0) percicm,
```

---

## Por que foi alterado

### PERCICM — valor literal NULL (1 ocorrência)
Uma das seções da view retornava `NULL percicm` diretamente, sem nenhum cálculo. Isso gerava um valor nulo no campo que alimenta o campo `PERCICM` no sistema C5, podendo causar erros de integração ou comportamento inesperado nos cálculos de alíquota de ICMS no destino.

### PERCICM — subquery sem NVL (4 ocorrências)
A subquery busca o campo `percaliquota` na tabela `monitorpdvmiddle.tb_doctotributacaoitem` filtrando por `seqtipotributacao = 1`. Quando não existe registro correspondente para o item (produto sem tributação cadastrada ou item não processado pela tributação do PDV), a subquery retorna `NULL`, pois não encontra nenhuma linha. Esse `NULL` propagava-se diretamente para o campo `PERCICM` nas views, podendo causar falhas silenciosas ou erros nos sistemas consumidores.

---

## Resumo das views impactadas

| View | Campo | Tipo de alteração |
|------|-------|-------------------|
| `vw_int_c5_pcpedcecf` | `PERCICM` | Literal `NULL` → `0` |
| `vw_int_c5_pcpedcecf` | `PERCICM` | Subquery sem `NVL` → `NVL(..., 0)` |
| `vw_int_c5_pcpediecf` | `PERCICM` | Subquery sem `NVL` → `NVL(..., 0)` |
| `VW_INT_C5_PCPEDIECFCESTA` | `PERCICM` | Subquery sem `NVL` → `NVL(..., 0)` (×2) |
| `vw_int_c5_pcpedcecf` | `BASEICMS` | ✅ Já protegido — sem alteração |
| `vw_int_c5_pcpediecf` | `BASEICMS` | ✅ Já protegido — sem alteração |
| `VW_INT_C5_PCPEDIECFCESTA` | `BASEICMS` | ✅ Já protegido — sem alteração |

---

## Fluxo de teste para validação

### Pré-condições
- Ambiente Oracle 11g ou superior com o script aplicado
- Acesso às views `vw_int_c5_pcpedcecf`, `vw_int_c5_pcpediecf` e `VW_INT_C5_PCPEDIECFCESTA`

---

### Teste 1 — Verificar ausência de NULLs nos campos alterados

Execute as consultas abaixo e confirme que o resultado é **zero** em todos os casos:

```sql
-- vw_int_c5_pcpedcecf
SELECT COUNT(*)
  FROM vw_int_c5_pcpedcecf
 WHERE percicm IS NULL
    OR baseicms IS NULL;

-- vw_int_c5_pcpediecf
SELECT COUNT(*)
  FROM vw_int_c5_pcpediecf
 WHERE percicm IS NULL
    OR baseicms IS NULL;

-- VW_INT_C5_PCPEDIECFCESTA
SELECT COUNT(*)
  FROM VW_INT_C5_PCPEDIECFCESTA
 WHERE percicm IS NULL
    OR baseicms IS NULL;
```

**Resultado esperado:** `0` em todas as consultas.

---

### Teste 2 — Item sem registro de tributação em tb_doctotributacaoitem

Cenário: item de venda que **não possui** registro na tabela `tb_doctotributacaoitem` com `seqtipotributacao = 1`.

```sql
-- Identificar um item sem tributação
SELECT i.seqdocto, i.seqitem
  FROM monitorpdvmiddle.tb_doctoitem i
 WHERE NOT EXISTS (
       SELECT 1
         FROM monitorpdvmiddle.tb_doctotributacaoitem t
        WHERE t.nroempresa      = i.nroempresa
          AND t.nrocheckout     = i.nrocheckout
          AND t.seqdocto        = i.seqdocto
          AND t.seqitem         = i.seqitem
          AND t.seqtipotributacao = 1
       )
   AND ROWNUM <= 5;

-- Verificar o campo percicm para esse item
SELECT seqdocto, seqitem, percicm
  FROM vw_int_c5_pcpedcecf
 WHERE seqdocto = <SEQDOCTO_DO_ITEM_SEM_TRIBUTACAO>;
```

**Resultado esperado:** `percicm = 0` (não NULL).

---

### Teste 3 — Item com tributação cadastrada (regressão)

Cenário: item com registro normal em `tb_doctotributacaoitem`. Validar que o valor de `percaliquota` continua sendo retornado corretamente e não foi substituído por zero indevidamente.

```sql
SELECT seqdocto, seqitem, percicm, baseicms
  FROM vw_int_c5_pcpedcecf
 WHERE seqdocto = <SEQDOCTO_COM_TRIBUTACAO_NORMAL>;
```

**Resultado esperado:** `percicm` com o valor da alíquota (`> 0`), `baseicms` com o valor da base de cálculo correspondente.

---

### Teste 4 — Teste de integração com C5

Realizar uma venda completa no PDV e verificar que o documento é integrado ao C5 sem erros, com os campos `BASEICMS` e `PERCICM` devidamente preenchidos na nota fiscal gerada.

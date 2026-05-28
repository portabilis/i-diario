---
description: Consolida ./tmp/cr_1_<PR>.md + ./tmp/cr_2_<PR>.md, deduplica e posta UM comment no PR
argument-hint: <PR-number>
---

PR_NUM="$ARGUMENTS"

**Contexto:** os arquivos `./tmp/cr_1_$PR_NUM.md` e `./tmp/cr_2_$PR_NUM.md` contêm findings de code review de dois agents distintos. Cada arquivo começa com um header padronizado (PR/SHA/Branch/Timestamp/Skill ou Aspectos rodados) seguido do output literal da skill.

- `cr_1`: skill `/code-review xhigh` (fan-out 5 agentes Sonnet em paralelo — CLAUDE.md compliance, shallow bug scan, git blame/history, PRs anteriores, code comments)
- `cr_2`: plugin `/pr-review-toolkit:review-pr` (agentes especializados por aspecto: errors, tests, types, comments, code, simplify)

**Sua tarefa:** ler os dois arquivos, deduplicar findings, categorizar por severidade e postar UM comment consolidado no PR via `gh pr comment $PR_NUM --body-file -` (passar o body via heredoc/stdin pra evitar problemas com backticks no body).

**Dedup:** dois findings são iguais se (a) referem o mesmo arquivo, (b) a linha está dentro de ±3 linhas, (c) descrevem o mesmo problema (mesmo verbo central + objeto, ignorando diferenças de fraseado). Quando duplicado, manter UMA entrada com `**Detectado por:** cr_1 + cr_2` e usar a **maior severidade** entre as duas fontes.

**Template do comment a postar:**

```markdown
## 🔍 Code Review consolidado — PR #<PR_NUM>

**Fontes:** `/code-review xhigh` (5 agentes em paralelo) + `/pr-review-toolkit:review-pr` (agentes especializados por aspecto)

### Resumo

| Severidade | Quantidade |
|---|---|
| 🚨 CRITICAL | <N> |
| ⚠️ HIGH | <N> |
| 📝 MEDIUM | <N> |
| 💡 LOW | <N> |
| **Total** | **<N>** |

### 🚨 CRITICAL (<N>)

- **[`<file>:<line>`](<link-para-linha-no-PR>)** — <descrição curta>
  <detalhes técnicos>
  **Detectado por:** `cr_1` e/ou `cr_2` (ambos se duplicado)

### ⚠️ HIGH (<N>)

(idem)

### 📝 MEDIUM (<N>)

(idem)

### 💡 LOW (<N>)

(idem)

---

### Próximos passos para o autor

1. **Aplicar fixes que fizerem sentido** — pode usar Claude no editor pra ajudar, mas revise cada change
2. **Para findings que NÃO vai aplicar** — justifique (false positive, fora de escopo, trade-off aceito)
3. **Responda neste PR** com resumo:
   - **Aplicados:** N (commits abc, def, ...)
   - **Não aplicados:** N (com justificativa em 1 linha cada)
4. **Pedir review humano** após resposta

---
<sub>🤖 Gerado por /cr-consolidate · ver [docs/code-review-agentico.md](../blob/main/docs/code-review-agentico.md)</sub>
```

**Regras de severidade — classificar você mesmo pelo conteúdo:**

A skill `/code-review` NÃO emite severity keywords (CRITICAL/HIGH/etc.) no output — só lista findings numerados com link pro código. O `/pr-review-toolkit` usa rótulos próprios (`Critical` / `Important` / `Suggestions`). Mapeie ambos para o esquema canônico abaixo lendo o conteúdo de cada finding:

- **CRITICAL:** bug em produção/segurança/integridade de dados (multi-tenant leak, SQL injection, auth bypass, migration destrutiva sem backfill, silent failure em path crítico). Também: qualquer finding rotulado `Critical` pelo `pr-review-toolkit`.
- **HIGH:** bug com alta probabilidade de incidente (N+1 em endpoint quente, missing test pra lógica nova, service object ausente em lógica >20 linhas, missing index em FK consultada). Também: `Important` do `pr-review-toolkit`.
- **MEDIUM:** problema de qualidade que vira dívida técnica (refactor sugerido, método com >5 args, log sem contexto, comentário desatualizado). Também: `Suggestions` do `pr-review-toolkit`.
- **LOW:** estilo, sugestão opcional (espaçamento, nome de variável, nit).

**Default em caso de dúvida:** MEDIUM (não CRITICAL — evita falso positivo de severidade).

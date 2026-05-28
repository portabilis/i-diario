---
description: Code review baseline — roda Skill code-review xhigh e salva em ./tmp/cr_1_<PR>.md
argument-hint: <PR-number>
---

PR_NUM="$ARGUMENTS"

Rode `/code-review xhigh $PR_NUM` e salve o output em `./tmp/cr_1_$PR_NUM.md`.

**Formato do arquivo salvo** (header + output literal da skill):

```markdown
# /cr-1 output (review baseline)

**PR:** #<PR_NUM>
**SHA:** <PR head SHA>
**Branch:** <PR head branch>
**Timestamp:** <UTC ISO 8601>
**Skill:** /code-review xhigh (5 agentes Sonnet em paralelo: CLAUDE.md compliance, shallow bug scan, git blame/history, PRs anteriores, code comments)

---

<output literal da skill code-review — começa com `### Code review`>

---
<sub>🤖 review baseline · /cr-1</sub>
```

**Importante:** preserve o output da skill SEM tradução ou reformatação. Não invente severidade, agrupamento ou tabela de resumo.

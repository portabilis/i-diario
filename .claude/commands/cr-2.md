---
description: Code review especializado — pr-review-toolkit por aspecto detectado e salva em ./tmp/cr_2_<PR>.md
argument-hint: <PR-number>
---

PR_NUM="$ARGUMENTS"

Rode `/pr-review-toolkit:review-pr $PR_NUM` e salve o output em `./tmp/cr_2_$PR_NUM.md`. Você decide quais aspects da skill rodar com base no diff do PR (errors/tests/types/comments/code/simplify/all). Use `all` se o diff for grande ou tocar múltiplos tipos de código; aspect específico se o diff for focado.

**Formato do arquivo salvo:**

```markdown
# /cr-2 output (review especializado)

**PR:** #<PR_NUM>
**SHA:** <PR head SHA>
**Branch:** <PR head branch>
**Timestamp:** <UTC ISO 8601>
**Aspectos rodados:** <ex: errors, tests, types — ou "all">

---

<output literal da skill — preserve seções por aspecto se houver>

---
<sub>🤖 review especializado · /cr-2</sub>
```

**Importante:** preserve o output da skill SEM tradução ou reformatação. Se a skill emite rótulos próprios (`Critical` / `Important` / `Suggestions`), mantenha-os literalmente.

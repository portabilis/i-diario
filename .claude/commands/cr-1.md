---
description: Code review baseline — roda Skill code-review xhigh e salva em ./tmp/cr_1_<PR>.md
argument-hint: <PR-number>
---

PR_NUM="$ARGUMENTS"

## Não toque no git

**Esta skill é read-only sobre o repositório.** O arquivo de review é a única escrita permitida.

Antes de qualquer coisa, registre onde você está:

```bash
git rev-parse --abbrev-ref HEAD   # branch atual
git rev-parse HEAD                # SHA atual
```

**Se a branch atual já é a do PR** — o caso normal, já que quem roda o review está trabalhando nela — o diff já está no disco (`git diff origin/main...HEAD`). Não faça checkout, não crie branch, não adicione worktree, não rode `stash`/`reset`/`clean`. A skill `/code-review` pode oferecer fazer parte disso por conta própria: **recuse**.

Só quando a branch atual **não** for a do PR, leia o diff com `gh pr diff $PR_NUM` — sem sair de onde está.

Ao terminar, confirme que branch e SHA são os que você registrou. Se algum mudou, **volte** (`git checkout <branch original>`) e diga isso no arquivo de output: quem está na sessão pode ter fixes não-commitados que um checkout apaga, e um push posterior responderia "Everything up-to-date" enquanto o PR fica sem os commits.

**Antes de começar, apague qualquer arquivo de run anterior** deste PR para não deixar review stale caso esta run falhe no meio:

```bash
rm -f "./tmp/cr_1_$PR_NUM.md"
```

Rode `/code-review xhigh $PR_NUM` e salve o output em `./tmp/cr_1_$PR_NUM.md`. **Sobrescreva o arquivo por completo** (Write tool / `>`, nunca append nem Edit sobre conteúdo antigo). O `SHA` no header DEVE ser o head atual do PR (`gh pr view $PR_NUM --json headRefOid -q .headRefOid`).

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

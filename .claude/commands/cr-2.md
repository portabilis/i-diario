---
description: Code review especializado — pr-review-toolkit por aspecto detectado e salva em ./tmp/cr_2_<PR>.md
argument-hint: <PR-number>
---

PR_NUM="$ARGUMENTS"

## Não toque no git nem nos arquivos do repositório

**Esta skill é read-only sobre o repositório.** O arquivo de review é a única escrita permitida.

Antes de qualquer coisa, registre onde você está:

```bash
git rev-parse --abbrev-ref HEAD   # branch atual
git rev-parse HEAD                # SHA atual
```

**Se a branch atual já é a do PR** — o caso normal, já que quem roda o review está trabalhando nela — o diff já está no disco (`git diff origin/main...HEAD`). Não faça checkout, não crie branch, não adicione worktree, não rode `stash`/`reset`/`clean`.

Só quando a branch atual **não** for a do PR, leia o diff com `gh pr diff $PR_NUM` — sem sair de onde está.

⚠️ **O `pr-review-toolkit` tem dois hábitos que quebram isso**, e os dois já aconteceram de verdade:

1. O sub-agente `code-simplifier` **edita arquivos** mesmo a skill sendo review — o prompt dele manda agir "autonomously and proactively... without requiring explicit requests". Ao perceber as edições, o toolkit **faz rollback da working tree** para o SHA do PR, levando junto qualquer fix não-commitado de quem está na sessão.
2. Ele **cria a própria branch** (ex.: `<branch-do-pr>-cr2`) e deixa a sessão nela. Commits seguintes caem lá, e `git push` na branch do PR responde **"Everything up-to-date"** enquanto o remoto continua no SHA antigo.

O hábito 1 fica fechado por construção: a lista de aspectos abaixo nunca inclui `simplify`, então o `code-simplifier` não chega a ser criado. O hábito 2 ainda exige conferir a branch no fim.

Se algum aspecto oferecer aplicar simplificação ou fix, **não aplique** — descreva no relatório.

**Antes de começar, apague qualquer arquivo de run anterior** deste PR para não deixar review stale caso esta run falhe no meio:

```bash
rm -f "./tmp/cr_2_$PR_NUM.md"
```

## Quais aspectos rodar

**Nunca passe `all`, nunca passe `simplify`.** `all` expande incluindo `simplify`, que invoca o `code-simplifier` — o agente que edita arquivos por conta própria. Nomear os aspectos explicitamente é o que mantém este passo read-only; não existe string de aspecto que cubra tudo e continue read-only.

Escolha entre estes cinco, conforme o diff:

| Aspecto | Rode quando |
|---|---|
| `code` | sempre — qualidade geral contra o CLAUDE.md |
| `tests` | o diff adiciona ou altera specs |
| `errors` | o diff toca `rescue`, tratamento de erro ou log |
| `comments` | o diff adiciona ou altera comentário, docstring ou `/docs` |
| `types` | o diff introduz novos tipos ou value objects |

Para diff amplo, passe os cinco — é o equivalente read-only de `all`:

```bash
/pr-review-toolkit:review-pr $PR_NUM code tests errors comments types
```

Salve o output em `./tmp/cr_2_$PR_NUM.md`. **Sobrescreva o arquivo por completo** (Write tool / `>`, nunca append nem Edit sobre conteúdo antigo). O `SHA` no header DEVE ser o head atual do PR (`gh pr view $PR_NUM --json headRefOid -q .headRefOid`).

## Ao terminar, confirme os três

```bash
git rev-parse --abbrev-ref HEAD   # tem que ser a branch registrada no começo
git rev-parse HEAD                # tem que ser o SHA registrado
git status --porcelain            # tem que estar vazio
```

Branch ou SHA mudou: **volte** (`git checkout <branch original>`) e registre no arquivo de output. Árvore suja: algum sub-agente escreveu no repositório apesar das regras — dos cinco aspectos, só o `comment-analyzer` declara ser read-only, os outros herdam Edit/Write. Reverta esses arquivos, registre quais sob `## Edições de sub-agente revertidas`, e siga. Nunca termine esta skill com árvore suja: o passo seguinte assume que o review não mudou nada.

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

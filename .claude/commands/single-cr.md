---
description: Code review agêntico do i-Diário em agente único — lentes (.claude/agents/cr-*) aplicadas sequencialmente na própria sessão, sem subagents nem Workflow; ledger em disco, probes em lote (Docker), verificação adversarial por execução, comment consolidado e fix pass
argument-hint: "[PR-number] (default: PR da branch atual)"
---

# /single-cr — code review agêntico em agente único

Variante de agente único do fluxo `/cr-1` → `/cr-2` → `/cr-consolidate`: **tudo roda nesta sessão, sequencialmente** — nenhum subagent, nenhum Workflow. As lentes são as mesmas (`.claude/agents/cr-*.md`), aplicadas por você como checklists; a verificação adversarial vira disciplina de execução em vez de agente independente.

`$ARGUMENTS` é o número do PR. Se vier vazio, resolver pela branch atual:

```bash
gh pr view --json number -q .number
```

Sem PR na branch: parar e avisar.

## Princípios

1. **Review não edita, fix pass não revisa.** Nenhuma alteração de arquivo do repo entre o início da triagem e o comment postado. Aqui isso é **disciplina, não estrutura** — nada te impede de usar Edit, então a regra é sua: escrita permitida só em `./tmp/cr_single_*` e `./tmp/cr_probe_*`. Ambos ficam sob `/tmp` do repo, que é **gitignored** — e precisam estar dentro do repo porque os probes rodam em container, que só enxerga o que está montado em `/app`.
2. **Finding exige regra citável OU evidência executável.** Sem nenhum dos dois, não entra no relatório final.
3. **Afirmação de runtime só entra CONFIRMADA por execução.** O risco nº 1 desta arquitetura é auto-confirmação: quem achou o finding é quem o julga. O antídoto não é "reler com ceticismo" — é **probe cujo output decide**. Persona não gera independência; execução gera.
4. **Cobertura parcial declarada, nunca silenciosa** — o que não foi verificado vai em *Gaps de verificação*.
5. **Lente sem alvo neste diff não roda.** A triagem justifica cada passe E cada pulo.
6. **Achado vai para o ledger no momento em que nasce**, não no fim. Contexto longo pode ser summarizado no meio da run; o que está só na sua cabeça se perde, o que está no disco sobrevive. O comment final é montado **do ledger**, nunca de memória.
7. **Postura de recall no find, rigor no verify.** Candidato de bug com cenário de falha nomeável entra no ledger como `[CANDIDATO]` mesmo sem prova — a barra "regra OU evidência" é aplicada na fase de verify, não na coleta. Solo isso importa MAIS: não há segunda lente para pegar o que você descartou em silêncio.

## Preparação

Pré-condição: **working tree limpa** (`git status --porcelain` vazio). Anote branch e SHA — é contra eles que você confere no fechamento:

```bash
git rev-parse --abbrev-ref HEAD && git rev-parse HEAD
```

⚠️ **Git nunca roda dentro do container** (regra do CLAUDE.md). Comandos de código, sim — sempre: `docker compose run --rm ruby ...`, `docker compose exec postgres psql -U idiario -d idiario_development ...`.

Crie o **ledger** em `./tmp/cr_single_<PR>_ledger.md` (sobrescrever se existir) com o esqueleto:

```markdown
# Ledger /single-cr — PR #<N> · <branch> · <SHA> · <timestamp>

## Triagem
(bucket, passes rodados, passes pulados — preenchido na Fase 1)

## Mapa do diff
(preenchido na Fase 2)

## Candidatos
(um bloco por candidato, apendado na hora — Fase 3)

## Perguntas de probe
(acumuladas nas Fases 2–3, respondidas em lote na Fase 4)

## Verificado e descartado
## Gaps de verificação
```

Formato de cada candidato no ledger (campos obrigatórios):

```markdown
### C<n> — `arquivo:linha` — <SEV> — <título curto>
- **Lente:** <cr-*> · **Status:** CANDIDATO
- **Problema:** <1–2 frases>
- **Cenário de falha:** <input/estado concreto → consequência visível>
- **Regra/Evidência:** <citação de 1 linha OU o que foi lido/rodado — ou "(pendente de probe P<k>)">
- **Tentativa de refutação:** (pendente — preenchido na Fase 5)
```

Ao apendar, **cheque duplicata primeiro**: candidato no mesmo arquivo, linha ±3, mesmo verbo central + objeto = mesma entrada, acrescente a lente em **Lente:** (duas lentes no mesmo ponto é sinal de confirmação, não entrada nova).

## Fase 1 — Triagem: quais lentes rodam, e quais não

Decida pelo **diff final** (não pelo histórico da branch). Colete os sinais de uma vez:

```bash
gh pr diff "$PR_NUM" -R portabilis/i-diario-portabilis --name-only
git diff --stat origin/main...HEAD
git diff --unified=0 origin/main...HEAD | grep -E '^\+' | grep -cE 'rescue|begin$|\.catch\(|ensure$'   # sinal de error handling
git diff --unified=0 origin/main...HEAD | grep -E '^\+' | grep -cE '^\+\s*(class|module) [A-Z]'        # sinal de tipo novo
```

### Buckets

| Bucket | Condição | Teto de lentes |
|---|---|---|
| 📄 **docs-only** | todos os arquivos ∈ `*.md`/`docs/**`/`.claude/**`, **nenhum** executável | 1–2 |
| 🔹 **trivial** | lockfile/bump, ou ≤10 linhas em 1 arquivo | 2 |
| 🔸 **cirúrgico** | ≤ ~40 linhas, ≤ 3 arquivos | ≤ 4 |
| 🔶 **feature** | maior que isso | ≤ 7 (+ sweep se >400 linhas) |

**Regra dura (precede o gate de docs):** qualquer `*.sh`, `scripts/**`, `.github/workflows/**`, `db/migrate/` ou arquivo de `app/`/`lib/` no diff **impede** o tratamento docs-only.

No modo single, o teto é **orçamento de atenção**, não de latência: lente cortada é passe que você não faz. Nunca corte `cr-tenant-guard`, `cr-migrations-data` nem `cr-docs-guard` quando dispararem. Ordem de corte quando estourar: `cr-comment-analyzer` → `cr-type-design` → `cr-code-reviewer` → `cr-test-analyzer` → `cr-silent-failure-hunter` → `cr-query-perf` → `cr-exec-prober`. Se sobrarem só lentes não-cortáveis, o teto cede — rode todas. Todo corte vai para *Gaps de verificação*, com nome e motivo.

### Gates por lente — RODA se, PULA se

O predicado de PULA é tão vinculante quanto o de RODA: bateu o PULA, a lente não roda mesmo que o RODA também bata.

| Lente | RODA se | PULA se |
|---|---|---|
| `cr-tenant-guard` | diff toca `app/`/`lib/` — **sempre**, é a dimensão Critical | diff não tem query, model, controller, service nem worker (só view/asset/locale/config) |
| `cr-rails-way` | diff toca `app/`/`lib/` — **sempre** | nada (lente-base de todo PR com código) |
| `cr-code-reviewer` | bucket **feature** | bucket cirúrgico/trivial/docs — generalista redundante num diff pequeno |
| `cr-query-perf` | diff adiciona/altera SQL cru, AR relation, scope, `app/queries/**`, ou relatório/view que monta query | mudança em query é só rename/reordenação sem mudar plano |
| `cr-migrations-data` | diff toca `db/migrate/`, ou usa `update_all`/`delete_all`/`update_columns` | — |
| `cr-exec-prober` | diff adiciona/altera **lógica executável** em Ruby/JS, **ou** inclui `*.sh`/`scripts/**` | mudança executável é só markup/CSS/locale/constante/renomeação mecânica |
| `cr-test-analyzer` | diff adiciona/altera lógica em service/model/query/controller/worker (com ou sem spec no diff) | diff só mexe em view/asset/doc, ou só renomeia |
| `cr-silent-failure-hunter` | diff **adiciona** `rescue`/`begin`/`ensure`/`.catch(`/retry/fallback, ou toca integração externa (API do i-Educar, HTTP, upload, relatório) | os `rescue` do diff são pré-existentes só movidos/reindentados |
| `cr-comment-analyzer` | diff adiciona/altera comentário, docstring ou prosa técnica em `docs/**` | comentário do diff é anotação trivial (`# rubocop:`, `# frozen_string_literal`) |
| `cr-type-design` | diff cria classe/módulo/value object novo **com estado próprio** | classe nova é service procedural sem estado, worker fino ou spec helper |
| `cr-docs-guard` | diff toca `*.md`, `docs/**` ou `.claude/**` | — |

**Registre a triagem no ledger** em duas listas: **passes rodados** (lente + gatilho em 1 linha) e **passes pulados** (lente + o PULA que bateu, em 1 linha). Silêncio sobre o que não rodou é indistinguível de esquecimento.

## Fase 2 — Mapa do diff (uma leitura, todas as lentes consomem)

Num fluxo multi-agent cada finder relê o diff do zero; aqui você lê **uma vez, com cuidado**, e as lentes consultam o mapa. Leia `git diff origin/main...HEAD` completo (e os arquivos inteiros quando o hunk não se explica sozinho) e registre no ledger:

- **Por arquivo:** hunks e tags de risco — `query-nova`, `rescue-novo`, `migration`, `tipo-novo`, `teste`, `comentário/prosa`, `shell`, `worker`, `bulk-write`, `js/vue` — as tags mapeiam 1:1 para os gates da triagem e viram o índice dos passes.
- **Auditoria de deleções** (herdada do `cr-exec-prober`, feita AQUI porque exige a leitura completa): para cada linha que o diff REMOVE ou substitui, nomeie o invariante/comportamento que ela garantia e onde o código novo o restabelece. Não achou = candidato direto no ledger (guard removido, caminho de erro perdido, validação estreitada, teste deletado que cobria caso real). É a classe de bug que merge/rebase cria sem conflito aparente.
- **Cobertura de decorators:** se o diff toca navegação, features, helper ou classe que algum decorator estende, anote — o comportamento em runtime pode vir de `app/decorators/` (ou de uma engine em `packages/`), não do arquivo do diff.
- **CLAUDE.md / CLAUDE.local.md aplicáveis** e as 2–4 linhas de convenções que importam para este diff.

## Fase 3 — Passes de lente (sequenciais, baratas → caras)

Para cada lente ativa, **leia o arquivo `.claude/agents/cr-<lente>.md` correspondente e aplique a seção Missão como checklist sobre o mapa do diff**. Ignore do arquivo: frontmatter, instruções de spawn e o formato de relatório (o ledger substitui). Não destile nem parafraseie as regras de memória — o arquivo da lente é a fonte; se ele mudou, seu passe muda junto.

Ordem sugerida (textuais primeiro, execução por último — as perguntas de probe acumulam para o lote):

1. `cr-docs-guard`, `cr-comment-analyzer` — julgamento mecânico, rápido
2. `cr-rails-way`, `cr-code-reviewer` (se ativo), `cr-type-design`
3. `cr-tenant-guard`, `cr-silent-failure-hunter`, `cr-test-analyzer`
4. `cr-migrations-data`, `cr-query-perf`, `cr-exec-prober` — os que geram mais perguntas de probe

Durante os passes:

- **Grep/Read/`git diff -S` inline à vontade** — são baratos e imediatos (e rodam no host, sem container).
- **Checagem que exige boot do Rails ou conexão psql NÃO roda agora**: vira pergunta numerada em *Perguntas de probe* no ledger (`P<k> (C<n>): <o que rodar e o que o output decide>`). Cada `docker compose run --rm ruby bundle exec rails runner` paga o boot inteiro do Rails em container — o ganho desta arquitetura é pagar **um** para todas as lentes. Não desperdice o ganho rodando probe avulso no meio de um passe.
- Candidato nasce no ledger na hora (formato da Preparação), inclusive `[CANDIDATO]` sem prova ainda.
- O que você conferiu e **não** virou candidato vai em *Verificado e descartado* na hora, com a razão.

Sem orçamento de transporte: não há resposta de subagent para caber num limite — registre o que encontrar, completo.

**Sweep (só diff >400 linhas):** ao fim dos passes, releia o diff procurando SÓ o que não está no ledger, focando no que a primeira passada tende a perder: código movido/extraído que perdeu guard ou âncora; assimetria de setup/teardown em teste; default de config invertido; linha deletada cujo invariante ninguém restabeleceu.

## Fase 4 — Checkpoint de probes (um boot responde tudo)

Agrupe TODAS as perguntas acumuladas. Tudo em Docker, tudo read-only:

- **Um** script para `rails runner` — arquivo em `./tmp/cr_probe_<PR>.rb` (dentro do repo, que é o que o container monta em `/app`; `/tmp` é gitignored). Somente leitura: nada de `save`/`update`/`delete`/`destroy`; `.to_sql` para extrair SQL real das relations. Models por rede só respondem dentro de `Entity.find_by(name: <entity de dev>).using_connection { ... }` — o nome está no `CLAUDE.local.md`; `Entity.all` pode estar vazio no dev, então confira antes e não assuma `Entity.first` — probe sem isso fala com o banco errado e o output não prova nada.

  ```bash
  docker compose run --rm ruby bundle exec rails runner tmp/cr_probe_<PR>.rb
  ```

- **Um** heredoc `psql` com todas as queries (SELECT/EXPLAIN/`\d`):

  ```bash
  docker compose exec -T postgres psql -U idiario -d idiario_development <<'SQL'
  ...
  SQL
  ```

- `docker compose run --rm ruby bundle exec rspec <spec:linha>` / `npm test -- <arquivo>` quando a pergunta é sobre um teste específico. Suíte com comportamento estranho (0 exemplos, cassette regravado, `create` que persiste fora da transação) é armadilha conhecida do ambiente local — não confunda com defeito do PR.
- Shell script no diff: `bash -n` + leitura crítica (bash 3.2 do macOS: sem `mapfile`, `source <(...)`, `${var,,}`); **não execute script que fale com rede, com a API do i-Educar, ou que escreva no banco**.

Registre cada output no ledger, ao lado da pergunta, e atualize o campo **Regra/Evidência:** dos candidatos que dependiam dele. Apague o `./tmp/cr_probe_<PR>.rb` ao fim da fase.

## Fase 5 — Verify adversarial (o passe que substitui o cr-verifier)

Agora você troca de lado: para cada candidato **CRITICAL, HIGH, `[CANDIDATO]` ou com afirmação de runtime**, a missão é **REFUTÁ-LO**. O campo *Tentativa de refutação* é obrigatório — CONFIRMADO sem ele não existe. As regras são as do `cr-verifier` (leia `.claude/agents/cr-verifier.md` antes deste passe se ainda não leu nesta run):

- Siga o **caminho real do valor** (getters, callbacks, defaults, decorators) — não julgue a função isolada; é o falso positivo nº 1. `app/decorators/` (e os de engines em `packages/`) sobrescrevem classes em runtime.
- Finding que depende de dado usa **registro real do banco de dev**, dentro do contexto de Entity — cenário fabricado não prova nem refuta.
- Finding de custo de query: SQL real via `.to_sql` + `EXPLAIN` — estimativa não vale.
- Finding de tenancy: a prova é o caminho de chamada (quem enfileira o worker e com quais argumentos; a chave de cache construída de verdade).
- Finding visual/CSS: a prova é a tela; sem app de pé em `localhost:3000`, veredito máximo é PLAUSÍVEL + a checagem manual mais curta para o humano.
- Suspeita de pré-existente: compare com `git show origin/main:<arquivo>` no **mesmo registro** — nunca stash/checkout.
- **REFUTADO só com prova construtível** (linha real citada, impossibilidade demonstrada, guard no próprio diff, decorator que cobre o caso, ou probe com output contrário). **Não refute por "especulativo"** quando o estado é realista: corrida de concorrência, nil em caminho raro-mas-alcançável, zero-falsy tratado como ausente, off-by-one em fronteira não excluída, retry parcial de Sidekiq — isso é PLAUSÍVEL, não refutado.

Probes novos que este passe exigir: **agrupe de novo** — um segundo `rails runner`/heredoc no máximo, não um por candidato.

Vereditos (atualizar **Status:** no ledger, com a evidência na *Tentativa de refutação*):

- **CONFIRMADO** — input/estado que dispara + output errado nomeados, com comando e output (ou linha citada) que prova.
- **REFUTADO** — sai do relatório; vai para *Verificado e descartado* com a prova (refutação tem valor preventivo — impede a próxima rodada de reabrir).
- **PLAUSÍVEL** — mecanismo real, gatilho incerto: anexe o que confirmaria + a checagem manual mais curta.
- **PRÉ-EXISTENTE** — comportamento idêntico na main no mesmo registro; seção própria, candidato a follow-up.

**MEDIUM/LOW de regra citada** não passam por refutação de execução: confira inline que a citação existe e se aplica à linha — sim mantém, não corta.

## Fase 6 — Relatório e comment

**Montagem por referência:** o comment é composto a partir do ledger **sem reescrever o conteúdo técnico** — título, problema, cenário de falha e evidência entram como registrados (parafrasear na síntese introduz erro). Sua edição é seleção, ordenação (correctness antes de cleanup na mesma severidade) e formatação.

Regras de legibilidade (o leitor é humano, escaneando no GitHub):

1. Um finding = um heading `####` numerado, título em linguagem direta.
2. Camada visível curta: localização, problema (2–4 frases), cenário de falha, correção sugerida — alvo ≤10 linhas visíveis.
3. Evidência de verificação SEMPRE em `<details>`.
4. Backtick só em código de verdade; prosa em português corrente.
5. Índice no topo: tabela nº/severidade/título/onde/veredito.
6. *Verificado e descartado* e *Pré-existentes* inteiros em `<details>`; *Gaps de verificação* visível.

Salvar o relatório completo em `./tmp/cr_single_<PR>.md` (path distinto do `./tmp/cr_1_<PR>.md` e `./tmp/cr_2_<PR>.md` de propósito — rodar os dois fluxos no mesmo PR não pode colidir; header com PR/SHA/branch/timestamp/lentes rodadas). Depois postar **UM comment** no PR (`gh pr comment $PR_NUM -R portabilis/i-diario-portabilis --body-file -`, body via heredoc):

```markdown
## 🔍 Code Review agêntico (single) — PR #<PR_NUM>

**Lentes:** <passes rodados> · **Bucket:** <docs-only|trivial|cirúrgico|feature>
**Não rodadas:** <lente — PULA que bateu; …>
**Escopo revisado:** <arquivos/linhas, onde mora a lógica>

### Índice

| # | Sev | Finding | Onde | Veredito |
|---|---|---|---|---|
| 1 | 🚨 | <título curto> | `arquivo:linha` | CONFIRMADO |

### 🚨 CRITICAL (<N>)

#### 1. <Título em linguagem direta — o que quebra, para quem>

[`arquivo:linha`](<link>) · **CONFIRMADO** · lente <cr-*>

<Problema em 2–4 frases, parágrafos curtos.>

**Cenário de falha:** <input/estado concreto → consequência visível>

**Correção sugerida:** <1–2 frases; código só se couber em ≤5 linhas>

<details>
<summary>🔬 Verificação — como foi provado (e a tentativa de refutação)</summary>

<probe: comando + output, comparação main vs branch, linhas citadas>

</details>

### ⚠️ HIGH (<N>) / 📝 MEDIUM (<N>) / 💡 LOW (<N>)

(mesmo formato, numeração contínua; seções vazias saem; em MEDIUM/LOW o
<details> é opcional quando a evidência é citação de regra de 1 linha)

### ⚠️ Gaps de verificação (o revisor humano precisa saber)

- <o que não foi verificado + a checagem manual mais curta>
- <lente cortada pelo teto do bucket, se houve>

<details>
<summary>🔎 Pré-existentes (<N>) — sinalizar, não corrigir neste PR</summary>

- <bug real com comportamento idêntico na main; candidato a follow-up>

</details>

<details>
<summary>🛑 Verificado e descartado (<N>) — NÃO reabrir</summary>

- <hipótese refutada + evidência em 1–2 linhas cada>

</details>

---

### Próximos passos para o autor

1. **Aplicar fixes que fizerem sentido** — revise cada change
2. **Findings que NÃO vai aplicar** — justifique (false positive, fora de escopo, trade-off aceito)
3. **Responda neste PR**: aplicados (commits) / não aplicados (1 linha cada)
4. **Pedir review humano** após resposta

---
<sub>🤖 Gerado por /single-cr (variante agente único) · ver [docs/code-review-agentico.md](https://github.com/portabilis/i-diario-portabilis/blob/main/docs/code-review-agentico.md)</sub>
```

O CI deste repo (`.github/workflows/tests.yml`) roda em todo `pull_request` que não seja draft — **não há label para liberar**. Se o PR estiver em draft, avise no output que a suíte só roda depois de marcá-lo como ready.

**Fechar a fase conferindo branch, SHA e árvore:**

```bash
git status -sb | head -1 && git rev-parse HEAD && git status --porcelain
```

Branch ou SHA diferente do anotado, ou árvore suja (fora de `./tmp/`, que é gitignored): você violou o princípio 1 em algum momento — reverta antes de seguir e registre no relatório.

## Fase 7 — Fix pass (inline, nesta sessão)

**Único ponto do ciclo onde código é alterado.** Só com o comment já postado. Decidir **finding por finding** — não aplicar em bloco, não descartar em bloco:

- **CRITICAL/HIGH:** aplicar, salvo prova de falso positivo. Cada fix ganha (ou reusa) um teste.
- **MEDIUM/LOW:** aplicar quando o custo é baixo e o ganho real. Recusar o que é fora de escopo/especulativo — dizendo por quê.
- Rodar a suíte (`docker compose run --rm ruby bundle exec rspec`, e `npm test` se houver JS no diff) e o linter (`docker compose run --rm ruby bundle exec rubocop <arquivos>`). Commits em português, sem co-autoria: `fix: aplica CR do PR #<PR_NUM> (<resumo>)`. Push na branch do PR — **git roda no host, nunca no container**.
- **Confirme que o push chegou** comparando o head local com `gh pr view <PR_NUM> -R portabilis/i-diario-portabilis --json headRefOid -q .headRefOid` — "Everything up-to-date" também é a resposta de quem está na branch errada.

Responder no PR com **Aplicados** (commits) / **Não aplicados** (justificativa em 1 linha cada) / suíte verde. Review humano segue normal.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

i-Diário is a Brazilian educational management system that replaces physical teacher diaries. It integrates with i-Educar and is maintained by Portabilis. The system manages attendance records, grades, lesson plans, and educational content for Brazilian schools.

## Code Standards

### Language Guidelines
- **Code must always be written in English** (variables, methods, classes, etc.)
- **Comments can be written in Portuguese** when explaining business logic or Brazilian educational regulations
- **Documentation should be in Portuguese** when needed for clarity about educational concepts
- Issues, Pull Requests and Commits should be in Portuguese
- Issues are created in the project issue repository, not in this one, which carries code only; the GitHub MCP reaches them
- To access issues and pull requests, use the GitHub MCP
- Git commands should not be run inside Docker containers
- Commits should not have co-authorship
- Unit tests (RSpec, Jest) should be written in English (it, describe, context, etc) - only comments in Portuguese
- E2E tests (Playwright) should be written in Portuguese for readability by the whole team

### Comentários e Documentação (High)

**Comentário e doc descrevem o que o código faz hoje e as restrições que ele não consegue mostrar — não a mudança que os criou.** Quem quiser o histórico usa `git blame`, o commit e a PR; quem lê o código quer entender o estado atual. Narrativa de mudança envelhece mal: vira mentira na refatoração seguinte e ninguém percebe.

**Não escrever:**
- "Antes fazia X, agora faz Y" / "passou a" / "deixou de" / "virou"
- Referência ao que motivou a mudança: citar issue, PR, code review ou impeditivo de QA dentro do comentário
- Medição pontual da investigação: as contagens de registros levantadas durante a análise
- Registro real usado para depurar: ID de diário, turma, aluno, professor ou entidade que apareceu na investigação
- Comentário que narra a linha seguinte: `# incrementa o contador`

**Escrever:**
- Armadilha do schema ou da lib: `# Entity.connect não aceita bloco — ele troca a conexão e ignora o bloco; usar using_connection para escopo delimitado`
- Regra de negócio e sua origem normativa: `# LDB: carga horária mínima de 800 horas letivas anuais`
- Invariante que precisa ser mantido: `# as etapas do calendário da turma prevalecem sobre as do calendário da unidade`
- Restrição real que o código não expressa: `# a coluna aceita NULL quando o vínculo não tem turno, então a comparação precisa tratar o NULL explicitamente`

**Vale igual para RSpec, Jest, E2E e `/docs`.** Em `/docs`, documentar a decisão e a regra vigente; se o histórico for indispensável para entender a decisão, uma linha `> *Histórico:*` basta — não um changelog.

**No code review:** comentário histórico deve ser sinalizado e removido antes do merge.

**Este repositório é público.** Comentário, doc, spec e mensagem de commit não podem conter nome de cliente, nome de entidade, número de issue interna, link de sistema interno ou dado de pessoa real.

### Key Services
- **puma**: Rails application (port 3000)
- **postgres**: PostgreSQL 16 database
- **redis**: Cache and job queue (port 6379)
- **sidekiq**: Background job processor

## Common Commands

### Testing
```bash
# Run all tests (excluding acceptance)
docker-compose run ruby bundle exec rspec --exclude-pattern 'spec/acceptance/*.feature'

# Run specific test file
docker-compose run ruby bundle exec rspec spec/models/student_spec.rb

# Run test at specific line
docker-compose run ruby bundle exec rspec spec/models/student_spec.rb:42

# Run tests in a directory
docker-compose run ruby bundle exec rspec spec/controllers/

# Run linter
docker-compose run ruby bundle exec rubocop

# Run linter with auto-fix
docker-compose run ruby bundle exec rubocop -a

# Run JavaScript unit tests (Jest)
npm test

# Run E2E tests (Playwright) — requires app running and credentials configured
env $(cat .env.e2e | xargs) npm run test:e2e

# Run E2E tests with visual UI
env $(cat .env.e2e | xargs) npm run test:e2e:ui
```

### Development
```bash
# Start application
docker-compose up

# Rails console
docker-compose exec puma bundle exec rails console

# Database migrations
docker-compose exec puma bundle exec rails db:migrate

# View logs
docker-compose exec puma tail -f log/development.log
docker-compose logs -f sidekiq

# Access container bash
docker-compose exec puma bash

# List all rake tasks
docker-compose exec puma bundle exec rake -T
```

### Worktrees (sessões paralelas)
- `claude --worktree <nome>` isola sessões em git worktrees (cada uma na própria branch/diretório, em `.claude/worktrees/<nome>/`)
- Arquivos de config gitignored (`.env`, `config/secrets.yml`, `config/database.yml`, etc.) são copiados automaticamente para cada worktree via `.worktreeinclude` — não copiar manual
- Para subir a aplicação de um worktree com Docker, rode `docker compose -p <nome-do-projeto> up` **de dentro do diretório do worktree**, forçando o mesmo nome de projeto Compose do checkout principal — senão o Compose sobe um ambiente separado (banco/volumes vazios)
- Ver [docs/worktrees.md](docs/worktrees.md)

## Architecture

### Directory Structure
- `/app/models/` - ActiveRecord models with domain entities
- `/app/controllers/` - Request handling, uses Pundit for authorization
- `/app/services/` - Service objects for complex business operations
- `/app/workers/` - Sidekiq background jobs
- `/app/forms/` - Form Objects for complex validations
- `/app/queries/` - Encapsulated database queries
- `/app/policies/` - Authorization rules using Pundit
- `/app/decorators/` - Presentation logic
- `/app/reports/` - Report generation classes
- `/app/uploaders/` - File upload handlers
- `/app/enumerations/` - EnumerateIt enumerations — padrão do projeto para valores enumerados e suas traduções; valor novo entra aqui, não como string solta
- `/app/validators/` - Custom ActiveModel validators
- `/app/presenters/` - Presentation objects (complementam os decorators)
- `/app/serializers/` - API response formatting
- `/app/inputs/` - Custom SimpleForm inputs (select2 e afins)
- `/app/seeders/` - Data seeders
- `/app/helpers/` - View helpers
- `/app/mailers/` - Email delivery
- `/app/assets/` - Frontend assets (JS, CSS, images)

### Key Technologies
- **Ruby 2.6.6** with **Rails 5.0.7.2**
- **PostgreSQL 16** with structure.sql (not schema.rb)
- **Sidekiq** for background processing
- **Redis 7** for caching and job queues
- **RSpec** for testing with FactoryBot
- **Vue.js 2.6** for modern frontend components
- **Bootstrap 3** for UI framework
- **jQuery** and **Backbone.js** (legacy frontend)
- **Docker Compose** for development environment

### Restrições da stack (Ruby 2.6.6 / Rails 5.0.7.2)

A stack é antiga: sintaxe e API modernas de Ruby/Rails **não rodam aqui**. Antes de usar um recurso recente, conferir a versão em que ele entrou.

**Ruby 2.6 não tem:**
- `filter_map`, `tally`, parâmetros numerados (`_1`, `_2`), pattern matching (`case/in`), argument forwarding (`...`) — todos Ruby 2.7
- Endless method (`def valor = 42`) — Ruby 3.0
- Shorthand de hash (`{ classroom:, teacher: }`) — Ruby 3.1
- `Data.define` — Ruby 3.2
- Disponíveis e válidos: `&.`, `then`/`yield_self`, `Array#difference`/`#union`, `Hash#transform_keys`

**Rails 5.0 não tem:**
- `insert_all` / `upsert_all` / `pick` — Rails 6.0
- `where.missing` — Rails 6.1
- `delegate_missing_to` — Rails 5.1
- **Autoloader clássico, não Zeitwerk:** o nome do arquivo precisa casar com a constante, e `require` de código de `app/` quebra o reload — usar só o autoload
- Migration nova nasce com `ActiveRecord::Migration[5.0]`

**Rubocop** (`.rubocop.yml`): `TargetRubyVersion: 2.6`, aspas simples (`Style/StringLiterals`), linha de até 120 caracteres, `Metrics/BlockLength` máx. 25. Escrever já nesse estilo evita uma rodada de correção do linter.

### Important Patterns
1. Service objects in `/app/services/` handle complex business operations
2. Query objects in `/app/queries/` encapsulate complex database queries
3. Background jobs use Sidekiq workers in `/app/workers/`
4. Form Objects pattern for complex form validations
5. Multi-tenancy with Entity-based database connections
6. Authorization with Pundit policies

### Sincronização com i-Educar (High)

**⚠️ Ao criar ou alterar synchronizer, worker de sincronização ou qualquer consumo da API do i-Educar, ler [docs/sistema-de-sincronizacao.md](docs/sistema-de-sincronizacao.md).**

- A ordem de sincronização é dirigida por dependências declaradas em `config/synchronization_configs.yml` — entidade nova entra lá com as dependências corretas, não como chamada solta no worker
- Tabela gravada por synchronizer pertence ao i-Educar: edição manual nela é sobrescrita no próximo sync. Synchronizer que passa a gravar uma tabela editável pela tela precisa dizer no PR o que passa a ser sobrescrito
- Worker de sincronização tem retry automático (`sidekiq_options retry: 3`) — a operação precisa ser idempotente, senão o retry duplica registro
- O worker é único por argumentos (`unique: :until_and_while_executing`, `on_conflict: { server: :reject }`): uma segunda sincronização enfileirada para a mesma entidade enquanto outra roda é **rejeitada em silêncio**, sem erro e sem registro. "Disparei e não rodou" costuma ser isso, não falha do sync
- Validação que falha durante o sync pula o registro e segue: a tela fica sem o dado e nada estoura. Não confiar em ausência de erro como prova de que sincronizou

### Permissões (Features, Roles e Pundit) (High)

**⚠️ Ao criar tela nova, feature nova ou alterar policy, ler [docs/sistema-de-permissoes.md](docs/sistema-de-permissoes.md).**

- Feature nova exige as três pontas: valor em `app/enumerations/features.rb`, tradução em `config/locales/navigation.yml` e cobertura por policy — faltando a tradução, a tela de papéis mostra o nome sem tradução
- A `ApplicationPolicy` já cobre o caso padrão (`can_show?`/`can_change?`); policy específica só quando a regra foge disso
- A precedência é admin → permissões específicas do usuário → permissões do papel. Regra nova precisa ser pensada nas três camadas, não só no papel
- Feature especial (acesso a ano letivo encerrado, sincronização completa, envio sem restrição de data) contorna trava de negócio — ampliar o alcance de uma delas é mudança de segurança, não de conveniência

### Code Review Rules (used by agentic CR pipeline)

Regras explícitas que os agentes de code review devem aplicar. Mudanças que violem essas regras devem ser sinalizadas como **Critical** ou **High**.

#### Multi-tenant safety (Critical)
- Cada Entity (rede educacional) tem o próprio banco — operações sempre devem rodar no contexto da Entity correta (`Entity.current` / `current_entity`)
- Nunca usar `Model.find` ou `Model.where` em controllers/services sem garantir que estão no escopo da Entity ativa
- Jobs em Sidekiq devem propagar a Entity corrente (`Entity.using(...)` ou padrão equivalente já estabelecido no projeto)
- Operações cross-entity (rakes administrativos, jobs globais) devem ser explícitas e justificadas em comment

#### Authorization (Pundit) (Critical)
- Toda action de controller deve passar por uma policy Pundit (`authorize @record` ou `policy_scope(Model)`)
- Não confiar em `params` sem strong parameters
- `skip_before_action :authenticate_user!` (Devise) precisa de justificativa explícita
- Nunca retornar dados de outra Entity através de associações ou IDs adivinháveis

#### Escrita de código (High)
- Seguir a convenção da tecnologia e do código vizinho: Ruby idiomático (Rails way), JS idiomático, SQL idiomático
- Antes de implementar, procurar helper/concern/query object/partial equivalente no repo — duplicação de comportamento já existente deve ser sinalizada
- Sem abstração especulativa: interface com uma implementação, factory de um produto, config para valor que nunca muda ou parâmetro sem chamador atual devem ser removidos
- Extrair service/concern/partial quando há reuso real ou a unidade excede o limiar de tamanho abaixo — não por simetria com código vizinho
- Método com mais de uma responsabilidade deve ser quebrado; classe/arquivo que a mudança cria ou faz ultrapassar ~500 linhas deve ser sinalizado — a regra vale para o código da mudança, não para os arquivos grandes que já existem
- Argumentos nomeados (keyword args) a partir de 4 parâmetros, no lugar de posicionais ou hash de opções genérico
- Booleano posicional que alterna comportamento (`calculate(true)`) deve virar dois métodos
- Máximo dois níveis de aninhamento — usar guard clause e early return
- Cliente externo (`IeducarApi::*`, mailer, uploader) instanciado em **um único ponto** da classe — construtor ou método privado memoizado — e nunca repetido dentro dos métodos de negócio. É o que permite stubar a borda no spec (`allow(IeducarApi::Students).to receive(:new)`) e trocar a implementação num lugar só. O projeto não usa injeção por parâmetro; não exigir
- Nomes com qualificador de domínio (`frequency_date`, não `date`; `IeducarExamPoster`, não `Manager`) — o identificador precisa ser buscável por `grep`
- Diff restrito ao pedido: não reformatar código adjacente nem refatorar o que a mudança não toca
- Código morto tem dois tratamentos: o que **a própria mudança tornou obsoleto** (método que perdeu o último chamador, chave i18n que ficou sem uso, constante substituída) se remove na mesma alteração; o que **já estava morto antes** e a mudança apenas passou perto se sinaliza no PR e fica para uma alteração própria — deletá-lo aqui mistura assuntos e esconde o fix no meio da limpeza

#### Service objects vs controllers (High)
- Lógica de negócio complexa (>20 linhas ou múltiplas responsabilidades) deve estar em `/app/services/`, não em controllers
- Controllers devem ser finos: parse de params, autorização, chamada de service, render de response
- Models não devem conter lógica que orquestra múltiplos models — isso é responsabilidade de service
- Queries complexas devem ir para `/app/queries/`, não inline no controller

#### Background jobs (High)
- Operações I/O-bound que demorem >2s (envio de email, processamento de arquivo, integração com i-Educar, geração de relatório) devem ir para Sidekiq workers em `/app/workers/`
- Nunca bloquear request HTTP com operação demorada
- Jobs devem ser idempotentes sempre que possível (Sidekiq pode fazer retry)

#### Database migrations (Critical)
- Usa `structure.sql` (não `schema.rb`), porém `db/structure.sql` está no `.gitignore` e não é versionado — cada ambiente gera o seu ao rodar as migrations. Portanto, migration sem `db/structure.sql` no diff é o esperado e não deve ser apontada
- `add_column` com `NOT NULL` em tabela existente: usar default ou backfill em migration separada
- `add_index` em tabela grande: usar `algorithm: :concurrently` e `disable_ddl_transaction!`
- `remove_column` sempre em duas releases (ignorar no Rails primeiro com `ignored_columns`, depois remover)
- Migrations devem ter rollback testável (`down` method ou `reversible`)
- Migrações precisam ser compatíveis com o modelo multi-tenant (rodam por Entity)

#### Performance (High)
- Nada de N+1: usar `includes`, `preload`, `eager_load` em loops sobre AR collections
- Queries CRUD em loops Ruby (`.each { |x| Model.update(...) }`) devem ser substituídas por bulk operations (`pluck`, `update_all`, `delete_all`)
- **Rails 5.0 não tem `insert_all`/`upsert_all`** (chegaram no Rails 6.0) e não há gem de import em massa no Gemfile. O projeto não tem padrão estabelecido para insert em massa: as opções são SQL direto via `ActiveRecord::Base.connection.execute` ou avaliar a adoção de `activerecord-import`
- **Exceção:** para apenas iterar coleções grandes (>1000 records) sem CRUD em loop, usar `find_each` em vez de `each` (batching otimizado)
- Adicionar índice para colunas usadas em `WHERE`/`JOIN`/`ORDER BY` em tabelas grandes (matrículas, frequências, notas)

#### Error handling (High)
- Proibido `rescue => e` vazio ou apenas com log (silent failure)
- `rescue` deve capturar exceções específicas, não `StandardError` genérico
- Usar `Rails.logger.error` (ou equivalente) com contexto suficiente (IDs, parâmetros relevantes)
- Não usar `rescue nil` ou `rescue` para silenciar erros esperados — tratar explicitamente
- Honeybadger é o tracker oficial — exceções não silenciadas devem chegar lá com contexto

#### Auditoria de dados sensíveis (Medium)
- Mudanças em models com tracking de auditoria (Audited gem) devem manter `audited` ativo
- Operações em massa (`update_columns`, `update_all`, `delete_all`) pulam validations/callbacks/audit — usar apenas quando justificado e documentado em comment

#### Testing (High)
- Toda lógica nova em service/model/query precisa de teste RSpec
- Tests devem usar FactoryBot, não fixtures
- Não usar `save(validate: false)` em testes para "fazer passar" — corrigir o setup
- Testes JavaScript críticos com Jest (`spec/javascript/`)
- E2E (Playwright em `spec/e2e/`) só para fluxos críticos de usuário, em pt-BR

#### Comentário histórico (Medium)
- Comentário que narra a mudança em vez do estado atual ("antes fazia X, agora faz Y", referência a issue/PR/code review, contagens da investigação, ID usado para depurar) deve ser sinalizado — o histórico vive no blame e no commit
- Informação privada em código, comentário, spec ou commit (cliente, entidade, issue interna, link interno) deve ser sinalizada como **Critical** — o repositório é público
- Ver [Comentários e Documentação](#comentários-e-documentação-high) para o que fica e o que sai

#### Relatórios HTML → PDF (High)

**⚠️ Ao criar ou alterar relatório que gere PDF a partir de HTML (`ReportGenerator`), ler [docs/relatorios-html-plutobook.md](docs/relatorios-html-plutobook.md).**

- Relatório novo nasce no driver `pluto` (PlutoBook) com o layout `report_pluto` — `chrome` é o default do service e só serve aos ainda não migrados (hoje só o PEI)
- Numeração de página e margens vivem no CSS `@page` do layout, não em parâmetro da requisição
- Não repetir `thead` entre páginas no pluto: ele ignora regras de quebra em linha de tabela e desenha o cabeçalho duas vezes quando a tabela começa em página nova. Linhas que precisam sair juntas vão numa única célula
- O cabeçalho é do layout: título do relatório (via `content_for :report_title`), brasão, entidade e órgão — só isso, como nos demais relatórios. Relatório que repita esses dados na própria view sai com o bloco duplicado no PDF
- Estilo próprio do relatório vai em `content_for :head`, que o layout injeta depois do CSS base
- O pluto não encolhe a página para caber; elemento mais largo que a área útil (190mm) vaza para fora do papel — os layouts legados declaram `width: 210mm`, que é a folha inteira
- O pluto não converte JPEG CMYK: o brasão chega a ele como PNG sRGB pela versão `pdf` do `EntityLogoUploader`, mas brasão gravado antes dessa versão existir sai com os bytes originais até passar pelo `rake entity_logo:optimize`
- O gzip do corpo é automático no `ReportGenerator` acima de 1 MB — é o que evita 413/502 em relatório grande; header e corpo comprimido são obrigatórios juntos (um sem o outro devolve 400)
- Migração de layout deve ser validada com PDF gerado de dados reais, não só com o HTML — e conferindo a **segunda** página, não só a primeira: cabeçalho, folgas e quebra se comportam diferente a partir dela

### Database Notes
- Uses `structure.sql` instead of `schema.rb` — `db/structure.sql` is gitignored (not versioned); generated locally per environment
- Multi-tenant architecture with Entity-specific databases
- Extensive use of PostgreSQL features
- Database-level constraints and validations
- Each Entity (educational network) has its own database connection

### Testing Approach
- RSpec with FactoryBot for test data
- SimpleCov for code coverage
- DatabaseCleaner for test isolation
- Tests organized by type: models, controllers, services, queries, etc.
- Acceptance tests in `/spec/acceptance/` (usually excluded)
- **Jest** with jsdom for JavaScript unit tests (`spec/javascript/`)
- **Playwright** for E2E browser tests (`spec/e2e/`) — see [docs/testes-e2e.md](docs/testes-e2e.md)
- **Spec verde isolado não prova que a suíte está verde.** Em `spec/support/database_cleaner.rb` a limpeza está atrelada a tipos declarados (`:model`, `:form`, `:service`, `:controller`, `:query`, `:worker`), e o `infer_spec_type_from_file_location!` do RSpec só infere os tipos padrão do Rails — `:service`, `:form`, `:query` e `:worker` são customizados e precisam ser declarados à mão. Spec em `spec/services/` sem `type: :service` roda sem limpeza e vaza registro para os exemplos seguintes: passa sozinho e quebra junto com os outros
- Spec novo em `spec/services/`, `spec/forms/`, `spec/queries/` ou `spec/workers/` **deve declarar o `type:`** — sem isso ele entra para o conjunto que suja o banco
- A conexão do tenant (`entity.using_connection`, e toda request de spec de controller) entra na transação do exemplo porque `spec/support/tenant_fixture_connections.rb` materializa o pool de cada Entity antes do `enlist` dos fixtures e, para a Entity criada durante o exemplo, assina a criação do pool e entra com a conexão nova na mesma transação
- Por isso, o resultado de um arquivo isolado se reporta como tal ("spec do arquivo verde, suíte não rodou"), nunca como "testes passando". A suíte completa é o que vale antes do push, e leva ~12 minutos:
  `docker compose run --rm ruby bundle exec rspec --exclude-pattern 'spec/acceptance/*.feature'`
- Um único banco de teste é compartilhado por todos os checkouts/worktrees — dois runs simultâneos travam um ao outro

## Code Review Workflow

**⚠️ RECOMENDADO: Todo PR deve passar pelo fluxo de code review agêntico ANTES de pedir review humano.**

Três comandos em sequência (instâncias Claude limpas, paralelizável entre 1 e 2):

1. `/cr-1 <PR>` → `./tmp/cr_1_<PR>.md`
2. `/cr-2 <PR>` → `./tmp/cr_2_<PR>.md`
3. `/cr-consolidate <PR>` → comment consolidado no PR

Dev aplica fixes manualmente (com awareness), justifica os que não vai aplicar, responde no PR com resumo. Review humano segue normal.

**Detalhes, severidades, troubleshooting:** [docs/code-review-agentico.md](docs/code-review-agentico.md)

## Important Notes

1. Always use Docker for all commands
2. Heavy operations should use Sidekiq workers
3. Database queries should be optimized (avoid N+1)
4. Follow existing code patterns in the codebase

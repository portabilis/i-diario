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
- Issues should be created in the GitHub repository portabilis/board
- To access issues and pull requests, use the GitHub MCP
- Git commands should not be run inside Docker containers
- Commits should not have co-authorship
- Unit tests (RSpec, Jest) should be written in English (it, describe, context, etc) - only comments in Portuguese
- E2E tests (Playwright) should be written in Portuguese for readability by the whole team

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

### Important Patterns
1. Service objects in `/app/services/` handle complex business operations
2. Query objects in `/app/queries/` encapsulate complex database queries
3. Background jobs use Sidekiq workers in `/app/workers/`
4. Form Objects pattern for complex form validations
5. Multi-tenancy with Entity-based database connections
6. Authorization with Pundit policies

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
- Usa `structure.sql` (não `schema.rb`) — confirmar que `db/structure.sql` foi commitado junto da migration
- `add_column` com `NOT NULL` em tabela existente: usar default ou backfill em migration separada
- `add_index` em tabela grande: usar `algorithm: :concurrently` e `disable_ddl_transaction!`
- `remove_column` sempre em duas releases (ignorar no Rails primeiro com `ignored_columns`, depois remover)
- Migrations devem ter rollback testável (`down` method ou `reversible`)
- Migrações precisam ser compatíveis com o modelo multi-tenant (rodam por Entity)

#### Performance (High)
- Nada de N+1: usar `includes`, `preload`, `eager_load` em loops sobre AR collections
- Queries CRUD em loops Ruby (`.each { |x| Model.update(...) }`) devem ser substituídas por bulk operations (`pluck`, `update_all`, `insert_all`)
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

### Database Notes
- Uses `structure.sql` instead of `schema.rb`
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

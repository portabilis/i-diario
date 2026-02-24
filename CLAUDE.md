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

## Important Notes

1. Always use Docker for all commands
2. Heavy operations should use Sidekiq workers
3. Database queries should be optimized (avoid N+1)
4. Follow existing code patterns in the codebase

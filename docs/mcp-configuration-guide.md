# Guia de Configuração dos MCP Servers

Este guia explica como configurar os MCP (Model Context Protocol) servers recomendados para o projeto i-Diário.

## O que são MCP Servers?

MCP Servers são ferramentas que estendem as capacidades do Claude Code, permitindo integração com serviços externos, análise avançada e operações especializadas.

## MCP Servers Recomendados

### 1. GitHub MCP Server

#### Para que serve
- Gerenciar issues, pull requests e código no GitHub
- Automatizar workflows de desenvolvimento
- Buscar código em repositórios
- Revisar e comentar em PRs
- Criar branches e commits

#### Instalação
```bash
claude mcp add-json github '{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "ghcr.io/github/github-mcp-server"
  ],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "{seu_token_aqui}"
  }
}'
```

#### Como obter o token
1. Acesse https://github.com/settings/tokens
2. Clique em "Generate new token" → "Generate new token (classic)"
3. Nome do token: "Claude Code MCP i-Diário"
4. Selecione os scopes necessários:
   - `repo` (acesso completo aos repositórios)
   - `workflow` (atualizar GitHub Actions)
   - `write:discussion` (criar discussões)
   - `read:org` (ler dados da organização)
5. Clique em "Generate token"
6. Copie o token e substitua `{seu_token_aqui}` no comando

#### Casos de uso no i-Diário
- Criar issues no repositório portabilis/board
- Buscar e revisar pull requests
- Analisar código em outros repositórios da organização
- Automatizar criação de branches para novas features
- Verificar status de PRs e issues

---

### 2. PostgreSQL MCP Server (para i-Diário)

#### Para que serve
- Executar queries SQL diretamente
- Analisar estrutura do banco de dados
- Verificar índices e performance
- Gerenciar migrações e schemas
- Debugar problemas de dados
- Analisar multi-tenancy das entidades

#### Instalação
```bash
claude mcp add-json postgresql-idiario '{
  "command": "npx",
  "args": [
    "@henkey/postgres-mcp-server",
    "--connection-string", "postgresql://postgres@localhost/idiario_development"
  ]
}'
```

#### Configuração
1. Ajuste a connection string conforme seu ambiente:
   - Para Docker: `postgresql://postgres@localhost/idiario_development`
   - Certifique-se de que o PostgreSQL está acessível na porta 5432
2. Verifique as credenciais no arquivo `config/database.yml`
3. Para ambientes multi-tenant, configure cada entity conforme necessário

#### Casos de uso no i-Diário
- Analisar queries lentas de sincronização com i-Educar
- Verificar índices nas tabelas de frequência e notas
- Executar queries de análise de dados educacionais
- Debugar problemas de constraints em períodos letivos
- Auditar dados de múltiplas entidades
- Verificar integridade de dados após migrações

---

### 3. Honeybadger MCP Server

#### Para que serve
- Monitorar erros e exceções em produção
- Analisar falhas e bugs reportados
- Acessar logs de erro detalhados
- Gerenciar alertas e notificações
- Rastrear tendências de erros no i-Diário

#### Instalação
```bash
claude mcp add-json honeybadger '{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "HONEYBADGER_PERSONAL_AUTH_TOKEN",
    "ghcr.io/honeybadger-io/honeybadger-mcp-server"
  ],
  "env": {
    "HONEYBADGER_PERSONAL_AUTH_TOKEN": "{seu_token_aqui}"
  }
}'
```

#### Como obter o token
1. Acesse https://app.honeybadger.io
2. Faça login com sua conta da Portábilis
3. Vá para Settings → My Account → API Authentication
4. Clique em "Create Auth Token"
5. Nome do token: "Claude Code MCP i-Diário"
6. Copie o token e substitua `{seu_token_aqui}` no comando

#### Casos de uso no i-Diário
- Investigar erros de sincronização com i-Educar
- Analisar stack traces de exceções em produção
- Identificar problemas recorrentes em operações batch
- Monitorar erros de validação de dados educacionais
- Priorizar correções baseadas em frequência de erros

---

### 4. Context7 MCP Server

#### Para que serve
- Acessar documentação oficial de bibliotecas e frameworks
- Buscar exemplos de código e best practices
- Obter informações atualizadas sobre APIs
- Consultar guias de migração e atualizações

#### Instalação
```bash
claude mcp add context7 -s user -- npx -y @upstash/context7-mcp
```

#### Como obter o token
**Não requer token!** Este MCP é gratuito e público.

#### Casos de uso no i-Diário
- Consultar documentação do Rails 5.0
- Buscar padrões de ActiveRecord
- Verificar APIs do Sidekiq
- Encontrar exemplos de Pundit para autorização
- Consultar documentação do Vue.js 2.6
- Buscar exemplos de integração Bootstrap 3

---

### 5. Sequential Thinking MCP Server

#### Para que serve
- Análise complexa passo a passo
- Resolução estruturada de problemas
- Debugging sistemático
- Planejamento de arquitetura
- Análise de causa raiz

#### Instalação
```bash
claude mcp add-json sequential-thinking '{
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-sequential-thinking"
  ]
}'
```

#### Como obter o token
**Não requer token!** Este MCP é open source e gratuito.

#### Casos de uso no i-Diário
- Debugar problemas complexos de sincronização com i-Educar
- Planejar refatorações de módulos educacionais
- Analisar arquitetura multi-tenant
- Investigar problemas de performance em relatórios
- Estruturar implementações de novas funcionalidades
- Analisar fluxos complexos de validação de dados

---

## Verificando MCPs Instalados

Para listar todos os MCPs configurados:
```bash
claude mcp list
```

Para remover um MCP:
```bash
claude mcp remove {nome_do_mcp}
```

## Troubleshooting

### MCP não está funcionando
1. Verifique se o Docker está rodando (para MCPs que usam Docker)
2. Confirme que os tokens estão corretos
3. Reinicie a sessão do Claude Code
4. Execute `claude mcp list` para verificar se está instalado

### Erro de autenticação
1. Regenere o token no serviço correspondente
2. Atualize o MCP com o novo token:
   ```bash
   claude mcp remove {nome}
   claude mcp add-json {nome} '{...configuração com novo token...}'
   ```

### MCP PostgreSQL não conecta
1. Verifique se o PostgreSQL está rodando:
   ```bash
   docker-compose ps postgres
   ```
2. Confirme o nome do banco de dados:
   ```bash
   docker-compose exec postgres psql -U postgres -l
   ```
3. Teste a conexão diretamente:
   ```bash
   docker-compose exec postgres psql -U postgres -d idiario_development -c "SELECT version();"
   ```
4. Ajuste a connection string no comando de instalação

### MCP GitHub com problemas
1. Verifique os scopes do token
2. Confirme que o token não expirou
3. Teste o token com curl:
   ```bash
   curl -H "Authorization: token SEU_TOKEN" https://api.github.com/user
   ```

## Prioridade de Instalação

1. **Essencial**: GitHub MCP (gestão de código e issues)
2. **Essencial**: PostgreSQL MCP (análise de dados e debugging)
3. **Muito Útil**: Sequential Thinking (debugging complexo)
4. **Recomendado**: Context7 (documentação de frameworks)
5. **Útil**: Honeybadger (se você tem acesso aos erros de produção)

## Segurança

- **Nunca commite tokens** em arquivos do projeto
- **Use variáveis de ambiente** quando possível
- **Revogue tokens** que não estão mais em uso
- **Limite os scopes** dos tokens ao mínimo necessário
- **Rotacione tokens** periodicamente (a cada 3-6 meses)
- **Mantenha tokens separados** por projeto quando possível

## Casos de Uso Específicos do i-Diário

### Análise de Performance
Combine PostgreSQL MCP + Sequential Thinking para:
- Identificar queries lentas na sincronização
- Analisar índices faltantes
- Otimizar consultas de relatórios

### Debugging de Erros
Combine Honeybadger MCP + GitHub MCP para:
- Rastrear erro em produção
- Buscar código relacionado
- Criar issue automaticamente

### Implementação de Features
Combine Context7 + GitHub MCP para:
- Consultar documentação de frameworks
- Criar branch para feature
- Implementar seguindo best practices

### Análise de Multi-tenancy
Use PostgreSQL MCP para:
- Verificar isolamento entre entities
- Analisar dados por escola/rede
- Validar integridade cross-tenant
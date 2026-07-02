# Guia de Configuração do Claude

Este guia explica como configurar adequadamente o Claude Code para o projeto i-Diário usando os arquivos CLAUDE.md e CLAUDE.local.md.

## Visão Geral

O projeto i-Diário utiliza dois arquivos de configuração para o Claude Code:

1. **CLAUDE.md** - Configurações do projeto (versionado no git)
2. **CLAUDE.local.md** - Configurações pessoais/locais (ignorado pelo git)

## CLAUDE.md (Configuração do Projeto)

### Propósito
Contém padrões, convenções e diretrizes do projeto que se aplicam a todos os desenvolvedores.

### Quando Editar o CLAUDE.md
Edite este arquivo quando precisar adicionar ou atualizar:
- Documentação da arquitetura do projeto
- Padrões e convenções de código
- Processos de desenvolvimento da equipe
- Comandos e fluxos de trabalho comuns
- Informações sobre a stack tecnológica
- Explicações da estrutura de diretórios
- Abordagens de teste
- Procedimentos de deploy

### O que NÃO Incluir no CLAUDE.md
- Configurações de ambiente pessoal
- Nomes de bancos de dados locais
- Configurações específicas da máquina
- Preferências individuais do desenvolvedor
- Caminhos locais ou credenciais

## CLAUDE.local.md (Configuração Pessoal)

### Propósito
Contém configurações específicas do desenvolvedor e do ambiente que NÃO devem ser commitadas no controle de versão.

### Quando Criar/Editar o CLAUDE.local.md
Crie ou edite este arquivo para:
- Configurações de banco de dados local
- Configurações do ambiente de desenvolvimento pessoal
- Informações específicas da máquina
- Caminhos de arquivos locais
- Preferências pessoais do Claude
- Variáveis específicas do ambiente

### Template Básico do CLAUDE.local.md

Todo desenvolvedor deve criar seu próprio arquivo `CLAUDE.local.md` com pelo menos as seguintes informações:

```markdown
## General Claude Configs:

- current_dev_database_name: [YOUR_DATABASE_NAME]
- project running locally or via docker: docker
- environment: [YOUR_MACHINE_INFO]
- honeybadger_project_id: 54397
- github_issue_repo: https://github.com/portabilis/board/
```

### Exemplo de CLAUDE.local.md para i-Diário

```markdown
## General Claude Configs:

- current_dev_database_name: idiario_development
- project running locally or via docker: docker
- environment: macbook pro M1, mac os 15.5
- honeybadger_project_id: 54397
- github_issue_repo: https://github.com/portabilis/board/

## Configurações Específicas do i-Diário:

- entity_name: demo_entity
- school_year: 2025
- i_educar_api_url: http://localhost:8080
```

## Instruções de Configuração para Novos Desenvolvedores

1. **Clone o repositório** - O CLAUDE.md já estará presente

2. **Crie seu arquivo CLAUDE.local.md** na raiz do projeto:
   ```bash
   touch CLAUDE.local.md
   ```

3. **Copie o template acima** e preencha com seus valores específicos:
   - Substitua `[YOUR_DATABASE_NAME]` pelo nome do seu banco de dados local (geralmente `idiario_development`)
   - Mantenha `docker` como configuração padrão para o i-Diário
   - Substitua `[YOUR_MACHINE_INFO]` pelos detalhes do seu sistema

4. **Configure as variáveis específicas do i-Diário**:
   - `entity_name`: Nome da entidade para testes locais
   - `school_year`: Ano letivo atual
   - `i_educar_api_url`: URL da API do i-Educar local

## Melhores Práticas

### Para o CLAUDE.md
- Mantenha informações gerais e aplicáveis a todos os membros da equipe
- Documente convenções com exemplos claros
- Atualize quando os processos da equipe mudarem
- Revise em pull requests como qualquer outro código

### Para o CLAUDE.local.md
- Nunca commite este arquivo
- Mantenha-o atualizado com seu ambiente atual
- Inclua instruções ou preferências pessoais do Claude
- Documente workarounds locais ou configurações temporárias

## Árvore de Decisão: Qual Arquivo Atualizar?

```
A informação é...
├── Específica da sua máquina/ambiente?
│   └── → CLAUDE.local.md
├── Um padrão ou convenção da equipe?
│   └── → CLAUDE.md
├── Um nome de banco de dados ou caminho local?
│   └── → CLAUDE.local.md
├── Arquitetura do projeto ou stack tecnológica?
│   └── → CLAUDE.md
└── Preferências pessoais do Claude?
    └── → CLAUDE.local.md
```

## Resolução de Problemas

### Claude não reconhece configurações locais
- Certifique-se de que o CLAUDE.local.md está na raiz do projeto
- Verifique se as permissões do arquivo permitem leitura
- Reinicie a sessão do Claude Code

### Commitou o CLAUDE.local.md acidentalmente
```bash
git rm --cached CLAUDE.local.md
git commit -m "Remove CLAUDE.local.md do tracking"
```

### Comandos de Docker não funcionam
- Verifique se o Docker está rodando: `docker ps`
- Confirme que os containers estão up: `docker-compose ps`
- Verifique os logs: `docker-compose logs`

### Banco de dados não conecta
- Verifique se `current_dev_database_name` no CLAUDE.local.md corresponde ao seu banco de dados real
- Confirme que o container do PostgreSQL está rodando: `docker-compose ps postgres`
- Teste a conexão: `docker-compose exec postgres psql -U postgres -l`

## Recursos Adicionais

- [CLAUDE.md](../CLAUDE.md) - Configuração atual do projeto
- [.gitignore](../.gitignore) - Verifique se CLAUDE.local.md está listado
- [Guia de MCPs](mcp-configuration-guide.md) - Configuração dos MCP Servers recomendados
- [Wiki do i-Diário](https://github.com/portabilis/i-diario/wiki) - Documentação completa do projeto
---
description: Gera roteiros de teste E2E e constrói testes Playwright navegando pelas telas do i-Diário. Aceita URL de issue, descrição livre, ou nome de feature como argumento.
---

# E2E Test — Roteiro + Testes Playwright Assistidos por IA (i-Diário)

Comando que analisa uma feature do i-Diário, gera um roteiro de teste E2E funcional, navega pelas telas da aplicação em par com o usuário, e escreve testes Playwright seguindo as convenções do projeto.

> Convenções de referência: [docs/testes-e2e.md](../../docs/testes-e2e.md) e exemplo em [spec/e2e/command_palette.spec.js](../../spec/e2e/command_palette.spec.js).

## Input

```
$ARGUMENTS
```

Aceita:
- URL de issue: `https://github.com/<owner>/<repo>/issues/<numero>`
- Descrição livre: `"testar o lançamento de notas do diário de avaliações"`

---

## Fase 1 — Análise da Feature

### Objetivo
Entender profundamente a feature antes de escrever qualquer roteiro.

### Passos

1. **Identificar a feature:**
   - Se for URL de issue: buscar com `gh issue view <url>` (usar `gh` CLI, nunca MCP do GitHub)
   - Se for descrição livre: usar como contexto para busca no código

2. **Analisar código-fonte:**
   - Buscar controllers, views, JS, services relacionados (`app/controllers/`, `app/views/`, `app/assets/javascripts/`, `app/services/`, `app/queries/`, `app/forms/`)
   - Usar Grep/Glob para localizar arquivos relevantes
   - Ler o código para entender fluxos, estados, validações

3. **Analisar testes existentes:**
   - Verificar se já existem testes E2E em `spec/e2e/` para essa feature
   - Verificar specs RSpec em `spec/` e Jest em `spec/javascript/` que documentem comportamento esperado
   - Identificar gaps de cobertura

4. **Mapear a feature:**
   - Listar todas as telas/páginas envolvidas
   - Identificar fluxos (happy path, erros, edge cases)
   - Identificar dependências (dados pré-existentes no banco, ano letivo, turma/enturmação ativa, permissões Pundit, papel do usuário)
   - Identificar elementos dinâmicos (AJAX, jobs Sidekiq, loading states, modais, selects encadeados, componentes Vue.js)

### Output da Fase 1
Apresentar ao usuário um resumo:
```
Feature: [nome]
Telas envolvidas: [lista]
Fluxos identificados: [lista]
Testes existentes: [sim/não, quais]
Próximo passo: gerar roteiro
```

Pedir confirmação antes de prosseguir.

---

## Fase 2 — Roteiro Funcional

### Objetivo
Gerar roteiro de teste em linguagem natural para validação humana.

### Estrutura do Roteiro

Criar arquivo markdown em `docs/e2e/<nome-feature>-roteiro.md` (criar o diretório se não existir) com:

```markdown
# Roteiro E2E: [Nome da Feature]

## Contexto
[Breve descrição da feature e seu propósito]

## Pré-requisitos
- [Dados necessários no banco: escola, turma, disciplina, alunos, enturmações]
- [Estado de autenticação — usuário e papel]
- [Ano letivo / período / etapa selecionados]

## Cenários

### Happy Path
#### CT-XX: [Título do cenário]
- **Dado que** [contexto/estado inicial]
- **Quando** [ação do usuário]
- **Então** [resultado esperado]

### Validações e Erros
#### CT-XX: [Título]
- ...

### Edge Cases
#### CT-XX: [Título]
- ...

### Navegação
#### CT-XX: [Título]
- ...
```

### Regras para o Roteiro
- Numerar cenários sequencialmente (CT-01, CT-02...)
- Se já existem testes E2E para essa feature, continuar a numeração a partir do último CT existente
- Agrupar por categoria (happy path, validações, edge cases, navegação)
- Usar linguagem acessível — o roteiro deve ser entendido sem conhecimento técnico
- Roteiro em **português (pt-BR)** — convenção do i-Diário para E2E
- Incluir cenários de segurança quando relevante (acesso não autorizado, isolamento por Entity, permissões Pundit)

### GATE: Aprovação Humana

Após gerar o roteiro:

> Roteiro salvo em `docs/e2e/<nome>-roteiro.md`.
> Por favor, revise os cenários. Posso ajustar, adicionar ou remover cenários antes de começarmos a navegar pelas telas.
> Quando estiver satisfeito, me diga para prosseguir.

**NÃO avançar para a Fase 3 sem aprovação explícita do usuário.**

---

## Fase 3 — Navegação Assistida + Enriquecimento Técnico

### Objetivo
Navegar pelas telas da aplicação, validar os cenários do roteiro, e coletar informações técnicas (seletores, waits, estados).

### Pré-requisitos para navegação

- Aplicação rodando via Docker (`docker-compose up`) e acessível em `http://entity.localhost:3000`
  - Verificar: `curl -s -o /dev/null -w "%{http_code}" http://entity.localhost:3000` (espera 200 ou 302)
  - Se estiver rodando de um worktree, subir com `docker compose -p <nome-projeto-principal> up` de dentro do worktree
- Arquivo `.env.e2e` configurado (ver `.env.e2e.example`)
- Chromium instalado: `npx playwright install chromium`
- Auth setup roda automaticamente como `setup project` — não precisa executar à parte

### Ferramentas de Browser

**Primário: Playwright MCP** (`mcp__playwright__*` ou `mcp__plugin_playwright_playwright__*`)
- Usar para navegação, cliques, preenchimento de formulários, screenshots, assertions
- Ferramentas principais:
  - `browser_navigate` — navegar para URLs
  - `browser_snapshot` — capturar estado da página (DOM acessível)
  - `browser_click` — clicar em elementos
  - `browser_fill_form` — preencher múltiplos campos
  - `browser_type` — digitar texto em campo focado
  - `browser_select_option` — selecionar opção em dropdown
  - `browser_take_screenshot` — capturar screenshot
  - `browser_evaluate` — executar JavaScript na página
  - `browser_wait_for` — aguardar elemento ou condição
  - `browser_press_key` — pressionar tecla

**Fallback: Claude-in-Chrome** (`mcp__claude-in-chrome__*`)
- Usar APENAS quando Playwright MCP falhar ou não conseguir interagir com algum elemento
- Útil para fluxos que precisam de sessão real do navegador do usuário

### Processo de Navegação

Para cada cenário do roteiro:

1. **Navegar até a tela inicial do cenário**
   - URL base do `.env.e2e` (`E2E_BASE_URL`, normalmente `http://entity.localhost:3000`)
   - O tenant é resolvido pelo **subdomínio** (`entity.`), não por path — não montar paths multi-tenant
   - Autenticar usando `storageState: 'spec/e2e/.auth/user.json'`; se não existir, rodar `npx playwright test spec/e2e/auth.setup.js`

2. **Executar os passos do cenário**
   - Clicar, preencher, selecionar conforme descrito
   - Capturar snapshot após cada ação significativa
   - Se o mini-profiler do Rails sobrepuser elementos no canto superior esquerdo, usar `{ force: true }` no clique

3. **Coletar informações técnicas:**
   - Seletores dos elementos interagidos (preferência: `#id` > `[data-testid]` > `getByRole` > CSS)
   - Tempos de carregamento observados
   - Estados intermediários (loading, AJAX, selects encadeados, jobs Sidekiq)
   - Mensagens de erro/sucesso exatas (flash messages do Rails)
   - Classes CSS e atributos de dados relevantes

4. **Reportar ao usuário:**
   - Mostrar o que encontrou para cada cenário
   - Destacar divergências entre o roteiro e o comportamento real
   - Pedir confirmação/ajuste

5. **Enriquecer o roteiro:**
   - Atualizar `docs/e2e/<nome>-roteiro.md` com detalhes técnicos descobertos
   - Adicionar seção "Detalhes Técnicos" em cada cenário com seletores e waits

### Formato do Enriquecimento

```markdown
#### CT-01: Acesso ao diário de avaliações
- **Dado que** o usuário está logado
- **Quando** acessa o menu Diário de Avaliações
- **Então** vê a tela de lançamento de notas

**Detalhes Técnicos:**
- URL: `/avaliacoes/notas`
- Seletor do menu: `#left-panel a[href="/avaliacoes/notas"]`
- Wait: `await expect(page.locator('#daily-notes-form')).toBeVisible()`
- Assertion: `await expect(page.locator('h1')).toHaveText('Diário de avaliações')`
```

---

## Fase 4 — Escrita dos Testes Playwright

### Objetivo
Transformar o roteiro enriquecido em código Playwright funcional.

### Convenções do Projeto i-Diário (OBRIGATÓRIAS)

Seguir as convenções de [docs/testes-e2e.md](../../docs/testes-e2e.md) e do teste existente `spec/e2e/command_palette.spec.js`:

1. **Idioma:**
   - Descrições dos `test()` e `describe()` em **português** — CLAUDE.md: E2E em pt-BR para legibilidade de todo o time
   - Comentários em **português**
   - Código (nomes de helpers, variáveis, funções) em **inglês** — regra geral do projeto

2. **Estrutura:**
   - Usar a fixture `page` de cada teste (`async ({ page }) => {}`) — **não** compartilhar `page` via `beforeAll`
   - `test.beforeEach` navega para a página e aguarda `#left-panel` visível
   - `test.describe.serial` apenas quando os testes realmente dependem de ordem
   - Cada teste deve ser independente — não depender de estado de testes anteriores
   - Helpers como funções no topo do arquivo, recebendo `page` como parâmetro

3. **Seletores (ordem de preferência):**
   - `#id` — preferencial (a UI do i-Diário é rica em ids)
   - `[data-testid]`
   - `getByRole()` / `getByText()`
   - `locator()` com CSS — quando não há alternativa

4. **Waits:**
   - `await expect(locator).toBeVisible()` em vez de `waitForTimeout`
   - `#left-panel` visível com `{ timeout: 15000 }` como sinal de página carregada
   - Antes de enviar teclas, garantir foco com `await expect(locator).toBeFocused()`

5. **Autenticação:**
   - Já resolvida pelo `setup project` do `playwright.config.js` — os testes iniciam autenticados
   - **NÃO** recriar fluxo de login nos testes nem declarar `storageState` manualmente
   - **NÃO** alterar `spec/e2e/auth.setup.js` sem aprovação

6. **Variáveis de ambiente:**
   - `baseURL` já vem do config — usar paths relativos (`page.goto('/avaliacoes/notas')`)
   - Nunca hardcodar credenciais; usar `process.env.E2E_*` quando necessário

### Estrutura do Arquivo (template i-Diário)

```javascript
const { test, expect } = require('@playwright/test');

// Helpers reutilizáveis
const form = (page) => page.locator('#meu-form');

async function selectClassroom(page, name) {
  await page.locator('#classroom_id').selectOption({ label: name });
  await expect(form(page)).toBeVisible();
}

test.describe('Nome da funcionalidade', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/caminho/da/feature');
    await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
  });

  test.describe('CT-01: descrição do cenário', () => {
    test('descrição do comportamento esperado', async ({ page }) => {
      await page.locator('#meu-elemento').click();
      await expect(page.locator('#resultado')).toBeVisible();
    });
  });
});
```

### Processo de Escrita

1. **Gerar o arquivo completo** em `spec/e2e/<nome_feature>.spec.js` (snake_case)
2. **Rodar os testes:**
   ```bash
   npm run test:e2e -- spec/e2e/<nome_feature>.spec.js
   ```
   Ou com browser visível para debug:
   ```bash
   npx playwright test spec/e2e/<nome_feature>.spec.js --headed
   ```
   > Comandos Playwright/npm rodam no host, **não** dentro do Docker.
3. **Se falhar:** analisar o erro, ajustar seletores/waits, rodar novamente
   - Trace do retry: `npx playwright show-trace test-results/<pasta>/trace.zip`
4. **Se passar:** reportar sucesso ao usuário

### Apresentação Final

Ao concluir:

> Testes E2E concluídos!
>
> **Arquivos criados:**
> - Roteiro: `docs/e2e/<nome>-roteiro.md`
> - Testes: `spec/e2e/<nome>.spec.js`
>
> **Resultados:** X cenários, Y testes, todos passando
>
> Quer que eu commite os arquivos? (Branch + commit + PR em português, seguindo Conventional Commits — ver skill `/git-flow`)

---

## Regras Gerais

### O que o comando NÃO faz
- NÃO modifica código de produção (controllers, views, models, services)
- NÃO cria fixtures ou dados de teste no banco (usa dados existentes do ambiente de dev)
- NÃO altera o auth setup existente (`spec/e2e/auth.setup.js`) a menos que necessário e aprovado
- NÃO roda testes destrutivos (exclusão de dados reais, drop, etc.)
- NÃO commita automaticamente — sempre pede aprovação

### Interatividade
- Cada fase pede confirmação antes de avançar
- O usuário pode pedir para ajustar, adicionar ou remover cenários a qualquer momento
- Se algo não funcionar na navegação, reportar e pedir orientação

### Adaptação ao i-Diário
- Tenant resolvido por **subdomínio** (`entity.localhost:3000`) — cada Entity tem seu próprio banco
- Considerar permissões por papel (professor, coordenador, administrador) e policies Pundit quando relevante
- Muitas telas dependem de contexto (ano letivo, escola, turma, disciplina, etapa) — o roteiro deve deixar isso explícito nos pré-requisitos
- Frontend misto: jQuery/Backbone (legado) + Vue.js 2.6 — atenção a componentes que montam de forma assíncrona
- Configuração: `playwright.config.js` na raiz; variáveis em `.env.e2e` (ver `.env.e2e.example`)
- E2E só para fluxos críticos de usuário (CLAUDE.md) — não replicar cobertura de RSpec/Jest

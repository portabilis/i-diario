# Testes E2E com Playwright

Testes end-to-end que validam funcionalidades do i-Diário em um navegador real (Chromium), interagindo com a aplicação em execução.

## Pré-requisitos

1. **Node.js** instalado
2. **Aplicação rodando** via Docker (`docker-compose up`)
3. **Navegador Chromium** instalado para o Playwright:

```bash
npx playwright install chromium
```

## Configuração de credenciais

Os testes precisam de credenciais para autenticar na aplicação. **Nunca commite senhas no repositório.**

### Opção 1: Arquivo `.env.e2e` (recomendado)

```bash
cp .env.e2e.example .env.e2e
```

Edite `.env.e2e` e preencha a senha:

```
E2E_BASE_URL=http://ararangua.localhost:3000
E2E_USER_EMAIL=admin@portabilis.com.br
E2E_USER_PASSWORD=sua_senha_aqui
```

> O arquivo `.env.e2e` já está no `.gitignore`.

### Opção 2: Variável de ambiente inline

```bash
E2E_USER_PASSWORD='sua_senha' npx playwright test
```

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `E2E_BASE_URL` | `http://ararangua.localhost:3000` | URL base da aplicação |
| `E2E_USER_EMAIL` | `admin@portabilis.com.br` | Email de login |
| `E2E_USER_PASSWORD` | *(obrigatório)* | Senha de login |

## Executando os testes

### Com `.env.e2e` configurado

```bash
# Carregar variáveis e rodar todos os testes
env $(cat .env.e2e | xargs) npx playwright test

# Ou usar o script npm
env $(cat .env.e2e | xargs) npm run test:e2e
```

### Rodar um teste específico

```bash
env $(cat .env.e2e | xargs) npx playwright test command_palette
```

### Rodar com interface visual (debug)

```bash
env $(cat .env.e2e | xargs) npx playwright test --ui
```

### Rodar com navegador visível

```bash
env $(cat .env.e2e | xargs) npx playwright test --headed
```

## Estrutura de arquivos

```
spec/e2e/
├── helpers/
│   └── auth.js            # Helper de autenticação (login via formulário)
└── command_palette.spec.js # Testes da paleta de comandos
playwright.config.js        # Configuração do Playwright
.env.e2e.example            # Exemplo de variáveis de ambiente
```

## Criando novos testes

### 1. Crie o arquivo de teste

Crie um arquivo em `spec/e2e/` com a extensão `.spec.js`:

```javascript
const { test, expect } = require('@playwright/test');
const { login } = require('./helpers/auth');

test.describe('Nome da funcionalidade', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('descrição do cenário', async ({ page }) => {
    // Interaja com a página
    await page.click('#meu-elemento');

    // Faça asserções
    await expect(page.locator('#resultado')).toBeVisible();
  });
});
```

### 2. Use o helper de autenticação

O `login(page)` navega para a página inicial, preenche o formulário e aguarda o menu lateral carregar:

```javascript
const { login } = require('./helpers/auth');

// Login com credenciais padrão (variáveis de ambiente)
await login(page);

// Login com credenciais específicas
await login(page, { email: 'outro@email.com', password: 'outra_senha' });
```

### 3. Boas práticas

- **Seletores**: prefira `#id` e `[data-testid]` em vez de classes CSS
- **Esperas**: use `await expect(locator).toBeVisible()` em vez de `waitForTimeout`
- **Foco**: se o teste envia teclas, garanta que o elemento correto está focado com `await expect(locator).toBeFocused()`
- **Isolamento**: cada teste deve ser independente — não dependa do estado de testes anteriores
- **Idioma**: descreva os testes em português (consistente com o projeto), mas escreva código em inglês

### 4. Dicas de debug

```bash
# Ver trace de um teste falhando (gerado automaticamente no retry)
npx playwright show-trace test-results/<pasta-do-teste>/trace.zip

# Rodar com screenshots a cada passo
env $(cat .env.e2e | xargs) npx playwright test --headed --screenshot on

# Pausar execução para inspecionar
await page.pause(); // adicione no teste
```

## Configuração

O arquivo `playwright.config.js` define:

- **testDir**: `./spec/e2e` — diretório dos testes
- **timeout**: 30s por teste
- **retries**: 1 retry em caso de falha
- **screenshot**: captura automática em falhas
- **trace**: captura de trace no primeiro retry
- **browser**: Chromium
- **locale**: pt-BR

## Troubleshooting

### Teste falha com "E2E_USER_PASSWORD não definida"

As credenciais não foram carregadas. Verifique se o `.env.e2e` existe e está preenchido, ou passe a variável inline.

### Timeout no login

A aplicação pode estar lenta para responder. Verifique se o Docker está rodando e a aplicação está acessível no URL configurado:

```bash
curl -s -o /dev/null -w "%{http_code}" http://ararangua.localhost:3000
# Deve retornar 200 ou 302
```

### Mini-profiler interceptando cliques

O mini-profiler do Rails pode sobrepor elementos no canto superior esquerdo. Use `{ force: true }` no clique ou clique em outra posição do elemento.

### Elemento não recebe foco a tempo

Alguns componentes usam `setTimeout` para focar elementos. Adicione `await expect(locator).toBeFocused()` antes de enviar teclas.

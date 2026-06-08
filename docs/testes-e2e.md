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
E2E_BASE_URL=http://entity.localhost:3000
E2E_USER_EMAIL=admin@example.com
E2E_USER_PASSWORD=sua_senha_aqui
```

> O arquivo `.env.e2e` já está no `.gitignore`. As variáveis são carregadas automaticamente via `dotenv` no `playwright.config.js`.

### Opção 2: Variável de ambiente inline

```bash
E2E_USER_PASSWORD='sua_senha' npx playwright test
```

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `E2E_BASE_URL` | `http://entity.localhost:3000` | URL base da aplicação |
| `E2E_USER_EMAIL` | `admin@example.com` | Email de login |
| `E2E_USER_PASSWORD` | *(obrigatório)* | Senha de login |

## Executando os testes

### Com `.env.e2e` configurado

```bash
# Rodar todos os testes (dotenv carrega variáveis automaticamente)
npm run test:e2e

# Ou diretamente
npx playwright test
```

### Rodar um teste específico

```bash
npx playwright test command_palette
```

### Rodar com interface visual (debug)

```bash
npx playwright test --ui
```

### Rodar com navegador visível

```bash
npx playwright test --headed
```

## Estrutura de arquivos

```
spec/e2e/
├── .auth/                      # Estado de sessão salvo (gitignored)
│   └── user.json
├── auth.setup.js               # Setup de autenticação (login uma única vez)
└── command_palette.spec.js     # Testes da paleta de comandos
playwright.config.js            # Configuração do Playwright
.env.e2e.example                # Exemplo de variáveis de ambiente
```

## Autenticação

O Playwright usa o padrão de **setup project** para autenticação. O login é executado **uma única vez** antes de todos os testes, e o estado de sessão é salvo em `spec/e2e/.auth/user.json`. Todos os testes subsequentes reutilizam essa sessão, tornando a execução mais rápida.

O fluxo é:

1. O projeto `setup` executa `auth.setup.js` (faz login e salva `storageState`)
2. O projeto `chromium` depende do `setup` e usa o `storageState` salvo
3. Cada teste inicia já autenticado — basta navegar para a página desejada

## Criando novos testes

### 1. Crie o arquivo de teste

Crie um arquivo em `spec/e2e/` com a extensão `.spec.js`:

```javascript
const { test, expect } = require('@playwright/test');

test.describe('Nome da funcionalidade', () => {
  test.beforeEach(async ({ page }) => {
    // Navega para a página — a autenticação já foi feita pelo setup
    await page.goto('/');
    await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 });
  });

  test('descrição do cenário', async ({ page }) => {
    // Interaja com a página
    await page.locator('#meu-elemento').click();

    // Faça asserções
    await expect(page.locator('#resultado')).toBeVisible();
  });
});
```

### 2. Boas práticas

- **Seletores**: prefira `#id` e `[data-testid]` em vez de classes CSS
- **Esperas**: use `await expect(locator).toBeVisible()` em vez de `waitForTimeout`
- **Foco**: se o teste envia teclas, garanta que o elemento correto está focado com `await expect(locator).toBeFocused()`
- **Isolamento**: cada teste deve ser independente — não dependa do estado de testes anteriores
- **Idioma**: descreva os testes em português (consistente com o projeto), mas escreva código em inglês

### 3. Dicas de debug

```bash
# Ver trace de um teste falhando (gerado automaticamente no retry)
npx playwright show-trace test-results/<pasta-do-teste>/trace.zip

# Rodar com screenshots a cada passo
npx playwright test --headed --screenshot on

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
- **auth**: setup project com `storageState` para login único
- **dotenv**: carrega `.env.e2e` automaticamente

## Troubleshooting

### Teste falha com "E2E_USER_PASSWORD não definida"

As credenciais não foram carregadas. Verifique se o `.env.e2e` existe e está preenchido, ou passe a variável inline.

### Timeout no login

A aplicação pode estar lenta para responder. Verifique se o Docker está rodando e a aplicação está acessível no URL configurado:

```bash
curl -s -o /dev/null -w "%{http_code}" http://entity.localhost:3000
# Deve retornar 200 ou 302
```

### Mini-profiler interceptando cliques

O mini-profiler do Rails pode sobrepor elementos no canto superior esquerdo. Use `{ force: true }` no clique ou clique em outra posição do elemento.

### Elemento não recebe foco a tempo

Alguns componentes usam `setTimeout` para focar elementos. Adicione `await expect(locator).toBeFocused()` antes de enviar teclas.

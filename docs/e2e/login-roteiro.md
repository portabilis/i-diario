# Roteiro E2E: Login

## Contexto

Autenticação de usuário no i-Diário. A tela de login é o ponto de entrada da aplicação:
usuários não autenticados que acessam qualquer rota interna são redirecionados para lá.

O campo de identificação aceita **nome de usuário, e-mail ou CPF**. Após autenticar, o
usuário cai na tela inicial com o menu lateral (`#left-panel`) disponível.

> Este roteiro cobre o **happy path**. O `spec/e2e/auth.setup.js` também faz login, mas como
> pré-condição dos demais testes — ele não valida o fluxo como funcionalidade. Este roteiro
> valida o login em si, partindo de sessão limpa.

## Pré-requisitos

- Aplicação acessível na URL de `E2E_BASE_URL`
- Usuário válido em `E2E_USER_EMAIL` / `E2E_USER_PASSWORD` (`.env.e2e`)
- **A senha deve estar entre aspas no `.env.e2e`** — caracteres como `#` iniciam comentário
  no formato dotenv e truncam o valor silenciosamente
- Sessão limpa (sem `storageState`) — o teste precisa autenticar de fato

⚠️ **Cuidado com bloqueio de conta:** o i-Diário bloqueia o acesso após 5 tentativas
falhas. Cenários de credencial inválida consomem tentativas e por isso **não** estão
automatizados neste roteiro.

## Cenários

### Happy Path

#### CT-01: Exibição da tela de login
- **Dado que** o usuário não está autenticado
- **Quando** acessa a raiz da aplicação
- **Então** é redirecionado para a tela de login com os campos de identificação, senha e o botão Acessar

**Detalhes Técnicos:**
- URL final: `/usuarios/logar`
- Seletores: `#user_credentials`, `#user_password`, `#btn-login`
- Botão Acessar: `#btn-login` (texto "Acessar")
- Assertion: `await expect(page).toHaveURL(/\/usuarios\/logar/)`

#### CT-02: Login com credenciais válidas
- **Dado que** o usuário está na tela de login
- **Quando** preenche identificação e senha válidas e clica em Acessar
- **Então** é autenticado e vê a tela inicial com o menu lateral

**Detalhes Técnicos:**
- Preenchimento: `#user_credentials` (e-mail), `#user_password` (senha)
- Submit: `#btn-login`
- Wait: `await expect(page.locator('#left-panel')).toBeVisible({ timeout: 15000 })`
- Título da página após login: `Início`
- Assertion adicional: `#user_credentials` deixa de existir (saiu da tela de login)

### Navegação

#### CT-03: Menu lateral disponível após autenticar
- **Dado que** o usuário acabou de autenticar
- **Quando** observa o menu lateral
- **Então** vê os itens de navegação e o link de sair

**Detalhes Técnicos:**
- Menu: `#left-panel a` (itens observados: Alunos vinculados `/user_students`,
  Ocorrências `/ocorrencias-disciplinares`, Boletins escolares `/boletins-escolares`,
  Sincronizações `/admin-sincronizacoes`)
- Link de sair: `#header a[href="/usuarios/sair"]` — fica no cabeçalho (**não** no `#left-panel`),
  dentro de um `.dropdown-menu` fechado (`display: none`). Asserção por presença
  (`toHaveCount(1)`), não por visibilidade
- Paleta de comandos disponível: `#cp-trigger`

### Segurança

#### CT-04: Rota interna exige autenticação
- **Dado que** o usuário não está autenticado
- **Quando** tenta acessar uma rota interna diretamente
- **Então** é redirecionado para a tela de login

**Detalhes Técnicos:**
- Rota testada: `/ocorrencias-disciplinares`
- Redirect observado: `/usuarios/logar`
- Assertion: `await expect(page).toHaveURL(/\/usuarios\/logar/)`

## Fora de escopo (não automatizado)

| Cenário | Motivo |
|---|---|
| Credenciais inválidas | Consome tentativas do contador de bloqueio (5 máx.) |
| Bloqueio após N tentativas | Bloquearia a conta usada pelos demais testes E2E |
| Login por CPF / nome de usuário | Exige credenciais adicionais não disponíveis no `.env.e2e` |
| Recuperação de senha / desbloqueio | Depende de envio de e-mail |

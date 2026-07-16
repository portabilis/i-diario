# Git Worktrees no i-Diário

Resumo de como o projeto está configurado para rodar sessões paralelas do Claude Code em [git worktrees](https://git-scm.com/docs/git-worktree) — cada sessão num diretório de trabalho isolado, com a própria branch, sem que edições de uma colidam com as de outra.

**Doc oficial (detalhes completos):** https://code.claude.com/docs/en/worktrees

## Como usar

Criar um worktree e iniciar o Claude nele:

```bash
claude --worktree minha-feature
# ou sem nome (gera um automático):
claude --worktree
```

Por padrão o worktree fica em `.claude/worktrees/<nome>/` na raiz do repo, numa branch nova `worktree-<nome>`. Também dá pra pedir ao Claude "trabalhe num worktree" durante a sessão (tool `EnterWorktree`).

### Rodando um worktree com Docker

Para subir a aplicação **de dentro de um worktree**, rode o Docker Compose a partir do diretório do worktree e force o mesmo nome de projeto do checkout principal:

```bash
cd .claude/worktrees/<nome>
docker compose -p <nome-do-projeto> up
```

O `-p <nome-do-projeto>` é necessário: sem ele, o Compose deriva o nome do projeto do diretório atual (o worktree) e sobe um ambiente isolado, com volumes vazios (banco sem dados, etc.), em vez de reaproveitar o do checkout principal. Use o nome de projeto Compose do checkout principal — por padrão, o nome do diretório raiz do projeto.

Como os `container_name` são fixos no `docker-compose.yml`, rode a aplicação em **um** checkout por vez (principal **ou** um worktree), não nos dois ao mesmo tempo.

## Configuração do projeto

### `.worktreeinclude` (raiz, versionado)

Worktree é um checkout limpo: arquivos gitignored **não** vêm junto. No i-Diário não basta o `.env` — vários arquivos de configuração necessários para subir a aplicação também estão no `.gitignore`. O `.worktreeinclude` lista os arquivos gitignored que o Claude Code copia automaticamente para cada worktree criado:

```
.env
.env.e2e
config/database.yml
config/secrets.yml
config/puma.rb
docker-compose.override.yml
Gemfile.plugins
.bundle/config
```

- Sintaxe `.gitignore`.
- Só copia o que casa com o padrão **e** é gitignored — arquivos versionados nunca são duplicados.
- Arquivos que não existirem na sua máquina são simplesmente ignorados (sem erro).
- Vale para `--worktree`, subagents com `isolation: worktree` e sessões paralelas do app desktop.

**Por que esses arquivos:**

- `config/database.yml` e `config/secrets.yml` — sem eles a aplicação Rails nem inicializa (conexão com o banco e `secret_key_base`).
- `config/puma.rb` — configuração do servidor de aplicação.
- `docker-compose.override.yml` — overrides locais do Docker Compose (portas, volumes, etc.).
- `.env` — variáveis de ambiente (ex.: `DOCKER_APP_PORT`).
- `.env.e2e` — credenciais e configuração dos testes Playwright (E2E).
- `Gemfile.plugins` — declaração de gems adicionais (plugins) usadas localmente.
- `.bundle/config` — configuração local do Bundler (caminhos e flags de install).

Se um novo arquivo gitignored de config virar dependência (ex.: `config/google_drive.json`, um initializer ignorado), adicionar a linha aqui.

**Dependências locais não-versionadas.** O `.worktreeinclude` **copia arquivos**, mas o container monta apenas o diretório do worktree em `/app`. Se a aplicação depender de algo que vive **fora** do worktree e não é versionado — por exemplo uma gem declarada com `path:` cujo diretório é gitignored — copiar não é o caminho: forneça essa dependência ao container por um **bind-mount no `docker-compose.override.yml`**, apontando para um caminho **absoluto** do host. Como o `docker-compose.override.yml` é copiado para cada worktree, o mesmo caminho absoluto vale para todos eles. Isso mantém o `.worktreeinclude` versionado enxuto e sem referências a dependências específicas do seu ambiente.

### `.gitignore`

`.claude/worktrees/` está ignorado para os worktrees não aparecerem como arquivos untracked no checkout principal.

## Limpeza

Ao sair de uma sessão de worktree, o Claude remove o worktree e a branch automaticamente **se não houver mudanças** (sem alterações não commitadas, sem arquivos untracked, sem commits novos). Havendo mudanças, ele pergunta se quer manter ou descartar. Remoção manual:

```bash
git worktree list
git worktree remove .claude/worktrees/<nome>
```

Mais detalhes sobre branch base, isolamento de subagents, VCS não-git e a tool `EnterWorktree`: ver a [doc oficial](https://code.claude.com/docs/en/worktrees).

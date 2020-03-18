[![Latest Release](https://img.shields.io/github/release/portabilis/i-diario.svg?label=latest%20release)](https://github.com/portabilis/i-diario/releases)
[![Maintainability](https://api.codeclimate.com/v1/badges/92cee0c65548b4b4653b/maintainability)](https://codeclimate.com/github/portabilis/i-diario/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/92cee0c65548b4b4653b/test_coverage)](https://codeclimate.com/github/portabilis/i-diario/test_coverage)

# i-Diário

Portal do professor integrado com o software livre [i-Educar](https://github.com/portabilis/i-educar)

## Comunicação

Acreditamos que o sucesso do projeto depende diretamente da interação clara e
objetiva entre os membros da Comunidade. Por isso, estamos definindo algumas
políticas para que estas interações nos ajudem a crescer juntos! Você pode
consultar algumas destas boas práticas em nosso [código de
conduta](https://github.com/portabilis/i-diario/blob/master/CODE_OF_CONDUCT.md).

Além disso, gostamos de meios de comunicação assíncrona, onde não há necessidade de
respostas em tempo real. Isso facilita a produtividade individual dos
colaboradores do projeto.

| Canal de comunicação | Objetivos |
|----------------------|-----------|
| [Fórum](https://forum.ieducar.org) | - Tirar dúvidas <br>- Discussões de como instalar a plataforma<br> - Discussões de como usar funcionalidades<br> - Suporte entre membros de comunidade<br> - FAQ da comunidade (sobre o produto e funcionalidades) |
| [Issues do Github](https://github.com/portabilis/i-diario/issues/new/choose) | - Sugestão de novas funcionalidades<br> - Reportar bugs<br> - Discussões técnicas |
| [Telegram](https://t.me/ieducar ) | - Comunicar novidades sobre o projeto<br> - Movimentar a comunidade<br>  - Falar tópicos que **não** demandem discussões profundas |

Qualquer outro grupo de discussão não é reconhecido oficialmente pela
comunidade i-Educar e não terá suporte da Portabilis - mantenedora do projeto.

## Instalação

- Baixar o i-Diário:

```bash
$ git clone https://github.com/portabilis/i-diario.git
$ cd i-diario
```

- Copiar o exemplo de configurações de banco de dados e configurar:

```bash
$ cp config/database.sample.yml config/database.yml
```

### Com Docker

No `config/database.yml` mudar o `host` para `host: postgres`.

- Rode `docker-compose up`.

Por baixo dos panos, será feito:
- setup do `secret_key_base`;
- setup do banco;
- setup das páginas de erro.

Pule para o [**Configuração da Aplicação**](#Configuração-da-Aplicação).

### Sem Docker (Testado no Ubuntu 18.04)

- Instalar o Ruby 2.3.7 (Recomendamos uso de um gerenciador de versões como [Rbenv](https://github.com/rbenv/rbenv) ou [Rvm](https://rvm.io/))
- Instalar Postgres e configurar para fazer coincidir com o configurado em `database.yml`
- Instalar a biblioteca `libpq-dev`

```bash
$ sudo apt install libpq-dev
```

- Instalar a gem Bundler:

```bash
$ gem install bundler -v '1.17.3'
```

- Instalar as gems:

```bash
$ bundle install
```

- Criar e configurar o arquivo `config/secrets.yml` conforme o exemplo:

```yaml
development:
  secret_key_base: CHAVE_SECRETA
  SMTP_ADDRESS: SMTP_ADDRESS
  SMTP_PORT: SMTP_PORT
  SMTP_DOMAIN: SMTP_DOMAIN
  SMTP_USER_NAME: SMTP_USER_NAME
  SMTP_PASSWORD: SMTP_PASSWORD
  BUCKET_NAME: S3_BUCKET_NAME
```

_Nota: Você pode gerar uma chave secreta usando o comando `bundle exec rake secret`_

- Criar e configurar o arquivo `config/aws.yml` conforme o exemplo:

```yaml
development:
  access_key_id: AWS_ACCESS_KEY_ID
  secret_access_key: AWS_SECRET_ACCESS_KEY

```

- Criar o banco de dados:

```bash
$ bundle exec rake db:create
$ bundle exec rake db:migrate
```

- Criar páginas de erro simples para desenvolvimento:

```bash
$ cp public/404.html.sample public/404.html
$ cp public/500.html.sample public/500.html
```

## Configuração da Aplicação

- Criar uma entidade:

```bash
$ bundle exec rake entity:setup NAME=prefeitura DOMAIN=localhost DATABASE=prefeitura_diario
```

- Criar um usuário administrador:

Abra o `rails console`.

Sem docker:

```bash
$ bundle exec rails console
```

Com docker:

```bash
$ docker exec -it idiario bundle exec rails console
```

Crie um usuário administrador.

```ruby
Entity.last.using_connection {
  User.create!(
    email: 'admin@domain.com.br',
    password: '123456789',
    password_confirmation: '123456789',
    status: 'active',
    kind: 'employee',
    admin:  true
  )
}
```

Iniciar o servidor:

```bash
$ bundle exec rails server
```

Para acessar o sistema, use a URL http://localhost:3000

### [PgHero](https://github.com/ankane/pghero)

Usamos o PgHero para monitorar o banco de dados. Recomendamos a leitura da
documentação.

## Sincronização com i-Educar

- Para executar a sincronização é necessário estar com o sidekiq rodando:
```bash
$ bundle exec sidekiq -d
```
- Acessar Configurações > Api de Integraçao e configurar os dados do sincronismo
- Acessar Configurações > Unidades e clicar em **Sincronizar**
- Acessar Calendário letivo, clicar em **Sincronizar** e configurar os calendários
- Acessar Configurações > Api de Integração
  - Existem dois botões nessa tela:
    - Sincronizar: Ao clicar nesse botão, será verificado a ultima data de sincronização e somente vai sincronizar os dados inseridos/atualizados/deletados após essa data.
    - Sincronização completa: Esse botão apenas aparece para o usuário administrador e ao clicar nesse botão, não vai fazer a verificação de data, sincronizando todos os dados de todos os anos.

_Nota: Após esses primeiros passos, recomendamos que a sincronização rode pelo menos diariamente para manter o i-Diário atualizado com o i-Educar_

## Rodar os testes

```bash
$ RAILS_ENV=test bundle exec rake db:create
$ RAILS_ENV=test bundle exec rake db:migrate
```

```bash
$ bin/rspec spec
```

## Upgrades

### Upgrade para a versão 1.1.0

Nessa atualização a sincronização entre i-educar e i-diário foi completamente reestruturada e com isso o i-diário passa a ter dependência da versão **2.1.18** do i-educar.

Para o upgrade é necessário:

* Atualizar o fonte para a versão 1.1.0
* Parar o sidekiq:
```bash
$ ps -ef | grep sidekiq | grep -v grep | awk '{print $2}' | xargs kill -TERM && sleep 20
```
* Rodar as migrations:
```bash
$ bundle exec rake db:migrate
```
* Iniciar o sidekiq:
```bash
$ bundle exec sidekiq -d --logfile log/sidekiq.log
```
* Executar a rake task que vai remover as enturmações e rodar a sincronização completa em todas as entidades:
```bash
$ bundle exec rake upgrade:versions:1_1_0
```

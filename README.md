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

- Instalar o Ruby 2.2.6 (Recomendamos uso de um gerenciador de versões como [Rbenv](https://github.com/rbenv/rbenv) ou [Rvm](https://rvm.io/))
- Instalar a gem Bundler:

```bash
$ gem install bundler -v '1.17.3'
```

- Baixar o i-Diário:

```bash
$ git clone https://github.com/portabilis/i-diario.git
```

- Instalar as gems:

```bash
$ cd i-diario
$ bundle install
```

- Copiar o exemplo de configurações de banco de dados e configurar:

```bash
$  cp config/database.sample.yml config/database.yml
```

- Criar e configurar o arquivo `config/secrets.yml` conforme o exemplo:

```yaml
development:
  secret_key_base: CHAVE_SECRETA_AQUI
```

_Nota: Você pode gerar uma chave secreta usando o comando `bundle exec rake secret`_


- Criar o banco de dados:

```bash
$ bundle exec rake db:create
$ bundle exec rake db:migrate
```

- Criar uma entidade:

```bash
$ bundle exec rake entity:setup NAME=prefeitura DOMAIN=localhost DATABASE=prefeitura_diario
```

- Criar um usuário administrador:

```bash
$ bundle exec rails console
```
```ruby
Entity.last.using_connection {
  User.create!(
    email: 'admin@domain.com.br',
    password: '123456789',
    password_confirmation: '123456789',
    status: 'actived',
    kind: 'employee',
    admin:  true
  )
}
```

- Iniciar o servidor e acessar http://localhost:3000 para acessar o sistema:

```bash
$ bundle exec rails server
```

## Sincronização com i-Educar

- Acessar Configurações > Api de Integraçao e configurar os dados do sincronismo
- Acessar Configurações > Unidades e clicar em **Sincronizar**
- Acessar Calendário letivo, clicar em **Sincronizar** e configurar os calendários
- Acessar Configurações > Api de Integração e clicar no botão de sincronizar

_Nota: Após esses primeiros passos, recomendamos que a sincronização rode pelo menos diariamente para manter o i-Diário atualizado com o i-Educar_

## Rodar os testes

```bash
$ RAILS_ENV=test bundle exec rake db:create
$ RAILS_ENV=test bundle exec rake db:migrate
```

```bash
$ bin/rspec spec
```

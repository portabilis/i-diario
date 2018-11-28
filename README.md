# Novo Educação

Portal do professor integrado com o software livre [i-Educar](https://github.com/portabilis/i-educar)

## Instalação

- Instalar o Ruby 2.2.6 (Recomendamos uso de um gerenciador de versões como [Rbenv](https://github.com/rbenv/rbenv) ou [Rvm](https://rvm.io/))
- Instalar a gem Bundler:

```bash
$ gem install bundler
```

- Baixar o novo educação:

```bash
$ git clone https://github.com/portabilis/novo-educacao.gi
```

- Instalar as gems:

```bash
$ cd novo-educacao
$ bundle install
```

- Copiar o exemplo de configurações de banco de dados e configurar:

```bash
$  cp config/database.sample.yml config/database.yml
```

- Criar e configurar o arquivo `config/secrets.yml` conforme o exemplo:

```yaml
development:
  secret_key_base: CHAVE_SECRETA_AQUI # Você pode gerar uma chave usando o comando "bundle exec rake secret"
```

- Criar o banco de dados:

```bash
$ bundle exec rake db:create
$ bundle exec rake db:migrate
```

- Criar uma entidade:

```bash
$ bundle exec rake entity:setup NAME=prefeitura DOMAIN=localhost DATABASE=prefeitura_educacao
```

- Criar um usuário administrador:

```bash
$ bundle exec rails console
```
```ruby
Entity.last.using_connection { User.create!(email: 'admin@domain.com.br', password: '123456789', password_confirmation: '123456789', status: 'actived', kind: 'employee', admin:  true) }
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

_Nota: Após esses primeiros passos, recomendamos que a sincronização rode pelo menos diariamente para manter o Novo Educação atualizado com o i-Educar_

## Rodar os testes

```bash
$ RAILS_ENV=test bundle exec rake db:create
$ RAILS_ENV=test bundle exec rake db:migrate
```

```bash
$ bin/rspec spec
```

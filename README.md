[![Latest Release](https://img.shields.io/github/release/portabilis/i-diario.svg?label=latest%20release)](https://github.com/portabilis/i-diario/releases)

# i-Diário

Portal do professor integrado com o software livre [i-Educar](https://github.com/portabilis/i-educar).

## Comunicação

Acreditamos que o sucesso do projeto depende diretamente da interação clara e objetiva entre os membros da
Comunidade. Por isso, estamos definindo algumas políticas para que estas interações nos ajudem a crescer juntos!
Você pode consultar algumas destas boas práticas em nosso
[código de conduta](https://github.com/portabilis/i-diario/blob/master/CODE_OF_CONDUCT.md).

Além disso, gostamos de meios de comunicação assíncrona, onde não há necessidade de respostas em tempo real. Isso
facilita a produtividade individual dos colaboradores do projeto.

| Canal de comunicação | Objetivos |
|----------------------|-----------|
| [Fórum](https://forum.ieducar.org) | - Tirar dúvidas <br>- Discussões de como instalar a plataforma<br> - Discussões de como usar funcionalidades<br> - Suporte entre membros de comunidade<br> - FAQ da comunidade (sobre o produto e funcionalidades) |
| [Issues do Github](https://github.com/portabilis/i-diario/issues/new/choose) | - Sugestão de novas funcionalidades<br> - Reportar bugs<br> - Discussões técnicas |
| [Telegram](https://t.me/ieducar ) | - Comunicar novidades sobre o projeto<br> - Movimentar a comunidade<br>  - Falar tópicos que **não** demandem discussões profundas |

Qualquer outro grupo de discussão não é reconhecido oficialmente pela comunidade i-Educar e não terá suporte da
Portabilis - mantenedora do projeto.

## Instalação

Há duas formas de fazer a instalação:

- [Instalação utilizando Docker](#Instalação-utilizando-Docker)
- [Instalação em Servidor](#Instalação-em-Servidor-(Testado-no-Ubuntu-18.04))

### Instalação utilizando Docker

> ATENÇÃO: Essa forma de instação tem o objetivo de facilitar demonstrações e desenvolvimento. Não é recomendado
> para ambientes de produção!

Para instalar o projeto execute todos os passos abaixo.

* Clone o repositório:

```bash
git clone https://github.com/portabilis/i-diario.git && cd i-diario
```

* Faça o build das imagens Docker utilizadas no projeto (pode levar alguns minutos) e inicie os containers da
aplicação:

```bash
docker-compose up -d --build
```

* Use o comando `docker-compose logs -f app` para acompanhar o log da aplicação.

* Aguarde a instalação finalizar até algo similar aparecer na tela:

```log
idiario     | => Ctrl-C to shutdown server
idiario     | Puma starting in single mode...
idiario     | * Version 4.3.1 (ruby 2.3.7-p456), codename: Mysterious Traveller
idiario     | * Min threads: 0, max threads: 16
idiario     | * Environment: development
idiario     | * Listening on tcp://0.0.0.0:3000
idiario     | Use Ctrl-C to stop
```

#### Personalizando a instalação via Docker

Você pode criar um arquivo `docker-compose.override.yml` para personalizar sua instalação do i-Diário, mudando as portas
dos serviços ou o mapeamento dos volumes extras para a aplicação.

### Instalação em Servidor (Testado no Ubuntu 18.04)

- Instale o Ruby 2.4.10 (recomendamos uso de um gerenciador de versões como [Rbenv](https://github.com/rbenv/rbenv)
 ou [Rvm](https://rvm.io/))
- Instale o Postgres e faça a configuração em `database.yml`
- Instale o Node.js 12.22.1
- Instale o gerenciador de pacotes [Yarn](https://yarnpkg.com/))
- Instale a biblioteca `libpq-dev`

```bash
sudo apt install libpq-dev
```

- Instale Redis

```bash
sudo apt install redis-server
```

- Instale a gem Bundler:

```bash
gem install bundler -v '1.17.3'
```

- Instale as gems:

```bash
bundle install
```

- Instale as dependencias do projeto

```bash
yarn install
```

- Crie e configure o arquivo `config/secrets.yml` conforme o exemplo:

```yaml
development:
  secret_key_base: CHAVE_SECRETA
  SMTP_ADDRESS: SMTP_ADDRESS
  SMTP_PORT: SMTP_PORT
  SMTP_DOMAIN: SMTP_DOMAIN
  SMTP_USER_NAME: SMTP_USER_NAME
  SMTP_PASSWORD: SMTP_PASSWORD
  NO_REPLY_ADDRESS: NO_REPLY_ADDRESS
  EMAIL_SKIP_DOMAINS: EMAIL_SKIP_DOMAINS
  STUDENT_DOMAIN: STUDENT_DOMAIN
```

_Nota: Você pode gerar uma chave secreta usando o comando `bundle exec rake secret`_

_Nota: Use `EMAIL_SKIP_DOMAINS` para informar domínios (separadas por virgula e sem espaço) para os quais não quer
que o sistema faça envio de emails_

_Nota: Use `STUDENT_DOMAIN` para informar o domínio que vai ser usado para criar as contas de usuarios dos alunos na sincronização. Se não for informado, o checkbox que permite essa funcionalidade na tela de configurações não vai ser apresentado_

- Crie o banco de dados:

```bash
bundle exec rake db:create
bundle exec rake db:migrate
```

- Crie as páginas de erro se baseando nas padrões:

```bash
cp public/404.html.sample public/404.html
cp public/500.html.sample public/500.html
```

- Crie uma entidade:

```bash
bundle exec rake entity:setup NAME=prefeitura DOMAIN=localhost DATABASE=prefeitura_diario
```

- Configure os uploads de arquivos

O i-Diário tem alguns uploads de arquivos, como anexos e foto de perfil.
Foi utilizado as gems [Carrierwave](https://github.com/carrierwaveuploader/carrierwave)
com [carrierwave-aws](https://github.com/sorentwo/carrierwave-aws).

Hoje, se não há configuração para usar a AWS S3, irá salvar os arquivos localmente.

Para usar AWS S3, basta colocar no secrets as seguintes chaves, alterando para valores reais:

```yaml
AWS_ACCESS_KEY_ID: 'xxx'
AWS_SECRET_ACCESS_KEY: 'xxx'
AWS_REGION: 'us-east-1'
AWS_BUCKET: 'bucket_name'
```

Se quiser customizar para onde vai o upload de documentos, caso queira mandar para um lugar diferente das imagens
pode usar as secrets abaixo:

```yaml
DOC_UPLOADER_AWS_ACCESS_KEY_ID: 'xxx'
DOC_UPLOADER_AWS_SECRET_ACCESS_KEY: 'xxx'
DOC_UPLOADER_AWS_REGION: 'us-east-1'
DOC_UPLOADER_AWS_BUCKET: 'bucket_name'
```

Caso você queira usar outro meio de fazer upload de arquivos, recomendamos dar uma olhada no
 [Fog](https://github.com/fog/fog).

O Fog trabalha com essas [opções](https://fog.io/about/provider_documentation.html).

Para adicionar o `fog`, crie o arquivo `Gemfile.plugins`, que irá ter gems customizadas, e coloque a gem
`gem 'fog', '~>1.42.0'`.

Uma vez adicionada a gem `fog`, basta criar um arquivo de configuração em `config/custom_carrierwave.rb`
 e fazer os ajustes para funcionar. Leia atentamente a documentação do `carrierwave` antes de fazer isso.

- Redirecionar os relatórios para outro servidor (opcional)
```yaml
  REPORTS_SERVER_IP: xx.xx.xx.xx
  REPORTS_SERVER_USERNAME: username
  REPORTS_SERVER_DIR: /var/www/relatorios_idiario
```

_Nota: REPORTS_SERVER_DIR deve estar dentro da pasta publica do seu servidor_

* Inicie o servidor:

```bash
bundle exec rails server
```

* Inicie os processos do [sidekiq](#sidekiq)

### Primeiro acesso

* Antes de realizar o primeiro acesso, crie um usuário administrador:

```bash
bundle exec rails console
```

* Crie o usuário administrador, substitua as informações que deseje:

```ruby
Entity.last.using_connection {
  User.create!(
    email: 'admin@domain.com.br',
    password: '123456789',
    password_confirmation: '123456789',
    status: 'active',
    kind: 'employee',
    admin: true,
    first_name: 'Admin'
  )
}
```

Agora você poderá acessar o i-Diário na URL [http://localhost:3000](http://localhost:3000) com as credenciais
fornecidas no passo anterior.

### Sincronização com i-Educar

- Para fazer a sincronização entre i-Educar e i-Diário é necessário estar com o Sidekiq rodando;
- Acessar Configurações > Api de Integraçao e configurar os dados do sincronismo
- Acessar Configurações > Unidades e clicar em **Sincronizar**
- Acessar Calendário letivo, clicar em **Sincronizar** e configurar os calendários
- Acessar Configurações > Api de Integração
  - Existem dois botões nessa tela:
    - Sincronizar: Ao clicar nesse botão, será verificado a ultima data de sincronização e somente vai sincronizar
     os dados inseridos/atualizados/deletados após essa data.
    - Sincronização completa: Esse botão apenas aparece para o usuário administrador e ao clicar nesse botão,
     não vai fazer a verificação de data, sincronizando todos os dados de todos os anos.

_Nota: Após esses primeiros passos, recomendamos que a sincronização rode pelo menos diariamente para manter o
 i-Diário atualizado com o i-Educar_

### Sidekiq

É a ferramenta usada para rodar comandos em background, sem travar o sistema
enquanto ele é usado.

- Processo 1 (Responsável pela sincronização com o i-educar)

```bash
bundle exec sidekiq -q synchronizer_enqueue_next_job -c 1 -d --logfile log/sidekiq.log
```

- Processo 2 (Responsável pelos outros jobs)

```bash
bundle exec sidekiq -c 10 -d --logfile log/sidekiq.log
```

Sempre que for fazer deploy, deve-se parar o sidekiq e depois reiniciá-lo com os
comandos acima.

```bash
ps -ef | grep sidekiq | grep -v grep | awk '{print $2}' | xargs kill -TERM && sleep 20
```

Conhece mais sobre o sidekiq [aqui](https://github.com/mperham/sidekiq).

#### Sidekiq com mais concorrência

Se o município configurado tem muitos envios de faltas e notas para o i-educar,
é possível iniciar vários processos para aumentar a concorrência.

No exemplo abaixo, estamos rodando dois processos do sidekiq.

```bash
bundle exec sidekiq -q exam_posting_1 -c 1 -d --logfile log/sidekiq_exam_posting_1.log
```

```bash
bundle exec sidekiq -q exam_posting_2 -c 1 -d --logfile log/sidekiq_exam_posting_1.log
```

Para funcionar, é necessário adicionar no arquivo `config/secrets.yml` as filas
usadas, separadas por virgula e sem espaço:

```yaml
production:
  EXAM_POSTING_QUEUES: 'exam_posting_1,exam_posting_2'
```

Assim ele vai escolher randomicamente qual a fila irá usar, diminuindo o gargalo
no servidor.

Deve-se tomar cuidado pois quanto mais concorrência, mais irá exigir do
i-educar.

Foi decidido usar a abordagem de vários workers com apenas um de concorrência
para diminuir a carga no i-educar. Então se um professor envia faltas e notas
para o i-educar, ele irá usar uma fila só sequencial. Se outro professor for
enviar, ele irá rodar em outra fila (se o random jogar para essa fila.)

### Executar os testes

```bash
# (Docker) docker-compose exec app RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:create

# (Docker) docker-compose exec app RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake db:migrate
```

```bash
# (Docker) docker-compose exec app bin/rspec spec
bin/rspec spec
```

### Upgrades

### Upgrade para a versão 1.1.0

Nessa atualização a sincronização entre i-Educar e i-Diário foi completamente reestruturada e com isso o i-Diário
 passa a ter dependência da versão **2.1.18** do i-Educar.

Para o upgrade é necessário atualizar o i-Diário para a versão
 [1.1.0](https://github.com/portabilis/i-diario/releases/tag/1.1.0).

* Executar as migrations:

```bash
# (Docker) docker-compose exec app bundle exec rake db:migrate
bundle exec rake db:migrate
```

* Executar a rake task que irá fazer a atualização do banco de dados e executar a sincronização completa em todas
 as entidades:

```bash
# (Docker) docker-compose exec app bundle exec rake upgrade:versions:1_1_0
bundle exec rake upgrade:versions:1_1_0
```

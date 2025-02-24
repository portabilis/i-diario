# Guia de instalação

Você pode instalar o i-Diário utilizando Docker ou diretamente no seu servidor web.

- [Dependências](#dependências)
- [Instalação utilizando Docker](#instalação-utilizando-docker)
- [Instalação em servidor web](#instalação-em-servidor-web)
- [Primeiro acesso](#primeiro-acesso)

## Dependências

Para executar o projeto é necessário a utilização de alguns softwares.

### Servidor

- [Ruby](https://www.ruby-lang.org/)
- [Bundler](https://bundler.io/)
- [Postgres](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [Git](https://git-scm.com/downloads)

### Docker

- [Docker](https://docs.docker.com/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Instalação utilizando Docker

Para instalar o projeto execute **todos os passos** abaixo:

> ATENÇÃO: Essa forma de instalação tem o objetivo de facilitar demonstrações e o desenvolvimento. Não é recomendado
> para ambientes de produção!

Para instalar o projeto execute todos os passos abaixo.

* Clone o repositório:

```bash
git clone https://github.com/portabilis/i-diario.git && cd i-diario
```

Faça o build das imagens Docker utilizadas no projeto e inicie os containers da aplicação (pode levar alguns minutos):

```bash
docker-compose up --build
```

Aguarde a instalação finalizar até algo similar aparecer na tela:

```log
idiario-puma             | * Puma version: 6.5.0 ("Sky's Version")
idiario-puma             | * Ruby version: ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-linux]
idiario-puma             | *  Min threads: 0
idiario-puma             | *  Max threads: 5
idiario-puma             | *  Environment: development
idiario-puma             | *          PID: 1
idiario-puma             | * Listening on http://0.0.0.0:3000
idiario-puma             | Use Ctrl-C to stop
```

#### Personalizando a instalação

Você pode criar um arquivo `docker-compose.override.yml` para personalizar sua instalação do i-Diário.

## Instalação em servidor web

Para instalar o projeto execute **todos os passos** abaixo conectado em seu servidor web:

> Este passo a passo serve para um servidor Ubuntu 22.04 LTS e não tem configurações mínimas de segurança

Configure o bash para evitar interatividade e erros colaterais:

```bash
echo 'export DEBIAN_FRONTEND=noninteractive' >> ~/.bashrc
echo 'export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt' >> ~/.bashrc
source ~/.bashrc

# Fix: https://gist.github.com/devisaah/1489d2f3137e231d3cd82153e7e6bfe0
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
```

Instale as dependências:

```bash
apt update
apt install -y curl wget git build-essential libpq-dev shared-mime-info rbenv postgresql postgresql-contrib redis
```

Instale e configure o OpenSSL, é necessária uma configuração especial devido a versão do Ruby:

```bash
mkdir ~/openssl
cd ~/openssl
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -xzvf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w
./config --prefix=/opt/openssl-1.1 --openssldir=/opt/openssl-1.1
make -j$(nproc)
make install
cd ~/
```

Configure o `rbenv`:

```bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
```

Instale e configure o Ruby, garanta que a versão exibida ao final é a `2.6.6`:

```bash
RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/openssl-1.1" rbenv install 2.6.6
rbenv global 2.6.6
source ~/.bashrc
ruby -v
```

Defina a versão do Bundler:

```bash
gem update --system 3.3.22
gem install bundler -v 2.4.22
```

Inicialize o banco de dados:

```bash
systemctl enable postgresql
systemctl start postgresql
cd /tmp
sudo -u postgres createuser idiario --superuser
sudo -u postgres psql -U postgres -c "ALTER USER idiario WITH PASSWORD 'idiario';"
cd ~
```

Instale o Node, NPM e Yarn, é necessária uma instalação especial devido a versão:

```bash
curl -fsSL https://deb.nodesource.com/setup_12.x | bash -
apt install -y nodejs npm
npm install -g yarn
```

Clone o repositório do i-Diário:

```bash
git clone https://github.com/portabilis/i-diario.git
cd i-diario
```

Instale o i-Diário:

```bash
bundle install
yarn install
```

Configure e copie os arquivos necessários:

```bash
cp config/database.sample.yml config/database.yml
cp public/404.html.sample public/404.html
cp public/500.html.sample public/500.html

echo -e "
development:
  secret_key_base: `bundle exec rails secret`
" > config/secrets.yml
```

Finalize a instalação:

```bash
bundle exec rails db:create
bundle exec rails db:migrate

echo "bundle exec rails entity:setup NAME=idiario DOMAIN=$(hostname -I | awk '{print $1}') DATABASE=idiario" | bash
bundle exec rails entity:admin:create NAME=idiario ADMIN_PASSWORD=A123456789$
```

Após os passos acima, o i-Diário estará completamente instalado e é preciso subir os serviços necessários para o
funcionamento completo do software.

### Execução

Para executar o software, é preciso executar em 3 abas distintas do servidor cada um dos comandos abaixo:

#### Puma

Ativar o Puma para responder na porta 80.

```bash
bundle exec rails server -b 0.0.0.0 -p 80
```

#### Sidekiq (sincronização)

Ativar o Sidekiq para processar a fila de sincronização.

```bash
bundle exec sidekiq -q synchronizer_enqueue_next_job -c 1 --logfile log/sidekiq.log
```

#### Sidekiq

Ativar o Sidekiq para processar as demais filas.

```bash
bundle exec sidekiq -c 10 --logfile log/sidekiq.log
```



### Primeiro acesso

Acesse [http://localhost:3000](http://localhost:3000) ou o IP do seu servidor para fazer o seu primeiro acesso.

O usuário padrão é: `admin` / A senha padrão é: `A123456789$`.

Assim que realizar seu primeiro acesso **não se esqueça de alterar a senha padrão**.

### Sincronização com i-Educar

Para fazer a sincronização entre i-Educar e i-Diário é necessário configurar os dados do ambiente do i-Educar em
`Configurações > API de Integração`.

Após configurada a integração, será exibido dois botões:
- `Sincronizar`: ao clicar neste botão, será somente sincronizado os dados inseridos/atualizados/deletados após a
  última data de sincronização.
- `Sincronização completa`: ao clicar nesse botão, será feita uma sincronização de todos os dados dos últimos 2 anos.
  Este botão apenas é exibido para o usuário `admin`.

_Nota: é recomendada que a sincronização seja executada diariamente para manter o i-Diário atualizado com o i-Educar_

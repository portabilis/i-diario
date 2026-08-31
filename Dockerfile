ARG RUBY_VERSION=2.7.8

# Debian 11 (bullseye) é a única base viável para o Ruby 2.7: não há imagem
# oficial ruby:2.7.x para bookworm e o 2.7 não compila com OpenSSL 3.
# Suporte regular encerrado em 14/08/2024 e LTS em 31/08/2026: a base não recebe
# mais correção de segurança. 2.7.8/bullseye é degrau para o Ruby 3, não destino.
FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG GEM_VERSION=3.3.22
ARG BUNDLER_VERSION=2.4.22

ENV APP_PATH /app
ENV BUNDLE_PATH /box

# Fora de suporte, o bullseye sai dos mirrors principais para o archive.debian.org
# em data não anunciada — build com cache de layer não percebe, build do zero quebra
# no apt-get update. A cascata cobre os três estados possíveis (mirrors servindo tudo;
# archive sem o bullseye-security; archive completo), então o build não depende de
# qual deles é o do dia.
RUN set -e; \
    if ! apt-get update -qq; then \
      sed -i 's|http://deb.debian.org|http://archive.debian.org|g' /etc/apt/sources.list; \
      echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive; \
      apt-get update -qq --allow-releaseinfo-change \
        || { sed -i '/-security/d' /etc/apt/sources.list; \
             apt-get update -qq --allow-releaseinfo-change; }; \
    fi
RUN apt-get install -y \
    build-essential \
    git \
    libpq-dev \
    shared-mime-info \
    curl

# Install Node.js 22 LTS via NodeSource (replaces Debian's outdated Node 10.x)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs

RUN apt-get clean
RUN npm i -g yarn
RUN gem update --system ${GEM_VERSION}
RUN gem install bundler -v ${BUNDLER_VERSION}

RUN mkdir $APP_PATH

WORKDIR $APP_PATH

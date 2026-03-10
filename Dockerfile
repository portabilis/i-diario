ARG RUBY_VERSION=2

FROM ruby:${RUBY_VERSION}-slim-buster

ARG GEM_VERSION=3
ARG BUNDLER_VERSION=2

ENV APP_PATH /app
ENV BUNDLE_PATH /box

# Fix Debian Buster repositories (moved to archive after EOL)
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

RUN apt-get update -qq
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
RUN gem update --system 3.3.22
RUN gem install bundler -v ${BUNDLER_VERSION}

RUN mkdir $APP_PATH

WORKDIR $APP_PATH

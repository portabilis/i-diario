ARG RUBY_VERSION=2.7.8

FROM ruby:${RUBY_VERSION}-slim-bullseye

ARG GEM_VERSION=3.3.22
ARG BUNDLER_VERSION=2.4.22

ENV APP_PATH /app
ENV BUNDLE_PATH /box

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
RUN gem update --system ${GEM_VERSION}
RUN gem install bundler -v ${BUNDLER_VERSION}

RUN mkdir $APP_PATH

WORKDIR $APP_PATH

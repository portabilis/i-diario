ARG RUBY_VERSION=2

FROM ruby:${RUBY_VERSION}-slim-buster

ARG GEM_VERSION=3
ARG BUNDLER_VERSION=2

ENV APP_PATH /app
ENV BUNDLE_PATH /box

RUN apt-get update -qq
RUN apt-get install -y \
    build-essential \
    git \
    libpq-dev \
    nodejs \
    npm \
    shared-mime-info

RUN apt-get clean
RUN npm i -g yarn
RUN gem update --system 3.3.22
RUN gem install bundler -v ${BUNDLER_VERSION}

RUN mkdir $APP_PATH

WORKDIR $APP_PATH

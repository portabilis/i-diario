FROM ruby:2.6.6-slim-buster

ENV APP_PATH /app
ENV BUNDLE_PATH /box

RUN apt-get update -qq
RUN apt-get install -y \
    build-essential \
    libpq-dev nodejs \
    npm \
    git \
    shared-mime-info
RUN npm i -g yarn
RUN gem update --system 3.3.22
RUN mkdir $APP_PATH

WORKDIR $APP_PATH

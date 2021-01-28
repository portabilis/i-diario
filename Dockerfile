FROM ruby:2.4.10-slim-buster

RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs npm git
RUN npm i -g yarn

ENV app /app
RUN mkdir $app
WORKDIR $app

ENV BUNDLE_PATH /box

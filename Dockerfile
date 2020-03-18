FROM ruby:2.3.7-slim-jessie

RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs nodejs-legacy npm git
RUN npm install -g phantomjs-prebuilt

ENV app /app
RUN mkdir $app
WORKDIR $app

ENV BUNDLE_PATH /box

ADD . $app

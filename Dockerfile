FROM ruby:2.2.6

ENV RAILS_ROOT /i-diario
ENV BUNDLE_PATH /bundler

RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs npm nodejs-legacy
RUN npm install -g phantomjs

RUN mkdir $RAILS_ROOT
WORKDIR $RAILS_ROOT
COPY . $RAILS_ROOT
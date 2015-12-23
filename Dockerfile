FROM ruby:2.2.3

RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs npm nodejs-legacy
RUN npm install -g phantomjs

RUN mkdir /app
WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN BUNDLE_JOBS=4 bundle install

ADD . /app

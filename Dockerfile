FROM ruby:2.5.1

ADD Gemfile* /code/

WORKDIR /code

RUN apt-get update
RUN apt-get install -y nodejs postgresql-client

RUN gem install bundler
RUN bundle install

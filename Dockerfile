FROM ruby:2.5.1

ADD Gemfile* /code/

WORKDIR /code

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/postgres.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y nodejs postgresql-client-9.4

RUN gem install bundler
RUN bundle install

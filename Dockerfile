FROM ruby:2.6.3

WORKDIR /code

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/postgres.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get update
RUN apt-get install -y curl nodejs postgresql-client-9.4

RUN gem install bundler -v 1.17.2

ADD Gemfile* /code/
RUN bundle install

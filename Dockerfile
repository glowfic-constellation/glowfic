FROM ruby:3.0.5

WORKDIR /code

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash
RUN apt-get update && apt-get install -y \
    curl \
    nodejs \
    postgresql-client-11 \
    chromium \
  && apt-get clean

ARG bundler_version=2.3.10

RUN gem install bundler -v $bundler_version

ADD Gemfile* /code/
RUN bundler _${bundler_version}_ install --jobs $(nproc)
RUN npm i -g eslint@8
RUN npm i -g stylelint stylelint-config-standard stylelint-declaration-strict-value stylelint-order stylelint-scss

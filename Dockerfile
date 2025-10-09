FROM ruby:3.4.7

WORKDIR /code

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /etc/apt/keyrings/postgresql.asc && \
  echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >> /etc/apt/sources.list.d/nodesource.list
RUN echo "Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 600\n\nPackage: nodejs\nPin: origin deb.debian.org\nPin-Priority: -10" > /etc/apt/preferences.d/nodejs
RUN echo "Package: postgresql* libpq-dev\nPin: origin apt.postgresql.org\nPin-Priority: 600\n\nPackage: postgresql* libpq-dev\nPin: origin deb.debian.org\nPin-Priority: -10" > /etc/apt/preferences.d/postgresql
RUN apt-get update \
  && apt install -y nodejs postgresql-client-16 \
  && apt install -y chromium \
  && apt-get clean

ARG bundler_version=2.6.2

RUN gem install bundler -v $bundler_version

ADD Gemfile* /code/
RUN bundler _${bundler_version}_ install --jobs $(nproc)
RUN npm i -g eslint@9 @stylistic/eslint-plugin@2
RUN npm i -g stylelint stylelint-config-standard stylelint-declaration-strict-value stylelint-order stylelint-scss

RUN git config --global --add safe.directory /code

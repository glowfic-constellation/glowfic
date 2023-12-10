FROM ruby:3.2.2

WORKDIR /code

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /etc/apt/keyrings/postgresql.asc && \
  echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >> /etc/apt/sources.list.d/nodesource.list
RUN apt-get update \
  && apt -t nodistro install -y nodejs \
  && apt -t bookworm-pgdg install -y postgresql-client-14 \
  && apt install -y curl chromium \
  && apt-get clean

ARG bundler_version=2.3.25

RUN gem install bundler -v $bundler_version

ADD Gemfile* /code/
RUN bundler _${bundler_version}_ install --jobs $(nproc)
RUN npm i -g eslint@8
RUN npm i -g stylelint stylelint-config-standard stylelint-declaration-strict-value stylelint-order stylelint-scss

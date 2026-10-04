FROM ruby:3.3-slim AS base

# build-essential compiles native gems (bcrypt, oj, puma); libpq-dev is needed by pg.
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential git libpq-dev libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock* ./

FROM base AS development

RUN bundle install -j5

COPY . .

FROM base AS release

ENV RACK_ENV=production \
    BUNDLE_WITHOUT=development:test

RUN bundle install -j5

COPY . .

RUN chmod 755 bin/setup

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

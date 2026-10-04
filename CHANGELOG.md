# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking

- Generated apps are API-first: the default output changes from HTML to JSON. `natra controller` and `natra scaffold` generate JSON controllers without views, `natra new` serves JSON at `GET /` and no longer creates `app/views/layout.erb`, `app/views/welcome.erb` or `public/`, and `--views` on `controller` now defaults to off. Pass `--views` to get HTML.

### Added

- `natra controller` and `natra scaffold` generate JSON CRUD routes backed by the model: `GET /posts` and `GET /posts/:id` (200), `POST /posts` (201), `PATCH /posts/:id` (200) and `DELETE /posts/:id` (204). They read the JSON request body and accept only the scaffold's fields, the fields passed to `natra controller`, or else the model's columns other than `id` and the timestamps. `natra controller` without a matching model generates a stub controller with a TODO.
- The generated `ApplicationController` defaults to JSON and returns JSON errors: 404 for unknown routes and missing records, 422 with the validation errors for `ActiveRecord::RecordInvalid`, 400 for a malformed request body, and 500 with a generic message (the exception message is added in development only). It adds `json(object, status)` and `json_params` helpers.
- `GET /health` returns `{"status":"ok","database":"ok"}`, or 503 with `"database":"unavailable"` when the database cannot be reached. The Dockerfile installs curl and adds a `HEALTHCHECK`, and `docker-compose.yml` health-checks `web` and `db` and starts `web` once the database is healthy.
- `natra scaffold` writes `spec/requests/<plural>_spec.rb`, covering every route and its success and error statuses. `natra new` writes `spec/requests/application_spec.rb` for `/`, `/health` and unknown routes.
- The generated `spec_helper.rb` loads the app once from `config.ru`, wraps each example in a database_cleaner-active_record transaction, and adds `json_body` and `json_request` helpers.
- `natra new --views` generates the HTML layout, welcome page and `public/favicon.ico`, and serves the welcome page at `GET /`.
- `natra scaffold` accepts `--views` and `--no-migration` and passes them to the controller and model generators.

### Changed

- The HTML controller generated with `--views` routes `DELETE /posts/:id` instead of `DELETE /posts/:id/delete`, and `PATCH` redirects to the record instead of the literal path `/posts/:id`.
- Generated migrations write `create_table :posts, id: :uuid` without a space before the comma, and the generated RuboCop config skips `db/schema.rb`, so a freshly scaffolded app passes RuboCop.
- The development Gemfile no longer pins `parallel` below 2, which was only needed for Ruby 3.2. parallel is now 2.3.0.
- `natra new --redis` adds `gem 'redis', '~> 6.0'` (was `~> 5.0`). redis 6 talks RESP3 by default; the generated `config/redis.yml` and initializer work unchanged.

## [2.0.0] - 2026-10-04

Changes since 0.0.8.

### Added

- `natra service_object NAME` generates a plain Ruby service object in `app/services`.
- `natra new` generates `config/puma.rb` and the Oj initializer, which were in the templates but never copied, and `config/environment.rb` loads `config/initializers`.
- `natra new --redis` adds the `redis` gem to the generated Gemfile.
- GitHub Actions runs the specs on Ruby 3.3 and 3.4 and runs RuboCop. CI fails below 100% line and branch coverage.
- A `.rubocop.yml` for the gem, and specs covering the CLI and every generator.
- This changelog.

### Changed

- natra requires Ruby 3.3 or newer.
- Dependency upgrades: thor 1.x (from 0.20), activesupport 8.1 (the runtime constraint is now `>= 6.1, < 9`), rubocop 1.x (from 0.63), Bundler 2.7, nokogiri 1.19, rack 3.2, rspec 3.13, rake 13.4, guard 2.20, guard-rubocop 1.5 and active_model_serializers 0.10.16, plus their transitive dependencies.
- Coverage uses SimpleCov with branch coverage instead of Coveralls.
- GitHub Actions replaces Travis CI, and Dependabot uses the GitHub-native configuration.
- Generated apps target Ruby 3.3: `ruby '~> 3.3'` in the Gemfile, a `ruby:3.3-slim` Docker image with the build dependencies for pg, and the running Ruby in `.ruby-version` with `--rvm`.
- Generated apps use current gems: ActiveRecord 8.1, pg 1.x, Sinatra 4 with Rack 3, Puma 6.4 or newer, sinatra-activerecord 2, database_cleaner-active_record and amazing_print.
- Generated migrations (`add_extensions` and `natra model`) use `ActiveRecord::Migration[8.1]`, matching the generated Gemfile.
- `natra new` runs `docker compose` instead of `docker-compose`, and the generated `docker-compose.yml` drops the obsolete `version` key, uses `depends_on` and PostgreSQL 17.
- `natra new` only runs `git init` and `git add .` with `--git`, and runs `git init` once.
- The generated `config/database.yml` reads database names from `DEV_DATABASE`, `TEST_DATABASE` and `PROD_DATABASE`, with defaults named after the app.
- The generated `bin/setup` runs rake through `bundle exec`, and the generated README, RuboCop config and spec helper are updated for current tools.

### Removed

- Coveralls, from both the gem and generated apps.
- `tux` from the generated Gemfile. Its last release was in 2011.
- The `natra` gem from the generated Gemfile. Release 0.0.8 pins activesupport 5, which conflicts with ActiveRecord 8.
- Travis CI configuration.

### Fixed

- `natra service_object` failed with "Could not find templates/service.rb.erb" because the generator looked in the wrong template directory.
- `natra service_object` wrote to `app/service` instead of `app/services`.
- `natra service_object` added `use XService` to `config.ru`, which broke every request because a service object is not Rack middleware.
- Migrations generated by `natra model` had no ActiveRecord version, so ActiveRecord 5 and later refused to run them.
- The CLI exited with status 0 on failures because it defined `exit_on_failure` instead of `exit_on_failure?`.
- `bin/natra` had a bash shebang, so running it directly failed.
- The `directory_name` regexp listed `|` twice, which made Ruby print a warning.
- `natra new` passed the app path to `cd` without shell escaping.
- The generated `config/database.yml` used literal `ENV['...']` strings as database names.
- The generated spec helper called `ActiveRecord::Migrator.needs_migration?`, which no longer exists, and the generated welcome page lacked the heading its spec expects.

[Unreleased]: https://github.com/jamesnjuguna0419/natra/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/jamesnjuguna0419/natra/compare/v0.0.8...v2.0.0

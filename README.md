# Natra

[![CI](https://github.com/jamesnjuguna0419/natra/actions/workflows/ci.yml/badge.svg)](https://github.com/jamesnjuguna0419/natra/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/natra.svg)](https://rubygems.org/gems/natra)
[![Downloads](https://img.shields.io/gem/dt/natra.svg)](https://rubygems.org/gems/natra)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

Natra is a command line generator for small Sinatra services. `natra new` creates a JSON API skeleton with ActiveRecord, PostgreSQL, Puma, RSpec, RuboCop, a `/health` endpoint and a Docker setup. Inside that app, `natra model`, `natra controller`, `natra scaffold` and `natra service_object` add models with migrations, JSON CRUD controllers with request specs, and plain Ruby service objects. HTML views are available with `--views`.

## Requirements

- Ruby 3.3 or newer to run natra and the apps it generates.
- PostgreSQL for the generated app's database.
- Docker with Compose v2, only if you want the generated Docker setup. `natra new` runs `docker compose build --pull` as its last step. Without Docker that step prints an error, but the app is still generated and you can run it locally.

## Installation

```sh
gem install natra
```

## Quick start

```sh
natra new my-api
cd my-api
```

### Run with Docker

`secrets.env` holds the database settings for the `web` and `db` containers.

```sh
docker compose run --rm web bin/setup
docker compose up
```

### Run locally

Start PostgreSQL first. Without `DATABASE_URL`, `config/database.yml` uses the databases `development_my_api` and `test_my_api` (override them with `DEV_DATABASE` and `TEST_DATABASE`).

```sh
bundle install
bundle exec rake db:create db:migrate
bundle exec puma -C config/puma.rb
```

Either way the app listens on http://localhost:9292. Run its specs with `bundle exec rspec` after `RACK_ENV=test bundle exec rake db:create db:migrate`.

### Add a resource

```sh
natra scaffold post title:string body:text
bundle exec rake db:migrate
```

Restart Puma, then:

```sh
$ curl -s -X POST localhost:9292/posts -H 'Content-Type: application/json' \
    -d '{"title":"Hello","body":"First post"}'
{"id":"a43585d4-9b1e-4bb5-96b3-966edc9566e0","title":"Hello","body":"First post","created_at":"2026-10-04T19:26:10.670Z","updated_at":"2026-10-04T19:26:10.670Z"}

$ curl -s localhost:9292/posts
[{"id":"a43585d4-9b1e-4bb5-96b3-966edc9566e0","title":"Hello","body":"First post",...}]

$ curl -s -X PATCH localhost:9292/posts/a43585d4-9b1e-4bb5-96b3-966edc9566e0 \
    -H 'Content-Type: application/json' -d '{"title":"Hello again"}'
{"id":"a43585d4-9b1e-4bb5-96b3-966edc9566e0","title":"Hello again",...}

$ curl -s -o /dev/null -w '%{http_code}\n' -X DELETE localhost:9292/posts/a43585d4-9b1e-4bb5-96b3-966edc9566e0
204
```

## The generated API

Every response is JSON. The generated `ApplicationController` sets the content type, provides the `json(object, status = 200)` and `json_params` helpers, and turns errors into JSON responses:

| Status | When | Body |
| --- | --- | --- |
| 400 | The request body is not valid JSON, or not a JSON object | `{"error":"Invalid JSON"}` |
| 404 | Unknown route, or `ActiveRecord::RecordNotFound` | `{"error":"Not found"}` |
| 422 | `ActiveRecord::RecordInvalid`, for example a failed `validates` | `{"errors":{"title":["can't be blank"]}}` |
| 500 | Any other error | `{"error":"Internal server error"}`, plus the exception message in development only. The backtrace goes to the log, never to the client. |

`natra scaffold post title:string body:text` generates these routes:

| Route | Success | Errors |
| --- | --- | --- |
| `GET /posts` | 200, a JSON array ordered by `created_at` | |
| `GET /posts/:id` | 200, the record | 404 |
| `POST /posts` | 201, the created record | 400, 422 |
| `PATCH /posts/:id` | 200, the updated record | 400, 404, 422 |
| `DELETE /posts/:id` | 204, no body | 404 |

Create and update read the JSON request body and only accept the scaffold's fields (`title` and `body` here), so other keys such as `id` are ignored. `natra controller NAME` generates the same routes when `app/models/NAME.rb` exists, accepting the fields you pass (`natra controller post title body`) or, without fields, the model's columns other than `id`, `created_at` and `updated_at`. Without a model it generates a stub controller with a `GET` index and show and a TODO; generate the model, then run `natra controller NAME` again and let it overwrite the stub.

### Health check

`GET /health` runs `SELECT 1` against the database:

```sh
$ curl -s localhost:9292/health
{"status":"ok","database":"ok"}
```

If the database cannot be reached it returns 503 with `{"status":"error","database":"unavailable"}`. The Dockerfile has a `HEALTHCHECK` that calls it with curl, and `docker-compose.yml` health-checks both containers and starts `web` only once PostgreSQL is healthy. `GET /` returns the app name, such as `{"name":"MyApi","status":"ok"}`.

### Request specs

`natra new` writes `spec/requests/application_spec.rb`, which covers `/`, `/health` (including the 503) and unknown routes. `natra scaffold` writes `spec/requests/posts_spec.rb`, which checks every route above with its success and error statuses, using sample values for the fields. The specs use rack-test against `config.ru`, and `spec/spec_helper.rb` wraps each example in a transaction with database_cleaner-active_record and provides `json_body` and `json_request(method, path, payload)`.

### HTML views

The default output is JSON only. To render HTML with erb instead:

- `natra new APP_PATH --views` adds `app/views/layout.erb`, `app/views/welcome.erb` and `public/favicon.ico`, and serves the welcome page at `GET /`.
- `natra controller NAME --views` and `natra scaffold NAME --views` generate HTML routes (index, new, create, show, edit, update and delete, with placeholder views and redirects) instead of the JSON controller, and no request spec.

## Commands

| Command | What it does | Options |
| --- | --- | --- |
| `natra new APP_PATH` | Creates a new Sinatra application in `APP_PATH` | `--views` adds an HTML layout, welcome page and `public/`<br>`--git` runs `git init` and `git add .`<br>`--bundle` runs `bundle install`<br>`--redis` adds the redis gem, `config/redis.yml` and a Redis initializer<br>`--capistrano` runs `cap install`<br>`--rvm` writes `.ruby-version` (the Ruby running natra) and `.ruby-gemset`, and skips `--bundle` |
| `natra model NAME [field:type ...]` | Generates a model and a migration that creates its table | `--no-migration` skips the migration |
| `natra controller NAME [field ...]` | Generates a JSON controller and mounts it in `config.ru`: CRUD routes if the model exists, otherwise a stub | `--views` generates HTML routes and erb views instead |
| `natra scaffold NAME [field:type ...]` | Runs `model` and `controller` for `NAME` and writes a request spec | `--views` generates HTML routes and erb views instead, without a request spec<br>`--no-migration` skips the migration |
| `natra service_object NAME` | Generates a service object in `app/services` | |
| `natra -v`, `natra --version` | Prints the natra version | |
| `natra help [COMMAND]` | Lists the commands, or describes one | |

Run `model`, `controller`, `scaffold` and `service_object` from the root of a generated app.

Naming rules:

- `APP_PATH` is lowercased, and characters other than letters, `-` and `_` are dropped. `natra new My-Blog` creates `my-blog`.
- Fields are written `name:type`, for example `title:string body:text published:boolean`. The type defaults to `string`, so `title` is the same as `title:string`.
- Models are singular (a plural name is singularized with a warning). Controllers and service objects are pluralized: `natra controller post` creates `PostsController`, and `natra service_object payment` creates `PaymentsService`.

## What you get

`natra new blog` creates:

```
blog/
├── .gitignore
├── .rspec
├── .rubocop.yml
├── Dockerfile
├── Gemfile
├── Guardfile
├── README.md
├── Rakefile
├── config.ru
├── docker-compose.yml
├── secrets.env
├── app/
│   ├── controllers/application_controller.rb
│   ├── models/
│   └── services/
├── bin/setup
├── config/
│   ├── database.yml
│   ├── environment.rb
│   ├── puma.rb
│   └── initializers/oj.rb
├── db/
│   ├── migrate/YYYYMMDD0000_add_extensions.rb
│   └── seeds.rb
├── lib/
└── spec/
    ├── requests/application_spec.rb
    ├── spec_helper.rb
    └── support/
```

The Gemfile uses Sinatra 4, ActiveRecord 8.1 through sinatra-activerecord, pg, Puma, Oj, rack-timeout and Scout APM, with RSpec, rack-test, FactoryBot, Faker, DatabaseCleaner, SimpleCov and Guard for tests. The first migration enables the `hstore`, `uuid-ossp` and `pgcrypto` PostgreSQL extensions. The Rakefile loads the sinatra-activerecord tasks, such as `db:create`, `db:migrate`, `db:seed` and `db:create_migration`. `rake db:seed` loads `db/seeds.rb`, which is plain Ruby, and `bin/setup` runs it after migrating.

`natra scaffold post title:string body:text` then creates:

```
app/models/post.rb                          # class Post < ActiveRecord::Base
db/migrate/YYYYMMDDHHMMSS_create_posts.rb   # posts table with a UUID id, title, body and timestamps
app/controllers/posts_controller.rb         # JSON index, show, create, update and delete routes
spec/requests/posts_spec.rb                 # request specs for every route and status
```

It also adds `use PostsController` to `config.ru`.

## Development

Natra is developed on Ruby 3.3.10 (see `.ruby-version`). CI runs on Ruby 3.3, 3.4.3, 3.4.8, 3.4.9 and the latest 3.4.

```sh
bin/setup                    # install dependencies
bundle exec rspec            # run the specs
bundle exec rubocop          # lint
bin/console                  # Pry session with natra loaded
```

SimpleCov measures line and branch coverage and writes a report to `coverage/`. CI requires 100% line and branch coverage. Run `CI=true bundle exec rspec` to apply the same check locally.

To release a new version:

1. Update the version number in `lib/natra/version.rb`.
2. Move the entries under "Unreleased" in [CHANGELOG.md](CHANGELOG.md) to a section for the new version.
3. Commit, then run `bundle exec rake release`. This builds the gem, tags the version, pushes the commit and tag, and pushes the gem to [rubygems.org](https://rubygems.org/gems/natra).

## Changelog

Notable changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jamesnjuguna0419/natra.

1. Open an issue first for larger changes, so the approach can be agreed before you write code.
2. Fork the repository and create a branch from `master`.
3. Make your change and add or update specs for it. If you change what a generator produces, update its spec under `spec/natra/generators/`.
4. Check that `CI=true bundle exec rspec` passes with 100% line and branch coverage, and that `bundle exec rubocop` reports no offenses.
5. Add a line to the "Unreleased" section of [CHANGELOG.md](CHANGELOG.md).
6. Open a pull request that explains what changed and why.

## Code of Conduct

This project is intended to be a safe, welcoming space for collaboration. Everyone interacting in the Natra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md), which is adapted from the [Contributor Covenant](https://www.contributor-covenant.org).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

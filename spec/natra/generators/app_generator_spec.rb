# frozen_string_literal: true

require 'yaml'

RSpec.describe Natra::Generators::AppGenerator, 'natra new' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'creates the application skeleton in a directory named after the app' do
    run_cli('new', 'My-Blog')

    expected = %w[
      config.ru Gemfile Rakefile README.md Dockerfile docker-compose.yml Guardfile secrets.env
      .gitignore .rspec .rubocop.yml bin/setup config/environment.rb config/database.yml config/puma.rb
      config/initializers/oj.rb
      app/controllers/application_controller.rb
      app/models/.gitkeep db/seeds.rb lib/.keep spec/spec_helper.rb
      spec/requests/application_spec.rb spec/support/.keep
    ]
    expect(expected.reject { |file| File.file?(File.join('my-blog', file)) }).to be_empty
    expect(%w[app/services config/initializers db/migrate].map { |dir| File.directory?("my-blog/#{dir}") })
      .to all(be true)
  end

  it 'creates no views or public directory by default' do
    run_cli('new', 'blog')

    expect(File).not_to exist('blog/app/views')
    expect(File).not_to exist('blog/public')
  end

  it 'does not create the optional redis and rvm files by default' do
    run_cli('new', 'blog')

    expect(Dir.glob('blog/{config/redis.yml,config/initializers/redis.rb,.ruby-version,.ruby-gemset}')).to be_empty
    expect(read('blog/Gemfile')).not_to include('redis')
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'rendered templates' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  before { run_cli('new', 'My-Blog') }

  it 'names the databases after the app' do
    secrets = read('my-blog/secrets.env')
    expect(secrets).to include('DEV_DATABASE=development_my_blog', 'TEST_DATABASE=test_my_blog')
    expect(secrets).to include('DATABASE_URL=postgresql://docker:docker@db:5432/development_my_blog?pool=5')
  end

  it 'targets Ruby 3.3 with current gems and no coveralls or tux' do
    gemfile = read('my-blog/Gemfile')
    expect(gemfile).to include("ruby '~> 3.3'", "gem 'pg', '~> 1.5'", "gem 'sinatra', '~> 4.1'", "gem 'simplecov'")
    expect(gemfile).to include("gem 'puma', '~> 8.0'")
    expect(gemfile).not_to match(/coveralls|tux/)
    expect(read('my-blog/Dockerfile')).to start_with('FROM ruby:3.3-slim').and include('libpq-dev')
  end

  it 'reads database names from the environment with defaults named after the app' do
    database = read('my-blog/config/database.yml')
    expect(database).to include("<%= ENV.fetch('DEV_DATABASE', 'development_my_blog') %>")
    expect(database).to include("<%= ENV.fetch('TEST_DATABASE', 'test_my_blog') %>")
  end

  it 'writes a compose file without the obsolete version key' do
    expect(read('my-blog/docker-compose.yml')).to start_with("services:\n")
  end

  it 'pins migrations to the ActiveRecord version in the Gemfile' do
    migration = Dir.glob('my-blog/db/migrate/*_add_extensions.rb').first
    expect(read(migration)).to include('ActiveRecord::Migration[8.1]')
    expect(read('my-blog/Gemfile')).to include("gem 'activerecord', '~> 8.1'")
  end

  it 'titles the README with the app name' do
    expect(read('my-blog/README.md')).to start_with("# my_blog service\n")
  end

  it 'writes a JSON application controller with a health check named after the app' do
    controller = read('my-blog/app/controllers/application_controller.rb')
    expect(controller).to include('set :default_content_type, :json', "json(name: 'MyBlog', status: 'ok')")
    expect(controller).to include("get '/health' do", "connection.select_value('SELECT 1')")
    expect(controller).to include('error ActiveRecord::RecordNotFound', 'error ActiveRecord::RecordInvalid',
                                  'error Sinatra::BadRequest', 'def json(object, code = 200)', 'def json_params')
    expect(controller).not_to include('erb ')
  end

  it 'checks the health endpoint from Docker and waits for a healthy database' do
    expect(read('my-blog/Dockerfile')).to include('curl', 'HEALTHCHECK', 'http://localhost:${PORT:-9292}/health')
    compose = YAML.safe_load(read('my-blog/docker-compose.yml'))
    expect(compose.dig('services', 'web', 'depends_on')).to eq('db' => { 'condition' => 'service_healthy' })
    expect(compose.dig('services', 'web', 'healthcheck', 'test')).to include('http://localhost:9292/health')
    expect(compose.dig('services', 'db', 'healthcheck', 'test').last).to include('pg_isready')
  end

  it 'sets up request specs against config.ru with transactional database cleaning' do
    helper = read('my-blog/spec/spec_helper.rb')
    expect(helper).to include("require 'database_cleaner/active_record'",
                              "Rack::Builder.parse_file(File.expand_path('../config.ru', __dir__))")
    expect(helper).to include('DatabaseCleaner.strategy = :transaction', 'DatabaseCleaner.cleaning { example.run }')
    expect(helper).to include('def json_body', 'def json_request(method, path, payload = {})')
  end

  it 'specs the root and health endpoints' do
    spec = read('my-blog/spec/requests/application_spec.rb')
    expect(spec).to include("get '/health'", "'name' => 'MyBlog'", 'eq(503)')
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'extensions migration' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'is timestamped with the current date' do
    allow(Time).to receive(:now).and_return(Time.new(2026, 10, 4, 15, 30, 0))
    run_cli('new', 'blog')

    expect(Dir.children('blog/db/migrate')).to eq(['202610040000_add_extensions.rb'])
    expect(read('blog/db/migrate/202610040000_add_extensions.rb')).to include('class AddExtensions')
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'shell commands' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'builds the app with docker compose and runs no git commands by default' do
    run_cli('new', 'My-Blog')

    expect(shell_commands.size).to eq(1)
    expect(shell_commands.first[:command].lines.map(&:strip))
      .to eq(['cd my-blog', 'docker compose build --pull'])
  end

  it 'runs git, bundle and capistrano inside the app when asked to' do
    run_cli('new', 'blog', '--git', '--bundle', '--capistrano')

    expected = ['cap install', 'git init .', 'bundle'].map { |command| { command: command, dir: 'blog' } }
    expect(shell_commands[0..2]).to eq(expected)
    expect(shell_commands.size).to eq(4)
    expect(shell_commands.last[:command].lines.map(&:strip))
      .to eq(['cd blog', 'git add .', 'docker compose build --pull'])
  end

  it 'escapes the app path for the shell' do
    run_cli('new', 'my|blog')

    expect(shell_commands.last[:command].lines.first.strip).to eq('cd my\|blog')
  end

  it 'makes bin/setup executable' do
    run_cli('new', 'blog')

    expect(File.stat('blog/bin/setup').mode & 0o777).to eq(0o755)
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'optional files' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'adds redis configuration with --redis' do
    run_cli('new', 'blog', '--redis')

    expect(read('blog/config/redis.yml')).to eq(read(File.join(described_class.source_root, 'config/redis.yml')))
    expect(read('blog/config/initializers/redis.rb')).to include('REDIS = Redis.new')
    expect(read('blog/Gemfile')).to include("gem 'redis', '~> 6.0'\n")
  end

  it 'adds the HTML layout, welcome page and public directory with --views' do
    run_cli('new', 'My-Blog', '--views')

    layout = read('my-blog/app/views/layout.erb')
    expect(layout).to include('<title>MyBlog</title>', '<strong>MyBlog</strong>', '<%= yield %>')
    expect(layout).to include("&copy; #{Time.now.year}")
    expect(read('my-blog/app/views/welcome.erb')).to include('Welcome to the Sinatra Template!')
    expect(File).to exist('my-blog/public/favicon.ico')
    controller = read('my-blog/app/controllers/application_controller.rb')
    expect(controller).to include("set :views, 'app/views'", 'erb :welcome')
    expect(controller).not_to include("json(name: 'MyBlog'")
    expect(read('my-blog/spec/requests/application_spec.rb')).to include("include('text/html')")
  end

  it 'writes rvm files with --rvm and skips bundling even with --bundle' do
    output = run_cli('new', 'blog', '--rvm', '--bundle')

    expect(read('blog/.ruby-version')).to eq("ruby-#{RUBY_VERSION}")
    expect(read('blog/.ruby-gemset')).to eq('blog')
    expect(output).to include("You need to run 'bundle install' manually.")
    expect(shell_commands.map { |call| call[:command] }).not_to include('bundle')
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'when the app already exists' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  before { run_cli('new', 'blog') }

  it 'reports unchanged files as identical on a second run' do
    output = run_cli('new', 'blog')

    expect(output).to match(%r{identical\s+blog/Gemfile})
    expect(output).not_to match(%r{conflict|create\s+blog/Gemfile})
  end

  it 'asks before overwriting a file that was changed and keeps it when declined' do
    File.write('blog/Gemfile', "# edited\n")

    output = run_cli('new', 'blog', answers: 'n')

    expect(output).to match(%r{conflict\s+blog/Gemfile}).and match(%r{skip\s+blog/Gemfile})
    expect(read('blog/Gemfile')).to eq("# edited\n")
  end

  it 'overwrites the changed file when confirmed' do
    File.write('blog/Gemfile', "# edited\n")

    run_cli('new', 'blog', answers: 'y')

    expect(read('blog/Gemfile')).to include("gem 'sinatra'")
  end
end

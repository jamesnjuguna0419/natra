# frozen_string_literal: true

RSpec.describe Natra::Generators::AppGenerator, 'natra new' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'creates the application skeleton in a directory named after the app' do
    run_cli('new', 'My-Blog')

    expected = %w[
      config.ru Gemfile Rakefile README.md Dockerfile docker-compose.yml Guardfile secrets.env
      .gitignore .rspec .rubocop.yml bin/setup config/environment.rb config/database.yml
      app/controllers/application_controller.rb app/views/layout.erb app/views/welcome.erb
      app/models/.gitkeep db/seeds.rb lib/.keep public/favicon.ico spec/spec_helper.rb
      spec/application_controller_spec.rb spec/support/.keep
    ]
    expect(expected.reject { |file| File.file?(File.join('my-blog', file)) }).to be_empty
    expect(%w[app/services config/initializers db/migrate].map { |dir| File.directory?("my-blog/#{dir}") })
      .to all(be true)
  end

  it 'does not create the optional redis and rvm files by default' do
    run_cli('new', 'blog')

    expect(Dir.glob('blog/{config/redis.yml,config/initializers/redis.rb,.ruby-version,.ruby-gemset}')).to be_empty
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'rendered templates' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  before { run_cli('new', 'My-Blog') }

  it 'uses the camel cased app name in the layout and keeps the yield tag' do
    layout = read('my-blog/app/views/layout.erb')
    expect(layout).to include('<title>MyBlog</title>', '<strong>MyBlog</strong>', '<%= yield %>')
    expect(layout).to include("&copy; #{Time.now.year}")
  end

  it 'names the databases after the app' do
    secrets = read('my-blog/secrets.env')
    expect(secrets).to include('DEV_DATABASE=development_my_blog', 'TEST_DATABASE=test_my_blog')
    expect(secrets).to include('DATABASE_URL=postgresql://docker:docker@db:5432/development_my_blog?pool=5')
  end

  it 'titles the README with the app name' do
    expect(read('my-blog/README.md')).to start_with("# my_blog service\n")
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

  it 'builds the app with docker-compose and nothing else by default' do
    run_cli('new', 'My-Blog')

    expect(shell_commands.size).to eq(1)
    expect(shell_commands.first[:command].lines.map(&:strip))
      .to eq(['cd my-blog', 'chmod +x bin/setup', 'git init', 'git add .', 'docker-compose build --pull'])
  end

  it 'runs git, bundle and capistrano inside the app when asked to' do
    run_cli('new', 'blog', '--git', '--bundle', '--capistrano')

    expected = ['cap install', 'git init .', 'bundle'].map { |command| { command: command, dir: 'blog' } }
    expect(shell_commands[0..2]).to eq(expected)
    expect(shell_commands.last[:command]).to include('docker-compose build --pull')
  end
end

RSpec.describe Natra::Generators::AppGenerator, 'optional files' do
  include_context 'in a temp dir'
  include_context 'with stubbed shell commands'

  it 'adds redis configuration with --redis' do
    run_cli('new', 'blog', '--redis')

    expect(read('blog/config/redis.yml')).to eq(read(File.join(described_class.source_root, 'config/redis.yml')))
    expect(read('blog/config/initializers/redis.rb')).to include('REDIS = Redis.new')
  end

  it 'writes rvm files with --rvm and skips bundling even with --bundle' do
    output = run_cli('new', 'blog', '--rvm', '--bundle')

    expect(read('blog/.ruby-version')).to eq('ruby-2.5.3')
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

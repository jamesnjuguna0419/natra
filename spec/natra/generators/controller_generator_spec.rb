# frozen_string_literal: true

RSpec.describe Natra::Generators::ControllerGenerator, 'natra controller' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'creates a RESTful controller for the pluralized resource' do
    run_cli('controller', 'post')

    controller = read('app/controllers/posts_controller.rb')
    expect(controller).to start_with("class PostsController < ApplicationController\n")
    routes = controller.scan(/^\s+(get|post|patch|delete) "([^"]+)"/)
    expect(routes).to eq([%w[get /posts], %w[get /posts/new], %w[post /posts], %w[get /posts/:id],
                          %w[get /posts/:id/edit], %w[patch /posts/:id], %w[delete /posts/:id/delete]])
    expect(controller).to include('erb :"/posts/index.html"', 'erb :"/posts/edit.html"')
  end

  it 'mounts the controller in config.ru after the application controller' do
    run_cli('controller', 'post')

    expect(read('config.ru')).to end_with("run ApplicationController\nuse PostsController\n")
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, 'views' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'creates the views' do
    run_cli('controller', 'post')

    expect(Dir.children('app/views/posts')).to contain_exactly(
      'index.html.erb', 'new.html.erb', 'show.html.erb', 'edit.html.erb'
    )
  end

  it 'skips the views with --no-views' do
    run_cli('controller', 'post', '--no-views')

    expect(File).to exist('app/controllers/posts_controller.rb')
    expect(File).not_to exist('app/views/posts')
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, 'naming' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  { 'BlogPost' => 'camel case', 'blog_post' => 'snake case', 'blog-post' => 'hyphenated' }.each do |name, style|
    it "derives class, file, route and view names from a #{style} name" do
      run_cli('controller', name)

      controller = read('app/controllers/blog_posts_controller.rb')
      expect(controller).to include('class BlogPostsController < ApplicationController', 'get "/blog_posts/new"')
      expect(read('config.ru')).to include("use BlogPostsController\n")
      expect(File).to exist('app/views/blog_posts/index.html.erb')
    end
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, 'when files already exist' do
  include_context 'in a temp dir'

  it 'does not mount the controller twice' do
    create_app_skeleton
    run_cli('controller', 'post')
    output = run_cli('controller', 'post')

    expect(read('config.ru').scan('use PostsController').size).to eq(1)
    expect(output).to match(%r{identical\s+app/controllers/posts_controller\.rb})
  end

  it 'fails outside an app because there is no config.ru' do
    expect do
      expect { run_cli('controller', 'post') }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end.to output(/config\.ru does not appear to exist/).to_stderr
  end
end

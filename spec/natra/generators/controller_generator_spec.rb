# frozen_string_literal: true

RSpec.describe Natra::Generators::ControllerGenerator, 'natra controller for an existing model' do
  include_context 'in a temp dir'

  before do
    create_app_skeleton
    File.write('app/models/post.rb', "class Post < ActiveRecord::Base\nend\n")
  end

  it 'creates JSON CRUD routes backed by the model' do
    run_cli('controller', 'post')

    controller = read('app/controllers/posts_controller.rb')
    expect(controller).to start_with("class PostsController < ApplicationController\n")
    routes = controller.scan(/^\s+(get|post|patch|delete) '([^']+)'/)
    expect(routes).to eq([%w[get /posts], %w[get /posts/:id], %w[post /posts], %w[patch /posts/:id],
                          %w[delete /posts/:id]])
    expect(controller).to include('json Post.order(:created_at)', 'json Post.create!(post_params), 201',
                                  'record.update!(post_params)', 'find_post.destroy!', 'halt 204',
                                  'Post.find(params[:id])')
    expect(controller).not_to include('erb', 'redirect', '/new', '/edit')
  end

  it "permits the model's columns other than id and timestamps" do
    run_cli('controller', 'post')

    expect(read('app/controllers/posts_controller.rb'))
      .to include('json_params.slice(*(Post.column_names - %w(id created_at updated_at)))')
  end

  it 'permits only the given fields' do
    run_cli('controller', 'post', 'title:string', 'body:text')

    expect(read('app/controllers/posts_controller.rb')).to include("json_params.slice('title', 'body')")
  end

  it 'mounts the controller in config.ru after the application controller' do
    run_cli('controller', 'post')

    expect(read('config.ru')).to end_with("run ApplicationController\nuse PostsController\n")
  end

  it 'creates no views' do
    run_cli('controller', 'post')

    expect(Dir.children('app/views')).to be_empty
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, 'natra controller without a model' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'creates a JSON stub with a TODO explaining how to get CRUD routes' do
    run_cli('controller', 'post', 'title')

    controller = read('app/controllers/posts_controller.rb')
    expect(controller).to start_with("class PostsController < ApplicationController\n")
    expect(controller).to include('# TODO: There is no Post model yet', 'natra model post',
                                  'rerun `natra controller post` and let it overwrite')
    expect(controller.scan(/^\s+(get|post|patch|delete) '([^']+)'/)).to eq([%w[get /posts], %w[get /posts/:id]])
    expect(controller).to include('json []', 'not_found')
    expect(read('config.ru')).to include("use PostsController\n")
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, '--views' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'creates HTML routes and erb views' do
    run_cli('controller', 'post', '--views')

    controller = read('app/controllers/posts_controller.rb')
    routes = controller.scan(/^\s+(get|post|patch|delete) '([^']+)'/)
    expect(routes).to eq([%w[get /posts], %w[get /posts/new], %w[post /posts], %w[get /posts/:id],
                          %w[get /posts/:id/edit], %w[patch /posts/:id], %w[delete /posts/:id]])
    expect(controller).to include('set :default_content_type, :html', "erb :'posts/index.html'",
                                  "redirect \"/posts/\#{params[:id]}\"")
    expect(Dir.children('app/views/posts')).to contain_exactly(
      'index.html.erb', 'new.html.erb', 'show.html.erb', 'edit.html.erb'
    )
  end
end

RSpec.describe Natra::Generators::ControllerGenerator, 'naming' do
  include_context 'in a temp dir'

  before do
    create_app_skeleton
    File.write('app/models/blog_post.rb', "class BlogPost < ActiveRecord::Base\nend\n")
  end

  { 'BlogPost' => 'camel case', 'blog_post' => 'snake case', 'blog-post' => 'hyphenated' }.each do |name, style|
    it "derives class, file, route and model names from a #{style} name" do
      run_cli('controller', name)

      controller = read('app/controllers/blog_posts_controller.rb')
      expect(controller).to include('class BlogPostsController < ApplicationController', "get '/blog_posts/:id'",
                                    'BlogPost.find(params[:id])', 'def blog_post_params')
      expect(read('config.ru')).to include("use BlogPostsController\n")
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

  it 'replaces the stub with CRUD routes when confirmed once the model exists' do
    create_app_skeleton
    run_cli('controller', 'post')
    File.write('app/models/post.rb', "class Post < ActiveRecord::Base\nend\n")
    run_cli('controller', 'post', answers: 'y')

    controller = read('app/controllers/posts_controller.rb')
    expect(controller).to include('Post.create!')
    expect(controller).not_to include('TODO')
  end

  it 'fails outside an app because there is no config.ru' do
    expect do
      expect { run_cli('controller', 'post') }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end.to output(/config\.ru does not appear to exist/).to_stderr
  end
end

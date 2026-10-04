# frozen_string_literal: true

RSpec.describe Natra::Generators::ScaffoldGenerator, 'natra scaffold' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'generates the model, migration and JSON controller for a resource' do
    run_cli('scaffold', 'BlogPost', 'title', 'body:text')

    expect(read('app/models/blog_post.rb')).to start_with('class BlogPost < ActiveRecord::Base')
    migration = read(Dir.glob('db/migrate/*_create_blog_posts.rb').fetch(0))
    expect(migration).to include('create_table :blog_posts', 't.string :title', 't.text :body')
    controller = read('app/controllers/blog_posts_controller.rb')
    expect(controller).to include('class BlogPostsController', "json_params.slice('title', 'body')")
    expect(read('config.ru')).to include("use BlogPostsController\n")
    expect(Dir.children('app/views')).to be_empty
  end

  it 'uses a singular model and a plural controller for a plural name' do
    output = run_cli('scaffold', 'posts')

    expect(output).to include("using the singular 'post' instead")
    expect(File).to exist('app/models/post.rb')
    expect(read('app/controllers/posts_controller.rb')).to include('Post.column_names')
  end

  it 'passes --views to the controller generator and skips the request spec' do
    run_cli('scaffold', 'post', 'title', '--views')

    expect(read('app/controllers/posts_controller.rb')).to include("erb :'posts/index.html'")
    expect(Dir.children('app/views/posts').size).to eq(4)
    expect(File).not_to exist('spec/requests')
  end

  it 'passes --no-migration to the model generator' do
    run_cli('scaffold', 'post', 'title', '--no-migration')

    expect(File).to exist('app/models/post.rb')
    expect(Dir.children('db/migrate')).to be_empty
    expect(read('app/controllers/posts_controller.rb')).to include("json_params.slice('title')")
  end
end

RSpec.describe Natra::Generators::ScaffoldGenerator, 'request spec' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'covers every endpoint and status with sample values for the fields' do
    run_cli('scaffold', 'BlogPost', 'title', 'body:text', 'views:integer', 'tagline:inet')

    spec = read('spec/requests/blog_posts_spec.rb')
    expect(spec).to include("RSpec.describe '/blog_posts' do", 'BlogPost.create!(attributes)')
    expect(spec).to include("let(:attributes) { { 'title' => 'Example title', 'body' => 'Example body', " \
                            "'views' => 1, 'tagline' => 'Example tagline' } }")
    %w[GET POST PATCH DELETE].each { |verb| expect(spec).to include("describe '#{verb} /blog_posts") }
    %w[200 201 204 400 404 422].each { |status| expect(spec).to include("eq(#{status})") }
    expect(spec).to include("'title' => 'Updated title'", "record.reload.title).to eq('Updated title')")
    expect(spec).to include('allow_any_instance_of(BlogPost).to receive(:valid?)', "'{\"oops\"'")
  end

  it 'updates with all the attributes when there is no string field' do
    run_cli('scaffold', 'counter', 'value:integer', 'enabled:boolean')

    spec = read('spec/requests/counters_spec.rb')
    expect(spec).to include("let(:attributes) { { 'value' => 1, 'enabled' => true } }")
    expect(spec).to include("json_request(:patch, \"/counters/\#{record.id}\", attributes)")
    expect(spec).not_to include('Updated')
  end

  it 'uses empty attributes without fields' do
    run_cli('scaffold', 'post')

    expect(read('spec/requests/posts_spec.rb')).to include('let(:attributes) { {} }')
  end
end

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

  it 'passes --views to the controller generator' do
    run_cli('scaffold', 'post', 'title', '--views')

    expect(read('app/controllers/posts_controller.rb')).to include("erb :'posts/index.html'")
    expect(Dir.children('app/views/posts').size).to eq(4)
  end

  it 'passes --no-migration to the model generator' do
    run_cli('scaffold', 'post', 'title', '--no-migration')

    expect(File).to exist('app/models/post.rb')
    expect(Dir.children('db/migrate')).to be_empty
    expect(read('app/controllers/posts_controller.rb')).to include("json_params.slice('title')")
  end
end

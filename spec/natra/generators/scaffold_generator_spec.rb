# frozen_string_literal: true

RSpec.describe Natra::Generators::ScaffoldGenerator, 'natra scaffold' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'generates the model, migration, controller and views for a resource' do
    run_cli('scaffold', 'BlogPost', 'title', 'body:text')

    expect(read('app/models/blog_post.rb')).to start_with('class BlogPost < ActiveRecord::Base')
    migration = read(Dir.glob('db/migrate/*_create_blog_posts.rb').fetch(0))
    expect(migration).to include('create_table :blog_posts', 't.string :title', 't.text :body')
    expect(read('app/controllers/blog_posts_controller.rb')).to include('class BlogPostsController')
    expect(read('config.ru')).to include("use BlogPostsController\n")
    expect(Dir.children('app/views/blog_posts').size).to eq(4)
  end

  it 'uses a singular model and a plural controller for a plural name' do
    output = run_cli('scaffold', 'posts')

    expect(output).to include("using the singular 'post' instead")
    expect(File).to exist('app/models/post.rb')
    expect(File).to exist('app/controllers/posts_controller.rb')
  end
end

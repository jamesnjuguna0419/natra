# frozen_string_literal: true

RSpec.describe Natra::Generators::ModelGenerator, 'natra model' do
  include_context 'in a temp dir'

  before do
    create_app_skeleton
    allow(Time).to receive(:now).and_return(Time.utc(2026, 10, 4, 15, 30, 7))
  end

  it 'creates the model class' do
    run_cli('model', 'post')

    expect(read('app/models/post.rb')).to eq("class Post < ActiveRecord::Base\nend\n")
  end

  it 'creates a timestamped migration with the given columns, defaulting to string' do
    run_cli('model', 'post', 'title', 'body:text', 'views:integer')

    migration = read('db/migrate/20261004153007_create_posts.rb')
    expect(migration).to include('class CreatePosts < ActiveRecord::Migration[8.1]', 'create_table :posts, id: :uuid')
    columns = migration.scan(/^\s+t\.\w+ :\w+$/).map(&:strip)
    expect(columns).to eq(['t.string :title', 't.text :body', 't.integer :views'])
    expect(migration).to include('t.timestamps null: false')
  end

  it 'skips the migration with --no-migration' do
    run_cli('model', 'post', '--no-migration')

    expect(File).to exist('app/models/post.rb')
    expect(Dir.children('db/migrate')).to be_empty
  end
end

RSpec.describe Natra::Generators::ModelGenerator, 'naming' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  {
    'BlogPost' => 'camel case', 'blog_post' => 'snake case', 'blog-post' => 'hyphenated'
  }.each do |name, style|
    it "derives class, file and table names from a #{style} name" do
      run_cli('model', name)

      expect(read('app/models/blog_post.rb')).to start_with('class BlogPost < ActiveRecord::Base')
      migration = Dir.glob('db/migrate/*_create_blog_posts.rb').first
      expect(read(migration)).to include('class CreateBlogPosts', 'create_table :blog_posts')
    end
  end

  it 'singularizes a plural name and warns about it' do
    output = run_cli('model', 'people')

    expect(output).to include("The model name 'people' was recognized as a plural, using the singular 'person'")
    expect(read('app/models/person.rb')).to start_with('class Person ')
    expect(Dir.glob('db/migrate/*')).to contain_exactly(match(/\d{14}_create_people\.rb\z/))
  end
end

RSpec.describe Natra::Generators::ModelGenerator, 'when the model already exists' do
  include_context 'in a temp dir'

  before do
    create_app_skeleton
    run_cli('model', 'post')
  end

  it 'does not create a second migration' do
    allow(Time).to receive(:now).and_return(Time.now + 60)
    output = run_cli('model', 'post')

    expect(Dir.children('db/migrate').size).to eq(1)
    expect(output).to match(%r{identical\s+app/models/post\.rb})
    expect(output).to match(%r{identical\s+db/migrate/\d{14}_create_posts\.rb})
  end
end

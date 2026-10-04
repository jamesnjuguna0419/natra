# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
require_relative '../config/environment'
require 'rack/test'
require 'capybara/rspec'
require 'capybara/dsl'

ActiveRecord::Migration.check_all_pending!

ActiveRecord::Base.logger = nil

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.include Rack::Test::Methods
  config.include Capybara::DSL
  DatabaseCleaner.strategy = :truncation

  config.before do
    DatabaseCleaner.clean
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.order = :defined
end

def app
  Rack::Builder.parse_file('config.ru')
end

Capybara.app = app

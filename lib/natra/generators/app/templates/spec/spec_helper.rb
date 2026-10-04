# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
require_relative '../config/environment'
require 'rack/test'
require 'database_cleaner/active_record'

ActiveRecord::Migration.check_all_pending!

ActiveRecord::Base.logger = nil

# Faker's locale files take seconds to parse. Load them now so the first request
# that needs a translation does not run into Rack::Timeout.
I18n.backend.eager_load!

APP = Rack::Builder.parse_file(File.expand_path('../config.ru', __dir__))

module RequestHelpers
  def app
    APP
  end

  def json_body
    Oj.load(last_response.body)
  end

  def json_request(method, path, payload = {})
    body = payload.is_a?(String) ? payload : Oj.dump(payload, mode: :compat)
    custom_request(method.to_s.upcase, path, body, 'CONTENT_TYPE' => 'application/json')
  end
end

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.include Rack::Test::Methods
  config.include RequestHelpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  config.order = :defined
end

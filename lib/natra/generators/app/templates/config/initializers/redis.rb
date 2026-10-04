# frozen_string_literal: true

require 'yaml'

# Redis Configuration
unless ENV.fetch('RACK_ENV') == 'test'
  redis_settings = YAML.load_file('config/redis.yml').fetch(ENV.fetch('RACK_ENV'))
  REDIS = Redis.new(**redis_settings.compact.transform_keys(&:to_sym))
end

# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'
require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV'))
require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string'
require_all 'config/initializers'
require './app/controllers/application_controller'
require_all 'app'

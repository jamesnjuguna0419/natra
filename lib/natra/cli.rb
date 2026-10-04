# frozen_string_literal: true

require 'thor'
module Natra
  # Entry point for the natra executable: maps commands onto generators.
  class CLI < Thor
    desc '-v', 'Show Natra version number'
    map %w[-v --version] => :version

    def version
      say "Natra #{Natra::VERSION}"
    end

    register Natra::Generators::AppGenerator, 'new', 'new APP_PATH', 'Creates a new Sinatra application'
    register Natra::Generators::ModelGenerator, 'model', 'model NAME', 'Generate a model'
    register Natra::Generators::ControllerGenerator, 'controller', 'controller NAME', 'Generate a controller'
    register Natra::Generators::ScaffoldGenerator, 'scaffold', 'scaffold NAME',
             'Generate a model with its JSON CRUD controller'
    register Natra::Generators::ServiceGenerator, 'service_object', 'service_object NAME', 'Generate a service object'

    def self.exit_on_failure?
      true
    end
  end
end

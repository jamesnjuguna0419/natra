# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'
module Natra
  module Generators
    # Generates a model with its JSON controller (natra scaffold).
    class ScaffoldGenerator < Thor::Group
      include Thor::Actions

      desc 'Generate an ActiveRecord model with its JSON CRUD controller'
      argument :name, type: :string, desc: 'Name of the model'
      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      class_option :views, type: :boolean, default: false, desc: 'Generate erb views and HTML routes instead of JSON'
      class_option :migration, type: :boolean, default: true, desc: 'Generate migration for model'

      def create_model
        ModelGenerator.new([name, *attributes], options).invoke_all
      end

      def create_controller
        ControllerGenerator.new([name, *attributes], options).invoke_all
      end
    end
  end
end

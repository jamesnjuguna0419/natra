# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'
module Natra
  module Generators
    # Generates a JSON controller, or an HTML one with views (natra controller).
    class ControllerGenerator < Thor::Group
      include Thor::Actions

      attr_reader :controller_name, :class_name, :file_name, :model_name, :model_class, :permitted_attributes

      desc 'Generate a JSON CRUD controller for a model, or an HTML controller with views'
      argument :name, type: :string, desc: 'Name of the controller'
      argument :attributes, type: :array, default: [], banner: 'field[:type] field[:type]'

      class_option :views, type: :boolean, default: false, desc: 'Generate erb views and HTML routes instead of JSON'

      def self.source_root
        File.dirname(__FILE__)
      end

      def setup
        @controller_name      = name.pluralize.underscore
        @class_name           = "#{controller_name.camel_case}Controller"
        @file_name            = class_name.underscore
        @model_name           = controller_name.singularize
        @model_class          = model_name.camel_case
        @permitted_attributes = attributes.map { |attribute| attribute.split(':').first }
      end

      def create_controller
        template "templates/#{controller_template}.rb.erb", File.join('app/controllers', "#{file_name}.rb")
        insert_into_file 'config.ru', "use #{class_name}\n", after: "run ApplicationController\n"
      end

      def create_views
        return unless options[:views]

        directory 'templates/views', File.join('app/views', controller_name.to_s)
      end

      private

      def controller_template
        return 'html_controller' if options[:views]

        File.exist?(File.join(destination_root, 'app/models', "#{model_name}.rb")) ? 'controller' : 'stub_controller'
      end
    end
  end
end

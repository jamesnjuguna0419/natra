# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'
module Natra
  module Generators
    # Generates a plain Ruby service object.
    class ServiceGenerator < Thor::Group
      include Thor::Actions
      attr_reader :service_name, :class_name, :file_name

      desc 'Generate a Service Object'
      argument :name, type: :string, desc: 'Name of the Service Object'

      def self.source_root
        File.dirname(__FILE__)
      end

      def setup
        @service_name = name.pluralize.underscore
        @class_name      = "#{service_name.camel_case}Service"
        @file_name       = class_name.underscore
      end

      def create_service
        template 'template/service.rb.erb', File.join('app/service', "#{file_name}.rb")
        insert_into_file 'config.ru', "use #{class_name}\n", after: "run ApplicationController\n"
      end
    end
  end
end

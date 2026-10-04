# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'
module Natra
  module Generators
    # Generates a model with its JSON controller and request spec (natra scaffold).
    class ScaffoldGenerator < Thor::Group
      include Thor::Actions

      STRING_TYPES = %w[string text citext].freeze
      SAMPLE_VALUES = {
        'integer' => '1', 'bigint' => '1', 'float' => '1.5', 'decimal' => "'1.5'", 'boolean' => 'true',
        'date' => "'2026-01-01'", 'datetime' => "'2026-01-01T00:00:00.000Z'",
        'timestamp' => "'2026-01-01T00:00:00.000Z'", 'json' => "{ 'key' => 'value' }",
        'jsonb' => "{ 'key' => 'value' }", 'uuid' => "'00000000-0000-0000-0000-000000000001'"
      }.freeze

      desc 'Generate an ActiveRecord model with its JSON CRUD controller and request spec'
      argument :name, type: :string, desc: 'Name of the model'
      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      class_option :views, type: :boolean, default: false, desc: 'Generate erb views and HTML routes instead of JSON'
      class_option :migration, type: :boolean, default: true, desc: 'Generate migration for model'

      def self.source_root
        File.dirname(__FILE__)
      end

      def create_model
        ModelGenerator.new([name, *attributes], options).invoke_all
      end

      def create_controller
        ControllerGenerator.new([name, *attributes], options).invoke_all
      end

      def create_request_spec
        return if options[:views]

        template 'templates/request_spec.rb.erb', File.join('spec/requests', "#{controller_name}_spec.rb")
      end

      private

      def controller_name
        name.pluralize.underscore
      end

      def model_class
        controller_name.singularize.camel_case
      end

      def fields
        attributes.map do |attribute|
          field, type = attribute.split(':')
          { name: field, type: type || 'string' }
        end
      end

      def attributes_literal
        pairs = fields.map { |field| "'#{field[:name]}' => #{sample_value(field)}" }
        pairs.empty? ? '{}' : "{ #{pairs.join(', ')} }"
      end

      def sample_value(field)
        SAMPLE_VALUES.fetch(field[:type]) { "'Example #{field[:name]}'" }
      end

      def update_field
        fields.find { |field| STRING_TYPES.include?(field[:type]) }&.fetch(:name)
      end
    end
  end
end

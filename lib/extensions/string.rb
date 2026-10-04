# frozen_string_literal: true

module Natra
  module Extensions
    # Naming helpers mixed into String for turning user input into Ruby names.
    module String
      def camel_case
        return gsub(/^./, &:capitalize) unless match(/[_-]/)

        altered_self = downcase.capitalize
        altered_self.scan(/[_-][a-zA-Z]/).each { |match| altered_self.gsub!(match, match[1].upcase) }
        altered_self
      end

      def camel_case!
        replace camel_case
      end

      def directory_name
        downcase.gsub(/[^a-z|_-]/, '')
      end

      def file_name
        gsub(/[-| ]/, '_')
          .gsub(/([A-Z]+|[A-Z][a-z])/) { |x| "_#{x}" }
          .sub(/^_/, '')
          .gsub(/_{2,}+/, '_')
          .downcase
      end

      def file_name!
        replace file_name
      end
    end
  end
end

String.include(Natra::Extensions::String)

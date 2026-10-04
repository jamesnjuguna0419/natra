# frozen_string_literal: true

module Natra
  # Versions written into generated apps, chosen from the Ruby running natra.
  # ActiveRecord 8, pg 1.7 and redis 6 need Ruby 3.2, so Ruby 3.0 and 3.1 get
  # the newest releases that still support them.
  module Versions
    module_function

    def ruby_minor(ruby = RUBY_VERSION)
      ruby[/\A\d+\.\d+/]
    end

    def current?(ruby = RUBY_VERSION)
      Gem::Version.new(ruby) >= Gem::Version.new('3.2')
    end

    def activerecord(ruby = RUBY_VERSION)
      current?(ruby) ? '8.1' : '7.1'
    end

    def pg(ruby = RUBY_VERSION)
      current?(ruby) ? '1.7' : '1.6'
    end

    def redis(ruby = RUBY_VERSION)
      current?(ruby) ? '6.0' : '5.4'
    end
  end
end

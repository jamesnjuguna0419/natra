# frozen_string_literal: true

class AddExtensions < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'hstore'
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
  end
end

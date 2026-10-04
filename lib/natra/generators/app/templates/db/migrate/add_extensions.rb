# frozen_string_literal: true

class AddExtensions < ActiveRecord::Migration[<%= Natra::Versions.activerecord %>]
  def change
    enable_extension 'hstore'
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
  end
end

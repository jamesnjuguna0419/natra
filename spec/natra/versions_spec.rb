# frozen_string_literal: true

RSpec.describe Natra::Versions do
  it 'keeps the major and minor of the Ruby version' do
    expect(described_class.ruby_minor('3.4.9')).to eq('3.4')
    expect(described_class.ruby_minor).to eq(RUBY_VERSION[/\A\d+\.\d+/])
  end

  it 'uses ActiveRecord 8.1, pg 1.7 and redis 6 from Ruby 3.2' do
    %w[3.2.0 3.3.10 3.4.9].each do |ruby|
      expect([described_class.activerecord(ruby), described_class.pg(ruby), described_class.redis(ruby)])
        .to eq(%w[8.1 1.7 6.0])
    end
  end

  it 'falls back to ActiveRecord 7.1, pg 1.6 and redis 5.4 on Ruby 3.0 and 3.1' do
    %w[3.0.6 3.1.3].each do |ruby|
      expect([described_class.activerecord(ruby), described_class.pg(ruby), described_class.redis(ruby)])
        .to eq(%w[7.1 1.6 5.4])
    end
  end
end

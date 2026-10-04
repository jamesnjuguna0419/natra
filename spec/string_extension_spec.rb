# frozen_string_literal: true

require 'open3'
require_relative 'spec_helper'
require_relative '../lib/extensions/string'

RSpec.describe String, '#camel_case' do
  it 'should ignore an already camel cased string' do
    expect('MyApp'.camel_case).to eq('MyApp')
  end

  it 'should capitalize an all lower case string' do
    expect('myapp'.camel_case).to eq('Myapp')
  end

  it 'should camel case a lower case string with underscores' do
    expect('my_app'.camel_case).to eq('MyApp')
  end

  it 'should camel case a lower case string with hyphens' do
    expect('my-app'.camel_case).to eq('MyApp')
  end

  it 'should camel case an uppercase string with underscores' do
    expect('MY_APP'.camel_case).to eq('MyApp')
  end

  it 'should camel case an uppercase string with hyphens' do
    expect('MY-APP'.camel_case).to eq('MyApp')
  end

  it 'should camel case a string with a hyphen preceding a capital letter' do
    expect('my_App'.camel_case).to eq('MyApp')
  end
end

RSpec.describe String, '#file_name' do
  it 'should underscore a camel cased string' do
    expect('MyApp'.file_name).to eq('my_app')
  end

  it 'should underscore a hypenated string' do
    expect('my-app'.file_name).to eq('my_app')
  end

  it 'should ignore an already underscored string' do
    expect('my_app'.file_name).to eq('my_app')
  end

  it 'should_underscore_a_string_with_a_hyphen_preceding_a_capital_letter' do
    expect('my_App'.file_name).to eq('my_app')
  end
end

RSpec.describe String, 'bang methods' do
  it 'camel cases the receiver in place' do
    name = +'blog_post'
    name.camel_case!
    expect(name).to eq('BlogPost')
  end

  it 'underscores the receiver in place' do
    name = +'MyApp'
    name.file_name!
    expect(name).to eq('my_app')
  end
end

RSpec.describe String, '#directory_name' do
  it 'should allow dashes in directory names, but not in filenames' do
    expect('my-App'.directory_name).to eq('my-app')
    expect('my-App'.file_name).to eq('my_app')
  end

  it 'keeps only lowercase letters, hyphens and underscores' do
    expect('My App 2.0!'.directory_name).to eq('myapp')
    expect('my_cool-App'.directory_name).to eq('my_cool-app')
  end

  it 'compiles without regexp warnings' do
    path = File.expand_path('../lib/extensions/string.rb', __dir__)
    _out, err, = Open3.capture3(RbConfig.ruby, '-wc', path)
    expect(err).not_to match(/character class/)
  end
end

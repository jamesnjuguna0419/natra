# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'natra/version'

Gem::Specification.new do |spec|
  spec.name          = 'natra'
  spec.version       = Natra::VERSION
  spec.authors       = ['Thiru Njuguna']
  spec.email         = ['thirunjuguna@outlook.com']

  spec.summary       = 'Natra generate a light weight sinatra application'
  spec.description   = 'Natra generate a light weight sinatra application.It\'s ideal for building containerized api services with postgres database'
  spec.homepage      = 'https://github.com/thirunjuguna/natra'
  spec.license       = 'MIT'
  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/thirunjuguna/natra'
    spec.metadata['changelog_uri'] = 'https://github.com/thirunjuguna/natra'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.executables = ['natra']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_runtime_dependency('activesupport', '>= 5', '< 7')
  spec.add_runtime_dependency('thor', '>= 0.18', '< 2.0')
end

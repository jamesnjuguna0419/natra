# frozen_string_literal: true

require 'fileutils'
require 'stringio'
require 'tmpdir'

# Helpers for running natra generators in a throwaway directory.
module GeneratorHelpers
  # Runs the example inside a fresh temp directory and removes it afterwards.
  def within_tmpdir(&)
    Dir.mktmpdir('natra-spec') { |dir| Dir.chdir(dir, &) }
  end

  # Invokes the CLI the same way bin/natra does and returns what it printed.
  def run_cli(*args)
    capture_stdout { Natra::CLI.start(args.flatten.map(&:to_s)) }
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  # The minimum a generated app needs for the model/controller/service generators.
  def create_app_skeleton
    FileUtils.mkdir_p(%w[app/controllers app/models app/services app/views db/migrate])
    File.write('config.ru', "require './config/environment'\nrun ApplicationController\n")
  end

  def read(path)
    File.read(path)
  end
end

RSpec.configure do |config|
  config.include GeneratorHelpers
end

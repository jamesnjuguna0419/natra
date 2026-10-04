# frozen_string_literal: true

require 'fileutils'
require 'stringio'
require 'tmpdir'

# Helpers for running natra generators in a throwaway directory.
module GeneratorHelpers
  # Runs the example inside a fresh temp directory and removes it afterwards.
  def within_tmpdir(&block)
    Dir.mktmpdir('natra-spec') { |dir| Dir.chdir(dir, &block) }
  end

  # Invokes the CLI the same way bin/natra does and returns what it printed.
  # `answers` reply, in order, to Thor's prompts (e.g. "Overwrite file?"); an
  # unexpected prompt fails the spec instead of waiting on the terminal.
  def run_cli(*args, answers: [])
    pending_answers = Array(answers).dup
    allow(Thor::LineEditor).to receive(:readline) do |prompt, *|
      pending_answers.shift || raise("unexpected prompt: #{prompt}")
    end
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

RSpec.shared_context 'in a temp dir' do
  around { |example| within_tmpdir(&example) }
end

# `natra new` shells out (git, bundle, cap, docker compose), either directly or
# through Thor's `run`, which calls `system` too. Record those commands instead
# of running them so specs never touch the network or Docker.
RSpec.shared_context 'with stubbed shell commands' do
  let(:shell_commands) { [] }

  before do
    # no_commands stops Thor::Group from registering the stub as a generator step.
    Natra::Generators::AppGenerator.no_commands do
      allow_any_instance_of(Natra::Generators::AppGenerator).to receive(:system) do |_generator, command|
        shell_commands << { command: command, dir: File.basename(Dir.pwd) }
        true
      end
    end
  end
end

RSpec.configure do |config|
  config.include GeneratorHelpers
end

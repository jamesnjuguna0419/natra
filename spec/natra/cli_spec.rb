# frozen_string_literal: true

RSpec.describe Natra::CLI, 'version' do
  it 'prints the version for -v and --version' do
    expect(run_cli('-v')).to eq("Natra #{Natra::VERSION}\n")
    expect(run_cli('--version')).to eq("Natra #{Natra::VERSION}\n")
  end
end

RSpec.describe Natra::CLI, 'help' do
  it 'lists every command' do
    help = run_cli('help')
    ['-v', 'new APP_PATH', 'model NAME', 'controller NAME', 'scaffold NAME', 'service_object NAME'].each do |usage|
      expect(help).to include(" #{usage} ")
    end
  end

  it 'describes a single command' do
    expect(run_cli('help', 'scaffold')).to include('scaffold NAME', 'Generate a model with its associated views')
  end
end

RSpec.describe Natra::CLI, 'invalid arguments' do
  def expect_failure(*args, message)
    expect do
      expect { run_cli(*args) }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end.to output(message).to_stderr
  end

  it 'exits with status 1 for an unknown command' do
    expect_failure('bogus', /Could not find command "bogus"/)
  end

  it 'exits with status 1 when a generator is missing its NAME' do
    expect_failure('model', /No value provided for required arguments 'name'/)
  end
end

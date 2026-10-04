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

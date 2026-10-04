# frozen_string_literal: true

require 'open3'

RSpec.describe 'bin/natra' do
  let(:executable) { File.expand_path('../../bin/natra', __dir__) }

  it 'runs directly from the shell' do
    out, err, status = Open3.capture3(executable, '-v')
    expect(status).to be_success, err
    expect(out).to eq("Natra #{Natra::VERSION}\n")
  end
end

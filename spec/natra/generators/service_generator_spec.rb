# frozen_string_literal: true

RSpec.describe Natra::Generators::ServiceGenerator, 'natra service_object' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'renders a callable service class' do
    run_cli('service_object', 'payment')

    service = read('app/service/payments_service.rb')
    expect(service).to start_with("class PaymentsService\n")
    expect(service).to include('def initialize(*args)', 'def call')
  end
end

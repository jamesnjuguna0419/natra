# frozen_string_literal: true

RSpec.describe Natra::Generators::ServiceGenerator, 'natra service_object' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  it 'renders a callable service class' do
    run_cli('service_object', 'payment')

    service = read('app/services/payments_service.rb')
    expect(service).to start_with("class PaymentsService\n")
    expect(service).to include('def initialize(*args)', 'def call')
  end
end

RSpec.describe Natra::Generators::ServiceGenerator, 'config.ru' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  # A service is not Rack middleware: its #call takes no env, so `use` would
  # break every request. environment.rb already loads app/ with require_all.
  it 'is left untouched' do
    expect { run_cli('service_object', 'payment') }.not_to(change { read('config.ru') })
  end
end

RSpec.describe Natra::Generators::ServiceGenerator, 'naming' do
  include_context 'in a temp dir'

  before { create_app_skeleton }

  names = { 'SendInvoice' => 'camel case', 'send_invoice' => 'snake case', 'send-invoice' => 'hyphenated' }
  names.each do |name, style|
    it "derives the class and file name from a #{style} name, pluralizing it" do
      run_cli('service_object', name)

      expect(read('app/services/send_invoices_service.rb')).to start_with("class SendInvoicesService\n")
    end
  end

  it 'reports an unchanged service as identical when run again' do
    run_cli('service_object', 'payment')

    expect(run_cli('service_object', 'payment')).to match(%r{identical\s+app/services/payments_service\.rb})
  end
end

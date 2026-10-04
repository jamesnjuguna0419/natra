# frozen_string_literal: true

RSpec.describe ApplicationController do
<% if @views -%>
  it 'shows the welcome page at the root' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.content_type).to include('text/html')
    expect(last_response.body).to include('Welcome to the Sinatra Template!', '<title><%= @name.camel_case %></title>')
  end
<% else -%>
  it 'describes the app at the root' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.content_type).to include('application/json')
    expect(json_body).to eq('name' => '<%= @name.camel_case %>', 'status' => 'ok')
  end
<% end -%>

  it 'reports a healthy database' do
    get '/health'
    expect(last_response.status).to eq(200)
    expect(json_body).to eq('status' => 'ok', 'database' => 'ok')
  end

  it 'returns 503 when the database is unavailable' do
    pool = ActiveRecord::Base.connection_pool
    allow(pool).to receive(:with_connection).and_raise(ActiveRecord::ConnectionNotEstablished)
    get '/health'
    expect(last_response.status).to eq(503)
    expect(json_body).to eq('status' => 'error', 'database' => 'unavailable')
  end

  it 'returns JSON 404 for unknown routes' do
    get '/nope'
    expect(last_response.status).to eq(404)
    expect(json_body).to eq('error' => 'Not found')
  end
end

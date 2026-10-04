# frozen_string_literal: true

require './config/environment'

class ApplicationController < Sinatra::Base
  configure do
    set :default_content_type, :json
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
<% if @views -%>
    set :public_folder, 'public'
    set :views, 'app/views'
<% end -%>
  end

  get '/' do
<% if @views -%>
    content_type :html
    erb :welcome
<% else -%>
    json(name: '<%= @name.camel_case %>', status: 'ok')
<% end -%>
  end

  get '/health' do
    if database_available?
      json(status: 'ok', database: 'ok')
    else
      json({ status: 'error', database: 'unavailable' }, 503)
    end
  end

  not_found do
    json({ error: 'Not found' }, 404)
  end

  error ActiveRecord::RecordNotFound do
    json({ error: 'Not found' }, 404)
  end

  error ActiveRecord::RecordInvalid do
    json({ errors: env['sinatra.error'].record.errors }, 422)
  end

  error Sinatra::BadRequest do
    json({ error: env['sinatra.error'].message }, 400)
  end

  error do
    exception = env['sinatra.error']
    warn "#{exception.class}: #{exception.message}", *exception.backtrace
    body = { error: 'Internal server error' }
    body[:message] = exception.message if settings.development?
    json(body, 500)
  end

  private

  def json(object, code = 200)
    status code
    content_type :json
    Oj.dump(object.as_json)
  end

  def json_params
    @json_params ||= parse_json_body
  end

  def parse_json_body
    raw = read_request_body
    return {} if raw.strip.empty?

    parsed = Oj.load(raw)
    raise Sinatra::BadRequest, 'Request body must be a JSON object' unless parsed.is_a?(Hash)

    parsed
  rescue Oj::ParseError, EncodingError
    raise Sinatra::BadRequest, 'Invalid JSON'
  end

  def read_request_body
    input = request.body
    return '' unless input

    input.rewind if input.respond_to?(:rewind)
    input.read.to_s
  end

  def database_available?
    ActiveRecord::Base.with_connection { |connection| connection.select_value('SELECT 1') }
    true
  rescue StandardError
    false
  end
end

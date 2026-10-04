# frozen_string_literal: true

threads_count = Integer(ENV.fetch('PUMA_MAX_THREADS', 5))
port          = Integer(ENV.fetch('PORT', 9292))
workers_count = Integer(ENV.fetch('WEB_CONCURRENCY', 0))

threads threads_count, threads_count

# Cluster mode only when WEB_CONCURRENCY asks for workers.
if workers_count.positive?
  workers workers_count
  preload_app!
end

environment ENV.fetch('RACK_ENV', 'development')

bind "tcp://0.0.0.0:#{port}"

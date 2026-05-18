# frozen_string_literal: true

# Returns a 503 to non-logged-in users whose request has already been waiting
# in Puma's queue longer than `WAIT_THRESHOLD_SECONDS` by the time it gets a
# worker. Frees the worker to serve a logged-in request from the queue
# instead.
#
# This is a load-shedding layer that complements the steady-state rate limits
# in `config/initializers/rack_attack.rb`. Under normal load the queue wait
# is sub-100ms and this middleware passes everything through unchanged; it
# only triggers when the system is genuinely saturated (large queues, slow
# requests, dyno restart re-saturation). When that happens, anonymous
# traffic gets a fast 503 + Retry-After instead of being held in queue and
# eventually rack-timeout-aborted; logged-in traffic continues normally.
#
# `WAIT_THRESHOLD_SECONDS` is deliberately well above normal latency and
# well below `RACK_TIMEOUT_WAIT_TIMEOUT`, so anonymous users still get fast
# service in steady state, and only shed when the queue is actually deep
# enough that rack-timeout would have failed them in another few seconds
# anyway.
class AnonLoadShed
  WAIT_THRESHOLD_SECONDS = 5.0

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) if logged_in?(env)
    waited = wait_seconds(env)
    return @app.call(env) if waited.nil? || waited < WAIT_THRESHOLD_SECONDS
    [
      503,
      { 'Content-Type' => 'text/plain', 'Retry-After' => '30' },
      ["Server busy, please try again shortly.\n"],
    ]
  end

  private

  def logged_in?(env)
    session = env['rack.session']
    session && session[:user_id].present?
  end

  # rack-timeout populates env['rack.timeout.info'].wait with the seconds
  # the request spent in the dyno's queue before reaching a worker.
  def wait_seconds(env)
    info = env['rack.timeout.info']
    info&.wait
  end
end

# frozen_string_literal: true

require 'digest'

# Records a JA4H-style fingerprint of the request's header shape, the Sec-Fetch
# headers and the shedder's scraper_signal on the New Relic transaction.
# Observability only. Header names lose their casing in Rack, so the digests
# are not comparable with public JA4H data.
class ClientFingerprint
  # Fraction of requests whose raw header order is logged.
  LOG_SAMPLE_RATE = ENV.fetch('CLIENT_FINGERPRINT_LOG_RATE', '0.001').to_f

  # Added by Heroku's router, not the client.
  PROXY_HEADERS = %w[
    HTTP_X_FORWARDED_FOR
    HTTP_X_FORWARDED_PROTO
    HTTP_X_FORWARDED_PORT
    HTTP_X_FORWARDED_HOST
    HTTP_X_REQUEST_ID
    HTTP_X_REQUEST_START
    HTTP_TOTAL_ROUTE_TIME
    HTTP_CONNECTION
    HTTP_VIA
  ].freeze

  # Per-request values, not per-client. Cookie values are never digested.
  EXCLUDED_HEADERS = %w[HTTP_COOKIE HTTP_REFERER HTTP_AUTHORIZATION].freeze

  SEC_HEADERS = {
    'sec_fetch_dest' => 'HTTP_SEC_FETCH_DEST',
    'sec_fetch_mode' => 'HTTP_SEC_FETCH_MODE',
    'sec_fetch_site' => 'HTTP_SEC_FETCH_SITE',
    'sec_ch_ua'      => 'HTTP_SEC_CH_UA',
  }.freeze

  # Easier to facet on in NRQL than a null.
  ABSENT = '(absent)'

  def initialize(app)
    @app = app
  end

  def call(env)
    record(env)
    @app.call(env)
  end

  private

  # HTML requests only. Never fails the request.
  def record(env)
    return unless env['HTTP_ACCEPT']&.start_with?('text/html')
    names = header_names(env)
    NewRelic::Agent.add_custom_attributes(attributes(env, names)) if defined?(NewRelic::Agent)
    log_sample(env, names)
  rescue StandardError => e
    Rails.logger.warn("ClientFingerprint failed: #{e.class}: #{e.message}")
  end

  def attributes(env, names)
    attrs = {
      'ja4h_a'        => part_a(env, names),
      'ja4h_b'        => digest(names.join(',')),
      'ja4h_b_sorted' => digest(names.sort.join(',')),
    }
    SEC_HEADERS.each { |attr, key| attrs[attr] = env[key].presence || ABSENT }
    attrs['scraper_signal'] = AnonLoadShed.scraper_signal(env) || ABSENT
    attrs
  end

  # Wire-form header names in Rack's order, without CONTENT_TYPE/CONTENT_LENGTH.
  def header_names(env)
    keys = env.keys.select { |key| key.start_with?('HTTP_') }
    (keys - PROXY_HEADERS - EXCLUDED_HEADERS).map { |key| key.delete_prefix('HTTP_').downcase.tr('_', '-') }
  end

  # method(2) + version(2) + cookie?(1) + referer?(1) + header count(2) + language(4).
  def part_a(env, names)
    [
      env['REQUEST_METHOD'].to_s.downcase[0, 2].ljust(2, '0'),
      http_version(env),
      env.key?('HTTP_COOKIE') ? 'c' : 'n',
      env.key?('HTTP_REFERER') ? 'r' : 'n',
      format('%02d', [names.size, 99].min),
      accept_language(env),
    ].join
  end

  # "HTTP/1.1" -> "11".
  def http_version(env)
    match = env['SERVER_PROTOCOL'].to_s.match(/\AHTTP\/(\d)\.(\d)\z/)
    match ? "#{match[1]}#{match[2]}" : '00'
  end

  # "en-US,en;q=0.9" -> "enus"; "0000" when absent.
  def accept_language(env)
    primary = env['HTTP_ACCEPT_LANGUAGE'].to_s.split(',').first.to_s.split(';').first.to_s
    primary.downcase.gsub(/[^a-z0-9]/, '')[0, 4].to_s.ljust(4, '0')
  end

  def digest(value)
    Digest::SHA256.hexdigest(value)[0, 12]
  end

  def log_sample(env, names)
    return unless LOG_SAMPLE_RATE.positive? && rand < LOG_SAMPLE_RATE
    Rails.logger.info(
      "[client_fingerprint] ua=#{env['HTTP_USER_AGENT'].inspect} " \
      "proto=#{env['SERVER_PROTOCOL'].inspect} order=#{names.join(',')}",
    )
  end
end

# frozen_string_literal: true

require 'digest'

# Derives a JA4H-equivalent fingerprint of the HTTP client from the shape of
# its request headers, and attaches it to the New Relic transaction so traffic
# can be clustered in NRQL without trusting the User-Agent.
#
# The User-Agent is attacker-controlled and free to rotate: the scraper that
# saturated the dynos on 2026-08-06 cycled eight forged Chrome strings, and
# 15% of real readers happened to share those exact strings, so neither
# blocking nor throttling on the UA is viable. Header *shape* - which headers
# a client sends, in what order, and how many - is a property of the HTTP
# library rather than of a string the caller chose, so it survives UA rotation
# and does not pool real browsers in with the bot.
#
# This is observability only. It classifies nothing and blocks nothing; the
# point is to find out empirically whether the fingerprint separates the
# scraper cleanly before any rule is written on top of it.
#
# == Equivalent to JA4H, not identical
#
# Rack normalises header names on the way in - upcased, `-` folded to `_` -
# and discards their original casing, which FoxIO's JA4H hashes verbatim. Our
# digests are therefore comparable to each other but NOT to a reference
# implementation or any public JA4H corpus. Two further Heroku-specific
# caveats:
#
# - The router terminates the client connection and re-emits HTTP/1.1 to the
#   dyno, so `SERVER_PROTOCOL` is always "11" and that component of _a carries
#   no signal here. It is kept for structural fidelity with the real format.
# - The router may reorder or inject headers, which would make the ordered
#   digest unstable through no fault of the client. That is exactly what the
#   sampled `order=` log line below is for: until it confirms order survives
#   the hop, treat `ja4h_b_sorted` as the trustworthy one.
class ClientFingerprint
  # Fraction of requests whose raw header order is logged, so the ordered
  # digest can be validated against what clients actually send. Deliberately
  # tiny - at ~50 req/s the default is about one line every 20 seconds - and
  # env-tunable so it can be raised briefly during an investigation.
  LOG_SAMPLE_RATE = ENV.fetch('CLIENT_FINGERPRINT_LOG_RATE', '0.001').to_f

  # Injected or rewritten by Heroku's router between client and dyno. They
  # describe the proxy hop rather than the client, so including them would add
  # noise shared by every request regardless of origin.
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

  # JA4H excludes Cookie and Referer from its header-name digest because they
  # vary per request rather than per client. We exclude Authorization for the
  # same reason and drop JA4H's _c and _d components entirely: those hash
  # cookie names and values, which is user session data we have no reason to
  # digest, and anonymous scraper traffic carries no cookies anyway. They
  # would cost privacy for no signal.
  EXCLUDED_HEADERS = %w[HTTP_COOKIE HTTP_REFERER HTTP_AUTHORIZATION].freeze

  # Chromium sends these on every top-level navigation from a real browser.
  # Recorded verbatim rather than folded into the digest so a rule can be
  # written against a spec'd behaviour later, instead of against the
  # incidental `signed-exchange` Accept token that first surfaced the scraper.
  SEC_HEADERS = {
    'sec_fetch_dest'     => 'HTTP_SEC_FETCH_DEST',
    'sec_fetch_mode'     => 'HTTP_SEC_FETCH_MODE',
    'sec_fetch_site'     => 'HTTP_SEC_FETCH_SITE',
    'sec_ch_ua_platform' => 'HTTP_SEC_CH_UA_PLATFORM',
  }.freeze

  # Faceting on a literal reads better in NRQL than `WHERE x IS NULL`, and
  # absence is the signal we care about most.
  ABSENT = '(absent)'

  def initialize(app)
    @app = app
  end

  def call(env)
    record(env)
    @app.call(env)
  end

  private

  # Fingerprinting is observability and must never be a reason to fail a
  # request, so anything raised here is swallowed after being logged.
  def record(env)
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
    attrs['has_sec_ch_ua'] = env.key?('HTTP_SEC_CH_UA')
    attrs
  end

  # Client header names, lowercased and hyphenated back to their wire form, in
  # the order Rack recorded them. CONTENT_TYPE and CONTENT_LENGTH arrive
  # without the HTTP_ prefix and so cannot be placed at their true position in
  # the sequence; they are left out rather than inserted at a guessed index,
  # which would corrupt the ordered digest. The traffic under investigation is
  # entirely GETs, which carry neither.
  def header_names(env)
    keys = env.keys.select { |key| key.start_with?('HTTP_') }
    (keys - PROXY_HEADERS - EXCLUDED_HEADERS).map { |key| key.delete_prefix('HTTP_').downcase.tr('_', '-') }
  end

  # method(2) + http version(2) + cookie?(1) + referer?(1) + header count(2) +
  # primary Accept-Language(4), per the JA4H_a layout.
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

  # "HTTP/1.1" -> "11". Always "11" behind Heroku's router, per the class
  # comment; the client's real protocol never reaches the dyno.
  def http_version(env)
    match = env['SERVER_PROTOCOL'].to_s.match(/\AHTTP\/(\d)\.(\d)\z/)
    match ? "#{match[1]}#{match[2]}" : '00'
  end

  # "en-US,en;q=0.9" -> "enus". Zero-padded to four characters, and all zeroes
  # when the header is absent - which is itself a strong bot tell, since every
  # mainstream browser sends one.
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

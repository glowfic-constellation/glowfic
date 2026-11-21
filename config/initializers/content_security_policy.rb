# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Content Security Policy, currently REPORT-ONLY: browsers log violations to /csp_reports
# (see CspReportsController) but block nothing. Read the reports, adjust the policy, and only
# then remove report_only to enforce it.
#
# Inline <script> tags (gon) carry a per-request nonce. Inline styles are allowed because user posts
# and many views use style attributes. User content can embed images from any https host, so img-src
# is wide open; the aim is to stop injected scripts, plugins, framing and form hijacking.
Rails.application.configure do
  config.content_security_policy do |policy|
    asset_host = ENV.fetch('ASSET_HOST', nil)
    icon_host = ENV.fetch('ICON_HOST', nil)
    bucket = ENV.fetch('S3_BUCKET_NAME', nil)
    s3_hosts = bucket.present? ? ["https://#{bucket}.s3.amazonaws.com", "https://s3.amazonaws.com"] : []

    policy.default_src :self
    policy.script_src  :self, *asset_host
    policy.style_src   :self, :unsafe_inline, *asset_host
    policy.font_src    :self, :data, *asset_host
    policy.img_src     :self, :https, :data, :blob
    policy.connect_src :self, *s3_hosts, *icon_host
    policy.media_src   :self
    policy.object_src  :none
    policy.frame_src   :none
    policy.base_uri    :self
    policy.frame_ancestors :self
    policy.report_uri "/csp_reports"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src)
  config.content_security_policy_report_only = true
end

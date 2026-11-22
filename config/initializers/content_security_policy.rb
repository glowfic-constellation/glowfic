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
    # New Relic's browser agent beacons (seen in the first production violation reports)
    policy.connect_src :self, *s3_hosts, *icon_host, 'https://bam.nr-data.net', 'https://bam-cell.nr-data.net'
    policy.media_src   :self
    # manifest-src falls back to default-src 'self', but the favicon manifest is served from the asset host
    policy.manifest_src :self, *asset_host
    policy.object_src  :none
    policy.frame_src   :none
    # Inline event-handler attributes (onclick etc.) are blocked (reported only): the first production reports show
    # some, attributed to application.js although none are in our own views or JS. :report_sample makes the report
    # carry the first 40 characters of the handler (script-sample) so the source can be found. If they turn out to be
    # unavoidable, use :unsafe_inline here before enforcing.
    policy.script_src_attr :report_sample
    policy.base_uri :self
    policy.frame_ancestors :self
    policy.report_uri "/csp_reports"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src)
  config.content_security_policy_report_only = true
end

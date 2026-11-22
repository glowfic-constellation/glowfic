# frozen_string_literal: true
# Receives Content-Security-Policy violation reports (see config/initializers/content_security_policy.rb)
# and writes one short warn-level log line per report, so they can be searched in the logs. Nothing is stored.
class CspReportsController < ActionController::API
  MAX_BODY_BYTES = 4096
  FIELDS = %w(violated-directive effective-directive blocked-uri document-uri source-file line-number disposition script-sample).freeze

  def create
    body = request.body.read(MAX_BODY_BYTES).to_s
    report = JSON.parse(body)['csp-report']
    if report.is_a?(Hash)
      summary = FIELDS.filter_map do |field|
        value = report[field]
        # drop query strings and fragments: they can hold tokens or personal data
        value = value.to_s.sub(/[?#].*\z/m, '') if field.end_with?('uri', 'file')
        "#{field}=#{value.to_s.truncate(200).inspect}" unless value.nil?
      end
      # warn, not info: production runs at the warn log level, and info lines would be dropped
      Rails.logger.warn("CSP violation #{summary.join(' ')}")
    end
    head :no_content
  rescue JSON::ParserError
    head :bad_request
  end
end

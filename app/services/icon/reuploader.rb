# frozen_string_literal: true
class Icon::Reuploader < Object
  def initialize(icon)
    @icon = icon
    filename = File.basename(URI.parse(@icon.url).path)
    @key = "users/#{icon.user_id}/icons/#{filename}"
    @content_type = validate
  end

  def process
    validate
    stream = scrape
    object = S3_BUCKET.put_object(key: @key, body: steam, acl: 'public-read', content_type: @content_type, cache_control: 'public, max-age=31536000')
  end

  private

  def validate
  end

  def scrape
    sleep 0.25
    StringIO.new(HTTParty.get(@icon.url).body, 'r')
  rescue Net::OpenTimeout => e
    retried += 1
    base_message = "Failed to get #{url}: #{e.message}"
    if retried < max_try
      Resque.logger.debug base_message + "; retrying (tried #{retried} #{'time'.pluralize(retried)})"
      retry
    else
      Resque.logger.warn base_message
      raise
    end
  end

  def s3_setup
    # mostly copied from Uploading Control set_s3_url

    presign_conf = {}
    if !Rails.env.production? && ENV.key?('MINIO_ENDPOINT') && ENV.key?('MINIO_ENDPOINT_EXTERNAL')
      # for minio and Docker compatibility, replace the guest-compatible "minio" host with the host-compatible "localhost" path
      standard_endpoint = ENV.fetch('MINIO_ENDPOINT', nil)
      replacement_endpoint = ENV.fetch('MINIO_ENDPOINT_EXTERNAL', nil)
      bucket_url = S3_BUCKET.url
      unless bucket_url.include?(standard_endpoint)
        raise RuntimeError.new("couldn't find minio endpoint in direct post URL: #{standard_endpoint} in #{bucket_url}")
      end
      presign_conf[:url] = bucket_url.sub(standard_endpoint, replacement_endpoint)
    end
  end
end

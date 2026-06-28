# frozen_string_literal: true
class Icon::Reuploader < Object
  def initialize(icon)
    @icon = icon
    filename = File.basename(URI.parse(@icon.url).path)
    filename = @icon.id.to_s if filename.blank?
    @key = "users/#{icon.user_id}/icons/#{filename}"
    @content_type = validate(filename)
  end

  def process
    stream = scrape
    # can I parse this as an image and check dimensions here?
    object = S3_BUCKET.put_object(key: @key, body: stream, acl: 'public-read', content_type: @content_type, cache_control: 'public, max-age=31536000')
    update_icon(object)
  end

  private

  def validate
    headers = HTTParty.head(@icon.url).headers
    raise InvalidFileTypeError unless headers.content_type.starts_with?('image/')
    raise TooLargeFileError unless headers.content_length <= 300_000 # 300kb
  end

  def scrape
    sleep 0.25
    HTTParty.get(@icon.url).body
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

  def update_icon(object)
    @icon.s3_key = object.key
    url = object.public_url

    # mostly copied from Uploading Control set_s3_url
    if !Rails.env.production? && ENV.key?('MINIO_ENDPOINT') && ENV.key?('MINIO_ENDPOINT_EXTERNAL')
      # for minio and Docker compatibility, replace the guest-compatible "minio" host with the host-compatible "localhost" path
      standard_endpoint = ENV.fetch('MINIO_ENDPOINT', nil)
      replacement_endpoint = ENV.fetch('MINIO_ENDPOINT_EXTERNAL', nil)
      raise RuntimeError.new("couldn't find minio endpoint in direct post URL: #{standard_endpoint} in #{url}") unless url.include?(standard_endpoint)
      url = url.sub(standard_endpoint, replacement_endpoint)
    end

    @icon.url = url
    @icon.save!
  end
end

# frozen_string_literal: true
class UploadingController < ApplicationController
  protected

  def set_s3_url
    return if params[:type] == "existing"

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

    @s3_direct_post = S3_BUCKET.presigned_post(
      key: "users/#{current_user.id}/icons/${filename}",
      success_action_status: '201',
      acl: 'public-read',
      content_type_starts_with: 'image/',
      cache_control: 'public, max-age=31536000',
      **presign_conf,
    )
  end
end

require 'uri'
require 'digest'

class MigrateUploadJob < ApplicationJob
  queue_as :low

  def perform(icon_id)
    icon = Icon.find(icon_id)
    raise IconNotUploaded, "Icon #{icon.id} is remotely hosted" unless icon.s3_key.present?
    path = URI(icon.url).path
    # path format: `/users/#{user_id}/icons/#{random}_#{filename}`
    strip = "/users%2F#{icon.user_id}%2Ficons%2F"
    filename = path.reverse.chomp(strip.reverse).reverse

    head, checksum = scrape!(icon.url)
    last_modified = head.key?("last-modified") ? head["last-modified"] : icon.updated_at

    Icon.transaction do
      blob = ActiveStorage::Blob.create_before_direct_upload!(
        key: path[1..],
        filename: filename,
        content_type: head["content-type"],
        byte_size: head["content-length"],
        checksum: checksum,
        service_name: 'amazon',
      )
      blob.update_columns(created_at: last_modified) # rubocop:disable Rails/SkipsModelValidations
      ActiveStorage::Attachment.create!(name: 'image', blob: blob, record: icon)
      icon.reload
      icon.image.attachment.update_columns(created_at: last_modified) # rubocop:disable Rails/SkipsModelValidations
      icon.update!(s3_key: nil)
    end
  end

  def scrape!(url)
    max_try = 3
    retried = 0
    begin
      sleep 0.25
      result = HTTParty.get(url)
      [result.headers, Digest::MD5.base64digest(result.body)]
    rescue Net::OpenTimeout => e
      retried += 1
      if retried < max_try
        logger.debug "Failed to get #{url}: #{e.message}; retrying (tried #{retried} #{'time'.pluralize(retried)})"
        retry
      else
        logger.warn "Failed to get #{url}: #{e.message}"
        raise
      end
    end
  end
end

class IconNotUploaded < StandardError; end

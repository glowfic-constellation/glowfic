# frozen_string_literal: true
class DeleteIconFromS3Job < ApplicationJob
  queue_as :high

  def perform(s3_key)
    # the key may have been re-used by another icon row (or the update that freed it rolled back)
    if Icon.where(s3_key: s3_key).exists?
      Rails.logger.info("Not deleting S3 object still used by an icon: #{s3_key}")
      return
    end
    Rails.logger.info("Deleting S3 object: #{s3_key}")
    S3_BUCKET.delete_objects(delete: { objects: [{ key: s3_key }] })
  end
end

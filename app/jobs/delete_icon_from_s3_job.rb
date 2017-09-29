class DeleteIconFromS3Job < ApplicationJob
  queue_as :high

  def perform(s3_key)
    Rails.logger.info("Deleting S3 object: #{s3_key}")
    S3_BUCKET.delete_objects(delete: {objects: [{key: s3_key}]})
  end
end

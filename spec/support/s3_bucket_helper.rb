def handle_s3_bucket
  # compensates for developers not having S3 buckets set up locally
  return unless S3_BUCKET.nil?
  struct = Struct.new(:url) do
    def delete_objects(_args)
      1
    end

    def presigned_post(_args)
      1
    end
  end
  stub_const("S3_BUCKET", struct.new(''))
end

# frozen_string_literal: true
access_key_id = ENV.fetch('AWS_ACCESS_KEY_ID', 'glowfic_minio')
secret_access_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'glowfic_minio')
bucket_name = ENV.fetch('S3_BUCKET_NAME', 'glowfic-dev')
Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(access_key_id, secret_access_key),
  logger: Rails.logger,
})

s3_config = {}
if ENV.key?('MINIO_ENDPOINT')
  s3_config = {
    endpoint: ENV['MINIO_ENDPOINT'],
    force_path_style: true,
  }
  client = Aws::S3::Client.new(**s3_config)
  begin
    client.head_bucket(bucket: bucket_name)
  rescue Aws::S3::Errors::NotFound
    Rails.logger.warn "creating bucket #{bucket_name}..."
    public_read_policy = {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "arn:aws:s3:::#{bucket_name}/*",
      }],
    }.to_json

    begin
      client.create_bucket(bucket: bucket_name)
      client.put_bucket_policy(bucket: bucket_name, policy: public_read_policy)
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou, Aws::S3::Errors::BucketAlreadyExists
      # Another process (e.g. a parallel_tests worker or a sibling Puma worker)
      # created the bucket between our head_bucket check and here — that's fine.
    end
  end
end

S3_BUCKET = Aws::S3::Resource.new(**s3_config).bucket(bucket_name)

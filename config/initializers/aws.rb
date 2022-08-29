Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', nil), ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)),
})

bucket = ENV.fetch('S3_BUCKET_NAME', nil)
S3_BUCKET = bucket ? Aws::S3::Resource.new.bucket(bucket) : nil

Aws::Rails.add_action_mailer_delivery_method(:aws_ses)

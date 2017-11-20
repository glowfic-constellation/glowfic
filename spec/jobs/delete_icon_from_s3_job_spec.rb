require "spec_helper"
require "support/s3_bucket_helper"

RSpec.describe DeleteIconFromS3Job do
  before(:each) { ResqueSpec.reset! }

  it "deletes the given key" do
    handle_s3_bucket
    key = 'arbitrary'
    delete_key = {delete: {objects: [{key: key}]}}
    expect(S3_BUCKET).to receive(:delete_objects).with(delete_key)
    DeleteIconFromS3Job.perform_now(key)
  end
end

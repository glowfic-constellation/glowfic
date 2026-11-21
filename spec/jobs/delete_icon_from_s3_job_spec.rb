RSpec.describe DeleteIconFromS3Job do
  it "deletes the given key" do
    key = 'arbitrary'
    delete_key = { delete: { objects: [{ key: key }] } }
    expect(S3_BUCKET).to receive(:delete_objects).with(delete_key)
    DeleteIconFromS3Job.perform_now(key)
  end

  it "does not delete a key that an icon still uses" do
    icon = create(:uploaded_icon)
    expect(S3_BUCKET).not_to receive(:delete_objects)
    DeleteIconFromS3Job.perform_now(icon.s3_key)
  end
end

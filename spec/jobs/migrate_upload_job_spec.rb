RSpec.describe MigrateUploadJob do
  include ActiveJob::TestHelper
  before(:each) { clear_enqueued_jobs }

  it "requires valid id" do
    expect { MigrateUploadJob.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "requires uploaded icon" do
    expect { MigrateUploadJob.perform_now(create(:icon).id) }.to raise_error(IconNotUploaded)
  end

  it "requires valid icon url" do
    icon = create(:uploaded_icon)
    icon.update_columns(url: 'fakeurl.con') # rubocop:disable Rails/SkipsModelValidations
    expect { MigrateUploadJob.perform_now(icon.id) }.to raise_error(Addressable::URI::InvalidURIError)
  end

  it "handles request failure" do
    icon = create(:uploaded_icon)
    allow(HTTParty).to receive(:get).and_raise(Net::OpenTimeout)
    expect { MigrateUploadJob.perform_now(icon.id) }.to raise_error(Net::OpenTimeout)
  end

  it "sets correct parameters" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ICON_HOST').and_return('https://d1anwqy6ci9o1i.cloudfront.net')
    allow(ENV).to receive(:[]).with('S3_BUCKET_NAME').and_return('glowfic-constellation')

    user = create(:user)
    url = "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{user.id}%2Ficons%2Fl15eeps7j9f2cm6sxbly5_1195882_original.png"
    s3_key = "users/#{user.id}/icons/l15eeps7j9f2cm6sxbly5_1195882_original.png"
    icon = create(:icon, user: user, url: url, s3_key: s3_key)
    file = Rails.root.join('spec', 'support', 'fixtures', 'avatar.png')
    bytes = 107_333
    time = 5.minutes.ago
    headers = { 'content-type': 'image/png', 'content-length': bytes, 'last-modified': time }
    stub_request(:get, icon.url).to_return(status: 200, body: File.new(file), headers: headers)

    expect {
      MigrateUploadJob.perform_now(icon.id)
    }.to change { ActiveStorage::Blob.count }.by(1).and change { ActiveStorage::Attachment.count }.by(1)

    icon.reload
    expect(icon.image).to be_attached
    expect(icon.url).to eq(url)

    blob = icon.image.blob
    expect(blob.key).to eq(CGI.escape(s3_key))
    expect(blob.filename.to_s).to eq('l15eeps7j9f2cm6sxbly5_1195882_original.png')
    expect(blob.content_type).to eq('image/png')
    expect(blob.byte_size).to eq(bytes)
    expect(blob.checksum).to eq('MypFGrrRrkUpxOiHHHqLDA==')
    expect(blob.created_at).to be_the_same_time_as(time)
    expect(icon.image.attachment.created_at).to be_the_same_time_as(time)
  end
end

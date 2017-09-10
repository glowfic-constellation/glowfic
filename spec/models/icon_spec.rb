require "spec_helper"

RSpec.describe Icon do
  describe "#validations" do
    it "requires url" do
      icon = build(:icon, url: nil)
      expect(icon).not_to be_valid
      icon = build(:icon, url: '')
      expect(icon).not_to be_valid
    end

    it "requires url-looking url" do
      icon = build(:icon, url: 'not-a-url')
      expect(icon).not_to be_valid
    end

    it "requires user" do
      icon = build(:icon, user: nil)
      expect(icon).not_to be_valid
    end

    it "requires keyword" do
      icon = build(:icon, keyword: nil)
      expect(icon).not_to be_valid
      icon = build(:icon, keyword: '')
      expect(icon).not_to be_valid
    end

    context "#uploaded_url_not_in_use" do
      it "should set the url back to its previous url on create" do
        icon = create(:uploaded_icon)
        dupe_icon = build(:icon, url: icon.url, s3_key: icon.s3_key)
        expect(dupe_icon).not_to be_valid
        expect(dupe_icon.url).to be nil
      end

      it "should set the url back to its previous url on update" do
        icon = create(:uploaded_icon)
        dupe_icon = create(:icon)
        old_url = dupe_icon.url
        dupe_icon.url = icon.url
        dupe_icon.s3_key = icon.s3_key
        expect(dupe_icon.save).to be false
        expect(dupe_icon.url).to eq(old_url)
      end
    end
  end

  describe "#after_destroy" do
    it "updates ids" do
      reply = create(:reply, with_icon: true)
      reply.icon.destroy
      reply.reload
      expect(reply.icon_id).to be_nil
    end
  end

  describe "#delete_from_s3" do
    def delete_key(key)
      {delete: {objects: [{key: key}], quiet: true}}
    end

    it "deletes uploaded on destroy" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.s3_key))
      icon.destroy
    end

    it "does not delete non-uploaded on destroy" do
      icon = create(:icon)
      expect(S3_BUCKET).not_to receive(:delete_objects)
      icon.destroy
    end

    it "deletes uploaded on new uploaded update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.s3_key))
      icon.url = "https://d1anwqy6ci9o1i.cloudfront.net/users/#{icon.user.id}/icons/nonsense-fakeimg2.png"
      icon.s3_key = "/users/#{icon.user.id}/icons/nonsense-fakeimg2.png"
      icon.save
    end

    it "deletes uploaded on new non-uploaded update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.s3_key))
      icon.url = "https://fake.com/nonsense-fakeimg2.png"
      icon.s3_key = "/users/#{icon.user.id}/icons/nonsense-fakeimg2.png"
      icon.save
    end

    it "does not delete uploaded on non-url update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).not_to receive(:delete_objects)
      icon.keyword = "not a url update"
      icon.save
    end
  end

  context "#use_icon_host" do
    let(:asset_host) { "https://fake.cloudfront.net" }
    before(:each) { @cached_host = ENV['ICON_HOST'] }
    after(:each) { ENV['ICON_HOST'] = @cached_host }

    it "does nothing unless asset host is present" do
      ENV['ICON_HOST'] = nil
      icon = build(:icon)
      icon.s3_key = 'users/1/icons/fake_test.png'
      icon.url = 'https://glowfic-bucket.s3.amazonaws.com/users%2F1%2Ficons%2Ffake_test.png'
      icon.save
      expect(icon.reload.url).to eq('https://glowfic-bucket.s3.amazonaws.com/users%2F1%2Ficons%2Ffake_test.png')
    end

    it "does nothing unless the icon is uploaded" do
      ENV['ICON_HOST'] = asset_host
      icon = build(:icon)
      icon.s3_key = nil
      icon.url = 'https://glowfic-bucket.s3.amazonaws.com/users%2F1%2Ficons%2Ffake_test.png'
      icon.save
      expect(icon.reload.url).to eq('https://glowfic-bucket.s3.amazonaws.com/users%2F1%2Ficons%2Ffake_test.png')
    end

    it "does nothing unless the icon already has the asset host domain in it" do
      ENV['ICON_HOST'] = asset_host
      icon = build(:icon)
      icon.s3_key = 'users/1/icons/fake_test.png'
      icon.url = asset_host + '/users%2F1%2Ficons%2Ffake_test.png'
      icon.save
      expect(icon.reload.url).to eq(asset_host + '/users%2F1%2Ficons%2Ffake_test.png')
    end

    it "updates the s3 domain to the asset host domain" do
      ENV['ICON_HOST'] = asset_host
      icon = build(:icon)
      icon.s3_key = 'users/1/icons/fake_test.png'
      icon.url = 'https://glowfic-bucket.s3.amazonaws.com/users%2F1%2Ficons%2Ffake_test.png'
      icon.save
      expect(icon.reload.url).to eq(asset_host + '/users%2F1%2Ficons%2Ffake_test.png')
    end
  end
end

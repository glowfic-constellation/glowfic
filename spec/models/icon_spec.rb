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
        dupe_icon = build(:icon, url: icon.url)
        expect(dupe_icon).not_to be_valid
        expect(dupe_icon.url).to be nil
      end

      it "should set the url back to its previous url on update" do
        icon = create(:uploaded_icon)
        dupe_icon = create(:icon)
        old_url = dupe_icon.url
        dupe_icon.url = icon.url
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
    def delete_key(url)
      {delete: {objects: [{key: Icon.send(:s3_key, url)}], quiet: true}}
    end

    it "deletes uploaded on destroy" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.url))
      icon.destroy
    end

    it "does not delete non-uploaded on destroy" do
      icon = create(:icon)
      expect(S3_BUCKET).not_to receive(:delete_objects)
      icon.destroy
    end

    it "deletes uploaded on new uploaded update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.url))
      icon.url = "https://d1anwqy6ci9o1i.cloudfront.net/users/#{icon.user.id}/icons/nonsense-fakeimg2.png"
      icon.save
    end

    it "deletes uploaded on new non-uploaded update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).to receive(:delete_objects).with(delete_key(icon.url))
      icon.url = "https://fake.com/nonsense-fakeimg2.png"
      icon.save
    end

    it "does not delete uploaded on non-url update" do
      icon = create(:uploaded_icon)
      expect(S3_BUCKET).not_to receive(:delete_objects)
      icon.keyword = "not a url update"
      icon.save
    end
  end
end

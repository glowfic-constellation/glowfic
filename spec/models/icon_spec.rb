require "spec_helper"

RSpec.describe Icon do
  describe "#uploaded_url_not_in_use" do
    it "should set the url back to its previous url on create" do
      icon = create(:uploaded_icon)
      dupe_icon = build(:icon, url: icon.url)
      expect(dupe_icon.valid?).to be false
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

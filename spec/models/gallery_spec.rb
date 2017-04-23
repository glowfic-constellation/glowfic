require "spec_helper"

RSpec.describe Gallery do
  it "adds icons if it saves successfully" do
    user = create(:user)
    icon = create(:icon, user: user)
    expect(icon.has_gallery).to eq(false)
    gallery = build(:gallery, user: user)
    gallery.icon_ids = [icon.id]
    expect(gallery).to be_valid
    expect(gallery.save).to be_true
    expect(icon.reload.has_gallery).to be_true
  end

  it "only adds icons if it saves successfully" do
    user = create(:user)
    icon = create(:icon, user: user)
    expect(icon.has_gallery).to eq(false)
    gallery = build(:gallery, user: user, name: nil)
    gallery.icon_ids = [icon.id]
    expect(gallery).not_to be_valid
    expect(gallery.save).to eq(false)
    expect(icon.reload.has_gallery).to eq(false)
  end
end

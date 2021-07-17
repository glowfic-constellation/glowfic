RSpec.describe AccessCircle do
  describe "validations" do
    let(:user) { create(:user) }

    it "requires a user" do
      circle = build(:access_circle, user_id: nil)
      expect(circle).not_to be_valid
    end

    it "requires a name" do
      circle = build(:access_circle, name: nil)
      expect(circle).not_to be_valid
    end

    it "requires a unique name per user" do
      circle1 = create(:access_circle, user: user)
      circle2 = build(:access_circle, user: user, name: circle1.name)
      expect(circle2).not_to be_valid
    end

    it "can have the same name as another user's circle" do
      circle1 = create(:access_circle)
      circle2 = build(:access_circle, name: circle1.name)
      expect(circle1.user_id).not_to eq(circle2.user_id)
      expect(circle2).to be_valid
    end

    it "can have the same name as a setting" do
      setting = create(:setting, user: user, owned: true)
      circle = build(:access_circle, user: user, name: setting.name)
      expect(circle).to be_valid
    end
  end
end

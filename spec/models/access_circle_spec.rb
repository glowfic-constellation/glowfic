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

  describe 'visible_to?' do
    let(:user) { create(:user) }
    let(:circle) { create(:access_circle, user: user) }
    let(:reader) { create(:reader_user) }
    let(:other) { create(:user) }

    it 'does not allow logged out users' do
      expect(circle.visible_to?(nil)).to eq(false)
    end

    it 'does not allow logged out users for public circles' do
      circle.update!(owned: false)
      expect(circle.visible_to?(nil)).to eq(false)
    end

    it 'returns true if the circle is public' do
      circle.update!(owned: false)

      aggregate_failures do
        expect(circle.visible_to?(reader)).to eq(true)
        expect(circle.visible_to?(other)).to eq(true)
      end
    end

    it 'returns true for admins' do
      expect(circle.visible_to?(create(:admin_user))).to eq(true)
    end

    it 'returns true for own circles' do
      expect(circle.visible_to?(user)).to eq(true)
    end

    it 'returns false for other circles' do
      aggregate_failures do
        expect(circle.visible_to?(reader)).to eq(false)
        expect(circle.visible_to?(other)).to eq(false)
      end
    end
  end
end

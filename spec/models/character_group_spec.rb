RSpec.describe CharacterGroup do
  describe "validations" do
    let(:user) { create(:user) }

    it "requires a user" do
      group = build(:character_group, user_id: nil)
      expect(group).not_to be_valid
    end

    it "requires a name" do
      group = build(:character_group, name: nil)
      expect(group).not_to be_valid
    end

    it "requires a unique name per user" do
      group1 = create(:character_group, user: user)
      group2 = build(:character_group, user: user, name: group1.name)
      expect(group2).not_to be_valid
    end

    it "can have the same name as another user's group" do
      group1 = create(:character_group)
      group2 = build(:character_group, name: group1.name)
      expect(group2).to be_valid
    end

    it "can have the same name as a setting" do
      setting = create(:setting, user: user, owned: true)
      group = build(:character_group, user: user, name: setting.name)
      expect(group).to be_valid
    end
  end
end

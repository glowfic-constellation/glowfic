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

    it "cannot have characters from another user" do
      group = build(:character_group, characters: create_list(:character, 1))
      expect(group).not_to be_valid
      expect(group.errors.full_messages).to eq(['Characters must be yours'])
    end

    it "cannot have templates from another user" do
      group = build(:character_group, templates: create_list(:template, 1))
      expect(group).not_to be_valid
      expect(group.errors.full_messages).to eq(['Templates must be yours'])
    end

    it "can have both characters and templates" do
      characters = create_list(:character, 1, user: user)
      templates = create_list(:template, 1, user: user)
      group = build(:character_group, user: user, characters: characters, templates: templates)
      expect(group).to be_valid
    end

    it "can have multiple characters" do
      group = build(:character_group, user: user, characters: create_list(:character, 3, user: user))
      expect(group).to be_valid
    end

    it "can have multiple templates" do
      group = build(:character_group, user: user, templates: create_list(:template, 3, user: user))
      expect(group).to be_valid
    end

    it "cannot have the same character as another group" do
      character = create(:character, user: user)
      create(:character_group, user: user, characters: [character])
      group = build(:character_group, user: user, characters: [character])
      expect(group).not_to be_valid
      expect(group.errors.full_messages).to match_array(['Character tags is invalid', 'Characters is invalid'])
      expect(group.character_tags.first.errors.full_messages).to eq(['Character has already been taken'])
    end

    it "cannot have the same template as another group" do
      template = create(:template, user: user)
      create(:character_group, user: user, templates: [template])
      group = build(:character_group, user: user, templates: [template])
      expect(group).not_to be_valid
      expect(group.errors.full_messages).to eq(['Template tags is invalid'])
      expect(template.template_tag.errors.full_messages).to eq(['Template has already been taken'])
    end

    it "can have the same character as a setting" do
      character = create(:character, user: user)
      create(:setting, characters: [character])
      group = build(:character_group, user: user, characters: [character])
      expect(group).to be_valid
    end
  end
end

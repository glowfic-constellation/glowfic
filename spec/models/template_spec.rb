require "spec_helper"

RSpec.describe Template do
  it "requires a name" do
    template = build(:template, name: nil)
    expect(template).not_to be_valid
    expect {
      template.save!
    }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    expect(Template.count).to eq(0)
  end

  it "requires a user" do
    template = build(:template, user_id: 999)
    expect(template).not_to be_valid
    expect {
      template.save!
    }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User must exist")
    expect(Template.count).to eq(0)
  end

  it "succeeds without characters" do
    template = build(:template, characters: [])
    expect(template).to be_valid
    expect {
      template.save!
    }.not_to raise_error
    expect(Template.first).to eq(template.reload)
  end

  it "orders characters when given" do
    template = create(:template)
    character3 = create(:character, name: 'c', template: template)
    character1 = create(:character, name: 'a', template: template)
    character2 = create(:character, name: 'b', template: template)
    expect(template.characters).to eq([character1, character2, character3])
  end

  describe "#plucked characters" do
    it "returns nothing for an empty template" do
      template = create(:template)
      expect(template.plucked_characters).to be_empty
    end

    it "returns info for a single character" do
      template = create(:template)
      character = create(:character, template: template, template_name: "nickname", screenname: "screen_name")
      info = [[character.id, "#{character.name} | #{character.template_name} | #{character.screenname}"]]
      expect(template.plucked_characters).to eq(info)
    end

    it "returns info for multiple characters" do
      template = create(:template)
      character1 = create(:character, template: template, name: 'AAAA')
      character2 = create(:character, template: template, template_name: "nickname", name: 'BBBB')
      character3 = create(:character, template: template, screenname: "screen_name", name: 'CCCC')
      info = [
        [character1.id, character1.name],
        [character2.id, "#{character2.name} | #{character2.template_name}"],
        [character3.id, "#{character3.name} | #{character3.screenname}"]
      ]
      expect(template.plucked_characters).to eq(info)
    end
  end

  it "cleans up when deleted" do
    template = create(:template)
    create(:character, template: template)
    create(:character, template: template)
    old_id = template.id
    template.destroy!
    expect(Character.where(template_id: old_id)).to be_empty
  end

  describe "#settings_info" do
    let (:user) { create(:user) }
    let (:character1) { create(:character, user: user) }
    let (:character2) { create(:character, user: user) }
    let (:setting1) { create(:setting, user: user) }
    let (:setting2) { create(:setting, user: user) }
    let (:association) { Character.where(id: [character1.id, character2.id]) }

    it "handles characters with no setting" do
      expect(Template.settings_info(association)).to eq({})
    end

    it "handles characters with one setting" do
      character1.update!(setting_ids: [setting1.id])
      character2.update!(setting_ids: [setting2.id])
      expected = {
        character1.id => [[setting1.id, setting1.name]],
        character2.id => [[setting2.id, setting2.name]]
      }
      expect(Template.settings_info(association)).to eq(expected)
    end

    it "handles characters with many settings" do
      character1.update!(setting_ids: [setting1.id, setting2.id])
      association = Character.where(id: [character1.id])
      expected = { character1.id => [[setting1.id, setting1.name], [setting2.id, setting2.name]] }
      expect(Template.settings_info(association)).to eq(expected)
    end

    it "handles multiple characters with the same setting" do
      character1.update!(setting_ids: [setting1.id])
      character2.update!(setting_ids: [setting1.id])
      character3 = create(:character, user: user, setting_ids: [setting1.id, setting2.id])
      association = Character.where(id: [character1.id, character2.id, character3.id])
      expected = {
        character1.id => [[setting1.id, setting1.name]],
        character2.id => [[setting1.id, setting1.name]],
        character3.id => [[setting1.id, setting1.name], [setting2.id, setting2.name]]
      }
      expect(Template.settings_info(association)).to eq(expected)
    end

    it "handles characters with a mixture of settings" do
      character1.update!(setting_ids: [setting1.id])
      character2.update!(setting_ids: [setting2.id])
      character3 = create(:character, user: user, setting_ids: [setting1.id, setting2.id])
      character4 = create(:character, user: user)
      association = Character.where(id: [character1.id, character2.id, character3.id, character4.id])
      expected = {
        character1.id => [[setting1.id, setting1.name]],
        character2.id => [[setting2.id, setting2.name]],
        character3.id => [[setting1.id, setting1.name], [setting2.id, setting2.name]]
      }
      expect(Template.settings_info(association)).to eq(expected)
    end
  end

  describe "#character_list" do
    let (:user) { create(:user, username: 'John Doe') }

    describe "handles simple characters" do
      let (:character1) { create(:character, user: user, name: 'Test Character 1') }
      let (:character2) { create(:character, user: user, name: 'Test Character 2') }
      let (:assoc) { Character.where(id: [character1.id, character2.id]) }

      it "when not showing templates" do
        assoc = Character.where(id: [character1.id, character2.id])
        expected = [
          [character1.id, 'Test Character 1', nil, nil, nil, user.id, 'John Doe', false],
          [character2.id, 'Test Character 2', nil, nil, nil, user.id, 'John Doe', false]
        ]
        expect(Template.characters_list(assoc, false)).to match_array(expected)
      end

      it "when showing templates" do
        assoc = Character.where(id: [character1.id, character2.id])
        expected = [
          [character1.id, 'Test Character 1', nil, nil, nil, user.id, 'John Doe', false, nil, nil],
          [character2.id, 'Test Character 2', nil, nil, nil, user.id, 'John Doe', false, nil, nil]
        ]
        expect(Template.characters_list(assoc, true)).to match_array(expected)
      end

      it "with deleted users" do
        user.update!(deleted: true)
        expected = [
          [character1.id, 'Test Character 1', nil, nil, nil, user.id, 'John Doe', true],
          [character2.id, 'Test Character 2', nil, nil, nil, user.id, 'John Doe', true]
        ]
        expect(Template.characters_list(assoc, false)).to match_array(expected)
      end

      it "from multiple users" do
        user2 = create(:user, username: 'Jane Doe')
        character2.update!(user: user2)
        expected = [
          [character1.id, 'Test Character 1', nil, nil, nil, user.id, 'John Doe', false],
          [character2.id, 'Test Character 2', nil, nil, nil, user2.id, 'Jane Doe', false]
        ]
        expect(Template.characters_list(assoc, false)).to match_array(expected)
      end
    end

    describe "handles complex characters" do
      let (:template1) { create(:template, name: 'Test Template 1')}
      let (:template2) { create(:template, name: 'Test Template 2')}

      let (:character1) do
        create(:character, user: user, template: template1,
               name: 'Test Character 1', screenname: 'screenname_one',
               template_name: "Nickname 1", pb: "Facecast 1")
      end

      let (:character2) do
        create(:character, user: user, template: template2,
               name: 'Test Character 2', screenname: 'screenname_two',
               template_name: "Nickname 2", pb: "Facecast 2")
      end

      let (:assoc) { Character.where(id: [character1.id, character2.id]) }

      it "when showing templates" do
        expected = [
          [character1.id, 'Test Character 1', 'Nickname 1', 'screenname_one',
           'Facecast 1', user.id, 'John Doe', false, template1.id, "Test Template 1"],
          [character2.id, 'Test Character 2', 'Nickname 2', 'screenname_two',
           'Facecast 2', user.id, 'John Doe', false, template2.id, "Test Template 2"]
        ]
        expect(Template.characters_list(assoc, true)).to match_array(expected)
      end

      it "when not showing templates" do
        expected = [
          [character1.id, 'Test Character 1', 'Nickname 1', 'screenname_one', 'Facecast 1', user.id, 'John Doe', false],
          [character2.id, 'Test Character 2', 'Nickname 2', 'screenname_two', 'Facecast 2', user.id, 'John Doe', false]
        ]
        expect(Template.characters_list(assoc, false)).to match_array(expected)
      end
    end

    it "handles a mixture of characters" do
      templateless = create_list(:character, 3, user: user)
      templated = Array.new(3) { create(:character, user: user, template: create(:template)) }
      template = create(:template)
      one_template = create_list(:character, 3, user: user, template: template)
      deleted_user = create_list(:character, 1, user: create(:user, deleted: true))
      other_user = create_list(:character, 2, user: create(:user))
      characters = templateless + templated + one_template + deleted_user + other_user
      assoc = Character.where(id: characters.map(&:id))
      expected = [
        templateless.map{ |char| [char.id, char.name, nil, nil, nil, user.id,      user.username,      false, nil,              nil] },
        templated.map   { |char| [char.id, char.name, nil, nil, nil, user.id,      user.username,      false, char.template.id, char.template.name] },
        one_template.map{ |char| [char.id, char.name, nil, nil, nil, user.id,      user.username,      false, template.id,      template.name] },
        deleted_user.map{ |char| [char.id, char.name, nil, nil, nil, char.user.id, char.user.username, true,  nil,              nil] },
        other_user.map  { |char| [char.id, char.name, nil, nil, nil, char.user.id, char.user.username, false, nil,              nil] },
      ].flatten(1)
      expect(Template.characters_list(assoc, true)).to match_array(expected)
    end
  end
end

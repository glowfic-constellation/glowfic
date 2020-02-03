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

    RSpec.shared_examples "shared tests" do |view|
      it "when not showing templates" do
        expect(Template.characters_list(assoc, page_view: view)).to eq(expected)
      end

      it "from multiple users" do
        user2 = create(:user, username: 'Jane Doe')
        character2.update!(user: user2)
        expected[0][:user_id] = user2.id
        expected[0][:username] = 'Jane Doe' if expected[1].key?(:username)
        expect(Template.characters_list(assoc, page_view: view)).to eq(expected)
      end
    end

    describe "handles simple characters" do
      let! (:character1) { create(:character, user: user, name: 'Test Character b') }
      let! (:character2) { create(:character, user: user, name: 'Test Character a') }
      let (:assoc) { Character.where(id: [character1.id, character2.id]).ordered }

      describe "in icon view" do
        let (:expected) do
          [
            {id: character2.id, name: 'Test Character a', screenname: nil, user_id: user.id, url: nil, keyword: nil},
            {id: character1.id, name: 'Test Character b', screenname: nil, user_id: user.id, url: nil, keyword: nil}
          ]
        end

        include_examples "shared tests", 'icon'
      end

      describe "in list view" do
        let (:view) { 'list' }
        let (:expected) do
          [
            {id: character2.id, name: 'Test Character a', screenname: nil, nickname: nil, pb: nil,
             user_id: user.id, username: 'John Doe', user_deleted: false},
            {id: character1.id, name: 'Test Character b', screenname: nil, nickname: nil, pb: nil,
             user_id: user.id, username: 'John Doe', user_deleted: false}
          ]
        end

        include_examples "shared tests", 'list'

        it "when showing templates" do
          expected.each do |char|
            char[:template_id] = nil
            char[:template_name] = nil
          end
          expect(Template.characters_list(assoc, show_template: true, page_view: view)).to eq(expected)
        end

        it "with deleted users" do
          user.update!(deleted: true)
          expected.each { |char| char[:user_deleted] = true }
          expect(Template.characters_list(assoc, page_view: view)).to eq(expected)
        end
      end
    end

    describe "handles complex characters" do
      let (:template1) { create(:template, user: user, name: 'Test Template b')}
      let (:template2) { create(:template, user: user, name: 'Test Template a')}

      let! (:character1) do
        create(:character, user: user, template: template1,
               name: 'Test Character b', screenname: 'screenname_one',
               template_name: "Nickname 1", pb: "Facecast 1")
      end

      let! (:character2) do
        create(:character, user: user, template: template2,
               name: 'Test Character a', screenname: 'screenname_two',
               template_name: "Nickname 2", pb: "Facecast 2")
      end

      let (:assoc) { Character.where(id: [character1.id, character2.id]).ordered }

      describe "in icon view" do
        let (:expected) do
          [
            {id: character2.id, name: 'Test Character a', screenname: 'screenname_two', user_id: user.id, url: nil, keyword: nil},
            {id: character1.id, name: 'Test Character b', screenname: 'screenname_one', user_id: user.id, url: nil, keyword: nil}
          ]
        end

        include_examples "shared tests", "icon"

        it "with default icons" do
          icon1 = create(:icon, user: user, keyword: 'icon 1', url: 'https://fakeicon.com/1.png')
          icon2 = create(:icon, user: user, keyword: 'icon 2', url: 'https://fakeicon.com/2.png')

          character1.update!(default_icon: icon1)
          character2.update!(default_icon: icon2)

          expected[1][:keyword] = 'icon 1'
          expected[1][:url] = 'https://fakeicon.com/1.png'
          expected[0][:keyword] = 'icon 2'
          expected[0][:url] = 'https://fakeicon.com/2.png'

          expect(Template.characters_list(assoc, page_view: 'icon')).to eq(expected)
        end
      end

      describe "in list view" do
        let (:expected) do
          [{
            id: character2.id, name: 'Test Character a', screenname: 'screenname_two',
            nickname: 'Nickname 2', pb: 'Facecast 2',
            user_id: user.id, username: 'John Doe', user_deleted: false
          },
          {
            id: character1.id, name: 'Test Character b', screenname: 'screenname_one',
            nickname: 'Nickname 1', pb: 'Facecast 1',
            user_id: user.id, username: 'John Doe', user_deleted: false
          }]
        end

        it "when showing templates" do
          expect(Template.characters_list(assoc, page_view: 'list')).to eq(expected)
        end

        include_examples "shared tests", "list"
      end
    end

    describe "handles a mixture of characters" do
      let(:templateless) { create_list(:character, 3, user: user) }
      let(:templated) { Array.new(3) { create(:character, user: user, template: create(:template)) } }
      let(:template) { create(:template) }
      let(:one_template) { create_list(:character, 3, user: user, template: template) }
      let(:deleted_user) { create_list(:character, 1, user: create(:user, deleted: true)) }
      let(:other_user) { create_list(:character, 2, user: create(:user)) }
      let(:characters) { templateless + templated + one_template + deleted_user + other_user }
      let(:assoc) { Character.where(id: characters.map(&:id)).ordered }

      before(:each) do
        templateless[2].update!(name: 'b')
        one_template[1].update!(name: 'a')
        characters.sort_by!{ |char| [char.template_id.to_i, char.name] }
      end

      it "in icon view" do
        expected = characters.map do |char|
          { id: char.id, name: char.name, screenname: nil, user_id: char.user_id, url: nil, keyword: nil }
        end

        expect(Template.characters_list(assoc, page_view: 'icon')).to match_array(expected)
      end

      it "in list view" do
        expected = characters.map do |char|
          {
            id: char.id, name: char.name, screenname: nil, nickname: nil, pb: nil,
            user_id: char.user_id, username: char.user.username, user_deleted: char.user.deleted?,
            template_id: char.template_id, template_name: char.template.try(:name)
          }
        end

        expect(Template.characters_list(assoc, page_view: 'list', show_template: true)).to match_array(expected)
      end
    end
  end
end

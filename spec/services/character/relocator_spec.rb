RSpec.describe Character::Relocator do
  include ActiveJob::TestHelper

  let(:relocator) { Character::Relocator.new(create(:admin_user).id) }
  let(:target) { create(:user).id }
  let(:user) { create(:user) }

  describe 'validations' do
    it 'fails with characters from multiple users' do
      expect { relocator.transfer(create_list(:character, 3).map(&:id), target) }.to raise_error(RequireSingleUser)
    end

    it 'fails with character groups' do
      character = create(:character, user: user, character_group: create(:character_group, user: user))
      expect { relocator.transfer(character, target) }.to raise_error(CharacterGroupError)
    end

    it 'fails with galleries used on other characters' do
      gallery = create(:gallery, user: user)
      character = create(:character, user: user, galleries: [gallery])
      create(:character, user: user, galleries: [gallery])
      expect { relocator.transfer([character.id], target) }.to raise_error(OverlappingGalleriesError)
    end

    it 'fails with icons used on other characters as default icons' do
      icon = create(:icon, user: user)
      character = create(:character, user: user, default_icon: icon)
      create(:character, user: user, default_icon: icon)
      expect { relocator.transfer([character.id], target) }.to raise_error(OverlappingIconsError)
    end

    it 'fails with icons used in other galleries on other characters' do
      icon = create(:icon, user: user)
      gallery1 = create(:gallery, user: user, icons: [icon])
      character = create(:character, user: user, galleries: [gallery1])
      gallery2 = create(:gallery, user: user, icons: [icon])
      create(:character, user: user, galleries: [gallery2])
      expect { relocator.transfer([character.id], target) }.to raise_error(OverlappingIconsError)
    end

    it 'fails with mixed templates' do
      template = create(:template, user: user)
      character = create(:character, user: user, template: template)
      create(:character, user: user, template: template)
      expect { relocator.transfer([character.id], target, include_templates: true) }.to raise_error(OverlappingTemplatesError)
    end

    it 'fails with gallery-user mismatch' do
      gallery = create(:gallery)
      character = create(:character)
      CharactersGallery.create!(gallery_id: gallery.id, character_id: character.id)
      expect { relocator.transfer([character.id], target) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails with icon-user mismatch' do
      icon = create(:icon)
      character = create(:character)
      character.update_columns(default_icon_id: icon.id) # rubocop:disable Rails/SkipsModelValidations
      expect { relocator.transfer([character.id], target) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails with template-user mismatch' do
      template = create(:template)
      character = create(:character)
      character.update_columns(template_id: template.id) # rubocop:disable Rails/SkipsModelValidations
      expect { relocator.transfer([character.id], target, include_templates: true) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'succeeds' do
      char = create(:character, user: user).id
      perform_enqueued_jobs do
        relocator.transfer(char, target)
      end
      expect(Character.find_by(id: char).user_id).to eq(target)
    end
  end

  it 'successfully transfers complex cases' do
    template1 = create(:template, user: user)
    template2 = create(:template, user: user)

    icon1 = create(:icon, user: user)
    icon2 = create(:icon, user: user)
    icon3 = create(:icon, user: user)
    icons = create_list(:icon, 4, user: user)

    gallery1 = create(:gallery, user: user, icons: [icon2, *icons])
    gallery2 = create(:gallery, user: user, icons: [icon3, *icons])

    character1 = create(:character, template: template1, default_icon: icon1, user: user)
    character2 = create(:character, template: template2, galleries: [gallery1, gallery2], default_icon: icon3, user: user)
    character3 = create(:character, template: template2, galleries: [gallery2], default_icon: icon3, user: user)
    character4 = create(:character, template: template2, galleries: [gallery1], default_icon: icon2, user: user)
    character5 = create(:character, user: user)

    post1 = create(:post, user: user, character: character1, icon: icon1)
    post2 = create(:post, user: user, character: character4, icon: icon3)

    reply1 = create(:reply, user: user, post: post2, character: character1)
    reply2 = create(:reply, user: user, post: post2, character: character2)
    reply3 = create(:reply, user: user, character: character1)
    reply4 = create(:reply, user: user, character: character3)
    reply5 = create(:reply, user: user, post: post2, character: character5)

    draft = create(:reply_draft, user: user, character: character2, icon: icon2)

    character_ids = [character1, character2, character3, character4].map(&:id)

    perform_enqueued_jobs do
      relocator.transfer(character_ids, target, include_templates: true)
    end

    expect(template1.reload.user_id).to eq(target)
    expect(template2.reload.user_id).to eq(target)

    icons = Icon.where(id: icons.map(&:id) + [icon1, icon2, icon3].map(&:id))
    expect(icons.pluck(:user_id).uniq).to eq([target])

    expect(gallery1.reload.user_id).to eq(target)
    expect(gallery2.reload.user_id).to eq(target)

    expect(Character.where(id: character_ids).pluck(:user_id).uniq).to eq([target])
    expect(character5.reload.user_id).to eq(user.id)

    post1.reload
    expect(post1.user_id).to eq(target)
    expect(post1.authors.ids).to eq([target])

    post2.reload
    expect(post2.user_id).to eq(target)
    expect(post2.authors.ids).to match_array([user.id, target])

    replies = Reply.where(id: [reply1, reply2, reply3, reply4].map(&:id))
    expect(replies.pluck(:user_id).uniq).to eq([target])
    expect(reply5.reload.user_id).to eq(user.id)

    expect(draft.reload.user_id).to eq(target)
  end
end

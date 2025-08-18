class MigrateCharacterGroups < ActiveRecord::Migration[6.0]
  def up
    characters = Character.where.not(character_group_id: nil)
    templates = Template.where(id: characters.select(:template_id).distinct.pluck(:template_id))
    untemplated_characters = characters.where(template_id: nil)
    group_cross = OldCharacterGroup.ids.to_h { |i| [i, nil] }

    OldCharacterGroup.all.each do |group|
      new = CharacterGroup.create!(name: group.name, user: group.user)
      group_cross[group.id] = new.id
    end

    templates.each do |template|
      group_id = template.characters.where.not(character_group_id: nil),select(:character_group_id).distinct.pluck(:character_group_id)
      raise StandardError, 'Templates should only have one group' if group_id.length > 1
      group_id = group_id.first
      TemplateTag.create!(template: template, tag_id: group_cross[group_id], primary: true)
    end

    untemplated_characters.each do |character|
      CharacterTag.create(character: character, tag_id: group_cross[character.character_group_id], primary: true)
    end
  end

  def down
  end
end

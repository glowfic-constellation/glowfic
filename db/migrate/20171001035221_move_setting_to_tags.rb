class MoveSettingToTags < ActiveRecord::Migration[5.0]
  def up
    print "\nMigrating...\n"
    cached_settings = {}
    total = Character.where.not(setting: nil).count(:all)
    Character.where.not(setting: nil).find_each.with_index do |character, index|
      setting = cached_settings[character.setting]
      setting ||= Setting.where(name: character.setting).first
      setting ||= Setting.create!(user: character.user, name: character.setting)
      cached_settings[character.setting] ||= setting
      character.settings << setting
      print "\r#{index + 1} / #{total} migrated"
    end
    print "\nDone!\n\n"
    remove_column :characters, :setting
  end

  def down
    add_column :characters, :setting, :text
    Setting.all.each do |setting|
      setting.character_tags.each do |tag|
        tag.character.update_attributes!(setting: setting.name)
        tag.destroy!
      end
    end
  end
end

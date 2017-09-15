class SetCharacterDefaultIcons < ActiveRecord::Migration[4.2]
  def up
    Character.where(default_icon_id: nil).includes(:galleries).find_each do |char|
      next if char.galleries.blank?
      char.default_icon = char.galleries.detect(&:default_icon).try(:default_icon)
      char.save!
    end
  end

  def down
    raise(ActiveRecord::IrreversibleMigration, "Cannot undo setting character default icons")
  end
end

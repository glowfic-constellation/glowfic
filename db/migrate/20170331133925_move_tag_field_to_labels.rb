class MoveTagFieldToLabels < ActiveRecord::Migration
  def up
    Tag.where(type: nil).update_all(type: 'Label')
  end

  def down
    Tag.where(type: 'Label').update_all(type: nil)
  end
end

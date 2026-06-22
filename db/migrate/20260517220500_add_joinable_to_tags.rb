class AddJoinableToTags < ActiveRecord::Migration[7.2]
  def change
    add_column :tags, :joinable, :boolean, default: false, null: false
  end
end

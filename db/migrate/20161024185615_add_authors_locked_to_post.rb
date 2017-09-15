class AddAuthorsLockedToPost < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :authors_locked, :boolean, default: false
  end
end

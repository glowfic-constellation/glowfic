class AddAuthorsLockedToPost < ActiveRecord::Migration
  def change
    add_column :posts, :authors_locked, :boolean, default: false
  end
end

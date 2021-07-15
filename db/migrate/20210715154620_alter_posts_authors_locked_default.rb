class AlterPostsAuthorsLockedDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :posts, :authors_locked, true
  end
end

class AlterPostsAuthorsLockedDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :posts, :authors_locked, from: false, to: true
  end
end

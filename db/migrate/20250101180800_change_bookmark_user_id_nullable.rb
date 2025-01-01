class ChangeBookmarkUserIdNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bookmarks, :user_id, true
  end
end

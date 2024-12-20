class RenameUserBookmarks < ActiveRecord::Migration[7.2]
  def change
    rename_table :user_bookmarks, :bookmarks
  end
end

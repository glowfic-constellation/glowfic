class AddEditorModeToReplies < ActiveRecord::Migration[5.2]
  def up
    add_column :replies, :editor_mode, :string
    add_column :reply_drafts, :editor_mode, :string
    add_column :posts, :editor_mode, :string
  end

  def down
    remove_column :replies, :editor_mode, :string
    remove_column :reply_drafts, :editor_mode, :string
    remove_column :posts, :editor_mode, :string
  end
end

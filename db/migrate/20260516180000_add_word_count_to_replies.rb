class AddWordCountToReplies < ActiveRecord::Migration[8.0]
  def change
    add_column :replies, :word_count, :integer
  end
end

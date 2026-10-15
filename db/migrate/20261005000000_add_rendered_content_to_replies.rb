class AddRenderedContentToReplies < ActiveRecord::Migration[8.1]
  def change
    change_table :replies, bulk: true do |t|
      t.text :rendered_content
      t.integer :rendered_content_version
    end
  end
end

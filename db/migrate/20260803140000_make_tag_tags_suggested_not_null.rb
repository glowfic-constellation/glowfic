# frozen_string_literal: true
class MakeTagTagsSuggestedNotNull < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE tag_tags SET suggested = false WHERE suggested IS NULL")
    change_table :tag_tags, bulk: true do |t|
      t.change_null :suggested, false
      t.change_default :suggested, from: nil, to: false
    end
  end

  def down
    change_column_null :tag_tags, :suggested, true
  end
end

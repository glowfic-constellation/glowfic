class AddLastReadReplyToPostViews < ActiveRecord::Migration[8.0]
  def change
    add_reference :post_views, :last_read_reply, type: :integer, index: true
  end
end

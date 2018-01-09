class AddReplyOrderToReplies < ActiveRecord::Migration[5.1]
  def up
    add_column :replies, :reply_order, :integer
    Post.find_each do |post|
      post.replies.order(id: :asc).each_with_index do |reply, i|
        reply.update_attributes(reply_order: i)
      end
    end
  end

  def down
    remove_column :replies, :reply_order, :integer
  end
end

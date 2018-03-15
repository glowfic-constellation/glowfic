class AddReplyOrderToReplies < ActiveRecord::Migration[5.1]
  def up
    add_column :replies, :reply_order, :integer
    add_index :replies, :reply_order
    execute <<-SQL
WITH v_replies AS
(
  SELECT ROW_NUMBER() OVER(PARTITION BY replies.post_id ORDER BY replies.id asc) AS rn, id FROM replies
)
UPDATE replies
SET reply_order = v_replies.rn-1
FROM v_replies
WHERE replies.id = v_replies.id;
    SQL
  end

  def down
    remove_column :replies, :reply_order, :integer
  end
end

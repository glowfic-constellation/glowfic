class IncrementReplyOrder < ActiveRecord::Migration[8.0]
  def change
    Reply.update_all('reply_order = reply_order + 1')
  end
end

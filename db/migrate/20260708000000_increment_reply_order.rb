class IncrementReplyOrder < ActiveRecord::Migration[8.0]
  def up
    Reply.update_all('reply_order = reply_order + 1') # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    Reply.update_all('reply_order = reply_order - 1') # rubocop:disable Rails/SkipsModelValidations
  end
end

Reply.where(new_order: nil).in_batches do |replies|
  Reply.transaction do
    puts "Migrating replies #{replies.first.id} through #{replies.last.id}"
    replies.update_all('new_order = reply_order + 1')
  end
end

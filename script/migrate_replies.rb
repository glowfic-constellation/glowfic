BATCH_SIZE = 1000

replies = Reply.where(new_order: nil)

total = replies.count/BATCH_SIZE

total.times do |i|
  Reply.transaction do
    local_replies = Reply.where(new_order: nil).order(:id).limit(BATCH_SIZE)
    first_id = local_replies.order(id: :asc).limit(1).pluck(:id).first
    puts "Migrating replies from #{first_id} (batch #{i+1}/#{total})"
    local_replies.update_all('new_order = reply_order + 1') # rubocop:disable Rails/SkipsModelValidations
  end
end

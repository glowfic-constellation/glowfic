def collect_written
  replies = Reply.where(editor_mode: nil) + ReplyDraft.where(editor_mode: nil)
  replies.each do |reply|
    update_written(reply)
  end
end

def update_written(reply)
  return 'html' unless reply.content.present?
  if reply.content[WritableHelper::P_TAG] || reply.content[WritableHelper::BR_TAG]
    reply.update_columns(editor_mode: 'rtf') # rubocop:disable Rails/SkipsModelValidations
  else
    reply.update_columns(editor_mode: 'html') # rubocop:disable Rails/SkipsModelValidations
  end
end

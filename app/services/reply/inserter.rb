# TODO refactor RepliesController#restore to use this
class Reply::Inserter < Object
  def initialize(admin_id)
    @audited_user_id = admin_id
  end

  def insert_after(after_reply_id, new_reply_attributes)
    return false unless validate_user
    return false unless validate_after(after_reply_id)
    return false unless validate_reply(new_reply_attributes)
    insert_reply
  end

  private

  def validate_user
    admin_user = User.find_by_id(@audited_user_id)
    return false unless admin_user&.has_permission?(:insert_replies)
    true # TODO support post users
  end

  def validate_after(after_reply_id)
    (@after_reply = Reply.find_by_id(after_reply_id)).present?
  end

  def validate_reply(new_reply_attributes)
    @new_reply = Reply.new(new_reply_attributes)
    @new_reply.is_import = true
    @new_reply.skip_notify = true
    @new_reply.valid?
  end

  def insert_reply
    # TODO use reply_order not id if possible (audits may not be possible bc we may not audit it)
    following_replies = @new_reply.post.replies.where('id > ?', new_reply.id).order(id: :asc)
    @new_reply.skip_post_update = following_replies.exists?
    @new_reply.reply_order = following_replies.first&.reply_order

    # TODO handle failure cases cleanly
    Reply.transaction do
      following_replies.update_all('reply_order = reply_order + 1') # rubocop:disable Rails/SkipsModelValidations
      new_reply.save!
    end
  end
end

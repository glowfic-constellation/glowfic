class EmailPostHasNewReplyJob < BaseJob
  @queue = :email

  def self.process(user_id, reply_id)
    Rails.logger.info("[EmailPostHasNewReplyJob] sending mail to #{user_id} about reply #{reply_id} ")
    return unless user = User.find_by_id(user_id)
    return unless user.email.present?
    return unless user.email_notifications?
    return unless reply = Reply.find_by_id(reply_id)
    UserMailer.post_has_new_reply(user, reply).deliver
  end
end

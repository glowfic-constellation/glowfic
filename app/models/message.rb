class Message < ActiveRecord::Base
  belongs_to :sender, class_name: User, inverse_of: :sent_messages
  belongs_to :recipient, class_name: User, inverse_of: :messages
  belongs_to :parent, class_name: Message

  validates_presence_of :sender, :recipient

  after_create :set_thread_id, :notify_recipient
  attr_accessor :skip_notify

  def visible_to?(user)
    user_ids.include?(user.id)
  end

  def unempty_subject
    return '(no title)' if subject.blank?
    subject
  end

  def subject_from_parent
    @subject ||= "Re: " + (parent.subject.starts_with?('Re: ') ? parent.subject[4..-1] : parent.subject)
  end

  def box(user)
    @box ||= (sender_id == user.id ? 'outbox' : 'inbox')
  end

  def user_ids
    [sender_id, recipient_id]
  end

  private

  def set_thread_id
    return unless thread_id.blank?
    update_attributes(thread_id: id)
  end

  def notify_recipient
    return if skip_notify
    return if recipient_id == sender_id
    return unless recipient.email.present?
    return unless recipient.email_notifications?
    UserMailer.new_message(self.id).deliver
  end
end

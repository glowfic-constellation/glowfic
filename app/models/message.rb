class Message < ActiveRecord::Base
  belongs_to :sender, class_name: User, inverse_of: :sent_messages
  belongs_to :recipient, class_name: User, inverse_of: :messages
  belongs_to :parent, class_name: Message
  belongs_to :first_thread, class_name: Message, foreign_key: :thread_id

  validates_presence_of :sender, :recipient

  after_create :set_thread_id, :notify_recipient

  def visible_to?(user)
    user_ids.include?(user.id)
  end

  def unempty_subject
    return first_thread.unempty_subject if thread_id != id
    return '(no title)' if subject.blank?
    subject
  end

  def short_message
    return message if message.length <= 100
    message[0...100] + '...'
  end

  def last_in_thread
    return self if thread_id == id
    @last ||= self.class.where(thread_id: thread_id).order('id desc').first
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

  def num_in_thread
    self.class.where(thread_id: thread_id).count
  end

  private

  def set_thread_id
    return unless thread_id.blank?
    update_attributes(thread_id: id)
  end

  def notify_recipient
    return if recipient_id == sender_id
    return unless recipient.email.present?
    return unless recipient.email_notifications?
    UserMailer.new_message(self.id).deliver
  end
end

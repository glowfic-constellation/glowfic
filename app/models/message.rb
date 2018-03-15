class Message < ApplicationRecord
  # TODO drop marked_*
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages, optional: true
  belongs_to :recipient, class_name: 'User', inverse_of: :messages, optional: false
  belongs_to :parent, class_name: 'Message', inverse_of: false, optional: true
  belongs_to :first_thread, class_name: 'Message', foreign_key: :thread_id, inverse_of: false, optional: false

  validates :sender, presence: { if: Proc.new { |m| m.sender_id != 0 } }

  before_validation :set_thread_id
  after_create :notify_recipient

  def visible_to?(user)
    user_ids.include?(user.id)
  end

  def unempty_subject
    return first_thread.unempty_subject if thread_id != id
    return '(no title)' if subject.blank?
    subject
  end

  def last_in_thread
    return self if thread_id == id
    @last ||= self.class.where(thread_id: thread_id).order('id desc').first
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

  def sender_name
    return 'Glowfic Constellation' if site_message?
    sender.username
  end

  def site_message?
    sender_id.to_i.zero?
  end

  def self.send_site_message(user_id, subject, message)
    msg = Message.new(recipient_id: user_id, subject: subject, message: message)
    msg.sender_id = 0
    msg.save
  end

  private

  def set_thread_id
    return unless thread_id.blank?
    self.first_thread = self
  end

  def notify_recipient
    return if recipient_id == sender_id
    return unless recipient.email.present?
    return unless recipient.email_notifications?
    UserMailer.new_message(self.id).deliver
  end
end

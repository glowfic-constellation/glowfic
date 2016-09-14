class Message < ActiveRecord::Base
  belongs_to :sender, class_name: User, inverse_of: :sent_messages
  belongs_to :recipient, class_name: User, inverse_of: :messages
  belongs_to :parent, class_name: Message

  validates_presence_of :sender, :recipient

  after_create :set_thread_id

  def visible_to?(user)
    [sender_id, recipient_id].include?(user.id)
  end
  
  def unempty_subject
    if subject.blank?
      '(no title)'
    else
      subject
    end
  end

  def subject_from_parent
    @subject ||= "Re: " + (parent.subject.starts_with?('Re: ') ? parent.subject[4..-1] : parent.subject)
  end

  def box(user)
    @box ||= (sender_id == user.id ? 'outbox' : 'inbox')
  end

  private

  def set_thread_id
    return unless thread_id.blank?
    update_attributes(thread_id: id)
  end
end

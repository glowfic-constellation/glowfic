class Message < ActiveRecord::Base
  belongs_to :sender, class_name: User, inverse_of: :sent_messages
  belongs_to :recipient, class_name: User, inverse_of: :messages

  validates_presence_of :sender, :recipient

  def visible_to?(user)
    [sender_id, recipient_id].include?(user.id)
  end
end

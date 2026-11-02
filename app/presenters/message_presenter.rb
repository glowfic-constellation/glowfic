# frozen_string_literal: true
class MessagePresenter
  attr_reader :message

  def initialize(message)
    @message = message
  end

  # Pass viewer: current_user to include the read state.
  # The read state is only shown to the recipient, as on the HTML pages.
  def as_json(options={})
    json = {
      id: message.id,
      thread_id: message.thread_id,
      parent_id: message.parent_id,
      subject: message.subject,
      message: message.message,
      created_at: message.created_at,
      site_message: message.site_message?,
      sender: sender,
      recipient: message.recipient.as_json,
    }
    viewer = options[:viewer]
    json[:unread] = message.unread? if viewer && message.recipient_id == viewer.id
    json
  end

  private

  def sender
    return if message.site_message?
    message.sender.as_json
  end
end

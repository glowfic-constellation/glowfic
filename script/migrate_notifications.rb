# frozen_string_literal: true
def migrate_notifications
  site_messages = Message.where(sender_id: 0, notification_id: nil).ordered_by_id
  import_success_messages = site_messages.where(subject: 'Post import succeeded')
  import_failure_messages = site_messages.where(subject: 'Post import failed')
  new_favorite_messages = site_messages.where('subject like ?', 'New post by%')
  joined_favorite_messages = site_messages.where('subject like ?', '%has joined a new thread')

  create_notifications(import_success_messages, :import_success)
  create_notifications(new_favorite_messages, :new_favorite_post)
  create_notifications(joined_favorite_messages, :joined_favorite_post)

  import_failure_messages.find_each do |message|
    create_import_failure_notification(message)
  end
end

def create_notifications(association, type)
  association.find_each do |message|
    notification = setup_notification(message, type)
    notification.post_id = find_post_id(message)
    notification.save!
    message.update!(notification_id: notification.id)
  end
end

def create_import_failure_notification(message)
  notification = setup_notification(message, :import_fail)
  content = Nokogiri::HTML(message.message)
  links = content.css('a')

  if links.length == 2 # AlreadyImportedError messages will have two links; the original url and the post
    notification.post_id = find_post_id(message, links.last[:href])
  else
    notification.error_msg = content.at_css('p').children.last.to_s.delete_prefix(' could not be successfully scraped. ')
  end

  notification.save!
  message.update!(notification_id: notification.id)
end

def setup_notification(message, type)
  Notification.new(
    user: message.recipient,
    notification_type: type,
    unread: message.unread,
    read_at: message.read_at,
    created_at: message.created_at,
    updated_at: message.updated_at,
    skip_email: true,
  )
end

def find_post_id(message, link=nil)
  content = Nokogiri::HTML(message.message)
  link ||= content.at_css('a')[:href]
  post_id = URI(link).path.split('/').last.to_i
  raise StandardError "Unable to find post #{post_id}" unless Post.find_by(id: post_id)
  post_id
end

migrate_notifications if $PROGRAM_NAME == __FILE__

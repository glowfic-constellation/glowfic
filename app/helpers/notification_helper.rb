# frozen_string_literal: true
module NotificationHelper
  NOTIFICATION_MESSAGES = {
    'import_success'         => 'Post import succeeded',
    'import_fail'            => 'Post import failed',
    'new_favorite_post'      => 'An author you favorited has written a new post',
    'joined_favorite_post'   => 'An author you favorited has joined a post',
    'wrangling_scope_merged' => 'Your tag wrangling scope has changed',
    'tag_suggested'          => 'A reader suggested a tag on your post',
  }

  def subject_for_type(notification_type)
    NOTIFICATION_MESSAGES[notification_type]
  end
end

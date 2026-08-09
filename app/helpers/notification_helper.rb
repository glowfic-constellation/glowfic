# frozen_string_literal: true
module NotificationHelper
  NOTIFICATION_MESSAGES = {
    'import_success'       => 'Post import succeeded',
    'import_fail'          => 'Post import failed',
    'new_favorite_post'    => 'An author you favorited has written a new post',
    'joined_favorite_post' => 'An author you favorited has joined a post',
    'post_merged_author'   => 'A post you were an author of has been merged into another post',
    'source_post_merged'   => 'A post you had opened has been merged into another post',
    'target_post_merged'   => 'A post has been merged into another post you had opened',
  }

  def subject_for_type(notification_type)
    NOTIFICATION_MESSAGES[notification_type]
  end
end

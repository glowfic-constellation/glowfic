# frozen_string_literal: true
module NotificationHelper
  NOTIFICATION_MESSAGES = {
    nil     => {
      'import_success'       => 'Post import succeeded',
      'import_fail'          => 'Post import failed',
      'new_favorite_post'    => 'A once-favorited subject has a new post',
      'joined_favorite_post' => 'A once-favorited author has joined a post',
    },
    'user'  => {
      'new_favorite_post'    => 'An author you favorited has written a new post',
      'joined_favorite_post' => 'An author you favorited has joined a post',
    },
    'board' => {
      'new_favorite_post' => 'An continuity you favorited has a new post',
    },
  }

  def subject_for_type(notification_type, favorite_type)
    NOTIFICATION_MESSAGES[favorite_type][notification_type]
  end
end

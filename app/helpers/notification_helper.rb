module NotificationHelper
  NOTIFICATION_MESSAGES = {
    'import_success'           => 'Post import succeeded',
    'import_fail'              => 'Post import failed',
    'new_favorite_post'        => 'An author you favorited has written a new post',
    'joined_favorite_post'     => 'An author you favorited has joined a post',
    'accessible_favorite_post' => 'An author you favorited has given you access to a post',
    'published_favorite_post'  => 'An author you favorited has made a post public',
    'resumed_favorite_post'    => 'A favorite post has resumed',
    'coauthor_invitation'      => 'You have been invited as an author for a post',
  }

  def subject_for_type(notification_type)
    NOTIFICATION_MESSAGES[notification_type]
  end
end

#!/usr/bin/env ruby

layout = ARGV[0] || nil
user = User.find_by(username: "Kappa")

unless layout.nil?
  if layout == 'default'
    user.update!(layout: nil)
  else
    user.update!(layout: layout)
  end
end

Message.find_by(id: 4).update!(unread: true)
post = Post.find_by(id: 33)
post.mark_read(user, (post.replies.first.created_at - 5.seconds), true)

FlatPost.find_by(post_id: 3).update!(updated_at: "2012-09-13 02:00:00")

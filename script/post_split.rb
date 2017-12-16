new_subject = 'test subject'
reply_user = 'Throne3d'
reply_id = 1024

Post.transaction do
  user = User.find_by(username: reply_user)
  abort("needs user") unless user
  reply = Reply.find_by(user_id: user.id, id: reply_id)
  abort("couldn't find reply") unless reply
  post = reply.post
  puts "splitting post #{post.id}: #{post.subject}"

  first_reply = post.replies.where('id > ?', reply.id).order('id asc').first
  other_replies = post.replies.where('id > ?', first_reply.id).order('id asc')
  puts "from after reply #{reply.id} (#{first_reply} onwards)"
  new_post = Post.new

  [:character_id, :icon_id, :character_alias_id, :user_id, :content, :created_at, :updated_at].each do |atr|
    new_value = first_reply.send(atr)
    puts "new_post.#{atr} = #{new_value.inspect}"
    new_post.send(atr.to_s + '=', new_value)
  end

  [:board_id, :section_id].each do |atr|
    new_value = post.send(atr)
    puts "new_post.#{atr} = #{new_value.inspect}"
    new_post.send(atr.to_s + '=', new_value)
  end
  puts "new subject: #{new_subject}"
  new_post.subject = new_subject
  new_post.save!
  puts "new post: https://glowfic.com/posts/#{new_post.id}"

  puts "now updating #{other_replies.count} replies to be in post ID #{new_post.id}"
  other_replies.update_all(post_id: new_post.id)
end

exclude = Reply.where(reply_order: 0).select(:post_id)

Post.where.not(id: exclude).find_in_batches(batch_size: 500) do |posts|
  Post.transaction do
    puts "Creating writtens for posts #{posts.first.id} through #{posts.last.id}"
    post.each do |post|
      post.replies.create!(
        reply_order: 0,
        content: content,
        icon: icon,
        character: character,
        character_alias: character_alias,
        created_at: created_at,
        updated_at: edited_at,
      )
    end
  end
end

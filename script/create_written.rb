exclude = Reply.where(reply_order: 0).select(:post_id)

Post.where.not(id: exclude).find_in_batches(batch_size: 500) do |posts|
  Post.transaction do
    puts "Creating writtens for posts #{posts.first.id} through #{posts.last.id}"
    post.each do |post|
      reply = post.replies.create!(
        reply_order: 0,
        content: content,
        icon: icon,
        character: character,
        character_alias: character_alias,
        created_at: created_at,
        updated_at: edited_at,
      )
      audits = post.audits.where("audits.audited_changes ?| array['content', 'icon_id', 'character_id', 'character_alias_id']")
      audits.each do |audit|
        reply.audits.create!(
          user_id: audit.user_id,
          user_type: audit.user_type,
          action: audit.action,
          audited_changes: audit.audited_changes,
          version: audit.version,
          remote_address: audit.remote_address,
          created_at: audit.created_at,
          request_uuid: audit.request_uuid,
        )
      end
    end
  end
end

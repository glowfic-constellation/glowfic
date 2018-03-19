# Separating out the logic that allows us to split a post into
# two new posts given an arbitrary reply ID to be the new top post.
#
# Intended to be extended and called as class methods, e.g.:
#   Post.split(reply_id_to_be_new_top_post, subject_of_new_post)
#
# Takes all usual Post attribute arguments like privacy or status, but
# only subject is required; the rest default to the same values as
# the original post.

module Splitable
  def split(reply_id,
            subject,
            description='',
            board_id=nil,
            privacy=nil,
            status=nil,
            section_id=0,
            authors_locked=nil)
    return unless (reply = Reply.find_by_id(reply_id))
    board_id ||= reply.post.board_id
    privacy ||= reply.post.privacy
    status ||= reply.post.status
    section_id = reply.post.section_id if section_id.zero? # nil is a valid argument, 0 is not
    authors_locked = reply.post.authors_locked if authors_locked.nil? # false is a valid argument

    old_post = reply.post
    new_post = create_new_post_from_reply(reply, subject, description, privacy, board_id, status, section_id, authors_locked)

    migrate_replies_to_new_post(reply, new_post)
    reply.delete

    fix_post_and_authors(new_post, old_post.id)
    fix_post_and_authors(old_post, new_post.id)

    # TODO deal with PostViews

    new_post
  end

  private

  def create_new_post_from_reply(reply, subject, description, privacy, board_id, status, section_id, authors_locked)
    post = Post.new(subject: subject, description: description, privacy: privacy, board_id: board_id, status: status, section_id: section_id, authors_locked: authors_locked)
    post.content = reply.content
    post.character_id = reply.character_id
    post.user_id = reply.user_id
    post.icon_id = reply.icon_id
    post.character_alias_id = reply.character_alias_id
    post.created_at = reply.created_at
    post.edited_at = reply.updated_at

    post.skip_edited = post.is_import = true
    post.save
  end

  def migrate_replies_to_new_post(reply, post)
    replies = Reply.where(post_id: reply.post_id).where('reply_order > ?', reply.reply_order).order(:reply_order)
    replies.update_all(post_id: post.id)
    replies.each_with_index do |reply, index|
      reply.update_columns(reply_order: index)
    end
  end

  def fix_post_and_authors(post, other_post_id)
    last_reply = post.replies.order(:reply_order).last
    post.update_columns(
      last_reply_id: last_reply.id,
      last_user_id: last_reply.user_id,
      tagged_at: last_reply.created_at)

    post_author_ids = post.replies.group(:user_id).pluck(:user_id)
    post_author_ids.each do |author_id|
      next if PostAuthor.where(post_id: post.id, user_id: author_id).exists? # TODO plausibly wrong
      existing = PostAuthor.find_by(post_id: other_post_id, user_id: author_id)
      first_by_author = post.replies.where(user_id: author_id).order(:reply_order).first.created_at
      PostAuthor.create(user_id: author_id,
                        post_id: post.id,
                        created_at: existing.created_at,
                        updated_at: existing.updated_at,
                        can_owe: existing.can_owe,
                        can_reply: existing.can_reply,
                        joined: existing.joined,
                        joined_at: first_by_author)
    end
    post.replies.post_authors.where.not(user_id: post_author_ids).destroy_all
  end
end

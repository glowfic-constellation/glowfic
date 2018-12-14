class PostFlatten < Object
  def initialize(post_id, reply_id: nil)
    @post_id = post_id
    @reply_id = reply_id
  end

  def update
    if @reply_id.present?
      append
    else
      regenerate
    end
  end

  def self.regenerate_all(before=nil, override=true)
    # uses Post instead of FlatPost in case any are missing
    Post.includes(:flat_post).find_each do |post|
      unless post.flat_post
        # ignore arguments because posts should always have a flat post object and this is Bad
        GenerateFlatPostJob.enqueue(post.id)
        next
      end

      next if before.present? && post.flat_post.updated_at >= before
      next if !override && post.flat_post.updated_at >= post.tagged_at
      GenerateFlatPostJob.enqueue(post.id)
    end
  end

  private

  def append
    reply = Reply.find_by_id(@reply_id)
    return unless reply # TODO what?
    # TODO detect reply id in existing flat post, out of order mismatch

    new_content = view.render(partial: 'posts/flat_reply', locals: {reply: reply})
    update_content(post.flat_post.content.to_s + new_content)
  end

  def regenerate
    replies = post.replies
      .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
      .joins(:user)
      .left_outer_joins(:character)
      .left_outer_joins(:icon)
      .ordered

    content = view.render(partial: 'posts/generate_flat', locals: {replies: replies})
    update_content(content)
  end

  def view
    return @view if @view
    @view = ActionView::Base.new(ActionController::Base.view_paths, {})
    @view.extend ApplicationHelper
    @view
  end

  def post
    @post ||= Post.find_by_id(@post_id) # TODO what if nil?
  end

  def update_content(content)
    flat_post = post.flat_post
    flat_post.content = content
    flat_post.save!
  end
end

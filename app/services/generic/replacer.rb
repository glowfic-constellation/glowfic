class Generic::Replacer < Generic::Service
  attr_reader :alts, :posts, :gallery

  def initialize
    super
  end

  def setup(no_icon_url)
    @alts = find_alts
    @posts = find_posts
    @gallery = construct_gallery(no_icon_url)
  end

  def replace
  end

  def replace_jobs(wheres:, updates:, post_ids: nil)
    UpdateModelJob.perform_later(Reply.to_s, wheres, updates)
    wheres[:id] = wheres.delete(:post_id) if post_ids.present?
    UpdateModelJob.perform_later(Post.to_s, wheres, updates)
  end

  def find_posts(wheres)
    post_ids = Reply.where(wheres).select(:post_id).distinct.pluck(:post_id)
    Post.where(wheres).or(Post.where(id: post_ids)).distinct
  end
end

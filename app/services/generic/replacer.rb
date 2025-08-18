class Generic::Replacer < Generic::Service
  attr_reader :alts, :posts, :gallery

  def setup(no_icon_url)
    @alts = find_alts
    @posts = find_posts
    @gallery = construct_gallery(no_icon_url)
  end

  private

  def replace_jobs(wheres:, updates:, post_ids: nil)
    UpdateModelJob.perform_later(Reply.to_s, wheres, updates)
    wheres[:id] = wheres.delete(:post_id) if post_ids.present?
    UpdateModelJob.perform_later(Post.to_s, wheres, updates)
  end

  def find_posts(wheres)
    post_ids = Reply.where(wheres).select(:post_id).distinct.pluck(:post_id)
    Post.where(wheres).or(Post.where(id: post_ids)).distinct
  end

  def check_target(klass, id:, user:)
    model_key = klass.model_name.param_key.to_sym
    model_name = klass.model_name.human.downcase
    @errors.add(model_key, "could not be found.") unless id.blank? || (new_model = klass.find_by(id: id))
    @errors.add(:base, "You do not have permission to modify this #{model_name}.") if new_model && new_model.user_id != user.id
    new_model
  end
end

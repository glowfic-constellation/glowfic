class PostPresenter
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def as_json(options={})
    return {} unless post

    attrs = %w(id status subject description content created_at edited_at tagged_at)
    post_json = post.as_json_without_presenter(only: attrs)
    post_json.merge({
      board: post.board,
      section: post.section,
      user: post.user,
      character: post.character,
      icon: post.icon,
      replies: options[:replies] || post.replies.order('id asc') })
  end
end

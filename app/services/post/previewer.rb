class Post::Previewer < Post::Saver
  attr_reader :author_ids, :viewer_ids, :settings, :warnings, :labels

  def perform
    @post.assign_attributes(permitted_params(false))
    @post.board ||= Board.find_by_id(3)

    @author_ids = @params.fetch(:post, {}).fetch(:unjoined_author_ids, []).map(&:to_i)
    @viewer_ids = @params.fetch(:post, {}).fetch(:viewer_ids, [])
  end
end

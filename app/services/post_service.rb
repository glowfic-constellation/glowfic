class PostService < Object
  attr_reader :post, :params

  def initialize(post)
    @post = post
  end

  def update_post!(params, current_user)
    mark_unread and return if params[:unread].present?
    mark_hidden and return if params[:hidden].present?

    check_permissions!(current_user)

    change_status and return if params[:status].present?
    change_authors_locked and return if params[:authors_locked].present?

    @post.assign_attributes(params[:post])
    @post.board ||= Board.find(3)

    preview and return if params[:button_preview].present?

    @post.build_new_tags_with(current_user)
    @post.save!
  end

  def check_permissions!(current_user)
    raise UnauthorizedError.new unless @post.editable_by?(current_user) || @post.metadata_editable_by?(current_user)
  end
end

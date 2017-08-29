class Api::V1::PostsController < Api::ApiController
  before_filter :login_required, except: :show
  resource_description do
    description 'Viewing and editing posts'
  end

  api! 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def show
    unless (post = Post.find_by_id(params[:id]))
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless post.visible_to?(current_user)
    render json: post
  end

  api! 'Update the order of posts. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Board is not editable by the user"
  error 404, "Post IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_post_ids, Array, allow_blank: false
  param :section_id, :number, required: false
  def reorder
    section_id = params[:section_id] ? params[:section_id].to_i : nil
    post_ids = params[:ordered_post_ids].map(&:to_i).uniq
    posts = Post.where(id: post_ids)
    posts_count = posts.count
    unless posts_count == post_ids.count
      missing_posts = post_ids - posts.pluck(:id)
      error = {message: "Some posts could not be found: #{missing_posts * ', '}"}
      render json: {errors: [error]}, status: :not_found and return
    end

    boards = Board.where(id: posts.pluck('distinct board_id'))
    unless boards.count == 1
      error = {message: 'Posts must be from one board'}
      render json: {errors: [error]}, status: :unprocessable_entity and return
    end

    board = boards.first
    access_denied and return unless board.editable_by?(current_user)

    post_section_ids = posts.pluck('distinct section_id')
    unless post_section_ids == [section_id] &&
      (section_id.nil? || BoardSection.where(id: section_id, board_id: board.id).exists?)
      error = {message: 'Posts must be from one specified section in the board, or no section'}
      render json: {errors: [error]}, status: :unprocessable_entity and return
    end

    Post.transaction do
      posts = posts.sort_by {|post| post_ids.index(post.id) }
      posts.each_with_index do |post, index|
        next if post.section_order == index
        post.update_attributes(section_order: index)
      end

      other_posts = Post.where(board_id: board.id, section_id: section_id).where.not(id: post_ids).order('section_order asc')
      other_posts.each_with_index do |post, i|
        index = i + posts_count
        next if post.section_order == index
        post.update_attributes(section_order: index)
      end
    end

    posts = Post.where(board_id: board.id, section_id: section_id)
    render json: {post_ids: posts.order('section_order asc').pluck(:id)}
  end
end

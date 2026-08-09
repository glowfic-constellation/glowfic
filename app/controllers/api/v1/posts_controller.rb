# frozen_string_literal: true
class Api::V1::PostsController < Api::ApiController
  before_action :login_required, except: [:index, :show]
  before_action :find_post, only: [:show, :update]

  resource_description do
    description 'Viewing and editing posts'
  end

  api :GET, '/posts', 'Load all posts optionally filtered by subject'
  param :q, String, required: false, desc: 'Subject search term'
  param :min, String, required: false, desc: 'If present, returns only ID and subject per post'
  def index
    queryset = Post.order(Arel.sql('LOWER(subject) asc'))
    queryset = queryset.where('subject ILIKE ?', "%#{params[:q]}%") if params[:q].present?

    posts = paginate queryset, per_page: 25
    posts = posts.visible_to(current_user)
    render json: { results: posts.as_json(min: params[:min].present?) }
  end

  api :GET, '/posts/:id', 'Load a single post as a JSON resource'
  param :id, :number, required: true, desc: "Post ID"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def show
    render json: @post.as_json(include: [:character, :icon, :content])
  end

  api :PATCH, '/posts/:id', 'Update a single post. Currently only supports saving the private note for an author.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Post ID"
  param :private_note, String, required: true, allow_blank: true, desc: "Author's private notes about this post"
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  error 422, "Invalid parameters provided"
  def update
    author = @post.author_for(current_user)
    unless author.present?
      access_denied
      return
    end

    unless author.update(private_note: params[:private_note])
      error = { message: 'Post could not be updated.' }
      render json: { errors: [error] }, status: :unprocessable_content
      return
    end

    if author.private_note.present?
      render json: { private_note: helpers.sanitize_written_content(author.private_note) }
    else
      render json: { private_note: "" }
    end
  end

  api :POST, '/posts/reorder', 'Update the order of posts within their main continuity. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Continuity is not editable by the user"
  error 404, "Post IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_post_ids, Array, allow_blank: false
  param :section_id, :number, required: false
  def reorder
    section_id = params[:section_id]&.to_i
    post_ids = params[:ordered_post_ids].map(&:to_i).uniq

    # Board pages pass the continuity whose ordering is being edited, since posts may be in
    # it secondarily; without it, fall back to the posts' main continuities.
    post_boards = if params[:board_id].present?
      PostBoard.where(board_id: params[:board_id], post_id: post_ids)
    else
      PostBoard.main.where(post_id: post_ids)
    end
    unless post_boards.count == post_ids.count
      missing_posts = post_ids - post_boards.pluck(:post_id)
      error = { message: "Some posts could not be found: #{missing_posts * ', '}" }
      render json: { errors: [error] }, status: :not_found and return
    end

    board_ids = post_boards.distinct.pluck(:board_id)
    unless board_ids.one?
      error = { message: 'Posts must be from one continuity' }
      render json: { errors: [error] }, status: :unprocessable_content and return
    end

    board = Board.find(board_ids.first)
    access_denied and return unless board.editable_by?(current_user)

    post_boards_section_ids = post_boards.distinct.pluck(:section_id)
    unless post_boards_section_ids == [section_id] &&
           (section_id.nil? || BoardSection.where(id: section_id, board_id: board.id).exists?)
      error = { message: 'Posts must be from one specified section in the continuity, or no section' }
      render json: { errors: [error] }, status: :unprocessable_content and return
    end

    PostBoard.transaction do
      section_scope = PostBoard.where(board_id: board.id, section_id: section_id)
      all_section_pbs = section_scope.ordered_in_section.to_a
      visible_post_ids = Post.where(id: all_section_pbs.map(&:post_id)).visible_to(current_user).pluck(:id).to_set
      post_id_set = post_ids.to_set

      # Post_boards whose post the editor can't read get anchored to the post in their request that
      # preceded them in the original ordering, so a private post placed between two visible ones
      # stays attached to its predecessor instead of being shoved to the bottom. Posts the editor can
      # read but omitted from the request (the documented "subset reorder" case) still append at the end.
      anchors = {}
      visible_omitted = []
      anchor_id = :start
      all_section_pbs.each do |pb|
        if post_id_set.include?(pb.post_id)
          anchor_id = pb.post_id
        elsif visible_post_ids.include?(pb.post_id)
          visible_omitted << pb
        else
          anchors[pb.post_id] = anchor_id
        end
      end

      anchored_by = Hash.new { |h, k| h[k] = [] }
      all_section_pbs.each do |pb|
        anchored_by[anchors[pb.post_id]] << pb if anchors.key?(pb.post_id)
      end

      ordered_visible = post_boards.to_a.sort_by { |pb| post_ids.index(pb.post_id) }

      new_order = anchored_by[:start].dup
      ordered_visible.each do |pb|
        new_order << pb
        new_order.concat(anchored_by[pb.post_id])
      end
      new_order.concat(visible_omitted)

      new_order.each_with_index do |pb, index|
        next if pb.section_order == index
        pb.update(section_order: index)
      end
    end

    ordered = PostBoard.where(board_id: board.id, section_id: section_id).ordered_in_section.to_a
    visible_ids = Post.where(id: ordered.map(&:post_id)).visible_to(current_user).pluck(:id).to_set
    render json: { post_ids: ordered.map(&:post_id).select { |id| visible_ids.include?(id) } }
  end

  private

  def find_post
    return unless (@post = find_object(Post))
    access_denied unless @post.visible_to?(current_user)
  end
end

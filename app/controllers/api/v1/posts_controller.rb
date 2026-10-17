# frozen_string_literal: true
class Api::V1::PostsController < Api::ApiController
  before_action :login_required, except: [:index, :show]
  before_action :find_post, only: [:show, :update]

  resource_description do
    description 'Viewing and editing posts'
  end

  api :GET, '/posts', 'Load all posts, optionally filtered. Results are ordered by subject unless otherwise specified.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]". Required only when owed is true.', required: false
  param :q, String, required: false, desc: 'Subject search term'
  param :min, String, required: false, desc: 'If present, returns only ID and subject per post'
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :author_id, :number, required: false, desc: 'If provided, returns only posts where the given user is an author'
  param :board_id, :number, required: false, desc: 'If provided, returns only posts in the given continuity'
  param :character_id, :number, required: false, desc: 'If provided, returns only posts where the given character appears, in the post itself or in any reply'
  param :template_id, :number, required: false, desc: 'If provided, returns only posts where any character in the given template appears, in the post itself or in any reply'
  param :status, Post.statuses.keys, required: false, desc: 'If provided, returns only posts with the given status'
  param :owed, :boolean, required: false, desc: "If true, returns only posts on which the current user owes a reply, as on the Replies Owed page (including the user's preference for hiding hiatused posts there). Requires authentication."
  param :order, ['subject', 'tagged_at'], required: false, desc: "Result ordering: 'subject' (default, alphabetical) or 'tagged_at' (most recently updated first)"
  error 401, "You must be logged in to request owed posts"
  error 422, "Invalid parameters provided"
  def index
    owed = ActiveModel::Type::Boolean.new.cast(params[:owed])
    if owed && !logged_in?
      login_required
      return
    end

    queryset = owed ? owed_posts : Post.all
    queryset = queryset.where('subject ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    queryset = queryset.where(status: params[:status]) if params[:status].present?

    if params[:author_id].present?
      return unless (author = find_object(User, param: :author_id, status: :unprocessable_content))
      queryset = queryset.where(id: Post::Author.where(user_id: author.id).select(:post_id))
    end

    if params[:board_id].present?
      return unless (board = find_object(Board, param: :board_id, status: :unprocessable_content))
      queryset = queryset.where(board_id: board.id)
    end

    if params[:character_id].present?
      return unless (character = find_object(Character, param: :character_id, status: :unprocessable_content))
      queryset = queryset.with_character(character.id)
    end

    if params[:template_id].present?
      return unless (template = find_object(Template, param: :template_id, status: :unprocessable_content))
      queryset = queryset.with_character(Character.where(template_id: template.id).select(:id))
    end

    # filter visibility before paginating so the pagination headers only count visible posts
    queryset = queryset.visible_to(current_user)
    queryset = if params[:order] == 'tagged_at'
      queryset.ordered
    else
      queryset.order(Arel.sql('LOWER(subject) asc'), id: :asc)
    end

    posts = paginate queryset, per_page: 25
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

  api :POST, '/posts/reorder', 'Update the order of posts. This is an unstable feature, and may be moved or renamed; it should not be trusted.'
  error 401, "You must be logged in"
  error 403, "Continuity is not editable by the user"
  error 404, "Post IDs could not be found"
  error 422, "Invalid parameters provided"
  param :ordered_post_ids, Array, allow_blank: false
  param :section_id, :number, required: false
  def reorder
    section_id = params[:section_id]&.to_i
    post_ids = params[:ordered_post_ids].map(&:to_i).uniq
    posts = Post.where(id: post_ids)
    posts_count = posts.count
    unless posts_count == post_ids.count
      missing_posts = post_ids - posts.pluck(:id)
      error = { message: "Some posts could not be found: #{missing_posts * ', '}" }
      render json: { errors: [error] }, status: :not_found and return
    end

    boards = Board.where(id: posts.select(:board_id).distinct.pluck(:board_id))
    unless boards.one?
      error = { message: 'Posts must be from one continuity' }
      render json: { errors: [error] }, status: :unprocessable_content and return
    end

    board = boards.first
    access_denied and return unless board.editable_by?(current_user)

    post_section_ids = posts.select(:section_id).distinct.pluck(:section_id)
    unless post_section_ids == [section_id] &&
           (section_id.nil? || BoardSection.where(id: section_id, board_id: board.id).exists?)
      error = { message: 'Posts must be from one specified section in the continuity, or no section' }
      render json: { errors: [error] }, status: :unprocessable_content and return
    end

    Post.transaction do
      section_scope = Post.where(board_id: board.id, section_id: section_id)
      all_section_posts = section_scope.ordered_in_section.to_a
      visible_to_user_ids = section_scope.visible_to(current_user).pluck(:id).to_set
      post_id_set = post_ids.to_set

      # Posts the editor can't read get anchored to the post in their request that preceded
      # them in the original ordering, so a private post placed between two visible ones
      # stays attached to its predecessor instead of being shoved to the bottom. Posts the
      # editor can read but omitted from the request (the documented "subset reorder" case)
      # still get appended at the end.
      anchors = {}
      visible_omitted = []
      anchor_id = :start
      all_section_posts.each do |post|
        if post_id_set.include?(post.id)
          anchor_id = post.id
        elsif visible_to_user_ids.include?(post.id)
          visible_omitted << post
        else
          anchors[post.id] = anchor_id
        end
      end

      anchored_by = Hash.new { |h, k| h[k] = [] }
      all_section_posts.each do |post|
        anchored_by[anchors[post.id]] << post if anchors.key?(post.id)
      end

      ordered_visible = posts.sort_by { |post| post_ids.index(post.id) }

      new_order = anchored_by[:start].dup
      ordered_visible.each do |post|
        new_order << post
        new_order.concat(anchored_by[post.id])
      end
      new_order.concat(visible_omitted)

      new_order.each_with_index do |post, index|
        next if post.section_order == index
        post.update(section_order: index)
      end
    end

    posts = Post.where(board_id: board.id, section_id: section_id).visible_to(current_user)
    render json: { post_ids: posts.ordered_in_section.pluck(:id) }
  end

  private

  # matches PostsController#owed's default view
  def owed_posts
    posts = Post.replies_owed_by(current_user)
    posts = posts.not_on_hiatus if current_user.hide_hiatused_tags_owed?
    posts.where.not(id: current_user.hidden_posts).no_tests
  end

  def find_post
    return unless (@post = find_object(Post))
    access_denied unless @post.visible_to?(current_user)
  end
end

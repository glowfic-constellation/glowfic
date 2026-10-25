# frozen_string_literal: true
class Api::V1::IndexesController < Api::ApiController
  include PostListFilter

  before_action :find_index, only: :show

  resource_description do
    description 'Viewing indexes'
  end

  api :GET, '/indexes', 'Load all the indexes visible to the current user, ordered by ID. num_posts counts only the posts visible to the user.'
  header 'Authorization', 'Optional authorization token for a user in the format "Authorization" : "Bearer [token]"', required: false
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  error 422, "Invalid parameters provided"
  def index
    queryset = Index.visible_to(current_user).order(:id).includes(:user)
    indexes = paginate queryset, per_page: 25

    # count only the posts the user would see on each index's page
    visible_posts = posts_relation_filter(Post.all).select(:id)
    post_counts = IndexPost.where(index_id: indexes.map(&:id), post_id: visible_posts).group(:index_id).count

    results = indexes.map { |index| index.as_json.merge(num_posts: post_counts.fetch(index.id, 0)) }
    render json: { results: results }
  end

  api :GET, '/indexes/:id', 'Load a single index with its sections and posts, in index order. Posts not visible to the user are left out.'
  header 'Authorization', 'Optional authorization token for a user in the format "Authorization" : "Bearer [token]"', required: false
  param :id, :number, required: true, desc: 'Index ID'
  error 403, "Index is not visible to the user"
  error 404, "Index not found"
  error 422, "Invalid parameters provided"
  def show
    posts = posts_relation_filter(@index.posts)
      .select('posts.*, index_posts.index_section_id, index_posts.id AS index_post_id, index_posts.description AS index_description')
      .with_reply_count
      .preload(:board, :section)
      .ordered_by_index
    posts_by_section = posts.to_a.group_by(&:index_section_id)

    sections = @index.index_sections.ordered.map do |section|
      section.as_json.merge(posts: posts_json(posts_by_section.fetch(section.id, [])))
    end

    render json: @index.as_json.merge(
      index_sections: sections,
      unsectioned_posts: posts_json(posts_by_section.fetch(nil, [])),
    )
  end

  private

  def find_index
    return unless (@index = find_object(Index))
    access_denied unless @index.visible_to?(current_user)
  end

  def posts_json(posts)
    posts.map do |post|
      post.as_json.merge(
        index_post_id: post.index_post_id,
        index_description: post.index_description,
      )
    end
  end
end

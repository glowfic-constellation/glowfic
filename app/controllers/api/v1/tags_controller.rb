class Api::V1::TagsController < Api::ApiController
  before_filter :find_tag, except: :index

  resource_description do
    description 'Viewing tags'
  end

  api :GET, '/tags', 'Load all the tags of the specified type that match the given query, results ordered by name. GalleryGroup tags are filtered to tags the current user has used.'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :t, ['Setting', 'Label', 'ContentWarning', 'GalleryGroup'], required: true, desc: 'Whether to search Settings, Content Warnings, Labels or Gallery Groups'
  error 422, "Invalid parameters provided"
  def index
    queryset = params[:t].constantize.where("name LIKE ?", params[:q].to_s + '%').order('name')

    # gallery groups only searches groups the current user has used
    if (user_id = params[:user_id]) && params[:t] == 'GalleryGroup'
      user_char_tags = GalleryGroup.joins(character_tags: [:character]).where(characters: {user_id: user_id}).pluck(:id)
      user_gal_tags = GalleryGroup.joins(gallery_tags: [:gallery]).where(galleries: {user_id: user_id}).pluck(:id)
      queryset = queryset.where(id: user_char_tags + user_gal_tags)
    end

    tags = paginate queryset, per_page: 25
    render json: {results: tags}
  end

  api! 'Load a single tag as a JSON resource'
  param :id, :number, required: true, desc: 'Tag ID'
  def show
    render json: @tag.as_json(include: [:gallery_ids], user_id: params[:user_id])
  end

  private

  def find_tag
    unless (@tag = Tag.find_by(id: params[:id]))
      error = {message: 'Tag could not be found'}
      render json: {errors: [error]}, status: :not_found and return
    end
    @tag = @tag.type.constantize.find_by(id: params[:id])
  end
end

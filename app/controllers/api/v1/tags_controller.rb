class Api::V1::TagsController < Api::ApiController
  resource_description do
    description 'Viewing tags'
  end

  api :GET, '/tags', 'Load all the tags of the specified type that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :t, ['Setting', 'Label', 'ContentWarning', 'GalleryGroup'], required: true, desc: 'Whether to search Settings, Content Warnings, Labels or Gallery Groups'
  error 422, "Invalid parameters provided"
  def index
    queryset = params[:t].constantize.where("name LIKE ?", params[:q].to_s + '%').order('name')

    # gallery groups only searches groups the specified user has used
    if (user_id = params[:user_id]) && params[:t] == 'GalleryGroup'
      user_gal_tags = GalleryGroup.joins(gallery_tags: [:gallery]).where(galleries: {user_id: user_id}).pluck(:id)
      queryset = queryset.where(id: user_gal_tags)
    end

    tags = paginate queryset, per_page: 25
    render json: {results: tags}
  end
end

class Api::V1::TagsController < Api::ApiController
  resource_description do
    description 'Viewing tags'
  end

  api :GET, '/tags', 'Load all the tags of the specified type that match the given query, results ordered by name. GalleryGroup tags are filtered to tags the current user has used.'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :t, ['Setting', 'Label', 'ContentWarning', 'GalleryGroup'], required: true, desc: 'Whether to search Settings, Content Warnings or Labels'
  error 422, "Invalid parameters provided"
  def index
    queryset = params[:t].constantize.where("name LIKE ?", params[:q].to_s + '%').order('name')

    # gallery groups only searches groups the current user has used
    if (user_id = params[:user_id]) && params[:t] == 'GalleryGroup'
      queryset = queryset.where('(SELECT 1 FROM gallery_tags LEFT JOIN galleries ON gallery_tags.gallery_id = galleries.id WHERE galleries.user_id = ? LIMIT 1) IS NOT NULL', current_user.id)
    end

    tags = paginate queryset, per_page: 25
    render json: {results: tags}
  end
end

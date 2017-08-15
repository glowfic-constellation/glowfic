class Api::V1::CharactersController < Api::ApiController
  before_filter :login_required, only: :update
  before_filter :find_character, except: :index
  before_filter :find_post, except: :update
  before_filter :require_permission, only: :update

  resource_description do
    description 'Viewing and editing characters'
  end

  api! 'Load all the characters that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :post_id, :number, required: false, desc: 'If provided, will return only characters that appear in the provided post'
  error 403, "Post is not visible to the user"
  error 422, "Invalid parameters provided"
  def index
    queryset = Character.where("name LIKE ?", params[:q].to_s + '%').order('name')
    if @post
      char_ids = @post.replies.pluck('distinct character_id') + [@post.character_id]
      queryset = queryset.where(id: char_ids)
    end

    characters = paginate queryset, per_page: 25
    render json: {results: characters}
  end

  api! 'Load a single character as a JSON resource'
  param :id, :number, required: true, desc: 'Character ID'
  param :post_id, :number, required: false, desc: 'If provided, will return an additional alias_id_for_post param to represent most recently used alias for this character in the provided post'
  error 403, "Post is not visible to the user"
  error 404, "Character not found"
  error 422, "Invalid parameters provided"
  def show
    render json: @character.as_json(include: [:galleries, :default, :aliases], post_for_alias: @post)
  end

  api! 'Update a given character'
  param :id, :number, required: true, desc: 'Character ID'
  error 401, "You must be logged in"
  error 403, "Character is not editable by the user"
  error 404, "Character not found"
  error 422, "Invalid parameters provided"
  def update
    render json: {data: @character.as_json(include: [:default])} and return unless params[:character]

    errors = []
    if params[:character][:default_icon_id].present?
      errors << {message: "Default icon could not be found"} unless Icon.find_by_id(params[:character][:default_icon_id])
    end

    @character.assign_attributes(character_params)
    errors += @character.errors.full_messages.map { |msg| {message: msg} } unless @character.valid?
    render json: {errors: errors}, status: :unprocessable_entity and return unless errors.empty?

    @character.save
    render json: @character.as_json(include: [:default])
  end

  private

  def find_character
    unless @character = Character.find_by_id(params[:id])
      error = {message: "Character could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end
  end

  def find_post
    return unless params[:post_id].present?

    unless (@post = Post.find_by_id(params[:post_id]))
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :unprocessable_entity and return
    end

    access_denied and return unless @post.visible_to?(current_user)
  end

  def require_permission
    access_denied unless @character.user == current_user
  end

  def character_params
    params.fetch(:character, {}).permit(:default_icon_id, :name, :template_name, :screenname, :setting, :template_id, :new_template_name, :pb, :description, gallery_ids: [])
  end
end

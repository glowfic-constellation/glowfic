class Api::V1::CharactersController < Api::ApiController
  before_filter :login_required, only: :update
  before_filter :find_character
  before_filter :require_permission, only: :update

  resource_description do
    description 'Viewing and editing characters'
  end

  api :GET, '/characters/:id', 'Load a single character as a JSON resource'
  param :id, :number, required: true, desc: 'Character ID'
  error 404, "Character not found"
  example "'errors': [{'message': 'Character could not be found.'}]"
  example "'data': {
  'id': 1,
  'name': 'Character Example',
  'screenname': 'char-example',
  'default': {
    'id': 2,
    'url': 'http://www.example.com/image.png',
    'keyword': 'icon'
  },
  'galleries': [
    {
      'name': 'Example 1',
      'icons': []
    }, {
      'name': 'Example 2',
      'icons': [
        {
          'id': 2,
          'url': 'http://www.example.com/image.png',
          'keyword': 'icon'
        }, {
          'id': 3,
          'url': 'http://www.example.com/image2.png',
          'keyword': 'icon2'
      }]
  }]
}"
  def show
    render json: {data: @character.as_json(include: [:galleries, :default])}
  end

  api :PUT, '/characters/:id', 'Update a given character'
  param :id, :number, required: true, desc: 'Character ID'
  error 401, "You must be logged in"
  error 403, "Character is not editable by the user"
  error 404, "Character not found"
  error 422, "Invalid parameters provided"
  example "'errors': [{'message': 'You must be logged in to view that page.'}]"
  example "'errors': [{'message': 'You do not have permission to perform this action.'}]"
  example "'errors': [{'message': 'Character could not be found.'}]"
  example "'errors': [{'message': \"Name can't be blank\"}, {'message': 'Default icon could not be found'}]"
  example "'data': {
  'id': 1,
  'name': 'Character Example',
  'screenname': 'char-example',
  'default': {
    'id': 2,
    'url': 'http://www.example.com/image.png',
    'keyword': 'icon'
  }
}"
  def update
    render json: {data: @character.as_json(include: [:default])} and return unless params[:character]

    errors = []
    if params[:character][:default_icon_id].present?
      errors << {message: "Default icon could not be found"} unless Icon.find_by_id(params[:character][:default_icon_id])
    end

    @character.assign_attributes(params[:character])
    errors += @character.errors.full_messages.map { |msg| {message: msg} } unless @character.valid?
    render json: {errors: errors}, status: :unprocessable_entity and return unless errors.empty?

    @character.save
    render json: {data: @character.as_json(include: [:default])}
  end

  private

  def find_character
    unless @character = Character.find_by_id(params[:id])
      error = {message: "Character could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end
  end

  def require_permission
    access_denied unless @character.user == current_user
  end
end

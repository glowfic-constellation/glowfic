class Api::V1::SettingsController < Api::ApiController
  before_action :find_setting, except: :index

  resource_description do
    description 'Viewing settings'
  end

  api :GET, '/settings', 'Load all the settings of the specified type that match the given query, results ordered by name'
  param :q, String, required: false, desc: "Query string"
  param :page, :number, required: false, desc: 'Page in results (25 per page)'
  param :setting_id, :number, required: false, desc: 'Used so we don\'t show the current setting as a possible parent setting of itself'
  error 422, "Invalid parameters provided"
  def index
    queryset = Setting.where("name LIKE ?", params[:q].to_s + '%').order('name')
    queryset = queryset.where.not(id: params[:setting_id]) if params[:setting_id].present?

    settings = paginate queryset, per_page: 25
    render json: {results: settings}
  end

  api! 'Load a single setting as a JSON resource'
  param :id, :number, required: true, desc: 'Setting ID'
  error 404, "Setting not found"
  def show
    render json: @setting.as_json(include: [:gallery_ids], user_id: params[:user_id])
  end

  private

  def find_setting
    unless (@setting = Setting.find_by(id: params[:id]))
      error = {message: 'Setting could not be found'}
      render json: {errors: [error]}, status: :not_found and return
    end
  end
end

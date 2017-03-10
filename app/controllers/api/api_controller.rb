class Api::ApiController < ActionController::Base
  include Authentication

  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  around_filter :set_timezone
  around_filter :handle_param_validation

  resource_description do
    formats ['json']
    meta author: {name: 'Marri'}
    app_info 'The public API for the Glowfic Constellation'
  end

  protected

  def login_required
    return if logged_in?
    error = {message: "You must be logged in to view that page."}
    render json: {errors: [error]}, status: :unauthorized and return
  end

  def set_timezone
    Time.use_zone("UTC") { yield }
  end

  def handle_param_validation
    begin
      yield
    rescue Apipie::ParamMissing, Apipie::ParamInvalid => error
      render json: {errors: [Sanitize.fragment(error.message.gsub('"', "'"))]}, status: :unprocessable_entity
    end
  end


  def access_denied
    error = {message: "You do not have permission to perform this action."}
    render json: {errors: [error]}, status: :forbidden
  end

  def per_page
    per = params[:per_page].to_i
    return 25 if per < 1
    return 100 if per > 100
    per
  end
end

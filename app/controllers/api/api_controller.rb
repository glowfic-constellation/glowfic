class Api::ApiController < ActionController::Base
  include Authentication

  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  around_filter :set_timezone

  protected

  def set_timezone
    Time.use_zone("UTC") { yield }
  end
end

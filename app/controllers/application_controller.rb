class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  around_filter :set_timezone
  after_filter :store_location

  protected

  def current_user
    @current_user ||= User.find_by_id(session[:user_id]) if logged_in?
  end
  helper_method :current_user

  def logged_in?
    session[:user_id].present?
  end
  helper_method :logged_in?

  def login_required
    unless logged_in?
      flash[:error] = "You must be logged in to view that page."
      redirect_to root_path
    end
  end

  def use_javascript(js)
    @javascripts ||= []
    @javascripts << js
  end

  def page
    @page ||= params[:page] || 1
  end
  helper_method :page

  def page=(val)
    @page = val
  end

  def per_page
    default = browser.mobile? ? -1 : 25
    per = (params[:per_page] || current_user.try(:per_page) || default)
    per = -1 if per == 'all'
    @per_page ||= per.to_i
  end
  helper_method :per_page

  def page_view
    return @view if @view
    if logged_in?
      @view = params[:view] || current_user.default_view
    else
      @view = session[:view] = params[:view] || session[:view] || 'icon'
    end
  end
  helper_method :page_view

  def rowspan
    messages = current_user.messages.select(&:unread?).size if logged_in?
    @span ||= 1 + flash.keys.size + (messages || 0)
  end
  helper_method :rowspan

  def store_location
    return unless request.get?
    return if request.xhr?
    session[:previous_url] = request.fullpath
  end

  def set_timezone(&block)
    return yield unless logged_in?
    return yield unless current_user.timezone
    Time.use_zone(current_user.timezone, &block)
  end

  def check_permanent_user
    return if logged_in?
    session[:user_id] = cookies.signed[:user_id] if cookies.signed[:user_id].present?
  end
end

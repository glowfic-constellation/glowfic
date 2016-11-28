class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  before_filter :show_password_warning
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

  def show_password_warning
    return unless logged_in?
    if current_user.salt_uuid.nil?
      flash.now[:pass] = "Because Marri accidentally made passwords a bit too secure, you cannot update your username until you <a href='/users/#{current_user.id}/edit#change-password'>update your password</a>. (You may update your password to the same password you already have, as long as you go through the Change Password flow.) Please fix your password as soon as possible. You may also fix your password by logging out and then back in."
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
    default = 25 # browser.mobile? ? -1 : 25
    per = (params[:per_page] || current_user.try(:per_page) || default)
    per = -1 if per == 'all'
    per = default if per.to_i.zero?
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

  def require_glowfic_domain
    return unless Rails.env.production?
    return unless request.get?
    return if request.xhr?
    return if request.host.include?('glowfic.com')
    glowfic_url = root_url(host: ENV['DOMAIN_NAME'], protocol: 'https')[0...-1] + request.fullpath # strip double slash
    redirect_to glowfic_url, status: :moved_permanently
  end
end

# frozen_string_literal: true
class ApplicationController < ActionController::Base
  include Authentication

  before_filter :clear_old_cookies
  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  before_filter :show_password_warning
  before_filter :require_glowfic_domain
  around_filter :set_timezone
  after_filter :store_location

  protected

  def clear_old_cookies
    # historical stuff I should kill for safety vs conflicts
    [:_glowfic_session, :_glowfic_session_production].each do |key|
      cookies.delete(key, domain: 'glowfic.com')
      cookies.delete(key, domain: 'www.glowfic.com')
    end
  end

  def login_required
    unless logged_in?
      flash[:error] = "You must be logged in to view that page."
      redirect_to root_path
    end
  end

  def logout_required
    if logged_in?
      flash[:error] = "You are already logged in."
      redirect_to boards_path
    end
  end

  def show_password_warning
    return unless logged_in?
    return unless current_user.salt_uuid.nil?
    reset_session
    cookies.delete(:user_id)
    @current_user = nil
    flash.now[:pass] = "Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site."
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
    per = 100 if per == 'all' || per.to_i > 100
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

  def require_glowfic_domain
    return unless Rails.env.production?
    return unless request.get?
    return if request.xhr?
    return if request.host.include?('glowfic.com')
    glowfic_url = root_url(host: ENV['DOMAIN_NAME'], protocol: 'https')[0...-1] + request.fullpath # strip double slash
    redirect_to glowfic_url, status: :moved_permanently
  end

  def post_or_reply_link(reply)
    return unless reply.id.present?
    if reply.is_a?(Reply)
      reply_path(reply, anchor: "reply-#{reply.id}")
    else
      post_path(reply)
    end
  end
  helper_method :post_or_reply_link

  def posts_from_relation(relation, no_tests=true, with_pagination=true)
    posts = relation
      .select('posts.*, boards.name as board_name, users.username as last_user_name')
      .joins(:board)
      .joins(:last_user)

    posts = posts.paginate(page: page, per_page: 25) if with_pagination
    posts = posts.no_tests if no_tests

    if (with_pagination && posts.total_pages <= 1) || posts.count(:all) <= 25
      posts = posts.select {|post| post.visible_to?(current_user)}
    end

    if logged_in?
      @opened_ids ||= PostView.where(user_id: current_user.id).where('read_at IS NOT NULL').pluck(:post_id)

      opened_posts = PostView.where(user_id: current_user.id).where('read_at IS NOT NULL').where(post_id: posts.map(&:id)).select([:post_id, :read_at])
      @unread_ids ||= []
      @unread_ids += opened_posts.select do |view|
        post = posts.detect { |p| p.id == view.post_id }
        post && view.read_at < post.tagged_at
      end.map(&:post_id)
    end

    posts
  end
  helper_method :posts_from_relation

  def unread_ids
    # does not necessarily include fully unread posts
    @unread_ids
  end
  helper_method :unread_ids

  def opened_ids
    @opened_ids
  end
  helper_method :opened_ids
end

# frozen_string_literal: true
class SessionsController < ApplicationController
  TOKENLESS_ACTIONS = ['create', 'confirm_tos'].freeze

  before_action :logout_required, only: [:new, :create, :confirm_tos]
  before_action :login_required, only: [:destroy]

  def index
  end

  def new
    @page_title = "Sign In"
  end

  def create
    auth = Authentication.new
    if auth.authenticate(params[:username], params[:password])
      user = auth.user
      flash[:success] = "You are now logged in as #{user.username}. Welcome back!"
      session[:user_id] = user.id
      session[:api_token] = {
        "value"   => auth.api_token,
        "expires" => Authentication::EXPIRY.from_now.to_i,
      }
      cookies.permanent.signed[:user_id] = cookie_hash(user.id) if params[:remember_me].present?
      @current_user = user
      redirect_to continuities_path and return if return_path == '/login'
    else
      flash[:error] = auth.error
    end
    redirect_to return_path # allow_other_host: false
  end

  def confirm_tos
    cookies.permanent[:accepted_tos] = cookie_hash(User::CURRENT_TOS_VERSION)
    redirect_to return_path # allow_other_host: false
  end

  def destroy
    url = return_path
    logout
    flash[:success] = "You have been logged out."
    redirect_to url # allow_other_host: false
  end

  private

  # Shareable pages carry no CSRF token, so login and ToS accept a same-origin request instead.
  def verified_request?
    super || (TOKENLESS_ACTIONS.include?(action_name) && same_origin_request?)
  end

  # A request with neither header is not from a browser.
  def same_origin_request?
    site = request.headers['Sec-Fetch-Site']
    return ['same-origin', 'none'].include?(site) if site.present?
    origin = request.headers['Origin']
    origin.blank? || origin == request.base_url
  end

  def cookie_hash(value)
    return { value: value, domain: 'glowfic-staging.herokuapp.com' } if request.host.include?('staging')
    return { value: value, domain: '.glowfic.com', tld_length: 2 } if Rails.env.production?
    { value: value }
  end
end

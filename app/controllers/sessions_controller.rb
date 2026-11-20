# frozen_string_literal: true
class SessionsController < ApplicationController
  # Remember-me cookies are not revocable server-side, so keep their lifetime bounded
  REMEMBER_ME_DURATION = 1.year

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
      cookies.signed[:user_id] = remember_me_cookie(user.id) if params[:remember_me].present?
      @current_user = user
      redirect_to continuities_path and return if session[:previous_url] == '/login'
    else
      flash[:error] = auth.error
    end
    redirect_to session[:previous_url] || root_url # allow_other_host: false
  end

  def confirm_tos
    cookies.permanent[:accepted_tos] = cookie_hash(User::CURRENT_TOS_VERSION)
    redirect_to session[:previous_url] || root_url # allow_other_host: false
  end

  def destroy
    url = session[:previous_url] || root_url
    logout
    flash[:success] = "You have been logged out."
    redirect_to url # allow_other_host: false
  end

  private

  def remember_me_cookie(user_id)
    cookie_hash(user_id).merge(httponly: true, expires: REMEMBER_ME_DURATION.from_now)
  end

  def cookie_hash(value)
    return { value: value, domain: 'glowfic-staging.herokuapp.com' } if request.host.include?('staging')
    return { value: value, domain: '.glowfic.com', tld_length: 2 } if Rails.env.production?
    { value: value }
  end
end

# frozen_string_literal: true
class SessionsController < ApplicationController
  before_action :logout_required, only: [:new, :create, :confirm_tos]
  before_action :login_required, only: [:destroy]

  def index
  end

  def new
    @page_title = "Sign In"
  end

  def create
    user = User.find_by(username: params[:username])

    if !user
      flash[:error] = "That username does not exist."
    elsif user.suspended?
      flash[:error] = "You could not be logged in."
      begin
        raise NameError.new("Login attempt by suspended user #{user.id}")
      rescue NameError => e
        ExceptionNotifier.notify_exception(e, env: request.env)
      end
    elsif user.password_resets.active.unused.exists?
      flash[:error] = "The password for this account has been reset. Please check your email."
    elsif user.authenticate(params[:password])
      unless user.salt_uuid.present?
        user.salt_uuid = SecureRandom.uuid
        user.crypted = user.send(:crypted_password, params[:password])
        user.save!
      end
      flash[:success] = "You are now logged in as #{user.username}. Welcome back!"
      session[:user_id] = user.id
      cookies.permanent.signed[:user_id] = cookie_hash(user.id) if params[:remember_me].present?
      @current_user = user
      redirect_to boards_path and return if session[:previous_url] == '/login'
    else
      flash[:error] = "You have entered an incorrect password."
    end
    redirect_to session[:previous_url] || root_url
  end

  def confirm_tos
    cookies.permanent[:accepted_tos] = cookie_hash(User::CURRENT_TOS_VERSION)
    redirect_to session[:previous_url] || root_url
  end

  def destroy
    url = session[:previous_url] || root_url
    logout
    flash[:success] = "You have been logged out."
    redirect_to url
  end

  private

  def cookie_hash(value)
    return {value: value, domain: 'glowfic-staging.herokuapp.com'} if request.host.include?('staging')
    return {value: value, domain: '.glowfic.com', tld_length: 2} if Rails.env.production?
    {value: value}
  end
end

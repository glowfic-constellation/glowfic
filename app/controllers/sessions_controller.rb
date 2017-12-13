# frozen_string_literal: true
class SessionsController < ApplicationController
  before_action :logout_required, only: [:new, :create]
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
      cookies.permanent.signed[:user_id] = {value: user.id, domain: '.glowfic.com', tld_length: 2} if params[:remember_me].present?
      @current_user = user
      redirect_to boards_path and return if session[:previous_url] == '/login'
    else
      flash[:error] = "You have entered an incorrect password."
    end
    redirect_to session[:previous_url] || root_url
  end

  def destroy
    url = session[:previous_url] || root_url
    reset_session
    cookies.delete(:user_id, domain: '.glowfic.com')
    @current_user = nil
    flash[:success] = "You have been logged out."
    redirect_to url
  end
end

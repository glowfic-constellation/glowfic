# frozen_string_literal: true
class PasswordResetsController < ApplicationController
  before_action :logout_required
  before_action :find_model, only: [:show, :update]

  def new
    @page_title = 'Reset Password'
  end

  def create
    @page_title = 'Reset Password'
    unless params[:email].present?
      flash.now[:error] = "Email is required."
      render :new and return
    end

    unless params[:username].present?
      flash.now[:error] = "Username is required."
      render :new and return
    end

    unless (user = User.where(email: params[:email], username: params[:username]).first)
      flash.now[:error] = "Account could not be found."
      render :new and return
    end

    existing = user.password_resets.active.unused.first
    if existing.present?
      UserMailer.password_reset_link(existing.id).deliver
      flash[:success] = "Your password reset link has been re-sent." # rubocop:disable Rails/ActionControllerFlashBeforeRender
      params[:email] = params[:username] = nil
      redirect_to new_password_reset_path and return
    end

    password_reset = PasswordReset.new(user: user)
    begin
      password_reset.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(password_reset, action: 'created', now: true, err: e)
      render :new
    else
      UserMailer.password_reset_link(password_reset.id).deliver
      params[:email] = params[:username] = nil
      flash[:success] = "A password reset link has been emailed to you."
      redirect_to new_password_reset_path
    end
  end

  def show
    @page_title = 'Change Password'
  end

  def update
    @password_reset.user.password = params[:password]
    @password_reset.user.password_confirmation = params[:password_confirmation]
    @password_reset.user.validate_password = true

    begin
      User.transaction do
        @password_reset.user.save!
        @password_reset.update!(used: true)
      end
    rescue ActiveRecord::RecordInvalid => e
      @password_reset.errors.merge!(@password_reset.user.errors)
      render_errors(@password_reset, action: 'updated', now: true, class_name: 'Password', err: e)

      @page_title = 'Change Password'
      render :show
    else
      flash[:success] = "Password changed."
      redirect_to root_url
    end
  end

  private

  def logout_required
    return unless logged_in?
    flash[:error] = "You are already logged in."
    redirect_to edit_user_path(current_user)
  end

  def find_model
    unless (@password_reset = PasswordReset.find_by(auth_token: params[:id]))
      flash[:error] = "Authentication token not found."
      redirect_to root_url and return
    end

    unless @password_reset.active?
      flash[:error] = "Authentication token expired."
      redirect_to root_url and return
    end

    return unless @password_reset.used?
    flash[:error] = "Authentication token has already been used."
    redirect_to root_url
  end
end

# frozen_string_literal: true
# Lets a user register and manage the OAuth applications they develop.
class OauthClientsController < ApplicationController
  before_action :login_required
  before_action :find_application, except: [:index, :new, :create]

  def index
    @applications = current_user.oauth_applications.ordered_by(:name)
    @page_title = 'Your OAuth Applications'
  end

  def new
    @application = current_user.oauth_applications.new
    @page_title = 'New OAuth Application'
  end

  def create
    @application = current_user.oauth_applications.new(application_params)
    if @application.save
      flash.now[:success] = "Application registered. Copy the secret now: it will not be shown again."
      show_with_secret
    else
      flash.now[:error] = {
        message: "Application could not be registered because of the following problems:",
        array: @application.errors.full_messages,
      }
      @page_title = 'New OAuth Application'
      render :new, status: :unprocessable_content
    end
  end

  def show
    @page_title = @application.name
  end

  def edit
    @page_title = 'Edit Application: ' + @application.name
  end

  def update
    if @application.update(application_params)
      flash[:success] = "Application updated."
      redirect_to oauth_client_path(@application)
    else
      flash.now[:error] = {
        message: "Application could not be updated because of the following problems:",
        array: @application.errors.full_messages,
      }
      @page_title = 'Edit Application: ' + @application.name_was
      render :edit, status: :unprocessable_content
    end
  end

  def renew_secret
    @application.renew_secret
    @application.save!
    flash.now[:success] = "New secret generated. Copy it now: it will not be shown again. The old secret no longer works."
    show_with_secret
  end

  def destroy
    @application.destroy!
    flash[:success] = "Application deleted."
    redirect_to oauth_clients_path
  end

  private

  # Secrets are stored hashed, so the plaintext only exists on the request that generates it.
  def show_with_secret
    @secret = @application.plaintext_secret
    @page_title = @application.name
    render :show
  end

  def application_params
    params.fetch(:application, {}).permit(:name, :redirect_uri, :confidential)
  end

  def find_application
    return if (@application = current_user.oauth_applications.find_by(id: params[:id]))
    flash[:error] = "Application could not be found."
    redirect_to oauth_clients_path
  end
end

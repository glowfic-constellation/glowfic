# frozen_string_literal: true

class User::RegistrationsController < Devise::RegistrationsController
  # adding custom setup for the built-in Devise signup page
  before_action :signup_prep, only: [:new, :create]
  before_action :configure_sign_up_params, only: [:create]
  # adding custom setup for the built-in Devise update page
  before_action :configure_account_update_params, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter

  # GET /resource/sign_up
  def new
    @page_title = 'Sign Up'
    super
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    unless resource.tos_version.present?
      clean_up_passwords resource
      set_minimum_password_length
      flash.now[:error] = "You must accept the Terms and Conditions to use the Constellation."
      render :new
      return
    end

    if params[:addition].to_i != 14
      clean_up_passwords resource
      set_minimum_password_length
      flash.now[:error] = "Please check your math and try again."
      render :new
      return
    end

    if params[:secret].present? && params[:secret] != ENV["ACCOUNT_SECRET"]
      clean_up_passwords resource
      set_minimum_password_length
      flash.now[:error] = "That is not the correct secret. Please ask someone in the community for help or leave blank to create a reader account."
      render :new
      return
    end

    super
  end

  # GET /resource/edit
  def edit
    @page_title = 'Edit Account'
    super
  end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  def destroy
    flash[:error] = "Please contact an admin to delete your account."
    redirect_to root_path
    # TODO: allow users to soft delete their own accounts
    # https://github.com/heartcombo/devise/wiki/How-to:-Soft-delete-a-user-when-user-deletes-account
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def signup_prep
    use_javascript('users/new')
    @page_title = 'Sign Up'
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
  end

  def build_resource(hash={})
    self.resource = resource_class.new_with_session(hash, session)
    resource.role_id = Permissible::READONLY if params[:secret] != ENV["ACCOUNT_SECRET"]
    resource.tos_version = User::CURRENT_TOS_VERSION if params[:tos].present?
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:email])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end

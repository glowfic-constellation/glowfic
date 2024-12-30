# frozen_string_literal: true

class User::RegistrationsController < Devise::RegistrationsController
  before_action :signup_prep, only: [:new, :create] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :configure_sign_up_params, only: [:create]

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

    super
  end

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
end

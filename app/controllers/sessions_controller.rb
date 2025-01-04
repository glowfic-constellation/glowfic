# frozen_string_literal: true
class SessionsController < ApplicationController
  before_action :logout_required, only: [:confirm_tos]

  def confirm_tos
    cookies.permanent[:accepted_tos] = cookie_options.merge({ value: User::CURRENT_TOS_VERSION })
    redirect_to session[:previous_url] || root_url # allow_other_host: false
  end
end

# frozen_string_literal: true
class SessionsController < ApplicationController
  before_action :logout_required, only: [:confirm_tos]

  def confirm_tos
    cookies.permanent[:accepted_tos] = cookie_hash(User::CURRENT_TOS_VERSION)
    redirect_to session[:previous_url] || root_url # allow_other_host: false
  end

  private

  def cookie_hash(value)
    return { value: value, domain: 'glowfic-staging.herokuapp.com' } if request.host.include?('staging')
    return { value: value, domain: '.glowfic.com', tld_length: 2 } if Rails.env.production?
    { value: value }
  end
end

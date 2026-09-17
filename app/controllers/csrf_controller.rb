# frozen_string_literal: true

# Hands a CSRF token to a page that was rendered without one.
#
# A page held in a shared cache cannot carry a CSRF token: the token is tied
# to the session of whoever caused the render, and every later reader gets a
# different session or none at all. The header login form therefore ships with
# an empty token and asks for one here.
#
# This is not a hole in forgery protection. The token still has to match the
# requester's own session, and this response is what establishes that session,
# so a token fetched here is only ever valid for the browser that fetched it.
# An attacker's page can call this endpoint too, but it cannot read the reply:
# there is no CORS header on it, so a cross-origin caller is refused by the
# browser before it sees the body.
#
# Volume is not a concern. The scrape does not run JavaScript, so it never
# calls this — of the roughly 2.8M daily page views, only the ~500k from real
# browsers reach it, and the action touches no database.
class CsrfController < ApplicationController
  skip_before_action :check_tos, raise: false
  skip_before_action :show_password_warning, raise: false

  def show
    response.cache_control.replace(private: true, no_store: true)
    render json: { token: form_authenticity_token }
  end
end

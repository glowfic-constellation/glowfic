# frozen_string_literal: true
class BugsController < ApplicationController
  before_filter :login_required

  def create
    exception = Icon::UploadError.new
    data = params.merge({user_id: current_user.try(:id)})
    ExceptionNotifier.notify_exception(exception, data: data)
    render json: {}
  end
end

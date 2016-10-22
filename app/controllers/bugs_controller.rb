class BugsController < ApplicationController
  before_filter :login_required

  def create
    exception = Icon::UploadError.new
    data = params.merge({user: current_user})
    ExceptionNotifier.notify_exception(exception, data: data)
    render json: {}
  end
end

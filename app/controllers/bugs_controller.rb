class BugsController < ApplicationController
  def create
    exception = Icon::UploadError.new
    data = {response_status: params[:response_status], response_body: params[:response_body], user: current_user}
    ExceptionNotifier.notify_exception(exception, data: data)
    render json: {}
  end
end

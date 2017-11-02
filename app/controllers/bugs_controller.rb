# frozen_string_literal: true
class BugsController < ApplicationController
  before_action :login_required

  def create
    exception = Icon::UploadError.new
    data = {
      response_status: params[:response_status],
      response_body: params[:response_body],
      response_text: params[:response_text],
      file_name: params[:file_name],
      file_type: params[:file_type],
      user_id: current_user.try(:id)
    }
    ExceptionNotifier.notify_exception(exception, data: data)
    render json: {}
  end
end

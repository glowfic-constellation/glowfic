# frozen_string_literal: true
class ReuploadIconJob < ApplicationJob
  queue_as :low

  def perform(icon_id)
    uploader = Icon::Reuploader.new(Icon.find_by(icon_id))
    uploader.process
  end

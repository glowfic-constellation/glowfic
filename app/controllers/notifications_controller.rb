# frozen_string_literal: true
class NotificationsController < ApplicationController
  before_action :login_required

  def index
    @page_title = "Notifications"
    @notifications = current_user.notifications.visible_to(current_user).ordered
    @notifications = @notifications.not_ignored_by(current_user) if current_user&.hide_from_all
    @notifications = @notifications.order(:created_at).paginate(page: page)

    post_ids = @notifications.map(&:post_id).compact_blank
    @posts = posts_from_relation(Post.where(id: post_ids), with_pagination: false).index_by(&:id)

    use_javascript('global')
  end

  def mark
    notifications = Notification.where(id: params[:marked_ids], user: current_user)

    case params[:commit]
      when "Mark Read"
        notifications.each { |notif| notif.update(unread: false, read_at: notif.read_at || Time.zone.now) }
      when "Mark Unread"
        notifications.each { |notif| notif.update(unread: true) }
      when "Delete"
        notifications.destroy_all
      else
        flash[:error] = "Could not perform unknown action."
        redirect_to notifications_path and return
    end

    flash[:success] = "Notifications updated"
    redirect_to notifications_path
  end
end

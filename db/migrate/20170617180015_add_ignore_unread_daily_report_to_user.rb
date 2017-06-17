class AddIgnoreUnreadDailyReportToUser < ActiveRecord::Migration
  def change
    add_column :users, :ignore_unread_daily_report, :boolean, default: false
  end
end

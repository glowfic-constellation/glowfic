class AddIgnoreUnreadDailyReportToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :ignore_unread_daily_report, :boolean, default: false
  end
end

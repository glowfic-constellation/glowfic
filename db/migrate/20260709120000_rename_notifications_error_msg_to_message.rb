class RenameNotificationsErrorMsgToMessage < ActiveRecord::Migration[8.0]
  def change
    rename_column :notifications, :error_msg, :message
  end
end

class AddReportView < ActiveRecord::Migration
  def change
    create_table :report_views do |t|
      t.integer :user_id, :null => false
      t.datetime :read_at
      t.timestamps
    end
    add_index :report_views, :user_id
  end
end

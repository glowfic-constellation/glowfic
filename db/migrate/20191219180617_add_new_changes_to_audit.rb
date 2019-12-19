class AddNewChangesToAudit < ActiveRecord::Migration[5.2]
  def change
    add_column :audits, :new_changes, :jsonb
  end
end

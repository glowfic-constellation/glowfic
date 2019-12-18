class ChangeAuditedChangesToJson < ActiveRecord::Migration[5.2]
  def change
    rename_column :audits, :audited_changes, :old_changes
    add_column :audits, :audited_changes, :jsonb
  end
end

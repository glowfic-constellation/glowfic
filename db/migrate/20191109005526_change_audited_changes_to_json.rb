class ChangeAuditedChangesToJson < ActiveRecord::Migration[5.2]
  def up
    change_column_type(:jsonb) do |audit|
      YAML.load(audit.old_changes)
    end
  end

  def down
    change_column_type(:text) do |audit|
      audit.old_changes
    end
  end

  def change_column_type(column_type)
    rename_column :audits, :audited_changes, :old_changes
    add_column :audits, :audited_changes, column_type
    Audited::Audit.find_each do |audit|
      audit.update!(audited_changes: yield(audit))
    end
    remove_column :audits, :old_changes
  end
end

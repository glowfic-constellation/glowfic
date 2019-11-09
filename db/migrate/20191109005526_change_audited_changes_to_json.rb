class ChangeAuditedChangesToJson < ActiveRecord::Migration[5.2]
  def up
    rename_column :audits, :audited_changes, :old_changes
    add_column :audits, :audited_changes, :jsonb
    Audited::Audit.all.each do |audit|
      audit.update!(audited_changes: YAML.load(audit.old_changes))
    end
    remove_column :audits, :old_changes
  end

  def down
    rename_column :audits, :audited_changes, :old_changes
    add_column :audits, :audited_changes, :text
    Audited::Audit.all.each do |audit|
      audit.update!(audited_changes: JSON.load(audit.old_changes))
    end
    remove_column :audits, :old_changes
  end
end

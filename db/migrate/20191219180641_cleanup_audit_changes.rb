class CleanupAuditChanges < ActiveRecord::Migration[5.2]
  def change
    audits = Audited::Audit.where(new_changes: nil)
    raise ActiveRecord::Rollback if audits.count > 1000 # if there are that many audits to migrate we shouldn't be here yet
    audits.each do |audit|
      audit.update!(new_changes: audit.audited_changes)
    end
    remove_column :audits, :audited_changes
    rename_column :audits, :new_changes, :audited_changes
  end
end

class AddIndexToAuditAction < ActiveRecord::Migration[5.2]
  def change
    add_index :audits, :action
  end
end

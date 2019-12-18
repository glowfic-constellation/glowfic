class UpdateAuditsSlowly < ActiveRecord::Migration[5.2]
  def up
    change_column_type(:jsonb) { |audit| YAML.load(audit.old_changes) }
  end

  def down
    change_column_type(:text) { |audit| audit.old_changes }
  end

  def change_column_type(column_type)
    Audited::Audit.find_each do |audit|
      puts "At #{audit.id}" if audit.id % 1000 == 0
      audit.update!(audited_changes: yield(audit))
    end
    remove_column :audits, :old_changes
  end
end

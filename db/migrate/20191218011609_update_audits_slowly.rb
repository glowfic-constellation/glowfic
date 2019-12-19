class UpdateAuditsSlowly < ActiveRecord::Migration[5.2]
  def change
    Audited::Audit.find_each do |audit|
      puts "At #{audit.id}" if audit.id % 1000 == 0
      audit.update!(audited_changes: YAML.load(audit.old_changes))
    end
    remove_column :audits, :old_changes
  end
end

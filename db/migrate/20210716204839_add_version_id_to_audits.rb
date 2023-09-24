class AddVersionIdToAudits < ActiveRecord::Migration[5.2]
  def change
    add_column :audits, :version_id, :integer
  end
end

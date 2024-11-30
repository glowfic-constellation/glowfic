class AddRetiredToTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :templates, :retired, :boolean, default: false
  end
end

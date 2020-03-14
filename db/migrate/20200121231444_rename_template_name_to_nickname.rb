class RenameTemplateNameToNickname < ActiveRecord::Migration[5.2]
  def change
    rename_column :characters, :template_name, :nickname
  end
end

class CreateSettings < ActiveRecord::Migration[5.0]
  def up
    create_table :settings do |t|
      t.integer :user_id, null: false
      t.citext :name, null: false
      t.text :description
      t.boolean :owned, default: false
      t.timestamps null: true
    end
    add_index :settings, :name

    create_table :post_settings do |t|
      t.integer :post_id, null: false
      t.integer :setting_id, null: false
      t.boolean :suggested, default: false
      t.timestamps null: true
    end
    add_index :post_settings, :post_id
    add_index :post_settings, :setting_id

    create_table :character_settings do |t|
      t.integer :character_id, null: false
      t.integer :setting_id, null: false
      t.timestamps null: true
    end
    add_index :character_settings, :character_id
    add_index :character_settings, :setting_id

    Tag.connection.select_all("select * from tags where type = 'Setting';").each do |setting|
      new_setting = Setting.create!(
        name: setting['name'],
        user_id: setting['user_id'],
        description: setting['description'],
        owned: setting['owned'],
        created_at: setting['created_at'],
        updated_at: setting['updated_at'])

      PostTag.where(tag_id: setting['id']).order('id asc').each do |pt|
        PostSetting.create!(
          setting_id: new_setting.id,
          post_id: pt.post_id,
          created_at: pt.created_at,
          updated_at: pt.updated_at)
        pt.destroy
      end

      CharacterTag.where(tag_id: setting['id']).order('id asc').each do |pt|
        CharacterSetting.create!(
          setting_id: new_setting.id,
          character_id: pt.character_id,
          created_at: pt.created_at,
          updated_at: pt.updated_at)
        pt.destroy
      end
    end

    Tag.where(type: 'Setting').delete_all
    remove_column :tags, :description
    remove_column :tags, :owned
  end

  def down
    add_column :tags, :description, :text
    add_column :tags, :owned, :boolean, default: false
    Setting.unscoped.find_each do |setting|
      Tag.create!(
        type: 'Setting',
        name: setting.name,
        user_id: setting.user_id,
        description: setting.description,
        owned: setting.owned,
        created_at: setting.created_at,
        updated_at: setting.updated_at)
    end
    # TODO joins
    Setting.delete_all
    drop_table :settings
  end
end

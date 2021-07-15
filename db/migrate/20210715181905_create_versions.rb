class CreateVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :versions do |t|
      t.string   :item_type, null: false, index: true
      t.integer  :item_id,   null: false, index: true
      t.string   :event,     null: false
      t.string   :whodunnit
      t.jsonb    :object
      t.jsonb    :object_changes
      t.string   :comment
      t.string   :ip
      t.string   :request_uuid

      t.datetime :created_at
    end
  end
end

class CreateVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :post_versions do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false, index: true
      t.string   :event,     null: false
      t.integer  :whodunnit
      t.jsonb    :object_changes
      t.string   :comment
      t.string   :ip
      t.string   :request_uuid

      t.datetime :created_at
    end

    create_table :reply_versions do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false, index: true
      t.string   :event,     null: false
      t.integer  :whodunnit
      t.jsonb    :object_changes
      t.string   :comment
      t.string   :ip
      t.string   :request_uuid
      t.integer  :post_id,  null: false, index: true

      t.datetime :created_at
    end

    create_table :character_versions do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false, index: true
      t.string   :event,     null: false
      t.integer  :whodunnit
      t.jsonb    :object_changes
      t.string   :comment
      t.string   :ip
      t.string   :request_uuid

      t.datetime :created_at
    end

    create_table :block_versions do |t|
      t.string   :item_type, null: false
      t.integer  :item_id,   null: false, index: true
      t.string   :event,     null: false
      t.integer  :whodunnit
      t.jsonb    :object_changes
      t.string   :comment
      t.string   :ip
      t.string   :request_uuid

      t.datetime :created_at
    end
  end
end

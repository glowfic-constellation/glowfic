class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.integer :sender_id, null: false
      t.integer :recipient_id, null: false
      t.integer :parent_id
      t.integer :thread_id
      t.string :subject
      t.text :message
      t.boolean :unread, default: true
      t.boolean :visible_inbox, default: true
      t.boolean :visible_outbox, default: true
      t.boolean :marked_inbox, default: false
      t.boolean :marked_outbox, default: false
      t.datetime :read_at
      t.timestamps null: true
    end
    add_index :messages, :sender_id
    add_index :messages, [:recipient_id, :unread]
    add_index :messages, :thread_id
  end
end

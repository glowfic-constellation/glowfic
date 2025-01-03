# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :crypted, :legacy_password_hash
    change_column_null :users, :legacy_password_hash, true

    # when migrating down, fill in old "crypted" hashes for any users that were already migrated
    # we use a securerandom password (not exposed); users will have to reset passwords in this eventuality
    # as we don't have access to their underlying password, and we're removing devise support by rolling this back
    reversible do |direction|
      direction.up { }
      direction.down do
        User.reset_column_information
        puts "Migrating users back to legacy password format (random password will be set)"
        User.where(legacy_password_hash: nil).find_each do |user|
          puts "- User #{user.id}/#{user.username}"
          user.salt_uuid ||= SecureRandom.uuid
          crypted = user.send(:crypted_password, SecureRandom.alphanumeric(32))
          user.update_columns(legacy_password_hash: crypted, salt_uuid: user.salt_uuid) # intentionally skip callbacks
        end
      end
    end

    change_table :users do |t|
      ## Database authenticatable
      # t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.citext   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps null: false
    end
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true

    # in Rails 8.0.1, needs options to be passed to be reversible (avoids ArgumentError in create_table)
    drop_table :password_resets, id: :serial do |t| # copied schema before deletion
      t.integer "user_id", null: false
      t.string "auth_token", null: false
      t.boolean "used", default: false
      t.datetime "created_at", precision: nil
      t.datetime "updated_at", precision: nil
      t.index ["auth_token"], name: "index_password_resets_on_auth_token", unique: true
      t.index ["user_id", "created_at"], name: "index_password_resets_on_user_id_and_created_at"
    end

    reversible do |direction|
      direction.up do
        User.reset_column_information
        User.where.not(email: nil).update_all(confirmed_at: Time.now)
      end
      direction.down { }
    end
  end
end

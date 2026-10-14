class CreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_openid_requests do |t|
      t.references :access_grant, null: false, index: true, foreign_key: { to_table: :oauth_access_grants, on_delete: :cascade }
      t.string :nonce, null: false
      t.datetime :created_at, null: false
    end
  end
end

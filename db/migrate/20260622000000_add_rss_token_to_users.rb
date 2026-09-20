class AddRssTokenToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :rss_token, :string
    add_index :users, :rss_token, unique: true

    say_with_time "Backfilling rss_token for existing users" do
      User.reset_column_information
      User.where(rss_token: nil).find_each do |user|
        # rubocop:disable Rails/SkipsModelValidations
        user.update_columns(rss_token: User.generate_unique_secure_token)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end

  def down
    remove_column :users, :rss_token
  end
end
